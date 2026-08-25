const { expect } = require("chai");
const { witnessIndex } = require("./lib/aenknre-signal-layout.js");
const { newRejectionTracker } = require("./util/witness-errors.js");
const { join } = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const {
  genKeypair,
  genEcdhSharedKey,
  formatPrivKeyForBabyJub,
  stringifyBigInts,
} = require("maci-crypto");
const {
  Merkletree,
  InMemoryDB,
  str2Bytes,
  ZERO_HASH,
} = require("@iden3/js-merkletree");
const {
  Poseidon,
  newSalt,
  newEncryptionNonce,
  poseidonDecrypt,
  enforcementNullifier,
} = require("../index.js");

const SMT_HEIGHT_UTXO = 32;
const SMT_HEIGHT_IDENTITY = 20;
const SMT_HEIGHT_COMPLIANCE = 20;
const poseidonHash = Poseidon.poseidon4;
const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;
const STATUS_FROZEN = 2n;

// The 1-based witness index of a public signal of this circuit.
const pi = (signal) =>
  witnessIndex("anon_enc_nullifier_kyc_non_repudiation_enforced", signal);

describe("main circuit tests for Zeto fungible tokens with encryption, KYC, non-repudiation, and enforcement nullifiers", () => {
  let circuit;
  // circom_tester accumulates every failed assert into one error string for the
  // life of the process, so only the freshly appended stack describes the failure
  // under test. See test/util/witness-errors.js.
  const rejects = newRejectionTracker();
  let smtUtxo, smtKYC;
  let smtComplianceAllActive,
    smtComplianceSenderFrozen,
    smtComplianceRecipientFrozen;

  const Alice = {};
  const Bob = {};
  const Arbiter = {};
  const Enforcer = {};
  let senderPrivateKey;

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(
        __dirname,
        "../../circuits/anon_enc_nullifier_kyc_non_repudiation_enforced.circom",
      ),
    );

    let keypair = genKeypair();
    Alice.privKey = keypair.privKey;
    Alice.pubKey = keypair.pubKey;
    senderPrivateKey = formatPrivKeyForBabyJub(Alice.privKey);

    keypair = genKeypair();
    Bob.privKey = keypair.privKey;
    Bob.pubKey = keypair.pubKey;

    keypair = genKeypair();
    Arbiter.privKey = keypair.privKey;
    Arbiter.pubKey = keypair.pubKey;

    keypair = genKeypair();
    Enforcer.privKey = keypair.privKey;
    Enforcer.pubKey = keypair.pubKey;

    // initialize the UTXO Sparse Merkle Tree
    smtUtxo = new Merkletree(
      new InMemoryDB(str2Bytes("utxo")),
      true,
      SMT_HEIGHT_UTXO,
    );

    // initialize the identity Sparse Merkle Tree
    smtKYC = new Merkletree(
      new InMemoryDB(str2Bytes("kyc")),
      true,
      SMT_HEIGHT_IDENTITY,
    );
    const aliceIdentity = poseidonHash2(Alice.pubKey);
    await smtKYC.add(aliceIdentity, aliceIdentity);
    const bobIdentity = poseidonHash2(Bob.pubKey);
    await smtKYC.add(bobIdentity, bobIdentity);

    // initialize compliance SMTs for different test scenarios

    // all ACTIVE (happy path)
    smtComplianceAllActive = new Merkletree(
      new InMemoryDB(str2Bytes("comp-all-active")),
      true,
      SMT_HEIGHT_COMPLIANCE,
    );
    await smtComplianceAllActive.add(
      poseidonHash2(Alice.pubKey),
      poseidonHash3([...Alice.pubKey, STATUS_ACTIVE]),
    );
    await smtComplianceAllActive.add(
      poseidonHash2(Bob.pubKey),
      poseidonHash3([...Bob.pubKey, STATUS_ACTIVE]),
    );

    // Alice FROZEN, Bob ACTIVE (sender FROZEN test)
    smtComplianceSenderFrozen = new Merkletree(
      new InMemoryDB(str2Bytes("comp-sender-frozen")),
      true,
      SMT_HEIGHT_COMPLIANCE,
    );
    await smtComplianceSenderFrozen.add(
      poseidonHash2(Alice.pubKey),
      poseidonHash3([...Alice.pubKey, STATUS_FROZEN]),
    );
    await smtComplianceSenderFrozen.add(
      poseidonHash2(Bob.pubKey),
      poseidonHash3([...Bob.pubKey, STATUS_ACTIVE]),
    );

    // Alice ACTIVE, Bob FROZEN (recipient FROZEN test)
    smtComplianceRecipientFrozen = new Merkletree(
      new InMemoryDB(str2Bytes("comp-recip-frozen")),
      true,
      SMT_HEIGHT_COMPLIANCE,
    );
    await smtComplianceRecipientFrozen.add(
      poseidonHash2(Alice.pubKey),
      poseidonHash3([...Alice.pubKey, STATUS_ACTIVE]),
    );
    await smtComplianceRecipientFrozen.add(
      poseidonHash2(Bob.pubKey),
      poseidonHash3([...Bob.pubKey, STATUS_FROZEN]),
    );
  });

  // Build full circuit inputs for a standard 2-in / 2-out transfer.
  // Returns circuitInputs plus metadata so individual tests can tweak specific
  // fields before passing to calculateWitness.
  async function buildHappyPathInputs(complianceSmt) {
    const inputValues = [32, 40];
    const outputValues = [20, 52];

    // create two input UTXOs, each has their own salt, but same owner
    const salt1 = newSalt();
    const input1 = poseidonHash([
      BigInt(inputValues[0]),
      salt1,
      ...Alice.pubKey,
    ]);
    const salt2 = newSalt();
    const input2 = poseidonHash([
      BigInt(inputValues[1]),
      salt2,
      ...Alice.pubKey,
    ]);
    const inputCommitments = [input1, input2];

    // create the owner nullifiers for the inputs
    const ownerNullifier1 = poseidonHash3([
      BigInt(inputValues[0]),
      salt1,
      senderPrivateKey,
    ]);
    const ownerNullifier2 = poseidonHash3([
      BigInt(inputValues[1]),
      salt2,
      senderPrivateKey,
    ]);
    const ownerNullifiers = [ownerNullifier1, ownerNullifier2];

    // create the enforcement nullifiers via ECDH(ownerPriv, enforcerPub)
    const enfNullifier1 = enforcementNullifier(
      Alice.privKey,
      Enforcer.pubKey,
      input1,
    );
    const enfNullifier2 = enforcementNullifier(
      Alice.privKey,
      Enforcer.pubKey,
      input2,
    );
    const enforcementNullifiers = [enfNullifier1, enfNullifier2];

    // calculate the root of the UTXO SMT
    await smtUtxo.add(input1, input1);
    await smtUtxo.add(input2, input2);

    // generate the merkle proof for the inputs
    const utxoProof1 = await smtUtxo.generateCircomVerifierProof(
      input1,
      ZERO_HASH,
    );
    const utxoProof2 = await smtUtxo.generateCircomVerifierProof(
      input2,
      ZERO_HASH,
    );
    const utxosRoot = utxoProof1.root.bigInt();

    // create two output UTXOs with different owners
    const salt3 = newSalt();
    const output1 = poseidonHash([
      BigInt(outputValues[0]),
      salt3,
      ...Bob.pubKey,
    ]);
    const salt4 = newSalt();
    const output2 = poseidonHash([
      BigInt(outputValues[1]),
      salt4,
      ...Alice.pubKey,
    ]);
    const outputCommitments = [output1, output2];

    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();
    const encryptInputs = stringifyBigInts({
      encryptionNonce,
      ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
    });

    // generate the merkle proof for the transacting identities
    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const kycProofBob = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Bob.pubKey),
      ZERO_HASH,
    );
    const identitiesRoot = kycProofAlice.root.bigInt();

    // generate the merkle proof for compliance status
    const compProofAlice = await complianceSmt.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const compProofBob = await complianceSmt.generateCircomVerifierProof(
      poseidonHash2(Bob.pubKey),
      ZERO_HASH,
    );
    const complianceRoot = compProofAlice.root.bigInt();

    const circuitInputs = {
      ownerNullifiers,
      enforcementNullifiers,
      inputCommitments,
      inputValues,
      inputSalts: [salt1, salt2],
      inputOwnerPrivateKey: senderPrivateKey,
      utxosRoot,
      utxosMerkleProof: [
        utxoProof1.siblings.map((s) => s.bigInt()),
        utxoProof2.siblings.map((s) => s.bigInt()),
      ],
      enabledInputs: [1, 1],
      identitiesRoot,
      identitiesMerkleProof: [
        kycProofAlice.siblings.map((s) => s.bigInt()),
        kycProofBob.siblings.map((s) => s.bigInt()),
        kycProofAlice.siblings.map((s) => s.bigInt()),
      ],
      complianceRoot,
      complianceMerkleProof: [
        compProofAlice.siblings.map((s) => s.bigInt()),
        compProofBob.siblings.map((s) => s.bigInt()),
        compProofAlice.siblings.map((s) => s.bigInt()),
      ],
      outputCommitments,
      outputValues,
      outputSalts: [salt3, salt4],
      outputOwnerPublicKeys: [Bob.pubKey, Alice.pubKey],
      arbiterPublicKey: Arbiter.pubKey,
      enforcerPublicKey: Enforcer.pubKey,
      ...encryptInputs,
    };

    return {
      circuitInputs,
      inputValues,
      outputValues,
      salts: { salt1, salt2, salt3, salt4 },
      ownerNullifiers,
      enforcementNullifiers,
      outputCommitments,
      utxosRoot,
      identitiesRoot,
      complianceRoot,
      encryptionNonce,
      ephemeralKeypair,
    };
  }

  it("should succeed for valid witness with all parties ACTIVE, arbiter and enforcer can decrypt", async function () {
    this.timeout(60000);

    const {
      circuitInputs,
      inputValues,
      outputValues,
      salts,
      ownerNullifiers,
      enforcementNullifiers,
      outputCommitments,
      utxosRoot,
      identitiesRoot,
      complianceRoot,
      encryptionNonce,
      ephemeralKeypair,
    } = await buildHappyPathInputs(smtComplianceAllActive);

    const witness = await circuit.calculateWitness(circuitInputs, true);

    // console.log('witness', witness.slice(0, 60));
    // console.log('ownerNullifiers', ownerNullifiers);
    // console.log('enforcementNullifiers', enforcementNullifiers);
    // console.log('outputCommitments', outputCommitments);
    // console.log('utxosRoot', utxosRoot);
    // console.log('identitiesRoot', identitiesRoot);
    // console.log('complianceRoot', complianceRoot);
    // console.log('encryptionNonce', encryptionNonce);

    // Public-signal indices come from test/lib/aenknre-signal-layout.js, which
    // public-signal-layout.js checks against the compiled .sym. Circom orders
    // public signals by declaration order in the template, not by the order of
    // the `{ public [...] }` list, so they cannot be re-derived by hand here.

    expect(witness[pi("ownerNullifiers[0]")]).to.equal(
      BigInt(ownerNullifiers[0]),
    );
    expect(witness[pi("ownerNullifiers[1]")]).to.equal(
      BigInt(ownerNullifiers[1]),
    );
    expect(witness[pi("enforcementNullifiers[0]")]).to.equal(
      BigInt(enforcementNullifiers[0]),
    );
    expect(witness[pi("enforcementNullifiers[1]")]).to.equal(
      BigInt(enforcementNullifiers[1]),
    );
    expect(witness[pi("utxosRoot")]).to.equal(utxosRoot);
    expect(witness[pi("enabledInputs[0]")]).to.equal(1n);
    expect(witness[pi("enabledInputs[1]")]).to.equal(1n);
    expect(witness[pi("identitiesRoot")]).to.equal(identitiesRoot);
    expect(witness[pi("complianceRoot")]).to.equal(complianceRoot);
    expect(witness[pi("outputCommitments[0]")]).to.equal(
      BigInt(outputCommitments[0]),
    );
    expect(witness[pi("outputCommitments[1]")]).to.equal(
      BigInt(outputCommitments[1]),
    );
    expect(witness[pi("encryptionNonce")]).to.equal(BigInt(encryptionNonce));
    expect(witness[pi("arbiterPublicKey[0]")]).to.equal(Arbiter.pubKey[0]);
    expect(witness[pi("arbiterPublicKey[1]")]).to.equal(Arbiter.pubKey[1]);
    expect(witness[pi("enforcerPublicKey[0]")]).to.equal(Enforcer.pubKey[0]);
    expect(witness[pi("enforcerPublicKey[1]")]).to.equal(Enforcer.pubKey[1]);

    // take the output from the proof circuit and attempt to decrypt
    // as the receiver (Bob decrypts output 1)
    let cipherText = witness.slice(3, 7);
    let recoveredKey = genEcdhSharedKey(Bob.privKey, ephemeralKeypair.pubKey);
    let plainText = poseidonDecrypt(
      cipherText,
      recoveredKey,
      encryptionNonce,
      2,
    );
    expect(plainText).to.deep.equal([BigInt(outputValues[0]), salts.salt3]);

    // decrypting the second utxo should fail as it belongs to the sender
    cipherText = witness.slice(7, 11);
    recoveredKey = genEcdhSharedKey(Bob.privKey, ephemeralKeypair.pubKey);
    expect(function () {
      plainText = poseidonDecrypt(cipherText, recoveredKey, encryptionNonce, 2);
    }).to.throw(
      "The last ciphertext element must match the second item of the permuted state",
    );

    // decrypt using the sender's key should succeed
    recoveredKey = genEcdhSharedKey(Alice.privKey, ephemeralKeypair.pubKey);
    plainText = poseidonDecrypt(cipherText, recoveredKey, encryptionNonce, 2);
    expect(plainText).to.deep.equal([BigInt(outputValues[1]), salts.salt4]);

    // take the output from the proof circuit and attempt to decrypt
    // as the arbiter (14-element authority plaintext)
    const recoveredKey2 = genEcdhSharedKey(
      Arbiter.privKey,
      ephemeralKeypair.pubKey,
    );
    const cipherText2 = witness.slice(11, 27);
    const plainText2 = poseidonDecrypt(
      cipherText2,
      recoveredKey2,
      encryptionNonce,
      14,
    );
    expect(plainText2).to.deep.equal([
      Alice.pubKey[0], // input owner public key
      Alice.pubKey[1],
      BigInt(inputValues[0]), // input values
      salts.salt1, // input salts
      BigInt(inputValues[1]),
      salts.salt2,
      Bob.pubKey[0], // output owner public keys
      Bob.pubKey[1],
      Alice.pubKey[0],
      Alice.pubKey[1],
      BigInt(outputValues[0]), // output values
      salts.salt3, // output salts
      BigInt(outputValues[1]),
      salts.salt4,
    ]);

    // take the output from the proof circuit and attempt to decrypt
    // as the enforcer (same plaintext, different ECDH key)
    const recoveredKey3 = genEcdhSharedKey(
      Enforcer.privKey,
      ephemeralKeypair.pubKey,
    );
    const cipherText3 = witness.slice(27, 43);
    const plainText3 = poseidonDecrypt(
      cipherText3,
      recoveredKey3,
      encryptionNonce,
      14,
    );
    expect(plainText3).to.deep.equal(plainText2);

    // non-authority cannot decrypt arbiter ciphertext
    expect(function () {
      poseidonDecrypt(cipherText2, recoveredKey, encryptionNonce, 14);
    }).to.throw();

    // non-authority cannot decrypt enforcer ciphertext
    expect(function () {
      poseidonDecrypt(cipherText3, recoveredKey, encryptionNonce, 14);
    }).to.throw();
  });

  it("should fail to generate a witness because sender has FROZEN compliance status", async function () {
    this.timeout(60000);

    // the circuit uses ComplianceStatus(..., 1) which hardcodes STATUS=ACTIVE;
    // the compliance tree has Alice as FROZEN -> leaf value mismatch -> SMT rejects
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceSenderFrozen,
    );

    await rejects(circuit, circuitInputs);
  });

  it("should fail to generate a witness because output recipient has FROZEN compliance status", async function () {
    this.timeout(60000);

    // the compliance tree has Bob as FROZEN; the circuit checks all output owners
    // for ACTIVE status, so Bob's check fails
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceRecipientFrozen,
    );

    await rejects(circuit, circuitInputs);
  });

  it("should fail to generate a witness because enforcement nullifier is tampered", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );

    // flip a bit in the first enforcement nullifier
    circuitInputs.enforcementNullifiers = [
      circuitInputs.enforcementNullifiers[0] + 1n,
      circuitInputs.enforcementNullifiers[1],
    ];

    await rejects(circuit, circuitInputs);
  });

  it("should fail if not using the right enforcer public key", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );

    // supply a different public key as enforcerPublicKey; enforcement nullifiers
    // were derived with the original key, so the circuit's ECDH produces a
    // different shared secret -> different derived nullifier -> mismatch
    const wrongEnforcer = genKeypair();
    circuitInputs.enforcerPublicKey = wrongEnforcer.pubKey;

    await rejects(circuit, circuitInputs);
  });

  it("should succeed for valid witness with a disabled output slot", async function () {
    this.timeout(60000);

    const inputValues = [32, 40];
    const outputValues = [72, 0]; // second output disabled

    // create two input UTXOs, each has their own salt, but same owner
    const salt1 = newSalt();
    const input1 = poseidonHash([
      BigInt(inputValues[0]),
      salt1,
      ...Alice.pubKey,
    ]);
    const salt2 = newSalt();
    const input2 = poseidonHash([
      BigInt(inputValues[1]),
      salt2,
      ...Alice.pubKey,
    ]);
    const inputCommitments = [input1, input2];

    // create the owner nullifiers for the inputs
    const ownerNullifiers = [
      poseidonHash3([BigInt(inputValues[0]), salt1, senderPrivateKey]),
      poseidonHash3([BigInt(inputValues[1]), salt2, senderPrivateKey]),
    ];

    // create the enforcement nullifiers
    const enforcementNullifiers = [
      enforcementNullifier(Alice.privKey, Enforcer.pubKey, input1),
      enforcementNullifier(Alice.privKey, Enforcer.pubKey, input2),
    ];

    // calculate the root of the UTXO SMT
    await smtUtxo.add(input1, input1);
    await smtUtxo.add(input2, input2);

    // generate the merkle proof for the inputs
    const utxoProof1 = await smtUtxo.generateCircomVerifierProof(
      input1,
      ZERO_HASH,
    );
    const utxoProof2 = await smtUtxo.generateCircomVerifierProof(
      input2,
      ZERO_HASH,
    );

    // create output UTXOs: first is real, second is disabled
    const salt3 = newSalt();
    const output1 = poseidonHash([
      BigInt(outputValues[0]),
      salt3,
      ...Bob.pubKey,
    ]);
    const outputCommitments = [output1, 0n];

    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();
    const encryptInputs = stringifyBigInts({
      encryptionNonce,
      ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
    });

    // generate the merkle proof for the transacting identities;
    // output 2 is disabled -> gated key becomes (0,0) -> pubkey-zero gating skips SMT
    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const kycProofBob = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Bob.pubKey),
      ZERO_HASH,
    );

    // generate the merkle proof for compliance status
    const compProofAlice =
      await smtComplianceAllActive.generateCircomVerifierProof(
        poseidonHash2(Alice.pubKey),
        ZERO_HASH,
      );
    const compProofBob =
      await smtComplianceAllActive.generateCircomVerifierProof(
        poseidonHash2(Bob.pubKey),
        ZERO_HASH,
      );

    const witness = await circuit.calculateWitness(
      {
        ownerNullifiers,
        enforcementNullifiers,
        inputCommitments,
        inputValues,
        inputSalts: [salt1, salt2],
        inputOwnerPrivateKey: senderPrivateKey,
        utxosRoot: utxoProof1.root.bigInt(),
        utxosMerkleProof: [
          utxoProof1.siblings.map((s) => s.bigInt()),
          utxoProof2.siblings.map((s) => s.bigInt()),
        ],
        enabledInputs: [1, 1],
        identitiesRoot: kycProofAlice.root.bigInt(),
        identitiesMerkleProof: [
          kycProofAlice.siblings.map((s) => s.bigInt()),
          kycProofBob.siblings.map((s) => s.bigInt()),
          Array(SMT_HEIGHT_IDENTITY).fill(0n), // disabled slot
        ],
        complianceRoot: compProofAlice.root.bigInt(),
        complianceMerkleProof: [
          compProofAlice.siblings.map((s) => s.bigInt()),
          compProofBob.siblings.map((s) => s.bigInt()),
          Array(SMT_HEIGHT_COMPLIANCE).fill(0n), // disabled slot
        ],
        outputCommitments,
        outputValues,
        outputSalts: [salt3, 0n],
        // A disabled slot's owner key is inert: the curve check is fed the
        // Base8 padding instead of this value, the KYC/compliance key is zeroed,
        // and CheckHashes is gated off by the zero commitment. Any value works;
        // a real key is used only to keep the fixture readable.
        outputOwnerPublicKeys: [Bob.pubKey, Bob.pubKey],
        arbiterPublicKey: Arbiter.pubKey,
        enforcerPublicKey: Enforcer.pubKey,
        ...encryptInputs,
      },
      true,
    );

    // console.log('witness', witness.slice(0, 60));

    // witness[pi("outputCommitments[1]")] is outputCommitments[1] per the .sym; witness[pi("enabledInputs[0]")] is
    // enabledInputs[0], which is 1 here.
    expect(witness[pi("outputCommitments[1]")]).to.equal(0n);
  });

  // Rebuild the two output commitments so CheckSum is satisfied by `values`.
  // Lets a test move value around without tripping mass conservation first.
  function retargetOutputs(circuitInputs, values) {
    circuitInputs.outputValues = values;
    circuitInputs.outputCommitments = values.map((v, i) =>
      poseidonHash([
        BigInt(v),
        circuitInputs.outputSalts[i],
        ...circuitInputs.outputOwnerPublicKeys[i],
      ]),
    );
  }

  it("should fail when the enforcement nullifiers are suppressed to zero", async function () {
    this.timeout(60000);

    // Every enforcement tag is a prover-chosen zero, which the per-slot
    // IsZero gate reads as "slot disabled" and skips. The spend still consumes
    // both real notes, so the tag the contract's OR-spend rule relies on is
    // never published and the note can be spent again on the other path.
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    circuitInputs.enforcementNullifiers = [0, 0];

    await rejects(circuit, circuitInputs);
  });

  it("should fail when a disabled input slot carries value", async function () {
    this.timeout(60000);

    // Slot 1 is turned off at every gate that keys off a zero — commitment,
    // owner nullifier, enforcement tag and the SMT enable flag — while
    // inputValues[1] stays in CheckSum, which has no gate at all. The spend then
    // mints 1_000_000 out of a single 32-unit note.
    const { circuitInputs, inputValues } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    const phantom = 1000000;
    circuitInputs.inputCommitments[1] = 0n;
    circuitInputs.ownerNullifiers[1] = 0n;
    circuitInputs.enforcementNullifiers[1] = 0n;
    circuitInputs.enabledInputs = [1, 0];
    circuitInputs.utxosMerkleProof[1] = Array(SMT_HEIGHT_UTXO).fill(0n);
    circuitInputs.inputValues = [inputValues[0], phantom];
    retargetOutputs(circuitInputs, [20, inputValues[0] + phantom - 20]);

    await rejects(circuit, circuitInputs);
  });

  it("should succeed with a genuinely disabled, zero-value input slot", async function () {
    this.timeout(60000);

    // The legitimate 1-in spend the gate must keep allowing: slot 1 is off at
    // every gate AND carries no value.
    const { circuitInputs, inputValues } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    circuitInputs.inputCommitments[1] = 0n;
    circuitInputs.ownerNullifiers[1] = 0n;
    circuitInputs.enforcementNullifiers[1] = 0n;
    circuitInputs.enabledInputs = [1, 0];
    circuitInputs.utxosMerkleProof[1] = Array(SMT_HEIGHT_UTXO).fill(0n);
    circuitInputs.inputValues = [inputValues[0], 0];
    retargetOutputs(circuitInputs, [20, inputValues[0] - 20]);

    const witness = await circuit.calculateWitness(circuitInputs, true);
    await circuit.checkConstraints(witness);
  });

  it("should fail when an enabled input slot has a zero enforcement tag", async function () {
    this.timeout(60000);

    // The half-on case: the slot is enabled everywhere else, only the
    // enforcement tag is suppressed.
    const { circuitInputs, enforcementNullifiers } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    circuitInputs.enforcementNullifiers = [enforcementNullifiers[0], 0];

    await rejects(circuit, circuitInputs);
  });

  it("should fail when enabledInputs is not boolean", async function () {
    this.timeout(60000);

    // The enable flag itself must be constrained, or it is merely another
    // prover-chosen value.
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    circuitInputs.enabledInputs = [2, 2];

    await rejects(circuit, circuitInputs);
  });

  it("should fail when a disabled output slot carries value", async function () {
    this.timeout(60000);

    // Output half: a zero commitment skips CheckHashes, so the slot mints
    // no note, but its value still balances CheckSum. The spend burns 52 units
    // of the sender's own value with no record of where it went.
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    circuitInputs.outputCommitments[1] = 0n;

    await rejects(circuit, circuitInputs);
  });

  it("should fail when an output owner key has x == 0", async function () {
    this.timeout(60000);

    // (0, 1) is a genuine point on the BabyJubJub curve, so BabyCheck
    // accepts it — but Kyc and ComplianceStatus both gate on `publicKey[0] == 0`
    // and read it as "slot disabled", skipping both checks. Value is sent to a
    // key that is in neither the identities tree nor the compliance tree.
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    circuitInputs.outputOwnerPublicKeys[0] = [0n, 1n];
    circuitInputs.outputCommitments[0] = poseidonHash([
      BigInt(circuitInputs.outputValues[0]),
      circuitInputs.outputSalts[0],
      0n,
      1n,
    ]);

    await rejects(circuit, circuitInputs);
  });

  it("should fail when an output owner key is the 2-torsion point", async function () {
    this.timeout(60000);

    // N-1: (0, p-1) is the other x == 0 point. EscalarMulAny substitutes the
    // Base8 generator for any x == 0 input, so the ECDH "shared secret" for such
    // a key is ecdhPrivateKey * Base8 — which is the published ecdhPublicKey.
    // The receiver ciphertext is then readable by anyone, and (0, 1) and (0, p-1)
    // produce byte-identical ciphertexts because the point is never used.
    const FIELD_P =
      21888242871839275222246405745257275088548364400416034343698204186575808495617n;
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    circuitInputs.outputOwnerPublicKeys[0] = [0n, FIELD_P - 1n];
    circuitInputs.outputCommitments[0] = poseidonHash([
      BigInt(circuitInputs.outputValues[0]),
      circuitInputs.outputSalts[0],
      0n,
      FIELD_P - 1n,
    ]);

    await rejects(circuit, circuitInputs);
  });

  it("should fail when the ephemeral key is zero", async function () {
    this.timeout(60000);

    // With a zero scalar every ECDH output is the curve identity,
    // so the "shared secret" is a constant any observer can compute. Every
    // ciphertext in the transaction — receiver, arbiter and enforcer — becomes
    // world-readable, and the published ephemeral public key is the identity.
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    circuitInputs.ecdhPrivateKey = 0;

    await rejects(circuit, circuitInputs);
  });

  it("should fail when the sender private key is zero", async function () {
    this.timeout(60000);

    // The same defect on the owner scalar: a zero key derives the curve
    // identity, whose x is zero, and Kyc and ComplianceStatus read x == 0 as
    // "slot disabled" — so the sender's own registration and ACTIVE checks are
    // skipped entirely.
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    circuitInputs.inputOwnerPrivateKey = 0;

    await rejects(circuit, circuitInputs);
  });

  it("pins that a non-canonical owner scalar is caught by the enforcement tag, not the owner nullifier", async function () {
    this.timeout(60000);

    // The owner nullifier is Poseidon(value, salt, ownerPrivateKey) over the
    // raw scalar, and BabyPbk reduces nothing: k and k + subOrder derive the same
    // public key, so they describe the same note but hash to different owner
    // nullifiers. A range bound cannot fix this — formatPrivKeyForBabyJub emits
    // exactly 252-bit scalars while subOrder is 251 bits, so every legitimate key
    // is already above subOrder and roughly half of them have a second
    // representative inside the same 252-bit window. Making the tag canonical
    // would mean reducing mod subOrder in-circuit, which changes the value of
    // every nullifier ever published.
    //
    // What makes this unexploitable here is the second nullifier domain: the
    // enforcement tag is derived from the commitment and from ECDH(scalar,
    // enforcerPublicKey), and the enforcer key is in the prime-order subgroup, so
    // (k + subOrder) · P == k · P and the tag is unchanged. Since every live input
    // slot must now publish its enforcement tag, the replay reuses a tag the
    // contract has already marked spent.
    const SUB_ORDER =
      2736030358979909402780800718157159386076813972158567259200215660948447373041n;

    const {
      circuitInputs,
      inputValues,
      salts,
      ownerNullifiers,
      enforcementNullifiers,
      outputCommitments,
    } = await buildHappyPathInputs(smtComplianceAllActive);

    const shiftedKey = BigInt(senderPrivateKey) + SUB_ORDER;
    const shiftedOwnerNullifiers = [
      poseidonHash3([BigInt(inputValues[0]), salts.salt1, shiftedKey]),
      poseidonHash3([BigInt(inputValues[1]), salts.salt2, shiftedKey]),
    ];

    // the owner nullifier is not canonical: same note, different tag
    expect(shiftedOwnerNullifiers[0]).to.not.equal(BigInt(ownerNullifiers[0]));
    expect(shiftedOwnerNullifiers[1]).to.not.equal(BigInt(ownerNullifiers[1]));

    // the enforcement tags are untouched, and the witness still validates
    // against them — that invariance is what the contract relies on
    circuitInputs.inputOwnerPrivateKey = shiftedKey;
    circuitInputs.ownerNullifiers = shiftedOwnerNullifiers;

    const witness = await circuit.calculateWitness(circuitInputs, true);
    await circuit.checkConstraints(witness);

    expect(witness[pi("enforcementNullifiers[0]")]).to.equal(
      BigInt(enforcementNullifiers[0]),
    );
    expect(witness[pi("enforcementNullifiers[1]")]).to.equal(
      BigInt(enforcementNullifiers[1]),
    );
    // and the note itself is unchanged: same commitments, same outputs
    expect(witness[pi("outputCommitments[0]")]).to.equal(
      BigInt(outputCommitments[0]),
    );
    expect(witness[pi("outputCommitments[1]")]).to.equal(
      BigInt(outputCommitments[1]),
    );
  });

  it("should fail when the output recipient is not KYC-registered", async function () {
    this.timeout(60000);

    // Negative KYC coverage. The suite tested FROZEN recipients but never an
    // identity absent from the identities tree, which is the case the SMT
    // inclusion proof exists to reject.
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );
    const stranger = genKeypair();
    circuitInputs.outputOwnerPublicKeys[0] = stranger.pubKey;
    circuitInputs.outputCommitments[0] = poseidonHash([
      BigInt(circuitInputs.outputValues[0]),
      circuitInputs.outputSalts[0],
      ...stranger.pubKey,
    ]);

    await rejects(circuit, circuitInputs);
  });

  it("should fail to generate a witness because mass conservation is not obeyed", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceAllActive,
    );

    // tamper output values: original sum = 72, new sum = 80.
    // recompute output commitments to match the tampered values so that
    // CheckHashes passes and CheckSum is the constraint that catches the violation.
    const tamperedOutputValues = [50, 30];
    circuitInputs.outputCommitments = [
      poseidonHash([
        BigInt(tamperedOutputValues[0]),
        circuitInputs.outputSalts[0],
        ...circuitInputs.outputOwnerPublicKeys[0],
      ]),
      poseidonHash([
        BigInt(tamperedOutputValues[1]),
        circuitInputs.outputSalts[1],
        ...circuitInputs.outputOwnerPublicKeys[1],
      ]),
    ];
    circuitInputs.outputValues = tamperedOutputValues;

    await rejects(circuit, circuitInputs);
  });
});

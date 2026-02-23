const { expect } = require("chai");
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
} = require("../index.js");

const SMT_HEIGHT_UTXO = 64;
const SMT_HEIGHT_IDENTITY = 10;
const SMT_HEIGHT_COMPLIANCE = 10;
const poseidonHash = Poseidon.poseidon4;
const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;
const STATUS_FROZEN = 2n;

const ENF_DOMAIN_TAG =
  21455947405572920533869930548514094044543253524099188107381343679564123236615n;

function computeEnforcementNullifier(
  ecdhPrivKey,
  counterpartyPubKey,
  commitment,
) {
  const shared = genEcdhSharedKey(ecdhPrivKey, counterpartyPubKey);
  const k0 = poseidonHash2([shared[0], shared[1]]);
  return poseidonHash3([commitment, k0, ENF_DOMAIN_TAG]);
}

describe("main circuit tests for Zeto fungible tokens with encryption, KYC, non-repudiation, and enforcement nullifiers", () => {
  let circuit;
  let smtUtxo, smtKYC;
  let smtComplianceAllActive, smtComplianceSenderFrozen, smtComplianceRecipientFrozen;

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
    const enfNullifier1 = computeEnforcementNullifier(
      Alice.privKey,
      Enforcer.pubKey,
      input1,
    );
    const enfNullifier2 = computeEnforcementNullifier(
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

    // public signal ordering snapshot for Solidity integration:
    //   output signals (automatically public, appear first):
    //     [1-2]    ecdhPublicKey[2]
    //     [3-10]   encryptedValuesForReceiver[2][4]
    //     [11-26]  encryptedValuesForArbiter[16]
    //     [27-42]  encryptedValuesForEnforcer[16]
    //   public input signals (in { public [] } declaration order):
    //     [43-44]  ownerNullifiers[2]
    //     [45-46]  enforcementNullifiers[2]
    //     [47-48]  outputCommitments[2]
    //     [49]     encryptionNonce
    //     [50]     utxosRoot
    //     [51]     identitiesRoot
    //     [52]     complianceRoot
    //     [53-54]  enabledInputs[2]
    //     [55-56]  arbiterPublicKey[2]
    //     [57-58]  enforcerPublicKey[2]

    expect(witness[43]).to.equal(BigInt(ownerNullifiers[0]));
    expect(witness[44]).to.equal(BigInt(ownerNullifiers[1]));
    expect(witness[45]).to.equal(BigInt(enforcementNullifiers[0]));
    expect(witness[46]).to.equal(BigInt(enforcementNullifiers[1]));
    expect(witness[47]).to.equal(BigInt(outputCommitments[0]));
    expect(witness[48]).to.equal(BigInt(outputCommitments[1]));
    expect(witness[49]).to.equal(BigInt(encryptionNonce));
    expect(witness[50]).to.equal(utxosRoot);
    expect(witness[51]).to.equal(identitiesRoot);
    expect(witness[52]).to.equal(complianceRoot);
    expect(witness[53]).to.equal(1n);
    expect(witness[54]).to.equal(1n);
    expect(witness[55]).to.equal(Arbiter.pubKey[0]);
    expect(witness[56]).to.equal(Arbiter.pubKey[1]);
    expect(witness[57]).to.equal(Enforcer.pubKey[0]);
    expect(witness[58]).to.equal(Enforcer.pubKey[1]);

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

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    // console.log(err);
    // TODO: pin exact template suffix and line number after first compilation run
    expect(err).to.match(/SMTVerifier/);
  });

  it("should fail to generate a witness because output recipient has FROZEN compliance status", async function () {
    this.timeout(60000);

    // the compliance tree has Bob as FROZEN; the circuit checks all output owners
    // for ACTIVE status, so Bob's check fails
    const { circuitInputs } = await buildHappyPathInputs(
      smtComplianceRecipientFrozen,
    );

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    // console.log(err);
    expect(err).to.match(/SMTVerifier/);
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

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    // console.log(err);
    expect(err).to.match(/CheckEnforcementNullifiers/);
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

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    // console.log(err);
    expect(err).to.match(/CheckEnforcementNullifiers/);
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
      computeEnforcementNullifier(Alice.privKey, Enforcer.pubKey, input1),
      computeEnforcementNullifier(Alice.privKey, Enforcer.pubKey, input2),
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
    const compProofAlice = await smtComplianceAllActive.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const compProofBob = await smtComplianceAllActive.generateCircomVerifierProof(
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
        // BabyCheck requires a valid curve point even for disabled slots;
        // Bob's key is valid and will be gated to (0,0) by isCommitmentZero
        outputOwnerPublicKeys: [Bob.pubKey, Bob.pubKey],
        arbiterPublicKey: Arbiter.pubKey,
        enforcerPublicKey: Enforcer.pubKey,
        ...encryptInputs,
      },
      true,
    );

    // console.log('witness', witness.slice(0, 60));

    expect(witness[48]).to.equal(0n); // outputCommitments[1] == 0
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

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    // console.log(err);
    expect(err).to.match(/CheckSum/);
  });
});
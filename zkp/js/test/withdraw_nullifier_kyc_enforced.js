const { expect } = require("chai");
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
} = require("../index.js");

const SMT_HEIGHT_UTXO = 32;
const SMT_HEIGHT_IDENTITY = 20;
const SMT_HEIGHT_COMPLIANCE = 20;
const poseidonHash = Poseidon.poseidon4;
const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;
const STATUS_FROZEN = 2n;

const ENF_DOMAIN_TAG =
  21455947405572920533869930548514094044543253524099188107381343679564123236615n;

// The contract injects the withdrawal recipient as `uint256(uint160(msg.sender))`
// and the proof binds it, so an observer cannot copy a pending withdrawal and
// redirect the payout. The circuit places no other statement on the value.
const RECIPIENT = BigInt("0x1234567890123456789012345678901234567890");

function computeEnforcementNullifier(
  ecdhPrivKey,
  counterpartyPubKey,
  commitment,
) {
  const shared = genEcdhSharedKey(ecdhPrivKey, counterpartyPubKey);
  const k0 = poseidonHash2([shared[0], shared[1]]);
  return poseidonHash3([commitment, k0, ENF_DOMAIN_TAG]);
}

describe("withdraw_nullifier_kyc_enforced circuit tests", () => {
  let circuit;
  // circom_tester accumulates every failed assert into one error string for the
  // life of the process, so only the freshly appended stack describes the failure
  // under test. See test/util/witness-errors.js.
  const rejects = newRejectionTracker();
  let smtUtxo, smtKYC;
  let smtComplianceAllActive, smtComplianceSenderFrozen;

  const Alice = {};
  // A KYC-registered, ACTIVE third party, used to show that the change output
  // cannot be redirected away from the sender.
  const Bob = {};
  const Arbiter = {};
  const Enforcer = {};
  let senderPrivateKey;

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(__dirname, "../../circuits/withdraw_nullifier_kyc_enforced.circom"),
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

    smtUtxo = new Merkletree(
      new InMemoryDB(str2Bytes("utxo")),
      true,
      SMT_HEIGHT_UTXO,
    );

    smtKYC = new Merkletree(
      new InMemoryDB(str2Bytes("kyc")),
      true,
      SMT_HEIGHT_IDENTITY,
    );
    await smtKYC.add(poseidonHash2(Alice.pubKey), poseidonHash2(Alice.pubKey));
    await smtKYC.add(poseidonHash2(Bob.pubKey), poseidonHash2(Bob.pubKey));

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

    // Alice FROZEN (sender FROZEN test)
    smtComplianceSenderFrozen = new Merkletree(
      new InMemoryDB(str2Bytes("comp-sender-frozen")),
      true,
      SMT_HEIGHT_COMPLIANCE,
    );
    await smtComplianceSenderFrozen.add(
      poseidonHash2(Alice.pubKey),
      poseidonHash3([...Alice.pubKey, STATUS_FROZEN]),
    );
  });

  // Build circuit inputs for a 2-in / 1-out withdrawal.
  // Both inputs belong to Alice; change output goes back to Alice.
  // fullWithdrawal: when true, change commitment is 0 (no change UTXO).
  async function buildWithdrawInputs(
    complianceSmt,
    { fullWithdrawal = false } = {},
  ) {
    const inputValues = [32, 40];
    const outputValues = fullWithdrawal ? [0] : [2];
    const amount = inputValues[0] + inputValues[1] - outputValues[0];

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

    const ownerNullifiers = [
      poseidonHash3([BigInt(inputValues[0]), salt1, senderPrivateKey]),
      poseidonHash3([BigInt(inputValues[1]), salt2, senderPrivateKey]),
    ];

    const enforcementNullifiers = [
      computeEnforcementNullifier(Alice.privKey, Enforcer.pubKey, input1),
      computeEnforcementNullifier(Alice.privKey, Enforcer.pubKey, input2),
    ];

    await smtUtxo.add(input1, input1);
    await smtUtxo.add(input2, input2);

    const utxoProof1 = await smtUtxo.generateCircomVerifierProof(
      input1,
      ZERO_HASH,
    );
    const utxoProof2 = await smtUtxo.generateCircomVerifierProof(
      input2,
      ZERO_HASH,
    );
    const utxosRoot = utxoProof1.root.bigInt();

    const salt3 = fullWithdrawal ? 0n : newSalt();
    const output1 = fullWithdrawal
      ? 0n
      : poseidonHash([BigInt(outputValues[0]), salt3, ...Alice.pubKey]);
    const outputCommitments = [output1];

    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();
    const encryptInputs = stringifyBigInts({
      encryptionNonce,
      ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
    });

    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const identitiesRoot = kycProofAlice.root.bigInt();

    const compProofAlice = await complianceSmt.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const complianceRoot = compProofAlice.root.bigInt();

    const circuitInputs = {
      amount,
      ownerNullifiers,
      enforcementNullifiers,
      outputCommitments,
      utxosRoot,
      identitiesRoot,
      complianceRoot,
      enabledInputs: [1, 1],
      arbiterPublicKey: Arbiter.pubKey,
      enforcerPublicKey: Enforcer.pubKey,
      recipient: RECIPIENT,
      inputCommitments,
      inputValues,
      inputSalts: [salt1, salt2],
      inputOwnerPrivateKey: senderPrivateKey,
      utxosMerkleProof: [
        utxoProof1.siblings.map((s) => s.bigInt()),
        utxoProof2.siblings.map((s) => s.bigInt()),
      ],
      // nOutputs + 1 = 2 proofs: [sender, changeOutputOwner]
      identitiesMerkleProof: [
        kycProofAlice.siblings.map((s) => s.bigInt()),
        fullWithdrawal
          ? Array(SMT_HEIGHT_IDENTITY).fill(0n)
          : kycProofAlice.siblings.map((s) => s.bigInt()),
      ],
      complianceMerkleProof: [
        compProofAlice.siblings.map((s) => s.bigInt()),
        fullWithdrawal
          ? Array(SMT_HEIGHT_COMPLIANCE).fill(0n)
          : compProofAlice.siblings.map((s) => s.bigInt()),
      ],
      outputValues,
      outputSalts: [salt3],
      outputOwnerPublicKeys: [Alice.pubKey],
      ...encryptInputs,
    };

    return {
      circuitInputs,
      inputValues,
      outputValues,
      amount,
      salts: { salt1, salt2, salt3 },
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

  it("should succeed for partial withdrawal, verify arbiter/enforcer decryption and public signal ordering", async function () {
    this.timeout(60000);

    const {
      circuitInputs,
      inputValues,
      outputValues,
      amount,
      salts,
      ownerNullifiers,
      enforcementNullifiers,
      outputCommitments,
      utxosRoot,
      identitiesRoot,
      complianceRoot,
      encryptionNonce,
      ephemeralKeypair,
    } = await buildWithdrawInputs(smtComplianceAllActive);

    const witness = await circuit.calculateWitness(circuitInputs, true);

    // Public signal ordering, read off zkp/artifacts/withdraw_nullifier_kyc_enforced.sym
    // (nPublic = 51; witness[0] is the constant 1, so signal i is witness[i]).
    // Circom orders public inputs by DECLARATION order in the template, not by the
    // order of the `{ public [...] }` list — do not re-derive this by hand.
    //   output signals (automatically public, appear first):
    //     [1-2]    ecdhPublicKey[2]
    //     [3-18]   encryptedValuesForArbiter[16]
    //     [19-34]  encryptedValuesForEnforcer[16]
    //   public input signals:
    //     [35]     amount
    //     [36-37]  ownerNullifiers[2]
    //     [38-39]  enforcementNullifiers[2]
    //     [40]     outputCommitments[1]
    //     [41]     utxosRoot
    //     [42]     identitiesRoot
    //     [43]     complianceRoot
    //     [44-45]  enabledInputs[2]
    //     [46]     encryptionNonce
    //     [47-48]  arbiterPublicKey[2]
    //     [49-50]  enforcerPublicKey[2]
    //     [51]     recipient

    expect(witness[35]).to.equal(BigInt(amount));
    expect(witness[36]).to.equal(BigInt(ownerNullifiers[0]));
    expect(witness[37]).to.equal(BigInt(ownerNullifiers[1]));
    expect(witness[38]).to.equal(BigInt(enforcementNullifiers[0]));
    expect(witness[39]).to.equal(BigInt(enforcementNullifiers[1]));
    expect(witness[40]).to.equal(BigInt(outputCommitments[0]));
    expect(witness[41]).to.equal(utxosRoot);
    expect(witness[42]).to.equal(identitiesRoot);
    expect(witness[43]).to.equal(complianceRoot);
    expect(witness[44]).to.equal(1n);
    expect(witness[45]).to.equal(1n);
    expect(witness[46]).to.equal(BigInt(encryptionNonce));
    expect(witness[47]).to.equal(Arbiter.pubKey[0]);
    expect(witness[48]).to.equal(Arbiter.pubKey[1]);
    expect(witness[49]).to.equal(Enforcer.pubKey[0]);
    expect(witness[50]).to.equal(Enforcer.pubKey[1]);
    expect(witness[51]).to.equal(RECIPIENT);

    // arbiter decrypts the 14-element authority plaintext
    const arbiterKey = genEcdhSharedKey(
      Arbiter.privKey,
      ephemeralKeypair.pubKey,
    );
    const arbiterCipherText = witness.slice(3, 19);
    const arbiterPlainText = poseidonDecrypt(
      arbiterCipherText,
      arbiterKey,
      encryptionNonce,
      14,
    );
    // [senderPubX, senderPubY, in1Value, in1Salt, in2Value, in2Salt,
    //  changeOwnerX, changeOwnerY, 0, 0, changeValue, changeSalt, 0, 0]
    expect(arbiterPlainText[0]).to.equal(Alice.pubKey[0]); // senderPubX
    expect(arbiterPlainText[1]).to.equal(Alice.pubKey[1]); // senderPubY
    expect(arbiterPlainText[2]).to.equal(BigInt(inputValues[0])); // in1Value
    expect(arbiterPlainText[3]).to.equal(salts.salt1); // in1Salt
    expect(arbiterPlainText[4]).to.equal(BigInt(inputValues[1])); // in2Value
    expect(arbiterPlainText[5]).to.equal(salts.salt2); // in2Salt
    expect(arbiterPlainText[6]).to.equal(Alice.pubKey[0]); // changeOwnerX
    expect(arbiterPlainText[7]).to.equal(Alice.pubKey[1]); // changeOwnerY
    expect(arbiterPlainText[8]).to.equal(0n); // virtual output owner X
    expect(arbiterPlainText[9]).to.equal(0n); // virtual output owner Y
    expect(arbiterPlainText[10]).to.equal(BigInt(outputValues[0])); // changeValue
    expect(arbiterPlainText[11]).to.equal(salts.salt3); // changeSalt
    expect(arbiterPlainText[12]).to.equal(0n); // virtual output value
    expect(arbiterPlainText[13]).to.equal(0n); // virtual output salt

    // enforcer decrypts the same 14-element plaintext via different ECDH key
    const enforcerKey = genEcdhSharedKey(
      Enforcer.privKey,
      ephemeralKeypair.pubKey,
    );
    const enforcerCipherText = witness.slice(19, 35);
    const enforcerPlainText = poseidonDecrypt(
      enforcerCipherText,
      enforcerKey,
      encryptionNonce,
      14,
    );
    expect(enforcerPlainText).to.deep.equal(arbiterPlainText);

    // non-authority cannot decrypt the ciphertext
    const wrongKey = genEcdhSharedKey(Alice.privKey, ephemeralKeypair.pubKey);
    expect(function () {
      poseidonDecrypt(arbiterCipherText, wrongKey, encryptionNonce, 14);
    }).to.throw();
  });

  it("should succeed for full withdrawal with zero change commitment", async function () {
    this.timeout(60000);

    const {
      circuitInputs,
      amount,
      outputCommitments,
      encryptionNonce,
      ephemeralKeypair,
    } = await buildWithdrawInputs(smtComplianceAllActive, {
      fullWithdrawal: true,
    });

    const witness = await circuit.calculateWitness(circuitInputs, true);

    expect(witness[35]).to.equal(BigInt(amount));
    expect(witness[40]).to.equal(BigInt(outputCommitments[0])); // 0n

    // arbiter can still see the full plaintext even with zero change
    const arbiterKey = genEcdhSharedKey(
      Arbiter.privKey,
      ephemeralKeypair.pubKey,
    );
    const arbiterPlainText = poseidonDecrypt(
      witness.slice(3, 19),
      arbiterKey,
      encryptionNonce,
      14,
    );
    // Input values are still visible to arbiter (non-repudiation even for full withdrawals)
    expect(arbiterPlainText[10]).to.equal(0n); // changeValue = 0
    expect(arbiterPlainText[12]).to.equal(0n); // virtual output value
    expect(arbiterPlainText[13]).to.equal(0n); // virtual output salt
  });

  it("should succeed for amount=0 withdrawal (note-washing attempt); arbiter CAN see the change output", async function () {
    this.timeout(60000);

    // amount=0: all value goes to the change output. This used to be a
    // note-washing vulnerability when the arbiter had no ciphertext.
    const inputValues = [10, 20];
    const outputValues = [30]; // amount = 30 - 30 = 0
    const amount = 0;

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

    const ownerNullifiers = [
      poseidonHash3([BigInt(inputValues[0]), salt1, senderPrivateKey]),
      poseidonHash3([BigInt(inputValues[1]), salt2, senderPrivateKey]),
    ];
    const enforcementNullifiers = [
      computeEnforcementNullifier(Alice.privKey, Enforcer.pubKey, input1),
      computeEnforcementNullifier(Alice.privKey, Enforcer.pubKey, input2),
    ];

    await smtUtxo.add(input1, input1);
    await smtUtxo.add(input2, input2);
    const utxoProof1 = await smtUtxo.generateCircomVerifierProof(
      input1,
      ZERO_HASH,
    );
    const utxoProof2 = await smtUtxo.generateCircomVerifierProof(
      input2,
      ZERO_HASH,
    );

    const salt3 = newSalt();
    const output1 = poseidonHash([
      BigInt(outputValues[0]),
      salt3,
      ...Alice.pubKey,
    ]);
    const encryptionNonce = newEncryptionNonce();
    const ephemeralKeypair = genKeypair();
    const kycProofAlice = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Alice.pubKey),
      ZERO_HASH,
    );
    const compProofAlice =
      await smtComplianceAllActive.generateCircomVerifierProof(
        poseidonHash2(Alice.pubKey),
        ZERO_HASH,
      );

    const circuitInputs = {
      amount,
      ownerNullifiers,
      enforcementNullifiers,
      outputCommitments: [output1],
      utxosRoot: utxoProof1.root.bigInt(),
      identitiesRoot: kycProofAlice.root.bigInt(),
      complianceRoot: compProofAlice.root.bigInt(),
      enabledInputs: [1, 1],
      arbiterPublicKey: Arbiter.pubKey,
      enforcerPublicKey: Enforcer.pubKey,
      recipient: RECIPIENT,
      inputCommitments: [input1, input2],
      inputValues,
      inputSalts: [salt1, salt2],
      inputOwnerPrivateKey: senderPrivateKey,
      utxosMerkleProof: [
        utxoProof1.siblings.map((s) => s.bigInt()),
        utxoProof2.siblings.map((s) => s.bigInt()),
      ],
      identitiesMerkleProof: [
        kycProofAlice.siblings.map((s) => s.bigInt()),
        kycProofAlice.siblings.map((s) => s.bigInt()),
      ],
      complianceMerkleProof: [
        compProofAlice.siblings.map((s) => s.bigInt()),
        compProofAlice.siblings.map((s) => s.bigInt()),
      ],
      outputValues,
      outputSalts: [salt3],
      outputOwnerPublicKeys: [Alice.pubKey],
      ...stringifyBigInts({
        encryptionNonce,
        ecdhPrivateKey: formatPrivKeyForBabyJub(ephemeralKeypair.privKey),
      }),
    };

    const witness = await circuit.calculateWitness(circuitInputs, true);

    // amount == 0 is valid (value conservation: 30 == 0 + 30)
    expect(witness[35]).to.equal(0n);

    // Arbiter CAN see the change output even when amount is zero —
    // this is the fix for the note-washing vulnerability.
    const arbiterKey = genEcdhSharedKey(
      Arbiter.privKey,
      ephemeralKeypair.pubKey,
    );
    const arbiterPlainText = poseidonDecrypt(
      witness.slice(3, 19),
      arbiterKey,
      encryptionNonce,
      14,
    );
    expect(arbiterPlainText[0]).to.equal(Alice.pubKey[0]); // sender identity visible
    expect(arbiterPlainText[2]).to.equal(BigInt(inputValues[0])); // input preimages visible
    expect(arbiterPlainText[4]).to.equal(BigInt(inputValues[1]));
    expect(arbiterPlainText[10]).to.equal(BigInt(outputValues[0])); // change output visible
    expect(arbiterPlainText[11]).to.equal(salt3);
  });

  it("should fail when a disabled input slot carries value", async function () {
    this.timeout(60000);

    // On the withdraw path: slot 1 is off at every zero-keyed gate while
    // inputValues[1] still feeds the conservation sum, so the ERC-20 payout is
    // 1_000_000 larger than the notes actually being spent.
    const { circuitInputs, inputValues, outputValues } =
      await buildWithdrawInputs(smtComplianceAllActive);
    const phantom = 1000000;
    circuitInputs.inputCommitments[1] = 0n;
    circuitInputs.ownerNullifiers[1] = 0n;
    circuitInputs.enforcementNullifiers[1] = 0n;
    circuitInputs.enabledInputs = [1, 0];
    circuitInputs.utxosMerkleProof[1] = Array(SMT_HEIGHT_UTXO).fill(0n);
    circuitInputs.inputValues = [inputValues[0], phantom];
    circuitInputs.amount = inputValues[0] + phantom - outputValues[0];

    await rejects(circuit, circuitInputs);
  });

  it("should succeed with a genuinely disabled, zero-value input slot", async function () {
    this.timeout(60000);

    // The legitimate 1-in withdrawal the gate must keep allowing.
    const { circuitInputs, inputValues, outputValues } =
      await buildWithdrawInputs(smtComplianceAllActive);
    circuitInputs.inputCommitments[1] = 0n;
    circuitInputs.ownerNullifiers[1] = 0n;
    circuitInputs.enforcementNullifiers[1] = 0n;
    circuitInputs.enabledInputs = [1, 0];
    circuitInputs.utxosMerkleProof[1] = Array(SMT_HEIGHT_UTXO).fill(0n);
    circuitInputs.inputValues = [inputValues[0], 0];
    circuitInputs.amount = inputValues[0] - outputValues[0];

    const witness = await circuit.calculateWitness(circuitInputs, true);
    await circuit.checkConstraints(witness);
  });

  it("should fail when the enforcement nullifiers are suppressed to zero", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildWithdrawInputs(smtComplianceAllActive);
    circuitInputs.enforcementNullifiers = [0, 0];

    await rejects(circuit, circuitInputs);
  });

  it("should fail when the disabled change output carries value", async function () {
    this.timeout(60000);

    // Output half on the withdraw path: zeroing the change commitment
    // skips CheckHashes, so the change note is never minted while its value
    // still reduces the public `amount`. The change disappears.
    const { circuitInputs } = await buildWithdrawInputs(smtComplianceAllActive);
    circuitInputs.outputCommitments = [0n];

    await rejects(circuit, circuitInputs);
  });

  it("should fail when the change output owner key has x == 0", async function () {
    this.timeout(60000);

    // On the withdraw path, this circuit never ran CheckBabyJubPublicKey
    // over its change output owner at all, so the key reached Kyc and
    // ComplianceStatus unchecked and both skipped on x == 0.
    const { circuitInputs, outputValues } = await buildWithdrawInputs(
      smtComplianceAllActive,
    );
    circuitInputs.outputOwnerPublicKeys[0] = [0n, 1n];
    circuitInputs.outputCommitments[0] = poseidonHash([
      BigInt(outputValues[0]),
      circuitInputs.outputSalts[0],
      0n,
      1n,
    ]);

    await rejects(circuit, circuitInputs);
  });

  it("should fail when the change output is redirected to a third party", async function () {
    this.timeout(60000);

    // This circuit deliberately omits per-receiver encryption, on the
    // stated premise that the change output owner is the sender and already
    // knows the preimage. Nothing enforced that premise, so the change could be
    // sent to any KYC-registered, ACTIVE third party — who then holds a note
    // whose preimage was never encrypted to them.
    const { circuitInputs, outputValues } = await buildWithdrawInputs(
      smtComplianceAllActive,
    );
    const kycProofBob = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Bob.pubKey),
      ZERO_HASH,
    );
    const compProofBob =
      await smtComplianceAllActive.generateCircomVerifierProof(
        poseidonHash2(Bob.pubKey),
        ZERO_HASH,
      );
    circuitInputs.outputOwnerPublicKeys[0] = Bob.pubKey;
    circuitInputs.outputCommitments[0] = poseidonHash([
      BigInt(outputValues[0]),
      circuitInputs.outputSalts[0],
      ...Bob.pubKey,
    ]);
    circuitInputs.identitiesMerkleProof[1] = kycProofBob.siblings.map((s) =>
      s.bigInt(),
    );
    circuitInputs.complianceMerkleProof[1] = compProofBob.siblings.map((s) =>
      s.bigInt(),
    );

    await rejects(circuit, circuitInputs);
  });

  it("should succeed when the change output goes back to the sender", async function () {
    this.timeout(60000);

    // The positive control for the binding above.
    const { circuitInputs } = await buildWithdrawInputs(smtComplianceAllActive);
    const witness = await circuit.calculateWitness(circuitInputs, true);
    await circuit.checkConstraints(witness);
  });

  it("should fail when the ephemeral key is zero", async function () {
    this.timeout(60000);

    // With a zero scalar every ECDH output is the curve identity,
    // so the "shared secret" is a constant any observer can compute. Every
    // ciphertext in the transaction — receiver, arbiter and enforcer — becomes
    // world-readable, and the published ephemeral public key is the identity.
    const { circuitInputs } = await buildWithdrawInputs(smtComplianceAllActive);
    circuitInputs.ecdhPrivateKey = 0;

    await rejects(circuit, circuitInputs);
  });

  it("should fail because sender has FROZEN compliance status", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildWithdrawInputs(
      smtComplianceSenderFrozen,
    );

    await rejects(circuit, circuitInputs);
  });

  it("should fail because value conservation is violated", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildWithdrawInputs(smtComplianceAllActive);

    // tamper: change the amount so sum(inputs) != amount + sum(outputs)
    // original: amount=70, inputs sum=72, outputs sum=2 → 72 == 70+2 ✓
    // tampered: amount=60 → 72 != 60+2 ✗
    circuitInputs.amount = 60;

    await rejects(circuit, circuitInputs);
  });

  it("should fail because enforcement nullifier is tampered", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildWithdrawInputs(smtComplianceAllActive);

    circuitInputs.enforcementNullifiers = [
      circuitInputs.enforcementNullifiers[0] + 1n,
      circuitInputs.enforcementNullifiers[1],
    ];

    await rejects(circuit, circuitInputs);
  });

  it("should fail if wrong enforcer public key is used", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildWithdrawInputs(smtComplianceAllActive);

    // enforcement nullifiers were derived with the original key;
    // supplying a different key produces a different ECDH shared secret
    const wrongEnforcer = genKeypair();
    circuitInputs.enforcerPublicKey = wrongEnforcer.pubKey;

    await rejects(circuit, circuitInputs);
  });
});

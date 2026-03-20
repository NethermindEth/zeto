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
const SMT_HEIGHT_IDENTITY = 64;
const SMT_HEIGHT_COMPLIANCE = 64;
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

describe("withdraw_nullifier_kyc_enforced circuit tests", () => {
  let circuit;
  let smtUtxo, smtKYC;
  let smtComplianceAllActive, smtComplianceSenderFrozen;

  const Alice = {};
  const Enforcer = {};
  let senderPrivateKey;

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(
        __dirname,
        "../../circuits/withdraw_nullifier_kyc_enforced.circom",
      ),
    );

    let keypair = genKeypair();
    Alice.privKey = keypair.privKey;
    Alice.pubKey = keypair.pubKey;
    senderPrivateKey = formatPrivKeyForBabyJub(Alice.privKey);

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
  async function buildWithdrawInputs(complianceSmt, { fullWithdrawal = false } = {}) {
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
      enforcerPublicKey: Enforcer.pubKey,
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

  it("should succeed for partial withdrawal, verify enforcer decryption and public signal ordering", async function () {
    this.timeout(60000);

    const {
      circuitInputs,
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

    // public signal ordering snapshot for Solidity integration:
    //   output signals (automatically public, appear first):
    //     [1-2]    ecdhPublicKey[2]
    //     [3-6]    encryptedValuesForEnforcer[4]
    //   public input signals (in { public [] } declaration order):
    //     [7]      amount
    //     [8-9]    ownerNullifiers[2]
    //     [10-11]  enforcementNullifiers[2]
    //     [12]     outputCommitments[1]
    //     [13]     utxosRoot
    //     [14]     identitiesRoot
    //     [15]     complianceRoot
    //     [16-17]  enabledInputs[2]
    //     [18]     encryptionNonce
    //     [19-20]  enforcerPublicKey[2]

    expect(witness[7]).to.equal(BigInt(amount));
    expect(witness[8]).to.equal(BigInt(ownerNullifiers[0]));
    expect(witness[9]).to.equal(BigInt(ownerNullifiers[1]));
    expect(witness[10]).to.equal(BigInt(enforcementNullifiers[0]));
    expect(witness[11]).to.equal(BigInt(enforcementNullifiers[1]));
    expect(witness[12]).to.equal(BigInt(outputCommitments[0]));
    expect(witness[13]).to.equal(utxosRoot);
    expect(witness[14]).to.equal(identitiesRoot);
    expect(witness[15]).to.equal(complianceRoot);
    expect(witness[16]).to.equal(1n);
    expect(witness[17]).to.equal(1n);
    expect(witness[18]).to.equal(BigInt(encryptionNonce));
    expect(witness[19]).to.equal(Enforcer.pubKey[0]);
    expect(witness[20]).to.equal(Enforcer.pubKey[1]);

    // enforcer decrypts the change output preimage: [changeValue, changeSalt]
    const enforcerKey = genEcdhSharedKey(
      Enforcer.privKey,
      ephemeralKeypair.pubKey,
    );
    const enforcerCipherText = witness.slice(3, 7);
    const enforcerPlainText = poseidonDecrypt(
      enforcerCipherText,
      enforcerKey,
      encryptionNonce,
      2,
    );
    expect(enforcerPlainText).to.deep.equal([
      BigInt(outputValues[0]),
      salts.salt3,
    ]);

    // non-enforcer cannot decrypt the ciphertext
    const wrongKey = genEcdhSharedKey(Alice.privKey, ephemeralKeypair.pubKey);
    expect(function () {
      poseidonDecrypt(enforcerCipherText, wrongKey, encryptionNonce, 2);
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

    expect(witness[7]).to.equal(BigInt(amount));
    expect(witness[12]).to.equal(BigInt(outputCommitments[0])); // 0n

    // enforcer ciphertext encrypts [0, 0] when change is zero
    const enforcerKey = genEcdhSharedKey(
      Enforcer.privKey,
      ephemeralKeypair.pubKey,
    );
    const enforcerPlainText = poseidonDecrypt(
      witness.slice(3, 7),
      enforcerKey,
      encryptionNonce,
      2,
    );
    expect(enforcerPlainText).to.deep.equal([0n, 0n]);
  });

  it("should fail because sender has FROZEN compliance status", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildWithdrawInputs(
      smtComplianceSenderFrozen,
    );

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.match(/SMTVerifier/);
  });

  it("should fail because value conservation is violated", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildWithdrawInputs(
      smtComplianceAllActive,
    );

    // tamper: change the amount so sum(inputs) != amount + sum(outputs)
    // original: amount=70, inputs sum=72, outputs sum=2 → 72 == 70+2 ✓
    // tampered: amount=60 → 72 != 60+2 ✗
    circuitInputs.amount = 60;

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.exist;
  });

  it("should fail because enforcement nullifier is tampered", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildWithdrawInputs(
      smtComplianceAllActive,
    );

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
    expect(err).to.match(/CheckEnforcementNullifiers/);
  });

  it("should fail if wrong enforcer public key is used", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildWithdrawInputs(
      smtComplianceAllActive,
    );

    // enforcement nullifiers were derived with the original key;
    // supplying a different key produces a different ECDH shared secret
    const wrongEnforcer = genKeypair();
    circuitInputs.enforcerPublicKey = wrongEnforcer.pubKey;

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.match(/CheckEnforcementNullifiers/);
  });
});
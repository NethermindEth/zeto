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

const SMT_HEIGHT_IDENTITY = 10;
const SMT_HEIGHT_COMPLIANCE = 10;
const poseidonHash = Poseidon.poseidon4;
const poseidonHash2 = Poseidon.poseidon2;
const poseidonHash3 = Poseidon.poseidon3;

const STATUS_ACTIVE = 1n;
const STATUS_FROZEN = 2n;

describe("deposit_kyc_non_repudiation_enforced circuit tests", () => {
  let circuit;
  let smtKYC;
  let smtComplianceAllActive, smtComplianceRecipientFrozen;

  const Alice = {};
  const Bob = {};
  const Arbiter = {};
  const Enforcer = {};

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(
        __dirname,
        "../../circuits/deposit_kyc_non_repudiation_enforced.circom",
      ),
    );

    let keypair = genKeypair();
    Alice.privKey = keypair.privKey;
    Alice.pubKey = keypair.pubKey;

    keypair = genKeypair();
    Bob.privKey = keypair.privKey;
    Bob.pubKey = keypair.pubKey;

    keypair = genKeypair();
    Arbiter.privKey = keypair.privKey;
    Arbiter.pubKey = keypair.pubKey;

    keypair = genKeypair();
    Enforcer.privKey = keypair.privKey;
    Enforcer.pubKey = keypair.pubKey;

    // initialize the identity Sparse Merkle Tree
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

    // Bob FROZEN (recipient FROZEN test)
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

  // Build circuit inputs for a standard 2-output deposit.
  // output 1 goes to Alice, output 2 goes to Bob.
  async function buildDepositInputs(complianceSmt) {
    const outputValues = [100, 200];

    const salt1 = newSalt();
    const output1 = poseidonHash([
      BigInt(outputValues[0]),
      salt1,
      ...Alice.pubKey,
    ]);
    const salt2 = newSalt();
    const output2 = poseidonHash([
      BigInt(outputValues[1]),
      salt2,
      ...Bob.pubKey,
    ]);
    const outputCommitments = [output1, output2];

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
    const kycProofBob = await smtKYC.generateCircomVerifierProof(
      poseidonHash2(Bob.pubKey),
      ZERO_HASH,
    );
    const identitiesRoot = kycProofAlice.root.bigInt();

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
      outputCommitments,
      outputValues,
      outputSalts: [salt1, salt2],
      outputOwnerPublicKeys: [Alice.pubKey, Bob.pubKey],
      identitiesRoot,
      identitiesMerkleProof: [
        kycProofAlice.siblings.map((s) => s.bigInt()),
        kycProofBob.siblings.map((s) => s.bigInt()),
      ],
      complianceRoot,
      complianceMerkleProof: [
        compProofAlice.siblings.map((s) => s.bigInt()),
        compProofBob.siblings.map((s) => s.bigInt()),
      ],
      arbiterPublicKey: Arbiter.pubKey,
      enforcerPublicKey: Enforcer.pubKey,
      ...encryptInputs,
    };

    return {
      circuitInputs,
      outputValues,
      salts: { salt1, salt2 },
      outputCommitments,
      identitiesRoot,
      complianceRoot,
      encryptionNonce,
      ephemeralKeypair,
    };
  }

  it("should succeed for valid deposit, verify amount binding and authority decryption", async function () {
    this.timeout(60000);

    const {
      circuitInputs,
      outputValues,
      salts,
      outputCommitments,
      identitiesRoot,
      complianceRoot,
      encryptionNonce,
      ephemeralKeypair,
    } = await buildDepositInputs(smtComplianceAllActive);

    const witness = await circuit.calculateWitness(circuitInputs, true);

    // public signal ordering snapshot for Solidity integration:
    //   output signals (automatically public, appear first):
    //     [1]      out (deposit amount = publicInputs[0])
    //     [2-3]    ecdhPublicKey[2]
    //     [4-11]   encryptedValuesForReceiver[2][4]
    //     [12-27]  encryptedValuesForArbiter[16]
    //     [28-43]  encryptedValuesForEnforcer[16]
    //   public input signals (in { public [] } declaration order):
    //     [44-45]  outputCommitments[2]
    //     [46]     identitiesRoot
    //     [47]     complianceRoot
    //     [48]     encryptionNonce
    //     [49-50]  arbiterPublicKey[2]
    //     [51-52]  enforcerPublicKey[2]

    // amount binding: out == sum(outputValues)
    expect(witness[1]).to.equal(BigInt(outputValues[0] + outputValues[1]));

    expect(witness[44]).to.equal(BigInt(outputCommitments[0]));
    expect(witness[45]).to.equal(BigInt(outputCommitments[1]));
    expect(witness[46]).to.equal(identitiesRoot);
    expect(witness[47]).to.equal(complianceRoot);
    expect(witness[48]).to.equal(BigInt(encryptionNonce));
    expect(witness[49]).to.equal(Arbiter.pubKey[0]);
    expect(witness[50]).to.equal(Arbiter.pubKey[1]);
    expect(witness[51]).to.equal(Enforcer.pubKey[0]);
    expect(witness[52]).to.equal(Enforcer.pubKey[1]);

    // receiver decryption: Alice decrypts output 1
    let cipherText = witness.slice(4, 8);
    let recoveredKey = genEcdhSharedKey(Alice.privKey, ephemeralKeypair.pubKey);
    let plainText = poseidonDecrypt(
      cipherText,
      recoveredKey,
      encryptionNonce,
      2,
    );
    expect(plainText).to.deep.equal([BigInt(outputValues[0]), salts.salt1]);

    // Bob decrypts output 2
    cipherText = witness.slice(8, 12);
    recoveredKey = genEcdhSharedKey(Bob.privKey, ephemeralKeypair.pubKey);
    plainText = poseidonDecrypt(cipherText, recoveredKey, encryptionNonce, 2);
    expect(plainText).to.deep.equal([BigInt(outputValues[1]), salts.salt2]);

    // arbiter decrypts the 14-element authority plaintext
    const arbiterKey = genEcdhSharedKey(
      Arbiter.privKey,
      ephemeralKeypair.pubKey,
    );
    const arbiterCipherText = witness.slice(12, 28);
    const arbiterPlainText = poseidonDecrypt(
      arbiterCipherText,
      arbiterKey,
      encryptionNonce,
      14,
    );
    // depositor pubkey = ecdhPublicKey (from ecdhPrivateKey via BabyPbk)
    const depositorPubKey = [witness[2], witness[3]];
    expect(arbiterPlainText).to.deep.equal([
      depositorPubKey[0], // depositor public key
      depositorPubKey[1],
      0n, // input fields zeroed for deposit
      0n,
      0n,
      0n,
      Alice.pubKey[0], // output 1 owner
      Alice.pubKey[1],
      Bob.pubKey[0], // output 2 owner
      Bob.pubKey[1],
      BigInt(outputValues[0]), // output values and salts
      salts.salt1,
      BigInt(outputValues[1]),
      salts.salt2,
    ]);

    // enforcer decrypts the same schema with a different ECDH key
    const enforcerKey = genEcdhSharedKey(
      Enforcer.privKey,
      ephemeralKeypair.pubKey,
    );
    const enforcerCipherText = witness.slice(28, 44);
    const enforcerPlainText = poseidonDecrypt(
      enforcerCipherText,
      enforcerKey,
      encryptionNonce,
      14,
    );
    expect(enforcerPlainText).to.deep.equal(arbiterPlainText);

    // non-authority cannot decrypt arbiter ciphertext
    expect(function () {
      poseidonDecrypt(arbiterCipherText, recoveredKey, encryptionNonce, 14);
    }).to.throw();

    // non-authority cannot decrypt enforcer ciphertext
    expect(function () {
      poseidonDecrypt(enforcerCipherText, recoveredKey, encryptionNonce, 14);
    }).to.throw();
  });

  it("should fail because output recipient has FROZEN compliance status", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildDepositInputs(
      smtComplianceRecipientFrozen,
    );

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.match(/SMTVerifier/);
  });

  it("should succeed with a disabled output slot (commitment == 0)", async function () {
    this.timeout(60000);

    const outputValues = [300, 0];
    const salt1 = newSalt();
    const output1 = poseidonHash([
      BigInt(outputValues[0]),
      salt1,
      ...Alice.pubKey,
    ]);
    const outputCommitments = [output1, 0n];

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

    const compProofAlice =
      await smtComplianceAllActive.generateCircomVerifierProof(
        poseidonHash2(Alice.pubKey),
        ZERO_HASH,
      );

    const witness = await circuit.calculateWitness(
      {
        outputCommitments,
        outputValues,
        outputSalts: [salt1, 0n],
        // BabyCheck requires a valid curve point even for disabled slots;
        // Alice's key is valid and will be gated to (0,0) by isCommitmentZero
        outputOwnerPublicKeys: [Alice.pubKey, Alice.pubKey],
        identitiesRoot: kycProofAlice.root.bigInt(),
        identitiesMerkleProof: [
          kycProofAlice.siblings.map((s) => s.bigInt()),
          Array(SMT_HEIGHT_IDENTITY).fill(0n), // disabled slot
        ],
        complianceRoot: compProofAlice.root.bigInt(),
        complianceMerkleProof: [
          compProofAlice.siblings.map((s) => s.bigInt()),
          Array(SMT_HEIGHT_COMPLIANCE).fill(0n), // disabled slot
        ],
        arbiterPublicKey: Arbiter.pubKey,
        enforcerPublicKey: Enforcer.pubKey,
        ...encryptInputs,
      },
      true,
    );

    expect(witness[1]).to.equal(300n); // out == sum(outputValues)
    expect(witness[45]).to.equal(0n); // outputCommitments[1] == 0
  });

  it("should fail because output commitment does not match preimage", async function () {
    this.timeout(60000);

    const { circuitInputs } = await buildDepositInputs(
      smtComplianceAllActive,
    );

    // tamper: supply wrong value but keep original commitment
    circuitInputs.outputValues = [999, 200];

    let err;
    try {
      await circuit.calculateWitness(circuitInputs, true);
    } catch (e) {
      err = e;
    }
    expect(err).to.match(/CheckHashes/);
  });
});
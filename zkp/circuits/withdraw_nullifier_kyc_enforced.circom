pragma circom 2.2.2;

include "./lib/check-positive.circom";
include "./lib/check-hashes.circom";
include "./lib/check-nullifiers.circom";
include "./lib/check-smt-proof.circom";
include "./lib/check-enforcement-nullifiers.circom";
include "./lib/check-babyjub-public-key.circom";
include "./lib/kyc.circom";
include "./lib/compliance_status.circom";
include "./lib/ecdh.circom";
include "./lib/encrypt.circom";
include "./node_modules/circomlib/circuits/babyjub.circom";
include "./node_modules/circomlib/circuits/comparators.circom";

// This circuit performs the following operations for an AENKNR-E withdrawal:
// - derive the sender's public key from the sender's private key
// - check the input and output commitments match the expected hashes
// - check the owner nullifiers are derived from the input values, salts, and owner private key
// - check the enforcement nullifiers are derived via ECDH(ownerPriv, enforcerPub)
// - check value conservation: sum(inputValues) == amount + sum(outputValues)
// - check the input commitments exist in the UTXO Sparse Merkle Tree
// - validate arbiterPublicKey and enforcerPublicKey lie on the BabyJubJub curve
// - check sender is KYC-registered and has ACTIVE compliance status
// - check non-zero change output owner is KYC-registered and has ACTIVE compliance status
// - encrypt all secrets for the arbiter (non-repudiation)
// - encrypt all secrets for the enforcer (seizure capability)
//
// Uses the unified 14-element authority plaintext schema (same as transfer/deposit):
//   [senderPubX, senderPubY, in1Value, in1Salt, in2Value, in2Salt,
//    out1OwnerX, out1OwnerY, out2OwnerX, out2OwnerY,
//    out1Value, out1Salt, out2Value, out2Salt]
// nVirtualOutputs = 1: pads the single change output to 2 outputs, matching
// the transfer layout so arbiter/enforcer use a single decryption schema.
//
// No per-receiver encryption (EncryptOutputs) — the change output owner is the
// sender themselves; they already know the preimage.
template WithdrawEnforced(nInputs, nOutputs, nUTXOSMTLevels, nIdentitiesSMTLevels, nComplianceSMTLevels) {
  signal input amount;
  signal input ownerNullifiers[nInputs];
  signal input enforcementNullifiers[nInputs];
  signal input outputCommitments[nOutputs];
  signal input utxosRoot;
  signal input identitiesRoot;
  signal input complianceRoot;
  signal input enabledInputs[nInputs];
  signal input encryptionNonce;
  signal input arbiterPublicKey[2];
  signal input enforcerPublicKey[2];

  signal input inputCommitments[nInputs];
  signal input inputValues[nInputs];
  signal input inputSalts[nInputs];
  // must be properly hashed and trimmed to be compatible with the BabyJub curve.
  // Reference: https://github.com/iden3/circomlib/blob/master/test/babyjub.js#L103
  signal input inputOwnerPrivateKey;
  // an ephemeral private key that is used to generate the shared ECDH key for encryption
  signal input ecdhPrivateKey;
  signal input utxosMerkleProof[nInputs][nUTXOSMTLevels];
  signal input identitiesMerkleProof[nOutputs + 1][nIdentitiesSMTLevels];
  signal input complianceMerkleProof[nOutputs + 1][nComplianceSMTLevels];
  signal input outputValues[nOutputs];
  signal input outputSalts[nOutputs];
  signal input outputOwnerPublicKeys[nOutputs][2];

  // the output for the public key of the ephemeral private key used in generating ECDH shared key
  signal output ecdhPublicKey[2];

  // Full 14-element authority schema (matches transfer/deposit):
  // [senderPubX, senderPubY, in1Value, in1Salt, in2Value, in2Salt,
  //  out1OwnerX, out1OwnerY, out2OwnerX, out2OwnerY,
  //  out1Value, out1Salt, out2Value, out2Salt]
  var nVirtualOutputs = 2 - nOutputs;   // = 1 for this circuit (nOutputs=1)
  var authorityPlaintextLength = 2 + 2 * nInputs + 2 * (nOutputs + nVirtualOutputs) + 2 * (nOutputs + nVirtualOutputs);
  // = 2 + 4 + 4 + 4 = 14
  var l = authorityPlaintextLength;
  if (l % 3 != 0) {
    l += (3 - (l % 3));
  }
  // 14 → padded to 15 (next multiple of 3) → output length = 16
  signal output encryptedValuesForArbiter[l + 1];
  signal output encryptedValuesForEnforcer[l + 1];

  // Derive sender's public key from private key (key ownership proof).
  // Single inputOwnerPrivateKey for all inputs → single-sender model.
  var inputOwnerPubKeyAx, inputOwnerPubKeyAy;
  (inputOwnerPubKeyAx, inputOwnerPubKeyAy) = BabyPbk()(in <== inputOwnerPrivateKey);

  CheckPositive(nOutputs)(outputValues <== outputValues);

  CommitmentInputs() inAuxInputs[nInputs];
  for (var i = 0; i < nInputs; i++) {
    inAuxInputs[i].value <== inputValues[i];
    inAuxInputs[i].salt <== inputSalts[i];
    inAuxInputs[i].ownerPublicKey <== [inputOwnerPubKeyAx, inputOwnerPubKeyAy];
  }

  CommitmentInputs() outAuxInputs[nOutputs];
  for (var i = 0; i < nOutputs; i++) {
    outAuxInputs[i].value <== outputValues[i];
    outAuxInputs[i].salt <== outputSalts[i];
    outAuxInputs[i].ownerPublicKey <== outputOwnerPublicKeys[i];
  }

  CheckHashes(nInputs)(commitmentHashes <== inputCommitments, commitmentInputs <== inAuxInputs);
  CheckHashes(nOutputs)(commitmentHashes <== outputCommitments, commitmentInputs <== outAuxInputs);

  // Owner nullifier = Poseidon(3)([value, salt, ownerPrivKey]).
  // Shares (values, salts, privKey) with CheckHashes above, so nullifiers
  // are transitively bound to the same input commitments.
  CheckNullifiers(nInputs)(nullifiers <== ownerNullifiers, values <== inputValues, salts <== inputSalts, ownerPrivateKey <== inputOwnerPrivateKey);

  // Value conservation: sum(inputValues) == amount + sum(outputValues)
  // GreaterEqThan provides range validation (both sums fit in 100 bits,
  // preventing field-wraparound attacks); IsEqual binds the public amount.
  var sumInputs = 0;
  for (var i = 0; i < nInputs; i++) {
    sumInputs = sumInputs + inputValues[i];
  }
  var sumOutputs = 0;
  for (var i = 0; i < nOutputs; i++) {
    sumOutputs = sumOutputs + outputValues[i];
  }

  var greaterEqThan;
  greaterEqThan = GreaterEqThan(100)(in <== [sumInputs, sumOutputs]);
  greaterEqThan === 1;

  var isSumEqual;
  isSumEqual = IsEqual()(in <== [sumInputs, amount + sumOutputs]);
  isSumEqual === 1;

  // With the above steps, we demonstrated that the nullifiers
  // are securely bound to the input commitments. Now we need to
  // demonstrate that the input commitments belong to the Sparse
  // Merkle Tree with the root `utxosRoot`.
  CheckSMTProof(nInputs, nUTXOSMTLevels)(root <== utxosRoot, merkleProof <== utxosMerkleProof, enabled <== enabledInputs, leafNodeIndexes <== inputCommitments, leafNodeValues <== inputCommitments);

  // Validate external public keys lie on the BabyJubJub curve.
  // Keys derived in-circuit via BabyPbk (inputOwnerPublicKey) are exempt.
  CheckBabyJubPublicKey()(publicKey <== arbiterPublicKey);
  CheckBabyJubPublicKey()(publicKey <== enforcerPublicKey);

  // Check that the sender and non-zero change output owners are
  // KYC-registered and have ACTIVE compliance status.
  // Zero-commitment gating: disabled output slots produce zero public keys,
  // which Kyc and ComplianceStatus skip via pubkey-zero gating.
  var ownerPublicKeys[nOutputs + 1][2];
  ownerPublicKeys[0] = [inputOwnerPubKeyAx, inputOwnerPubKeyAy];
  var isCommitmentZero[nOutputs];
  for (var i = 0; i < nOutputs; i++) {
    isCommitmentZero[i] = IsZero()(in <== outputCommitments[i]);
    ownerPublicKeys[i + 1][0] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][0];
    ownerPublicKeys[i + 1][1] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][1];
  }
  Kyc(nOutputs + 1, nIdentitiesSMTLevels)(publicKeys <== ownerPublicKeys, root <== identitiesRoot, merkleProof <== identitiesMerkleProof);

  // STATUS=1 is a compile-time constant (ACTIVE), preventing prover substitution.
  ComplianceStatus(nOutputs + 1, nComplianceSMTLevels, 1)(publicKeys <== ownerPublicKeys, root <== complianceRoot, merkleProof <== complianceMerkleProof);

  // Check enforcement nullifiers. Uses the same inputCommitments passed to
  // CheckHashes and CheckSMTProof — binding enforcement nullifiers to the
  // same verified, SMT-included notes as owner nullifiers.
  // In the withdraw path:
  //   ecdhKey = inputOwnerPrivateKey, counterpartyPublicKey = enforcerPublicKey
  // DH symmetry: ECDH(ownerPriv, enfPub) == ECDH(enfPriv, ownerPub)
  CheckEnforcementNullifiers(nInputs)(enforcementNullifiers <== enforcementNullifiers, inputCommitments <== inputCommitments, counterpartyPublicKey <== enforcerPublicKey, ecdhKey <== inputOwnerPrivateKey);

  // Derive the ECDH public key separately here because this circuit does not
  // use EncryptOutputs (which normally derives it). The arbiter/enforcer needs
  // this public key to compute the shared secret.
  (ecdhPublicKey[0], ecdhPublicKey[1]) <== BabyPbk()(in <== ecdhPrivateKey);

  // Assemble authority plaintext (14-element unified schema):
  // [senderPubX, senderPubY, in1Value, in1Salt, in2Value, in2Salt,
  //  changeOwnerX, changeOwnerY, 0, 0,      ← real output + virtual
  //  changeValue, changeSalt, 0, 0]          ← real output + virtual
  var plainText[authorityPlaintextLength];
  plainText[0] = inputOwnerPubKeyAx;
  plainText[1] = inputOwnerPubKeyAy;
  var idx = 2;
  for (var i = 0; i < nInputs; i++) {
    plainText[idx] = inputValues[i];
    idx++;
    plainText[idx] = inputSalts[i];
    idx++;
  }
  for (var i = 0; i < nOutputs; i++) {
    plainText[idx] = outputOwnerPublicKeys[i][0];
    idx++;
    plainText[idx] = outputOwnerPublicKeys[i][1];
    idx++;
  }
  // virtual output owner keys (zero-padded)
  for (var i = 0; i < nVirtualOutputs; i++) {
    plainText[idx] = 0;
    idx++;
    plainText[idx] = 0;
    idx++;
  }
  for (var i = 0; i < nOutputs; i++) {
    plainText[idx] = outputValues[i];
    idx++;
    plainText[idx] = outputSalts[i];
    idx++;
  }
  // virtual output values/salts (zero-padded)
  for (var i = 0; i < nVirtualOutputs; i++) {
    plainText[idx] = 0;
    idx++;
    plainText[idx] = 0;
    idx++;
  }

  // Arbiter ciphertext (non-repudiation)
  var sharedSecretArbiter[2];
  sharedSecretArbiter = Ecdh()(privKey <== ecdhPrivateKey, pubKey <== arbiterPublicKey);
  encryptedValuesForArbiter <== SymmetricEncrypt(authorityPlaintextLength)(plainText <== plainText, key <== sharedSecretArbiter, nonce <== encryptionNonce);

  // Enforcer ciphertext (seizure capability)
  var sharedSecretEnforcer[2];
  sharedSecretEnforcer = Ecdh()(privKey <== ecdhPrivateKey, pubKey <== enforcerPublicKey);
  encryptedValuesForEnforcer <== SymmetricEncrypt(authorityPlaintextLength)(plainText <== plainText, key <== sharedSecretEnforcer, nonce <== encryptionNonce);
}

// Output signals (signal output in template, not in { public [] }):
//   ecdhPublicKey[2], encryptedValuesForArbiter[16], encryptedValuesForEnforcer[16]
component main { public [ amount, ownerNullifiers, enforcementNullifiers, outputCommitments,
                          utxosRoot, identitiesRoot, complianceRoot, enabledInputs,
                          encryptionNonce, arbiterPublicKey, enforcerPublicKey ] }
  = WithdrawEnforced(2, 1, 64, 64, 64);
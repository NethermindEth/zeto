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
// - validate enforcerPublicKey lies on the BabyJubJub curve (defence-in-depth)
// - check sender is KYC-registered and has ACTIVE compliance status
// - check non-zero change output owner is KYC-registered and has ACTIVE compliance status
// - encrypt change output preimage for the enforcer (seizure capability for change UTXO)
//
// No arbiter ciphertext in this circuit — the withdrawal amount and ERC-20 destination
// are already public on-chain. Only the change output preimage is encrypted to the
// enforcer so they can seize it if needed.
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

  // enforcer ciphertext for the change output: [changeValue, changeSalt] per output
  // SymmetricEncrypt pads to multiple of 3; output length = padded length + 1
  var enforcerPlaintextLength = 2 * nOutputs;
  var el = enforcerPlaintextLength;
  if (el % 3 != 0) {
    el += (3 - (el % 3));
  }
  signal output encryptedValuesForEnforcer[el + 1];

  // derive the sender's public key from the secret input
  // for the sender's private key. This step demonstrates
  // the sender really owns the private key for the input UTXOs
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

  // Validate enforcerPublicKey lies on the BabyJubJub curve.
  // Only external public key entering ECDH in this circuit;
  // sender key is derived in-circuit via BabyPbk (exempt).
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

  // Check enforcement nullifiers. In the withdraw path:
  //   ecdhKey = inputOwnerPrivateKey, counterpartyPublicKey = enforcerPublicKey
  // DH symmetry ensures: ECDH(ownerPriv, enfPub) == ECDH(enfPriv, ownerPub)
  CheckEnforcementNullifiers(nInputs)(enforcementNullifiers <== enforcementNullifiers, inputCommitments <== inputCommitments, counterpartyPublicKey <== enforcerPublicKey, ecdhKey <== inputOwnerPrivateKey);

  // Derive the ECDH public key so the enforcer can compute the same
  // shared secret for decryption: ECDH(enforcerPrivKey, ecdhPublicKey)
  (ecdhPublicKey[0], ecdhPublicKey[1]) <== BabyPbk()(in <== ecdhPrivateKey);

  // Encrypt change output preimage for the enforcer.
  // Allows the enforcer to recover (changeValue, changeSalt) for future forced transfer.
  // When change commitment is zero (full withdrawal), outputValues[0] = 0 by value
  // conservation, so the ciphertext encrypts [0, salt] — content is irrelevant.
  var sharedSecretEnforcer[2];
  sharedSecretEnforcer = Ecdh()(privKey <== ecdhPrivateKey, pubKey <== enforcerPublicKey);
  var enforcerPlaintext[enforcerPlaintextLength];
  for (var i = 0; i < nOutputs; i++) {
    enforcerPlaintext[i * 2] = outputValues[i];
    enforcerPlaintext[i * 2 + 1] = outputSalts[i];
  }
  encryptedValuesForEnforcer <== SymmetricEncrypt(enforcerPlaintextLength)(plainText <== enforcerPlaintext, key <== sharedSecretEnforcer, nonce <== encryptionNonce);
}

// Output signals (signal output in template, not in { public [] }):
//   ecdhPublicKey[2], encryptedValuesForEnforcer[4]
component main { public [ amount, ownerNullifiers, enforcementNullifiers, outputCommitments,
                          utxosRoot, identitiesRoot, complianceRoot, enabledInputs,
                          encryptionNonce, enforcerPublicKey ] }
  = WithdrawEnforced(2, 1, 64, 10, 10);
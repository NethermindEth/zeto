pragma circom 2.2.2;

include "./lib/check-positive.circom";
include "./lib/check-hashes.circom";
include "./lib/check-sum.circom";
include "./lib/check-smt-proof.circom";
include "./lib/check-enforcement-nullifiers.circom";
include "./lib/check-babyjub-public-key.circom";
include "./lib/kyc.circom";
include "./lib/compliance_status.circom";
include "./lib/encrypt-outputs.circom";
include "./node_modules/circomlib/circuits/babyjub.circom";
include "./node_modules/circomlib/circuits/comparators.circom";
include "./node_modules/circomlib/circuits/poseidon.circom";
include "./node_modules/circomlib/circuits/smt/smtverifier.circom";

// This circuit performs the following operations for an AENKNR-E forced transfer (seizure):
// - prove knowledge of the enforcer private key: BabyPbk(enforcerPrivKey) == enforcerPublicKey
// - check the input and output commitments match the expected hashes
// - enforce single-frozen-owner: all inputs use the same seizedOwnerPublicKey
//   (if any input belongs to a different owner, CheckHashes will fail)
// - check value conservation: sum(inputValues) == sum(outputValues)
// - check each enabled input commitment exists in the UTXO Sparse Merkle Tree
// - validate all external public keys lie on the BabyJubJub curve (defence-in-depth)
// - check seized owner is KYC-registered and has FROZEN compliance status
// - check all non-zero output owners are KYC-registered in the identities SMT
// - check output compliance via isChangeBack mux:
//     change back to the same frozen owner → FROZEN compliance check
//     output to a new recipient → ACTIVE compliance check
// - check enforcement nullifiers via ECDH(enforcerPriv, seizedOwnerPub) (DH symmetry)
// - encrypt output UTXOs for their receivers (per-receiver ECDH encryption)
// - encrypt all secrets for the arbiter (non-repudiation audit trail)
// - encrypt all secrets for the enforcer (record-keeping and future seizure capability)
//
// No owner nullifiers in this circuit — the enforcer does not know the owner's
// private key and cannot compute them. Only enforcement nullifiers are used.
//
// Privacy: inputCommitments and seizedOwnerPublicKey are private witnesses — the
// on-chain transaction cannot be linked to specific UTXO history or identity.
//
// Binding: seizedOwnerPublicKey enters three constraint paths — CheckHashes
// (commitment preimage), ComplianceStatus (FROZEN assertion), and
// CheckEnforcementNullifiers (ECDH counterparty). A prover cannot misrepresent
// the seized identity without invalidating at least one of these.
template ForcedTransferEnforced(nInputs, nOutputs, nUTXOSMTLevels, nIdentitiesSMTLevels, nComplianceSMTLevels) {
  signal input enforcementNullifiers[nInputs];
  signal input outputCommitments[nOutputs];
  signal input utxosRoot;
  signal input identitiesRoot;
  signal input complianceRoot;
  signal input enabledInputs[nInputs];
  signal input enforcerPublicKey[2];
  signal input encryptionNonce;
  signal input arbiterPublicKey[2];
  signal input inputCommitments[nInputs];
  signal input inputValues[nInputs];
  signal input inputSalts[nInputs];
  signal input seizedOwnerPublicKey[2];
  // must be properly hashed and trimmed to be compatible with the BabyJub curve.
  // Reference: https://github.com/iden3/circomlib/blob/master/test/babyjub.js#L103
  signal input enforcerPrivateKey;
  // an ephemeral private key that is used to generate the shared ECDH key for encryption
  signal input ecdhPrivateKey;
  signal input utxosMerkleProof[nInputs][nUTXOSMTLevels];
  // index 0: seized owner; indices 1..nOutputs: output owners (zero-commitment gated)
  signal input identitiesMerkleProof[nOutputs + 1][nIdentitiesSMTLevels];
  // index 0: seized owner (FROZEN check); indices 1..nOutputs: output owners (isChangeBack mux)
  signal input complianceMerkleProof[nOutputs + 1][nComplianceSMTLevels];
  signal input outputValues[nOutputs];
  signal input outputSalts[nOutputs];
  signal input outputOwnerPublicKeys[nOutputs][2];

  // the output for the public key of the ephemeral private key used in generating ECDH shared key
  signal output ecdhPublicKey[2];

  // the output for the list of encrypted output UTXOs cipher texts
  signal output encryptedValuesForReceiver[nOutputs][4];

  // Poseidon sponge encryption absorbs plaintext in 3-element blocks, so the
  // plaintext is zero-padded to n = ceil(length/3) blocks. Each block emits 3
  // ciphertext elements, plus one final authentication tag → output = 3n + 1.
  // input length:
  //   - seized owner public key (x, y): 2
  //   - secrets (value and salt) for each input UTXOs: 2 * nInputs
  //   - output owner public keys (x, y): 2 * nOutputs
  //   - secrets (value and salt) for each output UTXOs: 2 * nOutputs
  var authorityPlaintextLength = 2 + 2 * nInputs + 2 * nOutputs + 2 * nOutputs;
  var l = authorityPlaintextLength;
  if (l % 3 != 0) {
    l += (3 - (l % 3));
  }
  signal output encryptedValuesForArbiter[l + 1];
  signal output encryptedValuesForEnforcer[l + 1];

  // Access-control gate: prove the prover holds the enforcer's private key.
  // BabyPbk derives the public key; the equality constraint binds it to the
  // contract-injected public input. Without enforcerPrivateKey, no valid proof.
  var enforcerDerivedPubX, enforcerDerivedPubY;
  (enforcerDerivedPubX, enforcerDerivedPubY) = BabyPbk()(in <== enforcerPrivateKey);
  enforcerDerivedPubX === enforcerPublicKey[0];
  enforcerDerivedPubY === enforcerPublicKey[1];

  CheckPositive(nOutputs)(outputValues <== outputValues);

  // Input commitment preimage integrity.
  // Using seizedOwnerPublicKey for ALL inputs enforces the single-frozen-owner
  // constraint: if any input belonged to a different owner, the hash would not match
  // the actual commitment and CheckHashes would fail.
  // This also binds seizedOwnerPublicKey to the input notes — the prover cannot
  // lie about the seized identity without invalidating the commitment preimages.
  CommitmentInputs() inAuxInputs[nInputs];
  for (var i = 0; i < nInputs; i++) {
    inAuxInputs[i].value <== inputValues[i];
    inAuxInputs[i].salt <== inputSalts[i];
    inAuxInputs[i].ownerPublicKey <== seizedOwnerPublicKey;
  }
  CheckHashes(nInputs)(commitmentHashes <== inputCommitments, commitmentInputs <== inAuxInputs);

  CommitmentInputs() outAuxInputs[nOutputs];
  for (var i = 0; i < nOutputs; i++) {
    outAuxInputs[i].value <== outputValues[i];
    outAuxInputs[i].salt <== outputSalts[i];
    outAuxInputs[i].ownerPublicKey <== outputOwnerPublicKeys[i];
  }
  CheckHashes(nOutputs)(commitmentHashes <== outputCommitments, commitmentInputs <== outAuxInputs);

  CheckSum(nInputs, nOutputs)(inputValues <== inputValues, outputValues <== outputValues);

  // Each enabled input must exist in the UTXO Sparse Merkle Tree.
  // The proof is private (Merkle paths are private witnesses); only the root is public.
  CheckSMTProof(nInputs, nUTXOSMTLevels)(root <== utxosRoot, merkleProof <== utxosMerkleProof, enabled <== enabledInputs, leafNodeIndexes <== inputCommitments, leafNodeValues <== inputCommitments);

  // Validate external public keys are on the BabyJubJub curve.
  // Keys derived in-circuit via BabyPbk (enforcerPublicKey) are exempt.
  // seizedOwnerPublicKey enters ECDH as counterparty — must be validated.
  // External keys entering ECDH must pass BabyCheck for defence-in-depth.
  CheckBabyJubPublicKey()(publicKey <== arbiterPublicKey);
  CheckBabyJubPublicKey()(publicKey <== seizedOwnerPublicKey);
  for (var i = 0; i < nOutputs; i++) {
    CheckBabyJubPublicKey()(publicKey <== outputOwnerPublicKeys[i]);
  }

  // Check that the seized owner and non-zero output owner public keys are
  // included in the identities Sparse Merkle Tree with the root `identitiesRoot`.
  // Zero-commitment gating: disabled output slots produce zero public keys,
  // which Kyc skips via pubkey-zero gating (mirrors kyc.circom pattern).
  var kycPublicKeys[nOutputs + 1][2];
  kycPublicKeys[0] = [seizedOwnerPublicKey[0], seizedOwnerPublicKey[1]];
  var isCommitmentZero[nOutputs];
  for (var i = 0; i < nOutputs; i++) {
    isCommitmentZero[i] = IsZero()(in <== outputCommitments[i]);
    kycPublicKeys[i + 1][0] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][0];
    kycPublicKeys[i + 1][1] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][1];
  }
  Kyc(nOutputs + 1, nIdentitiesSMTLevels)(publicKeys <== kycPublicKeys, root <== identitiesRoot, merkleProof <== identitiesMerkleProof);

  // Check that the seized owner has FROZEN compliance status.
  // STATUS=2 is a compile-time constant (FROZEN), preventing prover substitution.
  var seizedOwnerKeys[1][2];
  seizedOwnerKeys[0] = [seizedOwnerPublicKey[0], seizedOwnerPublicKey[1]];
  var seizedOwnerCompProof[1][nComplianceSMTLevels];
  for (var k = 0; k < nComplianceSMTLevels; k++) {
    seizedOwnerCompProof[0][k] = complianceMerkleProof[0][k];
  }
  ComplianceStatus(1, nComplianceSMTLevels, 2)(publicKeys <== seizedOwnerKeys, root <== complianceRoot, merkleProof <== seizedOwnerCompProof);

  // Output compliance via isChangeBack mux: per non-zero output, if the output
  // goes back to the same frozen owner (isChangeBack == 1), the compliance check
  // expects FROZEN status; if it goes to a new recipient (isChangeBack == 0),
  // the check expects ACTIVE status. This allows seizure outputs to ACTIVE
  // recipients AND change back to the same FROZEN owner, while rejecting outputs
  // to wrong-status or unregistered recipients.
  //
  // The mux uses intermediate signals to keep constraints quadratic (R1CS):
  //   muxDiff  = frozenLeafValue - activeLeafValue              (linear)
  //   expected = activeLeafValue + isChangeBack * muxDiff        (quadratic)
  var seizedOwnerPubKeyHash;
  seizedOwnerPubKeyHash = Poseidon(2)(inputs <== [seizedOwnerPublicKey[0], seizedOwnerPublicKey[1]]);

  signal muxLeafDiff[nOutputs];
  signal expectedComplianceLeafValue[nOutputs];

  for (var j = 0; j < nOutputs; j++) {
    var outputOwnerPubKeyHash;
    outputOwnerPubKeyHash = Poseidon(2)(inputs <== [kycPublicKeys[j + 1][0], kycPublicKeys[j + 1][1]]);

    // isChangeBack == 1: output goes back to the same frozen owner (change)
    // isChangeBack == 0: output goes to a different (new) recipient
    var isChangeBack;
    isChangeBack = IsEqual()(in <== [outputOwnerPubKeyHash, seizedOwnerPubKeyHash]);

    var activeLeafValue;
    activeLeafValue = Poseidon(3)(inputs <== [kycPublicKeys[j + 1][0], kycPublicKeys[j + 1][1], 1]);

    var frozenLeafValue;
    frozenLeafValue = Poseidon(3)(inputs <== [kycPublicKeys[j + 1][0], kycPublicKeys[j + 1][1], 2]);

    // R1CS-safe mux: selects FROZEN leaf value for change-back, ACTIVE for new recipients.
    // SMTVerifier below will reject if no matching leaf exists at this value in the tree.
    muxLeafDiff[j] <== frozenLeafValue - activeLeafValue;
    expectedComplianceLeafValue[j] <== activeLeafValue + isChangeBack * muxLeafDiff[j];

    // pubkey-zero gating: disabled output slots skip the SMT check
    var isPubKeyZero;
    isPubKeyZero = IsZero()(in <== kycPublicKeys[j + 1][0]);
    var smtEnabled = 1 - isPubKeyZero;

    var siblings[nComplianceSMTLevels];
    for (var k = 0; k < nComplianceSMTLevels; k++) {
      siblings[k] = complianceMerkleProof[j + 1][k];
    }

    SMTVerifier(nComplianceSMTLevels)(
      enabled   <== smtEnabled,
      root      <== complianceRoot,
      siblings  <== siblings,
      key       <== outputOwnerPubKeyHash,
      value     <== expectedComplianceLeafValue[j],
      fnc       <== 0,    // 0 = inclusion proof
      oldKey    <== 0,
      oldValue  <== 0,
      isOld0    <== 0
    );
  }

  // Check enforcement nullifiers. Uses the same inputCommitments passed to
  // CheckHashes and CheckSMTProof — binding nullifiers to verified, SMT-included UTXOs.
  // In forced transfer, the DH direction is inverted vs. transfer/withdraw:
  //   ecdhKey = enforcerPrivateKey, counterpartyPublicKey = seizedOwnerPublicKey
  // Same shared secret by DH symmetry: ECDH(enfPriv, ownerPub) == ECDH(ownerPriv, enfPub)
  CheckEnforcementNullifiers(nInputs)(enforcementNullifiers <== enforcementNullifiers, inputCommitments <== inputCommitments, counterpartyPublicKey <== seizedOwnerPublicKey, ecdhKey <== enforcerPrivateKey);

  // Generate cipher text for output UTXOs (per-receiver encryption)
  (ecdhPublicKey, encryptedValuesForReceiver) <== EncryptOutputs(nOutputs)(ecdhPrivateKey <== ecdhPrivateKey, encryptionNonce <== encryptionNonce, commitmentInputs <== outAuxInputs);

  // Assemble authority plaintext:
  // [seizedOwnerPubX, seizedOwnerPubY, in1Value, in1Salt, ...,
  //  out1OwnerX, out1OwnerY, ..., out1Value, out1Salt, ...]
  // senderPub = seizedOwnerPublicKey (the frozen owner's key, not the enforcer's)
  var plainText[authorityPlaintextLength];
  plainText[0] = seizedOwnerPublicKey[0];
  plainText[1] = seizedOwnerPublicKey[1];
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
  for (var i = 0; i < nOutputs; i++) {
    plainText[idx] = outputValues[i];
    idx++;
    plainText[idx] = outputSalts[i];
    idx++;
  }

  // Encrypt all secrets for the arbiter (non-repudiation).
  // The <== constraint on signal output ensures ciphertext is correctly computed
  // in-circuit — the prover cannot supply arbitrary ciphertext calldata.
  // senderPub = seizedOwnerPublicKey records the frozen owner in the audit trail.
  var sharedSecretArbiter[2];
  sharedSecretArbiter = Ecdh()(privKey <== ecdhPrivateKey, pubKey <== arbiterPublicKey);
  encryptedValuesForArbiter <== SymmetricEncrypt(authorityPlaintextLength)(plainText <== plainText, key <== sharedSecretArbiter, nonce <== encryptionNonce);

  // Encrypt all secrets for the enforcer (record-keeping for future seizure).
  var sharedSecretEnforcer[2];
  sharedSecretEnforcer = Ecdh()(privKey <== ecdhPrivateKey, pubKey <== enforcerPublicKey);
  encryptedValuesForEnforcer <== SymmetricEncrypt(authorityPlaintextLength)(plainText <== plainText, key <== sharedSecretEnforcer, nonce <== encryptionNonce);
}

// Output signals (signal output in template, not in { public [] }):
//   ecdhPublicKey[2], encryptedValuesForReceiver[2][4],
//   encryptedValuesForArbiter[16], encryptedValuesForEnforcer[16]
component main { public [ enforcementNullifiers, outputCommitments,
                          utxosRoot, identitiesRoot, complianceRoot, enabledInputs,
                          enforcerPublicKey, encryptionNonce, arbiterPublicKey ] }
  = ForcedTransferEnforced(2, 2, 64, 64, 64);
  
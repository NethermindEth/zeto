pragma circom 2.2.2;

include "./lib/check-positive.circom";
include "./lib/check-hashes.circom";
include "./lib/kyc.circom";
include "./lib/compliance_status.circom";
include "./lib/check-babyjub-public-key.circom";
include "./lib/encrypt-outputs.circom";
include "./node_modules/circomlib/circuits/comparators.circom";

// This circuit performs the following operations for an AENKNR-E deposit:
// - verify output commitments match expected hashes and values are positive
// - compute the deposit amount as sum(outputValues) exposed as signal output
// - check all non-zero output owners are KYC-registered in the identities SMT
// - check all non-zero output owners have ACTIVE compliance status
// - validate all external public keys lie on the BabyJubJub curve (defence-in-depth)
// - encrypt output UTXOs for their receivers
// - encrypt all secrets for the arbiter (non-repudiation)
// - encrypt all secrets for the enforcer (seizure capability)
template DepositEnforced(nOutputs, nIdentitiesSMTLevels, nComplianceSMTLevels) {
  signal input outputCommitments[nOutputs];
  signal input outputValues[nOutputs];
  signal input outputSalts[nOutputs];
  signal input outputOwnerPublicKeys[nOutputs][2];
  // an ephemeral private key that is used to generate the shared ECDH key for encryption
  signal input ecdhPrivateKey;
  signal input identitiesRoot;
  signal input identitiesMerkleProof[nOutputs][nIdentitiesSMTLevels];
  signal input complianceRoot;
  signal input complianceMerkleProof[nOutputs][nComplianceSMTLevels];
  signal input encryptionNonce;
  signal input arbiterPublicKey[2];
  signal input enforcerPublicKey[2];

  // the deposit amount: sum of output values; becomes publicInputs[0] in the verifier
  signal output out;

  // the output for the public key of the ephemeral private key used in generating ECDH shared key
  signal output ecdhPublicKey[2];

  // the output for the list of encrypted output UTXOs cipher texts
  signal output encryptedValuesForReceiver[nOutputs][4];

  // the number of cipher text messages returned by the encryption template will be 3n+1
  // authority plaintext (14-element schema for 2-in/2-out layout):
  //   [senderPubX, senderPubY, in1Value, in1Salt, in2Value, in2Salt,
  //    out1OwnerX, out1OwnerY, out2OwnerX, out2OwnerY,
  //    out1Value, out1Salt, out2Value, out2Salt]
  // For deposit: input fields are zeroed; senderPubX/Y = depositor's public key (ecdhPublicKey)
  var nVirtualInputs = 2;  // matches the 2-in layout of the stable authority plaintext schema
  var authorityPlaintextLength = 2 + 2 * nVirtualInputs + 2 * nOutputs + 2 * nOutputs;
  var l = authorityPlaintextLength;
  if (l % 3 != 0) {
    l += (3 - (l % 3));
  }
  signal output encryptedValuesForArbiter[l + 1];
  signal output encryptedValuesForEnforcer[l + 1];

  CheckPositive(nOutputs)(outputValues <== outputValues);

  // Single CommitmentInputs bus shared by CheckHashes and EncryptOutputs
  CommitmentInputs() outAuxInputs[nOutputs];
  for (var i = 0; i < nOutputs; i++) {
    outAuxInputs[i].value <== outputValues[i];
    outAuxInputs[i].salt <== outputSalts[i];
    outAuxInputs[i].ownerPublicKey <== outputOwnerPublicKeys[i];
  }

  CheckHashes(nOutputs)(commitmentHashes <== outputCommitments, commitmentInputs <== outAuxInputs);

  // calculate the sum of output values and set to the output
  var sumOutputs = 0;
  for (var i = 0; i < nOutputs; i++) {
    sumOutputs = sumOutputs + outputValues[i];
  }
  out <== sumOutputs;

  // Validate external public keys are on the BabyJubJub curve.
  // Keys derived in-circuit via BabyPbk (ecdhPublicKey) are exempt.
  // External keys entering ECDH must pass BabyCheck for defence-in-depth.
  CheckBabyJubPublicKey()(publicKey <== arbiterPublicKey);
  CheckBabyJubPublicKey()(publicKey <== enforcerPublicKey);
  for (var i = 0; i < nOutputs; i++) {
    CheckBabyJubPublicKey()(publicKey <== outputOwnerPublicKeys[i]);
  }

  // Commitment-zero gating: disabled output slots produce zero public keys,
  // which Kyc and ComplianceStatus skip via pubkey-zero gating.
  var ownerPublicKeys[nOutputs][2];
  var isCommitmentZero[nOutputs];
  for (var i = 0; i < nOutputs; i++) {
    isCommitmentZero[i] = IsZero()(in <== outputCommitments[i]);
    ownerPublicKeys[i][0] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][0];
    ownerPublicKeys[i][1] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][1];
  }

  Kyc(nOutputs, nIdentitiesSMTLevels)(publicKeys <== ownerPublicKeys, root <== identitiesRoot, merkleProof <== identitiesMerkleProof);

  // STATUS=1 is a compile-time constant (ACTIVE), preventing prover substitution.
  ComplianceStatus(nOutputs, nComplianceSMTLevels, 1)(publicKeys <== ownerPublicKeys, root <== complianceRoot, merkleProof <== complianceMerkleProof);

  // Generate cipher text for output UTXOs (per-receiver encryption)
  (ecdhPublicKey, encryptedValuesForReceiver) <== EncryptOutputs(nOutputs)(ecdhPrivateKey <== ecdhPrivateKey, encryptionNonce <== encryptionNonce, commitmentInputs <== outAuxInputs);

  // Assemble authority plaintext:
  // [depositorPubX, depositorPubY, 0, 0, 0, 0,
  //  out1OwnerX, out1OwnerY, out2OwnerX, out2OwnerY,
  //  out1Value, out1Salt, out2Value, out2Salt]
  // senderPubX/Y = depositor's public key (ecdhPublicKey, derived from ecdhPrivateKey)
  var plainText[authorityPlaintextLength];
  plainText[0] = ecdhPublicKey[0];
  plainText[1] = ecdhPublicKey[1];
  var idx = 2;
  // input fields zeroed for deposit (no input UTXOs)
  for (var i = 0; i < nVirtualInputs; i++) {
    plainText[idx] = 0;
    idx++;
    plainText[idx] = 0;
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

  // Encrypt all secrets for the arbiter (non-repudiation)
  var sharedSecretArbiter[2];
  sharedSecretArbiter = Ecdh()(privKey <== ecdhPrivateKey, pubKey <== arbiterPublicKey);
  encryptedValuesForArbiter <== SymmetricEncrypt(authorityPlaintextLength)(plainText <== plainText, key <== sharedSecretArbiter, nonce <== encryptionNonce);

  // Encrypt all secrets for the enforcer (seizure capability)
  var sharedSecretEnforcer[2];
  sharedSecretEnforcer = Ecdh()(privKey <== ecdhPrivateKey, pubKey <== enforcerPublicKey);
  encryptedValuesForEnforcer <== SymmetricEncrypt(authorityPlaintextLength)(plainText <== plainText, key <== sharedSecretEnforcer, nonce <== encryptionNonce);
}

// Output signals (signal output in template, not in { public [] }):
//   out (→ publicInputs[0] = amount), ecdhPublicKey[2],
//   encryptedValuesForReceiver[2][4], encryptedValuesForArbiter[16], encryptedValuesForEnforcer[16]
component main { public [ outputCommitments, identitiesRoot, complianceRoot,
                          encryptionNonce, arbiterPublicKey, enforcerPublicKey ] }
  = DepositEnforced(2, 10, 10);
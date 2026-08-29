// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
pragma circom 2.2.2;

include "./lib/check-positive.circom";
include "./lib/check-hashes.circom";
include "./lib/kyc.circom";
include "./lib/compliance-constants.circom";
include "./lib/compliance-status.circom";
include "./lib/check-non-zero.circom";
include "./lib/check-babyjub-public-key.circom";
include "./lib/encrypt-outputs.circom";
include "./node_modules/circomlib/circuits/comparators.circom";

// This circuit performs the following operations for an AENKNR-E deposit:
// - verify output commitments match expected hashes and values are positive
// - compute the deposit amount as sum(outputValues) exposed as signal output
// - check all non-zero output owners are KYC-registered in the identities SMT
// - check all non-zero output owners have ACTIVE compliance status
// - validate every external public key lies on the BabyJubJub curve and has a
//   non-zero x coordinate. This is load-bearing, not defence-in-depth: Kyc and
//   ComplianceStatus gate on `publicKey[0] == 0`, and EscalarMulAny substitutes
//   the Base8 generator for an x == 0 point
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
  // For deposit: input fields are zeroed. senderPubX/Y carries ecdhPublicKey, which
  // is the EPHEMERAL encryption key, not an attributable identity: ecdhPrivateKey is
  // chosen freely by the prover and is neither KYC-checked nor bound to any
  // registered key. Depositor attribution comes from msg.sender on-chain, which the
  // enforced token's events already record — do not read this field as the depositor.
  // nVirtualInputs = 2: zeroed input slots match the 2-in transfer layout so that
  // arbiter/enforcer use a single decryption schema across all operation types.
  var nVirtualInputs = 2;
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

  // Sum of output values → signal output `out` (becomes publicInputs[0]).
  // The contract binds this to the ERC-20 transfer amount, ensuring the
  // depositor locks exactly the value committed in the output UTXOs.
  var sumOutputs = 0;
  for (var i = 0; i < nOutputs; i++) {
    sumOutputs = sumOutputs + outputValues[i];
  }
  out <== sumOutputs;

  // Hoist isCommitmentZero — shared by BabyCheck gating, KYC gating, and compliance gating.
  var isCommitmentZero[nOutputs];
  for (var i = 0; i < nOutputs; i++) {
    isCommitmentZero[i] = IsZero()(in <== outputCommitments[i]);
  }

  // A disabled output slot mints no note, so it must carry no value. Without
  // this the slot's value still balances the conservation sum while nothing
  // records where it went — value is destroyed, or on deposit over-charged.
  for (var i = 0; i < nOutputs; i++) {
    isCommitmentZero[i] * outputValues[i] === 0;
  }

  // Validate external public keys are on the BabyJubJub curve.
  // Keys derived in-circuit via BabyPbk (ecdhPublicKey) are exempt.
  // A disabled output slot has no key of its own — the raw value may be (0,0),
  // which is not on the curve — so it is padded with the BabyJubJub generator.
  // The padding is a genuine prime-order point rather than the identity, so it
  // passes the same checks a live key does instead of side-stepping them.
  CheckBabyJubPublicKey()(publicKey <== arbiterPublicKey);
  CheckBabyJubPublicKey()(publicKey <== enforcerPublicKey);
  for (var i = 0; i < nOutputs; i++) {
    var checkedKey[2];
    checkedKey[0] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][0] + isCommitmentZero[i] * BabyJubBase8X();
    checkedKey[1] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][1] + isCommitmentZero[i] * BabyJubBase8Y();
    CheckBabyJubPublicKey()(publicKey <== checkedKey);
  }

  // Commitment-zero gating: disabled output slots produce zero public keys,
  // which Kyc and ComplianceStatus skip via pubkey-zero gating.
  var ownerPublicKeys[nOutputs][2];
  for (var i = 0; i < nOutputs; i++) {
    ownerPublicKeys[i][0] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][0];
    ownerPublicKeys[i][1] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][1];
  }

  Kyc(nOutputs, nIdentitiesSMTLevels)(publicKeys <== ownerPublicKeys, root <== identitiesRoot, merkleProof <== identitiesMerkleProof);

  // STATUS=1 is a compile-time constant (ACTIVE), preventing prover substitution.
  ComplianceStatus(nOutputs, nComplianceSMTLevels, STATUS_ACTIVE())(publicKeys <== ownerPublicKeys, root <== complianceRoot, merkleProof <== complianceMerkleProof);

  // Generate cipher text for output UTXOs (per-receiver encryption)
  (ecdhPublicKey, encryptedValuesForReceiver) <== EncryptOutputs(nOutputs)(ecdhPrivateKey <== ecdhPrivateKey, encryptionNonce <== encryptionNonce, commitmentInputs <== outAuxInputs);
  // The published ephemeral public key must not be the curve identity: that
  // happens exactly when the ephemeral scalar is zero (or a multiple of the
  // subgroup order), which makes every shared secret in this proof public.
  CheckNonZero()(in <== ecdhPublicKey[0]);

  // Assemble authority plaintext:
  // [ephemeralPubX, ephemeralPubY, 0, 0, 0, 0,
  //  out1OwnerX, out1OwnerY, out2OwnerX, out2OwnerY,
  //  out1Value, out1Salt, out2Value, out2Salt]
  // senderPubX/Y = ecdhPublicKey (ephemeral, see above) — not the depositor's identity
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
  // A disabled output slot contributes nothing to the authority record. Its
  // preimage fields are prover-chosen and correspond to no commitment, so
  // publishing them writes an audit entry that reconciles against nothing.
  for (var i = 0; i < nOutputs; i++) {
    plainText[idx] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][0];
    idx++;
    plainText[idx] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][1];
    idx++;
  }
  for (var i = 0; i < nOutputs; i++) {
    // outputValues[i] is already forced to zero for a disabled slot above.
    plainText[idx] = outputValues[i];
    idx++;
    plainText[idx] = (1 - isCommitmentZero[i]) * outputSalts[i];
    idx++;
  }

  // Encrypt all secrets for the arbiter (non-repudiation).
  // The <== constraint on signal output ensures ciphertext is correctly computed
  // in-circuit — the prover cannot supply arbitrary ciphertext calldata.
  var sharedSecretArbiter[2];
  sharedSecretArbiter = Ecdh()(privKey <== ecdhPrivateKey, pubKey <== arbiterPublicKey);
  encryptedValuesForArbiter <== SymmetricEncrypt(authorityPlaintextLength)(plainText <== plainText, key <== sharedSecretArbiter, nonce <== encryptionNonce);

  // Encrypt all secrets for the enforcer (seizure capability).
  // Enforcer needs output preimages to build forced-transfer proofs later.
  var sharedSecretEnforcer[2];
  sharedSecretEnforcer = Ecdh()(privKey <== ecdhPrivateKey, pubKey <== enforcerPublicKey);
  encryptedValuesForEnforcer <== SymmetricEncrypt(authorityPlaintextLength)(plainText <== plainText, key <== sharedSecretEnforcer, nonce <== encryptionNonce);
}

// Output signals (signal output in template, not in { public [] }):
//   out (→ publicInputs[0] = amount), ecdhPublicKey[2],
//   encryptedValuesForReceiver[2][4], encryptedValuesForArbiter[16], encryptedValuesForEnforcer[16]
component main { public [ outputCommitments, identitiesRoot, complianceRoot,
                          encryptionNonce, arbiterPublicKey, enforcerPublicKey ] }
  = DepositEnforced(2, 20, 20);
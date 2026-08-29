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

include "../lib/check-positive.circom";
include "../lib/check-hashes.circom";
include "../lib/check-sum.circom";
include "../lib/check-nullifiers.circom";
include "../lib/check-smt-proof.circom";
include "../lib/check-non-zero.circom";
include "../lib/check-enabled-inputs.circom";
include "../lib/check-enforcement-nullifiers.circom";
include "../lib/check-babyjub-public-key.circom";
include "../lib/kyc.circom";
include "../lib/compliance-constants.circom";
include "../lib/compliance-status.circom";
include "../lib/encrypt-outputs.circom";
include "../node_modules/circomlib/circuits/babyjub.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

// This circuit performs the following operations:
// - derive the sender's public key from the sender's private key
// - check the input and output commitments match the expected hashes
// - check the input and output values sum to the same amount (value conservation)
// - check the owner nullifiers are derived from the input values, salts, and owner private key
// - check the enforcement nullifiers are derived via ECDH(ownerPriv, enforcerPub)
// - check the input commitments exist in the UTXO Sparse Merkle Tree
// - validate every external public key lies on the BabyJubJub curve and has a
//   non-zero x coordinate. This is load-bearing, not defence-in-depth: Kyc and
//   ComplianceStatus gate on `publicKey[0] == 0`, and EscalarMulAny substitutes
//   the Base8 generator for an x == 0 point
// - check sender + non-zero output owners are KYC-registered in the identities SMT
// - check sender + non-zero output owners have ACTIVE compliance status
// - encrypt output UTXOs for their receivers
// - encrypt all secrets for the arbiter (non-repudiation)
// - encrypt all secrets for the enforcer (seizure capability)
template Zeto(nInputs, nOutputs, nUTXOSMTLevels, nIdentitiesSMTLevels, nComplianceSMTLevels) {
  signal input ownerNullifiers[nInputs];
  signal input enforcementNullifiers[nInputs];
  signal input inputCommitments[nInputs];
  signal input inputValues[nInputs];
  signal input inputSalts[nInputs];
  // must be properly hashed and trimmed to be compatible with the BabyJub curve.
  // Reference: https://github.com/iden3/circomlib/blob/master/test/babyjub.js#L103
  signal input inputOwnerPrivateKey;
  // an ephemeral private key that is used to generate the shared ECDH key for encryption
  signal input ecdhPrivateKey;
  signal input utxosRoot;
  signal input utxosMerkleProof[nInputs][nUTXOSMTLevels];
  signal input enabledInputs[nInputs];
  signal input identitiesRoot;
  signal input identitiesMerkleProof[nOutputs + 1][nIdentitiesSMTLevels];
  signal input complianceRoot;
  signal input complianceMerkleProof[nOutputs + 1][nComplianceSMTLevels];
  signal input outputCommitments[nOutputs];
  signal input outputValues[nOutputs];
  signal input outputSalts[nOutputs];
  signal input outputOwnerPublicKeys[nOutputs][2];
  signal input encryptionNonce;
  signal input arbiterPublicKey[2];
  signal input enforcerPublicKey[2];

  // the output for the public key of the ephemeral private key used in generating ECDH shared key
  signal output ecdhPublicKey[2];

  // the output for the list of encrypted output UTXOs cipher texts
  signal output encryptedValuesForReceiver[nOutputs][4];

  // Poseidon sponge encryption absorbs plaintext in 3-element blocks, so the
  // plaintext is zero-padded to n = ceil(length/3) blocks. Each block emits 3
  // ciphertext elements, plus one final authentication tag → output = 3n + 1.
  // input length:
  //   - input owner public key (x, y): 2
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

  // Derive sender's public key from private key (key ownership proof).
  // Single inputOwnerPrivateKey for all inputs → single-sender model.
  // The derived key serves dual purpose: (1) commitment preimage owner in
  // CheckHashes, and (2) ECDH key for enforcement nullifier derivation.
  var inputOwnerPubKeyAx, inputOwnerPubKeyAy;
  (inputOwnerPubKeyAx, inputOwnerPubKeyAy) = BabyPbk()(in <== inputOwnerPrivateKey);

  // The sender's derived key must not be the curve identity either: Kyc and
  // ComplianceStatus gate on x == 0, so a zero owner scalar would skip the
  // sender's own registration and status checks.
  CheckNonZero()(in <== inputOwnerPubKeyAx);

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

  // One enable flag per input slot, and every gate that could refuse the slot
  // follows it: commitment, owner nullifier, enforcement tag, SMT inclusion and
  // the value that enters CheckSum.
  CheckEnabledInputs(nInputs)(enabled <== enabledInputs, commitments <== inputCommitments, values <== inputValues);
  CheckSlotTags(nInputs)(enabled <== enabledInputs, tags <== ownerNullifiers);

  CheckHashes(nInputs)(commitmentHashes <== inputCommitments, commitmentInputs <== inAuxInputs);
  CheckHashes(nOutputs)(commitmentHashes <== outputCommitments, commitmentInputs <== outAuxInputs);

  // Owner nullifier = Poseidon(3)([value, salt, ownerPrivKey]).
  // Shares (values, salts, privKey) with CheckHashes above, so nullifiers
  // are transitively bound to the same input commitments.
  CheckNullifiers(nInputs)(nullifiers <== ownerNullifiers, values <== inputValues, salts <== inputSalts, ownerPrivateKey <== inputOwnerPrivateKey);

  CheckSum(nInputs, nOutputs)(inputValues <== inputValues, outputValues <== outputValues);

  // The preceding constraints bind each nullifier to its input commitment.
  // This one binds the commitment to the sparse merkle tree at `utxosRoot`,
  // so an input must be a member of the committed UTXO set.
  CheckSMTProof(nInputs, nUTXOSMTLevels)(root <== utxosRoot, merkleProof <== utxosMerkleProof, enabled <== enabledInputs, leafNodeIndexes <== inputCommitments, leafNodeValues <== inputCommitments);

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
  // Keys derived in-circuit via BabyPbk (inputOwnerPublicKey) are exempt.
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

  // Check that the owner public keys for inputs and outputs are
  // included in the identities Sparse Merkle Tree with the root `identitiesRoot`.
  // Zero-commitment gating: disabled output slots produce zero public keys,
  // which Kyc skips via pubkey-zero gating (mirrors kyc.circom pattern).
  var ownerPublicKeys[nOutputs + 1][2];
  ownerPublicKeys[0] = [inputOwnerPubKeyAx, inputOwnerPubKeyAy];
  for (var i = 0; i < nOutputs; i++) {
    ownerPublicKeys[i + 1][0] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][0];
    ownerPublicKeys[i + 1][1] = (1 - isCommitmentZero[i]) * outputOwnerPublicKeys[i][1];
  }
  Kyc(nOutputs + 1, nIdentitiesSMTLevels)(publicKeys <== ownerPublicKeys, root <== identitiesRoot, merkleProof <== identitiesMerkleProof);

  // Check that sender + non-zero output owners have ACTIVE compliance status.
  // STATUS=1 is a compile-time constant (ACTIVE), preventing prover substitution.
  // Uses the same gated ownerPublicKeys array; ComplianceStatus skips zero keys.
  ComplianceStatus(nOutputs + 1, nComplianceSMTLevels, STATUS_ACTIVE())(publicKeys <== ownerPublicKeys, root <== complianceRoot, merkleProof <== complianceMerkleProof);

  // Check enforcement nullifiers. Uses the same inputCommitments passed to
  // CheckHashes and CheckSMTProof — this three-way binding ensures enforcement
  // nullifiers correspond to real, SMT-included UTXOs with verified preimages.
  // In the transfer path:
  //   ecdhKey = inputOwnerPrivateKey, counterpartyPublicKey = enforcerPublicKey
  // DH symmetry: ECDH(ownerPriv, enfPub) == ECDH(enfPriv, ownerPub)
  CheckEnforcementNullifiers(nInputs)(enforcementNullifiers <== enforcementNullifiers, inputCommitments <== inputCommitments, counterpartyPublicKey <== enforcerPublicKey, ecdhKey <== inputOwnerPrivateKey, enabled <== enabledInputs);

  // Generate cipher text for output UTXOs (per-receiver encryption)
  (ecdhPublicKey, encryptedValuesForReceiver) <== EncryptOutputs(nOutputs)(ecdhPrivateKey <== ecdhPrivateKey, encryptionNonce <== encryptionNonce, commitmentInputs <== outAuxInputs);
  // The published ephemeral public key must not be the curve identity: that
  // happens exactly when the ephemeral scalar is zero (or a multiple of the
  // subgroup order), which makes every shared secret in this proof public.
  CheckNonZero()(in <== ecdhPublicKey[0]);

  // Assemble authority plaintext:
  // [senderPubX, senderPubY, in1Value, in1Salt, ..., out1OwnerX, out1OwnerY, ..., out1Value, out1Salt, ...]
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
  // Same plaintext as arbiter — both authorities get full transaction metadata.
  var sharedSecretEnforcer[2];
  sharedSecretEnforcer = Ecdh()(privKey <== ecdhPrivateKey, pubKey <== enforcerPublicKey);
  encryptedValuesForEnforcer <== SymmetricEncrypt(authorityPlaintextLength)(plainText <== plainText, key <== sharedSecretEnforcer, nonce <== encryptionNonce);
}
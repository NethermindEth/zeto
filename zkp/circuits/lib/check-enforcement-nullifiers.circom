pragma circom 2.2.2;

include "../node_modules/circomlib/circuits/comparators.circom";
include "./enforcement_nullifier.circom";

// CheckEnforcementNullifiers validates that each public enforcement nullifier
// in a batch is correctly derived from its corresponding input commitment via ECDH.
//
// For each slot i:
//   - enabled  (enforcementNullifiers[i] != 0): derives the nullifier in-circuit
//     and constrains it to equal the public input.
//   - disabled (enforcementNullifiers[i] == 0): bypasses the check entirely,
//     matching the same IsZero-gating pattern used in check-nullifiers.circom.
//
// inputCommitments must be the same preimage array used for UTXO SMT inclusion
// so that the enforcement nullifier is provably bound to the same note.
template CheckEnforcementNullifiers(nInputs) {
  signal input enforcementNullifiers[nInputs];
  signal input inputCommitments[nInputs];
  signal input counterpartyPublicKey[2];
  // The caller's private key, already formatted for BabyJub
  // (formatPrivKeyForBabyJub applied on the JS side).
  signal input ecdhKey;

  for (var i = 0; i < nInputs; i++) {
    var calculatedNullifier;
    calculatedNullifier = EnforcementNullifier()(
      inputCommitment <== inputCommitments[i],
      counterpartyPublicKey <== counterpartyPublicKey,
      ecdhKey <== ecdhKey
    );

    var isNullifierZero;
    isNullifierZero = IsZero()(in <== enforcementNullifiers[i]);

    var isHashEqual;
    isHashEqual = IsEqual()(in <== [
      enforcementNullifiers[i],
      (1 - isNullifierZero) * calculatedNullifier
    ]);

    isHashEqual === 1;
  }
}
pragma circom 2.2.2;

include "../node_modules/circomlib/circuits/babyjub.circom";

// CheckBabyJubPublicKey validates that a public key lies on the BabyJubJub curve
// by enforcing the twisted-Edwards equation: a*x^2 + y^2 = 1 + d*x^2*y^2.
//
// When to apply:
//   Apply to every externally-supplied public key before it enters an ECDH or
//   commitment-hash computation — specifically: enforcerPublicKey, arbiterPublicKey,
//   and outputOwnerPublicKeys[i].
//
// When NOT to apply:
//   Keys produced in-circuit via BabyPbk() are always on-curve by construction;
//   applying this check to them is redundant and wastes constraints.
//
// Scope of the check:
//   BabyCheck verifies curve membership (the curve equation) but does NOT verify
//   prime-order subgroup membership. Low-order points (e.g. identity, 2-torsion)
//   satisfy the curve equation and will pass this check. For the ECDH use cases in
//   this protocol, cofactor-leakage risk is negligible: private keys are already
//   reduced to the prime-order subgroup by formatPrivKeyForBabyJub on the JS side.
template CheckBabyJubPublicKey() {
    signal input publicKey[2];

    BabyCheck()(x <== publicKey[0], y <== publicKey[1]);
}

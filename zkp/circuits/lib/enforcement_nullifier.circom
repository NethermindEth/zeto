pragma circom 2.2.2;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./ecdh.circom";

// EnforcementNullifier derives a single enforcement nullifier for a UTxO.
// It uses ECDH to create a shared secret between the caller's private key
// and a counterparty public key, then derives a domain-separated nullifier:
//
//   shared[2]            = ECDH(ecdhKey, counterpartyPublicKey)
//   k0                   = Poseidon(2)([shared[0], shared[1]])
//   enforcementNullifier = Poseidon(3)([inputCommitment, k0, ENF_DOMAIN_TAG])
//
// DH symmetry: ECDH(ownerKey, enforcerPub) == ECDH(enforcerKey, ownerPub),
// so both the owner (during normal spend) and the enforcer (during seizure)
// independently derive the same nullifier without coordination.
//
// Domain separation from owner nullifiers (Poseidon(3)([value, salt, privKey])):
// ENF_DOMAIN_TAG in the third slot is a fixed constant that cannot equal any
// valid BabyJub private key, preventing cross-type preimage collision.
// On-chain, the two nullifier types are stored in physically separate mappings.
template EnforcementNullifier() {
    signal input inputCommitment;
    signal input counterpartyPublicKey[2];
    // The caller's private key, already hashed and trimmed for BabyJub
    // (i.e. formatPrivKeyForBabyJub has been applied on the JS side).
    signal input ecdhKey;

    signal output out;

    // ENF_DOMAIN_TAG = keccak256("zeto.enforcement.nullifier.v1") mod p
    // where p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
    var ENF_DOMAIN_TAG = 21455947405572920533869930548514094044543253524099188107381343679564123236615;

    signal shared[2];
    shared <== Ecdh()(privKey <== ecdhKey, pubKey <== counterpartyPublicKey);

    signal k0;
    k0 <== Poseidon(2)(inputs <== [shared[0], shared[1]]);

    out <== Poseidon(3)(inputs <== [inputCommitment, k0, ENF_DOMAIN_TAG]);
}
// Copyright © 2025 Kaleido, Inc.
//
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

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./ecdh.circom";

// The enforcement nullifier of a UTxO. ECDH creates a shared secret between the
// caller's private key and a counterparty public key, and a domain-separated
// hash binds that secret to the commitment:
//
//   shared[2]            = ECDH(ecdhKey, counterpartyPublicKey)
//   k0                   = Poseidon(2)([shared[0], shared[1]])
//   enforcementNullifier = Poseidon(3)([inputCommitment, k0, ENF_DOMAIN_TAG])
//
// The derivation is split at k0 because only the second half depends on the
// commitment: a caller checking several commitments against one counterparty
// pays for the ECDH once. EnforcementNullifier() composes both halves for the
// single-UTxO case.
//
// DH symmetry: ECDH(ownerKey, enforcerPub) == ECDH(enforcerKey, ownerPub),
// so both the owner (during normal spend) and the enforcer (during seizure)
// independently derive the same nullifier without coordination.
//
// Domain separation from owner nullifiers (Poseidon(3)([value, salt, privKey])):
// ENF_DOMAIN_TAG in the third slot is a fixed constant that cannot equal any
// valid BabyJub private key, preventing cross-type preimage collision.
// On-chain, the two nullifier types are stored in physically separate mappings.

// EnforcementNullifierKey derives the commitment-independent half of the
// nullifier: the ECDH shared secret compressed to a single field element.
// It depends only on (ecdhKey, counterpartyPublicKey), so a caller checking a
// batch of nullifiers against one counterparty derives it once.
// - check that k0 = Poseidon(2)(ECDH(ecdhKey, counterpartyPublicKey))
template EnforcementNullifierKey() {
    signal input counterpartyPublicKey[2];
    // The caller's private key, with formatPrivKeyForBabyJub already applied
    // on the JS side to hash and trim it for BabyJub.
    signal input ecdhKey;

    signal output k0;

    signal shared[2];
    shared <== Ecdh()(privKey <== ecdhKey, pubKey <== counterpartyPublicKey);

    k0 <== Poseidon(2)(inputs <== [shared[0], shared[1]]);
}

// EnforcementNullifierFromKey binds one commitment to an already-derived shared
// key. This is the only definition of the domain-separated nullifier hash.
// - check that out = Poseidon(3)(inputCommitment, k0, ENF_DOMAIN_TAG)
template EnforcementNullifierFromKey() {
    signal input inputCommitment;
    signal input k0;

    signal output out;

    // ENF_DOMAIN_TAG = keccak256("zeto.enforcement.nullifier.v1") mod p
    // where p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
    var ENF_DOMAIN_TAG = 21455947405572920533869930548514094044543253524099188107381343679564123236615;

    out <== Poseidon(3)(inputs <== [inputCommitment, k0, ENF_DOMAIN_TAG]);
}

// EnforcementNullifier composes the two halves for a single UTxO.
// - check that out is the enforcement nullifier of inputCommitment under
//   ECDH(ecdhKey, counterpartyPublicKey)
template EnforcementNullifier() {
    signal input inputCommitment;
    signal input counterpartyPublicKey[2];
    // The caller's private key, with formatPrivKeyForBabyJub already applied
    // on the JS side to hash and trim it for BabyJub.
    signal input ecdhKey;

    signal output out;

    signal k0;
    k0 <== EnforcementNullifierKey()(
        counterpartyPublicKey <== counterpartyPublicKey,
        ecdhKey <== ecdhKey
    );

    out <== EnforcementNullifierFromKey()(
        inputCommitment <== inputCommitment,
        k0 <== k0
    );
}
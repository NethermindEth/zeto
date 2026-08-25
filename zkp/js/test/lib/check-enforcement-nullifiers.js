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

const { expect } = require("chai");
const { join } = require("path");
const { wasm: wasm_tester } = require("circom_tester");
const {
  genKeypair,
  genEcdhSharedKey,
  formatPrivKeyForBabyJub,
} = require("maci-crypto");
const { Poseidon, newSalt, enforcementNullifier } = require("../../index.js");

const poseidon2 = Poseidon.poseidon2;
const poseidon3 = Poseidon.poseidon3;
const poseidon4 = Poseidon.poseidon4;

describe("CheckEnforcementNullifiers circuit tests", () => {
  let circuit;
  const owner = {};
  const enforcer = {};

  before(async function () {
    this.timeout(60000);

    circuit = await wasm_tester(
      join(__dirname, "../circuits/check-enforcement-nullifiers.circom"),
    );

    let kp = genKeypair();
    owner.privKey = kp.privKey;
    owner.pubKey = kp.pubKey;
    owner.formattedKey = formatPrivKeyForBabyJub(owner.privKey);

    kp = genKeypair();
    enforcer.privKey = kp.privKey;
    enforcer.pubKey = kp.pubKey;
  });

  // ── helper: build two valid commitments and their enforcement nullifiers ──
  function makeInputs() {
    const c1 = poseidon4([100n, newSalt(), ...owner.pubKey]);
    const c2 = poseidon4([200n, newSalt(), ...owner.pubKey]);
    const n1 = enforcementNullifier(owner.privKey, enforcer.pubKey, c1);
    const n2 = enforcementNullifier(owner.privKey, enforcer.pubKey, c2);
    return {
      inputCommitments: [c1, c2],
      enforcementNullifiers: [n1, n2],
    };
  }

  it("all slots enabled with correct nullifiers should pass", async () => {
    const { inputCommitments, enforcementNullifiers } = makeInputs();

    let error;
    try {
      await circuit.calculateWitness(
        {
          enforcementNullifiers,
          inputCommitments,
          counterpartyPublicKey: enforcer.pubKey,
          ecdhKey: owner.formattedKey,
          enabled: [1, 1],
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.be.undefined;
  });

  it("should fail when one nullifier is tampered", async () => {
    const { inputCommitments, enforcementNullifiers } = makeInputs();

    // Flip a single bit in the first nullifier — any non-matching value suffices
    const tampered = [...enforcementNullifiers];
    tampered[0] = enforcementNullifiers[0] + 1n;

    let error;
    try {
      await circuit.calculateWitness(
        {
          enforcementNullifiers: tampered,
          inputCommitments,
          counterpartyPublicKey: enforcer.pubKey,
          ecdhKey: owner.formattedKey,
          enabled: [1, 1],
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });

  it("an enabled slot may not suppress its nullifier to zero", async () => {
    // This used to be asserted as correct behaviour: a zero tag was read as
    // "slot disabled" and skipped the check. That let a spend consume a real
    // note while publishing no enforcement tag, so nothing recorded the note as
    // spent on the enforcement domain. The slot is now gated by `enabled`.
    const { inputCommitments, enforcementNullifiers } = makeInputs();

    let error;
    try {
      await circuit.calculateWitness(
        {
          enforcementNullifiers: [enforcementNullifiers[0], 0n],
          inputCommitments,
          counterpartyPublicKey: enforcer.pubKey,
          ecdhKey: owner.formattedKey,
          enabled: [1, 1],
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });

  it("a disabled slot must carry a zero nullifier", async () => {
    const { inputCommitments, enforcementNullifiers } = makeInputs();

    let error;
    try {
      await circuit.calculateWitness(
        {
          enforcementNullifiers: [enforcementNullifiers[0], 0n],
          inputCommitments,
          counterpartyPublicKey: enforcer.pubKey,
          ecdhKey: owner.formattedKey,
          enabled: [1, 0],
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.be.undefined;
  });

  it("a disabled slot may not publish a nullifier", async () => {
    const { inputCommitments, enforcementNullifiers } = makeInputs();

    let error;
    try {
      await circuit.calculateWitness(
        {
          enforcementNullifiers,
          inputCommitments,
          counterpartyPublicKey: enforcer.pubKey,
          ecdhKey: owner.formattedKey,
          enabled: [1, 0],
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });

  it("a zero ecdh key is refused", async () => {
    // CheckNonZero on the ecdh key is what stops a prover from collapsing the
    // shared secret: a zero scalar makes k0 derivable from the counterparty
    // public key alone, so the nullifier would no longer be owner-bound. The
    // wrapper suites cannot reach this guard, because they hit CheckNonZero on
    // the owner public key first.
    const { inputCommitments, enforcementNullifiers } = makeInputs();

    let error;
    try {
      await circuit.calculateWitness(
        {
          enforcementNullifiers,
          inputCommitments,
          counterpartyPublicKey: enforcer.pubKey,
          ecdhKey: 0n,
          enabled: [1, 1],
        },
        true,
      );
    } catch (e) {
      error = e;
    }
    expect(error).to.not.be.undefined;
  });
});

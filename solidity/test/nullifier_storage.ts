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

import { ethers, ignition, network } from "hardhat";
import { expect } from "chai";
import { SmtLibModule } from "../ignition/modules/lib/deps";

// nullifierSpent is a view over the same state validateInputs and processInputs
// act on. These tests run a full spend cycle to confirm the three agree: the
// getter is false before the spend and true after it, and validateInputs
// accepts then rejects the same nullifier.
describe("NullifierStorage: nullifierSpent getter", function () {
  let storage: any;

  before(async function () {
    if (network.name !== "hardhat") {
      this.timeout(120000);
    }
    const { smtLib, poseidon2, poseidon3 } =
      await ignition.deploy(SmtLibModule);
    const Storage = await ethers.getContractFactory("NullifierStorage", {
      libraries: {
        SmtLib: smtLib.target as string,
        PoseidonUnit2L: poseidon2.target as string,
        PoseidonUnit3L: poseidon3.target as string,
      },
    });
    storage = await Storage.deploy();
    await storage.waitForDeployment();
  });

  it("full spend cycle: nullifierSpent is consistent with validateInputs", async function () {
    const nullifier = 42n;

    expect(await storage.nullifierSpent(nullifier)).to.equal(false);
    await expect(storage.validateInputs([nullifier], false)).to.not.be.reverted;

    await storage.processInputs([nullifier], false);

    expect(await storage.nullifierSpent(nullifier)).to.equal(true);
    await expect(
      storage.validateInputs([nullifier], false),
    ).to.be.revertedWithCustomError(storage, "UTXOAlreadySpent");
  });

  it("processInputs skips zero nullifiers", async function () {
    await storage.processInputs([0n], false);
    expect(await storage.nullifierSpent(0n)).to.equal(false);
  });
});
// The storage backends are separately-addressed contracts. Every state-mutating
// entry point must be callable only by the Zeto contract that deployed the
// instance; otherwise anyone can append a leaf to the authoritative UTXO tree
// with no proof at all, then withdraw real reserves.
describe("UTXO storage authorization", function () {
  let nullifierStorage: any;
  let baseStorage: any;
  let owner: any;
  let stranger: any;

  // Every state-mutating entry point the storage backends expose. The
  // lock-delegate projection lives in the token's own ZetoLockableStorage
  // namespace rather than in storage, so it is not among them.
  const MUTATORS: Array<[string, any[]]> = [
    ["processInputs", [[7n], false]],
    ["processOutputs", [[7n]]],
    ["processLockedOutputs", [[7n]]],
  ];

  before(async function () {
    if (network.name !== "hardhat") {
      this.timeout(120000);
    }
    [owner, stranger] = await ethers.getSigners();

    const { smtLib, poseidon2, poseidon3 } =
      await ignition.deploy(SmtLibModule);
    const Nullifier = await ethers.getContractFactory("NullifierStorage", {
      libraries: {
        SmtLib: smtLib.target as string,
        PoseidonUnit2L: poseidon2.target as string,
        PoseidonUnit3L: poseidon3.target as string,
      },
    });
    nullifierStorage = await Nullifier.connect(owner).deploy();
    await nullifierStorage.waitForDeployment();

    const Base = await ethers.getContractFactory("BaseStorage");
    baseStorage = await Base.connect(owner).deploy();
    await baseStorage.waitForDeployment();
  });

  it("records the deploying Zeto contract as the sole authorized caller", async function () {
    expect(await nullifierStorage.zeto()).to.equal(await owner.getAddress());
    expect(await baseStorage.zeto()).to.equal(await owner.getAddress());
  });

  for (const [name, args] of MUTATORS) {
    it(`NullifierStorage.${name} rejects a caller that is not the owning Zeto`, async function () {
      await expect(nullifierStorage.connect(stranger)[name](...args))
        .to.be.revertedWithCustomError(nullifierStorage, "StorageUnauthorized")
        .withArgs(await stranger.getAddress());
    });

    it(`BaseStorage.${name} rejects a caller that is not the owning Zeto`, async function () {
      await expect(baseStorage.connect(stranger)[name](...args))
        .to.be.revertedWithCustomError(baseStorage, "StorageUnauthorized")
        .withArgs(await stranger.getAddress());
    });

    it(`NullifierStorage.${name} still accepts the owning Zeto`, async function () {
      await expect(nullifierStorage.connect(owner)[name](...args)).to.not.be
        .reverted;
    });

    it(`BaseStorage.${name} still accepts the owning Zeto`, async function () {
      await expect(baseStorage.connect(owner)[name](...args)).to.not.be
        .reverted;
    });
  }

  it("one storage instance cannot be mutated by another instance's owner", async function () {
    const other = await (await ethers.getContractFactory("BaseStorage"))
      .connect(stranger)
      .deploy();
    await other.waitForDeployment();
    expect(await other.zeto()).to.equal(await stranger.getAddress());

    // `stranger` owns `other`, which grants it nothing on `baseStorage`.
    await expect(baseStorage.connect(stranger).processOutputs([9n]))
      .to.be.revertedWithCustomError(baseStorage, "StorageUnauthorized")
      .withArgs(await stranger.getAddress());
  });

  it("view functions remain open to any caller", async function () {
    await expect(nullifierStorage.connect(stranger).validateInputs([1n], false))
      .to.not.be.reverted;
    expect(
      await nullifierStorage.connect(stranger).nullifierSpent(1n),
    ).to.equal(false);
    expect(await baseStorage.connect(stranger).spent(1n)).to.equal(0n); // UNKNOWN
  });
});

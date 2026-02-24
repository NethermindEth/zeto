import { ethers, ignition, network } from "hardhat";
import { expect } from "chai";
import { SmtLibModule } from "../ignition/modules/lib/deps";

// Adding IZetoNullifierStorageView to NullifierStorage's inheritance chain
// could in theory shift storage layout or break constructor/SMT init.
// These tests deploy the modified contract and run a full spend cycle to
// confirm the getter reads state consistent with the existing methods.
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

    // before spend
    expect(await storage.nullifierSpent(nullifier)).to.equal(false);
    await expect(storage.validateInputs([nullifier], false)).to.not.be
      .reverted;

    // spend
    await storage.processInputs([nullifier], false);

    // after spend
    expect(await storage.nullifierSpent(nullifier)).to.equal(true);
    await expect(
      storage.validateInputs([nullifier], false),
    ).to.be.revertedWithCustomError(storage, "UTXOAlreadySpent");
  });

  it("processInputs skips zero nullifiers", async function () {
    await storage.processInputs([0n], false);
    expect(await storage.nullifierSpent(0n)).to.equal(false);
  });

  it("BaseStorage does not expose nullifierSpent", async function () {
    const Base = await ethers.getContractFactory("BaseStorage");
    const base = await Base.deploy();
    await base.waitForDeployment();
    expect((base as any).nullifierSpent).to.be.undefined;
  });
});
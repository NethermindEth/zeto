import { ethers, ignition } from "hardhat";
import zetoModule from "../../ignition/modules/zeto_anon_enc_nullifier_kyc_non_repudiation_enforced";
import { smtLibraries, withZetoLockableLib } from "../lib/zeto_libraries";

export async function deployDependencies() {
  const [deployer] = await ethers.getSigners();

  const {
    verifier,
    depositVerifier,
    withdrawVerifier,
    forcedTransferVerifier,
    codec,
    transferFacet,
    smtLib,
    poseidon2,
    poseidon3,
    zetoLockableLib,
  } = await ignition.deploy(zetoModule);
  return {
    deployer,
    args: [
      "Zeto Anon Enc Nullifier Kyc Non Repudiation Enforced",
      "ZAENKNRE",
      await deployer.getAddress(),
      {
        verifier: verifier.target,
        depositVerifier: depositVerifier.target,
        withdrawVerifier: withdrawVerifier.target,
        // Non-batch variant — batch verifiers set to zero address
        batchVerifier: "0x0000000000000000000000000000000000000000",
        batchWithdrawVerifier: "0x0000000000000000000000000000000000000000",
        lockVerifier: "0x0000000000000000000000000000000000000000",
        batchLockVerifier: "0x0000000000000000000000000000000000000000",
        burnVerifier: "0x0000000000000000000000000000000000000000",
        batchBurnVerifier: "0x0000000000000000000000000000000000000000",
        forcedTransferVerifier: forcedTransferVerifier.target,
      },
    ],
    codec: codec.target,
    transferFacet: transferFacet.target,
    libraries: withZetoLockableLib(
      zetoLockableLib,
      smtLibraries({ smtLib, poseidon2, poseidon3 }),
    ),
  };
}

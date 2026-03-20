import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { SmtLibModule } from "./lib/deps";

const VerifierModule = buildModule(
  "Groth16Verifier_AnonEncNullifierKycNonRepudiationEnforced",
  (m) => {
    const verifier = m.contract(
      "Groth16Verifier_AnonEncNullifierKycNonRepudiationEnforced",
      [],
    );
    return { verifier };
  },
);

const DepositVerifierModule = buildModule(
  "Groth16Verifier_DepositKycNonRepudiationEnforced",
  (m) => {
    const verifier = m.contract(
      "Groth16Verifier_DepositKycNonRepudiationEnforced",
      [],
    );
    return { verifier };
  },
);

const WithdrawVerifierModule = buildModule(
  "Groth16Verifier_WithdrawNullifierKycEnforced",
  (m) => {
    const verifier = m.contract(
      "Groth16Verifier_WithdrawNullifierKycEnforced",
      [],
    );
    return { verifier };
  },
);

const ForcedTransferVerifierModule = buildModule(
  "Groth16Verifier_ForcedTransferNullifierKycEnforced",
  (m) => {
    const verifier = m.contract(
      "Groth16Verifier_ForcedTransferNullifierKycEnforced",
      [],
    );
    return { verifier };
  },
);

// Non-batch only — no batch verifier modules for this variant.
export default buildModule(
  "Zeto_AnonEncNullifierKycNonRepudiationEnforced",
  (m) => {
    const { smtLib, poseidon2, poseidon3 } = m.useModule(SmtLibModule);
    const { verifier } = m.useModule(VerifierModule);
    const { verifier: depositVerifier } = m.useModule(DepositVerifierModule);
    const { verifier: withdrawVerifier } = m.useModule(WithdrawVerifierModule);
    const { verifier: forcedTransferVerifier } = m.useModule(
      ForcedTransferVerifierModule,
    );
    return {
      verifier,
      depositVerifier,
      withdrawVerifier,
      forcedTransferVerifier,
      smtLib,
      poseidon2,
      poseidon3,
    };
  },
);
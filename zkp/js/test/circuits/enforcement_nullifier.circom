pragma circom 2.2.2;

include "../../../circuits/lib/enforcement-nullifier.circom";

component main { public [ inputCommitment, counterpartyPublicKey ] } = EnforcementNullifier();
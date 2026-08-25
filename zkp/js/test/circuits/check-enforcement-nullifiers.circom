pragma circom 2.2.2;

include "../../../circuits/lib/check-enforcement-nullifiers.circom";

component main { public [ enforcementNullifiers, inputCommitments, counterpartyPublicKey, enabled ] } = CheckEnforcementNullifiers(2);

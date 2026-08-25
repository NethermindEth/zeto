pragma circom 2.2.2;

include "../../../circuits/lib/check-enabled-inputs.circom";

component main { public [ enabled, commitments, values ] } = CheckEnabledInputs(2);

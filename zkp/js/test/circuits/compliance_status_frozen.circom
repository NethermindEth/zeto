pragma circom 2.2.2;

include "../../../circuits/lib/compliance-status.circom";

// STATUS=2 (FROZEN), nIdentities=1, nComplianceSMTLevels=20 — production depth
component main { public [ root ] } = ComplianceStatus(1, 20, 2);
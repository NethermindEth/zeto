pragma circom 2.2.2;

include "../../../circuits/lib/compliance_status.circom";

// STATUS=2 (FROZEN), nIdentities=1, nComplianceSMTLevels=10
component main { public [ root ] } = ComplianceStatus(1, 10, 2);
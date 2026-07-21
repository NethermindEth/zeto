pragma circom 2.2.2;

include "./basetokens/anon_enc_nullifier_kyc_non_repudiation_enforced_base.circom";

// Output signals (signal output in template, not in { public [] }):
//   ecdhPublicKey[2], encryptedValuesForReceiver[2][4],
//   encryptedValuesForArbiter[16], encryptedValuesForEnforcer[16]
component main { public [ ownerNullifiers, enforcementNullifiers, outputCommitments,
                          encryptionNonce, utxosRoot, identitiesRoot, complianceRoot,
                          enabledInputs, arbiterPublicKey, enforcerPublicKey ] }
  = Zeto(2, 2, 32, 20, 20);
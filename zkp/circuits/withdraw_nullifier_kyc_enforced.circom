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
pragma circom 2.2.2;

include "./basetokens/withdraw_nullifier_kyc_enforced_base.circom";

// Output signals (signal output in template, not in { public [] }):
//   ecdhPublicKey[2], encryptedValuesForArbiter[16], encryptedValuesForEnforcer[16]
component main { public [ amount, ownerNullifiers, enforcementNullifiers, outputCommitments,
                          utxosRoot, identitiesRoot, complianceRoot, enabledInputs,
                          encryptionNonce, arbiterPublicKey, enforcerPublicKey,
                          recipient ] }
  = WithdrawEnforced(2, 1, 32, 20, 20);

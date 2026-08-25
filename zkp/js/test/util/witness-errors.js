// Copyright © 2025 Kaleido, Inc.
//
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

// circom_tester's wasm witness calculator appends every failed assert to a
// single error string that lives for the whole process. The message thrown by
// the Nth failing witness therefore carries the stacks of all N failures, so
// matching a template name against `err.message` proves nothing about the
// failure under test — the name may have been left there by an earlier test in
// the same file. Measured on the transfer suite: run alone, a rejection carries
// 4 lines and names neither CheckEnabledInputs nor CheckEnforcementNullifiers;
// run in file order, the same rejection carries 29 lines and names both. Every
// such assertion in these suites was passing on residue from earlier tests.
//
// `newRejectionTracker` returns a `rejects(circuit, inputs)` helper that throws
// if the circuit ACCEPTS the witness. The call is therefore the assertion — a
// test that reaches the next line has proved the rejection. It also returns the
// lines appended by this failure, for a caller that needs them; that
// tail is sometimes empty, because a failure whose stack matches one already
// recorded appends nothing.
//
// Do not assert a gadget name against that either. The appended stack usually
// names only the wrapper template and a source line — `Error in template
// Zeto_278 line: 199` — because the constraint is attributed to the anonymous
// component's call site rather than to the gadget, and line numbers move with
// any edit above them.
//
// The sound way to show a rejection has the cause a test claims is a paired
// positive control: the same witness with only the attacked field restored must
// be accepted. The suites here do that for the slot-gating and change-output
// cases.
//
// One tracker per compiled circuit: the accumulation lives in that circuit's
// witness calculator.
function newRejectionTracker() {
  let consumedLines = 0;

  return async function rejects(circuit, inputs) {
    let err;
    try {
      await circuit.calculateWitness(inputs, true);
    } catch (e) {
      err = e;
    }
    if (err === undefined) {
      throw new Error(
        "expected the witness to be rejected, but the circuit accepted it",
      );
    }
    const lines = err.message.split("\n");
    const fresh = lines.slice(consumedLines).join("\n");
    consumedLines = lines.length;
    return fresh;
  };
}

module.exports = { newRejectionTracker };

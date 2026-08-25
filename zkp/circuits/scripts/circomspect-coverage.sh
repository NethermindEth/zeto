#!/usr/bin/env bash
#
# Copyright © 2025 Kaleido, Inc.
# SPDX-License-Identifier: Apache-2.0
#
# Circomspect reports "No issues found" for a file in which it analysed nothing
# at all. On the AENKNR-E wrappers that is exactly what happens: circomspect
# cannot parse circom buses, so it walks away from the file and still exits 0.
# A green line from this tool is therefore not evidence of anything unless a
# matching "analyzing template" line was printed.
#
# This script credits coverage only when it is real:
#   - every listed circuit must yield at least one analysed template;
#   - the circuits known to yield none are listed explicitly below, with the
#     reason, so the gap is reviewed rather than invisible;
#   - if a listed exception starts analysing, the build fails and asks for it to
#     be removed, so the list can only shrink.
#
# It deliberately does not attempt to rewrite the wrappers to avoid buses:
# restructuring production code so a linter parses more of it, without checking
# what it actually then covers, trades real assurance for an apparent one.

set -uo pipefail

cd "$(dirname "$0")/.."

CIRCOMSPECT="${CIRCOMSPECT:-circomspect}"
if ! command -v "$CIRCOMSPECT" >/dev/null 2>&1; then
  echo "circomspect not found on PATH (set CIRCOMSPECT to override)" >&2
  exit 127
fi

# Circuits that must be analysed.
ANALYSED=(
  lib/check-enabled-inputs.circom
  lib/check-non-zero.circom
  lib/check-babyjub-public-key.circom
  lib/check-enforcement-nullifiers.circom
  lib/enforcement-nullifier.circom
  lib/compliance-status.circom
)

# Circuits circomspect currently cannot analyse, with the reason. Every entry is
# zero coverage, not a clean bill of health.
#   all four: `CommitmentInputs()` buses — circomspect has no bus support, so it
#   abandons the file. Three surface a parse error; the transfer wrapper reports
#   "No issues found" having analysed nothing.
NOT_ANALYSED=(
  anon_enc_nullifier_kyc_non_repudiation_enforced.circom
  deposit_kyc_non_repudiation_enforced.circom
  withdraw_nullifier_kyc_enforced.circom
  forced_transfer_nullifier_kyc_enforced.circom
)

status=0

count_templates() {
  "$CIRCOMSPECT" "$1" 2>&1 | grep -c "analyzing template" || true
}

for circuit in "${ANALYSED[@]}"; do
  n=$(count_templates "$circuit")
  if [ "$n" -lt 1 ]; then
    echo "FAIL  $circuit: circomspect analysed 0 templates — its result is vacuous" >&2
    status=1
  else
    echo "ok    $circuit: $n template(s) analysed"
  fi
done

for circuit in "${NOT_ANALYSED[@]}"; do
  n=$(count_templates "$circuit")
  if [ "$n" -gt 0 ]; then
    echo "FAIL  $circuit: now analyses $n template(s) — remove it from NOT_ANALYSED" >&2
    status=1
  else
    echo "known $circuit: 0 templates analysed (buses unsupported) — no coverage credited"
  fi
done

exit $status

#!/usr/bin/env bash
#
# SPDX-License-Identifier: Apache-2.0
#
# Circomspect reports "No issues found" for a file in which it analyzed nothing
# at all. On the AENKNR-E wrappers that is exactly what happens: circomspect
# cannot parse circom buses, so it walks away from the file and still exits 0.
# A green line from this tool is therefore not evidence of anything unless it
# also says what it looked at.
#
# This gate credits coverage only when it is real. It takes the file set from
# the tree rather than from a hand-kept list, requires every file in that set to
# be classified below, and fails on any circomspect finding, whose output it
# prints.

set -uo pipefail

cd "$(dirname "$0")/.."

CIRCOMSPECT="${CIRCOMSPECT:-circomspect}"
if ! command -v "$CIRCOMSPECT" >/dev/null 2>&1; then
  echo "circomspect not found on PATH (set CIRCOMSPECT to override)" >&2
  exit 127
fi

# Files circomspect must actually analyze. Every one must yield at least one
# analyzed template or function, and report no findings.
ANALYZED=(
  lib/check-babyjub-public-key.circom
  lib/check-enabled-inputs.circom
  lib/check-enforcement-nullifiers.circom
  lib/check-non-zero.circom
  lib/check-output-slots.circom
  lib/cipher-text-length.circom
  lib/compliance-constants.circom
  lib/compliance-status.circom
  lib/enforcement-nullifier.circom
)

# Files circomspect cannot analyze, with the reason. Every entry is zero
# coverage, not a clean bill of health. If one starts analyzing, the gate fails
# and asks for it to be moved, so the list can only shrink.
#
#   all four: `CommitmentInputs()` buses — circomspect has no bus support, so it
#   abandons the file. Three surface a parse error; the transfer wrapper reports
#   "No issues found" having analyzed nothing.
NOT_ANALYZED=(
  anon_enc_nullifier_kyc_non_repudiation_enforced.circom
  deposit_kyc_non_repudiation_enforced.circom
  forced_transfer_nullifier_kyc_enforced.circom
  withdraw_nullifier_kyc_enforced.circom
)

# Upstream files this fork does not own. They are named rather than skipped by
# pattern so that a new file under lib/ cannot join them by accident; several
# carry findings that belong to whoever changes them.
OUT_OF_SCOPE=(
  lib/burn-nullifiers.circom
  lib/burn.circom
  lib/buses.circom
  lib/check-hashes-tokenid-uri.circom
  lib/check-hashes.circom
  lib/check-inputs-outputs-value-base.circom
  lib/check-nullifiers-tokenid-uri.circom
  lib/check-nullifiers-value-base.circom
  lib/check-nullifiers.circom
  lib/check-positive.circom
  lib/check-smt-proof.circom
  lib/check-sum.circom
  lib/deposit.circom
  lib/ecdh.circom
  lib/encrypt-outputs.circom
  lib/encrypt.circom
  lib/hash_signals.circom
  lib/kyc.circom
  lib/poseidon-ex.circom
  lib/poseidon.circom
  lib/pubkey.circom
)

contains() {
  local needle=$1 item
  shift
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

# The gate's scope, read off the tree: every library file, and every top-level
# enforced circuit. A file added to either place is in scope from the moment it
# lands, whether or not anyone remembers to list it.
scope=()
while IFS= read -r f; do scope+=("$f"); done < <(
  { find lib -maxdepth 1 -name '*.circom'; ls -1 *_enforced.circom; } | sort
)

status=0

for circuit in "${scope[@]}"; do
  if contains "$circuit" "${OUT_OF_SCOPE[@]}"; then
    continue
  fi

  in_analyzed=false
  in_not_analyzed=false
  contains "$circuit" "${ANALYZED[@]}" && in_analyzed=true
  contains "$circuit" "${NOT_ANALYZED[@]}" && in_not_analyzed=true

  if ! $in_analyzed && ! $in_not_analyzed; then
    echo "FAIL  $circuit: not classified — add it to ANALYZED, NOT_ANALYZED or OUT_OF_SCOPE" >&2
    status=1
    continue
  fi

  out=$("$CIRCOMSPECT" "$circuit" 2>&1)
  n=$(printf '%s\n' "$out" | grep -c "analyzing \(template\|function\)")
  findings=$(printf '%s\n' "$out" | grep -c "^circomspect: [0-9][0-9]* issue")

  if $in_analyzed && [ "$n" -lt 1 ]; then
    echo "FAIL  $circuit: circomspect analyzed nothing — its result is vacuous" >&2
    printf '%s\n' "$out" >&2
    status=1
    continue
  fi

  if $in_not_analyzed; then
    if [ "$n" -gt 0 ]; then
      echo "FAIL  $circuit: now analyzes $n item(s) — move it to ANALYZED" >&2
      status=1
    else
      # The finding these files report is the bus parse error itself, which is
      # the reason they are here. Judging them on findings would be judging
      # circomspect's own limitation.
      echo "known $circuit: 0 items analyzed (buses unsupported) — no coverage credited"
    fi
    continue
  fi

  if [ "$findings" -gt 0 ]; then
    echo "FAIL  $circuit: circomspect reported findings" >&2
    printf '%s\n' "$out" >&2
    status=1
    continue
  fi

  echo "ok    $circuit: $n item(s) analyzed, no findings"
done

exit $status

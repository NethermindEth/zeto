# Lost-key recovery via clawback

ERC-3643 `recoveryAddress` moves a holding from a lost wallet to a replacement while keeping the investor's identity. On an enforced Zeto token (`Zeto_AnonEncNullifierKycNonRepudiationEnforced`), the same outcome is a **clawback**: the clawback authority (`enforcer`) runs `forcedTransfer` so the notes land under the investor's new key.

## Prerequisites

- The token variant ships freeze (compliance status tree) and clawback (enforcement nullifiers + `forcedTransfer`).
- Every note the authority may seize was created while that authority's public key was configured as the enforcer, so the authority can derive enforcement nullifiers and decrypt its ciphertext copies.
- Circuit arity for `forced_transfer_nullifier_kyc_enforced` is **2 inputs / 2 outputs**. Recovering more notes means **multiple** `forcedTransfer` calls.

## Steps

1. **Register the replacement key** in the identity (KYC) tree and set its compliance status to **ACTIVE**.
2. **Freeze the lost key** — update the compliance root so the lost public key is **FROZEN**. While frozen, ordinary `transfer` / `withdraw` proofs for that key fail the ACTIVE compliance check.
3. **Locate the lost notes** — decrypt the enforcer ciphertext stream from earlier deposits/transfers (or your off-chain index) to recover commitments, values, and salts for the lost owner.
4. **Claw back in batches** — for each batch of up to two input notes, build a `forcedTransfer` proof that:
   - proves the seized owner is KYC'd and **FROZEN**;
   - sends outputs to the replacement key (**ACTIVE**);
   - reveals **enforcement nullifiers** only (the authority does not know the owner private key, so owner nullifiers stay hidden).
5. **Spend from the replacement key** with a normal `transfer` once the recovered notes are in its wallet.
6. **Do not expect a second clawback** of the same notes — their enforcement nullifiers are already spent, so another `forcedTransfer` reverts with `EnforcementNullifierAlreadySpent`.

## What the end-to-end test covers

`solidity/test/zeto_anon_enc_nullifier_kyc_non_repudiation_enforced.ts` → describe **`lost-key recovery via clawback`**:

- four notes under the lost key (more than one proof's two inputs);
- two batched `forcedTransfer` calls that move the full balance to the replacement;
- a successful spend from the replacement key;
- failed proofs with the lost key both while frozen and after recovery;
- a rejected second clawback of the same notes.

## Related

- Partial freeze / escrow-style clawback: issue discussion around `freezePartialTokens` (claw back a slice, change returns to the frozen owner).
- Module split of freeze vs clawback: see the freeze/clawback standalone-modules proposal in the repository issues.

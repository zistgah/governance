# zops — the one operations tool

© 1993–2026 Abhishek Choudhary. All rights reserved. AyeAI.

Every `apply_*` / `seed_*` script was re-implementing the same stages, and they
drifted. `seed_qedler.sh` ran `git clone` into an existing `./qedler` and died;
`apply_contracts.sh` had already solved that with clone-or-reuse. Same bug,
solved twice, wrong once. This library is the fix: solve each thing once.

## Use it

```sh
. ops/zops.sh
zops_init "qedler seed"
zops_preflight git python3 -- gh misty ots      # required -- optional
zops_repo project-ilm/qedler                    # clone OR reuse; safe on rerun
zops_contract_begin
  zops_check Q1 "copyright"      zops_check_copyright
  zops_check Q2 "affiliation"    zops_check_affiliation
  zops_check Q3 "no placeholder" zops_check_no_placeholder
zops_contract_end || exit 1
zops_diff
zops_push "qedler: seed the corpus"             # gate → commit → receipt → stamp → reseal → verify → push
zops_mark                                       # return-to tag at HEAD
zops_done
```

## What it enforces, and why

| invariant | learned from |
|---|---|
| never writes outside the invoking directory | "why are you climbing out of the executing folder" |
| clone-or-reuse, idempotent on rerun | `seed_qedler.sh` died on the second run |
| absent optional tools declared, never worked around | spiguard ABSENT was handled right; keep it that way |
| one tolerant typed gate per run | the strict form cost four attempts at the prompt |
| gate **is** the Candor intent — push and seal are one call | a push landed with no receipt and a broken MANIFEST |
| OTS waits announced; no client ⇒ stamp nothing, fake nothing | a silent calendar wait read as breakage |
| rotate manifest **and** its proof into `attest/history/` first | proofs are never overwritten |
| receipts written and stamped **before** the manifest | otherwise the manifest misses its own receipt's `.ots` |

## Functions

`zops_init` · `zops_preflight` · `zops_have` · `zops_repo` · `zops_contract_begin`
· `zops_check` · `zops_contract_end` · `zops_diff` · `zops_gate` · `zops_receipt`
· `zops_stamp` · `zops_reseal` · `zops_push` · `zops_mark` · `zops_done`

Standard checks: `zops_check_copyright`, `zops_check_affiliation`,
`zops_check_no_placeholder`, `zops_check_manifest`.

`ZOPS_FORGE` overrides the forge base, so Savannah is a variable, not a fork.

## zmark.sh

`bash ops/zmark.sh --dry` surveys every repo; without `--dry` it takes one typed
MARK and puts an annotated `return-to/<UTC>` tag on the HEAD of each. Tags are
additive — no branch moves, no history rewritten, nothing minted.
Retrace with `git checkout return-to/<UTC>`.

#!/usr/bin/env bash
# ops/zmark.sh — mark the top of every touched project as a RETURN-TO version.
#
# One annotated tag per repo at its current HEAD, so any later state can be
# retraced to a known-good point:  git checkout return-to/<UTC>
#
# Written against ops/zops.sh — it is the first consumer of the library and
# exists partly to prove the library carries its weight.
#
#   bash ops/zmark.sh --dry     # show what would be tagged, tag nothing
#   bash ops/zmark.sh           # one typed MARK gate, then tag + push all
#   bash ops/zmark.sh --repos "zistgah/fakir project-ilm/chakra"
#
# Runs from any directory; clones/reuses under ./ and never climbs out.
# © 1993–2026 Abhishek Choudhary. All rights reserved. AyeAI.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/zops.sh" 2>/dev/null || . "$PWD/ops/zops.sh"

# The estate as touched this cycle. Override with --repos.
REPOS_DEFAULT="
zistgah/fakir
zistgah/dome
zistgah/governance
zistgah/transeg
zistgah/aab
zistgah/poie
zistgah/zamin
zistgah/pratik_core_mvp
zistgah/fiza
project-ilm/chakra
project-ilm/ilm.codes
project-ilm/misty-doi
project-ilm/tok-doi
project-ilm/romenagri
project-ilm/qedler
"
DRY=0; REPOS="$REPOS_DEFAULT"
while [ $# -gt 0 ]; do case "$1" in
  --dry) DRY=1; shift ;;
  --repos) REPOS="$2"; shift 2 ;;
  *) echo "unknown flag: $1" >&2; exit 2 ;;
esac; done

zops_init "return-to marking"
zops_preflight git python3 -- gh ots

LABEL="return-to"
STAMP="$ZOPS_UTC"
BASE="$ZOPS_HOME"
declare -a MARKED=() SKIPPED=() MISSING=()

_z_b "SURVEY — current HEAD of each repo"
for slug in $REPOS; do
  [ -n "$slug" ] || continue
  name="${slug##*/}"
  if [ -d "$BASE/$name/.git" ]; then
    head="$(git -C "$BASE/$name" rev-parse --short HEAD 2>/dev/null || echo '?')"
    _z_i "$(printf '%-34s %s  (local clone)' "$slug" "$head")"
  else
    _z_i "$(printf '%-34s %s' "$slug" "will be cloned")"
  fi
done

if [ "$DRY" = 1 ]; then
  _z_b "DRY — nothing tagged. Tag name would be ${LABEL}/${STAMP}"
  zops_done; exit 0
fi

_z_b "GATE — one assertion covers every repo in this run"
cat <<TXT
   About to create an annotated tag ${LABEL}/${STAMP} at the current HEAD of
   each repository above, and push it. Tags are additive: no branch moves,
   no history is rewritten, nothing is minted.
TXT
REASON="$(zops_gate MARK)" || { _z_b "ABORTED — nothing tagged"; exit 0; }

for slug in $REPOS; do
  [ -n "$slug" ] || continue
  name="${slug##*/}"
  cd "$BASE"
  if ! zops_repo "$slug" "$name" 2>/dev/null; then
    MISSING+=("$slug"); _z_no "$slug — unreachable, skipped"; cd "$BASE"; continue
  fi
  tag="${LABEL}/${STAMP}"
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
    SKIPPED+=("$slug"); _z_i "$slug already carries $tag"
  else
    git -c user.name="$ZOPS_NAME" -c user.email="$ZOPS_EMAIL" tag -a "$tag" -m \
"Return-to point for $slug at $(git rev-parse --short HEAD).

$REASON

Retrace with:  git checkout $tag
Marked $STAMP on $ZOPS_HOST.
(c) 1993-2026 Abhishek Choudhary. All rights reserved. AyeAI."
    if git push --quiet origin "$tag" 2>/dev/null; then
      MARKED+=("$slug"); _z_ok "$(printf '%-34s %s -> %s' "$slug" "$(git rev-parse --short HEAD)" "$tag")"
    else
      SKIPPED+=("$slug"); _z_no "$slug tagged locally, push refused (permissions?)"
    fi
  fi
  cd "$BASE"
done

_z_b "LEDGER"
_z_i "tag:     ${LABEL}/${STAMP}"
_z_i "marked:  ${#MARKED[@]}"
_z_i "skipped: ${#SKIPPED[@]}"
_z_i "missing: ${#MISSING[@]} ${MISSING[*]:-}"
_z_i ""
_z_i "Retrace any of them with:  git checkout ${LABEL}/${STAMP}"
zops_done

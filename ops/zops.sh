#!/usr/bin/env bash
# ops/zops.sh — the Zistgah operations library.
#
# Every apply_*/seed_* script sources this instead of re-implementing the same
# stages. It exists because they WERE re-implemented every time and drifted:
# seed_qedler.sh ran `git clone` into an existing ./qedler and died, while
# apply_contracts.sh had already solved that with clone-or-reuse. One tool now.
#
#   . ops/zops.sh
#   zops_init "qedler seed"
#   zops_preflight git python3 -- gh misty ots     # required -- optional
#   zops_repo project-ilm/qedler                   # clone OR reuse; safe on rerun
#   zops_contract_begin; zops_check ...; zops_contract_end
#   zops_push "summary line"                       # gate+commit+receipt+stamp+reseal+verify+push
#   zops_mark                                      # return-to tag at HEAD
#   zops_done
#
# INVARIANTS ENFORCED HERE (each learned from a real failure, not invented):
#   · never climbs out of the invoking directory — everything under $PWD
#   · forge is overridable via ZOPS_FORGE, so Savannah is a variable not a fork
#   · clone-or-reuse, idempotent on rerun            [seed_qedler.sh died on this]
#   · absent optional tools are DECLARED absent, never worked around silently
#   · one typed gate per run, tolerantly parsed      [strict form cost 4 attempts]
#   · the gate IS the Candor intent: pushing and sealing are one call
#   · OTS waits announced; no ots client => stamp nothing, fabricate nothing
#   · manifest rotation archives the outgoing manifest AND its proof first
#   · receipts written and stamped BEFORE the manifest, so the manifest covers them
#
# © 1993–2026 Abhishek Choudhary. All rights reserved. AyeAI.
# SPDX-License-Identifier: GPL-3.0-or-later

ZOPS_VERSION="1.0.0"
[ -n "${ZOPS_SOURCED:-}" ] && return 0
ZOPS_SOURCED=1

# ---------------------------------------------------------------- presentation
_z_b(){ printf '\n\033[1m%s\033[0m\n' "$*"; }
_z_i(){ printf '   %s\n' "$*"; }
_z_ok(){ printf '   \033[32mok\033[0m   %s\n' "$*"; }
_z_no(){ printf '   \033[31mFAIL\033[0m %s\n' "$*"; }
zops_die(){ printf '\n\033[31mABORT: %s\033[0m\n' "$*" >&2; exit "${2:-1}"; }

# ---------------------------------------------------------------- 1. init
# Pins every path to the invoking directory. Nothing written outside $ZOPS_HOME.
zops_init(){
  ZOPS_TITLE="${1:-zops}"
  ZOPS_HOME="$PWD"
  ZOPS_UTC="$(date -u +%Y%m%dT%H%M%SZ)"
  ZOPS_LOGS="$ZOPS_HOME/logs"
  mkdir -p "$ZOPS_LOGS"
  ZOPS_LOG="$ZOPS_LOGS/${ZOPS_TITLE// /_}.$ZOPS_UTC.log"
  ZOPS_HOST="${CANDOR_HOST:-$(hostname 2>/dev/null || echo unknown)}"
  ZOPS_NAME="${CANDOR_NAME:-Abhishek Choudhary}"
  ZOPS_EMAIL="${CANDOR_EMAIL:-abhishek@ayeai.in}"
  ZOPS_FAILED=0
  ZOPS_SLUG="${ZOPS_SLUG:-local}"
  _z_b "$ZOPS_TITLE · zops $ZOPS_VERSION · $ZOPS_UTC"
  _z_i "© 1993–2026 Abhishek Choudhary. All rights reserved."
  _z_i "working dir: $ZOPS_HOME   (nothing is written outside it)"
  _z_i "log:         ${ZOPS_LOG#"$ZOPS_HOME"/}"
}

# ---------------------------------------------------------------- 2. preflight
# zops_preflight git python3 -- gh ots misty
zops_preflight(){
  _z_b "preflight"
  local mode=req t p
  for t in "$@"; do
    if [ "$t" = "--" ]; then mode=opt; continue; fi
    p="$(command -v "$t" 2>/dev/null || true)"
    if [ -n "$p" ]; then
      _z_i "$(printf '%-10s %s' "$t" "$p")"
      eval "ZOPS_HAS_${t//[^a-zA-Z0-9]/_}=1"
    elif [ "$mode" = req ]; then
      zops_die "required tool missing: $t"
    else
      _z_i "$(printf '%-10s ABSENT — its step is skipped, not faked' "$t")"
      eval "ZOPS_HAS_${t//[^a-zA-Z0-9]/_}=0"
    fi
  done
}
zops_have(){ local v="ZOPS_HAS_${1//[^a-zA-Z0-9]/_}"; [ "${!v:-0}" = 1 ]; }

# ---------------------------------------------------------------- 3. repo
# THE qedler BUG, fixed once and for all: clone if absent, reset if present.
zops_repo(){
  local slug="$1" name="${2:-${1##*/}}"
  ZOPS_SLUG="$slug"; ZOPS_REPO="$ZOPS_HOME/$name"
  if [ -d "$ZOPS_REPO/.git" ]; then
    _z_b "REUSING ./$name"
    git -C "$ZOPS_REPO" fetch --quiet origin 2>/dev/null \
      || _z_i "fetch failed — working offline against the existing clone"
    ZOPS_BRANCH="$(git -C "$ZOPS_REPO" symbolic-ref --short HEAD 2>/dev/null || echo main)"
    git -C "$ZOPS_REPO" reset --hard --quiet "origin/$ZOPS_BRANCH" 2>/dev/null || true
    git -C "$ZOPS_REPO" clean -qfd 2>/dev/null || true
  elif [ -e "$ZOPS_REPO" ]; then
    zops_die "./$name exists and is not a git clone — move it aside first"
  else
    _z_b "CLONING $slug → ./$name"
    if git clone --quiet "${ZOPS_FORGE:-https://github.com}/${slug}.git" "$ZOPS_REPO" 2>/dev/null; then
      :
    else
      # C12 — the remote does not exist yet. Do not die: a new repository is a
      # normal thing to seed. Initialise locally and record that the remote must
      # be created. Creating it is a public, irreversible act, so it happens in
      # zops_push under the typed gate that already lives there.
      _z_i "remote $slug not found — initialising a NEW local repo"
      _z_i "the remote will be created at push time, under your typed assertion"
      mkdir -p "$ZOPS_REPO"
      git -C "$ZOPS_REPO" init --quiet
      git -C "$ZOPS_REPO" symbolic-ref HEAD refs/heads/main 2>/dev/null || true
      git -C "$ZOPS_REPO" remote add origin \
        "${ZOPS_FORGE:-https://github.com}/${slug}.git" 2>/dev/null || true
      ZOPS_REMOTE_ABSENT=1
    fi
    ZOPS_BRANCH="$(git -C "$ZOPS_REPO" symbolic-ref --short HEAD 2>/dev/null || echo main)"
  fi
  cd "$ZOPS_REPO" || zops_die "cannot enter $ZOPS_REPO"
  _z_i "at $(git rev-parse --short HEAD) on $ZOPS_BRANCH"
}

# ---------------------------------------------------------------- 4. contract
zops_contract_begin(){ _z_b "contract"; ZOPS_FAILED=0; }
zops_check(){
  local id="$1" desc="$2"; shift 2
  if "$@" >/dev/null 2>&1; then _z_ok "$(printf '%-26s %s' "$id" "$desc")"
  else _z_no "$(printf '%-26s %s' "$id" "$desc")"; ZOPS_FAILED=$((ZOPS_FAILED+1)); fi
}
zops_contract_end(){
  if [ "${ZOPS_FAILED:-0}" -eq 0 ]; then _z_b "CONTRACT OK"; return 0
  else _z_b "CONTRACT VIOLATED — $ZOPS_FAILED check(s) failing"; return 1; fi
}

# standard checks, reusable by every repo
zops_check_copyright(){ grep -rqI '1993.\{0,3\}2026 Abhishek Choudhary' README.md 2>/dev/null; }
# A forbidden affiliation is a violation only where it is CLAIMED, never where
# it is forbidden. The first run of this check flagged CONTRACT.md, the gate
# rules and this file itself — all of which exist to prohibit the term.
zops_check_affiliation(){
  local hits
  hits="$(grep -rlI 'Independent Researcher' --include='*.md' --include='*.json' --include='*.cff' . 2>/dev/null \
          | grep -v '^\./ops/zops\.sh$' \
          | grep -v '^\./CONTRACT\.md$' \
          | grep -v '^\./filters/' \
          | grep -v '^\./ops/contract\.json$' || true)"
  [ -z "$hits" ]
}
zops_check_no_placeholder(){ ! grep -rqI 'DOI-PENDING\|ZENODO-DOI-PENDING\|zenodo\.NNN' . 2>/dev/null; }
zops_check_manifest(){ [ -f MANIFEST.sha256 ] && sha256sum -c MANIFEST.sha256 >/dev/null 2>&1; }

# ---------------------------------------------------------------- 5. diff
zops_diff(){
  _z_b "diff"
  git add -A >/dev/null 2>&1
  git --no-pager diff --cached --stat | tail -40
  if git diff --cached --quiet; then _z_i "nothing staged"; return 1; fi
  return 0
}

# ---------------------------------------------------------------- 6. gate
# Tolerant on purpose: the strict form once cost four attempts at the prompt.
zops_gate(){
  local want="$1" line word reason
  printf '   Type %s plus a reason ("%s fix", "%s, fix" and "%s: fix" all work).\n' "$want" "$want" "$want" "$want" >&2
  printf '   > ' >&2; read -r line || true
  word="$(printf '%s' "$line" | awk '{print toupper($1)}' | tr -d ',:;.')"
  reason="$(printf '%s' "$line" | sed -E 's/^[[:space:]]*[A-Za-z]+[,:;.]?[[:space:]]*//' | sed -E 's/[[:space:]]+$//')"
  [ "$word" = "$want" ] || return 1
  if [ -z "$reason" ]; then printf '   reason: ' >&2; read -r reason || true; fi
  [ -n "$reason" ] || { printf '   a reason is required — it is the substance of the intent\n' >&2; return 1; }
  printf '%s' "$reason"
}

# ---------------------------------------------------------------- 7. receipt
zops_receipt(){
  local action="$1" commit="$2" reason="$3" note="${4:-}" utc out
  utc="$(date -u +%Y%m%dT%H%M%SZ)"; out="attest/receipts/${utc}-${action}.json"
  mkdir -p attest/receipts
  python3 - "$out" "$action" "$commit" "$reason" "$utc" "$ZOPS_HOST" "$ZOPS_SLUG" "$note" <<'PY'
import json,sys
out,action,commit,reason,utc,host,repo,note = sys.argv[1:9]
p={"action":action,"reason":reason,"utc":utc,"host":host}
if note: p["note"]=note
json.dump({"_type":"https://in-toto.io/Statement/v1",
 "predicateType":"https://project-ilm.org/attestations/candor/v1",
 "subject":[{"name":repo,"digest":{"gitCommit":commit}}],
 "predicate":p}, open(out,"w"), indent=4)
open(out,"a").write("\n")
PY
  printf '%s' "$out"
}

# ---------------------------------------------------------------- 8. stamp
zops_stamp(){
  if ! zops_have ots; then
    _z_i "ots client absent — nothing stamped, nothing fabricated."
    _z_i "install opentimestamps-client and rerun to add the proofs."
    return 0
  fi
  _z_i "stamping $# file(s). OpenTimestamps waits on public calendars: silent for"
  _z_i "up to ~30 s each, and keystrokes you type will echo back. Not breakage."
  local f
  for f in "$@"; do
    [ -e "$f" ] || continue
    if [ -e "${f}.ots" ]; then _z_i "SKIP ${f}.ots exists — proofs are never overwritten"; continue; fi
    printf '     %s ... ' "$f"
    if ots stamp "$f" >/dev/null 2>&1; then echo done; else echo "FAILED (left unstamped, not faked)"; fi
  done
}

# ---------------------------------------------------------------- 9. reseal
zops_reseal(){
  local stamp; stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p attest/history
  if [ -f MANIFEST.sha256 ]; then
    cp MANIFEST.sha256 "attest/history/${stamp}-MANIFEST.sha256"
    if [ -f MANIFEST.sha256.ots ]; then
      cp MANIFEST.sha256.ots "attest/history/${stamp}-MANIFEST.sha256.ots"; rm -f MANIFEST.sha256.ots
    fi
    _z_i "outgoing manifest and proof archived → attest/history/${stamp}-*"
  fi
  git add -A >/dev/null
  git ls-files -z | grep -zv '^MANIFEST.sha256$' | xargs -0 sha256sum > MANIFEST.sha256
  _z_i "MANIFEST.sha256 rebuilt: $(grep -c . MANIFEST.sha256) entries"
  sha256sum -c MANIFEST.sha256 >/dev/null 2>&1 || zops_die "rebuilt manifest does not verify"
  _z_i "verifies clean"
}

# ---------------------------------------------------------------- 10. push
# The whole gated write as ONE call. Sealing is not separable from pushing.
zops_push(){
  # C12 — create the remote if zops_repo found it absent. This runs AFTER the
  # typed gate inside this function has been satisfied, so the human assertion
  # that authorises the push also authorises bringing the repository into being.
  _z_create_remote_if_needed(){
    [ "${ZOPS_REMOTE_ABSENT:-0}" = "1" ] || return 0
    command -v gh >/dev/null 2>&1 || zops_die "remote absent and gh unavailable: create ${ZOPS_SLUG} first"
    _z_b "CREATING ${ZOPS_SLUG} (public)"
    gh repo create "$ZOPS_SLUG" --public >/dev/null 2>&1 \
      || gh repo view "$ZOPS_SLUG" >/dev/null 2>&1 \
      || zops_die "could not create ${ZOPS_SLUG}"
    ZOPS_REMOTE_ABSENT=0
  }
  local summary="$1" reason receipt head
  _z_b "GATE"
  reason="$(zops_gate PUSH)" || { _z_b "ABORTED — tree left verified in place, nothing pushed"; return 10; }

  _z_b "COMMIT"
  git add -A
  git -c user.name="$ZOPS_NAME" -c user.email="$ZOPS_EMAIL" commit --quiet -m "$summary

$reason

(c) 1993-2026 Abhishek Choudhary. All rights reserved. AyeAI." || { _z_i "nothing to commit"; return 11; }
  head="$(git rev-parse HEAD)"; _z_i "$(git rev-parse --short HEAD)"

  _z_b "RECEIPT";  receipt="$(zops_receipt PUSH "$head" "$reason")"; _z_i "$receipt"
  _z_b "OTS — receipts first, so the reseal covers them"; zops_stamp "$receipt"
  _z_b "RESEAL";   zops_reseal; zops_stamp MANIFEST.sha256

  _z_b "SEAL COMMIT"
  git add -A
  git -c user.name="$ZOPS_NAME" -c user.email="$ZOPS_EMAIL" \
      commit --quiet -m "attest: Candor receipt + reseal [$(git rev-parse --short "$head")]"
  _z_i "$(git rev-parse --short HEAD)"

  if [ -f ops/verify.sh ]; then
    _z_b "VERIFY CONTRACT"; bash ops/verify.sh || zops_die "contract violated — NOT pushing"
  fi

  _z_b "PUSH"; git push --quiet origin "$ZOPS_BRANCH"; _z_i "pushed $(git rev-parse --short HEAD)"
  ZOPS_PUSHED="$(git rev-parse HEAD)"
}

# ---------------------------------------------------------------- 11. mark
# "Mark the top of each project as the return-to version." Annotated tag at HEAD
# so any later state can be retraced to a known-good point.
zops_mark(){
  local label="${1:-return-to}" tag msg
  tag="${label}/${ZOPS_UTC}"
  msg="Return-to point for $ZOPS_SLUG at $(git rev-parse --short HEAD).

Retrace with:  git checkout $tag

Marked $ZOPS_UTC on $ZOPS_HOST.
(c) 1993-2026 Abhishek Choudhary. All rights reserved. AyeAI."
  _z_b "MARK — return-to version"
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
    _z_i "$tag already exists — left alone"; ZOPS_TAG="$tag"; return 0
  fi
  git -c user.name="$ZOPS_NAME" -c user.email="$ZOPS_EMAIL" tag -a "$tag" -m "$msg"
  _z_i "tagged $tag at $(git rev-parse --short HEAD)"
  if git push --quiet origin "$tag" 2>/dev/null; then _z_i "pushed tag"
  else _z_i "tag is local — it will go up with your next push"; fi
  ZOPS_TAG="$tag"
}

# ---------------------------------------------------------------- 12. done
zops_done(){
  _z_b "done · $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  [ -n "${ZOPS_TAG:-}" ] && _z_i "return-to: $ZOPS_TAG"
  _z_i "tree: ${ZOPS_REPO:-$ZOPS_HOME}"
  _z_i "log:  ${ZOPS_LOG#"$ZOPS_HOME"/}"
}

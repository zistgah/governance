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

ZOPS_VERSION="1.2.0"
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
zops_have(){
  local v="ZOPS_HAS_${1//[^a-zA-Z0-9]/_}"
  case "${!v:-}" in 1) return 0 ;; 0) return 1 ;; esac
  command -v "$1" >/dev/null 2>&1
}

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
    # The remote may never have existed, or may have been deleted since this
    # clone was made. C12 only set ZOPS_REMOTE_ABSENT on the CLONE path, so a
    # second run reused the local repo, lost the flag, and pushed at nothing —
    # after committing, stamping and sealing. Probe here so the create-at-push
    # path stays reachable on every run, not only the first.
    if ! git -C "$ZOPS_REPO" ls-remote --exit-code origin >/dev/null 2>&1; then
      _z_i "remote $slug is not reachable — it will be created at push time"
      ZOPS_REMOTE_ABSENT=1
    fi
    ZOPS_REMOTE_RECHECKED=1
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
  if git rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
    _z_i "at $(git rev-parse --short HEAD) on $ZOPS_BRANCH"
  else
    _z_i "no commits yet on $ZOPS_BRANCH — this is a new repository"
  fi
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
  # gate-allow: G2-affiliation  (this line FORBIDS the term; it does not claim it)
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
  read -r -p '   > ' line || true
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
    local out
    if ! out="$(gh repo create "$ZOPS_SLUG" --public 2>&1)"; then
      gh repo view "$ZOPS_SLUG" >/dev/null 2>&1 || zops_die "could not create ${ZOPS_SLUG}: ${out}"
    fi
    gh repo view "$ZOPS_SLUG" >/dev/null 2>&1 || zops_die "${ZOPS_SLUG} does not exist after creation"
    ZOPS_REMOTE_ABSENT=0
  }
  local summary="$1" reason receipt head
  _z_b "GATE"
  reason="$(zops_gate PUSH)" || { _z_b "ABORTED — tree left verified in place, nothing pushed"; return 10; }
  # 1.1.0: the helper above was defined and never called, so a new repository was pushed at
  # nothing after being committed and sealed. The typed PUSH authorises its creation.
  _z_create_remote_if_needed

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
  [ "$(git ls-remote origin "refs/heads/$ZOPS_BRANCH" | cut -f1)" = "$(git rev-parse HEAD)" ] \
    || zops_die "origin/$ZOPS_BRANCH does not equal the local HEAD after the push"
  ZOPS_PUSHED="$(git rev-parse HEAD)"
}

# ---------------------------------------------------------------- 10b. pages (1.1.0)
# GitHub Pages from a branch path. POST creates a site and PUT only updates one, so both are
# tried; when neither takes, the reason is printed and nothing is claimed.
zops_pages(){
  local path="${1:-/docs}" out
  _z_b "PAGES"
  zops_have gh || { _z_i "gh absent: Pages not enabled, nothing claimed"; return 3; }
  if out="$(gh api -X POST "repos/$ZOPS_SLUG/pages" -f "source[branch]=$ZOPS_BRANCH" -f "source[path]=$path" 2>&1)"; then
    _z_ok "Pages created from $ZOPS_BRANCH:$path"
  elif out="$(gh api -X PUT "repos/$ZOPS_SLUG/pages" -f "source[branch]=$ZOPS_BRANCH" -f "source[path]=$path" 2>&1)"; then
    _z_ok "Pages set to $ZOPS_BRANCH:$path"
  else
    _z_no "Pages not enabled: $(printf '%s' "$out" | tail -1); the token may lack the pages scope"
    return 1
  fi
}

# ---------------------------------------------------------------- 10c. mint (1.1.0)
# Mints the pushed HEAD through misty. misty's interface is read at run time, the dry run must
# be clean, and the typed MINT is the author's verification. The DOI is read from misty's own
# result file, never from a log; it is recorded back, receipted, resealed and pushed as part of
# the same gated act. A repository that already carries a DOI is never minted as a new record.
zops_mint(){
  local meta="${1:-misty.json}" dir help version doi reason head receipt arc pkg=()
  _z_b "MINT"
  local prev=""
  if [ -f CITATION.cff ] && grep -q '^doi:' CITATION.cff; then
    prev="$(sed -n 's/^doi:[[:space:]]*//p' CITATION.cff | tr -d '"' | head -1)"
  fi
  zops_have misty || { _z_i "misty absent: nothing minted, no DOI claimed"; return 3; }
  [ -n "${ZENODO_TOKEN:-}" ] || { _z_i "ZENODO_TOKEN is not in the environment: nothing minted"; return 3; }
  [ -f "$meta" ] || zops_die "no $meta: one canonical metadata record drives the DOI"
  [ -z "$(git status --porcelain)" ] || zops_die "the working tree is dirty; a DOI names a commit"
  git fetch --quiet origin "$ZOPS_BRANCH" || zops_die "cannot reach origin to confirm the push"
  [ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$ZOPS_BRANCH")" ] \
    || zops_die "HEAD is not on origin/$ZOPS_BRANCH; a DOI naming an unpushed commit points at nothing"
  zops_check_manifest || zops_die "the manifest does not verify; a broken seal is not deposited"
  if [ -n "$prev" ]; then _z_mint_version "$meta" "$prev"; return $?; fi
  help="$(misty publish --help 2>&1 || true)"
  grep -Eq -- '(^|[[:space:],\[])(-f|--files)([[:space:],]|$)' <<<"$help" \
    || zops_die "this misty's publish takes no -f/--files; its --help was read, not recalled"
  if grep -q -- '--no-package' <<<"$help"; then pkg=(--no-package); fi
  version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$meta")" \
    || zops_die "$meta carries no version"
  dir="$ZOPS_HOME/.zops-mint/${ZOPS_SLUG//\//_}"; mkdir -p "$dir"
  arc="$dir/${ZOPS_SLUG##*/}-${version}.tar.gz"
  git archive --format=tar.gz --prefix="${ZOPS_SLUG##*/}-${version}/" -o "$arc" HEAD
  local files=("$arc"); [ -f CITATION.cff ] && files+=("$PWD/CITATION.cff")
  _z_i "deposit: ${arc#"$ZOPS_HOME"/}$([ -f CITATION.cff ] && echo ' and CITATION.cff'), from $(git rev-parse --short HEAD)"
  misty publish -m "$meta" -f "${files[@]}" "${pkg[@]}" --dry-run --output "$dir/dry-run.json" >>"$ZOPS_LOG" 2>&1 \
    || zops_die "the dry run is not clean, so nothing is minted; see ${ZOPS_LOG#"$ZOPS_HOME"/}"
  _z_ok "dry run clean"
  _z_i "A DOI is a dated public disclosure. This creates a new record and a new concept DOI;"
  _z_i "if one already exists for $ZOPS_SLUG, decline here and mint a version beneath it instead."
  reason="$(zops_gate MINT)" || { _z_b "MINT declined; pushed and sealed without a DOI is finished work"; return 10; }
  misty publish -m "$meta" -f "${files[@]}" "${pkg[@]}" --output "$dir/mint.json" >>"$ZOPS_LOG" 2>&1 \
    || zops_die "misty publish failed; nothing recorded back; see ${ZOPS_LOG#"$ZOPS_HOME"/}"
  doi="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("doi") or "")' "$dir/mint.json" 2>/dev/null || true)"
  [[ "$doi" =~ ^10\.5281/zenodo\.[0-9]{6,}$ ]] \
    || zops_die "misty reported success and no DOI; nothing recorded back and nothing invented" 3
  _z_ok "minted $doi"
  ZOPS_DOI="$doi"
  _z_record_back "$doi" "doi: record $doi" "$reason"
}

# The record-back both mint paths share: the DOI into CITATION.cff and README.md, a receipt
# stamped, the seal rebuilt, the contract re-run, and the push proved.
_z_record_back(){
  local doi="$1" msg="$2" reason="$3" head receipt
  python3 - "$doi" <<'PY'
import os, re, sys
doi = sys.argv[1]
if os.path.exists("CITATION.cff"):
    s = open("CITATION.cff", encoding="utf-8").read()
    if re.search(r"(?m)^doi:", s):
        s = re.sub(r"(?m)^doi:.*$", "doi: " + doi, s, count=1)
    else:
        s = s.replace("\nversion:", "\ndoi: " + doi + "\nversion:", 1) if "\nversion:" in s else s + "doi: " + doi + "\n"
    open("CITATION.cff", "w", encoding="utf-8").write(s)
if os.path.exists("README.md"):
    s = open("README.md", encoding="utf-8").read()
    line = "DOI: [" + doi + "](https://doi.org/" + doi + ")"
    if re.search(r"(?m)^DOI: \[10\.5281/zenodo\.\d+\]\(https://doi\.org/10\.5281/zenodo\.\d+\)$", s):
        s = re.sub(r"(?m)^DOI: \[10\.5281/zenodo\.\d+\]\(https://doi\.org/10\.5281/zenodo\.\d+\)$", line, s, count=1)
    else:
        head, _, rest = s.partition("\n")
        s = head + "\n\n" + line + "\n" + rest
    open("README.md", "w", encoding="utf-8").write(s)
PY
  git add -A
  git -c user.name="$ZOPS_NAME" -c user.email="$ZOPS_EMAIL" commit --quiet -m "$msg

$reason

(c) 1993-2026 Abhishek Choudhary. All rights reserved. AyeAI."
  head="$(git rev-parse HEAD)"
  _z_b "RECEIPT"; receipt="$(zops_receipt MINT "$head" "$reason" "$doi")"; _z_i "$receipt"
  zops_stamp "$receipt"
  _z_b "RESEAL"; zops_reseal; zops_stamp MANIFEST.sha256
  git add -A
  git -c user.name="$ZOPS_NAME" -c user.email="$ZOPS_EMAIL" \
      commit --quiet -m "attest: DOI record-back [Candor $(git rev-parse --short "$head")]"
  if [ -f ops/verify.sh ]; then
    bash ops/verify.sh >>"$ZOPS_LOG" 2>&1 || zops_die "the contract fails after the record-back; NOT pushed"
  fi
  git push --quiet origin "$ZOPS_BRANCH"
  [ "$(git ls-remote origin "refs/heads/$ZOPS_BRANCH" | cut -f1)" = "$(git rev-parse HEAD)" ] \
    || zops_die "origin/$ZOPS_BRANCH does not equal the local HEAD after the record-back push"
  _z_ok "recorded back, resealed and pushed at $(git rev-parse --short HEAD)"
}

# 1.2.0: a repository that already carries a DOI gets a NEW VERSION beneath that DOI's concept,
# through misty newversion, never a second record. The typed MINT is the author's
# verification and is written into the metadata the guard reads; the dry run before it shows
# every guard finding without letting the missing verification block the look.
_z_mint_version(){
  local meta="$1" prev="$2" help version dir arc dry res doi concept prevv reason head receipt
  help="$(misty newversion --help 2>&1 || true)"
  grep -q -- '--concept' <<<"$help" \
    || { _z_i "this misty cannot add a version beneath $prev: its newversion has no --concept (misty-doi 1.2.0 has); nothing minted"; return 3; }
  version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$meta")" \
    || zops_die "$meta carries no version"
  dir="$ZOPS_HOME/.zops-mint/${ZOPS_SLUG//\//_}"; mkdir -p "$dir"
  arc="$dir/${ZOPS_SLUG##*/}-${version}.tar.gz"
  git archive --format=tar.gz --prefix="${ZOPS_SLUG##*/}-${version}/" -o "$arc" HEAD
  local files=("$arc"); [ -f CITATION.cff ] && files+=("$PWD/CITATION.cff")
  _z_i "deposit: ${arc#"$ZOPS_HOME"/}$([ -f CITATION.cff ] && echo ' and CITATION.cff'), from $(git rev-parse --short HEAD)"
  dry="$dir/dry-run.json"; rm -f "$dry"
  if ! misty newversion -c "$prev" -m "$meta" -f "${files[@]}" --dry-run --allow-findings --output "$dry" >>"$ZOPS_LOG" 2>&1; then
    if tail -3 "$ZOPS_LOG" | grep -q "is already the latest version's"; then
      _z_i "version $version is already minted beneath this concept ($prev); nothing to mint"; return 0
    fi
    tail -4 "$ZOPS_LOG" | sed 's/^/   /'
    zops_die "the version dry run is not clean, so nothing is minted; see ${ZOPS_LOG#"$ZOPS_HOME"/}"
  fi
  read -r concept prevv <<<"$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d.get("concept_doi") or "?", d.get("previous_version") or "unrecorded")' "$dry")"
  _z_ok "dry run clean: version $version beneath concept $concept, after $prev (version $prevv)"
  _z_i "the guard reports this deposit as not yet author-verified: that is expected before the gate,"
  _z_i "because typing MINT is the verification, and it is written into the metadata the guard then reads"
  _z_i "A DOI is a dated public disclosure. Typing MINT also records that you read the metadata."
  reason="$(zops_gate MINT)" || { _z_b "MINT declined; pushed and sealed without a new DOI is finished work"; return 10; }
  python3 - "$meta" "$dir/misty.gated.json" "$ZOPS_UTC" "$reason" <<'PY'
import json, sys
m = json.load(open(sys.argv[1], encoding="utf-8"))
m["author_verified"] = True
m["author_verified_by"] = f"typed MINT gate {sys.argv[3]}: {sys.argv[4]}"
json.dump(m, open(sys.argv[2], "w", encoding="utf-8"), indent=1, ensure_ascii=False)
PY
  res="$dir/mint.json"; rm -f "$res"
  misty newversion -c "$prev" -m "$dir/misty.gated.json" -f "${files[@]}" --output "$res" >>"$ZOPS_LOG" 2>&1 \
    || { tail -6 "$ZOPS_LOG" | sed 's/^/   /'; zops_die "misty newversion failed; nothing recorded back; see ${ZOPS_LOG#"$ZOPS_HOME"/}"; }
  doi="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("doi") or "")' "$res" 2>/dev/null || true)"
  [[ "$doi" =~ ^10\.5281/zenodo\.[0-9]{3,}$ ]] && [ "$doi" != "$prev" ] \
    || zops_die "misty reported success and no new version DOI; nothing recorded back and nothing invented" 3
  _z_ok "minted version $doi beneath concept $concept"
  ZOPS_DOI="$doi"
  _z_record_back "$doi" "doi: record $doi (version $version beneath $concept)" "$reason"
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

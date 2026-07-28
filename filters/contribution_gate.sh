#!/usr/bin/env bash
###############################################################################
#  contribution_gate.sh — the ecosystem's contribution filter.
#
#  Runs on EVERY contribution, human or AI — mistakes occur regardless of who
#  typed. Checks are rules-driven (filters/gate_rules.json) so policy evolves
#  without editing this script.
#
#    bash filters/contribution_gate.sh --all            # scan the whole tree
#    bash filters/contribution_gate.sh --diff <base>    # only files changed vs base ref
#
#  Exit 0 = PASS, 1 = FAIL (report printed with file:line). Read-only; safe.
#
#  Checks:
#   G1 forbidden credit patterns  (sole-authorship protection; generic patterns
#      in gate_rules.json + a PRIVATE, git-ignored forbidden.local.txt for names
#      that must never appear in public files — including this rules file)
#   G2 affiliation hygiene        (AyeAI only; forbidden variants)
#   G3 /tmp usage in scripts      (in-folder rule)
#   G4 secrets                    (tokens/keys committed by mistake)
#   G5 DOI verification           (every 10.5281/zenodo.N must be in
#                                  REGISTRY.json known_dois or the file's own
#                                  declared placeholder — anti-fabrication)
#   G6 unguarded irreversible ops (force-push/delete/publish without a typed
#                                  confirmation prompt in the same script)
#   G7 parse checks               (.json/.yml/.yaml/.cff/.html must parse)
#
#  © 1993-2026 Abhishek Choudhary. All rights reserved. GPL-3.0-or-later.
###############################################################################
set -euo pipefail
GATE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT="$(cd "$GATE_DIR/.." && pwd)"
RULES="$GATE_DIR/gate_rules.json"
LOCAL="$GATE_DIR/forbidden.local.txt"     # private, git-ignored, optional
REG="$ROOT/REGISTRY.json"

MODE="${1:---all}"; BASE="${2:-}"
cd "$ROOT"

# ---- collect target files ----
if [ "$MODE" = "--diff" ]; then
  [ -n "$BASE" ] || { echo "usage: contribution_gate.sh --diff <base-ref>"; exit 2; }
  mapfile -t FILES < <(git diff --name-only --diff-filter=ACMR "$BASE"...HEAD 2>/dev/null || true)
else
  mapfile -t FILES < <(find . -type f \
      -not -path "./.git/*" -not -path "./.seedwork/*" -not -name "*.ots" \
      -not -name "forbidden.local.txt" -not -path "./node_modules/*" | sed 's|^\./||')
fi
[ "${#FILES[@]}" -gt 0 ] || { echo "gate: no files to check"; exit 0; }

FAILS=0; WARNS=0
fail(){ echo "  FAIL [$1] $2"; FAILS=$((FAILS+1)); }
EXEMPT=0; EXEMPT_ANY=0
# A rule has to be able to name the thing it forbids. Exempting a whole FILE by
# name (the old behaviour) is too blunt and invisible; this exempts the LINE, for
# the NAMED rule, and says so in the output.
#   grep -q 'Independent Researcher' ...   # gate-allow: G2-affiliation
# The pragma may sit on the matching line or the line immediately above it.
gate_line_exempt(){
  local file="$1" lineno="$2" rule="$3" ctx
  ctx="$(sed -n "$((lineno>1?lineno-1:1)),${lineno}p" "$file" 2>/dev/null)"
  case "$ctx" in
    *"gate-allow: $rule"*|*"gate-allow:$rule"*) EXEMPT=$((EXEMPT+1)); return 0 ;;
    *"gate-allow: *"*)                          EXEMPT_ANY=$((EXEMPT_ANY+1)); return 0 ;;
  esac
  return 1
}
# every matching line, minus the exempted ones
gate_hits(){
  local file="$1" pat="$2" rule="$3" n out=""
  while IFS=: read -r n _; do
    [ -n "$n" ] || continue
    gate_line_exempt "$file" "$n" "$rule" || out="$out $n"
  done < <(grep -niE "$pat" "$file" 2>/dev/null)
  printf '%s' "${out# }"
}
warn(){ echo "  warn [$1] $2"; WARNS=$((WARNS+1)); }
is_text(){ case "$1" in *.png|*.jpg|*.jpeg|*.gif|*.webp|*.pdf|*.gz|*.tgz|*.zip|*.ots|*.woff*|*.ico) return 1;; *) return 0;; esac; }

echo "=== contribution gate · mode=$MODE · ${#FILES[@]} file(s) ==="

# ---- load rules once ----
eval "$(python3 - "$RULES" <<'PY'
import json,sys,shlex
r=json.load(open(sys.argv[1]))
def arr(name,key):
    print(name+"=("+" ".join(shlex.quote(x) for x in r.get(key,[]))+")")
arr("R_CREDITS","forbidden_credit_patterns")
arr("R_AFFIL","forbidden_affiliations")
arr("R_SECRETS","secret_patterns")
arr("R_IRREV","irreversible_ops")
print("R_GUARD="+shlex.quote(r.get("confirmation_guard","read -r -p")))
PY
)"

# known DOIs from registry (+ registry's own listing exempt)
KNOWN_DOIS="$(python3 -c "
import json;d=json.load(open('$REG'))
print(' '.join(k['doi'].split('zenodo.')[-1] for k in d.get('known_dois',[])))" 2>/dev/null || echo "")"

for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  is_text "$f" || continue

  # G1 forbidden credits (rules + private local list)
  if ! echo "$f" | grep -qE "contribution_gate|gate_rules|CONTRACT|AGENTS"; then
    for p in "${R_CREDITS[@]}"; do
      hits="$(gate_hits "$f" "$p" G1-credit)"
      if [ -n "$hits" ]; then
        fail "G1-credit" "$f: forbidden credit pattern ($p) at line(s)$hits"
      fi
    done
  fi
  if [ -f "$LOCAL" ]; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      if grep -qiF "$name" "$f" 2>/dev/null; then fail "G1-private" "$f contains a privately-forbidden reference"; fi
    done < "$LOCAL"
  fi

  # G2 affiliation
  for p in "${R_AFFIL[@]}"; do
    hits="$(gate_hits "$f" "$p" G2-affiliation)"
    if [ -n "$hits" ] && ! echo "$f" | grep -qE "contribution_gate|gate_rules|CONTRACT"; then
      fail "G2-affiliation" "$f: forbidden affiliation pattern ($p) at line(s)$hits"; fi
  done

  # G3 /tmp in scripts (gate excludes itself — it must be able to name what it forbids)
  case "$f" in filters/contribution_gate.sh|contribution_gate.sh) :;; *.sh|*.py|*.bash)
    if grep -nHE '(^|[^A-Za-z0-9_])/tmp(/|[^A-Za-z0-9_]|$)' "$f" | grep -v "never /tmp\|NEVER /tmp\|no /tmp" >/dev/null 2>&1; then
      fail "G3-tmp" "$f uses /tmp (in-folder rule: scratch under the run folder only)"; fi;;
  esac

  # G4 secrets
  for p in "${R_SECRETS[@]}"; do
    hits="$(gate_hits "$f" "$p" G4-secret)"
    if [ -n "$hits" ] && ! echo "$f" | grep -qE "contribution_gate|gate_rules"; then
      fail "G4-secret" "$f: secret pattern at line(s)$hits"; fi
  done

  # G5 DOI verification (skip the registry itself)
  if [ "$f" != "REGISTRY.json" ]; then
    for suff in $(grep -ohE '10\.5281/zenodo\.[0-9]+' "$f" 2>/dev/null | sed 's/.*zenodo\.//' | sort -u); do
      echo " $KNOWN_DOIS " | grep -q " $suff " || fail "G5-doi" "$f cites 10.5281/zenodo.$suff — not in REGISTRY.json known_dois (verify or register before merge)"
    done
  fi

  # G6 unguarded irreversible ops (scripts only)
  case "$f" in *.sh|*.bash)
    for op in "${R_IRREV[@]}"; do
      if grep -qE "$op" "$f" 2>/dev/null; then
        grep -q "$R_GUARD" "$f" || fail "G6-irreversible" "$f contains '$op' with no typed-confirmation guard"
      fi
    done;;
  esac

  # G7 parse checks
  case "$f" in
    *.json) python3 -c "import json;json.load(open('$f'))" 2>/dev/null || fail "G7-parse" "$f: invalid JSON";;
    *.yml|*.yaml|*.cff) python3 -c "import yaml;yaml.safe_load(open('$f'))" 2>/dev/null || fail "G7-parse" "$f: invalid YAML";;
    *.html) python3 - "$f" <<'PY' 2>/dev/null || fail "G7-parse" "$f: HTML parse error"
import sys,html.parser
class V(html.parser.HTMLParser):
    def error(self,m): raise ValueError(m)
V().feed(open(sys.argv[1],encoding='utf-8',errors='strict').read())
PY
    ;;
  esac
done

echo ""
if [ "$FAILS" -gt 0 ]; then
  [ "$EXEMPT" -gt 0 ] && echo "  $EXEMPT line(s) exempted by an explicit gate-allow pragma"
[ "$EXEMPT_ANY" -gt 0 ] && echo "  $EXEMPT_ANY line(s) exempted by a BLANKET gate-allow: * — review these"
echo "=== GATE: FAIL — $FAILS violation(s), $WARNS warning(s). Fix before merge. ==="
  exit 1
else
  [ "$EXEMPT" -gt 0 ] && echo "  $EXEMPT line(s) exempted by an explicit gate-allow pragma"
[ "$EXEMPT_ANY" -gt 0 ] && echo "  $EXEMPT_ANY line(s) exempted by a BLANKET gate-allow: * — review these"
echo "=== GATE: PASS — 0 violations, $WARNS warning(s). ==="
  exit 0
fi

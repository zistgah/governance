<!-- MASTER CONTRACT — canonical for ALL repos across project-ilm · hindawiai · zistgah · obonac · ayeai -->
# MASTER CONTRACT — the ecosystem's non-negotiables

_Every repo carries a thin overlay pointing HERE. Any session — human or AI — **maintains
contract and context**. Per-repo CONTRACT.md files may ADD constraints; they may never relax
these._

## Identity & authorship
1. **Sole author:** Abhishek Choudhary. Affiliation **AyeAI only** (never "Consulting",
   "Independent Researcher", or employer names). Name no co-author, co-founder, co-creator,
   or collaborator anywhere unless the author explicitly does; remove such credits on sight.
2. **Copyright:** `© 1993–2026 Abhishek Choudhary. All rights reserved`, except per category:
   content `CC-BY-SA-4.0` · software `GPL-3.0-or-later` · metadata `CC0-1.0` · novel methods
   proprietary (patents reserved; consulting via AyeAI). The specific category licence governs
   its files.

## Truth discipline
3. **No fabrication.** No invented DOIs, dates, citations, ORCIDs, numbers, or standard codes.
   Every DOI referenced must exist in `REGISTRY.json known_dois` or be verified before use.
4. **Verify by execution.** Nothing ships on assertion. Parse it, run it, test it; honest
   figures; flag gaps (Honest Deferral), never fake them.
5. **Read before write.** Never modify or rebuild existing work without reading the actual
   current source first. Exact-anchor patching; no whole-file regeneration of living files.

## Operational safety
6. **Gated irreversibility.** DOI mint, push, force-push, delete, issue-create, PR-open: each
   behind an explicit flag AND a typed confirmation. Dry-run by default.
7. **Filesystem:** stay inside the run folder; subfolders only; **never `/tmp`**, never
   navigate outside. Logs to `~/work/logs/`. Tokens/ORCID from the environment only — never
   in files, never in history.
8. **Provenance travels.** Every publish carries its `.ots`; `--push` always includes
   `provenance/`. One canonical metadata record (misty.json) drives DOI/citation outputs.
9. **Workflow:** fork → PR → merge for shared repos (no direct pushes to core repos with
   collaborators); every PR passes `filters/contribution_gate.sh` before merge.

## Process
10. **Scrum-sized increments.** Short, reviewable deliverables; open issues rather than
    completing everything; each accepted increment records the contributor's original intent.
11. **Multi-AI role split** (agreed protocol): ChatGPT — host/OS setup, ~/work hygiene,
    org-wide normalization (foundry). Claude — deep audits, kernel/spec correctness,
    verification-by-execution. Neither re-does the other's domain without cause.
12. **Repo classes** (declared in each repo's MANIFEST.yaml): `core` · `library` ·
    `archival` · `out-of-scope`. Conformance expectations scale by class; archival repos are
    preserved byte-faithfully (dedupe-as-documentation, never destructive).

---
_Reconstruct faithfully. Critique with evidence, not tone. Maintain contract and context._

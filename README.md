# governance — the ecosystem's centralized contracts, contexts & contribution gate

One master CONTRACT.md + CONTEXT.md for all orgs (project-ilm · hindawiai · zistgah ·
obonac · ayeai); a correlated REGISTRY.json (25 repos, verified DOIs); one canonical
AGENTS.md with thin per-repo overlays; and `filters/contribution_gate.sh` — the filter
every contribution passes, **human or AI**, because mistakes occur regardless of who typed.

Gate classes: G1 forbidden credits (+ private forbidden.local.txt, git-ignored) ·
G2 affiliation hygiene · G3 no-/tmp · G4 secrets · G5 DOI-vs-registry anti-fabrication ·
G6 unguarded irreversible ops · G7 parse checks. Proven by execution: clean fixture PASS,
8-class dirty fixture fully caught, zero false positives, and this repo passes its own gate.

Adopt in any repo: copy `overlays/CLAUDE.md`+`MANIFEST.yaml`, add the gate + workflow, done.
Registry upkeep: feed `known_dois` from `mistyx bib` records.json — one source of truth.

Standing instruction for any session: **"maintain contract and context."**

## Sprint backlog
- [ ] **gov#1 forbidden.local.txt** — author populates the private list on his machine (never committed).
- [ ] **gov#2 adopt-in-repo script** — one-shot overlay+gate installer for existing repos.
- [ ] **gov#3 registry autofill** — merge `mistyx bib` records.json into REGISTRY.json known_dois.

© 1993–2026 Abhishek Choudhary · AyeAI · GPL-3.0-or-later (code) · CC-BY-SA-4.0 (docs).

<!-- trademarks:begin -->
---
AyeAI®, AyeCNSe® and AyeAM® are registered trademarks of Abhishek Choudhary in India, used and claimed worldwide since
2019. The names of his products and projects are his trademarks; see [legal/TRADEMARKS.md](legal/TRADEMARKS.md). Code
licences in this repository grant copyright permissions only and no right in any mark.
© 1993–2026 Abhishek Choudhary. All rights reserved. AyeAI.
<!-- trademarks:end -->

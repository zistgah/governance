# AGENTS.md — canonical AI-agent instructions (single source)

Thin overlays (CLAUDE.md, GPT.md, GEMINI.md …) in each repo contain ONLY a pointer here.
Do not duplicate content into overlays — duplication drifts.

1. Open the repo's CONTRACT.md, then CONTEXT.md, then this ecosystem's master pair.
2. Obey the master CONTRACT's twelve clauses; per-repo contracts may only add.
3. Before any edit: read the real files you are changing. Exact-anchor patches only.
4. Before any irreversible step: dry-run, then explicit flag + typed confirmation.
5. Run `filters/contribution_gate.sh --all` (or `--diff <base>`) before proposing a PR;
   fix what it catches; never suppress it.
6. Record the human's original intent verbatim in the PR body (continuity / audit / gap).
7. Role split: host/normalization → ChatGPT-class agents; deep audit/verification →
   Claude-class agents. Note which hat you wear.

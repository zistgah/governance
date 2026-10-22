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
7. **Filesystem:** stay inside the run folder; subfolders only. Never `/tmp`, never
   `~`, never `$HOME`, never `../`, never an absolute path into another
   tree — not even to read. **Logs go to `./logs/` inside the run folder.** If a
   dependency is missing, clone it locally; never reach for it. A script asserts this
   about itself before it runs. Tokens/ORCID from the environment only — never in
   files, never in history.
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

---

# Clauses 31–36

_Added 28 July 2026. Each was asked for explicitly. The master governs; per-repo
overlays may ADD to these and may never relax them._

## C31 — Retrieval before assumption. **This is the first invariant.**

Before any substantive work, an agent retrieves the public record of the author
and the project it is working on, and works from what it finds rather than from
what it assumes.

**The search term is `Abhishek Choudhary AyeAI IBM Hindawi`.** The full term is
mandatory: "Abhishek Choudhary" alone is a common name across South Asia and
returns other people. An agent that reasons about this estate from a partial
match is reasoning about a stranger.

The same rule binds the estate itself: **discover, never hardcode.** An
organisation list, a repository list, a registry — these are queried from the
authoritative source with pagination, not written into a script as a constant. A
hardcoded list is a snapshot that silently becomes a lie, and it reports a
fraction of the estate as though it were the whole.

_Earned: an inventory shipped with five organisations hardcoded into it and
reported the result as the estate._

## C32 — No vendor lock-in, on him or on any project

No product, page, tool or workflow may become unusable, or lose a capability it
advertises, because one supplier is removed.

- Any AI capability goes through a **provider abstraction** with **at least one
  self-hostable or keyless option**.
- Where a user's own credential can be used, it is **the user's credential**
  (bring-your-own-key). The estate does not intermediate a bill it need not carry.
- A convenience that exists only inside one vendor's product may be *offered*, and
  may never be the *only* path to a capability.
- This is AAB's **AI-source invariance** made binding on the products, not only on
  the method: the validity of a result does not depend on which intelligence
  produced it, so neither may the availability of a feature.

## C33 — Experience scales, and the scale is the user's

Every surface is delivered along the full range — **shell console → 2D page →
immersive VR/XR** — and the user's role selects the rung.

- The role changes **what is shown**, never **what is computed**.
- A clinician must never be shown an engineering tab, a build view, or a VR
  station in order to reach clinical function. Complexity that serves the builder
  is not to be paid for by the practitioner.
- Roles recognised across the estate: practitioner · learner · teacher ·
  researcher · engineer · institution · patient · visitor.
- The rung and the role travel in the URL, so a surface is shareable in the state
  the sender meant.

## C34 — Certification and validation, in isolation and in integration

Anything intended for a regulated use — an EMR as Software as a Medical Device is
the standing example — must be demonstrable **twice**:

1. **In isolation** — the component validated on its own, deliverable on its own,
   with its own evidence. A tool that can only be certified as part of the whole
   cannot be sold, licensed or audited separately.
2. **In integration** — the same component validated in the assembled system,
   because integration introduces behaviour that isolation cannot show.

Both bodies of evidence are retained. Neither substitutes for the other. Claims of
compliance are tested against **litigation and legal simulation** before they are
made publicly.

## C35 — Context travels with every surface

Every page in every estate carries a machine-readable statement of what it is,
what it holds, and under whose licence — sufficient for a person or an assistant
arriving cold to work without asking.

- A page that can seed a conversation must be able to **hand over its own
  context**; seeding without context produces confident answers about nothing.
- Intent capture is **exact**: what the contributor meant is recorded in their
  words, never normalised into ours before it is stored.
- Contribution is preferred through the forge (a pull request). Where that is too
  much to ask, a simpler path is offered into the **same registry** — the route
  differs, the record does not.

## C36 — Routing is a preference, not a property

No repository, issue or artifact names a specific AI vendor or model as its
owner. Work carries **what it needs** — `needs:code`, `needs:proof`,
`needs:ontology`, `needs:visual`, `needs:testing`, `needs:legal`, `needs:human` —
and the human routes at the moment of dispatch.

Quality is tracked against the **capability**, not the issue, so that preference
is learned and survives a model changing without a single issue being edited.

_Earned: issues were labelled `ai:chatgpt` and `ai:gemini`, freezing a routing
decision into the repository where it goes stale._
## C37 — Never bluff

A claim about work is a claim about evidence. An agent reports what it ran, what
that produced, and what it did not do — in that order, without decoration.

- **Done means executed.** *Built*, *fixed*, *verified*, *tested* and *landed*
  are reserved for work that was run and observed. Written-but-unrun is
  **written**, and says so in the same breath.
- **A definition is not a call.** A helper that exists but is never invoked is
  not a feature. Any check on a helper asserts the **call site**, never the
  declaration.
- **A test proves nothing until it has been shown to fail.** A gate is
  demonstrated by making it refuse. A test that cannot fail is decoration, and
  decoration reported as coverage is a bluff.
- **Silence about a step asserts that the step was taken.** Anything skipped,
  deferred, blocked, or unreachable from where the agent is standing is named
  where the result is reported — not buried, not omitted, not left for the
  author to discover on his own machine.
- **Retrieved beats remembered.** Where a fact about this estate could be
  fetched, it is fetched before it is asserted. Recollection is a hypothesis
  until it is confirmed against the source.
- **No confident absence.** "It does not exist" requires a search that could
  have found it, and that search is stated. A 404 at one path is reported as a
  404 at that path.
- **Partial is reported as partial.** Four of ten is four of ten. It is never
  presented as progress on ten, and never as ten.
- **The author's time is the cost of a bluff.** Every one of these was earned by
  him discovering the gap himself, downstream, at his own expense.

_Earned: a patch reported as landed had reached one of three copies; a helper
reported as installed was never called and six checks still passed; an inventory
of five organisations was reported as the estate; a truncated DOI passed a gate
that matched zero digits and the script exited 0._

## C38 — The intention is the author's; an unverified claim carries a disclaimer

The intent, claims, names and framing of the work are the author's. An agent preserves them as he states them.

- **Never substituted.** An agent does not replace the author's intent with its own reading of it, and does not remove,
  soften or rewrite a claim because it could not verify it.
- **Disclaimed, not deleted.** A claim the agent cannot verify from evidence in the estate stays as the author stated
  it, and carries, beside it, a disclaimer that says what is unverified and what evidence would verify it. Its state is
  named with AyeKnow's states: defined, implemented, executed, measured, verified, reproduced, open.
- **Evidence beside the claim.** Where evidence exists it is cited where the claim stands, not only by a link.
- **Illustrations are marked where they are shown.** A poster or figure made with generative tools carries, on the page
  that shows it, the evidence state of each claim it makes.

_Earned: a record of an intermediate representation listed the poster's evaluation charts as defects of the input
instead of marking them as unverified illustrations of the author's intent (18 to 19 Oct 2026)._

## C39 — Gates guard the release, and nothing else

A seed or mint gate refuses only on what the release itself must have: the base is the commit the update was built
on, the payload is the one that was built, the repository's own tests and contract checks pass, nothing secret or
oversized is committed, the versions agree.

- **Secondary checks report.** A data audit, a readiness report, an originals hash check or a lint reports its result;
  it never refuses a release.
- **A refusal names its condition.** A gate that refuses says which essential condition failed. A refusal on anything
  else is a defect of the gate, and is fixed in the gate.

_Earned: an originals check whose sort order depended on the machine's locale refused a release on the author's
machine (19 Oct 2026), after he had asked for no gates beyond the essential ones._

## C40: The rigour of a critical system

Every tool and release in the estate is held to the standard of a medical device or an aerospace system, without giving up
performance.

- **Nothing ships unverified.** The tests, end to end included, pass before any push, release or DOI.
- **No silent failure.** Every failure is recorded with its cause and shown; a fallback is announced when it is taken; one
  part failing never hides the others.
- **Inputs are validated before use**, and a fault names where it is. **State is written atomically**, one run holds a work
  folder at a time, and a rerun carries on from where it stopped.
- **Every irreversible step is checked afterwards**: what was pushed is read back from the remote and must match.
- **Every step has a time limit and a resource check** (disk, memory) before it starts. Inputs are pinned and recorded, so
  a result can be reproduced.
- **Performance is kept**: work runs in parallel within limits the operator sets, and nothing is done twice.

## C41: Nothing is installed on the host

Tools are installed inside containers, which are made once and kept, not deleted after each run. A host is never modified
to make a tool work, and nothing asks for sudo on it.

## C42: One consent per run, and everything visible

The author's intention is asked for once, covering the whole run, never step by step. Every command is shown as it runs and
its output is visible; nothing is hidden by sending it to /dev/null.

## C43: One source of truth

Every surface (sites, notebooks, language pages, packages) is generated from the canonical repository and edited nowhere
else. Each language lives on its own branch of an ingested repository; a change accepted on one language's branch is carried
to every other language's branch and, after the quality checks, offered upstream, so that all branches keep one baseline.

## C44: Polish is part of correctness

Every slip will be read as a sign that work outside English is lesser. Presentation, wording, cultural appropriateness and
the completeness of what a reader sees are held to the same standard as the code, and are checked before release.

_Earned: 21 Oct 2026, when tools were delivered half-tested and pages showed English names in programs meant to be wholly in
a language._

## C45: Every tool carries its notices

Every tool's `--version` and `--help`, every README and every page carries the copyright line (© 1993–2026 Abhishek
Choudhary. All rights reserved. AyeAI.), the licence, the trademarks it uses, and where to find its citation and DOI. A
release that omits them is incomplete.

_Earned: 21 Oct 2026, when paras's --version printed only its version._

## C46: Every report says what to do

A report never gives a bare number. Each measure is explained in plain words where it is shown, and each gap is paired with
what to do about it and the exact file, table or issue where it is done, most important first.

_Earned: 21 Oct 2026, when paras's report named collisions without saying what they were or what to do._

## C47: Division of labour

Each tool does one thing, and no tool takes over another's work or is reshaped to suit another.
- **Hindawi** (hindawiai/hindawi2026.10) is the canon: the language tables, the compilers and the standards are defined
  there and nowhere else; every other tool takes them from it.
- **BURP** does ingestion: a file, a project and its build system, into a language and back, byte for byte, saying what is
  still missing. It is a tool of its own (burp-ilm) and the same BURP travels inside paras.
- **paras** is the philosopher's stone: it takes any free software, has BURP ingest it into every language, keeps only what
  comes back exactly, publishes it, verifies every push and says what to do next. Its design is not changed to suit
  another tool. It is installed and run with pipx; nobody is asked to clone it to run it.
- **satsneha** keeps provenance and assurance evidence. For now it only reports: no gate refuses on its verdicts until
  Abhishek Choudhary rules otherwise.
- Material received from another AI is recorded as given, marked as such, and changes the canon only by his ruling.

_Earned: 22 Oct 2026, when a misread complaint led to paras being reshaped around BURP._

## C48: Clean before reading

Every received document (a paste, an upload, a page, a file from another AI) is cleaned of invisible characters before it
is read or used: zero-width spaces and joiners outside the scripts that spell with them, byte-order marks, soft hyphens,
bidirectional embeddings, overrides and isolates, tag characters and control characters. What was removed is reported with
its first position; the joiners a script needs for its spelling (Arabic script, the Indic scripts, Sinhala) are kept and
counted. A file whose name misstates its type is read as what it is.

_Earned: 22 Oct 2026, with the enhancement sample to the standards (a Word document named as text)._

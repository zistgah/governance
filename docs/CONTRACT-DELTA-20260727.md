# Contract and Context Delta — 27 July 2026

Each clause below exists because something failed. The `broken_on` column is the point:
a contract that does not carry its own failure history is a wish list. Fold these into
the master `CONTRACT.md` and `ops/contract.json`, and into the context seeder.

---

## A. New invariants for the contract

| ID | Invariant | broken_on |
|---|---|---|
| **C8-no-upward-access** | A script never reads or writes above its invocation directory. No `../`, no `~`, no filesystem globbing across roots. A missing dependency is **cloned locally**, never hunted for. | `seed_article.sh` searched `../`, `~/work/*` and `/shared/estate/*` for zops. Rejected on protocol before it was ever run |
| **C9-wrapper-tool-lockstep** | Any wrapper that invokes a tool asserts in preflight that every flag it passes is accepted by that tool. | `harvest.py` renamed `--cap`; `seed_pajr.sh` kept passing it. argparse ambiguity aborted the run after the banner |
| **C10-no-dead-stop** | A script never terminates because a dependency is absent when it could obtain it, or proceed in a labelled degraded mode. Blocking a human on something recoverable is a defect. | `seed_article.sh` stopped with "run apply_zops.sh first" in a directory deliberately kept away from the tokens |
| **C11-assume-and-record** | Never block on a human for a decision that can be safely assumed. Assume it, write it to `ASSUMPTIONS.md` with why it is safe and what correcting it costs, and let the typed gate carry the human intent. | Two turns lost waiting on "Research Kundali" and a repository name, neither of which gated anything irreversible |
| **C12-create-before-reuse** | Any clone-or-reuse helper must have a create path, or its caller must create the remote under its own typed assertion. | `zops_repo` aborted on `project-ilm/vgc-notes` — clone-or-reuse with no create path |
| **C13-native-script** | A named property carries its native script alongside the transliteration, in the title, the README and the deposit metadata. | `marham-bar-zistgah` shipped without مرهم بر زیستگاه, against the convention already set by زیستگاه, آب, فضا |
| **C14-use-the-machine** | Long-running work is `nice`d and sized to the host: I/O concurrency for network stages, cores−1 for CPU stages. Defaults that idle a 12-core machine are defects. | Harvest ran 8 workers for both phases; the network stage was throttled and the reduce stage under-used simultaneously |
| **C15-scope-admission** | Before a discovered source is ingested wholesale, it is sampled and admitted on evidence. | 1,900 of 5,363 indexed posts came from unrelated blogs reached via platform profile links, putting an animation-art blog into a clinical corpus |
| **C16-third-party-rules** | For material that is not ours: index rather than copy; remove identifiers while still intact; a proof per item, not per corpus; attribution captured or explicitly `UNATTRIBUTED`; never mint on anyone's behalf. | Established in the PaJR work, generalised in the مرهم charter |
| **C18-patch-every-copy** | A tool fix patches every copy reachable inside the invocation directory, and the wiring is asserted, not assumed. A helper installed but never called is worse than no fix, because the checks pass. | `patch_zops.sh` patched `./governance/ops/zops.sh` while the seeds sourced `./.zops/ops/zops.sh`; the call site regex was line-anchored and silently missed `_z_b "PUSH"; git push` |
| **C19-no-handback** | A script that has done the work does not print instructions for the human to finish it. If it can seal, it seals, asking intent once. | `patch_zops.sh` printed a three-line `cp`-and-`zops_push` recipe |
| **C20-contracts-live-in-governance** | Contract and context changes land in `zistgah/governance` — `CONTRACT.md`, `CONTEXT.md`, `ops/contract.json`, `docs/` — and spread from there. Nowhere else is canonical. | "contracts go somewhere??? retrieve where" |
| **C21-org-by-meaning** | A repository's org follows what it is, not where the last one went. Habitat layers live in `zistgah`; tooling lives in `project-ilm`. | مرهم بر زیستگاه was seeded under `project-ilm`; it is a habitat layer and belongs in `zistgah/marham` |
| **C23-probe-tools-live** | Optional-tool detection probes the live environment when preflight recorded no explicit result, rather than defaulting to absent. | `ots` v0.7.2 was installed and reported absent, because `zops_preflight` was called with no tool list and `zops_have` trusted the unset flag |
| **C24-call-tools-as-documented** | A tool is invoked through its documented machine interface, never by scraping its human output or inventing flags. | `zops_mint` scraped stderr and tee'd to a nonexistent log path; misty documents JSON-on-stdout via `--output` and exit codes 3/4/5 |
| **C25-empty-remote** | Create-or-clone handles a remote that exists but has no commits, not only one that is absent. | `gh repo create` makes an empty repo; `git clone` of it fails "Needed a single revision" and the seed aborted mid-flight, leaving a stranded local clone |
| **C22-tool-surface-checked** | A script asserts that every tool function it calls exists before calling it. | Every seed script called `zops_mint`, which zops never defined |
| **C17-test-the-real-path** | A self-test that exercises only a fixture path does not certify the invocation path. Every code path a real run takes has an assertion. | `--self-test` passed while a real run could not start |

## B. Context seeder additions

The seeder must carry these so a new conversation starts from fact rather than from
re-derivation. Every item below cost a correction at least once.

**Identity and affiliation.** Affiliation is `AyeAI`, never "Independent Researcher".
ORCID `0009-0002-0684-8320`. Copyright line `© 1993–2026 Abhishek Choudhary. All rights
reserved.` on every artefact. Verified public background: Founder AyeAI; Ex-IBM Senior
Architect (Power Hypervisor IO virtualization Power7–9, founding architect of PowerAI /
Watson ML Accelerator); Ex-HP platform architect SDN; Hindawi Programming System, first
released 15 August 2004, built on the Romenagri transliteration and APCISR
character-composing inventions; internationally awarded telemedicine (HMSEI / RDK /
Dr Rho), TARA, ANGEL. Positioning is always polite.

**Estate.** Root `/shared/estate`. Two orgs: `zistgah` and `project-ilm`. Only he pushes
and mints; an AI writes the script, the script runs under his typed assertion on his
machine. Tokens are referenced by path, never by value, and third-party work happens in
a session that never sees them.

**Named entities.** No entity is named in any public artefact without his authorisation,
and he is prompted for fair-use proof even when he authorises: NIMHANS, IBM, HP/HPE,
KPIT, Cummins, Vyas Labs, Indicybers, Annamalai University, TWISHA, Interglial
Healthcare, and the third-party PaJR properties. No religiously significant terms in
public artefacts.

**Naming.** Native script alongside transliteration: زیستگاه, آب, فضا, مرهم بر زیستگاه.
Forbidden substitutions: ILM is not a "translation system"; SPR is not "Reality"; the
AyeAI triad is a triad, not a loop or a pipeline.

**Working style.** Terse, code-mixed input; profanity is emphasis, not hostility;
replies in RP English. No documents where code was asked for. No checklists — printing
"run this next" is the failure, not the fix. A gap is reported, never filled. Verify by
execution, and mutation-test the check itself: a check that never fails proves nothing.
Fun is a requirement, not a garnish — easter eggs and delight belong in everything.

## C. Open contract questions

1. **C7-no-fabrication remains advisory.** It is the only invariant with no mechanical
   test, and it is the one that matters most. The nearest thing to a test found so far is
   a per-repository check that every claim carrying a status label has one — the `Q7`
   pattern from qedler. Worth generalising.
2. **C5 boundary.** The first reseal in any repository archives a proofless manifest, so
   C5 fails permanently thereafter. C3 solves this class with a derived boundary; C5
   needs the same, or `candor_reseal` must stamp before archiving.
3. **Deletion and provenance.** When indexed third-party material disappears, the index
   holds a proof that something existed which can no longer be read. Keep or drop is a
   policy decision that has not been made.

---

© 1993–2026 Abhishek Choudhary. All rights reserved.

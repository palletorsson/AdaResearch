# Project memory

Open [Project memory](http://localhost:3003/project-memory) in the existing Ada web app. The workspace connects the whole project, sequences, halls and source evidence. It reads the authored storyboards live and keeps editable working memory alongside them.

## Use it

1. Start at **Project** to read or edit the working brief and its reason.
2. Choose a **sequence**, then a **hall**. Keep its arc in view while inspecting the actual storyboard, supplied material and earlier museum photograph.
3. Save a **working note**: what matters, why, and the open question. This does not rewrite the storyboard, manuscript or museum.
4. **Add a finding** when a source or encounter changes what we understand. Name the source and the consequence for the sequence and project. It begins as a proposal.
5. **Review** the finding with a reason. Acceptance is an editorial decision, not a certificate of truth. Source freshness is shown separately.
6. **Export a handoff** at the level you need. Give that text to the next AI reader; it carries orientation, findings, uncertainty and source pointers.

The gaps view exposes recorded questions, missing selections and source/version discrepancies. It does not rate the artistic value of a room. Source refresh compares fingerprints; it does not run Godot. A changed source means the associated evidence needs reading again. Recording a new review requires reading the sources and supplying a note; accepting a finding alone never updates its old fingerprints.

## Keep the route open to change

The outline is a view of the current proposed teaching route, not a prescription for every hall. Read whole compact summaries together, including their open choices and deferred material. Expand a hall for close work while retaining its neighbours. Expanding another sequence is for comparison; it does not select a different destination for the current note or handoff.

The project purpose and sequence arc provide orientation, not a test every work must pass. The learning fields describe the current selection and can be incomplete. A hall can chiefly support reflection, composition or an encounter without adding new syntax. The tutorial summary does not stand in for `final.md`, the critical text or the wider museum.

Use the free-text note, reason and open question to reconsider selection, order or the form of a lesson. Record an alternative as a proposal with its reason. These working choices can evolve without silently rewriting the authored route; reconcile the source documents deliberately when a change is agreed. Avoid completion scores and fixed categories that make a provisional lineage look inevitable.

## What is authoritative

| Material | Location | Responsibility |
| --- | --- | --- |
| Shared teaching agreement | `doc/book/course/storyboards/BRIEF.md` | Existing author agreement; linked context. |
| Full and short teaching proposals | `doc/book/course/storyboards/{opening,early,growth,later}.json` | Current authored storyboards, read live. |
| Working memory | `doc/book/memory/state.json` | Editable core, notes, scoped findings and review journal. |
| Previous memory revisions | `doc/book/memory/history/` | Full prior state, preserved before replacement. |
| Image/source metadata | `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json` | Earlier generated route; discrepancies must be surfaced. |
| Implementation | Referenced source files | Evidence for scoped technical claims. |

The working brief is a compact operational memory, not a silent replacement for the full teaching agreement. If a decision changes, reconcile the affected authored documents deliberately. No write action in this tool changes Godot files, map order, `tutorial.md` or `final.md`.

## AI interface

Use `tools/project_memory.py` from the repository root. It accepts a JSON object on standard input and returns JSON. `model` returns the hierarchy, current notes, findings and source freshness. `packet` returns a compact handoff. `source` reads an allowed text source with its hash. `mutate` requires the revision just read. The full request/response contract is in [CONTRACT.md](CONTRACT.md).

PowerShell examples:

```powershell
'{}' | python tools/project_memory.py --root . model
'{"scope":"project"}' | python tools/project_memory.py --root . packet
'{"scope":"sequence:primitives"}' | python tools/project_memory.py --root . packet
'{"scope":"map:Point_Line_Grid"}' | python tools/project_memory.py --root . packet
'{"path":"commons/primitives/line/grid_lines.gd"}' | python tools/project_memory.py --root . source
```

For parallel reading, give workers different scopes and the same initial revision. Each returns a proposed finding with evidence and effects beyond its hall. A coordinator rereads the current state and integrates reports; a stale revision is rejected rather than overwriting another reader. Conflicting evidence remains visible. Routine evidence integration need not ask Palle to approve every small step; changes to his intended teaching selection still belong in the agreed storyboard process.

Read [AI.md](AI.md) at resumption. The tool provides storage, retrieval, source freshness and handoff generation. It does not automatically dispatch AI jobs, discover every conceptual dependency or evaluate the entire curriculum.

## Run and maintain

The interface and API live in the sibling `ada_encyclopedia` project, using its configured `ADA_RESEARCH_PATH`. Run its normal development server on port 3003; the new API is restricted to localhost. It invokes the fixed Python backend without shell interpolation. Python must be on PATH; `ADA_MEMORY_PYTHON` can name a different installed Python executable. No database, API key, external service or new package is needed for the memory store.

Backend tests use temporary fixture projects. They must not modify this live memory. Atomic replacement, exclusive writing, revision guards and prior snapshots protect against conflicting edits. A save error preserves the UI draft; review the latest saved text before retrying. Saved memory survives browser reloads. Unsaved drafts only live in the open page.

To restore a previous state, inspect a file in `history/`, then deliberately reapply the desired content against the current revision. Do not replace the live file blindly while another reader may be editing it.

## Verified first release — 4 October 2026

- 21 backend tests passed in isolated fixture projects, covering conflicting writers, stale revisions, history, interrupted replacement, source freshness/recheck, path boundaries and packet contents.
- The live browser saved and reloaded a project note and a proposed hall question. Source inspection, navigation, packet copy and a downloaded Markdown packet were checked; the download exactly matched the API export.
- The new UI, API and header pass their focused TypeScript check. A whole-site typecheck still reports pre-existing errors elsewhere; the initial output is retained in `typecheck-initial.log`.
- The thirteen inputs from the earlier source pilot still match their recorded hashes. This release did not change the museum scripts, authored hall summaries or teaching texts.

Run the backend checks from AdaResearch_46 with `python -m unittest discover -s tests -p test_project_memory.py -v`. In the sibling web repository, run `node node_modules/typescript/bin/tsc --project tests/project-memory/tsconfig.json --pretty false`.

The three `*-handoff-example.md` files are frozen examples from revision 3. Use **AI handoff** or the CLI for current context. The full-project packet keeps sequence arcs, decisions, findings, explicit open choices and source pointers; detailed hall review notes are grouped by sequence and expanded in the local packet.

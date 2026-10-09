# A working memory for the Endless Museum

4 October 2026. [Open Project memory](http://localhost:3003/project-memory).

![Live workspace with the Grid hall's earlier museum image and saved working note](workspace.png)

The tested method now has a repository-backed interface. Start with the shared direction, descend through a sequence to a hall, inspect its summary and sources, then record what the local finding changes for the sequence and project. Museum images are attributed earlier captures, not new runtime observations.

The workspace reads all 25 sequences and 204 hall storyboards. It saves notes, reasons, open questions and findings separately from authored teaching documents. Findings begin as proposals. Accepting one retains its source fingerprints; changed or missing sources remain visible. Saves require the current revision and preserve the preceding state, so concurrent work cannot silently overwrite another reader.

Use **AI handoff** to copy or download context at the current scale. The global packet preserves explicit open choices and points to detailed local reviews. The interface can support parallel readers; dispatching and synthesizing their work remain deliberate tasks.

## What was exercised

| Check | Result |
| --- | --- |
| Isolated backend checks | 21 passed; no skipped tests. |
| Focused UI/API/header TypeScript check | Passed. |
| Live project note and proposed Grid question | Saved, reloaded and retained at revision 3. |
| Scoped navigation, source reader, handoff copy | Exercised in the browser. |
| Handoff download | Saved Markdown exactly matches the exported hall packet. |
| Stale write / cross-origin write | Rejected with 409 / 403. |
| Unsafe or private source path | Rejected. |
| Earlier pilot's thirteen selected inputs | All hashes unchanged. |

The whole web project has pre-existing TypeScript errors outside this addition; the initial output is saved in `doc/book/memory/typecheck-initial.log`. The browser automation timed out waiting for a download event, but the resulting file was found and its complete contents matched the API packet.

## Boundaries

Seven starting findings comprise five accepted, scoped source observations and two open proposals/questions. They do not certify all halls. Fingerprints detect changed bytes, not semantic truth. No Godot/headset or learner test was performed for this memory-tool release. The workspace does not rewrite museum logic, map order, `tutorial.md`, `final.md` or authored storyboards.

Read [the usage guide](../../memory/README.md) and [the resume instructions](../../memory/AI.md). The backend is `tools/project_memory.py`; the interface and API are in the sibling `ada_encyclopedia` repository at `/project-memory` and `/api/project-memory`.

## Continuous outline — same-day revision

Palle asked to see whole sequences and to keep the freedom to change them. The workspace now opens sequences into complete compact hall summaries. The selected hall's editor opens inside that outline. Project purpose, sequence arc and the selected save/handoff destination remain available above it. A focused view remains available for sustained local work.

Disclosure and selection are separate: comparing another sequence does not retarget the current edit. Closing the selected hall's parent sequence preserves its editor separately, with a way to reveal it in the outline. Optional learning fields and distinct final/critical source links remain accessible without treating every hall as a programming lesson. Alternative selections and orders belong in free-text working notes and proposals until deliberately reconciled with the authored route.

Browser checks confirmed an unsaved Grid note survives expanding Transformation, collapsing/reopening Primitives, visiting Melencolia and returning; the temporary test text was then removed without saving. The selected Grid handoff retained its ancestor arc and excluded that unsaved text. Melencolia's full scale uncertainty remained visible. A direct hall-link reload restored its outline. The focused TypeScript check passed after the final navigation fix. Back/Forward handling was inspected in source; the browser's own history buttons were not exercised in this pass.

The author's freedom-to-change instruction was saved through the project form, then retained as an accepted author decision at memory revision 5. It has no source fingerprint and claims no runtime verification. The backend and API were unchanged. The bounded file comparison found the authored storyboard inputs and selected scripts unchanged; a concurrent addition of `trace_sampling_monitor` to `Point_Trace/map_data.json` appeared during the pass and was left intact. This interface work did not make that map edit.

![The continuous Primitives outline](outline.png)

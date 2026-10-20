# Post-crisis: what the record can support

12 October 2026 · Endless Museum · Source and reading reconciliation

The eight-hall progression holds: distinguish, arrange, retain disagreement, locate a claim, inspect contributions, change connections, assemble a body, meet the change again. The strongest ending is already built. A released position or connection in Assembly becomes the amber body and ledger in Synthesis. Earlier work with points, local coordinates, arrays, graphs and forces supplies the operations; the final arc asks who chose their permissions and what their records leave available for revision.

The supplied review identified useful additions to two reflections. Checking the tutorials exposed a larger mismatch: Assembly still proposed its existing body editor as future work, while Synthesis taught the ledger's inactive illustrative branch. Those passages now describe the actual encounter. No engine script, artifact placement, hall order or numeric quality score changed.

## Applied changes

| Hall | Change | Read |
| --- | --- | --- |
| Rhizome Network | The reflection now names the two trees produced by one-link growth from two unlinked seeds. It distinguishes a counted degree from a claim about influence. | [Current reflection](rhizome-final.html) |
| Assembly Laboratory | The tutorial now includes the existing gold body, local joint positions, both editable endpoints of one connection, and the saved-pose handoff. The separate physical bodies do not supply that record. | [Current tutorial](assembly-tutorial.html) |
| Post-crisis Synthesis | The reflection distinguishes keeping an alteration from being accountable for its effects. The tutorial now reads the real pose, explains the two counters and local persistence, and offers predictions the visitor can check. | [Current reflection](synthesis-final.html) · [Current tutorial](synthesis-tutorial.html) |
| Review register | Collective Knowledge, Rhizome, Assembly and Synthesis notes now acknowledge their implemented controls and distinguish them from further work. All numeric ratings remain historical and unchanged. | [Exact changes](changes.html) |

## Decisions on the seven candidates

| Candidate | Decision |
| --- | --- |
| One link gives two trees; three links join them and create circuits. | Added with the initial conditions stated. All points must be present. The third point joins both seeds under the three-link rule; later arrivals create circuits. |
| Degree is countable; influence needs another question. | Added. The readout measures active adjacency, not social authority. |
| Survival, repair and undo are different. | Already covered: the reflection asks what survives, describes restoration, then distinguishes inventing a connection. No extra sentence needed. |
| Seeded replay makes the arrangement available again. | Kept in the tutorial and technical account, where it supports the controlled comparison. No repeated mechanism sentence added to the reflection. |
| A crossing is not necessarily a junction. | Already developed through the cave's upper crossing and the relation between centre lines and passage widths. |
| Accountability connects a decision, evidence of effects and someone able to revisit it. | Added to Synthesis. The current record supports comparing arrangements, but does not identify who was helped or who answers for the decision. |
| Displaying a cost does not absolve a choice. | Not added. This placement does not measure cost, and the more specific addition already establishes the missing relation between a record and accountability. |

## Source receipts

- `rhizome_grower.gd`: two initial nodes are added without an edge. `_grow_shoot()` and `_rewire()` choose only earlier neighbours. `LINKS` changes adjacency while retaining positions; `CUT` toggles an active flag; `_refresh_graph()` counts components and degrees. `REPLAY` reuses samples. The map selects interactive mode and seed 47.
- `peer_production_tool.gd`: the readout separates SOURCES, EVER, ADDITIONS, PARTICIPATIONS and REVISIONS. A disputed piece can already be revised without adding another piece. One previous version remains in memory; this is not a durable collaborative history.
- `MolecularDesigner.gd` and its map: `body_workshop:true` enables `AssemblyBodyStudy.gd`; the catalogue's configured periods are eight and eighteen seconds. The gold workshop is distinct from the automatic catalogue, physical ragdoll and furniture.
- `AssemblyBodyStudy.gd`: a joint release exceeding 0.01 m from pickup, or a valid changed connection release, increments edits and calls the record helper. Positions and connectivity are separate data. Only one connection's two endpoints are editable.
- `AssemblyPoseRecord.gd`: validated original/current coordinates and edges are cached and written to a temporary file before replacement of `user://ada_research/assembly_pose.json`. Successful writes are marked `saved locally`; a failed write leaves the cache available for this session. The schema does not provide visitor identity or a gesture path.
- `accountability_ledger.gd` and the Synthesis map: `visitor_record:true` selects `_refresh_record()` and disables timed illustrative entries. `assembly_return.gd` reconstructs the same record. No missing visitor change is invented on a direct start.
- `commons/data/museum/em_plan.json`: the eight maps occupy plan entries 182–189 in the order given by `commons/maps/sequences/postfoundationscrisis.json`.

The existing technical pages already document these controls, durations and persistence rules. The old “leaving is not yet saving” and illustrative-ledger passages would now be false in this placement. They were not restored. The remaining six reflections were read and left unchanged. Additional placed artifacts do not automatically need another tutorial or reflective section.

## What this pass establishes

This was a source and text check, not a fresh ghost-student runtime pass. The shown tutorial snippets were compared with the live scripts. JSON, source links, hall order, unchanged code/placements and retained numeric scores were checked; exact diffs and source hashes accompany this report. Previous dated runtime evidence remains previous evidence. No new VR reach, readability, performance or learner-success claim is made.

The next instructional pass still needs complete runnable student code and real assertions. It should carry the existing point, graph and record through these halls, with one independent prediction per lesson. The corrected Assembly → Synthesis handoff is the clearest test: move a joint, reroute a relation without moving joints, save, reload and reconstruct the same data in the next hall. A source excerpt alone does not pass that test.

The numeric scores were not raised because an implemented feature is not evidence of teaching quality or headset readability. The older Foundations status in the score file is a dated review; its later reconstruction evidence is available in the [12 October ghost-student report](../2026-10-11-foundations-reconstruction/ghost.html). This pass updates only the four post-crisis source notes and their review metadata.

The pasted review's historical sentence count and forum posting were not independently audited. No forum message was sent, and the other suggested sequences were not changed.

## Files and evidence

- [Before/after comparison](changes.html)
- [Validation receipt](validation.json)
- [Source hashes before this pass](before-hashes.json)
- [Source register after this pass](source-register.json)

The `before/` and `after/` folders retain the edited sources so this reading pass can be reviewed independently of later work.

# A focused manuscript for every room

2026-09-08. All **190 rooms across 24 sequences** now have `final.md` and an explicit teaching core. **140 chapters are new; 50 existing chapters are retained.** Existing text received narrow continuity or factual corrections in 11 rooms; 39 remain byte-for-byte identical to the initial census. No artifact placements or room map files were changed in this writing pass.

[Follow Museum Progress](http://localhost:3003/museum-progress) · [Read the complete manuscript snapshot](manuscript.md) · [Inspect the checks](verification.json) · [Review the retained-text corrections](retained-text-corrections.diff)

## The curatorial rule

Choose the encounter that carries the room's question, then give primacy to the objects needed for that encounter. One or two is the starting point, and every new chapter uses one or two. Existing developed comparisons can keep more: Point One has four, Melencolia four, and the comparative leg family seven. Across the museum, 180 rooms use one or two primary artifacts and ten retain larger comparisons.

A secondary role leaves the object and its existing prose available. It does not delete either. The existing role notes, spatial positions, groups and all non-spine rulings were preserved. The derived spine order was refreshed from the authored roles so it carries the same teaching decisions.

The prose starts from a question and a particular action or observation, makes the operation intelligible, identifies a specific limit, and offers a variation or a handoff. Existing substantial chapters retain their broader comparisons. The new chapters deliberately distinguish working calculations, static diagrams, authored animations and proposed interactions.

## What has been checked

- All 190 map files match their pre-pass SHA-256 hashes.
- Every primary is placed and tagged. Two retained comparisons use stacked markers for shared prose; these are recorded in the verification file.
- All 140 new chapters have inspected source cards; 845 distinct inspected local files still match their source hashes.
- The unchanged repository wall-text checker reports **0 failures** over the new chapters. Its 166 advisory notes concern rhythm, openings and related phrasing; no complete sentence of nine or more words is duplicated across the new chapters. See [the full output](wall-voice.txt).
- The artifact-tag check inspected 191 manuscript files, including one outside the current spine: **0 stale tags**, 13 grammar fixtures passing and 13 Python/TypeScript parser fixtures agreeing.
- The live progress page displays **190/190 room texts, 0 baselines verified** and Point One's four primary objects. Read-and-write links use the live room files.

The new chapters contain 57,278 words by the wall-text check, with 385–460 words per chapter. Source inspection is not a museum walk or a learner test. No new room was marked as a verified baseline.

## What to improve next

There are 34 specifically reviewed development proposals in [development_gaps.json](development_gaps.json). Each includes a room link, inspected source hashes, one next action and a question about reuse. Those actions now lead the corresponding room's open questions on Museum Progress. The complete source cards retain additional cautions beyond this shortlist.

Use the first written core as the unit of work: read it, perform or inspect it in the museum, record the first consequential mismatch, and make one paired change to the room and prose. Keep the intended learning question available when the current object cannot yet answer it.

| Type of next work | Example | What may transfer |
|---|---|---|
| Recover a lost relationship | Random Remove's local grid host; inspect Git before restoring | The historical restoration method used for Melencolia, with separate evidence for each map |
| Repair a control's connection | QFEP Sandbox; sculptor ERASE | Trace input to a named local receiver and compare its actual output |
| Make a comparison valid | Perlin versus Simplex | Hold other settings and visible scales steady while changing the intended mechanism |
| Supply the missing computation | Memory, GAN, graph metrics | Show the data and update behind a readout that currently illustrates a concept |
| Test a spatial condition | Sky Stairs, cycling cube, cave approaches | Verify the route and support a body can actually use |
| Restore or build the missing encounter | Pinned cloth, continuous cellular rules | Check history first, then build only what is absent |

Some titles and intended lessons remain ahead of their present objects: the cellular-automata rooms, cloth, several learning diagrams and incomplete graph solvers are explicit examples. The first manuscript names those limits rather than claiming that a finished interaction exists. Existing text outside the narrowly corrected passages has not received a fresh exhaustive behaviour audit in this pass. These are starting points for the next development cycle, not reasons to discard the existing collection.

## Sequence coverage

| Sequence | Rooms | New texts | Existing retained |
|---|---:|---:|---:|
| [Primitives: Points Build Worlds](http://localhost:3003/museum-progress?sequence=primitives) | 10 | 0 | 10 |
| [Transformation: What Stays the Same When Everything Changes](http://localhost:3003/museum-progress?sequence=transformation) | 8 | 0 | 8 |
| [Array Tutorial Sequence](http://localhost:3003/museum-progress?sequence=array_tutorial) | 3 | 3 | 0 |
| [Color and Composition](http://localhost:3003/museum-progress?sequence=color) | 4 | 4 | 0 |
| [Tiling and Symmetry](http://localhost:3003/museum-progress?sequence=tiling) | 4 | 4 | 0 |
| [Change: Rate, Accumulation, and Flow](http://localhost:3003/museum-progress?sequence=change) | 4 | 4 | 0 |
| [Vectors & Forces: From Direction to Dynamics](http://localhost:3003/museum-progress?sequence=forces) | 12 | 3 | 9 |
| [Form-Finding: Matter Solves for Its Own Shape](http://localhost:3003/museum-progress?sequence=formfinding) | 6 | 1 | 5 |
| [Wavefunctions: Everything Oscillates](http://localhost:3003/museum-progress?sequence=wavefunctions) | 12 | 12 | 0 |
| [Randomness: Freedom from Pattern](http://localhost:3003/museum-progress?sequence=randomness) | 14 | 14 | 0 |
| [Noise: Entropy with Memory](http://localhost:3003/museum-progress?sequence=noise) | 9 | 9 | 0 |
| [Cellular Automata: Local Rules, Global Patterns](http://localhost:3003/museum-progress?sequence=cellularautomata) | 8 | 8 | 0 |
| [Fractals: Infinite Within Finite](http://localhost:3003/museum-progress?sequence=fractals) | 10 | 6 | 4 |
| [L-Systems: Rules Grow Structure](http://localhost:3003/museum-progress?sequence=lsystems) | 7 | 7 | 0 |
| [Procedural Generation: Rules Build Worlds](http://localhost:3003/museum-progress?sequence=proceduralgeneration) | 7 | 7 | 0 |
| [Soft Bodies & Morphogenesis: Matter That Finds Its Shape](http://localhost:3003/museum-progress?sequence=softbodies) | 9 | 5 | 4 |
| [Isosurfaces: Implicit to Explicit](http://localhost:3003/museum-progress?sequence=isosurfaces) | 13 | 13 | 0 |
| [Boolean Surfaces: CSG as Composition](http://localhost:3003/museum-progress?sequence=boolean_surfaces) | 3 | 0 | 3 |
| [Swarm Intelligence: No Leader, Yet Coordinated](http://localhost:3003/museum-progress?sequence=swarmintelligence) | 7 | 7 | 0 |
| [Machine Learning: Algorithms That Learn](http://localhost:3003/museum-progress?sequence=machinelearning) | 8 | 8 | 0 |
| [Graph Theory: Connections Define Structure](http://localhost:3003/museum-progress?sequence=graphtheory) | 8 | 8 | 0 |
| [Foundations Crisis: The Limits of Formalization](http://localhost:3003/museum-progress?sequence=foundationscrisis) | 8 | 1 | 7 |
| [QFEP Laboratory: The Formula Made Interactive](http://localhost:3003/museum-progress?sequence=qfeplaboratory) | 8 | 8 | 0 |
| [Post-Crisis: Applied Limits](http://localhost:3003/museum-progress?sequence=postfoundationscrisis) | 8 | 8 | 0 |

The [manifest](manuscript_manifest.json) records original and installed text hashes, map hashes, core selections and source-card locations. The earlier ten-action iteration is preserved in [previous-iteration.json](previous-iteration.json).

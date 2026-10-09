# Transformation: local review and decisions

19 September 2026. Seven halls, reviewed in parallel against the manuscript, current placements, implementations and available runtime evidence. The received 18 September reviews and source ZIP remain historical inputs. This pass applies the [review principles](../../REVIEW_PRINCIPLES.md): establish which layer is missing before changing a strong passage.

## Finding

Transformation is a comparatively mature sequence. Its progression is coherent: name the operations; use them to make passage; distinguish axes and constraints; change the relationship between body and surroundings; let the visitor become input; turn the same operations into obstruction and finally an invitation through the airlock.

The main repairs concern evidence packaging, imported archival code and misleading supporting descriptions. No new artifact, promotion, map alteration or cut to any of the seven `final.md` chapters was justified in this pass. This is a local judgment about these encounters, not a rule against restoring other artifacts later.

The pickup registry now describes collection by contact, configurable motion and retained demonstration mode. It previously promised grabbing, carrying and dropping on targets, which this scene does not implement. Only that entry's metadata changed; the other 172 entries, scene reference and surrounding text are unchanged. The book already described the live collection behavior correctly.

| Hall | Work performed by its encounters | Decision and remaining question |
|---|---|---|
| Trans_Pre | The same collectible acquires translation, rotation and scale through cumulative additions. | Keep. Prior museum checks support placement/collection; a novice still needs time to perceive the still cube and distinguish the additions. |
| Trans_Introduction | A transformation becomes a crossing; moving the bank changes what that crossing permits. | Keep. Utilities were missing from the old review ZIP, not the project. Held-opening geometry is tested; ordinary timed crossings and comfortable control reach remain to verify. |
| Trans_Translation | Seven rides differentiate displacement, carried contact and constrained/free motion. | Keep. Shared carry behavior has substantial prior XR tests. Fresh diagnostics expose assumptions in the old course probe; a continuous walk and return boarding remain open. |
| Trans_Rotation | Axis, radius, profile and body width change what rotating forms permit. | Keep the measured comparison. Fresh collision tests reproduce it. Clarify the carousel's default versus clean-gallery collision comments. |
| Trans_Scale | A fourfold change to surroundings and relocation alters the relation between body, table and doorway. | Keep the instant-cut account. Fresh actual-museum route checks pass. Clarify the legacy ScaleMe mode; an ambient crab can still interrupt the encounter. |
| Trans_Body | The visitor becomes an input; boundaries respond differently and a cut persists. | Keep the open-topped trench and recognition question. Prior museum evidence supports the descriptions; this pass did not rerun a full Body traversal. |
| Trans_Pit | Transforms occupy clearance; optional lanes culminate in a combined door that makes room. | Keep the argument and airlock. Fresh obstacle/bypass and airlock checks pass after archive isolation. Old supplementary pit descriptions need a later targeted update. |

`Biome_Ladder_Transformation` is an intentional museum coda documented in `doc/COMBINATORY_BIOME.md`. Its presence after the seven book halls is not grounds to add or remove a chapter automatically.

## A real runtime fault found and repaired

Godot's global script-class cache contained **239 paths into frozen review-package sources**. These copies could take the place of live classes and trigger duplicate-class parse errors. Fresh Rotation and Pit probes initially failed to instantiate the intended scripts.

- Added `doc/book/review-packages/.gdignore` so Godot excludes the archive tree.
- Updated the exporter to write an ignore file before copying source snapshots, including one inside each transferable package.
- Saved the old class cache, verified each affected class name against an existing live source, and corrected only those 239 cached paths. No blanket cache deletion or project restart was used.
- Reran the affected probes successfully. Original failures remain in the evidence alongside the successful reruns.

[Cache repair record](cache-repair.json) records paths and hashes. The zero remaining archive paths is a cache check; it does not certify every Godot resource or every hall. This repair matters beyond Transformation because the archived class paths came from several sequences.

## Evidence supplied, with its limits

| Check | Fresh result | What it establishes |
|---|---|---|
| Rotation body comparison | 40/40 | The same constant-forward collision experiment reproduces narrow BLOCKED and wide ARRIVED. Body settings matter; this is not proof of universal impossibility or headset navigation. |
| Compact Rotation | 33/33 after isolation | Configured bands, profiles, tunnel and aisle clearance in the source-grid fixture. |
| Scale | 40/40 | Actual museum bottle interaction, room/door dimensions, route and bypass exclusion. A recorded ambient crab bite remains an experience issue. |
| Pit | 14/14 after isolation | All six obstacles instantiate, sampled pusher volumes clear their paths, and the specified capsule fits the east bypass. |
| Airlock | 25/25 | Physical opening/closure, occupancy and return behavior in the focused fixture; actual museum placement has separate prior evidence. |
| Translation course | 85 checks, 17 failed assertions | All seven carrier heights, detection and carried arrivals pass. Thirteen assertions incorrectly compare bobbing pickup positions with fixed means; four combine ramp traversal with a flat-floor endpoint expectation. |
| Exporter regression | 6/6 | Utility sources, explicit incomplete-dependency boundaries, supplement bytes/hashes, archive isolation, retained-ZIP protection and rejection of loose publication files that differ from the captured archive. |
| Existing museum regression suite | 123 Godot checks and 9 Python checks pass | Previously repaired Point One, Lines, snapping and triangle behaviors still pass after cache repair. This is separate from Transformation coverage. |

The instrumented first Translation landing stays supported and rises onto its retained ramp: start `(3, 0.01, 10)`, final `(3, 0.442878, 11.33196)`, minimum Y `0.000935`. Its failed flat-floor assertion is not evidence of falling. The other three landings were not individually instrumented. The old course probe also selects pickups by moving positions, so its collection assertions can pass vacuously. Preserve the failed report; update the probe around authored mean positions, retained object references and separate support/ramp checks before using it as an all-joins certificate.

Prior reports remain explicitly prior: the 116-check XR transport regression, 58-check actual-museum pickup runs, seven Body checks, and actual-museum airlock placement. Matching source hashes strengthens attribution but does not prove all dependencies and conditions unchanged. No fresh headset, tracked-controller, unassisted learner or complete continuous sequence traversal was performed.

## Review package repair

The new exporter resolves active utilities separately from ordinary artifacts. `tc`, `sc`, `rc` and `wp` now include their implementation sources; the utility index records literal registry mappings and unresolved/special dispatch honestly. It also includes grid/museum placement context and the transport cube's XR player-body dependency. The bounded resource crawl reports its frontier; the ZIP remains an inspection package, not a runnable game.

Independent review found two further archive-integrity gaps. The builder now refuses to overwrite a retained ZIP even if its extracted directory is gone. The optional publisher now verifies the loose reading text and manifest against the verified ZIP before writing its destination. Both cases have regression coverage; no external publication was performed.

The new [Transformation package](../../review-packages/2026-09-19/transformation-review.zip) includes the full seven chapters, current state and source plans, utility inventory, implementations and selected dated evidence. Read [review.md](../../review-packages/2026-09-19/transformation/review.md) with the ZIP. It is a new snapshot; the 18 September package was not replaced or published over.

## Next actions, in order

1. Continue the maturity-sensitive review with Arrays. Do not impose a full Transformation rewrite to make this pass look uniform.
2. Repair the Translation course probe's measured quantities, then verify ordinary outbound/return boarding and landings. Do not delete ramps to satisfy an inappropriate flat-floor assertion.
3. Update the stale supplementary `Trans_Pit/technical.md` and `artifacts.md` descriptions against the live mechanisms. Its final chapter already describes the developed room.
4. Review the ambient crab interruption in Scale in context. The earlier decision to remove the crab applied specifically to Introduction.
5. Resolve Rotation's localhost zoetrope footnote for external publication. A durable repository copy exists at `doc/research/possible-bodies/transformation-zoetrope.html`; changing a link needs to respect both the book renderer and exported package.

Detailed findings: [opening halls](opening-audit.md), [Rotation](rotation-audit.md), [Scale, Body and Pit](late-audit.md). Each distinguishes text, source, prior captures and fresh runtime checks.

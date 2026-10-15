# Final text draft review

Palle asked to commit the local drafts if they improve the ten spine texts just listed. This review covers the six files that differ from their committed versions. The other four have no local text changes.

## Text updates selected for the map files

| Map | Improvement retained | Scope of the judgement |
| --- | --- | --- |
| [Point Trace](../../../../commons/maps/Point_Trace/final.md) | The Pulse Room comparison gives finite retention an artistic neighbour. Its footnote distinguishes retained pulse rhythms from positions without timing. | The addition is supported by [Lozano-Hemmer's account](https://www.lozano-hemmer.com/pulse_room.php). It adds no new apparatus requirement. The amber short-memory point is already described in the committed chapter but is absent from the inspected authored map and generated hall placements; that inherited mismatch still needs reconciliation. This commit is not a room-release verdict. |
| [Cellular automata bridge](../../../../commons/maps/CA_ExpandingSpace/final.md) | The closing paragraph connects the visitor's position to the surface's response, replacing a list of conceptual choices with the relation actually experienced. | The committed proximity study already supplies the relevant position input and support threshold. The original gold-frame passage is retained. |
| [Cloth physics](../../../../commons/maps/SoftBodies_Cloth_Physics/final.md) | The pin explanation is shorter while retaining the eight-to-two-to-none progression. “Can fall” replaces an assumed landing; stopping the nearby bodies is distinguished from recording them. The membrane remains an optional encounter. | The existing committed console and cloth scripts supply the controls and mechanism. The wall comparison survives. No new artifact or map change is required by these edits. |

## Stronger drafts preserved for later integration

These are full copies of the local drafts, not adopted replacements for the committed map texts. They remain locally editable in their original map folders. Relative links inside the copies retain their original map-file context; some implementation and research references are not yet committed.

| Saved draft | Why preserve it | What prevents promotion with a text-only commit |
| --- | --- | --- |
| [Random Definition — What chance is allowed to do](drafts/Random_Definition/final.md) | A situated “we” follows the abacus, falling digits, seed and movement into the distinction between changing a value and changing a rule. It avoids the absolute claim that offline computers cannot receive physical entropy. | The abacus, Geiger apparatus, shared-seed implementation and receipt have uncommitted dependencies. The authored seed-window token explicitly removes MOVE / KEEP even though the text visits it. The generated museum plan also trails the authored room. Reconcile the route and commit its implementation before promoting this version. |
| [Boids — Three ways to be near](drafts/SwarmIntelligence_Boids_Algorithm/final.md) | Neighbour selection becomes an action of the hand. The revision distinguishes a combined steering request from instantaneous travel and states the timing comparison more accurately. | The black-point neighbour lens and placement changes are uncommitted. The text still uses the older `flocking_controls` artifact marker for the lens encounter. Align that marker and the incoming/outgoing encounters when the exhibit is committed. |
| [Graph flow — Room for another](drafts/GT_Flow/final.md) | A first allocation creates the need to revise it. The harbour gives reverse capacity a concrete consequence while retaining the older forward-only study as a comparison. | `graph_worlds`, its flow model, registry and room placement are uncommitted. The draft should land with those dependencies so the encountered harbour exists in the same revision. |

The Boids timing qualification agrees with the retained probe record: identical time steps preserve agreement; the jittered comparison is aligned by step count, not exactly equal elapsed time. Its local-neighbour account is also consistent with [Reynolds's description](https://www.red3d.com/cwr/boids/). The harbour source was inspected for its two allocations and reverse adjustment. These checks support the writing; they do not replace runtime verification of the new exhibits.

The three new 270–279-word voice samples remain separate proposals. They are not substituted into any map by this commit. There is no new reader preference or whole-book voice decision.

## Preservation and verification

`review.json` records the compared Git revision, original map paths, decisions and SHA-256 hashes. The three draft copies are byte-for-byte snapshots. Before committing, the selected map texts were checked against their reviewed bytes and the index was limited to this review and the three text-only updates. No tutorial, registry, map layout or runtime script is included.

This is a local commit request. Publishing to GitHub remains a separate push.

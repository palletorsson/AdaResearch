# Point Lines: connection, barrier and measurement

Five paragraph edits sharpen the first three encounters. This is a prose pass; no artifact, scene, map or role changes were made.

## Decisions

- Give the hand a plain action before the barrier breaks: bring an endpoint close and let go.
- Explain the apparently empty gap beneath the plank through the actual floor-to-bar collision shape. The explosion removes that shape; disconnecting the points does not restore it.
- Replace a general transition with a specific return to Point One: repeated arrival there, a lasting open passage here. The final sentence interprets what these rules let the rooms keep from a gesture.
- Read the existing displacement example component by component.
- Reverse the subtraction with the endpoints fixed to distinguish direction from length. This acts on the written example; it does not invent a control in the hall.

Walk this line, the player trace, the closing invitation to bring the detour, all code blocks, artifact markers and footnotes are unchanged. Point One is unchanged.

## Source correspondence

snap_point.gd detects the nearby endpoint when released and attempts a connection. snap_connection_manager.gd creates the relation and emits connection_created. line_demo.gd opens the nearby Point Lines barrier on the first accepted connection; disconnection does not restore it.

do_not_cross_barrier.gd creates a box extending from floor to bar top and removes its physics body when broken. The visible gap beneath the plank belongs to that box.

drag_point_target.gd clears _inside after leaving, allowing a further entry. Point One enables repeated arrivals by default. This supports the comparison with the first-only barrier consequence.

line.gd derives its cylinder from the distance, midpoint and direction between the endpoints; its displayed length is rounded to two decimal places. The unchanged written example uses Vector3 subtraction and length().

These are source checks, not a new VR observation or a claim of verified tactile feedback.

## Scope and next encounter

The current technical.md and tutorial.md still describe older teaching routes. Existing purpose-view actions already record this. They were not used as evidence for the current interaction and were not rewritten in this narrow prose pass.

The measuring-line source also contains a near-integer visual jitter effect and conditional feedback. This is a possible later inquiry into how a measuring instrument draws attention to selected values; its runtime behavior needs checking before the manuscript describes it as an experienced effect.

Continue next with Walk this line and the player trace. Keep the distinction between a marking that invites a path and a record that samples actual movement.

## Reading records

The current manuscript hash, encounter metadata and purpose notes are synchronized in a new derived snapshot. Unchanged annotations are retained by block identity. This page includes continuous reading and five original/revised pairs. Frozen full-book and audiobook captures were not regenerated.

See Point_Lines.diff, changes.json and checks.json for exact edits, paragraph purposes and preservation checks.

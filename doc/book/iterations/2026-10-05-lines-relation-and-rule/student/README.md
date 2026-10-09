# Lines: carry the point, read the relation

This is a proposed next state of the imagined learner's code. It continues the **exact saved Coordinates state**. That earlier state began with an explicitly assumed reconstruction of Point One; no real learner portfolio is claimed.

The host is the existing museum's prepared, unit-scale `Node3D` student station and configured XR hand. Save `assembled.gd` and the supplied `line_skin.gd` together. This is not a replacement project, XR installer or museum artifact patch.

The executable lesson adds three blocks to the incoming file:

1. Retain references to the two endpoints and the segment.
2. Keep the existing point as A; duplicate it once for B; create the supplied segment renderer.
3. Every frame, express both endpoints in the station frame, compute `b - a`, measure its length and update the segment.

`line_skin.gd` is explicitly supplied. It gives a cylinder visible thickness and aligns its Y axis with the endpoint displacement. Basis construction is not a newly taught prerequisite. The station must retain unit scale; its position and rotation may change.

The optional `two_lines_parallel.gd`, `two_lines_plus.gd`, `two_lines_x.gd` and `two_lines_x_depth.gd` are complete extensions of the same code. They add one segment between **position values**, without two more pickup bodies. Only the first segment follows held endpoints. The second is made once in `_ready()`. This distinction is intentional and explained in the lesson. The depth variant separates C and D from the first segment by 0.2 metres.

## Evidence

Run `python run_checks.py` from this folder. It first composes the declared edits from the pinned predecessor and checks that all printed executable blocks match them; comments and blank lines are ignored for that text comparison. The plus exercise is checked against its printed block too.

`expected.gd` is a reviewed frozen target, not an independently implemented oracle. Behavioral evidence comes from native Godot checks and a deliberately broken variant. The native runner copies this repository's XR Tools into a private temporary project; it does not change the museum or the addon.

The tests cover both endpoint pickups, real overlap selection, grab-driver movement, frozen release, preserved radius and surface, a translated/rotated station, the rendered endpoints, vertical/coincident/reseparated endpoints, and all four two-line arrangements. The negative variant keeps pickup and distance working but only draws the segment once; the same checks detect its stale geometry.

`report-runtime.json` records outcomes, source and dependency hashes, complete input hashes, and the negative-control failure IDs. A passing report does not prove headset usability, learner understanding, or a new museum playthrough. The actual museum implementation remains unchanged.

## Writing boundary

The finite endpoints and generated vertices remain countable. The qualitative change is in what the learner acts upon: an individual body, a relation between positions, then a collection and eventually a rule for generating that collection. Do not describe 3D as an uncountability threshold.

The two-line exercise gives that transition a small material form: A and B are held bodies; C and D are stored positions. The algorithm draws both segments. Trace can next retain positions in order without inventing a pickup object for every entry.

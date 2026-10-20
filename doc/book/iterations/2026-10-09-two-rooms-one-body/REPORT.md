# Two rooms claim one body

Installed in **Endless Museum → Shaders → Patterns**, on the left after the image gallery, beside the precision/time/feedback model. These pictures come from that Godot hall.

The existing black point becomes a small hand control for a larger sphere. Move it sideways and different parts of the sphere enter overlapping fields. One lifts, another folds; their shared membership activates a twist. The original sphere remains available.

![Competing rules in the real museum](museum/fuzzy-rules.png)

## Three views, one source

FIELDS reveals graded membership. RULES turns the memberships into a weighted blend of positions. CUT makes a definite selection: keep a triangle when BOTH at its source centroid meets the threshold. Its jagged open edge is visible evidence of sampling, not a smooth closed solid.

![The coloured source](museum/fuzzy-fields.png)
![A threshold selects part of the same sphere](museum/fuzzy-cut.png)

## What your hand changes

Grip the black point and move left or right. On desktop, right-click to carry and again to release; LEFT/CENTRE/RIGHT also place it. WIDTH changes the field transition, STRENGTH changes deformation, THRESHOLD changes the cut. The meters show values at the centre; the surface shows values across the body.

![Native dials and buttons](museum/fuzzy-console.png)

## A decision remains

Softening the boundary does not remove the choice. We chose the fields, the three transformations, how they combine and the threshold that selects a face. The comparison makes those choices available to inspection. This is a visual research encounter; the tutorial and reflective text have not been rewritten.

## Placement and tests

Map cell [8,40], rotation180. Six earlier artifacts retained; entrance and onward portal retained. The shaded frames indicate two influences rather than precise field boundaries. Deforming geometry has no collision; fixed plinth, controls and museum floor retain theirs.

**97/97 native Godot checks passed**, including the earlier model installation, explicit membership arithmetic, zero-strength identity, retained source, monotonic threshold selection, empty selection, parameter extremes, pointer buttons, desktop carry, synthetic XRTools grip/dials/release. 321 new supported capsule samples cover access to the controls and both sides, alongside the earlier entrance/exit route checks. Physical headset comfort and Quest performance remain untested. Existing unrelated museum startup/resource warnings remain in the log.

![Arrangement from above](museum/fuzzy-above.png)

[Actual receipt](validation/report.json) · [Engine log](validation/engine.log) · [Source](source/fuzzy_body.gd) · [Usage and exact operations](source/README.md) · [Open the museum scene](source/museum.tscn)

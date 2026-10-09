# Point Grid: a place to return to

3 October 2026 · one tutorial pilot for author review.

## What it adds

The next map after Point_Trace is Point_Line_Grid. Keep that order. The new construction converts a position into an integer lattice address, then converts the address back into a position: divide by spacing, round, multiply. `Vector3i` counts steps and `Vector3` measures metres. The learner changes one coordinate, compares either side of a rounding boundary, tries negative inputs, and changes the spacing.

The record is still an ordered Array[Vector3]. Its array index counts visits; a lattice address names a place. Returning to a previous address is another visit. Admission changes from Trace's minimum-distance test to a changed rounded output. `is_empty()` seeds the first entry, and `!=` compares the new placement with the previous one. The existing adjacent-pair loop and bounded capacity are reused.

The local lesson contract records those introductions. It does not promote the old numerical taxonomy or declare every proposed curriculum location verified. The broad branching chapter in Transformation can build on this use of a comparison.

## Which part of the museum

The core source is `commons/primitives/point/grab_sphere_point_snap.gd`, particularly `snap_position_to_grid()`. It rounds world coordinates at its configured spacing, and can align the marker on release. The reduced lesson names its frame explicitly: all inputs and outputs belong to Study. It uses quarter-metre spacing so the movement of the output can be seen clearly, rather than silently copying the hall's five-centimetre setting.

The study separates a larger pink PointHandle from a small white output marker. Rounding never moves the input. Release only freezes that input through the already supplied hold. The source artifact's offset marker, release alignment and table are additional behaviors, not promises made by the reduced study.

The Trace manuscript and museum already encounter snapping. This is the tutorial's first explicit construction of that operation; it is not a claim that the preceding hall had a continuous or unmediated record.

## Supplied and deferred

PointHandle and TraceDrawing are inherited unchanged. The learner creates the output sphere and all readouts in code. GridRuling supplies a finite XY section at Z = 0, labelled with integer lattice indices. It has no collision or recording rule. It draws the selected spacing, omitting the visual ruling below 0.025 m to avoid excessive reference geometry. No teaching object is obtained through a scene-node lookup.

A lattice address identifies a representative point. It is not automatically the label of a floor tile enclosed between drawn lines. The plan vitrine, nested floor loops, body/headset trace and transformed replay remain separate museum encounters. They need not all become new programming requirements here. Array and Tiling can later develop placement from indices and nested repetition.

The critical manuscript and live map stay unchanged. Next is Triangle: using positions to close a boundary, then distinguishing that boundary from a face and collision. Coordinates still retains its earlier spine position; its shared-starter rewrite remains pending.

## Evidence

Native Godot 4.6 checks cover both sides of positive and negative boundaries, exact halfway behavior, all three coordinates, unchanged input, ordered returns, diagonal jumps without invented intermediate visits, spacing changes, bounded memory, desktop pickup, synthetic XR grip and a translated bare study. Actual desktop captures use scripted positions for controlled comparisons. A physical headset and a beginner reading trial remain pending.

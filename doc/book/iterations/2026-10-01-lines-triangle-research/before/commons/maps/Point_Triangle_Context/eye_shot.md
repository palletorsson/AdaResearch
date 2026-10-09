# Eye shot — Point_Triangle_Context

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 12 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] dark_sphere:0:-0.5         <-> triangleprofiles:0:2       gap +1.00m (centers 2.00m)`
- `[tight  ] triangleprofiles:0:2       <-> floating_sphere_field#bounds:4,3,12 gap +0.41m (centers 1.41m)`
- `[tight  ] floating_sphere_field#bounds:4,3,12 <-> pythagorean_triangle_angles gap +1.16m (centers 3.16m)`
- `[tight  ] folded_strip:270:1         <-> pythagorean_triangle_angles gap +0.24m (centers 2.24m)`
- `[tight  ] draw_triangle_faces:90     <-> science_screen:90          gap +0.41m (centers 1.41m)`
- `[tight  ] draw_triangle_faces:90     <-> triangle:90                gap +0.41m (centers 1.41m)`
- `[tight  ] draw_triangle_faces:90     <-> pythagorean_triangle_angles gap +1.16m (centers 3.16m)`
- `[tight  ] science_screen:90          <-> triangle:90                gap +1.00m (centers 2.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.171
      walkability improved: 0/1  mean Δ=-0.316

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 12→12). Note-only.

## The voice (qfep)
14 of 14 cast members carry a theory-claim; 0 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **draw_triangle_faces** — fan_triangulate(loop) → a colored surface: the moment a closed loop of points stops being an outline and becom
- **floating_sphere_field** — The void was never empty, only under-rendered. Replacing the lattice with a drift trades the comfort of fixed 
- **folded_strip** — triangle_strip(24) — a pleated ribbon of alternating heights, faces sharing edges down its length. The most ec

## The text vs the space
walked.md exists — the writing names 10/14 of the cast; dwells declared for 1.
- **the writing's subjects are blocked in space**: draw_triangle_faces, folded_strip, pythagorean_triangle_angles, triangle, triangleprofiles sit in clearance violations — the text promises what the floor obstructs.
- space without text: dark_sphere, floating_sphere_field, lab_room, science_screen — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.

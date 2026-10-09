# Eye shot — Primitives_Ignorance

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **3 overlaps, 23 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] sphere:0:-0.5              <-> library_rack:0:0#collection:primitives#layout:rack_torus.json gap +0.00m (centers 1.00m)`
- `[OVERLAP] sphere:0:-0.5              <-> platonic_grabbables        gap -0.55m (centers 3.16m)`
- `[tight  ] library_rack:0:0#collection:primitives#layout:rack_torus.json <-> diamonds:0:1:0.6           gap +1.00m (centers 2.00m)`
- `[OVERLAP] library_rack:0:0#collection:primitives#layout:rack_torus.json <-> platonic_grabbables        gap -1.48m (centers 2.24m)`
- `[OVERLAP] diamonds:0:1:0.6           <-> platonic_grabbables        gap -0.11m (centers 3.61m)`
- `[tight  ] plus:0:1                   <-> grab_octahedron:0:0:0.4    gap +0.00m (centers 1.00m)`
- `[tight  ] plus:0:1                   <-> sphere_mid                 gap +1.00m (centers 2.00m)`
- `[tight  ] grab_octahedron:0:0:0.4    <-> sphere_mid                 gap +0.00m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.008
      walkability improved: 0/1  mean Δ=-0.106

no sibling kept — the move did not beat the ride (overlaps 3→3, tight 23→23). Note-only.

## The voice (qfep)
23 of 23 cast members carry a theory-claim; 0 mute.
- **capsule** — A cylinder that rounded its ends — the primitive of the *organic*, the shape a body or a pill takes when it re
- **capsule_radials_rings** — The capsule with its resolution exposed — radial segments and rings you can set. The reminder that every smoot
- **cube_scene** — Transformation changes S while the cube serves as the invariant reference body. Because the base form is so le
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change

## The text vs the space
walked.md exists — the writing names 14/23 of the cast; dwells declared for 1.
- **the writing's subjects are blocked in space**: grab_octahedron, library_rack, platonic_grabbables, sphere, sphere_mid sit in clearance violations — the text promises what the floor obstructs.
- space without text: cube_scene, dark_sphere, diamonds, floating_sphere_field, plus, prism_block — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.

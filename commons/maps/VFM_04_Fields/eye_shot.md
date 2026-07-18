# Eye shot — VFM_04_Fields

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **2 overlaps, 3 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] magnetic_simulation        <-> weather_vector_field       gap -0.92m (centers 6.08m)`
- `[tight  ] weather_vector_field       <-> vector_field               gap +0.97m (centers 11.18m)`
- `[OVERLAP] weather_vector_field       <-> force_fields               gap -0.38m (centers 7.00m)`
- `[tight  ] vector_field               <-> force_fields               gap +0.50m (centers 12.08m)`
- `[tight  ] force_fields               <-> force_field_visualizer     gap +0.72m (centers 5.66m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.004
      walkability improved: 1/1  mean Δ=+0.012

no sibling kept — the move did not beat the ride (overlaps 2→2, tight 3→3). Note-only.

## The voice (qfep)
9 of 11 cast members carry a theory-claim; 2 mute.
- **VectorFieldFlow** — The swirl-to-radial ratio in _field_value(). It determines whether the field spirals inward, orbits, or ejects
- **flow_field_painter** — Noise as structured randomness â€” not chaos, not order, but Î»-edge. Flow reveals hidden structure. noise_sca
- **force_field_visualizer** — Fields as invisible structure â€” order you can't see until you probe it. The hidden F that shapes everything.
- **force_fields** — Regional F — three zones with three different force laws. Cross a boundary and physics changes. Lambda is spat
- mute: interactive_point_origin_force, noc_5_04_flow_field

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.

# Eye shot — ForcesChaos

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **12 overlaps, 10 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] library_rack:0:0#collection:physics_simulation#layout:rack_layout.json <-> forcedirected3d            gap -5.71m (centers 3.61m)`
- `[tight  ] three_body_problem         <-> example_2_8_two_body_attraction_vr gap +1.07m (centers 2.24m)`
- `[tight  ] three_body_problem         <-> particle_systems           gap +0.21m (centers 6.71m)`
- `[OVERLAP] nbody_simulation           <-> particle_systems           gap -2.71m (centers 3.61m)`
- `[OVERLAP] chaos_attractor            <-> forcedirected3d            gap -6.19m (centers 3.00m)`
- `[tight  ] chaos_attractor            <-> particle_systems           gap +0.91m (centers 7.28m)`
- `[OVERLAP] chaos_attractor            <-> spring_system              gap -2.50m (centers 3.00m)`
- `[OVERLAP] forcedirected3d            <-> particle_systems           gap -4.62m (centers 10.20m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.043
      walkability improved: 0/1  mean Δ=-0.004

sibling **Trial_eye_ForcesChaos** kept: overlaps 12→12, tight 10→4, pathfinder OK.

## The voice (qfep)
11 of 13 cast members carry a theory-claim; 2 mute.
- **catalyst_target** — Transformation here is discrete state change: intact, flashing, destroyed, respawned. Identity persists while 
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **example_2_8_two_body_attraction_vr** — gravitational_constant and initial tangential velocity — together they decide circular, elliptical, parabolic,
- **example_2_9_n_body_attraction_vr** — body count and gravitational_constant — count gates whether the system can be reasoned about; G scales how fas
- mute: chaos_attractor, proximity_spawner

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The floor was fighting the walk — bodies inside each other's clearance. The mover found a better seating; the ride confirms it in text. The voice column above says what the room is FOR; the next writing pass should say it in the walked page.

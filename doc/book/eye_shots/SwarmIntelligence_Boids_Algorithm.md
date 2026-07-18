# Eye shot — SwarmIntelligence_Boids_Algorithm

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **4 overlaps, 1 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] boids_aquarium             <-> boid_manager               gap -6.66m (centers 4.00m)`
- `[tight  ] boid_flocking              <-> science_screen:180:1.5#mode:scatter gap +1.00m (centers 2.00m)`
- `[OVERLAP] boid_flocking              <-> boid_manager               gap -4.90m (centers 5.66m)`
- `[OVERLAP] science_screen:180:1.5#mode:scatter <-> boid_manager               gap -3.34m (centers 7.21m)`
- `[OVERLAP] boid_manager               <-> boids_2d_in_3d             gap -7.55m (centers 4.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.009
      walkability improved: 1/1  mean Δ=+0.006

no sibling kept — the move did not beat the ride (overlaps 4→4, tight 1→1). Note-only.

## The voice (qfep)
3 of 5 cast members carry a theory-claim; 2 mute.
- **boid_manager** — interaction_radius — at zero, it's a particle cloud; past a threshold, a coherent organism crystallizes from t
- **boids_aquarium** — Emergence at Î»â‰ˆ0.4 â€” simple rules create complex, unpredictable behavior without central control separati
- **science_screen** — Transformation here is projection: a 3D state is re-expressed in 2D while preserving selected structural relat
- mute: boid_flocking, boids_2d_in_3d

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.

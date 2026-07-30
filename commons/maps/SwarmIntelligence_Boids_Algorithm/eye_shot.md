# Eye shot — SwarmIntelligence_Boids_Algorithm

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **4 overlaps, 1 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] boid_flocking              <-> boid_manager               gap -3.85m (centers 6.71m)`
- `[OVERLAP] science_screen:180:1.5#mode:scatter <-> boid_manager               gap -2.74m (centers 7.81m)`
- `[tight  ] boids_aquarium             <-> boids_2d_in_3d             gap +0.72m (centers 2.83m)`
- `[OVERLAP] boids_aquarium             <-> boid_manager               gap -8.42m (centers 2.24m)`
- `[OVERLAP] boids_2d_in_3d             <-> boid_manager               gap -8.55m (centers 3.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=+0.000
      walkability improved: 0/1  mean Δ=+0.000

no sibling kept — the move did not beat the ride (overlaps 4→4, tight 1→1). Note-only.

## The voice (qfep)
5 of 5 cast members carry a theory-claim; 0 mute.
- **boid_flocking** — Reynolds' three commandments — separate, align, cohere — and nothing else. No leader, no plan, no bird knows t
- **boid_manager** — interaction_radius — at zero, it's a particle cloud; past a threshold, a coherent organism crystallizes from t
- **boids_2d_in_3d** — The flat textbook flock stood up in the room — 2D boids rendered in 3D space, the diagram and the phenomenon s
- **boids_aquarium** — Emergence at Î»â‰ˆ0.4 â€” simple rules create complex, unpredictable behavior without central control separati

## The text vs the space
walked.md exists — the writing names 5/5 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: boid_flocking, boid_manager, boids_2d_in_3d, boids_aquarium, science_screen sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.

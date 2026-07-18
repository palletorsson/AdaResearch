# Eye shot — LSystems_Architecture

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **2 overlaps, 0 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] dark_sphere                <-> CityGenerator              gap -5.65m (centers 2.83m)`
- `[OVERLAP] CityGenerator              <-> lsystem_dungeon            gap -4.24m (centers 4.24m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.015
      walkability improved: 1/1  mean Δ=+0.054

no sibling kept — the move did not beat the ride (overlaps 2→2, tight 0→0). Note-only.

## The voice (qfep)
3 of 3 cast members carry a theory-claim; 0 mute.
- **CityGenerator** — iterations — complexity grows exponentially; each level adds branching in all six cardinal directions Change t
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **lsystem_dungeon** — Architecture from grammar: the dungeon layout emerges from rewriting rules on the XZ plane. Rooms and corridor

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.

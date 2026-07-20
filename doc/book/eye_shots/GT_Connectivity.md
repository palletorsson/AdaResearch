# Eye shot — GT_Connectivity

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 1 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] topological_sort:0:0:0.6   <-> tarjan_algorithm:0:0:0.6   gap +0.00m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=+0.000
      walkability improved: 0/1  mean Δ=+0.000

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 1→1). Note-only.

## The voice (qfep)
3 of 3 cast members carry a theory-claim; 0 mute.
- **kosaraju_algorithm** — Pure F through reversal: transposing the graph changes direction but not mutual reachability. SCCs persist as 
- **tarjan_algorithm** — Pure F in directed form: SCCs mark the regions where reachability closes back on itself. Low-link values revea
- **topological_sort** — The DAG's confession: once arrows forbid cycles, some order becomes mandatory. Topological sort extracts the h

## The text vs the space
walked.md exists — the writing names 3/3 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: tarjan_algorithm, topological_sort sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The space already walks: the bodies keep the law without being told. What carries this map is its voice, not its floor.

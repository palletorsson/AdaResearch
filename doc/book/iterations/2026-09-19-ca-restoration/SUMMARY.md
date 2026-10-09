# A comparison gets its room back

The review found a real gap between the manuscript and the museum: CA_AgentsCircuits was present in the declared sequence but absent from the live and shipped museum plans. Its two works already existed and were both primary. This repair restores their encounter instead of cutting the comparison from the book.

The museum route now includes **Soft Rules → AgentsCircuits → Edge of Chaos**, matching the eight-hall book order. All seven existing CA halls retain their layouts and artifacts. Other sequence plans are unchanged.

## Encounter

- A 13 × 18 m gallery replaces the uneven, partly open source grid. The entrance has a true spawn cell and a continuous route to the exit.
- The Rule 90 explorer stands near the entrance. Its existing neighbour-study furniture supplies STEP, RUN, SEED and CELL. The desk's feet meet the floor and its main buttons sit about 1.08 m high.
- The existing recursive pyramid stands farther along the room at 0.42 scale. Its height is about 5.15 m; the hall has an open roof. A clear route surrounds it.
- Both artifacts remain primary, in explorer → pyramid order. Neither production artifact script nor the shared museum script was changed.

The manuscript receives only two further changes: use STEP to build the history, and try the existing single/paired-seed switch now. The question about resemblance and different procedures remains intact. [Exact text diff](CA_AgentsCircuits.diff).

## Evidence

[Desk](desk.png) · [Pyramid](comparison.png) · [Arrival](arrival.png)

These are actual Godot museum captures, made through an isolated copy of the production museum scene. The desk images show generation seven held after seven STEP button signals. They are two views of the restored encounter, not a visual before/after pair: this hall was missing from the previous museum route.

- Six support rays reached the floor at the expected height.
- Seven controlled CharacterBody walks reached their destinations, including the desk approach, all four sides of the pyramid, and the exit threshold.
- Seven live checks passed for initial state, STEP, RUN/pause, paired seed, the pair's next row, return to the central seed, and control height. Buttons were exercised through their actual signals; no hand tracking was simulated.
- Twenty-six production routing assertions selected all eight halls in order and reset the chapter cursor after the last hall.
- Source snapshots confirm that the shared museum script, artifact roles and sequence definition were untouched by this repair; only the missing plan row and CA order counts were added to the plans.

[Placement and walks](report.json) · [Controls](controls-report.json) · [Route](navigation.json) · [Preservation checks](verification.json) · [Source manifest](source_manifest.json)

## Remaining work

Headset reach, continuous portal travel and learner understanding have not been tested. Rendering reported the existing global UID/certificate warnings and a slow decorative statue build; this is not a frame-rate acceptance test.

The pyramid is the project's existing recursive cube construction. Its script contains six recursive calls although its identity comments describe five; this repair makes no five-copy or exact mathematical-dimension claim. Its algorithm and the visibility of its nested gaps deserve a focused Fractals follow-up. Do not present this capture as validation of the ideal Sierpinski construction.

The finite Rule 90 desk has 32 wrapping sites; long runs can erase the single-seed pattern. STEP supports the short, held comparison described here. The Introduction's early NEXT answer display remains a separate reveal-timing task.

The dated `_map_halls` generation metadata is historical; the current `plans` rows, authored membership and regenerated effective-order files carry this restoration. Regeneration also reports existing layer-size mismatches in six unrelated maps. Those warnings are retained in the build logs and are not repaired here.

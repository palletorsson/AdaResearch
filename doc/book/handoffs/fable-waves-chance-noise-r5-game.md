# R5 — Random_Game: the crossing (Fable, 12 September 2026)

Astra's card asked for a bounded crossing over a shallow recoverable gap, with the cycling cube as the actual support, a reliable observation position, a return path and a bypass, the enemies kept off the first timing experiment, and the shipped during-motion beacon compared with a genuine advance cue whose countdown runs to a sampled deadline. Palle's brief: "be bold here, this needs to be more like a Lara Croft adventure."

Both point at the same room, and the room already held the pieces in the wrong places.

## What was there

`random_cycle_cube` — the map's `r_c`, a one-metre tile that sinks out from under you on drawn timing, with a fixed four-state order, a collider it switches itself, and a mote lit while it moves. The map had a five-by-three pit of `0` cells in its west corner (a `0` is a hole the museum lays no floor on), two folding enemies and a spire standing inside that void, and the tile itself parked in another void row in the far south-east corner, sixteen cells from the pit it was written for. The old final said, correctly, that the museum-floor support was unverified.

## What it is now

A tomb chasm, staged by the tile itself through an opt-in `stand:chasm`:

- **The hall's own hole stays a hole.** The artifact lines it, lays a bed one metre and two centimetres down, cuts a ramp back out of it on the west third, closes all four sides, and lays a worn threshold at each lip.
- **Three of these tiles stand in a row across it**, a step proud of the floor, gaps of twelve centimetres, the tile the token names being the middle one. A stone stands 2.4–4.6 s and is gone 1.1–2.2 s, each from its own seed dealt by the crossing's generator.
- **Two surfaces, deliberately apart.** A stele at the lip carries the order cut in stone — IT STANDS · IT LEAVES · IT IS GONE · IT RETURNS — and under it, ONLY THE WAITS ARE DRAWN. A tablet beside it carries the live draws, a line per stone: `1 STANDS drawn 4.3 s left 3.1 |||||||.`
- **The cue.** The middle stone wears a crown ring for the second before it goes, lit while it still stands. CUE at the lip swaps it for the shipped beacon on all three stones at once. The machine is identical either way; what differs is when a body may commit.
- **The idol** on the far lip: a lit prism on a plinth with the crossing's five-digit seed cut into its face. REPLAY deals that rhythm again, NEW SEED names another. What you carry out of a trap room is the ability to run it again.

## The deadline is stored

The loop drew its wait and handed it straight to a timer, so the number existed only inside that timer and nothing could say how much was left. `_note_step` now records the kind, the draw and the millisecond it expires; the tablet's bar, the crown and the probe all read that. The probe samples every 0.25 s for 22 s and fails if a drawn figure moves while its step is still running — zero moves over five stands and four gones. A countdown redrawn each frame is a fresh throw of the dice wearing a clock's face, which is the trap Astra named.

## Evidence

| lane | result |
|---|---|
| bare (`run_wcn_probe.sh game`) | 47 checks, 0 failures |
| live (`run_wcn_probe.sh game live`) | 57 checks, 0 failures, exit 0 |

The live lane's desktop rig presses REPLAY, NEW SEED and CUE through the pointer, walks the row, and then falls on purpose: it stands on the middle stone at y 0.22, the stone leaves, and it is on the bed at −1.02; it then crosses the bed to the ramp's foot and climbs out to y 0.00 on the hall floor. Across runs the walk has both ended on the far side with all three stones standing and dropped at a stone that left under it. A ray down the pit finds the artifact's `BedCollider` at 1.02 m and no museum tile, and the pit's cells are asserted still `"0"` in the same run — the support check the old final asked for. A flood fill of the map's own structure from the north door proves the far lip is reachable with no stone at all.

## Map changes

- `r_c` from (12,16) to (3,4), the pit's exact centre, as `r_c#stand:chasm#cue:advance`.
- `scissor_stalker` (1,3) → (2,8), `kaleidocycle_enemy` (5,3) → (4,10), `kresling_spire` (3,4) → (12,13). The first two stood inside the void; the third stood where the middle stone belongs. The arena now comes after the crossing on the route, which is Astra's "activate them as a distinct later variation" read as a walk.
- Structure (6,2) from `"2"` to `"1"`: one doorway through the wall stub. Without it the spawn corner was sealed by the pit and that column, every artifact was unreachable from the spawn, and the crossing would have been the only way out — the opposite of a bypass. Pathfinder: 173 of 233 cells reachable, all nine artifacts, no failures.
- `museum.artifact_placement: "map"` and `sculpture_clear_rects [[1,2,7,8],[8,8,13,15]]`.

## Not done, said plainly

- No headset walk. The crossing is a body's question and no body has walked it in VR.
- No person at the controls, and no one has tried to cross under the beacon rather than the ring; the comparison is built and checked, not yet felt.
- The museum's starfield is visible under the hall floor from inside the bed when you look up past the lips. That is the museum's void, not the artifact's, and it is left alone.
- Astra's review of this room.
- The map's own grid lane (outside the museum) walks a `0` as ground, so in that lane the pit's floor is invisible rather than absent; the staging is built for the museum lane, where the hole is real.

## Files

`commons/primitives/cubes/random_cycle_cube.gd` (the staging, the stored deadline, the advance cue, the second wait band — every default a no-op for the seven existing placements), `commons/maps/Random_Game/map_data.json`, `commons/maps/Random_Game/{final,summary,technical,tutorial,blurb,field_notes}.md`, `commons/testing/probe_wcn_game.gd` and its live port, `tools/run_wcn_probe.sh` and `tools/port_wcn_probes_live.py` (the `game` case), `tools/build_wcn_captures_page.py` (R5's views), and the captures page rebuilt. Forum: 260912-4tujd.

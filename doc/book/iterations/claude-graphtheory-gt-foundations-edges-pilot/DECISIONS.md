# GT_Foundations — edges pilot

Sequence `graphtheory`, hall `GT_Foundations`. 24 September 2026. Not installed: `final.candidate.md` is a candidate, `before/final.md` the shipped chapter, `final.diff` the delta, `as_built_probe.txt` the report of `commons/testing/probe_gt_foundations_bodies.gd` (two Godot boots, no agents). Palle installs or not.

Why this hall: the sequence's opening; 405 words about one artifact of five; the rule named in paragraph one ("The exhibit alternates between two visiting rules"); no disturbance; the edge deferred to "a proposed extension could".

## 1. The hall is a graph — that is the encounter, and it is the map's own design

`commons/maps/GT_Foundations/map_data.json`, read the museum's way (`h==1` floor, `0` hole — the hall is in `map_authored.json`, "the map IS the hall", `em_plan.json` row `authored: "map"`):

```
4444411144444      x: 0123456789012
4111.11....14      A = island x1-3 z1-3 (graphspace, an board)   N = block x5-6 z1-2 (synthesis stand)
4111.11....14      spine x=5 z1..10, doors at x5-7 north and south
4111.1.....14
4....1.....14      W = stub end (3,5): one hole cell (3,4) from A
4..1111111.14      crossing row z5 x3..9, fork J5 at (5,5)
4....111...14      K = block x5-7 z6-7 (Königsberg)
4....111...14
4....1..11114      R = block x8-11 z8-10 (two_travelers at (10,9)) + column x=11 z1..7, dead end at (11,1)
4....1..1.114
4....1..11114
4444411144444
```

Rides (`utilities`): `tc:2:x` at (3,2) parked on A, lands at (5,2); `tc:3:z` at (9,5) parked at the crossing row's east end, lands at (9,8) in R; `tc:3:x` at (5,8) parked on the spine, lands at (8,8) in R. A cube's `DetectionArea` is a child of the cube (`transport_cube.tscn:25`), so a ride can only be boarded where it is parked; a rider still in the `CarryArea` is carried back after `return_delay = 3.0` s.

Degrees of the floor graph: A 1 · W 1 · column top 1 · fork 4 · N 3 · J8 (5,8) 3 · R 3 · each door 1. More than two odd vertices, so no walk uses every walkway once — the hall fails Euler's test exactly as the city does. That is beat 6, and it needed no code.

A body that steps into a hole falls past `CATCH_Y = -6` and `_catch_if_fallen` (`endless_museum.gd:18339`) sets it down at the save point, the last threshold crossed — the door. Beat 2.

## 2. The beats

| beat | in the candidate | verified against |
|---|---|---|
| **Encounter** | a floor one cell wide, nothing either side, no floor below; the fork, the block, the far door; islands with parked cubes; "you are already walking a graph" | the tile above; `tc` cells; museum hole rule ([[museum-zero-is-a-hole]]) |
| **Disturbance** | the crossing row ends one cell short of the island whose cube is parked on the wrong shore; step in, you are set down at the door | cells (3,5)/(3,4)/(3,3); `tc:2:x` at (3,2); `_catch_if_fallen` |
| **Search** | the east cube carries you two cells to R and back if you stay aboard; R has two ways in and none you can call; count the ways at each place | `transport_cube.gd` carry/return; the tile |
| **Rule** | a graph is a set of places and pairs; the drawing is the hall's, not the graph's; a traversal is an itinerary laid over it | `two_travelers.gd` header ("every algorithm is an itinerary") |
| **Name** | vertex, edge, breadth-first/queue, depth-first/stack — after the tide and the diver have been watched | `two_travelers.gd:105–127` `_bfs`/`_dfs`; readout strings `:155–158` (task .010) |
| **Edge** | Königsberg: 5/3/3/3, all red, no walk; then the floor's own odd count; then the QFEP paragraph with the "proposed extension" turned into a question the visitor can ask now (task .011) | `konigsberg3d.gd:104` `parity = "blocked"`, `:517` red for odd, `:850` theorem label, probe: labels "Degree: 5 / 3 / 3 / 3" |

The tide and the diver are named as the readout names them; the QFEP paragraph ("If the lamps stood for people awaiting attention…") is kept and now ends on a question rather than an extension. The handover is unchanged.

## 3. The as-built, which the chapter cannot pretend about

`probe_gt_foundations_bodies.gd` stands each placed body at its map cell and scale, at the origin of a hall frame (floor y 0, interior x 0.5..12.5, z 0.5..11.5; the museum's own frame is the same shifted one metre in x). Nobody has walked this hall in the museum (no row in `em_layout_walk.json`, no `seam_walkable` entry). What stands:

**Königsberg at scale 0.6 (`KonigsbergBridge:0:0:0.6` at (6,6))** — a 50 × 30 m city scaled to 30 × 18 m in a 13 × 12 m hall:
- the four landmasses are solid CSG cylinders (`use_collision = true`), radius 2.4 m, **y 0.90..1.50**: Altstadt centred x −3 (behind the west wall), Löbenicht x 15 (behind the east wall), **Kneiphof x 3.6..8.4 / z −3.6..1.2 — in the north doorway (x 5–7)**, **Vorstadt z 10.8..15.6 — in the south doorway**. A walking body meets a red disc at chest height in both doors. Both "Degree: 3" labels float in the doorways at 2.5 m; "Degree: 5" is behind the west wall.
- seven solid bridge decks (`konigsberg3d.gd:733 use_collision = true`) cross the hall at **y 1.1..2.2**: the Grüne Brücke runs wall to wall along z 5.4..6.6, its deck 1.9–2.2 m over the crossing row and 1.56 m at x 0..1.5; Krämer/Schmieden/Köttel decks reach into the north doorway at 1.35–1.74 m, Holz/Hohe/Honig into the south.
- the Pregel (no collision) spans x −9..21, z −3..15 at y −0.75..−0.45: under the entire floor, visible through every hole.
- the theorem plate (yellow, font 28) at (6, 3.24, 6) over the block — readable from the spine.

**graphspace at scale 0.6 at (2,2)** — 12 solid room shells over a 60 m spread (x −26..34, z −27..30, y −3.9..6.1); 168 of 184 mesh centres outside the hall. Inside: **Room_0's shell (solid, 5.4 × 3 × 4.8 m) stands on R at x 6.6..12 / z 7.3..12.1 — around the two travellers**; a 12 m floor-level plank crosses the void from x −2.3 to 9.7; two portal frames stand in the void.

**graphspace3d at (11,5)** — 15 buildings in an 80 × 40 × 80 m volume, 283 of 296 mesh centres outside. Inside: ramps at y 3–6 and y −3.5..−4.7, and a solid portal frame (1.9 × 2.7 × 1.7 m) at x 2.1..4 / z 5.4..7.1 — over the stub's end.

**synthesis_stand#subject:graphspace#mode:hero at (5,1)** — the stand pins graphspace's far-end variant (`lattice`) **at full size** (`_build_hero` sets `inst.position`, never a scale): a 94 × 94 m body. Inside the hall: Room_6's shell (solid, 9 × 5 × 8 m) at x 6..15 / z −3..5 — its west wall runs along x 6 beside the spine and across the north doorway; a plank 12 cm high across the whole entry row z 0.4..1.6; **a solid portal frame on the spine at (5,1), 1.36 m tall**; a plank along the right column; **a solid portal frame on the column at (11,7)**.

So: north door — Kneiphof at 0.9–1.5 m, a bridge deck at 1.35 m, a room wall and a portal on the spine's first cell; south door — Vorstadt at 0.9–1.5 m; the right column cut at (11,7); the travellers inside a room shell. **The hall is sealed to a walker at both ends as it stands.** The museum's walk map cannot see any of it: it reads footprints from the registry (`KonigsbergBridge` 9 cells, `graphspace` 1 cell) and knows nothing of CSG collision. Forum thread 260924-xplku; tasks .015–.018 below.

The chapter is written to the hall's design, not to this. Every sentence in it stays true when the bodies are fixed, except that the candidate says nothing about where Königsberg stands — on purpose — so a fitted model (scale, a plinth, a `#fit`) does not go stale. What the fix cannot be: any scale ≥ 0.04 centred at (6,6) puts the river across the spine at x 5; any scale with the arches overhead (deck ends ≥ 2.2 m) and the river under the floor needs s ≥ 0.85, which does not fit the hall. Königsberg here is a model to look at from above (registry `player_position: "above"`), which means a small scale on a plinth, or a hall-aware build. That is a design decision; the chapter leaves the model's size out.

## 4. Venue

The chapter is written for the museum, which builds this hall from its map (holes are holes, a fall returns you to the door). In the grid lane (`desktop_map_tester`, the map switcher) the `0` cells are ground half a metre below the walkways, the spawn `sp` is at (9,10) on R, and nothing falls — the encounter paragraph is then a description of raised paths, not of a graph with holes. VR is primary and the museum is the game, so this is the venue; the difference is stated here rather than hedged in the prose.

## 5. Tasks

- `.010` (name the tide and the diver) — in.
- `.011` (six chapters close on a backlog paragraph) — the Foundations part is in: the extension became a question.
- New in `doc/tasks/book_graphtheory.json`, source "the edges pilot of 24 Sept": the sealed doors (kind `vr`, event `collision`), the four oversize bodies (kind `vr`, event `scale`), the one-way rides and the sink block R (kind `encounter`, event `threshold` — a decision: it is the Connectivity hall's question arriving early, or a walker trap), the river under the floor (kind `encounter`, event `occlusion` — keep it if the model stays large enough).

## 6. Not done

- Not walked in a headset; the door seal is a probe result and a plan row, not a walk. A physics walk from the seam is the test (`--em-map=GT_Foundations`).
- Not installed, not committed, no map, registry or plan touched. The probe is a new file in `commons/testing/` (uncommitted).

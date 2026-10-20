# The pocket that counts as wall

**State: proposed — nothing has run under this record's identity; the artifact stands in the hall as an uncommitted working-tree placement of 2026-10-13.**

This companion binds two passages of the Algorithmic Bias hall to `filled_pocket`, an artifact that exists in the working tree (`commons/artifacts/filled_pocket/`, untracked) and is placed in the hall's modified `map_data.json` as `filled_pocket:0:0.95`. Neither hall text mentions it; the texts predate the artifact, and the binding depends on that. The record is [experiment.json](./experiment.json). The form follows the [seed-bench pilot](../../random-definition/seed-bench-001/proposition.md), which has since executed — this record has not. See [the book architecture](../../../RECURSIVE_ARCHITECTURE.md).

The [tutorial](../../../../../commons/maps/CriticalAlgorithms_Algorithmic_Bias_Visualization/tutorial.md) passage (`algorithmic-bias.predict-one-change.v1`) says: “Before HALF, predict warm gap 0.32 m and grey gap 0.66 m. Change the authored finish gap in code, predict its midpoint, and check a fresh layout.” It initiates the question whether that predict-then-check discipline carries from authored gaps to authored reachability: from the hand-written character map alone, predict route cost and never-reached free cells before anything runs, then change exactly one authored cell and predict again.

The [final](../../../../../commons/maps/CriticalAlgorithms_Algorithmic_Bias_Visualization/final.md) passage (`algorithmic-bias.presence-vs-distinction.v1`) says: “The words themselves remain. Their colours and brightness stay fixed while the space available to tell them apart changes. Presence in a representation is therefore different from being represented with useful distinctions.” It initiates the limit question the hall's slider never reaches: when a region stays present, coloured and in place, yet no route arrives, does a visitor meet those cells as floor or as wall — and does opening a single door give the region back with no cell's occupancy changing?

Our proposition is conditional: **if presence is counted as the layout's free cells and useful distinction as its reachable cells, then their deficit — the pocket — stages the final's sentence as a discrete fact, and the tutorial's one-change discipline can move that fact with a single authored cell.** The mappings below are readings of that conditional, not its literary meaning. [filled_pocket.gd](../../../../../commons/artifacts/filled_pocket/filled_pocket.gd) is the whole ground truth: hand-written layouts, no RNG, and three probe methods (`route_steps()`, `pocket_cells()`, `reachable_cells()`), so no claim needs pixels.

## Competing interpretations

| ID (roles) | Operational mapping | Assumptions | Exclusions |
| --- | --- | --- | --- |
| `filled-pocket.interp.seal-census` (final) | Presence = the free-cell count of the hand-written layout (83 at wall "ring", door "sealed"); useful distinction = `reachable_cells()`; their deficit = `pocket_cells()`. The final's sentence holds in the artifact exactly when `pocket_cells() > 0` while those same cells are drawn (0.014-high boxes in `pocket_color`) rather than removed. | 4-neighbour adjacency in `_flood()` is the hall-relevant "reach"; the `_layout()` character maps are the whole ground truth (no RNG, so two placements of one token are the same argument); the amber fill is legible as absorbed floor, not merely a third colour. | No claim about trained embeddings, measured social data, or the hall's own six words — a route-level analogy, exactly as the final's exhibit is an authored analogy; counts, not experience; door held at "sealed". |
| `filled-pocket.interp.door-drains` (tutorial + final) | "Change one thing" / "give the region back" = the door axis: at wall "ring", move door from "sealed" to "single", which per `_door_cells()` frees exactly Vector2i(5, 2) — a `#` in ring row 2, so `_door_mattered` becomes true. Predicted (labelled prediction, nothing run): `pocket_cells()` 9 -> 0, `reachable_cells()` 74 -> 84, `route_steps()` unchanged at 14, verdict changing from "POCKET: %d cells sealed -- filled" to "every free cell reachable" with no "(the door names open floor)" suffix. | `apply_grid_config` lower-cases and validates against `DOORS`, so "single" is carried, not silently refused; BFS tie-breaking cannot shorten the route — with one door and no right-side opening the through-door path dead-ends for y, so the 14-step detour stands; both setters call `_rebuild()`, so set order cannot mask a value. | door "double" excluded (second cell Vector2i(4, 2) not exercised); wall "open" and "u_bend" excluded — there the door names cells that are already floor and the axis is conditional by the artifact's own comment; no claim that the route gets shorter. |
| `filled-pocket.interp.severed-route` (tutorial) | The far end of "the space available to tell them apart" = route existence: wall "split", door "sealed" places a full-height `#` column at x = 5. Predicted from the layout strings alone: the flood from x never reaches y, `route_steps()` returns -1 (the empty-route sentinel), the verdict begins "NO ROUTE", and `pocket_cells()` counts y's entire stranded half. The tutorial's continuously measurable separation becomes a binary the program can still measure. | The split layout's column 5 is `#` in all 9 rows as written, leaving no gap; -1 is read as "no route", per the method body `_route.size() - 1 if not _route.is_empty() else -1`. | Not part of the bounded comparison — a second changed condition (wall) would break the one-change rule; no gradual-compression analogue, since the artifact has no continuous blend export; no claim about which half a visitor identifies with. |

## Bounded comparison

Baseline: wall "ring", door "sealed" — both are the export defaults as spelled in the .gd — with cell 0.036 and show_readout true. Single change: door "sealed" -> "single", via the @export setter or `apply_grid_config({"door": "single"})`. Per `_door_cells()` at ring this frees exactly one cell, Vector2i(5, 2).

Held fixed: wall "ring"; cell 0.036; show_readout; the five colour exports at their defaults; the hand-written `_layout()` strings (no RNG anywhere in the artifact); start x and goal y read from the layout at (0,3) and (10,3); `const W := 11` and `const H := 9`; the 4-neighbour flood and the parent-chain route reconstruction. Defaults stay sacred: the comparison changes one axis value, once.

## Invented arithmetic fixture

**An invented pen-and-paper calculation, not output.** Every number here is derived by hand from the .gd alone — none is taken from the registry description, any measured_* block, or any past probe or capture. Where a number coincides with a registry phrase (the interior is 9 cells there too, and the registry's measured U-route cost of 14 equals the ring route derived here, because ring and u_bend share every route-blocking cell outside the mouth), the authority is the arithmetic shown. All expected values are predictions.

Board: W*H = 11*9 = 99 cells. Ring walls counted off the layout strings: row 2 has 5 `#` (cols 3-7), rows 3-5 have 2 each (cols 3 and 7), row 6 has 5 — 5+2+2+2+5 = 16 walls, so free = 99-16 = 83. The enclosed interior is cols 4-6 x rows 3-5 = 3*3 = 9 free cells walled on all four sides, so the flood from x(0,3) reaches 83-9 = 74 and the pocket is 9. Route: row 3 is blocked at (3,3)/(7,3) and row 2 at cols 3-7, so any x->y path must cross on row 1 (or symmetrically row 7): at least 2 up + 10 across + 2 down = 14; achieved by (0,3)->(2,3)->(2,1)->(8,1)->(8,3)->(10,3) = 2+2+6+2+2 = 14, so BFS returns 14 regardless of tie-breaking. Door "single" frees (5,2): walls 16-1 = 15, free 83+1 = 84; the interior drains through (5,2)->(5,1), so reachable = 84 and pocket = 0; with no second opening in the right wall the through-door path dead-ends for y, so the route stays 14. Marker: `_at(Vector2i(0,3), 0.016)` gives x = (0-5)*0.036 = -0.18, z = (3-4)*0.036 = -0.036.

Predictions, labelled as such: sealed baseline — `route_steps()` 14, `pocket_cells()` 9, `reachable_cells()` 74, plate reading "ROUTE: 14 steps" then "POCKET: 9 cells sealed -- filled". Door "single" — 14, 0, 84, plate reading "ROUTE: 14 steps" then "every free cell reachable", with no "(the door names open floor)" line because `_door_mattered` is true at ring. Geometry — the x marker's local position is (-0.18, 0.016, -0.036) metres.

## What could change the work

- A hand recount of the ring layout gives other than 16 wall / 83 free / 9 interior, or a shorter-than-14 route is exhibited: the whole fixture is wrong and must be rebuilt before any run is scored against it.
- A live probe at wall "ring" disagrees with the fixture (e.g. door "single" fails to drain the pocket): test the handoff before the artifact — check `_rejects.json` and setter order before concluding anything about the design.
- The hall texts are revised to mention `filled_pocket` (tutorial.md is already dirty in the working tree): the premise that the texts predate the artifact fails, and both excerpts must be re-selected against the new bytes.
- In the headset the amber pocket reads as decoration or a third team colour rather than floor absorbed into wall: the final-role encounter question stays unresolved, and a rendering interpretation becomes its own experiment rather than a repair.
- The flood's neighbour set changes or `_layout()` is edited: "reach" no longer matches the hall's floor metaphor as mapped, and all three interpretations need remapping, not just renumbering.

## The cycle, as planned future work

1. Instantiate the baseline (the shipped defaults) and state all three counts and the plate text before reading any of them — the fixture above is that statement.
2. Change only door to "single"; touch nothing else.
3. Compare the three probe methods and the plate against the fixture; record agreement, divergence, or failure, each as a distinct finding.
4. Keep the probe output as a receipt bound to this record's IDs, with command, build and hashes.
5. Replay from a fresh process; the layouts carry no RNG, so a replay must agree exactly.
6. Independent reconstruction: a reader recounts the ring layout by hand and exhibits the 14-step route, or a shorter one, without this record's arithmetic.
7. Review tutorial and final separately — revise, retain with reasons, or keep the question open — and select, defer or stop the next experiment from what was observed.

## What remains open

Execution; observation; the tutorial review; the final review; a human encounter in the hall; independent reconstruction. The [text simulation](text-simulation.md) is hypothetical, the [observation log](observations.md) is empty, and [revision](revision.md) holds both reviews as pending.

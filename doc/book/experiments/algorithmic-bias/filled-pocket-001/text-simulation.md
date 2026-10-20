# A hypothetical trace of the pocket and the door

**Text thought experiment. Not executed in Godot; no visitor has been observed through this record.** This is an authored prediction using the [proposition's](proposition.md) invented fixture; every number below is hand arithmetic, not output.

| Step | Assumed action/state | Predicted consequence | What execution must establish |
| --- | --- | --- | --- |
| 0 | Instantiate `filled_pocket.tscn` at the shipped defaults (wall "ring", door "sealed") | Nine interior cells drawn amber at 0.014 height; plate reads "ROUTE: 14 steps" then "POCKET: 9 cells sealed -- filled" | That the node builds standalone, and the exact plate bytes |
| 1 | Read the three probe methods | `route_steps()` 14, `pocket_cells()` 9, `reachable_cells()` 74 | That the methods agree with the drawn scene, not only with the fixture |
| 2 | `apply_grid_config({"door": "single"})`, wait a frame | (5,2) freed; pocket 9 -> 0, reachable 74 -> 84, route stays 14; plate flips to "every free cell reachable" with no door-suffix | The setter path end to end, `_door_mattered`, and the rebuild frame |
| 3 | Return door to "sealed" | Counts return to 14 / 9 / 74 — the layouts are deterministic, no RNG | That the rebuild is stateless, with no residue from the opened door |
| 4 | A visitor stands at the hall's uncommitted placement | The amber reads as perfectly good floor that is wall — the artifact's desire line | A human account via bridge SEND; this record claims nothing about it |
| 5 | Return to tutorial, final and the record | Each text may be revised, retained with reasons, or kept open | Separate evidence-linked reviews of both texts |

A counter-trace is equally useful, as hypotheses rather than events: a typed `set()` elsewhere in the chain could be refused in silence, so the probe must read the `door` value back after setting it rather than trust the call; `_rebuild()` uses `queue_free()`, so a probe counting children in the same frame would see two generations at once; the plate is billboarded but the whole board could face away from the hall approach; the 0.014-high pocket boxes could read as decoration in a headset; and the placement `filled_pocket:0:0.95` could stand on unreachable floor or collide with the existing distinctions bench. None of these has occurred in any recorded run, because there is no recorded run.

[The observation log](observations.md) stays empty until evidence exists.

# GT_Pathfinding

Authored dimensions: {"width": 13, "depth": 14, "max_height": 5}

![Source plan](GT_Pathfinding.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/GT_Pathfinding/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/GT_Pathfinding/map_data.json)

Text: [commons/maps/GT_Pathfinding/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/GT_Pathfinding/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 9,2 | `salesman_knot` | unassigned | [commons/artifacts/registry/salesman_knot.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/salesman_knot.json) → [commons/artifacts/salesman_knot/salesman_knot.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/salesman_knot/salesman_knot.tscn) |
| A2 | 11,2 | `grid_substrate_runner` | secondary | [commons/artifacts/registry/cellular_automata.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/cellular_automata.json) → [commons/grid/mutators/grid_substrate_runner.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/grid/mutators/grid_substrate_runner.tscn) |
| A3 | 3,4 | `pathfinding3d:0:0:0.6` | secondary | [commons/artifacts/registry/algorithms_misc.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/algorithms_misc.json) → [algorithms/graphtheory/pathfinding3d/pathfinding3d.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/graphtheory/pathfinding3d/pathfinding3d.tscn) |
| A4 | 9,5 | `family_chandelier` | secondary | [commons/artifacts/registry/graphtheory.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/graphtheory.json) → [commons/artifacts/family_chandelier/family_chandelier.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/family_chandelier/family_chandelier.tscn) |
| A5 | 10,9 | `impatient_river` | primary | [commons/artifacts/registry/graphtheory.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/graphtheory.json) → [commons/artifacts/impatient_river/impatient_river.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/impatient_river/impatient_river.tscn) |
| A6 | 11,12 | `living_paper_dfs_maze` | secondary | [commons/artifacts/registry/living_paper.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/living_paper.json) → [commons/substrates/living_paper/living_paper.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/substrates/living_paper/living_paper.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. `utility-index.json` resolves active codes to the literal utility registry and scene, separately from the ordinary artifact registry. Their scene sources and the grid/museum dispatch context are included. Unresolved/special dispatch stays explicitly labelled. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

# GT_Flow

Authored dimensions: {"width": 13, "depth": 12, "max_height": 5}

![Source plan](GT_Flow.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/GT_Flow/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/GT_Flow/map_data.json)

Text: [commons/maps/GT_Flow/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/GT_Flow/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 2,1 | `grid3d_dfs` | secondary | [commons/artifacts/registry/grid3d.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/grid3d.json) → [commons/substrates/grid3d/grid3d_substrate.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/substrates/grid3d/grid3d_substrate.tscn) |
| A2 | 10,1 | `grid3d_prim` | secondary | [commons/artifacts/registry/grid3d.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/grid3d.json) → [commons/substrates/grid3d/grid3d_substrate.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/substrates/grid3d/grid3d_substrate.tscn) |
| A3 | 3,3 | `karger_algorithm:0:0:0.6` | secondary | [commons/artifacts/registry/algorithms_misc.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/algorithms_misc.json) → [algorithms/graphtheory/karger_algorithm/karger_algorithm.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/graphtheory/karger_algorithm/karger_algorithm.tscn) |
| A4 | 4,4 | `push_relabel_algorithm:0:1.2:0.6` | primary | [commons/artifacts/registry/algorithms_misc.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/algorithms_misc.json) → [algorithms/graphtheory/push_relabel/push_relabel.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/graphtheory/push_relabel/push_relabel.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. `utility-index.json` resolves active codes to the literal utility registry and scene, separately from the ordinary artifact registry. Their scene sources and the grid/museum dispatch context are included. Unresolved/special dispatch stays explicitly labelled. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

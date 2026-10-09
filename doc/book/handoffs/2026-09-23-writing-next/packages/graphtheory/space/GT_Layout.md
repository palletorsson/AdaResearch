# GT_Layout

Authored dimensions: {"width": 15, "depth": 13, "max_height": 5}

![Source plan](GT_Layout.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/GT_Layout/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/GT_Layout/map_data.json)

Text: [commons/maps/GT_Layout/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/GT_Layout/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 2,3 | `living_paper_bfs` | secondary | [commons/artifacts/registry/living_paper.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/living_paper.json) → [commons/substrates/living_paper/living_paper.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/substrates/living_paper/living_paper.tscn) |
| A2 | 4,5 | `force_directed_layout:0:0:0.6` | primary | [commons/artifacts/registry/algorithms_misc.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/algorithms_misc.json) → [algorithms/graphtheory/force_directed_layout/force_directed_layout.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/graphtheory/force_directed_layout/force_directed_layout.tscn) |
| A3 | 12,6 | `graph_basilica` | secondary | [commons/artifacts/registry/concept_architecture.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/concept_architecture.json) → [commons/artifacts/graph_basilica/graph_basilica.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/graph_basilica/graph_basilica.tscn) |
| A4 | 10,8 | `forcedirected3d` | secondary | [commons/artifacts/registry/algorithms_misc.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/algorithms_misc.json) → [algorithms/graphtheory/forcedirected3d/forcedirected3d.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/graphtheory/forcedirected3d/forcedirected3d.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. `utility-index.json` resolves active codes to the literal utility registry and scene, separately from the ordinary artifact registry. Their scene sources and the grid/museum dispatch context are included. Unresolved/special dispatch stays explicitly labelled. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

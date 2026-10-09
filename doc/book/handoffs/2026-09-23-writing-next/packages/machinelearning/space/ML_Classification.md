# ML_Classification

Authored dimensions: {"width": 15, "depth": 19, "max_height": 3}

![Source plan](ML_Classification.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/ML_Classification/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/ML_Classification/map_data.json)

Text: [commons/maps/ML_Classification/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/ML_Classification/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 7,4 | `enhanced_kmeans:0:0.15:0.2#natural_cluster_count:3#lesson_controls:on` | primary | [commons/artifacts/registry/machinelearning.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/machinelearning.json) → [algorithms/machinelearning/kmeansclustering/enhanced_kmeans.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/machinelearning/kmeansclustering/enhanced_kmeans.tscn) |
| A2 | 6,11 | `svm_visualization:0:0:0.6#desktop_ui:off` | secondary | [commons/artifacts/registry/machinelearning.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/machinelearning.json) → [algorithms/machinelearning/supportvectormachine/svm_visualization.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/machinelearning/supportvectormachine/svm_visualization.tscn) |
| A3 | 10,12 | `random_forest_visualization:0:0:0.6#desktop_ui:off` | secondary | [commons/artifacts/registry/machinelearning.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/machinelearning.json) → [algorithms/machinelearning/randomforest/random_forest_visualization.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/machinelearning/randomforest/random_forest_visualization.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. `utility-index.json` resolves active codes to the literal utility registry and scene, separately from the ordinary artifact registry. Their scene sources and the grid/museum dispatch context are included. Unresolved/special dispatch stays explicitly labelled. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

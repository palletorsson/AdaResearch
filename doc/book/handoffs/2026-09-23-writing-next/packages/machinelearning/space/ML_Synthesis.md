# ML_Synthesis

Authored dimensions: {"width": 13, "depth": 12, "max_height": 3}

![Source plan](ML_Synthesis.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/ML_Synthesis/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/ML_Synthesis/map_data.json)

Text: [commons/maps/ML_Synthesis/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/ML_Synthesis/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 2,2 | `anomaly_detection:0:2:0.6` | primary | [commons/artifacts/registry/machinelearning.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/machinelearning.json) → [algorithms/machinelearning/anomaly_detection/anomaly_detection.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/machinelearning/anomaly_detection/anomaly_detection.tscn) |
| A2 | 6,2 | `joint_learn_walk:0:2:0.6` | secondary | [commons/artifacts/registry/machinelearning.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/machinelearning.json) → [algorithms/machinelearning/reinforcementlearning/joint_learn_walk.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/machinelearning/reinforcementlearning/joint_learn_walk.tscn) |
| A3 | 2,7 | `explainable_ai_xai_vr:0:2:0.6` | secondary | [commons/artifacts/registry/machinelearning.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/machinelearning.json) → [algorithms/machinelearning/explainable_AI_XAI/ExplainableAIXAI_VR.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/machinelearning/explainable_AI_XAI/ExplainableAIXAI_VR.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. `utility-index.json` resolves active codes to the literal utility registry and scene, separately from the ordinary artifact registry. Their scene sources and the grid/museum dispatch context are included. Unresolved/special dispatch stays explicitly labelled. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

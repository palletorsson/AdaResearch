# QFEP_E_Term

Authored dimensions: {"width": 14, "depth": 14, "max_height": 1}

![Source plan](QFEP_E_Term.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/QFEP_E_Term/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/QFEP_E_Term/map_data.json)

Text: [commons/maps/QFEP_E_Term/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/QFEP_E_Term/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 2,2 | `tt:180:entropy_axioms:180:0.5` | secondary | [commons/artifacts/registry/commons_artifacts.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/commons_artifacts.json) → [commons/context/clipboard/codeDisplay.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/context/clipboard/codeDisplay.tscn) |
| A2 | 2,5 | `microstate_counter:180:0:1` | secondary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/artifacts/microstate_counter/microstate_counter.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/microstate_counter/microstate_counter.tscn) |
| A3 | 6,5 | `entropy_fan:180:0:1#visitor_control:on` | primary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/artifacts/entropy_fan/entropy_fan.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/entropy_fan/entropy_fan.tscn) |
| A4 | 10,5 | `possibility_space_cloud:180:0:1` | secondary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/artifacts/possibility_space_cloud/possibility_space_cloud.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/possibility_space_cloud/possibility_space_cloud.tscn) |
| A5 | 2,8 | `random_cubes:0:0.5:0.5` | secondary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/interfaces/qfep/random_cubes.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/qfep/random_cubes.tscn) |
| A6 | 3,10 | `particle_chaos:0:1:0.35` | secondary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/interfaces/qfep/particle_chaos.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/qfep/particle_chaos.tscn) |
| A7 | 10,10 | `lambda_slider:180:0:1#calibration:none` | secondary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/interfaces/qfep/lambda_slider.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/qfep/lambda_slider.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. `utility-index.json` resolves active codes to the literal utility registry and scene, separately from the ordinary artifact registry. Their scene sources and the grid/museum dispatch context are included. Unresolved/special dispatch stays explicitly labelled. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

# QFEP_Sandbox

Authored dimensions: {"width": 14, "depth": 16, "max_height": 4}

![Source plan](QFEP_Sandbox.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/QFEP_Sandbox/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/QFEP_Sandbox/map_data.json)

Text: [commons/maps/QFEP_Sandbox/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/QFEP_Sandbox/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 2,2 | `tt:180:qfep_mastery:180:0.5` | secondary | [commons/artifacts/registry/commons_artifacts.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/commons_artifacts.json) → [commons/context/clipboard/codeDisplay.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/context/clipboard/codeDisplay.tscn) |
| A2 | 5,5 | `lambda_slider:180:0:1#calibration:none` | primary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/interfaces/qfep/lambda_slider.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/qfep/lambda_slider.tscn) |
| A3 | 8,5 | `phi_slider:180:0.1:1#sign_study:on#phi:0` | primary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/interfaces/qfep/phi_slider.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/qfep/phi_slider.tscn) |
| A4 | 7,9 | `qfep_reactor:180:0.3:1#wiring_study:on` | primary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/interfaces/qfep/qfep_reactor.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/qfep/qfep_reactor.tscn) |
| A5 | 3,11 | `reactive_particles:0:1:1#field_seed:401` | secondary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/interfaces/qfep/reactive_particle_field.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/qfep/reactive_particle_field.tscn) |
| A6 | 11,12 | `qfep_formula_3d:180:0.05:1` | secondary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/interfaces/qfep/formula_display/qfep_formula_3d.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/qfep/formula_display/qfep_formula_3d.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. `utility-index.json` resolves active codes to the literal utility registry and scene, separately from the ordinary artifact registry. Their scene sources and the grid/museum dispatch context are included. Unresolved/special dispatch stays explicitly labelled. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

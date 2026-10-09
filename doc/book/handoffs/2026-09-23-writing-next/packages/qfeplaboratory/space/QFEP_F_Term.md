# QFEP_F_Term

Authored dimensions: {"width": 10, "depth": 12, "max_height": 3}

![Source plan](QFEP_F_Term.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/QFEP_F_Term/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/QFEP_F_Term/map_data.json)

Text: [commons/maps/QFEP_F_Term/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/QFEP_F_Term/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 1,1 | `tt:180:free_energy:180:0.5` | secondary | [commons/artifacts/registry/commons_artifacts.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/commons_artifacts.json) → [commons/context/clipboard/codeDisplay.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/context/clipboard/codeDisplay.tscn) |
| A2 | 2,2 | `lambda_slider:180:0.5#calibration:none` | secondary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/interfaces/qfep/lambda_slider.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/qfep/lambda_slider.tscn) |
| A3 | 8,2 | `science_screen:180:1.5#mode:scatter` | secondary | [commons/artifacts/registry/shaders.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/shaders.json) → [commons/artifacts/science_screen/science_screen.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/science_screen/science_screen.tscn) |
| A4 | 4,4 | `shannon_workbench:180:0#prediction_study:on#initial_p:0.1` | primary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/artifacts/shannon_workbench/shannon_workbench.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/shannon_workbench/shannon_workbench.tscn) |
| A5 | 1,6 | `dark_sphere` | decoration | [commons/artifacts/registry/lsystems.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lsystems.json) → [commons/artifacts/dark_sphere/dark_sphere.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/dark_sphere/dark_sphere.tscn) |
| A6 | 2,8 | `snap_octahedron_puzzle:0:0.3` | secondary | [commons/artifacts/registry/primitives.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/primitives.json) → [commons/primitives/snappoint/puzzles/snap_octahedron_puzzle.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/primitives/snappoint/puzzles/snap_octahedron_puzzle.tscn) |
| A7 | 7,8 | `snap_tetrahedron_puzzle:0:0.3` | secondary | [commons/artifacts/registry/primitives.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/primitives.json) → [commons/primitives/snappoint/puzzles/snap_tetrahedron_puzzle.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/primitives/snappoint/puzzles/snap_tetrahedron_puzzle.tscn) |
| A8 | 1,9 | `crystal_cluster:0:0.8` | secondary | [commons/artifacts/registry/qfep.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/qfep.json) → [commons/primitives/crystalcluster/crystalcluster.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/primitives/crystalcluster/crystalcluster.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. `utility-index.json` resolves active codes to the literal utility registry and scene, separately from the ordinary artifact registry. Their scene sources and the grid/museum dispatch context are included. Unresolved/special dispatch stays explicitly labelled. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

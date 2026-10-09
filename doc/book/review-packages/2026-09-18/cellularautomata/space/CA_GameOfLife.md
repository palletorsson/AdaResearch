# CA_GameOfLife

Authored dimensions: {"width": 15, "depth": 37, "max_height": 5}

![Source plan](CA_GameOfLife.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/CA_GameOfLife/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/CA_GameOfLife/map_data.json)

Text: [commons/maps/CA_GameOfLife/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/CA_GameOfLife/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 6,5 | `ca_bridge:0:0#study:history#plinth:0` | primary | [commons/artifacts/registry/cellular_automata.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/cellular_automata.json) → [algorithms/cellularautomata/ca_bridge/ca_bridge.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/cellularautomata/ca_bridge/ca_bridge.tscn) |
| A2 | 6,22 | `lab_room#room_width:8.0#room_depth:7.0#room_height:3.8#south_wall_is_glass:false#show_back_window:true#back_window_size:6.5,2.4#show_front_window:true#front_window_size:1.4,0.7#front_window_offset_x:-2.4#front_window_y:2.55#show_sliding_door:true#door_wall:east#door_width:1.5#door_height:2.2#door_sensor_radius:2.6#accent_color:0.227,0.482,1.0#signage_top:TURING MACHINE LAB#signage_sub:Rule 110 → universal computation#annotation_top:M = (Q, Σ, Γ, δ, q0, F) — Game of Life is Turing complete#annotation_bottom:belt = Γ*, panel = q, server rack = δ, button = HALT#mounted_artifact_scene:res://commons/artifacts/turing_apparatus/turing_apparatus.tscn` | secondary | [commons/artifacts/registry/lab.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lab.json) → [commons/artifacts/lab_room/lab_room.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/lab_room/lab_room.tscn) |
| A3 | 5,25 | `dark_sphere` | decoration | [commons/artifacts/registry/lsystems.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lsystems.json) → [commons/artifacts/dark_sphere/dark_sphere.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/dark_sphere/dark_sphere.tscn) |
| A4 | 5,26 | `ca_columns:0:-0.5:0.2` | secondary | [commons/artifacts/registry/cellular_automata.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/cellular_automata.json) → [algorithms/cellularautomata/ca_columns/ca_columns.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/cellularautomata/ca_columns/ca_columns.tscn) |
| A5 | 6,32 | `mirrored_cellular_automata:0:-0.5` | secondary | [commons/artifacts/registry/cellular_automata.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/cellular_automata.json) → [algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirror_cellular_texture_for_3d.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirror_cellular_texture_for_3d.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

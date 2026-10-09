# LSystems_Architecture

Authored dimensions: {"width": 19, "depth": 39, "max_height": 6}

![Source plan](LSystems_Architecture.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/LSystems_Architecture/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/LSystems_Architecture/map_data.json)

Text: [commons/maps/LSystems_Architecture/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/LSystems_Architecture/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 9,7 | `lsystem_dungeon:180#lesson:true` | primary | [commons/artifacts/registry/lsystems.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lsystems.json) → [commons/artifacts/lsystem_dungeon/lsystem_dungeon.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/lsystem_dungeon/lsystem_dungeon.tscn) |
| A2 | 4,24 | `catalyst_vent:0:0#emit_interval_s:2.5#wave_size:3#start_delay_s:5.0#sequence:auto` | secondary | [commons/artifacts/registry/hazards.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/hazards.json) → [commons/hazards/catalyst_foe/catalyst_vent.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/hazards/catalyst_foe/catalyst_vent.tscn) |
| A3 | 13,24 | `mesh_grammar_petal_flower` | secondary | [commons/artifacts/registry/mesh_grammar.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/mesh_grammar.json) → [commons/mesh_grammar/mesh_grammar_node.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/mesh_grammar/mesh_grammar_node.tscn) |
| A4 | 8,25 | `dark_sphere` | decoration | [commons/artifacts/registry/lsystems.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lsystems.json) → [commons/artifacts/dark_sphere/dark_sphere.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/dark_sphere/dark_sphere.tscn) |
| A5 | 12,26 | `dragon_room` | secondary | [commons/artifacts/registry/lsystems.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lsystems.json) → [commons/artifacts/dragon_room/dragon_room.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/dragon_room/dragon_room.tscn) |
| A6 | 6,27 | `CityGenerator` | secondary | [commons/artifacts/registry/lsystems.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lsystems.json) → [algorithms/lsystems/Architecture/CityGenerator.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/lsystems/Architecture/CityGenerator.tscn) |
| A7 | 6,29 | `grammar_seed` | secondary | [commons/artifacts/registry/lsystems.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lsystems.json) → [algorithms/lsystems/grammar_seed/grammar_seed.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/lsystems/grammar_seed/grammar_seed.tscn) |
| A8 | 7,31 | `catalyst_prompter_box:0:0#emergence:vent#sequence:auto#lease_s:45` | secondary | [commons/artifacts/registry/hazards.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/hazards.json) → [commons/hazards/becoming_catalyst/catalyst_prompter_box.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/hazards/becoming_catalyst/catalyst_prompter_box.tscn) |
| A9 | 14,31 | `mesh_grammar_coral_fingers` | secondary | [commons/artifacts/registry/mesh_grammar.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/mesh_grammar.json) → [commons/mesh_grammar/mesh_grammar_node.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/mesh_grammar/mesh_grammar_node.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

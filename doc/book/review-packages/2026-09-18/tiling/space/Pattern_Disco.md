# Pattern_Disco

Authored dimensions: {"width": 19, "depth": 23, "max_height": 6}

![Source plan](Pattern_Disco.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/Pattern_Disco/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Pattern_Disco/map_data.json)

Text: [commons/maps/Pattern_Disco/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Pattern_Disco/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 9,4 | `disco_controls#mode:colour` | primary | [commons/artifacts/registry/disco_controls.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/disco_controls.json) → [commons/artifacts/regularity/disco_controls.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/regularity/disco_controls.tscn) |
| A2 | 3,5 | `step_sequencer:180:1.2:1.2#sound_preset:90s_house` | primary | [commons/artifacts/registry/arrays.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/arrays.json) → [commons/audio/sequencer/step_sequencer.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/audio/sequencer/step_sequencer.tscn) |
| A3 | 9,13 | `standalone_disco#width:12#depth:12#tile_size:0.8#floor_y_offset:0#walkable:true` | primary | [commons/artifacts/registry/commons_artifacts.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/commons_artifacts.json) → [commons/context/discofloor/standalone_disco_floor.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/context/discofloor/standalone_disco_floor.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

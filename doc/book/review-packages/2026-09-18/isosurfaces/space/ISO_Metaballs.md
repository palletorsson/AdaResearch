# ISO_Metaballs

Authored dimensions: {"width": 30, "depth": 32, "max_height": 8}

![Source plan](ISO_Metaballs.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/ISO_Metaballs/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/ISO_Metaballs/map_data.json)

Text: [commons/maps/ISO_Metaballs/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/ISO_Metaballs/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 15,5 | `iso_metaball_console:0` | decoration | [commons/artifacts/registry/isosurfaces.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/isosurfaces.json) → [commons/artifacts/timing_machines/iso_metaball_workshop.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/timing_machines/iso_metaball_workshop.tscn) |
| A2 | 15,14 | `metaball_world:0:0:0.2` | primary | [commons/artifacts/registry/isosurfaces.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/isosurfaces.json) → [algorithms/proceduralgeneration/hybrid_complex/metaballgenerator/metaballworld.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/proceduralgeneration/hybrid_complex/metaballgenerator/metaballworld.tscn) |
| A3 | 7,22 | `raymarched_metaballs:0:0:0.2` | secondary | [commons/artifacts/registry/isosurfaces.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/isosurfaces.json) → [algorithms/proceduralgeneration/isosurfaces/implicitsurfacemodeling/metaballs/metaballs.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/proceduralgeneration/isosurfaces/implicitsurfacemodeling/metaballs/metaballs.tscn) |
| A4 | 23,22 | `nakama_metaballs:0:0:0.2` | secondary | [commons/artifacts/registry/isosurfaces.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/isosurfaces.json) → [algorithms/proceduralgeneration/isosurfaces/metaballs/nakama_metaballs.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/proceduralgeneration/isosurfaces/metaballs/nakama_metaballs.tscn) |
| A5 | 15,28 | `metaballs:0:2` | secondary | [commons/artifacts/registry/procgen_extra.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/procgen_extra.json) → [algorithms/proceduralgeneration/isosurfaces/implicitsurfacemodeling/metaballs/metaballs.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/proceduralgeneration/isosurfaces/implicitsurfacemodeling/metaballs/metaballs.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

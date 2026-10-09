# Noise_Perlin_Simplex

Authored dimensions: {"width": 13, "depth": 15, "max_height": 3}

![Source plan](Noise_Perlin_Simplex.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/Noise_Perlin_Simplex/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Noise_Perlin_Simplex/map_data.json)

Text: [commons/maps/Noise_Perlin_Simplex/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Noise_Perlin_Simplex/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 3,7 | `simplex_noise:0:1.1#seed:20260910#size:8#ramp:shared#panel:front#frequency:10#amplitude:0.8#persistence:0.5#octaves:4#witness:show#study:compare` | primary | [commons/artifacts/registry/randomness.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/randomness.json) → [algorithms/randomness/simplexnoise/simplexnoise.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/randomness/simplexnoise/simplexnoise.tscn) |
| A2 | 8,7 | `perlin_noise:0:1.1#generator:perlin#seed:20260910#size:8#ramp:shared#panel:front#frequency:10#amplitude:0.8#persistence:0.5#octaves:4` | primary | [commons/artifacts/registry/randomness.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/randomness.json) → [algorithms/randomness/perlinnoise/perlinnoise.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/randomness/perlinnoise/perlinnoise.tscn) |
| A3 | 2,11 | `perlin_noise_terrain:0:1.0` | primary | [commons/artifacts/registry/randomness.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/randomness.json) → [algorithms/randomness/noise/perlinnoise/scenes/perlin_noise_terrain.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/randomness/noise/perlinnoise/scenes/perlin_noise_terrain.tscn) |
| A4 | 6,11 | `dark_sphere` | primary | [commons/artifacts/registry/lsystems.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lsystems.json) → [commons/artifacts/dark_sphere/dark_sphere.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/dark_sphere/dark_sphere.tscn) |
| A5 | 9,13 | `configurable_portal#dest_map:Lab_Path#label:Lab Path - not connected#active:false` | secondary | [commons/artifacts/registry/furniture.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/furniture.json) → [commons/scenes/mapobjects/configurable_portal.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/scenes/mapobjects/configurable_portal.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

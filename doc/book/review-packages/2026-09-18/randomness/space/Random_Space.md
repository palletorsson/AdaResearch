# Random_Space

Authored dimensions: {"width": 13, "depth": 16, "max_height": 5}

![Source plan](Random_Space.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/Random_Space/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Random_Space/map_data.json)

Text: [commons/maps/Random_Space/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Random_Space/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 4,3 | `noise_mixer:0:-0.5` | primary | [commons/artifacts/registry/randomness.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/randomness.json) → [commons/artifacts/noise_mixer/noise_mixer.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/noise_mixer/noise_mixer.tscn) |
| A2 | 8,4 | `worley_noise:0:-0.5` | secondary | [commons/artifacts/registry/randomness.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/randomness.json) → [commons/artifacts/worley_noise/worley_noise.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/worley_noise/worley_noise.tscn) |
| A3 | 6,6 | `random_space:0:-0.3:1.4` | secondary | [commons/artifacts/registry/commons_artifacts.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/commons_artifacts.json) → [commons/context/walkgrids/random_space.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/context/walkgrids/random_space.tscn) |
| A4 | 5,7 | `dark_sphere` | decoration | [commons/artifacts/registry/lsystems.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lsystems.json) → [commons/artifacts/dark_sphere/dark_sphere.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/dark_sphere/dark_sphere.tscn) |
| A5 | 4,9 | `shannon_entropy_meter:0:-0.5` | secondary | [commons/artifacts/registry/randomness.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/randomness.json) → [commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

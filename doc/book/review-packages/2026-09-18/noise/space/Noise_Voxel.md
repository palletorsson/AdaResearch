# Noise_Voxel

Authored dimensions: {"width": 15, "depth": 16, "max_height": 3}

![Source plan](Noise_Voxel.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/Noise_Voxel/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Noise_Voxel/map_data.json)

Text: [commons/maps/Noise_Voxel/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Noise_Voxel/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 9,4 | `science_screen:180#mode:voxel_slice#support:stand#screen_width:2.8#screen_height:1.8` | primary | [commons/artifacts/registry/shaders.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/shaders.json) → [commons/artifacts/science_screen/science_screen.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/science_screen/science_screen.tscn) |
| A2 | 4,7 | `perlin_terrain_sculptor:180:1.35:1#stand:lattice#seed:31415` | primary | [commons/artifacts/registry/commons_artifacts.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/commons_artifacts.json) → [commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.tscn) |
| A3 | 9,9 | `voxelnoise#stand:volume` | primary | [commons/artifacts/registry/randomness.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/randomness.json) → [algorithms/randomness/voxelnoise/voxelnoise.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/randomness/voxelnoise/voxelnoise.tscn) |
| A4 | 4,12 | `dark_sphere` | primary | [commons/artifacts/registry/lsystems.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/lsystems.json) → [commons/artifacts/dark_sphere/dark_sphere.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/dark_sphere/dark_sphere.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

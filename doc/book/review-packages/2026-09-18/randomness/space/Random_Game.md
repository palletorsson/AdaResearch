# Random_Game

Authored dimensions: {"width": 19, "depth": 52, "max_height": 9}

![Source plan](Random_Game.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/Random_Game/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Random_Game/map_data.json)

Text: [commons/maps/Random_Game/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Random_Game/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 9,6 | `r_c:0:3#stand:chasm#cue:advance#controls:compact#control_front:-2.6#control_facing:-z#control_height:1.38#control_floor:0.28#control_fixed:true` | primary | [commons/artifacts/registry/random_cubes.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/random_cubes.json) → [commons/primitives/cubes/random_cycle_cube.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/primitives/cubes/random_cycle_cube.tscn) |
| A2 | 9,17 | `random_removal_arena:0:3#columns:9#rows:9#glass_width:11#glass_depth:11#glass_height:4.5#glass_title:THE SET UNDERFOOT#glass_grid:false#controls:compact#control_front:-6.0#control_facing:-z` | primary | [commons/artifacts/registry/randomness.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/randomness.json) → [commons/artifacts/randomness_space/removal_arena.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/randomness_space/removal_arena.tscn) |
| A3 | 9,29 | `random_doors#controls:compact#control_front:-4.0#control_facing:-z` | primary | [commons/artifacts/registry/randomness.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/randomness.json) → [commons/artifacts/randomness_space/random_doors.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/randomness_space/random_doors.tscn) |
| A4 | 9,37 | `cube_projectile_spawner#mode:field#field_size:8x8#field_height:8#fall_min:1.6#fall_max:2.6#drift:0.25#jitter:0.25#jitter_interval:0.45#vertical_variation:0.2#spawn_interval:0.5#max_projectiles:24#stand:field#controls:compact#control_front:-5.0#control_facing:-z` | primary | [commons/artifacts/registry/primitives.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/primitives.json) → [commons/primitives/cubes/cube_spawner.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/primitives/cubes/cube_spawner.tscn) |
| A5 | 9,47 | `waiting_profile#controls:compact#control_front:-1.7#control_facing:-z` | secondary | [commons/artifacts/registry/randomness.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/randomness.json) → [commons/artifacts/randomness_space/waiting_profile.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/randomness_space/waiting_profile.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

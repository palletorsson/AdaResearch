# Color_Nails

Authored dimensions: {"width": 15, "depth": 21, "max_height": 8}

![Source plan](Color_Nails.svg)

Source plan only: columns=x, rows=z. Red dots are manuscript/role primary anchors; blue dots are other placed objects; green crosses are utilities. Numbers refer to A rows below. Dark blue is source 0, cream lower structure, grey source wall-height threshold, ochre platforms. Museum overrides can change the built interpretation. Dots show anchors, not footprints or a proven route.

Map: [commons/maps/Color_Nails/map_data.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Color_Nails/map_data.json)

Text: [commons/maps/Color_Nails/final.md](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/maps/Color_Nails/final.md)

| Instance | x,z | Raw token | Recorded role | Registry / scene |
|---|---|---|---|---|
| A1 | 2,5 | `science_screen:180:1.5#mode:field` | secondary | [commons/artifacts/registry/shaders.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/shaders.json) → [commons/artifacts/science_screen/science_screen.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/science_screen/science_screen.tscn) |
| A2 | 12,5 | `colorballs:180:0:1#case:salon#plinth:0` | secondary | [commons/artifacts/registry/color.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/color.json) → [algorithms/color/colorballs/colorballs.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/color/colorballs/colorballs.tscn) |
| A3 | 12,7 | `brick_wall_factory:90:0:0.4#plinth:0` | secondary | [commons/artifacts/registry/color.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/color.json) → [algorithms/color/brick_wall_factory/brick_wall_factory.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/algorithms/color/brick_wall_factory/brick_wall_factory.tscn) |
| A4 | 7,9 | `nail_salon:180:0:1#plinth:0` | secondary | [commons/artifacts/registry/nail_salon.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/nail_salon.json) → [commons/artifacts/nail_salon/nail_salon.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/nail_salon/nail_salon.tscn) |
| A5 | 5,14 | `nail_color_controller:180:1.2:1#plinth:0#mount:salon` | primary | [commons/artifacts/registry/commons_artifacts.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/commons_artifacts.json) → [commons/interfaces/nail_color_controller.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/nail_color_controller.tscn) |
| A6 | 9,14 | `hand_color_controller:180:1.2:1#plinth:0#mount:salon` | primary | [commons/artifacts/registry/commons_artifacts.json](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/artifacts/registry/commons_artifacts.json) → [commons/interfaces/hand_color_controller.tscn](https://github.com/palletorsson/AdaResearch/blob/palm-scanner-door-entry/commons/interfaces/hand_color_controller.tscn) |

Utilities are listed with exact coordinates and raw tokens in space.json. Read map_info.museum and utility_definitions before inferring pits, entrances, movement or collision.

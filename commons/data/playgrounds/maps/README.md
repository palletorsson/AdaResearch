# Playground recipes per map - where a map fits a structure

One spec per map that fits (Palle, 2026-10-31: "more like one per map where it fits"), in the board vocabulary
(commons/modular/places/board_builder.gd), named for the map, with `map`, `sequence` and `principle`. A map whose
primaries are machines or rooms gets no file here - that absence is the categorisation. probe_example_structures
compiles and photographs these beside the examples (ada_run/workstation/map_<Map>.png).

| map | principle | structure |
|---|---|---|
| Pattern_Foundry | the array | sixteen groups of one motif in a 4 x 4 field; the four tile rules on a rack behind |
| Pattern_Temple | the court | one group on the floor and the four walls, the walker inside |
| Shader_05_Patterns | the path of screens | the chapter's ten shaders as walkable screens, wallpaper posters behind |
| Facade_Assembly_Principle | the street | a mini town: eleven facade plans (commons/facade_parts/presets) at half size, held a metre up in board frames, fronts turned to the street (`artifact_turn` 180, `fit`); trial `facade_town` |
| Mosaic_Pompeii_Floors | the decks and the field | all 46 mosaic floor artifacts on 4 x 4 m floor boards at ground level, framed, fitted, walkable (`walk`), named at their south edge (`label`) - pompeii_meander_floor draws nothing and says so; north of them the five Pompeii floors in the slots of 6 x 6 m plates a metre up, rimmed, railed, ramped; trial `mosaic_decks` |

A spec is walked as a Void trial named for it: `python tools/playground_trial.py make --spec <file> --id <trial>
--map <Map>` writes the trial with a slab sized to it, and `python tools/launch_void_desktop.py --trial <trial>`
opens it on the desktop (Palle, 2026-11-02: "test this inside their maps, then later move to the skyscraper").
Trials do not ship to the Quest; a tested hall moves into the tower as a floor's space. probe_playground_maps
checks the town and the decks: fronts at or above 1 m, fitted, turned; decks walkable at 1 m.

Board words for artifacts other than the display plate: `artifact` names the token, `artifact_turn` adds to its
yaw (a facade's front is +Z, a plate's -Z), `fit: true` scales whatever it built uniformly into the board's w x h
and centres it, measured off its meshes (place_activity._fit_into). On a floor board, `walk: true` lays a thin body at the artifact's surface (the mosaic floors carry no collision), `label: true` its title at the south edge, and a content may name its own `artifact`, so one board repeats different tokens.

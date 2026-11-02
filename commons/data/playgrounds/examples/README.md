# Example structures - the board vocabulary, one spec per principle

Each file is a place spec (commons/modular/places/place_spec.gd), most with no places and only `boards`
(board_builder.gd): rectangular display plates on the floor, upright or overhead, framed by the kit's bars,
repeated by count, step, rows and quarter turns. probe_example_structures.tscn compiles every one, stands it in
the hall's runtime scene and photographs it (ada_run/workstation/example_<name>.png).

| file | principle | content |
|---|---|---|
| path | the path of screens | the Shader_05 chapter, ten walkable screens in a row |
| array | the array | sixteen wallpaper groups in a 4 x 4 field, the same motif |
| corridor | the corridor | tiling: floor and both walls tiled, walked through |
| canopy | the canopy | patterns hung overhead at 3 m, walked under |
| court | the court | one wallpaper group four ways round a floor, the walker inside |
| rack | the rack | fifteen pattern candidates on one wall |
| stack | the stack | three shader floors at 0, 2 and 4 m on posts |
| pit | the pit | a 6 x 6 pool, rim at 1 m, full of beach balls (ball_pit) under a screen wall; the one spec with a place |
| mosaic_wall | the vertical plane | eight mosaic floors stood upright in wall frames (`artifact_tilt` -90, `fit`), faces to the room - the Patterns sequence's mosaic floors on a wall |

`facing` names the side a wall stands on, looking inward. A spec may carry `principle`, `title` and `camera`
(`[[eye], [look_at]]`) for the probe's picture. A map that fits gets a spec like these, named for the map.

# Point Animatedcube — artifact inventory

Current map_data.json and commons/data/artifact_roles.json, updated 2026-10-05. Twenty-two placements, sixteen artifact types. The restored shelf at (11,8), offset 0.2 m west, faces the sorting line at (16,7) across a shared aisle; the other placements retain their grid cells.

## Primary encounters

The book and necklace order is **cube_lines → animatedcubebuilder → cube_diagonal_plate → polyhedron_nets_cube → prefab_box_library → cube_sorting_line**. These six types occupy seven placements because the builder appears twice. One builder can remain a reference while the visitor changes the other. The shelf offers reusable copies for an arrangement; the sorting game turns folded cubes into repeated stock that must be handled.

## Every placement

Coordinates are (column,row) grid indices, not world metres. Placement strings below preserve the current rotation, offset and configuration tokens.

| Grid cell | Artifact | Role | Full placement string |
| --- | --- | --- | --- |
| (2,1) | `cube_lines` | primary | `cube_lines:0:0` |
| (2,2) | `floating_sphere_field` | decoration | `floating_sphere_field:0:0#bounds:4,3,8` |
| (5,3) | `wooden_pallet` | secondary | `wooden_pallet:0:0#box_arrangement:pyramid#stencil_words:A_WORLD;WITHOUT;COMPOSITION` |
| (11,3) | `first_shadow` | secondary | `first_shadow` |
| (1,5) | `film_cube_corner` | primary by default (unruled) | `film_cube_corner:90:0#plinth:0#pin:true` |
| (5,5) | `animatedcubebuilder` | primary | `animatedcubebuilder:0:0#plinth:0.55#discovery:1` |
| (7,5) | `cube_diagonal_plate` | primary reference | `cube_diagonal_plate:-90:0:0.8#offset:0.30,0.34,0` |
| (11,8) | `prefab_box_library` | primary | `prefab_box_library:90:0#plinth:0#offset:-0.2,0,0#worktable_x:-2.45#worktable_z:2.0#column_pitch:1.2` |
| (16,7) | `cube_sorting_line` | primary | `cube_sorting_line:270:0#plinth:0` |
| (5,7) | `hangar_supply_pile` | secondary | `hangar_supply_pile:0:0#palette:metal#crate_count:2#stencil_words:WITHOUT_COMPOSITION;YET` |
| (2,8) | `animatedcubebuilder` | primary | `animatedcubebuilder:0:0#plinth:0.55#discovery:1` |
| (6,9) | `crate` | secondary | `crate:0:0#stamp_label:YET` |
| (1,10) | `station_crates` | secondary | `station_crates#upkeep:store` |
| (4,10) | `polyhedron_nets_cube` | primary | `polyhedron_nets_cube:0:0#plinth:0#fall_cycle:true#loop_fold:true#edge_length:0.7#fold_duration:2.6#think_hold:2.2` |
| (2,11) | `glove_box` | secondary | `glove_box:0:0#glove_count:1` |
| (8,11) | `pyramid` | secondary | `pyramid#base_sides:8` |
| (3,12) | `station_crates` | secondary | `station_crates:0:0` |
| (4,12) | `pyramid` | secondary | `pyramid#base_sides:3` |
| (5,12) | `pyramid` | secondary | `pyramid#base_sides:4` |
| (6,12) | `pyramid` | secondary | `pyramid#base_sides:5` |
| (7,12) | `pyramid` | secondary | `pyramid#base_sides:6` |
| (11,12) | `first_phosphor` | secondary | `first_phosphor` |

## What the instrument makes available

Both builders have `#discovery:1`: REPLAY, local PAUSE / RESUME, RESTORE CUBE and DIAGONALS, with numbered handles enabled when assembly completes. The cross-shaped net folds into a 0.7 m cube, shrinks to 0.315 m and drops a new physical copy on each cycle. After a 2.2-second pause, the working net grows and reopens above the fallen cubes. The collection keeps up to 24 bodies. This October 4 upgrade keeps the grid cell and removes the plinth. Other nets remain available in the source.

The edited cube's surfaces are visual meshes, not a collision enclosure. The seven selected primary placements include two builder instances, the shelf with 24 pickable copies and its worktable, and the sorting line with separate grabbable cubes. Accepted cubes shrink into their matching baskets; unsorted cubes remain in the room's backlog and can be reclaimed from its surface. `dark_sphere` and `science_screen` are absent from this map's current interactables. `film_cube_corner` is also present; it has no explicit role ruling, so the role system treats it as primary by default without adding it to the selected book order.

## Secondary and decorative work

The pallet, supply pile, single crate, two station-crate placements, glove box and phosphor display retain the Boxes Example group. The shadow display and eight-sided pyramid remain secondary outside it. Their comparisons are available in tutorial.md. The floating sphere field remains decoration.

The pallet, pile and crate carry Palle's "A world without composition yet" across their stencils; this admission remains in final.md. Secondary placement does not mean the work has been removed.

## Source references

- `commons/primitives/line/cube_lines.gd`
- `commons/primitives/animatedcubebuilder/animatedcubebuilder.gd`
- `commons/ui/cube_experiment_panel.gd`
- `commons/infoboards_3d/visualizations/polyhedron_nets.gd`
- `commons/artifacts/first_shadow/first_shadow.gd`
- `commons/artifacts/first_phosphor/first_phosphor.gd`

The archive and validation record are in `doc/space/animated-cube-focus-2026-09-16/`.

## Shared illustration

The wall plate compares the same front-face triangle triples before and after v6 moves out of plane. It is static reference geometry; the two builders remain the hands-on comparison. Its centre is 1.7 m high on the east wall of the first chamber. A narrow sculpture-clear strip keeps its approach available. The September 23 illustration pass moved no existing artifact, floor or wall. The September 26 library pass widens the east gallery and opens its dividing wall; all earlier artifact and utility cells remain unchanged.

## Prefab library — September 26

The shelf shows four repeated families followed by two columns of variations, with 24 pickable copies in all. It reuses `cardboard_box`, `crate` and `tech_crate`, and adds an original printed `edition_carton`. A low, initially empty table receives copies taken down for a new arrangement. Restored on October 5 at grid (11,8), with a 0.2 m westward offset, the shelf faces east toward the sorting line across their shared aisle. Its `column_pitch:1.2` setting brings the rack width to 7.44 m, compared with the September 26 rack's 9.12 m, while retaining all 24 copies at their original sizes. Its original-size worktable moves to the south end through the placement's `worktable_x:-2.45` and `worktable_z:2.0` settings. The secondary crates and stencilled supply pile remain in place; their earlier “A world without composition yet” returns beside an arrangement the visitor can change.

The editable library is `commons/artifacts/prefab_box_library/catalog.json`. The manuscript's Warhol reference concerns fabricated plywood sculptures with packaging imagery; the AGAIN carton is an original study, not a reproduction. Full scene references, separate-copy/stacking checks and native interior photographs are in `doc/book/iterations/2026-09-26-cube-prefab-library/`.

## Sorting line — October 5

`cube_sorting_line` stands at grid (16,7), facing west toward the restored shelf and worktable. A folding net feeds grabbable cubes onto a conveyor; a printer assigns an AGAIN or YET texture based on the existing printed carton's design. The basket samples use the `edition_carton` scene. The two matching baskets shrink accepted cubes. Unsorted cubes fall from the open conveyor end and remain on the museum floor, where a backlog can fill the room and end the round. The control stand provides pause and reset. The shelf supports free arrangement; the sorting game supplies a matching rule. The independent folding-net exhibit and the hall's earlier artifacts remain in place.

The fixed stage is `commons/artifacts/cube_sorting_line/cube_sorter_stage.gd`; gameplay is `commons/artifacts/cube_sorting_line/cube_sorting_line.gd`. The stage uses the actual museum floor and the shared production push buttons. This entry describes the new placement and intended interaction; it does not carry the earlier shelf's validation claims forward to the minigame.

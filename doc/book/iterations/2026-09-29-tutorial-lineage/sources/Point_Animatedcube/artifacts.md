# Point Animatedcube — artifact inventory

Current map_data.json and commons/data/artifact_roles.json, updated 2026-09-26. Sixteen placements, fourteen artifact types. All fifteen earlier placements are retained at their original grid cells.

## Primary encounters

The book and necklace order is **cube_lines → animatedcubebuilder → cube_diagonal_plate → polyhedron_nets_cube → prefab_box_library**. These five types occupy six placements because the builder appears twice. One builder can remain a reference while the visitor changes the other.

## Every placement

Coordinates are (column,row) grid indices, not world metres. Placement strings below preserve the current rotation, offset and configuration tokens.

| Grid cell | Artifact | Role | Full placement string |
| --- | --- | --- | --- |
| (2,1) | `cube_lines` | primary | `cube_lines:0:0` |
| (2,2) | `floating_sphere_field` | decoration | `floating_sphere_field:0:0#bounds:4,3,8` |
| (5,3) | `wooden_pallet` | secondary | `wooden_pallet:0:0#box_arrangement:pyramid#stencil_words:A_WORLD;WITHOUT;COMPOSITION` |
| (11,3) | `first_shadow` | secondary | `first_shadow` |
| (5,5) | `animatedcubebuilder` | primary | `animatedcubebuilder:0:0#plinth:0.55#discovery:1` |
| (7,5) | `cube_diagonal_plate` | primary reference | `cube_diagonal_plate:-90:0:0.8#offset:0.30,0.34,0` |
| (16,7) | `prefab_box_library` | primary | `prefab_box_library:270:0#plinth:0` |
| (5,7) | `hangar_supply_pile` | secondary | `hangar_supply_pile:0:0#palette:metal#crate_count:2#stencil_words:WITHOUT_COMPOSITION;YET` |
| (2,8) | `animatedcubebuilder` | primary | `animatedcubebuilder:0:0#plinth:0.55#discovery:1` |
| (6,9) | `crate` | secondary | `crate:0:0#stamp_label:YET` |
| (1,10) | `station_crates` | secondary | `station_crates#upkeep:store` |
| (4,10) | `polyhedron_nets_cube` | primary | `polyhedron_nets_cube:0:1#loop_fold:true` |
| (2,11) | `glove_box` | secondary | `glove_box:0:0#glove_count:1` |
| (8,11) | `pyramid` | secondary | `pyramid#base_sides:8` |
| (3,12) | `station_crates` | secondary | `station_crates:0:0` |
| (11,12) | `first_phosphor` | secondary | `first_phosphor` |

## What the instrument makes available

Both builders have `#discovery:1`: REPLAY, local PAUSE / RESUME, RESTORE CUBE and DIAGONALS, with numbered handles enabled when assembly completes. The net uses the default cross configuration and folds repeatedly. The source supports other nets; this map contains one net placement.

The edited cube's surfaces are visual meshes, not a collision enclosure. Six primary placements include two builder instances and the library with 24 individually pickable copies. `dark_sphere` and `science_screen` are absent from this map's current interactables.

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

A 9.12 m shelf shows four repeated families followed by two columns of variations. It reuses `cardboard_box`, `crate` and `tech_crate`, and adds an original printed `edition_carton`. A low, initially empty table receives copies taken down for a new arrangement. The secondary crates and stencilled supply pile remain in place; their earlier “A world without composition yet” returns beside an arrangement the visitor can change.

The editable library is `commons/artifacts/prefab_box_library/catalog.json`. The manuscript's Warhol reference concerns fabricated plywood sculptures with packaging imagery; the AGAIN carton is an original study, not a reproduction. Full scene references, separate-copy/stacking checks and native interior photographs are in `doc/book/iterations/2026-09-26-cube-prefab-library/`.

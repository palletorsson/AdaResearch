# Point Animatedcube — Map Summary

## The room's experiment

Follow an outline, reveal its layers, then move one corner. A diagonal becomes a crease: positions have changed while the triangle connections remain. Compare this deformation with the folding net's rigid faces and moving hinges.

## Current spatial setup

- Dimensions: 19 × 14 grid cells; maximum structure height value 2.
- Twenty-two artifact placements, sixteen distinct artifact types.
- Outline: `cube_lines` at (2,1).
- Two instrumented builders at (5,5) and (2,8), both configured `#plinth:0.55#discovery:1`.
- Folding net at (4,10), configured `polyhedron_nets_cube:0:0#plinth:0#fall_cycle:true#loop_fold:true#edge_length:0.7#fold_duration:2.6#think_hold:2.2`.
- `prefab_box_library` at (11,8), offset 0.2 m west and facing east: a 7.44 m rack with closer column spacing, all 24 pickable copies at their original sizes, and the original-size worktable for making another arrangement. The table sits at the shelf's south end.
- `cube_sorting_line` at (16,7), facing west toward the shelf across a shared aisle: folding-net feeder, conveyor printer, two sorting baskets and pause/reset controls.
- Existing carton, crate, glove-box, shadow, phosphor, pyramid and sphere-field placements remain. See artifacts.md for every placement.
- Spawn `sp` at (0,0), orientation `an:-90` at (6,0), exit `t` at (5,12).

Coordinates above are (column,row) indices from map_data.json, not world metres or measured visitor reach.

## Primary encounter order

1. `cube_lines`: recognise a cube through its connected edges.
2. `animatedcubebuilder`: replay; pause the local reveal; resume; move `v6` out of the face plane; find the shared diagonal; compare replay with restoration. Keep the second builder unchanged as a reference.
3. `cube_diagonal_plate`: compare the unchanged and creased face with the live experiment.
4. `polyhedron_nets_cube`: follow one rigid square through folding and shrinking, then watch a new cube drop each cycle and stay on the floor. Distinguish hinge rotation from corner deformation.
5. `prefab_box_library`: take copies from the shelf to the worktable. Compare repeated scenes and their variations, then make an arrangement of your own.
6. `cube_sorting_line`: take an AGAIN or YET cube from the conveyor and release it into the matching basket. Accepted cubes shrink; missed cubes fall and accumulate on the floor until the room fills and the round ends.

Six selected primary types make seven physical placements. The museum companion keeps the other exhibits available without making all their questions prerequisites for leaving.

## Sequence context

Ninth of fifteen maps in the current `primitives` sequence. Follows `Primitives_Polythedra`; precedes `Primitives_Ignorance`. The admission "A world without composition yet" stays in the book as the transition from known parts to relations still to investigate.

## Verification limit

The existing component probe checks actual pointer-button events, supplied handle movement, geometry updates and both map-configured instruments. The restored hall passes 30 native museum checks, including all 24 shelf pickables, complete shelf/worktable collider clearance and supported visitor-capsule routes between the library, table and sorter. Full-room headset reach and viewing comfort remain to be checked.

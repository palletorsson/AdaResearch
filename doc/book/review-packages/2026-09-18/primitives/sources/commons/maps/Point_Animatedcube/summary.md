# Point Animatedcube — Map Summary

## The room's experiment

Follow an outline, reveal its layers, then move one corner. A diagonal becomes a crease: positions have changed while the triangle connections remain. Compare this deformation with the folding net's rigid faces and moving hinges.

## Current spatial setup

- Dimensions: 13 × 14 grid cells; maximum structure height value 2.
- Fourteen artifact placements, twelve distinct artifact types.
- Outline: `cube_lines` at (2,1).
- Two instrumented builders at (5,5) and (2,8), both configured `#plinth#discovery:1`.
- Folding net at (4,10), configured `polyhedron_nets_cube:0:1#loop_fold:true`.
- Existing carton, crate, glove-box, shadow, phosphor, pyramid and sphere-field placements remain. See artifacts.md for every placement.
- Spawn `sp` at (0,0), orientation `an:-90` at (6,0), exit `t` at (5,12).

Coordinates above are (column,row) indices from map_data.json, not world metres or measured visitor reach.

## Primary encounter order

1. `cube_lines`: recognise a cube through its connected edges.
2. `animatedcubebuilder`: replay; pause the local reveal; resume; move `v6` out of the face plane; find the shared diagonal; compare replay with restoration. Keep the second builder unchanged as a reference.
3. `polyhedron_nets_cube`: follow one rigid square through the folding loop and distinguish hinge rotation from corner deformation.

Three primary types make four physical placements. The tutorial's optional return visits keep the other exhibits available without making all their questions prerequisites for leaving.

## Sequence context

Seventh of ten maps in the current `primitives` sequence. Follows `Primitives_Polythedra`; precedes `Primitives_Ignorance`. The admission "A world without composition yet" stays in the book as the transition from known parts to relations still to investigate.

## Verification limit

The existing component probe checks actual pointer-button events, supplied handle movement, geometry updates and both map-configured instruments. Full-room headset reach and viewing comfort remain to be checked.

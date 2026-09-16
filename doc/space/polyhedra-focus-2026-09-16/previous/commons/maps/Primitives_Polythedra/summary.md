# Primitives 1 - Map Summary

## Overview
Primitives_1 is the first explicit jump from 2D primitives into enclosed 3D form. It stages a trihedron as the corner condition for volume, then moves into tetrahedron assembly.

## Spatial Layout
- Dimensions: 7x9 grid.
- Architecture: Raised pedestals at (2,2) and (4,2), with a recessed fillhole strip at row 4.
- Entry orientation: `an:-90` at (6,0).
- Exit path: Teleporter `t` at (5,6).

## Key Elements
- `grab_trihedron:90:0:0.4` at (2,2): grabbable trihedron display.
- `snap_tetrahedron_puzzle:0:0.5:0#fillhole:reveal` at (3,2): tetrahedron assembly puzzle.
- `dark_sphere` at (3,3): local contrast dome for focus.
- `cube_scene:0:0:0.90#group:fillhole` at (2,4), (3,4), (4,4): fillhole markers.
- `pyramid_edit:0:0:0.4` at (1,7): optional side comparison with another polyhedron family.
- Title text `3t:polythedra` at (3,8).

## Learning Flow
1. Read the trihedron as a non-closed corner primitive.
2. Transition to the snap puzzle and close a tetrahedron from triangular faces.
3. Compare open junction vs closed volume.
4. Exit through teleporter once dimensional shift is clear.

## Design Intent
The map frames a clean progression: point -> line -> triangle -> volumetric enclosure. The trihedron and tetrahedron are paired so the learner can feel the threshold between "faces meeting" and "space enclosed".

## Sequence Context
- Position in primitives sequence: 7/11.
- Follows: `Point_Triangle_Context`.
- Precedes: `Point_Animatedcube`.
- Role: bridge from planar primitives to volumetric primitives.

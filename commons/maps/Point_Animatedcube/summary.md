# Point Animatedcube - Map Summary

## Overview
Point_Animatedcube shifts from static primitive display to procedural construction. Multiple `animatedcubebuilder` instances stage the same cube-assembly process so learners can read structure as sequence, not only as finished form.

## Spatial Layout
- Dimensions: 7x14 grid.
- Architecture: Two raised pedestal pairs at (2,4)/(4,4) and (2,8)/(4,8).
- Focus anchor: `dark_sphere` at (3,4).
- Exit: teleporter `t` at (5,12).

## Key Elements
- `animatedcubebuilder:0:0:0.5` at (2,4), (4,4), (2,8), and (4,8).
- `dark_sphere` at (3,4) for local contrast.
- `polyhedron_nets_cube:0:1#loop_fold:true` at (3,10) as a fold/unfold bridge from face nets to enclosed volume.
- Spawn orientation `an:-90` at (6,0).

## Learning Flow
1. Watch cube assembly phases (points, edges, faces) on the front pair.
2. Cross-check the same logic on the rear pair.
3. Read the cube net fold animation as another path to enclosure.
4. Exit once procedural assembly is internalized.

## Design Intent
The map teaches that volume is constructed, not given. Repetition across four builders reduces one-off spectacle and emphasizes rule-based generation.

## Sequence Context
- Position in primitives sequence: 8/11.
- Follows: `Primitives_Polythedra`.
- Precedes: `Primitives_Ignorance`.
- Role: procedural bridge from primitive vocabulary to volumetric construction logic.

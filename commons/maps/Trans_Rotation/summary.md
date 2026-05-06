# Trans_Rotation_1 - Map Summary

## Overview
Trans_Rotation_1 introduces rotation as the transformation that makes space anisotropic - directionally differentiated. Unlike translation where all directions are equivalent, rotation establishes front/back, left/right, facing and faced-away. The map uses spinning objects and grid rotation to demonstrate orientation as a fundamental spatial property.

## Spatial Layout
- **Dimensions**: 7×36 grid (tall vertical map)
- **Architecture**: Small northern platform, vast void, southern platform
- **Height**: Multi-level with long vertical descent
- **Structure**: Extreme vertical separation emphasizes falling through rotated space

## Key Elements

### Interactables
- **RotateGridCubes** (3,3) - Grid of cubes that rotate together
- **spin:180:1** (2,18) - Spinning object at 180° offset
- **spin:0:1** (2,19) - Spinning object at 0° offset (counter-reference)
- **pick_up_cube** (1,32) - Collection target
- **pickup_gate#pickups:7** (4,32) - Final gate
- **dark_sphere** (2,17) - Ambient atmosphere

### Utilities
- **3D Text** (2,16) - "Rotation produces space as anisotropic"
- **Teleporter** (5,34) - Exit
- **Score point** (6,35) - Completion marker

## Atmosphere
- **Lighting**: Cool ambient with warm directional
- **Background**: Sky blue
- **Mood**: Vertiginous, disorienting

## Learning Sequence
1. Player spawns on small northern platform
2. Observes RotateGridCubes demonstration
3. Falls/navigates through long vertical void
4. Encounters paired spin objects (180° vs 0°)
5. Reads text about anisotropic space
6. Continues descent to southern platform
7. Collects pickups and exits through gate

## Design Intent
The extreme verticality creates a sense of **falling through oriented space**. The spinning objects at different angles demonstrate that rotation creates difference: 180° and 0° produce opposing orientations despite identical spin rates.

The RotateGridCubes show that rotation can apply to multiple objects simultaneously, maintaining their relative positions while changing all their orientations.

## Connection to Sequence
- **Position in transformation sequence**: 4/6
- **Precedes**: Trans_Rotation_2 (rotation continuation)
- **Follows**: Trans_Translate_2 (translation completion)
- **Establishes**: Rotation as orientation-producing operation

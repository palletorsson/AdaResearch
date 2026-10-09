# Trans_Translate_1 - Map Summary

## Overview
Trans_Translate_1 focuses purely on translation - movement through space without rotation or scaling. The map uses walkways and transport cubes to demonstrate that translation is not merely walking but a fundamental operation that can be mechanized, automated, and applied to bodies as well as objects.

## Spatial Layout
- **Dimensions**: 7×24 grid
- **Architecture**: Fragmented platforms connected by transport systems
- **Height**: Multi-level with vertical transport (up to height 4)
- **Voids**: Large gaps requiring transport cube traversal

## Key Elements

### Utilities
- **Walkway** (3,0) rotated 90° - Initial launch platform
- **Transport Cubes**:
  - tc:3:z - Horizontal translation (Z-axis)
  - tc:1:y:auto - Automatic vertical lift
  - tc:3:y / tc:2:y - Vertical transport pair
  - tc:6:y - Long vertical ascent
- **Waypoint** (2,8) - Mid-map checkpoint
- **Teleporter** (5,22) - Exit

### Interactables
- **pick_up_cube** instances at various heights
- **pickup_gate#pickups:3** - First checkpoint (3 required)
- **pickup_gate#pickups:7** - Final checkpoint (7 total required)
- **dark_sphere** (3,10) - Ambient atmosphere

## Atmosphere
- **Lighting**: Cool ambient with warm directional
- **Background**: Sky blue [0.2, 0.3, 0.7]
- **Mood**: Kinetic, puzzle-like

## Learning Sequence
1. Player uses initial walkway to reach first platform
2. Boards transport cube for horizontal translation across void
3. Navigates vertical transport system
4. Collects pickup cubes at various heights
5. Passes through intermediate gate (3 pickups)
6. Continues collection through vertical shafts
7. Reaches final gate (7 total pickups)
8. Exits via teleporter

## Design Intent
The map makes translation **visible and physical**. When standing on a transport cube, the player's body is translated by the platform's movement - they experience translation passively, as something done to them. This contrasts with active walking, where translation feels like personal action.

The scattered pickups require planning vertical routes through the transport system, teaching that translation in 3D space involves all three axes, not just horizontal movement.

## Connection to Sequence
- **Position in transformation sequence**: 2/6
- **Precedes**: Trans_Translate_2 (vertical focus)
- **Follows**: Transformation_Intro (vocabulary establishment)
- **Establishes**: Translation as mechanized spatial operation

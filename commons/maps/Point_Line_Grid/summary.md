# Point Line Grid - Map Summary

## Overview
Point Line Grid formalizes space into a system of addressability. After individual points, measured lines, and line networks, this map shows how a coordinate grid turns free space into indexed, computable territory. The focus shifts from geometric objects to the coordinate system as infrastructure.

## Spatial Layout
- **Dimensions**: 8x14 grid (compact rectangular space with south extension)
- **Architecture**: Rectangular platform with large central void (rows 1-5, columns 2-6) plus a tapered south runway
- **Border walkway**: Perimeter path around central emptiness
- **Entry**: Type "I" - immersive spawn

## Key Elements

### Primary Interactables
- **grid_lines** (4,3) - Grid overlay visualization
  - Makes coordinate system visible as geometry
  - X and Z axes rendered as intersecting lines
  - Demonstrates how space becomes indexed
- **player_trace** (0,0) - Passive recorder of player locomotion through grid space
- **grab_sphere_point_snap** (2,8) - Snapped point for comparing continuous movement with quantized placement

### Atmosphere and Context
- **dark_sphere** (3,4) - Intimate lighting enclosure
- **Floating text** (4,12) - "the_grid/the_trace" connection to Point_Trace

### Utilities
- **Teleporter** (4,8) - Exit to next map
- **Annotation** (7,8) rotated -90 deg - Navigation marker

## Atmosphere
- **Background**: Sky blue [0.2, 0.3, 0.7]
- **Lighting**: Cool ambient with warm directional (1.2 energy)
- **Mood**: Contemplative and infrastructural
- **Visibility**: Hidden tiles except corners

## Learning Sequence
1. Player spawns on the perimeter walkway.
2. Encounters the large central void and south runway extension.
3. Observes grid_lines as visible coordinate infrastructure.
4. Generates movement history through player_trace while walking.
5. Compares continuous locomotion with snapped placement via grab_sphere_point_snap.
6. Recognizes that VR position is always grid-indexed.
7. Exits with the grid understood as organizational technology, not discovered truth.

## Design Intent
The central void makes the argument legible: the grid spans absence as confidently as presence. Embodied walkability and indexed space diverge. You can only walk certain tiles, but the coordinate system still names the void.

## Focused Interactables
Point_Line_Grid uses a constrained set of interactables to isolate one conceptual pair:
- **grid_lines** as coordinate infrastructure
- **player_trace** as embodied memory
- **grab_sphere_point_snap** as quantization anchor

This focused set emphasizes that indexing and trace are co-present: the grid captures motion without exhausting it.

## The Grid/Trace Pairing
- **Trace** preserves path and duration.
- **Grid** enforces addressability and quantization.

Together, they stage the core tension in digital embodiment: continuous bodies moving through discrete coordinate systems.

## Connection to Sequence
- **Position in primitives sequence**: 4/11
- **Precedes**: Point_Triangle (first closure, bounded area)
- **Follows**: Point_Trace (continuous gesture versus discrete grid)
- **Establishes**: Coordinate systems, addressability, spatial indexing
- **Critical theme**: Grid as political technology of organization
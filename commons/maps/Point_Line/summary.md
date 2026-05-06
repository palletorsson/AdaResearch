# Point Line - Map Summary

## Overview
Point_Line shifts from isolated point to relation. The map centers a single manipulable line relation so distance and direction are learned through direct hand movement.

## Spatial Layout
- **Dimensions**: 7x15 grid
- **Architecture**: irregular single-floor platform with void cuts toward the south edge
- **Height**: mostly level floor with central interaction focus

## Key Elements

### Interactables
- **line_demo** at (3,5): two snap points with dynamic connection line
- **dark_sphere** at (3,2): enclosure to isolate the relation exercise

### Utilities
- **annotation board** `an:-90` near the north-east edge
- **floating text** `3t:stretching_between_two_points,_the_line_that_measures`
- **teleporter** `t` at (5,8)

## Atmosphere
- **Background**: sky blue [0.2, 0.3, 0.7]
- **Lighting**: default directional + ambient
- **Mood**: focused and comparative, with one core interaction

## Learning Sequence
1. Enter and identify the central two-point setup.
2. Grab either endpoint and stretch/compress the relation.
3. Observe that length and direction are computed from endpoint placement.
4. Read the line text prompt and exit through teleporter.

## Design Intent
Point_Line is intentionally sparse so the player stays with one conceptual move: a line is not a standalone object, but a measured relation between two commitments in space.

## Connection to Sequence
- **Follows**: Point_One (single point)
- **Prepares**: Point_Lines (multi-line systems)
- **Core transition**: from atom (point) to relation (line)

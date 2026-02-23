# Point One - Map Summary

## Overview
Point One isolates individuation: one marked position beyond origin. The map now stages both a fixed point and a grabbable point so the player can contrast stable reference with embodied repositioning.

## Spatial Layout
- **Dimensions**: 7x10 grid
- **Architecture**: Continuous west platform (columns 0-2) plus one isolated cube at (4,0)
- **Height**: Single-level field with selected interactables raised for readability

## Key Elements

### Interactables
- **origin** at (0,0), lowered -0.5: rotating zero marker + alias text cycle
- **folding_past** at (1,0), raised, scaled 0.5: temporal frame stack ambience
- **static_point** at (4,0), raised 1: fixed "the one" on the isolated cube
- **script_runner#point** at (0,1), raised 1: live Vector3 point code playback
- **dark_sphere** at (3,2): ambient enclosure for focus
- **interactive_point_origin** at (1,3), raised 1: grabbable point with position label and line-to-origin
- **frame_counter_display** at (0,9) and **CoordinateSystem3M** at (6,9): peripheral instrumentation

### Utilities
- **Annotation board** `an:-90` near spawn lane
- **Subtitle trigger** `sub:point_zero` at (1,2)
- **Floating text** `3t:that_which_has_no_part` at (1,8)
- **Teleporter** `t` at (1,5)

## Atmosphere
- **Background**: sky color [0.2, 0.3, 0.7]
- **Lighting**: ambient + directional warm key
- **Mood**: sparse, reflective, with one high-contrast interaction focus

## Learning Sequence
1. Enter from infrastructure residue (origin + temporal folding).
2. Read/observe the fixed static point on the isolated cube.
3. Grab the interactive point and move it; watch live coordinates and line-to-origin.
4. Compare fixed point vs moved point as two modes of "one."
5. Optional: trigger script runner to see Vector3 as code-level point representation.
6. Exit through teleporter.

## Design Intent
Point One should stay minimal but legible in VR. The added fixed point on the isolated cube gives a stable visual anchor, while the grabbable point carries embodiment and agency. Together they sharpen the concept without overloading the room.

## Connection to Sequence
- **Position in primitives sequence**: early foundation map
- **Follows**: Point_Zero (origin/infrastructure)
- **Prepares**: Point-Line style relations between multiple marked positions

# Point Triangle Context - Map Summary

## Overview
Point_Triangle_Context applies triangle concepts in a comparative workshop. It pairs interactive triangle manipulation with right-triangle constraint and quad transition, showing where rigid closure gives way to flexible surfaces.

## Spatial Layout
- **Dimensions**: 7x12 grid
- **Architecture**: Elevated northern band, stepped center lane, and southern transition strip
- **Notable voids**: Structural gaps at (5,8), (3,9), and row 10 create suspended utility zones
- **Entry**: Default map spawn

## Key Elements

### Triangle Workbench
- **draw_triangle_faces** (3,3) - Face construction from point relations
- **interactivetriangle** (0,6) rotated 180 deg, lowered -1.0, scaled 0.2 - Compact editable triangle demo
- **pythagorean_triangle_angles** (1,6) rotated 180 deg, lowered -0.2, scaled 0.2 - Right-triangle angle and side relation demo

### Quad Transition
- **quad_line_puzzle** (4,6) - Four-line closure puzzle with `#fillhole:remove` trigger
- **quad** (5,6) offset +0.5 and scaled 0.5 - Editable quad showing non-rigid behavior
- **cube_scene** (3,7) fillhole marker for puzzle reveal flow

### Supporting Artifacts
- **dark_sphere** (3,5) - Focus enclosure
- **folded_strip** (6,1) rotated -90 deg, offset -0.3 - Folded surface counterpoint

### Utilities and Context
- **Teleporter** (5,8) - Exit to next map
- **Annotation utility** (1,11)
- **Floating text** (3,11) - "Triangle everything"

## Atmosphere
- **Background**: Sky blue [0.2, 0.3, 0.7]
- **Lighting**: Warm directional with ambient fill
- **Mood**: Comparative geometry lab

## Learning Sequence
1. Player enters the triangle workbench zone.
2. Constructs or inspects triangle faces at `draw_triangle_faces`.
3. Manipulates `interactivetriangle` and reads rigidity through live deformation limits.
4. Studies `pythagorean_triangle_angles` for deterministic right-triangle relations.
5. Moves to quad transition artifacts and solves `quad_line_puzzle`.
6. Compares rigid triangle behavior against flexible quad behavior.
7. Exits through teleporter with closure, rigidity, and decomposition linked.

## Design Intent
The map is staged as a contrast engine. Triangles are presented as stable closure systems, while quad artifacts expose hidden triangulation and deformation risk. The fillhole puzzle chain keeps these concepts embodied rather than purely symbolic.

## Connection to Sequence
- **Position in primitives sequence**: 6/11
- **Precedes**: `Primitives_Polythedra`
- **Follows**: `Point_Triangle`
- **Establishes**: Rigidity, right-triangle constraint, and quad decomposition
- **Critical theme**: Stability is produced by constraints, not by shape names
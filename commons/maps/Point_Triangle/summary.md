# Point Triangle - Map Summary

## Overview
Point Triangle introduces the first closed geometry: the triangle as fundamental enclosure. After points, lines, and grid indexing, this map shows what changes when three vertices form a boundary with an interior.

## Spatial Layout
- **Dimensions**: 7x9 grid (compact workshop)
- **Architecture**: Stepped platform with local height variation (1-2 levels)
- **Central void**: One absent structural cell at (3,7), used as a floating focus zone
- **Entry**: Default map spawn

## Key Elements

### Primary Interactables
- **triangle_line_puzzle** (3,3) - Three-line snap puzzle for constructing closure
  - Configured with `#fillhole:remove` trigger
  - Elevated via token offset (`:1.2`) for clearer hand access
- **triangle** (3,6) - Interactive triangle mesh with draggable vertices
  - Real-time surface updates from vertex motion
  - Demonstrates orientation and area through live manipulation

### Supporting Elements
- **dark_sphere** (3,4) - Enclosure for visual focus
- **cube_scene** (3,5) at 0.9 scale - Fillhole-tagged marker linked to puzzle flow
- **triangleprofiles** (3,7) elevated by +2.0 - Companion profile artifact for extended form reading
- **la:triangle** annotation utility (3,3)

### Utilities
- **Teleporter** (3,7) - Exit to next map
- **Annotation** (6,0) rotated -90 deg - Navigation marker
- **Floating text** (3,8) - "Everything triangle"

## Atmosphere
- **Audio**: `fractal_exploration` preset at -10 dB
- **Background**: Sky blue [0.2, 0.3, 0.7]
- **Lighting**: Warm directional light with ambient fill
- **Mood**: Focused geometric workshop

## Learning Sequence
1. Player enters the stepped workspace and finds the triangle annotation.
2. Builds closure through `triangle_line_puzzle`.
3. Encounters the fillhole marker and observes puzzle-linked reveal behavior.
4. Manipulates `triangle` vertices to see area and orientation change in real time.
5. Compares the primary triangle with the elevated `triangleprofiles` artifact.
6. Exits via teleporter with closure understood as boundary production.

## Design Intent
This map stages a progression from relation to enclosure. The puzzle introduces closure as a rule-governed event, while the draggable triangle makes closure dynamic and embodied. The floating focus zone at (3,7) reinforces that the triangle's logic can operate beyond grounded tiles.

## Key Concept: First Closure
- **Point**: isolated position
- **Line**: open relation
- **Triangle**: closed boundary with inside/outside distinction

The triangle is the first primitive that can contain.

## Connection to Sequence
- **Position in primitives sequence**: 5/11
- **Precedes**: `Point_Triangle_Context`
- **Follows**: `Point_Line_Grid`
- **Establishes**: Closure, orientation, interior/exterior logic
- **Critical theme**: Boundaries as computational and political decisions
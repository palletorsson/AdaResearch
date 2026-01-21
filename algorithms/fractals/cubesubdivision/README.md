# Cube Subdivision

## Overview
Creates furniture and architectural objects through recursive cube subdivision - starting with a single cube and progressively dividing it into functional parts.

## Objects

### recursive_table
Table with self-similar recursive legs.
```
recursive_table
```

### recursive_chair / cube_chair
Chair through subdivision - seat, backrest, and legs.
```
recursive_chair
cube_chair
```

### cube_bookshelf
Bookshelf with grid of shelves (4 rows × 3 columns), frame, and decorative trim.
```
cube_bookshelf
```
- Animated step-by-step construction
- Frame → shelves → trim sequence

### cube_staircase
Staircase with treads, risers, side stringers, and handrail with balusters.
```
cube_staircase
```
- Diagonal subdivision pattern
- Configurable step count

### cube_desk
Modern office desk with drawer unit (2×3 grid), desktop, and legs.
```
cube_desk
```
- Accent strip detail
- Drawer handles

### cube_cabin
Rustic cabin/house through architectural subdivision.
```
cube_cabin
```
Subdivision sequence:
1. Walls (4 sides)
2. Door opening
3. Window openings (with transparency)
4. Gabled roof
5. Chimney
6. Front porch

## Design Philosophy
Each object demonstrates how complex forms emerge from simple subdivision rules:
1. Start with unit cube
2. Identify functional regions
3. Subdivide along appropriate axes
4. Apply materials/colors
5. Add detail through further subdivision

## Common Parameters
Most objects support:
- `animate` - Watch construction step-by-step
- `step_delay` - Animation speed
- Color/material customization via code

## Technical Notes
- All objects use CSGBox3D for geometry
- Materials applied per-part for visual distinction
- Step-by-step animation shows subdivision process
- Scene files (.tscn) contain default configurations

## Educational Value
Demonstrates:
- Recursive thinking in design
- How simple rules create complex objects
- Spatial reasoning and subdivision
- The connection between fractals and functional design

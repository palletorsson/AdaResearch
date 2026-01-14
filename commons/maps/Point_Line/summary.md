# Point Line - Map Summary

## Overview
Point_Line introduces **relation** between discrete units. After learning about individual points, this map presents the line as captured trace - the formalization of movement into measured distance between two commitments in space.

## Spatial Layout
- **Dimensions**: 7×13 grid
- **Architecture**: Mostly-filled irregular platform with voids in southwest corner and strategic notches
- **Height**: Single level with line_demo sunken to height -1.5m (below floor level)

## Key Elements

### Interactables
- **line_demo** (3,4) height -1.5m - Two grabbable snap points connected by a measuring line
- **Dark sphere** (3,2) - Ambient darkness

### Utilities
- **Teleporter** (5,6) - Exit to next map
- **Label annotation** (3,4) - "la:line"
- **Floating text** (3,7) - "stretching_between_two_points,_the_line_that_measures"

## Atmosphere
- **Background**: Sky blue [0.2, 0.3, 0.7]
- **Audio**: Default ambient
- **Lighting**: Standard directional + ambient
- **Mood**: Interactive, measured, relational

## Learning Sequence
1. Player enters map with recessed center
2. Looks down to see the line_demo **sunken into the floor**
3. Grabs one of two snap points (now bigger and shinier with our modifications!)
4. Pulls the points apart - the line stretches and shows length
5. Pushes points together - the line compresses
6. Reads the poetic text: "stretching between two points, the line that measures"
7. **No clipboard tutorial** - learning through embodied manipulation
8. Exits via teleporter

## Design Intent

### Sunken Interaction
The line_demo is placed at **height -1.5m**, meaning it's **below the floor tiles**. This creates a "pit" or "well" effect - the player must look down into the recess to interact with the line. This architectural choice:
- **Focuses attention** downward to the minimal interaction
- **Isolates** the line from surrounding space
- **Emphasizes** the one-dimensional nature (line sinks into lower dimension)

### The Measuring Line
The line_demo scene creates a **dynamic measurement system**. As you move the snap points:
- The line's length updates in real-time
- The visual cylinder stretches/compresses
- The relation between points becomes **visible as geometry**

This is the key insight: **The line is not an object - it is a visualized relation**.

## Connection to Sequence
- **Position in primitives sequence**: 3/13
- **Follows**: Point_One (individual discrete unit)
- **Precedes**: Point_Lines (networks of lines, grids)
- **Establishes**: Relation, measurement, direction, the concept of "between"

# Line Primitives - Capturing the Poetics of Geometry

## Overview

This folder contains interactive line primitives for VR that explore the fundamental poetics of geometric relationships. Inspired by phenomenological observations of lines in reality – train tracks, horizons, marked spaces – these primitives transform abstract geometry into lived spatial experience.

## Files

### Core Primitive
- **`line.tscn`** - The base interactive line with two grab spheres
  - Dynamic visual feedback with length measurement
  - Glossy, emissive material
  - Real-time spatial relationship detection
  - Poetic scale descriptions

### Line Combinations
- **`parallel_lines.tscn`** - Five vertical lines demonstrating parallelism
  - *Ordningsprincip* (ordering principle)
  - The rhythm of repetition in space
  
- **`cross_lines.tscn`** - Diagonal X intersection
  - The unknown designated
  - *Genombrott i bildytan* (breakthrough in the image plane)
  - Tension and decision
  
- **`plus_lines.tscn`** - Vertical and horizontal intersection
  - The horizon and the plumb line
  - Renaissance perspective
  - Orientation in space

### Documentation
- **`LINE_POETICS.md`** - Philosophical and poetic framework
- **`README.md`** - This file

## Usage in VR

### Basic Interaction
```gdscript
# Instance a line
var line = preload("res://commons/primitives/line/line.tscn").instantiate()
add_child(line)

# Or use a line combination
var cross = preload("res://commons/primitives/line/cross_lines.tscn").instantiate()
add_child(cross)
```

### Grabbing and Measuring
- Each line has two grab spheres at its endpoints
- Grab with VR controllers to adjust position
- Length is displayed in real-time above the line
- On release, contextual information is sent via TextManager

### Contextual Information
When a line is dropped, it provides:
- Precise length measurement
- Poetic scale description ("a hair's breadth", "toward the horizon")
- Spatial relationship ("horizontal - the horizon line")

## Poetic Scales

The system recognizes different phenomenological scales:

| Distance | Description |
|----------|-------------|
| < 0.05m | "a hair's breadth from the eye" |
| 0.05-0.2m | "barely a decimeter" |
| 0.2-1.0m | "an arm's length" |
| 1.0-3.0m | "a human scale" |
| 3.0-10.0m | "the width of a room" |
| > 10.0m | "stretching toward the horizon" |

## Line Relationships

Lines are classified by their orientation:

- **Horizontal** (Y < 0.3) - "the horizon line"
- **Vertical** (Y > 0.7) - "the plumb line"  
- **Diagonal** - "cutting through space"

## Design Philosophy

### Minimalism
Following modernist principles:
- Clean, undecorated forms
- Black lines (can be customized)
- Focus on essential geometric relationships

### Phenomenology
Lines are not just visual objects but spatial experiences:
- **Embodied**: Move through and around them
- **Measured**: Understand scale through interaction
- **Transformed**: Rotate, adjust, discover new meanings

### Educational Poetics
Geometry becomes poetry through:
- Metaphorical language ("horizon", "plumb")
- Scale relativity (hair vs. horizon)
- Spatial consciousness (parallel vs. intersecting)

## Integration with TextManager

Lines send events to TextManager on interaction:

```gdscript
# Event: "line_drop"
# Context includes:
{
    "length": "1.50",
    "length_raw": 1.5,
    "poetic_scale": "an arm's length",
    "relationship": "diagonal - cutting through space"
}
```

Map authors can create contextual educational messages that respond to line measurements and orientations.

## Customization

### Appearance
```gdscript
# Access line properties
line.line_thickness = 0.01  # Thicker line
line.line_color = Color(1.0, 0.0, 0.0)  # Red line
```

### Behavior
```gdscript
# Manually refresh connections
line.refresh_connections()

# Check current measurement
var distance = line.last_distance
```

## Examples in Context

### Architecture
Use parallel lines to demonstrate structural principles, rhythm in facades

### Perspective
Use plus lines to teach Renaissance perspective, then rotate 45° to show transformation

### Navigation
Use lines to mark paths, measure distances, create spatial markers

### Art
Create line drawings in 3D space, gestural marks, spatial poetry

## Technical Notes

- All line combinations are oriented in the Y-X plane
- Lines use CylinderMesh with dynamic height
- Transform matrices handle rotation properly
- Labels are billboarded and offset for readability

## Future Possibilities

- **Line Networks**: Connect multiple lines into graphs or structures
- **Animated Lines**: Lines that grow, shrink, or pulse
- **Colored Lines**: Semantic meaning through color
- **Line Trails**: Leave traces of movement through space
- **Intersecting Planes**: Extend lines into surfaces

## Philosophical Note

*"Det ena strecket rusar iväg så långt ögat håller och blir horisont där borta. Det andra, vertikala, strecket skulle mycket väl kunna vara ett hårstrå som hänger kvar här en knapp decimeter från ögat."*

Scale is relative. A line can be a hair or a horizon. In VR, we make this relativity tangible. We don't just see lines – we **inhabit** them, **measure** them, **transform** them. Geometry becomes poetry. Code becomes art. Lines become **lived experience**.

---

*Parallelism as ordering principle. X as the unknown. The cross as orientation. These are not just geometric facts – they are ways of being in space.*


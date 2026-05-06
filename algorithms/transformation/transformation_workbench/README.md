# Transformation Workbench

An interactive VR learning tool for understanding transformations **without oscillation concepts**.

## What It Shows

### The Grabbable Object
- A cube with visible XYZ axes (RGB = XYZ)
- Grab it to translate, rotate, or scale
- Ghost wireframe shows original position for comparison

### Live Matrix Display
A floating 4x4 transformation matrix that updates in real-time:

```
┌─────────────────────┐
│  1    0    0   tx   │  ← Highlighted cells depend on mode
│  0    1    0   ty   │
│  0    0    1   tz   │
│  0    0    0    1   │
└─────────────────────┘
```

**Mode highlighting:**
- **Translate (T)**: Last column highlighted (tx, ty, tz)
- **Rotate (R)**: 3x3 upper-left highlighted (rotation matrix)
- **Scale (S)**: Diagonal highlighted (sx, sy, sz)

### Vector/Info Display
- **Translation mode**: Shows `T = (x, y, z)` with arrow visualization
- **Rotation mode**: Shows `R = (rx°, ry°, rz°)` plus coordinate swap notation
- **Scale mode**: Shows `S = (sx, sy, sz)`

### Mode Buttons
Three buttons (T, R, S) to switch which transformation you're learning about.

## Key Pedagogical Features

### No Trigonometry Required
Rotation is taught through:
1. **90° snapping** - rotations snap to discrete angles
2. **Coordinate swap notation** - `(x,y) → (-y,x)` for 90° rotation
3. **Visual demonstration** - see what rotation DOES before learning WHY

### The Matrix as "Gadget"
The matrix display shows the RESULT of transformations without requiring students to derive where the numbers come from. The connection to sin/cos is deferred to the Wavefunctions sequence.

### Before/After Comparison
Ghost object shows original position, making transformation effects immediately visible.

## Usage in Maps

Add to any map using the artifact key: `transformation_workbench`

Example in map_data.json:
```json
"interactables": [
    ["transformation_workbench:0:1:0.5", " ", " "]
]
```

## Exports

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `current_mode` | Mode enum | TRANSLATE | Starting mode (0=T, 1=R, 2=S) |
| `show_matrix` | bool | true | Show the 4x4 matrix display |
| `show_ghost` | bool | true | Show ghost at original position |
| `show_vectors` | bool | true | Show transformation vector/info |
| `snap_rotation_to_90` | bool | true | Snap rotations to 90° increments |

## Learning Sequence

This artifact supports the pedagogical arc:

1. **Transformations** (this sequence): Learn what T/R/S DO using the workbench
2. **Wavefunctions** (later): Reveal WHY rotation uses sin/cos (unit circle)

The "aha moment" comes later: "Those numbers in the rotation matrix? They come from circular motion."

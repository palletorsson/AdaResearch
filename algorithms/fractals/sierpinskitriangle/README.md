# Sierpinski Triangle

Three becomes three becomes three. Self-similarity at every scale.

## QFEP Connection

The Sierpinski triangle is **F replicating itself**: each triangle contains three smaller copies of itself. This is recursion as reproduction — the pattern is its own offspring. The fractal dimension (≈1.585) sits between line and plane, neither and both.

## The Algorithm

1. Start with an equilateral triangle
2. Find midpoints of each side
3. Connect midpoints to form an inner triangle
4. Remove the inner triangle (or keep the three corners)
5. Repeat on each remaining triangle

```
    △         △
   ╱ ╲       ╱ ╲
  ╱   ╲  →  △   △
 ╱     ╲   ╱ ╲ ╱ ╲
△───────△ △───△───△
```

## Properties

| Property | Value |
|----------|-------|
| Fractal dimension | log(3)/log(2) ≈ 1.585 |
| Area | 0 (in the limit) |
| Perimeter | ∞ (in the limit) |
| Self-similarity | 3 copies at 1/2 scale |

## 3D Implementation

This version creates **walkable 3D geometry**:
- Triangle stands vertical (rotated 90°)
- Optional extrusion — each iteration rises higher
- Color codes by depth
- 10m initial size for human-scale exploration

## Parameters

```gdscript
@export var subdivision_interval: float = 1.0   # Seconds between subdivisions
@export var max_iterations: int = 6             # Recursion depth
@export var triangle_size: float = 10.0         # Initial size (meters)
@export var triangle_thickness: float = 0.5     # 3D thickness
@export var extrude_on_subdivision: bool = true # Rise with each iteration
@export var extrusion_height: float = 1.5       # Height per iteration
@export var colorize_by_depth: bool = true      # Depth-based coloring
```

## Usage

```gdscript
$SierpinskiTriangle.step()         # Single subdivision
$SierpinskiTriangle.reset()
$SierpinskiTriangle.start_subdivision()
$SierpinskiTriangle.stop_subdivision()
```

## VR Experience

Walk through the Sierpinski triangle as it grows. With extrusion enabled, each iteration creates a new layer — the fractal becomes a staircase of self-similar forms rising into space.

## Files

- `sierpinski_triangle.gd` — 3D recursive subdivision
- `sierpinski_triangle.tscn` — Scene setup

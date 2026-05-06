# Sierpinski Pyramid

Recursive 3D fractal built from cubes — the Sierpinski triangle extruded into the third dimension.

## QFEP Connection

The Sierpinski pyramid is **self-similarity at every scale** — zoom in and you see the same structure. It emerges from a simple recursive rule (divide and remove center), yet contains infinite detail. This is λ at the edge: enough order to maintain recognizable structure, enough iteration to generate endless complexity.

## How It Works

```
Depth 0: Single cube

Depth 1: 5 cubes (4 base corners + 1 top)
    ▲
   ╱ ╲
  ▲   ▲
 ╱ ╲ ╱ ╲
▲   ▲   ▲

Depth 2+: Each cube becomes a depth-1 pyramid
```

The algorithm:
1. At depth 0, place a single cube
2. Otherwise, recursively build 5 sub-pyramids:
   - 4 at the base corners (half size)
   - 1 on top (half size)

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `depth` | 4 | Recursion depth (cubes = 5^depth) |
| `size` | 1.0 | Base cube size |
| `generate_on_ready` | true | Auto-generate when scene loads |

### Cube Count by Depth

| Depth | Cubes | Notes |
|-------|-------|-------|
| 0 | 1 | Single cube |
| 1 | 5 | Basic pyramid |
| 2 | 25 | Visible self-similarity |
| 3 | 125 | Clear fractal structure |
| 4 | 625 | Default, good detail |
| 5 | 3,125 | Performance heavy |

## Tool Mode

Marked `@tool` — works in the Godot editor. Change `depth` or `size` and watch it regenerate in real-time.

## Files

| File | Purpose |
|------|---------|
| `SierpinskiPyramid.tscn` | Scene root |
| `SierpinskiPyramid.gd` | Recursive generation |

## Usage

```gdscript
var pyramid = preload("res://algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.tscn").instantiate()
pyramid.depth = 5  # More detail (3125 cubes)
pyramid.size = 0.5  # Smaller base unit
add_child(pyramid)
```

## Mathematical Background

The Sierpinski pyramid (also called Sierpinski tetrahedron) has:
- **Fractal dimension**: log(5)/log(2) ≈ 2.32
- **Surface area**: Increases with each iteration
- **Volume**: Approaches zero as depth → ∞

It's related to Pascal's triangle mod 2 — the positions of odd numbers form the 2D Sierpinski triangle.

## VR Experience

Walk around and through the pyramid. At depth 4+, you can enter the gaps between sub-pyramids and experience the fractal from inside. The self-similarity becomes visceral when you're surrounded by it.

## Cellular Automata Connection

The Sierpinski triangle emerges from Rule 90 (elementary cellular automaton). Each row of the 1D CA, when stacked over time, produces the triangle pattern. This 3D version extends that principle into space.

## See Also

- `fractals/` — Other fractal implementations
- `rule_30_110/` — Elementary CA that generates similar patterns

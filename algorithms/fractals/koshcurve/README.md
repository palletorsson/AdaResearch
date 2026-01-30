# Koch Curve 3D

A portal archway shaped by the Koch snowflake curve — recursive fractal geometry bent into a walkable doorway.

## QFEP Connection

The Koch curve has **infinite length within finite bounds** — a paradox that emerges from simple recursive subdivision. Each iteration adds detail at smaller scales, demonstrating how F (the subdivision rule) generates unbounded E (complexity). The portal form makes this mathematical infinity something you can walk through.

## How It Works

```
Iteration 0:  ___________

Iteration 1:    /\
              _/  \_

Iteration 2:   /\  /\
             _/  \/  \_

... continues infinitely
```

The classic Koch curve construction:
1. Start with a line segment
2. Divide into thirds
3. Replace middle third with two sides of an equilateral triangle
4. Repeat on every segment

This implementation bends the curve into an arch and extrudes it through multiple depth layers.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `iterations` | 4 | Fractal depth (segments = 4^n) |
| `line_width` | 0.03 | Thickness of curve lines |
| `portal_width` | 2.0 | Width of the archway |
| `portal_height` | 2.5 | Height of the arch |
| `leg_height` | 1.5 | Height of supporting legs |
| `depth_layers` | 3 | Volumetric depth layers |
| `layer_spacing` | 0.15 | Distance between layers |
| `rotation_speed` | 0.0 | Auto-rotation (0 = static) |

## Segment Count by Iteration

| Iteration | Segments | Length Ratio |
|-----------|----------|--------------|
| 0 | 1 | 1.0 |
| 1 | 4 | 4/3 |
| 2 | 16 | 16/9 |
| 3 | 64 | 64/27 |
| 4 | 256 | 256/81 |

The curve length increases by 4/3 each iteration, approaching infinity.

## Visual Style

- **Emissive blue-white lines** for visibility
- **Multi-layer depth** creates volumetric feel
- **Optional rotation** for display/showcase

## Files

| File | Purpose |
|------|---------|
| `KochCurve3D.tscn` | Scene root |
| `KochCurve3D.gd` | Curve generation and portal assembly |

## Usage

```gdscript
var portal = preload("res://algorithms/fractals/koshcurve/KochCurve3D.tscn").instantiate()
portal.iterations = 5  # More detail
portal.rotation_speed = 0.2  # Slow spin
add_child(portal)
```

## VR Experience

Walk through the fractal portal. As you approach, notice how the edge detail seems to continue infinitely — this is the fractal nature becoming perceptible. The depth layers create a sense of passing through something substantial rather than just a flat curve.

## Mathematical Note

The Koch curve's fractal dimension is log(4)/log(3) ≈ 1.26 — more than a line (1) but less than a plane (2). It fills space more than a smooth curve but doesn't quite become a surface.

## See Also

- `fractals/` — Other fractal implementations
- `lsystems/` — Grammar-based curve generation

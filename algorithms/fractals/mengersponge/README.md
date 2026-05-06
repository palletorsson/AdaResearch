# Menger Sponge

Infinite holes, zero volume, infinite surface area. The cube that isn't there.

## QFEP Connection

The Menger sponge is **F annihilating itself**: recursive removal creates a structure with fractal dimension ≈2.73 (between surface and solid). Each iteration removes matter but adds complexity. The sponge approaches infinite surface area but zero volume — pure boundary, pure edge, pure λ.

## The Algorithm

Start with a cube. Subdivide into 27 smaller cubes (3×3×3). Remove:
- The center cube (1)
- The 6 face-center cubes

Repeat on remaining 20 cubes. Forever.

```
Iteration 0:  1 cube
Iteration 1:  20 cubes
Iteration 2:  400 cubes
Iteration 3:  8,000 cubes
Iteration n:  20^n cubes
```

## Visual Pattern

Top-down view of one face:
```
█ █ █     After 1 iteration:   █░█   (░ = hole)
█   █     each █ becomes →     ░ ░
█ █ █                          █░█
```

## Properties

| Property | Value |
|----------|-------|
| Fractal dimension | log(20)/log(3) ≈ 2.727 |
| Volume | Approaches 0 |
| Surface area | Approaches ∞ |
| Topological dimension | 1 (despite appearing 3D) |

## Usage

```gdscript
# Auto-starts subdivision on ready
$MengerSponge.max_iterations = 3    # Warning: 8000 cubes!
$MengerSponge.subdivision_interval = 1.0  # Seconds between iterations

# Manual control
$MengerSponge.step()                # Single iteration
$MengerSponge.start_subdivision()   # Begin auto
$MengerSponge.stop_subdivision()    # Pause
$MengerSponge.reset()               # Back to start
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `subdivision_interval` | 1.0 | Seconds between auto-subdivisions |
| `max_iterations` | 2 | Maximum recursion depth (2 = 400 cubes) |
| `auto_start` | true | Begin subdividing on ready |

## VR Experience

At iteration 2 with a 9m starting cube, the sponge becomes walkable — you can enter the holes and explore the fractal from inside. Each hole leads to smaller holes leads to smaller holes...

## Files

- `menger_sponge.gd` — Subdivision algorithm
- `menger_sponge.tscn` — Scene with initial cube

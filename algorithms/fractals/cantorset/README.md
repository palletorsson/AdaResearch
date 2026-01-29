# Cantor Set

Remove the middle. What remains is uncountably infinite yet has measure zero.

## QFEP Connection

The Cantor set is **F through subtraction**: each iteration removes structure yet the remainder is infinitely complex. It's uncountably infinite (as many points as the real line) but has zero length. Existence without extension. Pure λ — the edge between something and nothing.

## The Algorithm

1. Start with a line segment
2. Remove the middle third
3. Repeat on each remaining segment

```
Iteration 0:  ████████████████████████████
Iteration 1:  █████████          █████████
Iteration 2:  ███   ███          ███   ███
Iteration 3:  █ █   █ █          █ █   █ █
```

## Properties

| Property | Value |
|----------|-------|
| Fractal dimension | log(2)/log(3) ≈ 0.631 |
| Total length | 0 (in the limit) |
| Cardinality | Uncountably infinite |
| Topology | Totally disconnected, perfect set |

## Implementation

This version uses **physics simulation** — bars fall and stack:
- Each iteration creates bars at a lower height
- Bars use RigidBody3D and fall under gravity
- Color shifts with each iteration (hue based on depth)

## Parameters

```gdscript
@export var iteration_interval: float = 2.0   # Seconds between iterations
@export var max_iterations: int = 5           # Recursion depth
@export var initial_bar_length: float = 9.0   # Starting length
@export var bar_thickness: float = 0.3        # Bar height/depth
@export var vertical_spacing: float = 1.5     # Space between levels
```

## Usage

```gdscript
# Manual control
$CantorSet.step()            # Single iteration
$CantorSet.start_generation()
$CantorSet.stop_generation()
$CantorSet.reset()
```

## VR Experience

Watch the Cantor set build itself in 3D — bars fall from above, stacking into the fractal pattern. Walk through the gaps. The middle third is always missing.

## Files

- `cantor_set.gd` — Physics-based Cantor set
- `cantor_set.tscn` — Scene setup

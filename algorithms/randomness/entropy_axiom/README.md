# Entropy Axiom

A 4000-point visualization of the transition from order to chaos — perfect grid at one end, random scatter at the other.

## QFEP Connection

This is **λ made visible**. The Z-axis is the entropy dial:
- `z=0`: λ=0, pure order (F dominates) — points form a perfect grid
- `z=max`: λ=1, pure chaos (E dominates) — points scatter randomly

The color gradient reinforces this: **blue (cold, ordered)** → **magenta (transition)** → **red (hot, chaotic)**.

## How It Works

```
Z=0 (Order)                    Z=max (Chaos)
┌─────────────┐                ┌─────────────┐
│ • • • • • • │                │   •  •      │
│ • • • • • • │       →        │  •    •   • │
│ • • • • • • │                │ •   •  •    │
│ • • • • • • │                │    •   •  • │
└─────────────┘                └─────────────┘
   Blue                           Red
```

For each point:
1. Calculate base grid position (ordered)
2. Compute entropy factor from Z position (0→1)
3. Apply exponential curve for dramatic end-stage chaos
4. Add random X/Y offset scaled by entropy factor
5. Color by entropy (HSV: blue→red)

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `grid_size_x` | 10 | Points per row |
| `grid_size_y` | 10 | Points per column |
| `grid_size_z` | 40 | Depth (entropy gradient length) |
| `base_spacing` | 0.2 | Distance between grid points |
| `max_randomness` | 0.5 | Maximum displacement at high entropy |
| `min_randomness` | 0.0 | Displacement at low entropy (usually 0) |
| `point_radius` | 0.018 | Size of each sphere |

## Performance

Uses **MultiMesh** for efficient rendering:
- 4000 instances in a single draw call
- Per-instance transforms and colors
- Emissive material for visibility without lighting

## Files

| File | Purpose |
|------|---------|
| `entropy_axiom.tscn` | Original version |
| `entropy_axiom.gd` | Original script |
| `entropy_axiom_multimesh.tscn` | Optimized MultiMesh version |
| `entropy_axiom_multimesh.gd` | MultiMesh implementation |

## Usage

```gdscript
var axiom = preload("res://algorithms/randomness/entropy_axiom/entropy_axiom_multimesh.tscn").instantiate()
axiom.grid_size_z = 60  # Longer gradient
axiom.max_randomness = 0.8  # More chaos at the end
add_child(axiom)
```

## VR Experience

Walk alongside the entropy gradient. Start at the ordered blue end — notice the perfect lattice structure. As you move toward the red end, watch the structure dissolve into randomness. This is the second law of thermodynamics made spatial.

## Mathematical Note

The entropy factor uses an exponential curve (`pow(z, 2)`) so that most of the visible chaos happens in the final third. This mimics real thermodynamic systems where entropy increases slowly at first, then accelerates.

## See Also

- `randomize_cubes_over_Z/` — Similar concept with cubes
- `qfep/` — Interactive λ and φ controls

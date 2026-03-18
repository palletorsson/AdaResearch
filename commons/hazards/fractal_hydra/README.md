# Fractal Hydra

Multi-headed hydra with fractal branching — heads split on damage, creating smaller duplicates.

## Behavior

Extends `HazardCreatureBase`. 120 HP.

- Starts with 2 heads on neck cylinders
- Damaging a head splits it into 2 at half size (max depth 3, up to 8 tiny heads)
- More heads = faster attacks but less damage per bite
- Dies only when ALL heads at minimum size are destroyed
- Base head size 0.15, neck length 0.35, bite range 0.25, base bite damage 12.0

## Files

| File | Purpose |
|------|---------|
| `fractal_hydra.gd` | Main script — head splitting, fractal depth tracking |
| `fractal_hydra.tscn` | Scene |

## Key State

`_heads` array tracks mesh, neck, size, depth, angle, bite timer, and alive status per head.

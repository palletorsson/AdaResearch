# Branching Vine

Procedural vine hazard that grows via L-system rules, biased toward the player.

## Behavior

Extends `HazardCreatureBase`. Grows iteratively using the L-system rule `F → F[+F][-F]F`:

- Iterates every 3 seconds up to max depth 4
- Branch tips (leaves) deal 8.0 contact damage
- Growth direction biased toward player (player_bias 0.3)
- Branches can be pruned by damage

## Files

| File | Purpose |
|------|---------|
| `branching_vine.gd` | Main script — L-system iteration, mesh generation |
| `branching_vine.tscn` | Scene |

## Key Parameters

| Parameter | Value |
|-----------|-------|
| `segment_length` | 0.15 |
| `leaf_damage` | 8.0 |
| `max_iterations` | 4 |
| `branch_angle` | 25° |
| `player_bias` | 0.3 |

## Algorithm

Maintains `_current_string` starting from axiom `"F"`. Each iteration applies production rules, then recursively generates cylinder segments and branches at `[` and `]` brackets. Two root tendrils serve as legs.

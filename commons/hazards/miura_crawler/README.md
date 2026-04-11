# Miura Crawler

Miura-ori folding enemy — a flat corrugated sheet that crawls like an inchworm, flattens to squeeze through gaps, and pops up to attack.

## Behavior

Extends `CharacterBody3D`. State machine: **DORMANT → ALERT → CRAWL → ATTACK → FLATTEN**

- `fold_amount` interpolates between flat (0) and corrugated (1)
- Inchworm locomotion via alternating fold/unfold
- Can flatten completely to squeeze through narrow gaps
- Pops up from flat to attack at close range
- Uses `MiuraGeometry` helper for crease pattern mesh

## Files

| File | Purpose |
|------|---------|
| `miura_crawler.gd` | Main script — state machine, locomotion |
| `miura_geometry.gd` | Geometry helper — Miura-ori crease math |
| `miura_crawler.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction

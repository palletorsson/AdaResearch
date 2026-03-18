# Bricoleur Golem

Asymmetric creature assembled from random body parts that scatters and rebuilds on damage.

## Behavior

Extends `HazardCreatureBase`. 100 HP, chase speed 2.8.

- 6 body slots (head, torso, left/right arm, left/right leg) each pick a random mesh type and color
- On damage: parts scatter outward then reassemble (heal 20% per rebuild)
- After 3 rebuilds: enters EXHAUSTED state (40% speed, no more rebuilds)
- Random HSV colors per slot give each instance a unique look

## Files

| File | Purpose |
|------|---------|
| `bricoleur_golem.gd` | Main script — part generation, scatter/rebuild mechanics |
| `bricoleur_golem.tscn` | Scene |

## Key Parameters

| Parameter | Value |
|-----------|-------|
| `rebuild_time` | 1.5s |
| `max_rebuilds` | 3 |
| `part_scatter_distance` | 1.5 |
| `exhausted_speed_mult` | 0.4 |

# Swarm Hive

Stationary hive that spawns boid particles following separation/alignment/cohesion rules plus player-seeking.

## Behavior

Extends `Node3D`. Swarm intelligence hazard.

- Spawns boids at configurable intervals (max 20 active)
- Each boid follows classic flocking rules: separation, alignment, cohesion
- Player-seeking behavior added to the steering mix
- Individual boids have independent velocity and lifetime
- Teaches emergent collective behavior from simple local rules

## Files

| File | Purpose |
|------|---------|
| `swarm_hive.gd` | Main script — boid spawning, flocking rules, lifetime management |
| `swarm_hive.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction

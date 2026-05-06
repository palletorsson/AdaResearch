# Particle Emitter Hazard

Nozzle that fires manually-managed projectile particles with lifecycle coloring and physics.

## Behavior

Extends `Node3D`. Particles sequence hazard.

- Emits up to 30 particles from a nozzle
- Particle lifecycle: white → yellow → red → invisible (fade to death)
- Physics: velocity + gravity + drag per particle
- Emission pattern cycles every 5.0s: CONE → FOUNTAIN → SPIRAL
- Contact damage via distance check against player

## Files

| File | Purpose |
|------|---------|
| `particle_emitter_hazard.gd` | Main script — particle pool, lifecycle, emission modes |
| `particle_emitter_hazard.tscn` | Scene |

## Signals

- `enemy_destroyed` — On destruction

# Catalyst Modes

Projectile mode implementations for the Becoming Catalyst. Each mode has two files: a factory (`mode_*.gd`) and a projectile behavior (`*_projectile.gd`).

## Pattern

**Factory** (`mode_xxx.gd`):
- `class_name CatalystModeXxx`
- Constants: `MODE_ID`, `FIRE_RATE`
- Static `create_projectile(pos, dir) -> CatalystProjectile`

**Projectile** (`xxx_projectile.gd`):
- Extends `CatalystProjectile`
- Overrides: `_build_visual()`, `_build_collision()`, `_apply_initial_velocity()`, `_update_trajectory()`, `_on_hit()`, `_expire()`

## Modes

| Mode | Sequence | Behavior |
|------|----------|----------|
| Primitives | primitives | Bouncing glowing ball |
| Transformation | transformation | Morphing projectile |
| Chromatic | color | Color-shifting light burst |
| Forces | forces | Calming amber mortar |
| Waveform | wavefunctions | Oscillating wave projectile |
| Chaos | randomness | Unpredictable trajectory |
| Fractal | fractals | Branching fractal burst |
| Cellular | cellularautomata | Grid-spreading pattern |
| Branching | lsystems | Growing L-system tendril |
| Swarm | swarmintelligence | Particle swarm cluster |

## Unlock

Primitives is always available. Others unlock via `LabManager.is_sequence_completed()`.

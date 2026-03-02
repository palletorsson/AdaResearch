# The Becoming Catalyst

The player's evolving VR tool. Not a weapon of destruction but a tool of transformation, becoming, and boundary dissolution. Each Lab sequence unlocks a new expressive mode.

## Controls

- **Grip**: Absorb the crystal — it shrinks into your hand, granting its power
- **Trigger**: Fire from the hand (behavior depends on current mode)
- **Thumbstick left/right**: Switch between unlocked modes
- **Release grip**: Crystal re-emerges from the hand back into the world

## Modes

Each mode corresponds to a curriculum sequence. Completing a sequence unlocks its mode.

| Mode | Sequence | Description |
|------|----------|-------------|
| Primitives | primitives | Bouncing glowing ball that slowly shrinks |
| Transformation | transformation | Morphing projectile |
| Chromatic | color | Color-shifting light burst |
| Forces | forces | Calming amber mortar (future: gravity gun) |
| Waveform | wavefunctions | Oscillating wave projectile |
| Chaos | randomness | Unpredictable trajectory |
| Fractal | fractals | Branching fractal burst |
| Cellular | cellularautomata | Grid-spreading pattern |
| Branching | lsystems | Growing L-system tendril |
| Swarm | swarmintelligence | Particle swarm cluster |

Primitives is always unlocked. Other modes unlock via `LabManager.is_sequence_completed()` or the `sequence_completed` signal.

## File Structure

```
becoming_catalyst/
  becoming_catalyst.gd       Main script (extends XRToolsPickable)
  becoming_catalyst.tscn     Scene (instances pickable.tscn base)
  catalyst_projectile.gd     Base projectile class (RigidBody3D)
  catalyst_visual.gd         Procedural crystal mesh builder (tiers by unlock count)
  modes/
    mode_*.gd                Mode factory — static create_projectile(pos, dir)
    *_projectile.gd          Projectile behavior — extends CatalystProjectile
```

## How Modes Work

Each mode has two files:

**mode_xxx.gd** — Static factory with constants and `create_projectile()`:
```gdscript
class_name CatalystModeXxx
const MODE_ID := "xxx"
const FIRE_RATE := 0.5
static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
    var proj := CatalystProjectile.new()
    proj.speed = 8.0
    proj.direction = dir
    proj.set_script(load("res://.../xxx_projectile.gd"))
    return proj
```

**xxx_projectile.gd** — Extends CatalystProjectile, overrides virtual methods:
- `_build_visual()` — Create mesh + particles
- `_build_collision()` — Create collision shape
- `_apply_initial_velocity()` — Set physics material, gravity, initial velocity
- `_update_trajectory(delta)` — Per-frame behavior (curves, pulses, etc.)
- `_on_hit(body)` — What happens on collision
- `_expire()` — What happens when lifetime runs out

## Visual Evolution

The crystal's appearance evolves as modes unlock (managed by `catalyst_visual.gd`):
- Tier 0: Simple faceted sphere
- Tier 1+: Elongated, asymmetric
- Tier 2+: Rainbow rim + aura particles
- Tier 3+: Orbiting particle ring
- Tier 6+: Sub-crystal growths
- Tier 9+: Satellite spheres

## Grid Integration

Spawned via map_data.json interactables layer as `"becoming_catalyst"`.
Registry entry in `commons/artifacts/registry/hazards.json`.

Supports `apply_grid_config()`:
- `"all_modes": true` — Unlock everything (debug)
- `"start_mode": "forces"` — Unlock a specific mode
- `"unlock_to": 4` — Unlock all modes up to order 4

## Save/Load

Unlocked modes persist to `user://catalyst_modes.save` (JSON).

## Future

- **Forces mode** will integrate gravity gun mechanics (attract, capture, launch objects)
- **Algo gun** (Grid Agent capture/direction) will fold into the Catalyst
- Continuous mode handler pattern for non-projectile modes

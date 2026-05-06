# The Becoming Catalyst

The player's evolving VR tool. Not a weapon of destruction but a tool of transformation, becoming, and boundary dissolution. A bracelet that lives on the wrist, picked up from a wireframe pedestal in the lab.

## Pickup

- Player grabs the bracelet from a wireframe pedestal
- The catalyst absorbs into the hand; the bracelet spawns on the wrist
- The other hand rotates the bracelet to switch modes

## Controls

- **Trigger**: Place (behavior depends on current mode)
- **Grip**: Remove last placed object
- **Bracelet rotation** (other hand): Switch between unlocked modes

## Modes (Current)

3 modes available at start:

| Mode | Description |
|------|-------------|
| `voxel_editor` | Cube placement — solid blocks on the grid |
| `wedge_placer` | Walkable prism — ramps and wedge geometry |
| `off` | Bracelet inactive, no placement |

## Placement

- **Cardinal neighbor placement**: Head direction picks one of 4 compass directions, 2 cells out from current position
- Ghost preview shows where the block will land
- Trigger to confirm placement, grip to remove

## Persistence

- **In-memory**: Placed objects survive map transitions within a session
- **Fresh each launch**: No disk save files — every game start is a clean slate

## Mode-per-Sequence Unlock Architecture (Planned)

Each mode will correspond to a curriculum sequence. Completing a sequence unlocks its mode.

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

## Visual Evolution (Planned)

The bracelet's appearance will evolve as modes unlock (managed by `catalyst_visual.gd`):
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

## Future

- **Mode-per-sequence unlocks** will activate as the progression system matures
- **Forces mode** will integrate gravity gun mechanics (attract, capture, launch objects)
- **Algo gun** (Grid Agent capture/direction) will fold into the Catalyst
- Continuous mode handler pattern for non-projectile modes

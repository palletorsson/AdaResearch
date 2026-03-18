# Armadillo Droideka

Armored origami droid that rolls into a compact ball, deploys into a biped stance with articulated shell plates, and fires projectiles in bursts.

## Behavior

State machine: **ROLL → DETECT → DEPLOY → AIM → FIRE → RETRACT → DEAD**

- Rolls as a sealed sphere of 12 overlapping scutes
- On player detection, unfolds shell plates and raises core to biped stance
- Fires `fire_bolt` projectiles in bursts toward the player
- 80 HP, roll speed 2.8, turn speed 6.0

## Files

| File | Purpose |
|------|---------|
| `armadillo_droideka.gd` | Main CharacterBody3D — state machine, shell folding, projectile firing |
| `armadillo_droideka.tscn` | Scene |
| `armadillo_eggling.gd/.tscn` | Smaller egg variant |
| `fire_bolt.gd/.tscn` | Projectile fired during FIRE state |
| `origami_droideka.gd/.tscn` | Origami-style variant |
| `rigid_origami.gd` | Rigid origami folding math utilities |
| `waterbomb_enemy.gd/.tscn` | Waterbomb tessellation variant |
| `waterbomb_shell.gd` | Waterbomb shell geometry builder |

## Key Mechanics

- **Shell geometry**: 12 scutes with `open_degrees` and `wave_degrees` controlling fold state
- **Leg joints**: Hip and knee angles interpolate between folded and deployed poses
- **Shell radius**: 0.62, core raise height: 0.52
- Variants share the folding geometry system but use different tessellation patterns

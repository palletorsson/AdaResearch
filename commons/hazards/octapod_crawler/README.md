# Octapod Crawler

Procedural 8-legged wall-crawling critter that starts as an ambiguous egg-plant pod and hatches when disturbed.

## Behavior

Extends `CharacterBody3D`. Q-FEP theme: hostile because surprised — befriend later in lab.

State machine: **DORMANT → HATCHING → IDLE → PATROL → DETECT → CHASE → LEAP → STUNNED → DEAD**

- Starts as an egg-plant pod (plant? egg? food? danger?)
- Hatches when player approaches or disturbs it
- 8 IK legs using FABRIK3D with spring-based foot markers
- 4 eyes, body hover height 0.35
- Can leap at player during CHASE

## Files

| File | Purpose |
|------|---------|
| `octapod_crawler.gd` | Main script — state machine, IK locomotion |
| `octapod_crawler.tscn` | Scene |
| `ik_leg.tscn` | Single IK leg component |
| `octapod_ik.tscn` | Full IK rig scene |

## Variants

Several critter variants with fewer legs exist as separate scenes:
- `one_leg` through `six_leg_critter` — Smaller variants with reduced leg counts

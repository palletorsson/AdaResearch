# Void / an enemy becomes a health source

Implemented 19 October 2026. Trial placement: Cube, floor 07, north bay at x=-5, z=-5.3. It is a standalone artifact in `commons/void/rooms.json`, editable and copyable between floors in the lab editor. Existing floor arrangements remain intact.

The creature reuses `commons/hazards/octapod_crawler/octapod_ik.tscn` and its eight skinned FABRIK legs, enlarged to a 1.35 m shoulder height. `commons/void/spider_gait.gd` adapts the existing gait to a single CharacterBody movement controller and gives the foot targets one owner. Original museum creatures are unchanged.

Rules in `commons/void/spider.gd`:

- Outside 3 m: rests. Within 3 m on the same floor with clear sight: 0.65 s warning, then a 4.5 m/s rush.
- Bite: 20 health out of 100. A 3 s pause precedes a fresh warning and any further bite. Retreat beyond 5 m or break sight to end pursuit. Home leash: 6 m.
- Catalyst: the existing receiver contract calms it immediately, including during combat. Green light marks the health source. Further catalyst hits do not reset its healing clock.
- Within 2 m of the calmed creature, with clear sight: restores 10 health every 2 s, capped at 100. No healing across storeys or walls, or during death/recovery.
- Sleeping floors pause the encounter and retain its calm state for this visit. The creature checks support ahead and will not chase across an open shaft.
- Ordinary hard one-floor landing: now costs 10 health. Same-floor jumps and marked corner pads remain harmless. Falls beyond one floor retain the existing death, grunt, red fade and checkpoint return.

VR uses the existing earned two-hand catalyst: empty hands together, then trigger. Desktop now holds C to bring empty virtual hands together, then uses left click to fire the same ability. This change does not grant or alter catalyst unlocks. Restart The Void to load the changed scene and layout. The follow-up parity checks are in `../2026-10-19-void-shared-play/`; the verification table below records the initial spider implementation.

The editor's GLB exporter now bakes skinned geometry into the current pose. The spider therefore appears as the real eight-legged model, rather than unposed bone geometry. Copy/paste retains the same script and configurable encounter values.

## Verification

`python tools/test_void_spider.py` runs native Godot 4.6 / Jolt checks against production sources:

| Suite | Assertions |
| --- | ---: |
| Creature behaviour, geometry, actual projectile collisions and health | 28 |
| Authored tower floor, desktop fire and synthetic XR two-hand catalyst, streaming | 13 |
| Desktop and XRTools fall/damage/death/recovery | 42 |
| Desktop and XRTools safe corner landings | 16 |
| Total | 99 |

All passed. `--staged --capture` additionally runs the desktop tower assertions with the Mobile renderer and records the two screenshots. No physical headset test was performed. Native logs contain existing resource UID/Jolt warnings and teardown ObjectDB warnings, with no script or engine errors in these runs.

The full floor validator still fails on 26 pre-existing layout/access findings. Removing only the new spider placement produces the same findings; this addition introduces none. They were not auto-repaired because the arrangement is the user's curation.

Editor export: 420 GLBs, zero export failures. Browser check: floor 07 loads 33 real model snapshots, exposes the spider position and rotation controls, and enables Copy/Duplicate. No user layout was modified during this browser check.

![Resting spider inside the tower](tower-capture/spider-rest.png)

![Calmed spider supplying health](tower-capture/spider-calm.png)

# The museum player in The Void

The Void now uses the same core player scene as `commons/scenes/base.tscn`:
`commons/player/museum_rig.tscn`. Edit that shared scene to change the common
hands, pickup, pointer, movement or drift protection. Do not rebuild another
player in the Void.

The core was extracted from the existing base scene. The museum keeps its
additional tools, flight, wall walking and map-specific UI at their existing
paths. The tower uses the core with its own jump and fall rules.

## Controls

- Left stick: walk and strafe.
- Right stick: forward/back and turn, using the museum's user turn preference.
- Grip: pickup and release, with the existing collision hands and hand animation.
- Trigger: point at switches or use a held object; the existing two-hand catalyst
  still owns firing when its conditions are met.
- Right A: jump once per press. Holding it through a landing does not jump again.
- Right B: retry the last checkpoint. Left Y: roof. Left X: menu.

The museum walking speed is 3 m/s. Its existing 0.5 forward/back and 0.3 strafe
deadzones and small-velocity cleanup are restored. The Void had omitted those
helpers and the pointer functions while constructing its separate rig.

## Validation

`python tools/test_void_museum_rig.py` stages actual production sources and runs
Godot/Jolt with synthetic XR tracking. It checks idle drift, intentional movement,
the authored Point One light switch, grip/release, catalyst, jump, fall damage,
death feedback, checkpoint recovery and safe corner planks. It does not test
physical headset comfort or measure the user's controller hardware.

The full production base scene was also instantiated before and after extraction.
All 105 original node paths and the selected transform/control properties matched.
The one-time comparison uses `tools/probes/museum_rig_contract_probe.gd` and the
pre-change snapshot in `ada_run/museum-rig-before.tscn`.

The fall probe now starts its jump just inside the shaft edge: its previous takeoff
target assumed the faster 3.5 m/s Void rig. Its assertions about damage, death and
checkpoints remain unchanged. The movement-room probe likewise reads the shared
speed and tests the museum's turn settings rather than the retired Void overrides.

Restart The Void to load the shared player. The floor layouts are untouched.

Results: 96 rig/interaction/fall assertions passed in the isolated native project;
100 checks across 29 movement trials passed in the full project at 60/90 Hz.
No script or engine errors were reported. The isolated harness retains its known
ObjectDB teardown warning. Physical headset testing remains.

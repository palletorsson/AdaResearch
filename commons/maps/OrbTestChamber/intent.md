# OrbTestChamber — intent

**Tutorial-of-one** for the orb gesture slice (see `doc/ORB_GESTURE_SLICE.md`).

A single `orb_test_rig` artifact sits at the centre of an empty 9×9 room. The rig instantiates an `OrbGestureDetector` under the XR rig and a `CatalystOrb` under itself, then spawns three creatures around itself at radius 3 m: `catalyst_foe`, `fractal_hydra`, `gradient_hunter`. Each is movement-zeroed so the test can be felt without chase pressure.

The map's job is **felt-right testing of the new verb**. Two modes:

- **Two-handed sustained dose** — bring palms within 30 cm, extend them past 40 cm from the head, hold for > 0.3 s. The orb materialises at the midpoint, projects forward as long as the gesture is held.
- **One-handed burst with cooldown** — extend one hand past 35 cm with palm forward, held > 0.2 s. The orb fires from that controller for 0.4 s, then that hand cools for 1.2 s.

Conversion is dose-based: 0.6 s of continuous cone contact advances one creature one personality step along FOE → WARY → NEUTRAL → CURIOUS → FRIEND.

## Design rule (load-bearing)

*No orb-action produces a number on screen or a confirmation toast.* The dark spot stays habitat only if we refuse legibilisation creep. See [`/blog/2026-05-11-cognitive-water`](http://localhost:3003/blog/2026-05-11-cognitive-water) and the sieve pass at `doc/sieve_passes/2026-05-11T10-54-27_orb-gesture-detector.md`.

## Acceptance criteria

- A new VR player figures out the gesture within 30 seconds with nothing but the room and the creatures in view
- Both modes work; both feel different
- The cooldown is felt (gesture simply does not form on a cooling hand)
- No numbers, no toasts, no reticle — confirmed by inspection at commit time
- Each of the three creatures, when converted, shows distinct personality-stage visuals (the existing capture gallery proves this for catalyst_foe; the other two use base `_apply_personality` flags only — visual change is movement-based)

## Sequence position

`hazards` sequence — test/debug chamber, not a curriculum stop. Promoted to a real curriculum chamber after the verb is felt-right and integrated with the bracelet's mode dispatch.

# Pickup eligibility in the museum

The Array review found that a successful direct `collect()` call did not establish a usable museum encounter. The desktop museum creates a body named `Walker`, on the default collision layer 1, belonging to `em_walker`. The pickup detector listened only to layer 20, and its identity predicate did not recognise that dedicated group. Both conditions prevented ordinary desktop approach from collecting a cube.

The scoped repair changes `pick_up_cube.tscn`'s detector mask from `524288` to `524289`: layer 20 remains enabled and layer 1 is added. `pick_up_cube.gd::_is_player()` now also recognises `em_walker`. It does not add the museum walker to broad player groups or change its collision settings. Ordinary layer-1 bodies can enter the detector, but the identity guard rejects them.

Run `python tools/run_pickup_encounter_probe.py --label after`. Evidence, logs and hashes are in `ada_run/encounter_pilot/Pickup_detection/`. The actual pickup packed scene is exercised through genuine `Area3D.body_entered` events. The probe never invokes `collect()` or the entry handler directly.

| Case | Before | After |
| --- | --- | --- |
| Unrelated body, layer 1 | Detector did not receive overlap | Detector receives overlap; no collection or score |
| `em_walker`, layer 1 | No detection or collection | Collection; score increases once by 1 |
| `player_body`, layer 20 | Collection | Collection remains; score increases by 1 |
| `em_walker`, layer 1, `hold=demo` | Remains present | Remains present; detection stays disabled |

Each case first waits outside and verifies that the pickup remains. The test capsules use the museum's radius, height and foot origin, then are positioned inside the detector. This proves eligibility and the negative guards. It does not prove a continuous approach, passage width, safe return, XR controller operation, readable addresses or learner understanding. The separate museum walker probe is required for those spatial questions.

The reusable check is to follow the entire input path. Method-level state checks, detector overlap, eligible player identity, spatial approach and visible output are distinct pieces of evidence. Passing one must not stand in for the others.

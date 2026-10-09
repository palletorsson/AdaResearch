# Tutorial_Single encounter pilot

The existing western floor now supports the room's first experiment: pause short of the pickup, predict its response, approach into contact, then inspect the empty position. The actual museum walker completes that sequence. The chapter already describes contact and disappearance; map metadata now uses the same interaction vocabulary.

Two placement layers had obstructed the encounter. An old whole-hall necklace stamp placed the pickup at map-space `(2.5, 3.5)` instead of its map's `(2.5, 4.5)`. Retiring that hall's `stamp` flag restored current map placement. The generated opening gate then stood across the correct pickup position, with a three-metre collision slab and jambs blocking the western approach. The room now declares `map_info.museum.gate: false`, using the museum's existing per-room setting.

The authored structure and all five artifact tokens remain unchanged. The map's description, title, learning objectives, documentation and special instructions no longer promise hand grabbing or a nonexistent exit portal. They ask for observation, prediction, body contact and an account of event versus state. The focused `final.md` remains intact.

## Runtime evidence

Run `python tools/run_encounter_probe.py Tutorial_Single --render --spec ada_run/encounter_pilot/single-spec.json`. The durable report is `single-museum.json`, with input hashes in `single-museum-sources.json`, the exact spec in `single-spec.json`, and launch output in `single-museum.log` beside this note.

| Check in actual museum geometry | Result |
| --- | --- |
| Pickup, pause and western corridor support | All three rays meet floor at approximately y=0 |
| Western corridor to approach | Actual walker reaches the specified approach |
| Pause about 1.3 metres west of cube | Pickup remains present |
| Continue into pickup position | Physics contact removes the pickup |
| Return along the same corridor | Walker reaches the return position |

The walker is the museum's own layer-1 `CharacterBody3D`, with its `em_walker` identity. The contact case does not call the collection method or its signal handler directly. The earlier pickup fix admits this body to the detector while preserving the XR layer and rejecting unrelated layer-1 bodies; see `pickup.md` for those separate negative tests.

`single-pickup-before-eye.png` shows the cube from the western approach before contact; `single-empty-eye.png` shows the emptied position after the successful contact run. The before-contact view used a separate visual-only boot of the same museum snapshot, with no walker actions. Its report and spec are named `single-before-contact-view*`; that boot became the latest transient `ada_run` report. Use the durable `single-museum.json` for the four verified walker actions.

`single-museum-stamped.json` retains the first failed inspection with the old artifact position. `single-museum-gate-blocked.json` retains the failed approach after map placement was restored, with the gate's three-metre surface over both pickup and pause cells. No live bake entries were deleted. The scoped sequence refresh updated the two museum plans and retained unrelated rows.

## Limits and next check

The probe positions the walker at each leg's start and controls locomotion while ordinary museum input, catch and streaming logic are paused. It establishes collision clearance and contact for these short connected floor segments; it does not establish an uninterrupted journey from the hall entrance, normal gameplay safety, VR reach or learner understanding. Rendered eye views supplement the collision evidence, but no readability or headset acceptance is claimed. The engine log still contains shader-cache and existing project setup errors.

One supporting artifact remains unavailable: the runtime reports that `synthesis_stand` has no living scene. Its map token is preserved as a separate development gap. It is not needed for the chapter's primary pickup encounter.

The next useful learner check is to ask someone to stop before contact, predict what will change, collect, and distinguish the cube's repeating animation from the irreversible state change for that instance. Ask what the detector could know about their intention. Record that explanation separately from the successful collision check.

The reusable repair is to compare the actual artifact position with the map, inspect any stronger placement override, then inspect generated architecture around the restored position. A correct map coordinate alone did not guarantee that the approach remained open.

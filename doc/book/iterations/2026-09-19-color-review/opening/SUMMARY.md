# Color opening review — 19 September 2026

Three opening halls were inspected against the source-aware review and the current museum. Preserve all three `final.md` chapters. Two concrete staging gaps needed repair; the mature column hall needed verification.

## Decisions

| Hall | Existing work that holds | Missing layer and decision | Fresh verification |
|---|---|---|---|
| Color_Context_Placed | Twenty-three column studies accumulate primitives, static transforms, arrays and colour assignment; scientific and associative attention both belong at this threshold. | Preserve the hall and manuscript. Rule plates being present is not sufficient reason to hide them or cut the opening. | 691/691 actual-museum checks: authored transforms, parts/colours, physical floor, central aisle, plate approaches and walk-around space. No headset session. |
| Color_Flashlight | RGB overlap appears before the code explanation; the fixed albedo / moving light distinction is already legible in a current museum render. Supplied pickup and release work. | The manuscript asks the visitor to aim at “the cube standing to its side”, but neither scene nor active map supplied one. Add a 1 m matte near-white receiving cube only to the standing installation. Keep the text. | 30/30 checks including real-floor alignment, cube collision, 0.5 m capsule passage, live lamp pickup/release and fixed albedo. Real Vulkan/mobile paired images. |
| Color_Nails | The secondary `nail_salon` already subscribes to GameManager nail/hand signals and recolours the giant and petite hands. The review's missing receiver source was a package omission. | Rendered inspection revealed that the two RGB boxes were behind the giant hand while their labelled plinths were empty in front. Respect the salon's 180° transform: nails `(5,14) → (9,4)`, skin `(9,14) → (5,4)`. Keep existing height, rotation, furniture, materials, roles and prose. | 36/36 checks: plinth positions in salon-local space, reachable RGB heights, supplied pickable inputs, both display hands, independent nail/skin channels, two capsule aisles. Real paired images. |

The movement through these halls remains **assign colour to assembled forms → move the light → choose a bodily surface**. The opening does not need to define colour before this comparison starts.

## Exact changes and unchanged text

`changes.diff` and `changes.json` contain the scoped before/after source diff. Production changes are the standing mount in `flashlight_demo.gd`, four placement cells plus corrected layout metadata in `Color_Nails/map_data.json`, and the maintained `probe_nail_salon.gd` regression fixture. All three `final.md` SHA-256 hashes match the start of this pass.

Nails' old probe mixed salon-local starting positions with a world-space aisle sweep and assumed the controller discovery order. Its earlier aisle failures were false. The corrected fixture fails on both old plinth positions and passes after the placement repair. It now uses a salon-local sweep and a stable nail-then-skin order, including the reverse skin-leaves-nails-unchanged check. The original failed outputs are retained under `runtime/nails-original-probe/`, and the corrected pre-repair failures under `runtime/nails-corrected-before/`.

## Capture pairs

- Flashlight: `runtime/flashlight-before-overview.png` → `runtime/flashlight-after-overview-final.png`. An additional `flashlight-after-red-on-cube.png` shows red light carried onto the new receiver. Same museum camera; the floor, board and lamp arrangement remain.
- Nails: `runtime/nails-corrected-before/nails-after-choice.png` → `runtime/nails-after-choice.png`. Both show the same fixed camera and intentionally identical teal skin / pink nails. The controllers move onto the empty plinths. Background illumination differs between launches; no map lighting/settings were changed in this audit, and the cause is not established. Treat this as a placement comparison, not evidence of a lighting repair. Shared museum source changed externally during the pass.

## Evidence limits

The final three runs contain **757 passed assertions**. These include multiple geometry/material assertions per column, not 757 different learner actions. Context was checked headlessly; Flashlight and Nails were rendered inside the actual endless museum with Vulkan/mobile and supplied grabbers. No headset, tracked hand or learner test was performed. Display-hand success does not establish that an XR rig was found.

An initial Context launch encountered a transient parse error in the externally edited `commons/scenes/endless_museum.gd`. Its failure is preserved in `runtime/context-initial-failure/`; only the owned failed probe was stopped. The succeeding current-source retry passed 691 checks. This audit did not modify the shared museum file.

Logs retain known startup UID/certificate warnings, desktop missing-XR warnings, mobile-renderer feature limitations and shader-cache write warnings. There are no script errors in the successful final runs. These environment warnings are not silently treated as headset validation.

## Review package follow-up

Include `commons/artifacts/nail_salon/nail_salon.gd`, its scene and the right-hand source-mesh dependency even though the salon is secondary. It supplies an essential comparison explicitly promised by the primary controllers' manuscript. Preserve that comparison; do not weaken the chapter merely because a primary-only export omitted its receiver.

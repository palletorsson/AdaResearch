# Void visual profiles / three-floor trial

27 October 2026. Completed desktop comparison; physical Quest testing explicitly deferred by Palle. No test APK was built or installed.

## Delivered

An opt-in scene-owned controller, `commons/void/visual_profile.gd`, with three stages: baseline, light, finish. Pass `--void-look=finish` after `--` in a normal Void launch; F8 cycles stages. Normal launches keep their original appearance. `game.gd` only creates the controller when that argument is present.

The light stage adjusts the existing sun, ambient illumination, tone mapping and distance fog. One unshadowed cool directional fill approximates indirect illumination. It is an art-directed approximation, not bounced global illumination. The fill follows the existing sun's layer mask, preserving the isolated colour-room light boundary. No SSAO, SSIL, SDFGI, volumetric fog, DOF, TAA or additional shadow map is introduced.

Finish duplicates only the tower's five scene-owned architectural material families: concrete, steel, pink paint, pipe and timber. Two 128-pixel mipmapped textures provide modest grayscale variation and normal detail via triplanar mapping. Authored artifact materials and semantic hues are not edited. Switching to baseline restores the original material references. A first registration scan was made linear with an instance-ID set; later streaming inspects only changed floor content, rather than repeatedly searching the whole tower.

The current floor records identify Rotation at 16, Colour Flashlight at 30 and the wheel machines at 63 (the machines were historically floor 59). No map, placement, dimension, collision, source artifact, catalogue entry or editor arrangement was changed. Both runner receipts hash rooms.json, layout.json and catalog.json and confirm they are unchanged.

## Measurements

Mean frame intervals in milliseconds, two 3-second samples per stage, reversed order on the second pass. RTX 3070, 1600 x 1000, 4x MSAA, uncapped, no fixed-fps simulation. The native game's live artifact workload and normal nine-floor residency window are retained. Startup, shader compilation and screenshot readback are outside the timed samples. Short desktop intervals are sensitive to background tasks; these are exploratory comparisons, not sustained-performance guarantees.

| Renderer / device | Floor | Baseline ms | Light ms | Finish ms |
|---|---:|---:|---:|---:|
| forward_plus | 16 | 2.76 | 2.77 | 3.06 |
| forward_plus | 30 | 2.19 | 2.41 | 2.91 |
| forward_plus | 63 | 7.70 | 7.72 | 8.33 |
| mobile | 16 | 2.88 | 3.50 | 3.30 |
| mobile | 30 | 1.86 | 1.75 | 1.62 |
| mobile | 63 | 6.70 | 6.48 | 6.48 |

The HTML sheet additionally shows per-pass p95, viewport GPU times and end-sample draw counts. Viewport GPU time is not total GPU utilization or compositor time. Live animation and changed directional-shadow culling can change counts without any scene geometry change. Mobile here means the renderer on this PC; those timings are not Quest results and should not be used to predict headset frame rate.

## Evidence and scope

- Forward+ and Mobile each pass 14 checks: the actual authored floors load, geometry/collider poses stay fixed across photo stages, camera and residency remain fixed, baseline disables the fill and restores material references. There are 18 timed segments and nine captures per renderer. Motion/physics are paused only for each matched screenshot triplet, then restored before measurement. Animation phases can differ between the two separate renderer runs.
- Eight additional native checks pass for the actual launch flag, a single controller, unchanged source material, real dispatched F8 events, tone-map/material restoration and cycling back to finish.
- Both native logs have no engine errors. Existing Jolt solver-bias and source painting-viewport anchor warnings remain disclosed in the logs; they were not repaired during this visual pass.
- Source receipts, logs, checks and native captures: `doc/ports/2026-10-27-void-visual-profiles/`.
- Side-by-side reading sheet: `doc/book/iterations/2026-10-27-void-visual-profiles/index.html`. No JavaScript is needed; lighting-only stages use native HTML details controls. The page is verified in the in-app browser.

## Visual judgement

The machine area benefits most: directional shadows and a less uniform structural finish locate objects on the floor and distinguish the supporting cubes and wedges. Rotation's capsule silhouettes and surrounding surfaces read more clearly, while its existing large labels and sharp un-bevelled teaching cubes remain. The colour room's warm wash is less bright; the darker neighbouring exit is a tradeoff to review. Materials are intentionally a small second step. This is a candidate profile, not a declaration that every hall now looks better. It is not enabled as the default.

Quest 3 was detected over USB but asleep. Palle selected “Do desktop now; defer Quest testing.” Stereo frame budget, on-device shader/material cost, thermals and headset readability remain unverified. No headset session or app was changed. The future Quest pass should warm the same views, measure stereo CPU/GPU/compositor timing at the real render resolution and refresh rate, and check sustained behaviour and moving-head readability.

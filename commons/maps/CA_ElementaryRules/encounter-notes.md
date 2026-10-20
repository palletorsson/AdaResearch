# Enlarged neighbourhood — 25 September 2026

`structure_growth` remains the primary work. The map opts into `room:neighbours`; ordinary `study:states` placements remain unchanged.

`neighbour_room.gd` reads the 27 actual entries around (26, 22, 24). It shares the original solver, seed, buffers, controls and held clock. It adds no collision, sensor, rule, button or random source. Its 27 boxes are 0.52 m wide at 1.13 m spacing; empty positions remain wire outlines. Gold marks the central address. Directions between neighbours are preserved while the display spacing is enlarged. The compact specimen keeps its own scale and surface culling; the new view shows every occupied position in this neighbourhood, including ones the compact renderer can hide.

For seed 23090 under the existing 6-8/6-8/3/M rule:

| Generation | Centre | Active neighbours |
| --- | --- | --- |
| 0 | 1 — active | 11 |
| 1 | 2 — fading | 7 |
| 2 | 0 — empty | 5 |

The seven-neighbour count belongs to generation 1. It does not permit birth at that update because the central state is 2, not 0. This is a witnessed instance, not a claim that all fading cells have seven neighbours.

VIEW copies the source height-gradient mapping, using original addresses rather than the enlarged world coordinates. REPLAY restores the whole seeded volume. The fixed selected address also has a small depth-tested outline in the compact specimen; other cells can occlude it.

## Evidence and limits

49 native checks pass, with eight actual museum mouse-ray clicks and a supplied CharacterBody route through the gaps on the existing floor. Every shown state and colour, absence at state zero, shared controls, complete replay, budget, no extra collision and legacy opt-in are checked. The final process exits 0 without GDScript errors. Native images and exact diffs: `doc/book/iterations/2026-09-25-ca-lingering-cell/index.html`.

The full 125,000-cell update took 153.009 ms in the final run; the pre-change measurement was 166.710 ms. This variation is not an optimisation result. The solver is unchanged and its single-frame cost remains a VR problem. Existing missing-UID, environment, registry and renderer warnings, plus generated-art build warnings, remain in the log.

The narrow supplied desktop walking/input tests do not establish whole-route traversal, tracked-hand reach, headset comfort, Quest performance or learner acceptance. The first outside camera hid the chosen cell; later views approach it through a gap. Diagnostic captures are retained.


## 8 October 2026 — A state that lingers

The next lesson follows CA_Introduction's old/next arrays into three-state 3D cells. `tutorial.md` prints complete `volume.gd` and the unchanged carried `point_body.gd`; maintained sources are in `doc/book/studies/cellular-automata-through-the-hands/CA_ElementaryRules/`. The study uses 7³ cells, a stated 12-cell seed and the installed 6–8/6–8/3 rule. Its seed and uncullled rendering differ explicitly from the museum's 50³ installation. A two-cell seed is the independent transfer task.

The installed `room:neighbours` opt-in adds `state_hand.gd`: a frozen pickable point resting at 1.12 m, trigger connected to the existing study's `step_once`, release parks. Moving it does not select or edit a cell. One fixed gold address supports successive observation. The neighbourhood caption reports generation, centre state and active-neighbour count. The base solver file and its rule/seed are unchanged by this pass.

Source-grid rows 9–12 are level floor inside the outer walls; this removes the disconnected rear pits and tiers while retaining the central opening. Both authored works remain. Entry moves to (6,0), exit to (6,13), both at the central thresholds. Entry cage and generic extra gate are disabled for this map; exit approach is from the hall. Only its generated museum-plan row was replaced in live and shipped plans.

27 construction checks pass using exact extracted printed code: 81 transition cases, 26-neighbour active-only count, distinct old/next, independent seed, all faces empty, 8 mixed-state seeds × 8 updates matching the installed solver, reverse traversal, two faulty variants rejected, renderer/state separation and actual XRTools with supplied poses. 30 native museum checks include camera retention, installed pickup/action/release, same-volume neighbourhood, VIEW/replay and four walking routes: 197 samples, layer-1 capsule width .56 m/height 1.7 m, level-floor rays. Supported portal approaches pass; actual portal transfer is untested.

Before/after overhead and raised views, visitor views and temporary mounting of the printed study are in `doc/book/iterations/2026-10-08-ca-a-state-that-lingers/index.html`. Early learner framing confused the two volumes; it was moved for capture into the clear gallery. A later angle avoids a foreground neighbour covering the empty centre. Diagnostics retained. The learner study is not permanently added to the map.

The full installed update measured 212.7 ms in the final desktop run; it still needs performance work before smooth VR playback can be claimed. No physical headset, Quest or independent ghost-student test. No GDScript/parse errors in successful logs; existing project warnings remain.

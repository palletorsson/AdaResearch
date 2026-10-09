

## 2026-09-09 — configuration recovered and enclosed

Source: a36f33c996004abcdc67ea2a0ac3fce72eba42fd. Original size [11, 12]; enclosure [19, 20]; every original structure and utility cell preserved at offset (4,4). The real GridSystem retains grid-dependent colour behavior, inside perimeter walls, with no staged glass arena or fire.

Authored exceptions: [{"token": "flashlight_demo", "from": null, "to": [9, 9], "change": "historical map was empty; install its existing namesake demonstration"}].

Neutral matte grid surfaces; quiet edges, no emission. Historical authored colours still apply.

Source layouts and prior manuscripts are archived in `doc/space/color-recovery-2026-09-09`. Runtime grid and placement checks pass; headset walkthrough remains unverified.

## 2026-09-10 — first possible-bodies lesson

The recovered installation put lamp handles at world y=0.1 and buried half the receiving board. Its central height-two grid cube interrupted the initial comparison. Added an opt-in `mount:standing` to the existing artifact: root at floor level, handles at 1.1 m, full board above floor with collision. Lowered this installation's lamp energy from 12 to 2.5 and aimed white aside initially. Legacy mounting stays available to other maps.

Moved the central grid cube from (9,8) to (13,8), keeping it as a side receiver/shadow caster. Filled the old utility recess at (9,14). The original walls and map dimensions remain. Pre-edit map, manuscripts, root script and failing baseline report are in `doc/space/flashlight-lesson-2026-09-10/before/`.

Added `final.md` around the actual aim-away / overlap / return encounter. Rewrote the stale supporting texts, which had claimed missing controls, a prism, a dark sphere, a different scene path and a closing-room position. Primary remains `flashlight_demo`, matching placement and the book anchor.

Verification: `commons/testing/probe_flashlight_lesson.gd` loads the actual endless museum. Forty assertions pass: map and placement, floor and mounting, four colours, pickup/movement/release for four lamps, rendered RGB contributions, and the book's held-lamp aim-away / aim-back gesture. The board material remains unchanged. Report: `ada_run/probe_flashlight_lesson.json`. Unmodified render captures: `ada_run/flashlight_lesson_shots/`, including `arrival.png`, `red_aimed_away.png` and `red_aimed_back.png`.

This was a desktop Compatibility-renderer check with a supplied grabber. It does not establish tracked-hand usability, headset comfort or a frame-rate target. Fixture-only light visibility toggles isolate RGB contributions; the separate aim-away check uses the implemented pickup motion, without toggling the light.

The final run has no script errors. Startup still logs the existing unrecognised UID `uid://rwex60pqapc`; the tested museum scene and lamp interaction load and complete. Corpus index regeneration also reports the existing Tutorial_Disco row-width mismatch, outside this room.

Reusable method: keep the receiver fixed, change one contributing relation, trace the actual assignment, then carry the comparison onto a different receiver. Next missing Colour manuscript to inspect is Color_Rainbow; Color_Nails already provides the immediate book handoff.

## 2026-09-23 — the construction meets the light

At the author's request, add a coarse seven-division sphere to the standing flashlight installation. Keep the mature board comparison, existing receivers and four pickable lamps. The sphere uses the same near-white material as the board, so its changing appearance can return to the earlier primitives without adding painted facet colours or a new interface. Canonical final.md gains two encounter paragraphs and the shared native same-camera illustration.

Two implementation issues were caught before completion: the grid's shorthand parser initially read the new numeric key as yaw, so the key is now explicitly registered; SphereMesh includes degenerate pole triangles, now removed before flat normals and collision are built. The receiver was then moved farther sideways so the older grid cube no longer obscures the pedestal on approach. Final run: 43/43 checks pass. The sphere has 42 nondegenerate triangles, with seven divisions around it. Existing unrelated startup UID and Compatibility-renderer warnings remain in the archived log; no script errors occurred in the completed run.

Evidence, original files, exact text/source diffs and the current reading are under `doc/book/iterations/2026-09-23-flashlight-faceted-sphere/`. Supplied XRTools grabber motion is desktop evidence, not a headset or learner test. No live museum process was restarted and no live bake/save was overwritten. Next: Color_Nails, where the colour can become a chosen surface on the acting body.

## 2026-09-28 — follow the light before reading its value

A light editorial pass lets the board-to-sphere encounter finish before the RGB assignment is explained. The opening begins at the visible pools, and the code returns to the red lamp the reader has just followed. The dense channel paragraph is split; the future glass-wall aside is removed from this moment. The unchanged material, flat normals, other illumination and RGB-model limits remain. The ending and the handoff to Nails are preserved verbatim.

No artifact, map or interaction changes. The three artifact scene/builder hashes still match the 23 September native run. The later map change is the already-recorded standalone spawn correction from sp to s; the receiver and its placement remain. The same-camera native figure is retained with its original date. No fresh runtime or headset test is claimed. Review and exact text diff: doc/book/iterations/2026-09-28-flashlight-a-colour-between/. Current Colour capture refreshed. Next: Color_Nails.

# Menger Sponge: a hole becomes a place

Completed 14 September 2026. [Illustrated review](../../research/possible-bodies/menger-encounter.html) · [local encyclopedia](http://localhost:3003/research/possible-bodies/menger-encounter.html).

The existing flight installation now has a finite construction encounter. Start with a nine-metre cube, make one cut and then another, compare count with retained volume, inspect the discarded crosses, and fly through an opening. A smaller opening establishes a specific difference between a geometric connection and a route for the current player capsule.

## Preservation and implementation

All five authored placements remain in the same cells: `menger_sponge`, `diffusion_limited_aggregation`, `catalyst_prompter_box`, `dark_sphere`, `catalyst_vent`. The 15×18 map structure, utilities, museum settings, basin and floor patches remain unchanged. The only interactable-token change is `#lesson:true` on the existing sponge. The source scene and both original flight scripts are byte-identical to the archived pre-change files.

The opt-in helper is `commons/artifacts/menger_lesson/menger_lesson.gd`. NEXT/BACK/RESET select cuts 0–2 using the existing generator. GHOST reveals the complement; FRAME marks the original extent; RULE exposes the operation. The compact three-by-two desk has a 1.18×0.36 m transparent tilted readout. It stands outside the flight enclosure, to the right of its front entrance.

NEXT/BACK/RESET refuse while a grouped player occupies the enclosure. Leaving never triggers a queued change; a fresh press is necessary. GHOST/FRAME preserve the solid cubes and collision. This interlock covers the desk controls, not every possible external script/editor call. It gives the book's discussion of maintaining an inhabitant's conditions a specific implemented basis without claiming a general solution to authority or consent.

At fixed outer bounds of 9×9×9 m, the source produces:

| Cut | Retained cubes | Edge | Retained volume |
| --- | ---: | ---: | ---: |
| 0 | 1 | 9 m | 729 m³ |
| 1 | 20 | 3 m | 540 m³ |
| 2 | 400 | 1 m | 400 m³ |

The two-cut complement has 147 non-colliding ghost meshes: seven at edge 3 m and 140 at edge 1 m, totalling 329 m³. A third cut would request 8,000 retained cubes; it is outside this desk's budget. No headset performance or entropy claim follows from these counts.

## Text and shared records

Seven room texts are aligned: final, technical, critical, tutorial, summary, blurb and intent. `final.md` has one `menger_sponge` anchor. Primary roles and their explicit order were already correct and are unchanged. Only this hall's book pearl, trunk/hand overrides, active spine records and both museum-plan rows were updated. The live Necklace lists **one primary, menger_sponge, 816 words**.

The preceding flight manuscript and supporting texts are archived under `before/`. The old technical/critical texts still described recursive trees; those are replaced by source-grounded accounts of this room. DLA remains secondary with its own random-walk clock and attachment rule; it has not been redesigned or relabelled as a controlled comparison.

## Validation and limits

- Final isolated Godot run: PID **24696**, exit 0, **99 checks**, no failed checks or GDScript errors. See `receipt.json` and the captured report. All recorded source hashes still match.
- Construction counts, actual dimensions/volumes, fixed bounds, complement visibility, non-solid frame, repeated rebuilds and the occupied-room refusal pass.
- All six controls pass through synthetic input in the project's standalone DesktopPlayer pointer pipeline inside the museum. The first run exposed wall obstruction of two controls and unreliable generated ghost names; moving the desk into the approach and identifying ghosts by metadata corrected both before the final run.
- Native museum keyboard flight passes ground entry, ascent, hover, central passage, circling, roof/side/cube collision, descent, ground exit and resumed gravity. Synthetic XR controller input separately passes the XRTools movement adapter's ascent, hover, exclusive activation and release. The flight box instance survives rebuilds.
- A ray crosses the one-metre axial tunnel; the native museum capsule cannot enter. Its capsule is 1.5 m high and 0.64 m wide. The separate standalone pointer rig has a 1.8 m capsule; these are different fixtures. Tracked XR bodies may differ again.
- **21 scoped content checks** verify preservation, map-only plan edits, book/primary alignment, previous review validity and the exact runtime receipt. **24 published assets** return HTTP 200 with exact source hashes. `content-checks.json` and `http-checks.json` hold the results.
- Browser inspection: all nine displayed images load at 1280 px source width, no horizontal overflow at the tested 1280 px viewport, the manuscript disclosure opens, and the live primary card matches the book. Actual Godot photographs were visually inspected.
- Scoped `git diff --check` passes. Existing UID, viewport-texture and compatibility-renderer feature diagnostics remain in the engine log; this is not a clean-project diagnostic claim.
- User editor PID 40112, interactive museum PID 2936 and saved hand were preserved. The runner owned its hidden process and isolated hand/control/plan/output paths. No agents dispatched, commits made or unrelated files reverted.

Human headset reach, comfort, legibility and Quest frame time remain pending. Native museum mouse interaction with the desk is not certified by the separate pointer test. DLA growth timing and secondary experiences remain further work. Earlier flight evidence remains as a historical record; the new 99-check receipt validates the current teaching configuration.

## Next

**Fractal_GoldenSpiral**: inspect its complete existing collection and prior configuration before selecting or revising encounters. Move from geometric retention to a numerical recurrence and the additional mapping that makes it visible. Preserve useful works; distinguish Fibonacci arithmetic from spiral, height, turn and scale rules. The guide records this as next work, not as completed development.

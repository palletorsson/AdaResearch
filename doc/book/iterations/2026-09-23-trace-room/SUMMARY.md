# Point Trace — room arrangement, 23 September 2026

The first room now centres the drawing tools, mounts the two displays against their walls, and gives the board a reachable shelf with sculptural pens.

## Decisions and changes

- Shift all five drawing stations one cell right, preserving their relative order, plinth heights and recording settings. Their centres now span X=2.5–6.5 m around the room centre X=4.5 m.
- Mount the 2.0 by 1.2 m whiteboard against the east wall, its bottom at 0.95 m; the shelf top is 0.925 m. Increase width from 1.6 m to give the five tools comfortable spacing.
- Raise the hand telemetry diptych by 0.45 m and move it back against the rear wall.
- Put four differently shaped pen grips and the eraser on the shelf, with fixed labels for NO GRID, 10 mm, 40 mm, 80 mm and ERASE. Preserve their inks and drawing rules.
- Released shelf tools now fall. Below the dock by 0.25 m, or more than 3 m away, they return after 1.25 seconds. Held tools are exempt. Return resets the existing rigid body; it creates no duplicates.
- Exclude automatically generated benches in this map: the walking probe found one occupying the left aisle beside the tools. The other room artifacts and all structural cells remain.
- Change one sentence in final.md: “Four pens hang in front of the whiteboard” becomes “Four pens wait on the shelf beneath the whiteboard.” Update technical.md and the encounter hashes. The rest of the book text is preserved from the turn baseline.

## Evidence

Godot 4.6, actual isolated Endless Museum hall: **22 placement/interaction checks and 4 controlled walking checks pass**, exit 0. Checks cover wall positions, the centred row, shelf tools and resolutions, accepted/rejected writing contact, actual desktop pickup/drop hooks and XRTools pickup using a synthetic controller, held-tool protection, falling and return without duplication. The whiteboard capture retains the small dot drawn by the probe.

The four selected walks cover the left aisle, rear aisle, central exit and whiteboard approach. They are independent controlled paths, not a complete learner walkthrough. Actual room, board, shelf and telemetry images were inspected. No headset comfort or live tracking validation is claimed. The existing unrelated missing-UID notice and legacy material warnings remain; the final run has no GDScript parse/compile/runtime errors.

Shared whiteboard shelf behaviour is opt-in through `#pen_shelf:1`. Other boards keep their existing arrangement by default. No live museum session was restarted, no live bake or save was replaced, and no commit was made. The probe runner uses the private `ada_run/encounter_pilot/Point_Trace` location.

## Files and reproduction

`changes.diff` compares only this task against its preserved baseline. `source-manifest.json` records the finished source hashes; `museum-runtime.json` gives individual results. Run `python doc/book/iterations/2026-09-23-trace-room/check_hall.py` from the repository to rebuild the isolated evidence.

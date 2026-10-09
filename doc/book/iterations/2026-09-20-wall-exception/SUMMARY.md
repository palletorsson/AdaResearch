# The paper follows us

The first encounter with the museum's thin enclosure now belongs to **Tutorial_Tiling_Walls**, in **array_tutorial**, before Color. It follows the six existing black-and-white wall studies. Those studies and their image rules remain; a second primary artifact, `wall_exception`, brings their ONE EXCEPTION image onto an operable part of the enclosure.

EXCEPTION changes the image. TURN WALL turns the surface and its collider through a quarter turn. The visitor can walk onto a small exterior landing, look at the edge and plain reverse, and return. The landing has a floor and glass rails: this outside is also made. The opening and landing inhibit turning while occupied. The text carries that discovery before explaining the distinction between an image value and the surface that admits or refuses a body.

## What changed

- Added `commons/artifacts/regularity/wall_exception.gd` and its scene; registered it beside `tiling_principles` and promoted it after that artifact in the hall's primary order.
- Shared the actual ONE EXCEPTION texture, including later changes, through the existing generator's new `patterns_changed` signal. Turning the wall does not regenerate or alter the image.
- Replaced the east boundary at map cells (20,25) and (20,26). An explicit `museum.turning_wall` declaration and a matching placed owner are required before both museum wall layers are omitted. The placed artifact uses the existing `#pin:1` convention so the layout does not pull it inward.
- Removed this hall's embedded GridSystem setting. It now uses the authored museum floor and enclosure directly, which makes the door a passage through the museum itself. The six studies retain their authored position and wall mode. Other halls' simulation settings are unchanged.
- Added the encounter to `final.md`, preserving the previous paragraphs and the onward connection to the timed floor. Updated the tutorial, core encounter record, plan and derived necklace.

## Evidence

The [control report](controls-report.json) records 13 passing checks in the actual built museum: six retained fields and shared texture; image change without an opening; anchored placement; replacement of both wall layers; refusal of an ownerless declaration; closed-wall collision; gradual turn with collision; completed quarter turn with the same image; walking out; prevention of closure while outside; walking back; closure after return; exact restoration of the original image. Approach and landing floor rays also passed.

The walking probe uses the museum's CharacterBody and `move_and_slide`, with normal input and catch logic paused. Button signals are exercised through the real controls. This verifies geometry and controlled movement, **not headset reach, comfort, continuous gameplay or learner understanding**. The before capture used the previous embedded-grid hall; current closed/open images show two states of the updated hall, not software before/after versions.

[Closed](closed.png) · [Open](open.png) · [Looking back](outside.png) · [Plain reverse](reverse.png) · [Exact book diff](Tutorial_Tiling_Walls.diff)

`long_museum.py --check` and `museum_necklace.py --check` match their sources. Their existing cross-project warnings remain: six maps with disagreeing layer dimensions, and 41 claimed placements not built anywhere. The Godot run also reports existing shader-cache write errors and occasional slow decorative sculpture construction. These are not claimed fixed by this pass.

## Next

Try the control and return route in a headset when available. The wall slab is 25 mm thick in this experiment; “thin paper” is a description of its apparent adequacy as an enclosure, not a literal thickness measurement or a claim about every museum wall. The exterior sky is still rendered; the missing continuation is walkable ground, not all visual content.

Return to the bounded L-systems pass next. That sequence can later return to this early encounter with additional powers of construction, rather than first introducing the enclosure question there.

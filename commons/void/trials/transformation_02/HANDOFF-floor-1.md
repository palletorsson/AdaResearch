# Trans_Body transfer

Codex retained all six source placements at scale 1. The corridor is turned 180 degrees: `x = 5 - source_x`, `z = 12 - source_z`. Both shafts remain open. This is an editable collection, with no enclosing museum walls or new route imposed.

The original three body-operated instruments remain distinct:

- Approach Wall turns its solid slats towards the visitor, follows sideways movement, and closes afterwards. Its source clamps seven requested slats to five to guarantee shoulder clearance.
- Carve Grid retains 484 cells, removes only cells touched by the actual visitor capsule, and retains the cut through the original LeakData mechanism. `room: Trans_Body` supplies the missing map identity without changing its persistence algorithm.
- Approach Scale shrinks nine independently solid blocks around the visitor and restores them after departure. The source's `is_open()` diagnostic considers distant pairs too; the probe checks the entered pair's actual gap and physically walks through the field instead.

The two original film monitors retain their SubViewports and real pointer controls. The foundation-state monitor's APPROACH/AWAY, FRAME and RESET remain explicit model inputs, not sensors pretending to measure the current player. The dark sphere keeps its original inert Transformation stage.

The focused native probe uses real desktop walking and synthetic XR walking/pointer input. It checks physical passage, reversible wall/scale state, lasting cuts, matching visible/collision dimensions and monitor state changes. AnimatableBody poses commit on the following physics sync; the seating check allows 1 cm while moving, with observed discrepancy below 5 mm. The final acceptance receipt is evidence/checks.json; development results are not acceptance.

Original map data and chapter files are unchanged. No curation or final-text rewriting is included. Physical-headset play is still required.

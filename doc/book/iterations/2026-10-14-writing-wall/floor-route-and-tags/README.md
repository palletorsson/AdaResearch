# Floor magnets, walking order and writing tags

Applied on 2026-10-14 to Random_Definition and its web writing wall.

Later direction correction: the visitor enters at the top and exits at the bottom. The shared order now traverses the upper rows first, crosses the east doorway between stops 7 and 8, and finishes at the bottom. Artifact positions, tags, notes and conceptual connections are unchanged. See top-entry-correction.json for the current order; layout.json and verification.json below record the earlier arrangement. The UI labels the top entry and bottom exit. All 18 tests and the focused TypeScript check passed again after this correction.

Each magnet reserves three columns by two rows, anchored at its top-left floor cell. Dragging rejects walls, missing floor, overlap with another magnet and a placement that disconnects the walking route. Linked instruments remain independently movable. The room placements and the shared writing-wall order were saved together in this iteration; existing magnet writing, notes and conceptual connections were preserved.

The thirteen-stop arrangement in layout.json has twelve reachable walking legs. The sixth leg passes through the east doorway at grid cell (11, 9). Walking uses cardinal floor steps and one consistent approach point per artifact. This checks the floor plan, not Godot collider clearance or VR usability; a runtime walkthrough remains necessary.

Solid blue walking arrows and dashed purple conceptual connections have separate visibility controls. Conceptual connections retain their original direction and labels; they do not determine the walking route.

Tutorial and Final are independent editable tags on each magnet and in the inspector. Neither tag gives a plain artifact card; one tag gives its colour strip; both give two strips. Existing cards begin untagged rather than deriving classification from their text. Tag changes participate in wall undo and Save wall, and do not rewrite tutorial.md or final.md.

Verification:

- All 18 writing-wall tests passed, including overlap rejection, linked-part preservation, doorway access, continuous routes, stale-save protection and all four tag states.
- The focused writing-wall TypeScript check passed.
- The cell-edit endpoint returned HTTP 200 and the museum strip rebuild exited successfully.
- The saved model was reloaded and checked for all thirteen placements, twelve route legs, the doorway crossing and unchanged notes, connections and writing seeds.
- The strip rebuild also reported existing layer-size disagreements in Random_Rotate_Random_XYZ and Noise_Inside_Noise; these unrelated maps were not edited.
- Browser visual verification was unavailable because the browser tool rejected inspection under its URL policy. No screenshot from an earlier iteration represents this result.

before-room-and-wall.json contains the exact pre-change source text. placement-save.json contains the save and undo receipt. verification.json records the saved version, order and routed floor cells.

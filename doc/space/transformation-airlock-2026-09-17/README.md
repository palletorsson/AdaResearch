# Make Room: Transformation's final door

User confirmed the door belongs at the end of the whole Transformation sequence, in Trans_Pit. Added 17 September 2026.

Two armoured leaves translate apart and upwards, turn in the doorway plane, and shrink into side recesses. A stationary frame lets the visitor distinguish position, orientation and size. This returns to the cumulative pickup animation in Trans_Pre as a full-size passage.

The artifact is `transformation_airlock`, placed at source (7,29). Trans_Pit is now 15×33; the previous 25 rows and their studies are preserved, apart from moving the old teleporter from (7,23) to (7,31), behind the door. Nine-metre wall collars join the eight-metre frame to the grid walls without half-metre side gaps. The doorway is 3 metres wide and 2.8 metres high. The museum's outer observation route remains available.

Approaching from either side starts a 4.8-second opening. The door stays open while a visitor occupies its clearance area and reverses after three empty seconds. Re-entry reverses closing. No global pickup, scanner or progression signal is used, and no player relocation occurs. The physical leaf bodies retain unit scale; their convex collision shapes resize with the visible armour.

The narrow test capsule can pass during the translation stage, before the other operations finish. The door demonstrates their combination; neither implementation nor prose claims that all three are mathematically necessary to pass. A reader is invited to approach, stop and follow one strip through the complete motion.

## Text and data

The new encounter is primary and appears at the end of Trans_Pit's `final.md`. Roles, encounter order, book captions, sequence content, sequence beats, source-derived museum plan rows and compiled Transformation captions are aligned. Fourteen content checks pass, including preservation of prior study rows and the reading page's live text hash. Source byte hashes preserve Windows line endings; the reading API uses normalized text.

Read at http://localhost:3003/compose/sources?map=Trans_Pit. Reload or re-enter a running museum hall to rebuild the room.

## Verification

- `probe_transformation_airlock.gd`: 25 focused runtime checks pass. Includes 924 ray queries through intermediate poses, closed/open capsule traversal in both directions, nonzero parent position and 180-degree yaw, proximity opening, occupied hold, empty closing, return/reversal, ball exclusion and no player relocation. See `test-results.json`.
- `shoot_transformation_airlock.gd --museum`: nine placement checks pass in the actual embedded Trans_Pit grid. Correct source position (7,0.5,29), metre scale, level runway, closed/open capsule clearance and both side collars. Four actual museum screenshots are included. See `museum-placement.json`.
- Six additional renders show the actual artifact in isolation. These are Godot captures, not generated concept images.

Headset comfort and learner reading remain untested. Existing Godot UID, certificate and renderer-cache warnings were present; the focused artifact probe had no script error.

New implementation: `commons/artifacts/transformation_airlock/`. `apply_door.py` records the one-time, scoped content migration; it intentionally refuses a second run against the extended map. Snapshots in `before/` support review without reverting other tasks' changes.

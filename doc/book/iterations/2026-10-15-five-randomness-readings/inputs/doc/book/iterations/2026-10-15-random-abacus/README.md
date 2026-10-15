# Random Touch: five-row abacus

15 October 2026. Palle requests a smaller abacus: rows 1–4 at different speeds, row 5 with two-dimensional movement.

The open frame holds five one-metre rods and 13 cm diameter beads. The complete floor stand is approximately 1.3 m wide, 0.55 m deep and 2.15 m high including the title. All rows face the same direction. Rows 1–4 have rates of 0.4, 0.8, 1.6 and 3.2 segments per second, labelled ½×, 1×, 2× and 4×. They use the same stored X positions within ±0.44 m. Row 5 uses the 1× rate and adds Y within ±0.12 m, with extra vertical clearance.

Touch still moves only the contacting virtual hand. Physical withdrawal restores tracking. Desktop right-click runs/releases a bead without moving the camera. KEEP, LOAD, REPLAY and PAUSE remain. The hall's shared seed 435 and later seed choices are preserved.

The map token stays in its existing cell and orientation. Its former scale 2 and height 0.5 become scale 1 and floor height 0 for the compact stand. Writing-wall coordinates, tags and encounter order are retained. The canonical opening keeps its approved “we” voice and the current five-stop chapter. Its tutorial, plans, writing-wall notes and source artifact card describe five rows.

The new `random-touch/3` format records all five phases and the smaller X/Y ranges. It saves to `user://random-touch-abacus-001.json`. Older three-line recordings are preserved at their original path and are not reinterpreted.

## Verification

- `tests/test_random_touch_hand.gd`: four-speed path equivalence, fifth-row Y bounds, five-row geometry, idle waiting, desktop interaction, five-phase save/load, actual XR Tools hand contact, withdrawal and cleanup. The body, head, tracked controller and other hand remain unchanged. [Log](hand-test.log).
- `tests/test_random_definition_seed.gd`: shared seed propagation, reset/replay, saved records and atomic refusal during active interaction. [Log](hall-seed-test.log).
- Godot Compatibility renders inspected: [front](front.png) and [oblique with the fifth bead displaced](oblique.png). [Render script](render.gd).

The test environment emits existing Jolt solver-bias and missing-environment warnings. Physical headset feel and independent tutorial reconstruction remain unobserved.

Rebuild the current tutorial with `node doc/book/iterations/2026-10-15-random-abacus/build-tutorial.mjs`. It preserves the shared-hall-seed explanation and embeds all three current artifact source files. The prose and code counts are in [text-counts.json](text-counts.json).

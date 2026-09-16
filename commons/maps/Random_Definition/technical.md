# Random Definition — replay is a procedure

The primary is `seed_replay_demo:-90#comparison:replicas#stand:table` at map cell (8,11). The 13 × 22 hall retains all 15 placements. Its two 8 × 8 grids compare one generator under a shared seed and a controlled change in draw order. This is a pseudorandom colour experiment; it does not measure thermodynamic entropy, demonstrate an uncaused event or test cryptographic security.

## State and assignment

`_rng` is a local `RandomNumberGenerator` used for colours. Each column resets `_rng.seed` before assigning one `randf()` result to each of red, green and blue, row by row. There are 64 cells, 192 assigned channel values per grid. The `replicas` comparison supplies the current seed to both columns. The implementation and draw procedure determine the repeatability tested here; the seed alone is insufficient to specify an image across changes of generator, version or mapping.

`_extra_on` causes the last column to discard `extra_draws` values after seeding but before colouring. The map uses the default of one, so that column consumes 193 draws. It retains the same cell count, meshes and positions. Relative to the unshifted stream, G becomes R, B becomes G, and the next cell's R becomes B. The final blue channel requires the 193rd draw. Replaying preserves this choice; +1 DRAW toggles it. Waiting does not advance this colour generator.

`_pick` is another local generator, randomized once in `_ready`. RANDOM requests `_pick.randi() % 1000`. This menu contains 1000 seed values and allows repeats. No guarantee of a different seed, unique picture for every seed, perfectly equal selection frequencies, or statistical independence is asserted. The separate generator prevents these controls from advancing the game's shared random state.

The slider reads a normalized handle value, clamps it to [0,1] and rounds `norm * 999` to an integer. Its displayed range is 0–999 with no decimals. Programmatic changes synchronize the handle. Source configuration can accept integers outside this menu; the handle is clamped to its endpoint while the seed captions retain the actual configured integer. Hall rebuilding restores the configured state, rather than saving the visitor's last chosen seed.

## Interaction repair and staging

The slider receiver still looked for `SEED_REPLAY/Param_0` after the panel had been renamed `Panel`. It now reads `Panel/Param_0`; a synchronization guard separates programmatic updates from gestures. The repair applies to other placements of this shared artifact as well. The generator and colour assignment loop remain unchanged.

Claude's table and east-side staging remain: a 0.85 m table, controls around 1.01 m, a west-facing comparison with the east wall behind it. The entropy cloud remains west of the visitor. The museum clear rectangle remains [[5,9,10,13]], with wall_height 3 and map-authored placement. No room layer or artifact token was altered in this review.

The panel's local dark backing and pale lettered tags are now unshaded, keeping their contrast under room lighting. The original black lettering baked into tag textures is preserved. Font enlargement is idempotent across repeated contrast passes. The action readout uses 20 px type on a 0.60 × 0.085 m case. Shared rack templates and cube colour materials are unchanged.

## Evidence

The independent 12 September run passed 65 checks with zero assertion failures and engine exit 0. Checks include exact colour bytes, independent generator reconstruction, endpoint and intermediate seeds, the real slider move path, a desktop pointer drag, all three buttons, unchanged cube positions, global RNG isolation, panel contrast, approach, unload and rebuild. Seed 42's first 193 draws and both colour assignments are exported in samples.json. Matched captures use the same desktop camera pose.

The run still reports an ObjectDB leak warning and one resource in use at engine shutdown. Exit 0 and passing assertions do not resolve that warning. No engine script errors were reported. Headset reach and close text legibility remain for a later visit. See `doc/space/random-definition-review-2026-09-12/` and `/research/possible-bodies/random-definition.html`.

# Noise Voxel: the line that decides

Continuation after Noise_One. All four authored artifacts remain and now have primary book passages: **perlin_terrain_sculptor → science_screen → voxelnoise → dark_sphere**. Illustrated review: `/research/possible-bodies/noise-voxel.html`.

## Preservation and changes

The original map, six texts, relevant scenes/scripts and alignment data are preserved under `before/`. The 15×16 structure and utilities remain unchanged, including two raised cells, two openings, spawn, teleporter and transformation utilities. No authored work was removed. A clear rectangle reserves exhibit approaches against automatically dealt museum plinths.

The bench moves from (2,2), y0.5 with shelf metadata, to (4,7), y1.35 on its own plinth. Lattice mode omits the duplicate legacy slider case and floating labels; legacy mode retains them. The enlarged, tilted four-button panel and cased six-line readout fit the model. The selected marker is centred on the selected cell. Threshold no longer triggers a redundant second rebuild/broadcast.

The receiver moves from (2,3) to (9,9). Its original 32³ metre-cube assembly exceeded the room and occluded the other works. Opt-in volume mode gives it a 24³ grid at 0.20 m spacing, framed within 5.2 m. It preserves the same current mask as the bench. The original receiver accepted Perlin settings but reset the sampler to Simplex on rebuild; the fix retains the declared contract. Equalising grid dimensions also removes the unequal intermediate sample positions. Unlinked legacy generation remains available.

Volume mode emits only the boundary of the occupied cells, including cavity walls. Internal shared faces are omitted from both drawing and collision. Fully empty results leave no stale mesh or collider. The visible exposed triangle array supplies the collision shape. This preserves occupancy while reducing CPU construction cost; synchronous rebuilding still has a frame cost.

The screen moves from (12,2), y1.5 to a floor stand at (9,4). Explicit `voxel_slice` mode now survives initialization and reads the actual same-hall source. Its two 24² images compare biased values with stored decisions. Missing source produces no invented fallback. Existing generic modes are retained. The orb moves from (6,7) to (4,12); its implementation is unchanged and its independent sine-driven material remains part of the book.

Supported arguments about sampling, thresholding, height bias, representations and connectivity remain. Unsupported descriptions of sliders, noise-type controls, soft isosurfaces and guaranteed habitation were replaced with the current encounter. The previous texts are available in the snapshot.

## Runtime evidence

Accepted run: **61 checks, zero failures, exit 0**, PID **20528**, **11:18:08–11:18:32 +02:00**, 13 September 2026. See `ada_run/voxel-review-2026-09-13/run.json` for source fingerprints. Each launch was preceded by full Godot process inventory. The owned hidden/offscreen compatibility-renderer run used an isolated saved-hand snapshot; the original hand remained unchanged.

All 13,824 field samples and occupancy decisions agree between bench and receiver at each of five thresholds. All 576 decisions on the screen agree with the stored horizontal layer. Increasing thresholds produces subsets. Mesh face counts equal the independently counted exposed cell faces; colliders equal mesh triangles and physical rays hit sampled roof faces. Empty-volume cleanup, view-only CUT and cross-hall isolation pass. All four controls respond through synthetic mouse events on the project's real desktop pointer rig. The museum reports no severed route for this hall.

The initial seed 31415 gives occupied counts 11040, 9176, 6767, 4582, 2685 and component counts 4, 15, 25, 21, 32. The different behaviour of those counters is part of the chapter, not a claim that components measure entropy or walkability.

`baseline/` records the sampler mismatch and oversized volume. `staging-run/` records the first staged comparison. `first-acceptance/` and `boundary-run/` preserve three pointer failures. The controls were initially approached beside a retained raised cube, which displaced the rig. Relocating the bench gave it clear floor; using the rig's settled floor pose prevented the test helper from reintroducing a five-centimetre fall between aiming and clicking. No artifact button signal was substituted for input.

The accepted run contains no script/shader compilation errors. Other engine warnings and startup/shutdown diagnostics are recorded in verification.json. Headset reach, comfort, traversal through the changing volume and Quest performance remain unverified. The web comparison reads recorded Godot data; it is not a browser port of the VR scene. Plan-view capture follows the control tests and therefore shows a new seed; close-up captures use the initial seed, threshold zero and selected layer y8.

## Reusable repairs

- Preserve a sampler contract through every initialization and rebuild path; shared parameters do not guarantee shared samples.
- Match sample indices before claiming two differently sized works contain the same decisions.
- Show data from the actual local source; do not silently replace missing data with a plausible demo.
- Give a model, its cross-section and its physical receiver distinct readable stages without discarding older works.
- Keep boundary geometry and collider generation tied to the same mask; omit shared interior faces.
- Separate occupied count, connected components, visibility and body-specific traversal.

## Next: Noise_6_Wall

Publication verification: 57 explicitly listed review and sequence-guide files return HTTP 200 with matching source hashes. The browser displays all seven article images without horizontal overflow; threshold changes preserve the coloured field while changing the mask and counters. The complete chapter shows five source-exact code excerpts. The primary page displays all four works in the intended order, each with its full passage. Receipts: http-verification.json, browser-verification.json and verification.json.

Inspect all existing artifacts before selecting its primary order. Carry the question of the receiving operation into an immersive shader surface: what do individual spatial scales contribute, and what remains when some are removed? Verify actual controls and shader clocks before promising isolation or freezing in prose. No next-hall changes or agent dispatch are part of this pass.

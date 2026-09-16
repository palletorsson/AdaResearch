# Randomness: performance and the loading threshold

16 September 2026. Palle reports stutter **running directly on Quest**, and proposes explicit portals, one loaded hall, and authored transitions instead of compulsory inter-hall rooms.

## Findings

The current VR path in `commons/scenes/endless_museum.gd` keeps previous/current/next architecture shells and one hall's exhibit content. `_vr_single_map_stream` demotes and promotes at a segment boundary. The old `_create_vr_passage`, `_seal_vr_passage_and_unload`, and `_build_vr_passage_target` helpers remain in the file but are not called by this path. They are not an implemented portal mode.

`stream_probe.gd` exercises the VR path with a synthetic XR eye, real hall construction and frame-boundary deletion. It passed forward and reverse ownership checks: at most three shells and one exhibit owner; demoted shells had no exhibit roots. This is a lifecycle check, not a headset or floor-traversal test.

But neighbouring architecture builds synchronously. Recorded shell builds took **186–320 ms on this PC**. Crossings caused **188–322 ms** synchronous work, and subsequent artifact admission calls reached **137 ms**. The nominal 6 ms drain budget is checked *between* jobs; it cannot interrupt a long `_ready`, scene instantiation, or procedural builder. A hidden hall is not a free hall. A portal by itself will not make these calls asynchronous.

All seven active halls were inventoried and sampled on an **RTX 3070, 1280×800, Forward+ desktop rendering**, with a fixed overview camera and the museum's own streamer stopped after loading. These are diagnostic comparisons, not Quest performance numbers. Startup stamp timings include resource loading, instantiation, configuration, and museum placement work. Global Performance monitor values are sampled/cached engine readings, not per-artifact script timings. Ablation timings vary with simulation state, shadow passes and GPU clocks; their differences must not be added together or presented as a precise CPU/GPU ranking. The normal camera's reclaim timer can briefly interrupt the diagnostic view; all final overview images were explicitly captured with the diagnostic camera.

## Specific candidates

- `random_number_book_page_1955`: 312 labels, 280 interaction areas and 874 nodes. Approximately 399 ms for its initial placement in the first desktop run. It updates 280 number labels together once per second. Preserve the touch-to-freeze operation, but batch glyph rendering and consider one sheet interaction surface with local hit coordinates. Do not simply remove the book or pin its seed to hide the work.
- `random_walk_128`: 837 mesh/label/collision triples (4,188 nodes) at its sampling moment; this grows during the run. Scaling its placement smaller does not reduce its workload. Batch the recorded walk's visual instances and create interaction proxies only where needed. The snapshot of the whole hall was taken earlier than this per-artifact inventory.
- `entropy_jar`: 81 rigid bodies at the snapshot, approximately 380 ms initial placement. Benchmark physics while agitated and after settling; retain the distribution experiment while reducing unnecessary active bodies and mesh detail.
- `galton_board`: 50 rigid bodies, 128 collision objects; approximately 337 ms placement. It needs a bounded ball pool and staged construction before any change to its statistical lesson.
- `mushrooms`: 284 separate meshes plus instanced geometry at the snapshot; approximately 306 ms placement. A small number of artifacts can still be a large scene.
- `entropy_axiom` resolves to the **MultiMesh version**, with 4,000 instances and no processing callback at the snapshot. The duplicate legacy registry entry is not evidence that the live artifact contains 4,000 independently simulated nodes. It still has a geometry/GPU cost to measure on Quest.

## Changes made

1. `CubeSpawner.gd` now clears its world-parented projectiles when the emitter exits the scene tree. Regression fixture: two cubes survived before the fix; zero survived after. Their world-space placement stays unchanged.
2. `TrngVsPrng.gd` disables its standalone directional light and its shadows when an ancestor is a museum segment (`em_map`). The standalone demonstration retains its sun. The headless contract test checks both contexts. This removes a global lighting side effect from an exhibit; it does not remove the visualization. A final Mobile-renderer check is recorded separately from the original Forward+ baseline.
3. A PC Link launcher is prepared at `tools/run_quest_link.ps1`. It uses the existing staging scene, OpenXR and the Mobile renderer, writes `ada_run/quest_link.log`, and does not change project defaults or the selected OpenXR runtime. Dry-run verified. Meta Link is installed and the Windows OpenXR runtime points to Meta. Headset connection and actual Link play remain untested.

The full portal loader and removal of automatic passages have **not** been implemented. No artifacts or hall layouts were removed during this audit. No Quest build was deployed or benchmarked.

## Recommended next implementation: Definition → Entropy

Use these two halls as a reversible pilot, with the same backward path:

1. **Hall active.** Exactly one hall owns geometry, physics, artifacts and runtime-spawned children. The player rig, clock and progression belong to a persistent parent. The next hall may be prefetched as resources; it has no running scene tree.
2. **Explicit threshold.** An authored doorway/portal takes the visitor into a small persistent loading cell. This cell has its own visible floor and collision and is outside the hall being freed. Seal the crossing only once the player's tracked body is safely inside; keep head tracking active.
3. **Unload.** Record the hall's authored edits, selected parameters, relevant seeds and progress. Remove its whole scene and external effects, drop pending jobs/references, then wait for deletion to complete before constructing the target. Returning should not accidentally become a different random experiment because its seed was lost.
4. **Load.** Poll threaded resource loading without blocking on an unfinished request. Instantiate prepared architecture and exhibits over bounded steps. Refactor procedural builders that exceed the frame budget; a single giant `_ready` cannot be made safe by putting it on a queue. Reuse valid baked geometry and invalidate it when the source map changes. Measure first-use shader/pipeline stalls separately.
5. **Release.** Restore saved state, verify the target entry and floor, and open the portal after collision and essential exhibits are ready. A failure leaves the visitor in the loading cell with retry/back available. Prevent repeated triggers while loading.

The museum remains one ordered journey. Its runtime need not keep neighbouring halls alive. Palle can author transition shapes in the map; entry/exit markers and their orientation should define the loader contract. Remove the imposed inter-hall room only when the replacement crossing supports forward travel, return, reset and saved-game entry. Do not reuse the dormant strict-passage helpers blindly: they predate the current floor-preserving streamer.

## Acceptance and measurement

- Quest capture in current hall, while crossing, and after repeated forward/back trips: frame times, CPU/GPU timing, peak memory, live physics bodies, queued jobs, and artifact ownership.
- Treat 13.9 ms at 72 Hz or 11.1 ms at 90 Hz as whole-frame deadlines, with headroom for the XR compositor. Choose the actual test refresh rate explicitly.
- Compare architecture alone, the central exhibit, then each support. Also exercise expensive interactions; an idle screenshot does not test an active physics jar or a growing walk.
- Record cold load, warmed load and steady interaction separately. GPU draw counts and node counts are clues, not milliseconds.
- Test source-map edits against cartridge invalidation, reverse travel, load failure, respawn, and preservation of experiment state.

## Reproduction

`python doc/space/randomness-performance-2026-09-16/run.py` runs one desktop process per hall, with timeouts. Do not run other render tests concurrently when comparing timings. `--quick --mobile Random_Definition` performs a shorter Mobile-renderer check without individual ablations. Earlier Forward+ render retries encountered engine allocation failures; failed or interrupted runs must not be read as new measurements or overwrite the interpretation of the complete baseline in `before/`.

`python doc/space/randomness-performance-2026-09-16/run_checks.py` checks projectile cleanup, demo lighting isolation and the existing VR streaming contract headlessly. The scripts and raw JSON/logs are in this directory.

For PC VR: connect the headset using Meta Link (USB or Air Link), then run `tools/run_quest_link.ps1`. The PC renders Ada; this does not accelerate the separately installed Quest APK. Link is useful both for richer installations and for development, but success over Link does not establish standalone Quest performance.

References: [Godot background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html), [Godot XR renderer guidance](https://docs.godotengine.org/en/stable/tutorials/xr/setting_up_xr.html), [Meta Link hardware setup](https://developers.meta.com/horizon/design/prototype-setup-hardware/).

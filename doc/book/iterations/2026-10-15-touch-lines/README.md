# Three waiting lines — touch, ride, release

15 October 2026 · Supersedes the autonomous sphere display from the six-encounter trial.

Palle's correction: three bare two-metre X lines in space, no backing plates, one metre between lines. Their spheres wait for touch, then move the player: X, faster/more erratic X, and X plus Y. Parallel spacing is implemented along local Z. The second ride doubles the rate and frequency of direction changes while retaining the same targets and smoothing; it does not add a second random stream.

## Implemented encounter

- All spheres begin at their line centres at 1.25 m height. Only the contacted or held ride advances; the others wait.
- VR hand overlap starts a ride without pressing grip. Grabbing is also supported. Desktop right-click uses the existing held-point receiver.
- Carry uses Out / Back's movement-provider contract, preserving player collisions. The camera is not directly moved or rotated.
- Withdrawing the hand or dropping the grab ends carry immediately. The unoccupied sphere settles back to its line at 0.8 m/s. A blocked rider detaches when the prescribed path leaves reach.
- X targets stay within ±1 m; the third ride's Y targets are 0–1 m above its entry height, so descending returns toward the original level. The body still meets the physical floor.
- The retained path has a resting centre and 47 generated target pairs. Rates are 0.8 / 1.6 / 0.8 target segments per second; each ride has an independent elapsed clock. The faster ride's same-path relation is measured at half the slow ride's elapsed time.
- Replay arms the spheres and waits for contact. Pause ends carry. Keep/load preserves targets, per-line times, offsets and return state under schema random-touch/2. Loading never attaches or teleports a rider. Replay/load refuse an active rider.
- The small rectangular control board remains in front of the lines; the three backing plates and vertical crosshair are removed.

## Verification

[Headless test log](test.log) records a passing run of [test_random_touch.gd](../../../../tests/test_random_touch.gd), launched with XR hardware disabled and dummy audio. Assertions cover two-metre geometry, one-metre spacing, absence of plates, idle waiting, shared targets, doubled rate, axis bounds, actual hand overlap, own-origin receiver resolution, desktop hold/drop, collision-aware movement, vertical lift, a solid wall, release, return, replay guards and saved-state restoration.

The test also constructs an XRToolsPlayerBody with its origin and camera. The shared carry adapter installs exactly once, moves the XR origin and retains contact during the vertical ride. This verifies the runtime integration with simulated tracking. Physical headset comfort, legibility and felt quality remain unobserved.

[Verification](verification.json) checks printed tutorial code against both live source files, links, and the current six final tags/paragraph order. The map remains user-editable; no placement cells were rewritten in this revision. Refresh/reload the room to instantiate the changed scene.

## Text and research status

The tutorial now reconstructs this interaction with its complete source (910 prose words, 283 nonblank code lines). Rebuild using [build-tutorial.mjs](build-tutorial.mjs) and [tutorial-source.md](tutorial-source.md). The earlier six-encounter generator is historical.

The final has factual corrections to the opening and its closing callback. Its literary voice is still unresolved. No A/B/C variant was installed. Before-copies are preserved in [before](before).

Palle explicitly clarified that none of the opening drafts was a clear winner. The requested next writing task is a reusable collection of authors' strategies, with scientific and poetic attention and Bachelard among the references. That discussion is deferred until the artifact works as intended. The next physical observation is what changes between the three rides; it need not confirm the existing RAND handoff.

[Current tutorial](../../../../commons/maps/Random_Definition/tutorial.md) · [Current final](../../../../commons/maps/Random_Definition/final.md) · [Opening comparison](../2026-10-15-sphere-openings/README.md)

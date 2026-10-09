# The field also dresses a room — 25 September 2026

The museum map opts into `enclosure:arches` on its existing `simplex_noise#study:compare` placement. PairStudy attaches one NoiseArch to each of the original roots. Other placements retain their previous behaviour. Both arches call their root's existing `sample_at`; no third generator is created. Existing shared and individual controls remain the only controls.

Each base arch is 2.7 m wide, 2.7 m high and 2 m deep. Its 57 × 29 sample vertices map the same [-2, 1.5]² domain used by the cube centres, at closer intervals. Signed samples and a pinned-boundary weight feed the vertex shader; the added displacement is at most .55 m. The CPU uses the same expression to build physical wall triangles. Floor, feet and entrance ribs stay fixed. Collision faces are built directly from the displaced positions, avoiding render-mesh quantisation.

VIEW removes the added relief, preserving samples, colours, seed and supplied arch geometry. SAMPLE follows the five existing addresses on all four surfaces. FREQ, OCTAVES, REGEN, REPLAY and MATCH flow through the same source readback. An occupied arch retains its old mesh and collider until departure, labels that hold, and then takes the latest settings. This accommodation means the arch can temporarily differ from its display while occupied.

The hall expands from 13 × 15 to 13 × 21. Six floor rows after row 1 create a clear approach. Original later cells shift six rows; all five works remain. Source roots move to cells (3,13) and (8,13); arches stand before them with feet at museum y=0. The controls clear the museum entrance. Authored map placement remains authoritative; no live museum bake or save is replaced.

The chapter gains one encounter between the paired display comparison and its account of what a controlled comparison withholds. Its four original code excerpts, supporting sheet/orb returns and blob-culture ending remain. The source/core primary pair remains the pair; the old companion list's “four primary” wording is corrected to supporting returns for the sheet and orb.

Native test details and photographs: `doc/book/iterations/2026-09-25-noise-archways/index.html`. Tracked headset reach, collision comfort, visual readability and Quest performance still require a session in the device.

---

# The field remains; its expression changes — encounter notes

24 September 2026. Current implementation and verification for this pass.

The shared PairStudy VIEW action now sets only each root's and visualizer's readout and updates the visualizer. It no longer calls placement configuration, which was restoring the declared Simplex seed after REGEN. No shared noise generator default or other placement configuration path changed.

Native production-scene checks regenerate both fields, retain their generator parameters, values and colours, switch to a plate, return to relief, and exercise MATCH separately. MATCH still restores the declared seed. The chapter no longer needs a qualification explaining an unrelated seed reset.

The chapter's critical movement toward blob culture is preserved. VIEW's purpose is to distinguish a field from how an answer is spent on height or colour.

Prior repair record: `doc/book/iterations/2026-09-24-claude-randomness-onwards/Noise_Perlin_Simplex/DECISIONS.md`.

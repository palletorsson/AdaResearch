# N4 — Noise_Voxel: the contract and the lattice (Fable, 12 September 2026)

Astra's card asked for both artifacts kept primary as one linked encounter with their relationship made exact — preferably one sampler contract for basis, seed, coordinates, height bias, threshold and scale, changing only representation and size; the sample value and the occupied/empty decision shown for a selected cell; threshold changes at a fixed seed; the receiver bounded; and the link's scope audited so it cannot retune receivers in other halls.

## What was there

Two primaries that shared control values and not samples. The bench sampled Perlin at its own coordinates with a height bias; the receiver sampled its own noise at world integers against its own iso level; the link mapped a normalised scale into a frequency range. Calling them "the same field" required not looking. The bench's noise was seeded with `randi()`, so nothing was repeatable, and its broadcast used `call_group`, which reaches every receiver in the tree.

## What it is now

`#stand:lattice` on the bench, with `voxelnoise` across the room as the receiving terrain:

- **One sampler, written once.** `contract_noise`, `contract_value`, `contract_bias`, `contract_occupied`, static on `PerlinTerrainSculptor`, called by both displays. The coordinates are normalised, so the 24-cell model and the 32-cell terrain ask the same field the same question at two magnifications. That is the one scale relationship, chosen and made true.
- **The case, not the verdict.** A cage marks one cell; the plate prints its coordinate, the field's value, the bias, the subtraction, the threshold and the decision: `-0.1364 − +0.0109 = -0.1473 > +0.10 → empty`.
- **THRESHOLD at a fixed seed.** The line moves, the marked cell's value does not, the occupied count does.
- **CELL, SEED, CUT.** The selection walks five named cells; the seed is five digits; the cut hides the near half without changing a decision.
- **Connected is not walkable**, said on the plate and in the final, with the pieces of the occupied set counted so the distinction has numbers on both sides.

## Evidence

| lane | result |
|---|---|
| bare (`run_wcn_probe.sh voxel`) | 37 checks, 0 failures |
| live (`run_wcn_probe.sh voxel live`) | 40 checks, 0 failures, exit 0 |

Monotonicity is taken over every cell in the lattice at five thresholds through the contract itself: 10925, 8887, 6549, 4315, 2421 — never rising, and falling enough that a dead control could not pass. The probe also reads both source files to check the contract is one thing and the receiver calls it, and that the predicate is still `value - bias > threshold` rather than a simplification. The receiver is confirmed to have taken the contract, with the same threshold line.

## The broadcast was reaching other halls

`_broadcast_controls_to_voxelnoise` used `get_tree().call_group("voxelnoise_receivers", …)`. The museum streams several halls at once, so turning this bench's threshold retuned a terrain in a room nobody was standing in. It now finds the nearest ancestor that owns a hall (an `em_map` meta or a `Seg…` name) and speaks only to receivers under it, recording hall, reached and receivers-in-tree so the probe can read the scope. With no such ancestor the old behaviour stands.

## Not done, said plainly

- No headset walk, and nobody has tried to walk the terrain — which is the only way the passage question can be answered. The room says so rather than implying a passage.
- The receiver's own chunk bounds (32 × 64 × 32 at voxel scale 1) are unchanged; bounding them further was not needed for this pass and was not measured as a cost.
- Shipped paths are untouched at `stand:none`: eighteen placements of the bench and thirteen of the receiver sample exactly what they sampled.
- Astra's review.

## Files

`commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.gd`, `algorithms/randomness/voxelnoise/voxelnoise.gd`, `commons/maps/Noise_Voxel/map_data.json`, `commons/maps/Noise_Voxel/{final,summary,technical,tutorial,field_notes}.md`, `commons/testing/probe_wcn_voxel.gd` and its live port, `tools/run_wcn_probe.sh` and `tools/port_wcn_probes_live.py` (the `voxel` case), `tools/build_wcn_captures_page.py` (N4's views), and the captures page rebuilt and published. Forum: 260912-3ot1y.

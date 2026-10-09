# Noise Voxel — Summary

Noise_Voxel is the fourth map in the Noise sequence. It converts continuous noise into discrete solid-or-void geometry. The space is a cubic volume filled with a 3D noise field; a threshold slider at the entrance decides which cells become solid and which stay empty.

At low thresholds, most cells read as solid — a dense stone block with small scattered pockets. At high thresholds, most cells read as void, leaving floating stone islands suspended in the air. Between the extremes, caves open, overhangs form, shelves and bridges appear. The same noise field produces radically different topologies as the threshold changes, and the learner can scrub through the range live.

A smaller control set layers additional transformations. One slider selects the noise type; another adjusts the base frequency, so the learner can trade detail for feature size. A toggle switches between binary voxels and a softer surface that follows an iso-contour rather than a per-cell cut.

Within the sequence, Voxel is where noise starts behaving like architecture. The threshold operation is the minimum commitment a procedural world must make: somewhere there has to be a stone wall and somewhere there has to be air. Noise_6_Wall will next move the same kind of field to the GPU.

## The contract and the lattice (2026-09-12)

`perlin_terrain_sculptor:180:0.5:1#mount:shelf#stand:lattice` stands on the bench with `voxelnoise` across from it as the receiving terrain. They are one linked encounter and, since this pass, one field: the sampler is written once as four static functions — the basis, the coordinates, the height bias and the predicate — and both displays call them. The coordinates are normalised, so the 24-cell model and the 32-cell terrain ask the same field the same question at two magnifications.

A cage marks one cell and the plate shows its whole case: the field's value there, the height bias, the subtraction, the threshold and the decision. `-0.1364 − +0.0109 = -0.1473 > +0.10 → empty`. THRESHOLD moves the line at a fixed seed, and the plate demonstrates the room's distinction in one press: the marked cell's value does not move while the occupied count does. Raising the line can only take cells away — 10925, 8887, 6549, 4315, 2421 across the five steps — because the predicate is greater-than and nothing else.

The plate also counts the pieces of the occupied set and then refuses the obvious conclusion: connected is not walkable. Adjacency between cells is a fact about cells; passage is a fact about bodies, which need a floor, headroom, a way in and a climbable slope.

Corrected in the same pass: the bench announced its settings with `call_group`, which reaches every receiver in the building — in a museum that streams several halls at once, turning this threshold retuned a terrain in a room nobody was standing in. The broadcast is scoped to this hall now, and records who it reached.

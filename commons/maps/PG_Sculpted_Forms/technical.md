# What did the sample keep? — implementation

Sources: cube_mound.gd::generate_mesh_from_cubes, clear_generated_mesh; dome.gd::_apply_facture; layered_membrane.gd.

The opt-in `pg_workshop_console` binds the named artifacts within its own museum hall; controls are implemented in commons/artifacts/timing_machines/pg_workshop.gd. Six push buttons occupy one compact 3×2 desk with an inclined translucent readout. RULE reveals the implementation card. Actions are guarded while a rebuild is in progress.

Freeze physical cubes, compare their sampled surface, then reveal Boolean cutting operands.

The positions must first belong to the model's local frame:

```gdscript
positions.append(to_local(cube.global_position))
```

Each centre is mapped to a voxel address. The implementation then marks an axis-aligned neighbourhood around that address and emits faces where occupied cells meet empty ones. The extent is deliberately described here as the program computes it: `ceil(cube_size / voxel_size)` cells in each direction. It is an enlarged centre-based approximation. The cubes' rotations and exact contact surfaces are not copied.

VOXEL rebuilds from those same frozen positions at a different cell size. Look for an opening that becomes filled or a boundary that moves. A change of resolution can change the opportunities offered by a surface, not merely its smoothness. More detail has a cost, but less detail also makes decisions. Neither setting is innocent by virtue of being easy to compute.

The layered membrane remains nearby. Its repaired scene makes a further contrast available: nested displaced surfaces can suggest thickness without being one filled solid. Look between them. Do not assume that a convincing skin carries the collision or interior its appearance promises.

Space: the inherited structure is retained in a larger surround; relocated objects have an independent museum aisle. Source zeros remain present and receive explicitly listed museum.floor_cells covers. The floor audit records offsets and covers. Raised historic cells are retained witnesses, not universally certified decks.

Validation: see doc/space/pg-sequence-2026-09-15 and ada_run/pg-review-2026-09-15. Report actual runtime checks separately from outstanding human headset/clearance review.

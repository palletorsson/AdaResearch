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


## Reconstructed tutorial — 9 October 2026

Full printed sample.gd/faces.gd/sculpture.gd/unchanged Caves point_body.gd. Three fixed local centres(-1.5,1,0),(0,1,0),(1.5,1,0); host frame scale.3, y.8. Original rotations vary but are not sampled. capture(frame,bodies) uses frame.to_local(global_position). Component minimum minus BODY_EDGE anchors origin; floor((centre-origin)/spacing) picks address. Sparse dictionary is not clipped. Extent ceil(BODY_EDGE*EXTENT_FACTOR/spacing), inclusive offsets on all axes. Source opening1m cube/.5 spacing marks125cells, box2.5mwide. No extra half-cell centre shift. Six neighbours omit internal faces; each exposed face emits two clockwise triangles with outward normals. No smoothing or learner collision.

Point held action/SPACE samples; V changes visibility, M moves third source+.5x without recapturing, R restores source positions and original view. Physics parking returns inherited point to(0,1.1,1.5). SPACE also belongs to installed artifact, so prefer held action there. Temporary learner maplocal(8.5,0,21),yaw180; approach(8.5,0,19). Three static MeshInstance originals are explicit fixtures, not a replacement physics lesson.

29 exact printed checks PASS. Nine source-assembler comparisons across three spacings/three inputs match submitted vertices. Empty input, duplicate union, alias-safe retained resampling, isolated and adjacent cells, actual packed mesh winding/normals, local/world transform, retained sample/view/move/reset, whole edited program and supplied XRTools pick/action/drop. Wrong world coordinates, rounded addresses and emitted internal faces all rejected. Exact START fixture275cells/270faces=540triangles; full EXTENT_FACTOR.5 edit81cells/126faces=252triangles. Single-source edited box1.5unitswide still approximates rather than matching rotated cube.

Floating-point local/global round trips can change floor at a cell boundary. Do not snap inputs to conceal this: exact local fixture and actual captured positions are separate test cases. Headless transformed host250cells/250faces; moved third300/290; edited72/114. Native capture 250cells/250faces; edited72/114. Same captured inputs/origin and subset relation verified. First harness parse failure and second overly strict packed-normal comparison retained; final normal check uses angular dot>.99999 instead of component equality near1e-5. No tutorial geometry changed to satisfy it.

33 native checks PASS. Actual pointer DROP/SAMPLE/VOXEL/ORIGINAL/CUT/RULE effects. Printed full pipeline reproduces actual frozen twelve-body production surface vertices at1.0and.5 spacing. Changing view/resolution retains frozen transforms; exactly one generated sibling collider; ORIGINAL leaves it active; DROP removes it and starts twelve moving bodies. Dome cast/blank/core/section states exercised. Full learner and whole extent edit instantiated in actualmuseum; suppliedXRTools hand action/release passed. Ten final images plus three baseline images. First camera receipt preserved because pile was clipped; final framing raised target without changing model.

Route: 272 quarter-metre capsule samples, clear=True, supported=True, from beside desk via left x3 aisle and rear x20 aisle to exit approach. Authored entry (16.5, 0.05, 1.5) remains blocked by desk, exit record valid. This does not certify entry portal/player traversal or standing on generated mound. Oversized dome roof obscures front court from above and extends beyond perimeter in image; section capture makes relationship inspectable. Production room/placement/lighting unchanged, camera exposure.45. Headset/Quest/independentghoststudent/browserlayout acceptance remain open.

Canonical reflection keeps its argument, removes two code blocks and adds the rotation/forgotten-information comparison. Only target execution-plan row updated, draft retained. Production mound/dome/workshop/map/sequence protected by hashes; runtime target row unchanged. Review doc/book/iterations/2026-10-09-sculpted-what-the-centres-keep/index.html. Next PG_Mirrored_Patterns, final hall of this sequence.

# Wavefunctions_Sky_Stairs

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## When does a sampled curve become a route for a body?

Body/layer: The player's feet, treads and a varying-radius spiral.

Proposed primary encounter: `sine_cylinder_staircase`.

## Starting evidence

Outside the museum route. The placed scene sets WAVE_AMPLITUDE=0.45. The script constructs 80 treads with rise, turn and radius variation; membrane/none/rail/posts provisions already exist. Collider height offset and bridging geometry require a physical check. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 10}. Current final: 424 words.

Current primaries: sine_cylinder_staircase. Book anchors: sine_cylinder_staircase.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Recover the original footprint and start/end platforms before adapting this tall staircase to a hall.
2. Build one tested climb with entrance, headroom, continuous support and an exit; include a museum bypass. Correct any mismatch between visible tread and collider, rather than hiding it with an invisible lift.
3. Compare wave amplitude zero/nonzero at fixed rise/turn, or a short paired tread sample if a full second climb is too large. Keep the changed geometric variable explicit.

## Revise final.md

1. Begin at the first tread and ask whether the smooth-looking spiral can carry the reader.
2. Inspect centres and edges separately, then try the tested ascent.
3. Quote the real sampled angle/radius/height construction.
4. Make the difference between curve continuity and bodily access tangible. A changed stride can expose a gap without the equation being wrong.

**Code to trace and quote after implementation:** sine_cylinder_staircase.gd: _compute_samples, _build, _add_plane_bridge, provision code; inspect COLLIDER_HEIGHT_OFFSET in world space.

## Evidence to return

- Traverse from entry to exit with actual player dimensions and record collision alignment.
- Check the offered amplitude range for gaps/head clearance.
- Capture the whole route, not only an attractive crop of the middle.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Rail, posts or membrane may be chosen for what they do. Keep the support contract visible and the comparison controlled.

**Reusable method:** R4 sample-to-body mapping; R5 arena boundary.

## Open and inspect

- Map: `commons/maps/Wavefunctions_Sky_Stairs/map_data.json`
- Book and supporting texts: `commons/maps/Wavefunctions_Sky_Stairs/`
- [Primary view](http://localhost:3003/necklace/thread?map=Wavefunctions_Sky_Stairs&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=Wavefunctions_Sky_Stairs)
- `res://algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.tscn`
- `algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

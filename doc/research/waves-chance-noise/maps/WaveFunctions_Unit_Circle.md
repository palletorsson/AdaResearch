# WaveFunctions_Unit_Circle

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## How does going around become rising and falling?

Body/layer: A rotating point, its projections and a sampled construction.

Proposed primary encounter: `unit_circle_advanced`.

## Starting evidence

Currently outside the museum route. UnitCircle.gd supports correspondence and progressive/complete configurations; builds a finite number of steps and then stops. Wave length defaults to 28 m, beyond the 14×17 source map unless staged/scaled deliberately. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 14, 'depth': 17, 'max_height': 4}. Current final: 412 words.

Current primaries: unit_circle_advanced. Book anchors: unit_circle_advanced.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Preserve the projection construction. Identify angle progression, x=cos(angle), y=sin(angle) and the graph's separate horizontal coordinate using matched points/rods.
2. Offer replay and a manageable local phase scrub, reusing current correspondence variants. Keep the first encounter sine/cosine; tangent and helix can remain optional.
3. Separate a hand-scale explanatory graph from any walkable bridge. Restore or extend the original arena only after footprint inspection; do not squeeze a long bridge into the museum walls by hiding its ends.

## Revise final.md

1. Ask which height will appear next, then follow one point from circle to graph.
2. Return to the same height twice and notice what the projection lost.
3. Introduce the real sine/cosine code and the changed meaning of the graph axis.
4. Close toward Propagation in this extension route; if inserted on the spine, revise both neighbours and the book handoff together.

**Code to trace and quote after implementation:** UnitCircle.gd: _update_rotator_and_indicators, _create_bridge_step, _process. Record sample count and completion condition.

## Evidence to return

- Check four quarter-turn correspondences and replay after completion.
- Confirm every graph sample and any physical tread remain within the intended stage.
- Do not call the bridge walkable without entrance, support and exit tests.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Fable may choose a circular table, moving pointer or spatial unfolding. Maintain exact correspondence, not merely a circle beside a decorative wave.

**Reusable method:** R1 controlled comparison; R2 housed readout; R5 arena boundary.

## Open and inspect

- Map: `commons/maps/WaveFunctions_Unit_Circle/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_Unit_Circle/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_Unit_Circle&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_Unit_Circle)
- `res://algorithms/wavefunctions/unit_circle/unit_circle.tscn`
- `algorithms/wavefunctions/unit_circle/UnitCircle.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

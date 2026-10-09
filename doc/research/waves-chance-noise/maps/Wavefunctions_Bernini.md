# Wavefunctions_Bernini

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## Can a rhythm stand still as architecture?

Body/layer: A twisted column and a changing viewpoint.

Proposed primary encounter: `bernini_columns`.

## Starting evidence

Outside the museum route. The mesh uses height-dependent sine/cosine and is also rotated as a whole. Existing colonnade modes include grid, ring, aisle and pair. Generated accompanying audio is not evidence of touch-driven sound. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 20, 'depth': 16, 'max_height': 3}. Current final: 419 words.

Current primaries: bernini_columns. Book anchors: bernini_columns.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Use the existing pair or aisle configuration to compare an untwisted reference and a twisted shaft with whole-object rotation initially stopped.
2. Let one control vary twist/density while material and height remain fixed; expose whole-object rotation as a separate second operation.
3. Fit the full column height and base inside a deliberate stage. Keep architectural atmosphere and optional dress/speech objects if they contribute an identifiable secondary encounter.

## Revise final.md

1. Walk around an apparently moving twist before any motor starts.
2. Separate a profile that changes with height from an object rotating through time.
3. Read the mesh-coordinate construction, connecting back to Transformation.
4. Ask what makes the result a column when structural support is not simulated; keep any historical attribution limited to verified inspiration.

**Code to trace and quote after implementation:** BerniniColumns.gd: generate_spiral_column_mesh, _process, _plan_pair/_plan_aisle. Inspect the loaded base scene too.

## Evidence to return

- Freeze whole-object rotation and show that twist persists.
- Vary twist at fixed height and check the reference remains unchanged.
- Verify wall/ceiling clearance and whether any load-bearing claim has a real mechanism.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

The ornament can be excessive and desirable. Fable chooses its material and arrangement; the two kinds of change must remain separable.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping.

## Open and inspect

- Map: `commons/maps/Wavefunctions_Bernini/map_data.json`
- Book and supporting texts: `commons/maps/Wavefunctions_Bernini/`
- [Primary view](http://localhost:3003/necklace/thread?map=Wavefunctions_Bernini&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=Wavefunctions_Bernini)
- `res://algorithms/wavefunctions/berninicolumns/BerniniScene.tscn`
- `algorithms/wavefunctions/berninicolumns/BerniniColumns.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

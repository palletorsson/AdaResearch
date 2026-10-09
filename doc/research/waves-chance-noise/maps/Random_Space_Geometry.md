# Random_Space_Geometry

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## What changes when neighbouring heights are related?

Body/layer: Two fields mapped to the same column body.

Proposed primary encounter: `perlin_noise_bridge`.

## Starting evidence

Outside the active route. perlin_noise_bridge already compares independent heights with coherent noise on paired 16×16 grids, with octave/frequency/seed/resample controls. Height bounds are similar but distributions need not match.

Current map dimensions: {'width': 13, 'depth': 30, 'max_height': 3}. Current final: 399 words.

Current primaries: perlin_noise_bridge. Book anchors: perlin_noise_bridge.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Give the paired grids a common footprint, height axis and palette. Keep the two panels readable at the same viewing distance and do not independently normalise them without disclosing it.
2. Start at one octave and fixed seed. Isolate frequency before offering extra octaves; expose one selected coordinate and neighbouring samples.
3. Use this as the Randomness-to-Noise comparison laboratory. Reuse its paired sampler for Noise_Types or the later noise bench if helpful, while giving this extension its own geometry-mapping experiment.

## Revise final.md

1. Describe adjacent height differences before calling either side a landscape.
2. Hold the seed, change coherent frequency and revisit a coordinate.
3. Read independent draw versus field-at-coordinate; distinguish correlation from equal distributions.
4. Let the same values become colour or height only if that shared-data mapping is implemented. Do not claim erosion or geology from appearance.

**Code to trace and quote after implementation:** perlin_noise_bridge.gd: _rebuild_grids, _apply_column, _create_vr_controls. Inspect FastNoiseLite basis and frequency mapping.

## Evidence to return

- Paired displays use declared common dimensions, scale and colour mapping.
- Same seed/settings repeat; frequency changes leave the independent baseline stable if advertised.
- Confirm selected-coordinate readouts agree with the displayed columns.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Could be two miniature landscapes or two austere arrays. A useful alternative is a single field viewed as colour and relief after the basic comparison.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R6 local state/seed.

## Open and inspect

- Map: `commons/maps/Random_Space_Geometry/map_data.json`
- Book and supporting texts: `commons/maps/Random_Space_Geometry/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Space_Geometry&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Space_Geometry)
- `res://algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.tscn`
- `algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

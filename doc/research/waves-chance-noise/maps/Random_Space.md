# Random_Space

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## Can a deterministic sum persuade us it is a landscape?

Body/layer: A field assembled in layers and an interpretive palette.

Proposed primary encounter: `noise_mixer`.

## Starting evidence

Outside the active route. noise_mixer sums a sine-based function over octaves with seeded offsets; it is not Perlin. The generated image normalises its own range and uses terrain colours. OCT/LAC/PER and random seed controls already exist. Platform/wall recovery on 10 September: 48 interior cells restored as platforms; 43 boundary cells made explicit w. Keep museum.wall_height: 3 and existing gate-depth settings. See structure-recovery.html and doc/space/sequence-platform-recovery-2026-09-10/.

Current map dimensions: {'width': 13, 'depth': 16, 'max_height': 5}. Current final: 409 words.

Current primaries: noise_mixer. Book anchors: noise_mixer.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Stage the existing mixer on a reachable stand. Begin with one layer, then add layers while keeping the seed and base function fixed.
2. Provide a fixed-scale/normalised view comparison with the actual min/max values visible; changing contrast should not masquerade as changing absolute height.
3. Make a grayscale or neutral colour option available to compare field structure with landscape associations. Coordinate its scope with Noise_6_Wall so this room teaches interpretation/normalisation and that one teaches shader layers.

## Revise final.md

1. Meet an apparent coastline, then remove the landscape palette.
2. Build the image from one layer and trace what OCT, LAC and PER each change.
3. Quote _sin_noise and the octave accumulation, naming the actual construction.
4. Let normalisation conceal a numerical difference, then reveal it. Close with a precise question about mapping rather than claiming all irregularity is randomness.

**Code to trace and quote after implementation:** noise_mixer.gd: _fbm, _sin_noise, _generate_texture, _sample_color_ramp. Confirm the control units and range remapping.

## Evidence to return

- Replay field samples at a fixed seed/settings.
- Show fixed versus per-image normalisation without resampling the field.
- At one octave, test the claimed effect of layer-spacing controls before describing it.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Fable can retain the seductive terrain colours. Their power becomes more interesting when another reading is available.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R7 measurement contract.

## Open and inspect

- Map: `commons/maps/Random_Space/map_data.json`
- Book and supporting texts: `commons/maps/Random_Space/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Space&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Space)
- `res://commons/artifacts/noise_mixer/noise_mixer.tscn`
- `commons/artifacts/noise_mixer/noise_mixer.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

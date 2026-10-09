# Noise_Perlin_Simplex

**Active hall 8 in noise. Batch: PILOT. 39 rendered checks passed; 11 actual controls; headset pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## What must stay the same before a difference can be attributed to a rule?

Body/layer: Two retained cube fields, their live comparison plate and shared sample, plus an independently changing sheet and orb.

Proposed primary encounter: `simplex_noise`, `perlin_noise`, `perlin_noise_terrain`, `dark_sphere`.

## Starting evidence

The current map already declared Perlin versus OpenSimplex2, but its live museum row was stale. Replaced only this row with the accepted five-work configuration. Preserved all authored structure, utilities and current works. Turned the front controls and plate towards the entry. The plate now refreshes actual generator state and reports mismatches, including seed differences of one. SAMPLE marks five paired addresses, VIEW spends the values on colour alone or colour and relief, and MATCH restores the two declared configurations. The small terrain remains an independently timed 3D OpenSimplex2S slice. The unresolved optional Lab Path portal is retained, explicitly labelled and inactive.

Current map dimensions: {'width': 13, 'depth': 15, 'max_height': 3}. Current final: 1108 words.

Current primaries: simplex_noise, perlin_noise, perlin_noise_terrain, dark_sphere. Book anchors: simplex_noise, perlin_noise, perlin_noise_terrain, dark_sphere.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Preserve the authored pair and its two independent panels; restore the current five-work map in the museum.
2. Add a shared sample, view and matched return through a supported local instrument. Keep other halls untouched.
3. Retain the small sheet on a low plinth and the orb as distinct book encounters. Mark the unconnected Lab Path route inactive until its loader is repaired.

## Revise final.md

1. Keep the earlier discovery opening and code-grounded comparison.
2. Follow the same address in both fields, then change the display without changing the generator.
3. Let a mismatch revise the plate’s claim; do not infer corresponding features from a shared seed.
4. Give the moving sheet and orb their own passages. Carry the distinction between sampling a field and updating stored cell states into Cellular Automata.

**Code to trace and quote after implementation:** PerlinNoise.gd: apply_grid_config/_update_noise_parameters; NoiseVisualizer.gd: _noise_type_for/set_dna/generate_noise_at; SimplexVisualizer.gd setup and sampling.

## Evidence to return

- 39 rendered checks with 11 actual pointer controls: four slider drags, four individual buttons, three shared buttons.
- All 64 samples per display agree with height and material mapping through relief, plate, a detuned state and matched return. Five shared witnesses agree at each state.
- Actual generator readback, seed difference of one, local ownership, independent terrain clock, portal inactive state and a desktop body crossing the aisle and far door.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Fable can choose twin reliefs, a shared probe or a reversible display. A fair comparison matters more than preserving the current cabinet.

**Reusable method:** R1 controlled comparison; R6 local state/seed; R7 measurement contract.

## Open and inspect

- Map: `commons/maps/Noise_Perlin_Simplex/map_data.json`
- Book and supporting texts: `commons/maps/Noise_Perlin_Simplex/`
- [Primary view](http://localhost:3003/necklace/thread?map=Noise_Perlin_Simplex&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=noise&room=Noise_Perlin_Simplex)
- `res://algorithms/randomness/simplexnoise/simplexnoise.tscn`
- `algorithms/randomness/simplexnoise/SimplexNoise.gd`
- `algorithms/randomness/simplexnoise/SimplexVisualizer.gd`
- `res://algorithms/randomness/perlinnoise/perlinnoise.tscn`
- `algorithms/randomness/perlinnoise/PerlinNoise.gd`
- `algorithms/randomness/perlinnoise/NoiseVisualizer.gd`
- `res://algorithms/randomness/noise/perlinnoise/scenes/perlin_noise_terrain.tscn`
- `algorithms/randomness/noise/perlinnoise/scripts/terrain_generator.gd`
- `res://commons/artifacts/dark_sphere/dark_sphere.tscn`
- `commons/artifacts/dark_sphere/dark_sphere.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

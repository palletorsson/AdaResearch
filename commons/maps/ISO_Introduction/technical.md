# One field, multiple decisions

The registered `voxel_noise_demo` scene has an unscripted root and a `VoxelNoiseMarchingCubes` child. The hall desk locates that child; it does not replace the extractor. Ordinary placements keep their existing defaults.

`generate_density_field()` samples a 32-unit cube centred at zero. For n sample positions per axis, spacing is `chunk_size / float(n - 1)` and the flattened index is `x + y*n + z*n*n`. Density is `(noise.get_noise_3d(p) + 1) * 0.5`. The lesson keeps seed 1337 and all noise settings fixed.

`process_cube()` reads eight neighbouring samples. `march_cube()` sets bit i when density i is below `iso_level`, and looks up edges for the resulting mask. `interpolate_vertices()` uses:

```gdscript
t = (iso_level - v1_density) / (v2_density - v1_density)
p = v1_pos.lerp(v2_pos, t)
```

Only edges whose endpoint comparisons differ reach that interpolation. A triangle mesh and a concave collision shape are then created. Regeneration removes only the generator's owned nodes.

LEVEL cycles 0.50 / 0.45 / 0.55, remarching the same deterministic samples. SAMPLES cycles 24 / 16 / 32 per axis over the same domain. HOLD deep-copies the current ArrayMesh, offsets its displayed world position by 8m, and gives it a separate material; it adds no collider. RESET restores level .50 and 24 samples per axis without changing HOLD. CLEAR removes the copy. RULE exposes the construction after the encounter.

Source: `res://algorithms/spacetopology/marchingcubes/VoxelNoiseMarchingCubes.gd`; lesson controls: `res://commons/artifacts/timing_machines/iso_workshop.gd`.

The source box is 32 units; uniform display scale .18 makes its width 5.76m. Scaling the display and changing sampling are separate operations. Triangle count is reported, not used as a proxy for topology or physical traversability. The original science_screen remains secondary; no claim is made that its generic field mode reads this model.

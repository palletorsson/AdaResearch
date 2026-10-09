# Noise 6 Wall — one comparison, several surfaces

The active scene is `res://algorithms/randomness/shadernoisespace/noiseroom.tscn`, with `noiseroom.gd`, `WallNoiseShader.gdshader` and `QueerNoiseShader.gdshader`. The map retains a panel placement and an enclosure placement of shader_noise_space plus the independent dark_sphere. Original source and text versions are preserved in the dated wall review archive.

## From cells to fragments

Noise_Voxel stores a finite lattice of scalar samples and occupancy decisions. Here a spatial fragment shader evaluates a 2D noise construction at the interpolated UV coordinates of rendered surfaces. Fragment processing runs on the GPU; it remains finite work bounded by rendered coverage, sampling, precision and the selected branch. It does not evaluate an infinite field or every coordinate simultaneously. The room still has geometry, collision, uniforms and rendering state.

The variable called world_uv receives UV directly. It is not a world-position projection. Every newly staged quad uses its own chart; the sphere's chart wraps around its mesh. Equal uniforms produce the same calculation at equal UV coordinates, with different physical spacing and seams on different surfaces. These shader samples are not the stored Perlin FBM volume from the preceding hall.

## Accumulating a folded field

The fixed sine-based hash supplies coordinate-dependent pseudo-random values or vectors. The four selectable implementations are Perlin-style gradient interpolation, Value interpolation, Simplex-style triangular contributions and Cellular nearest-feature distance. Their existing scaling constants remain. This pass verifies shared state and equal shader outputs at matched UVs, not a new statistical equivalence across those four bases. A cellular nearest-distance field can be continuous while its derivative changes at feature boundaries; it is not automatically a discontinuous staircase.

cloud_noise starts value=0, amplitude=.5 and frequency=1. It adds amplitude × abs(noise2d(animated_pos)), halves amplitude and doubles frequency on every iteration. Animated coordinates combine pos × frequency with sine/cosine offsets. This is an octave accumulation of magnitudes, not a signed sum and not a claim to an exact fractional Brownian process. The selectable prefixes have 1, 2, 4 and 6 terms. Their weight sums are .5, .75, .9375 and .984375; their images also depend on sample values and display encoding.

In sum mode, the shader emits clamp(cloud_noise × term_gain, 0, 1), with gain 2 for this comparison. Albedo is zero and the lighting normal is neutral. The branch skips the full finish's extra field evaluations. The display may collapse distinct high sums to white; emitted greyscale is a chosen encoding, not an unmediated scalar measurement.

In dressed mode, the cloud sum is combined with a separate four-term turbulence loop, weighted by .4 and multiplied by cloud_density. That loop starts at amplitude 1 and frequency .5, then multiplies by .6 and 2.5. Smoothstep, pink colour mixing, time-driven colour shift, corner/edge treatment, roughness and a finite-difference lighting normal produce the finish. LAYERS changes the cloud loop's bound; the detail loop retains four iterations. Neither branch moves vertices or rebuilds collision.

The normal-map encoding has been corrected to map signed XY offsets into the expected 0–1 tangent-normal channels. This shared shader repair can alter shading in other existing consumers. The original scene geometry is unchanged; its default appearance is not claimed pixel-identical to the faulty normal encoding.

## Current time and local ownership

The panel owns the comparison clock. FREEZE stops its advancement and animation updates while retaining current time, rate, density and colours. It does not set time_scale to zero. RESUME advances from the held base_time. The fixed-count patches receive that same clock and basis. The room receiver copies the complete comparison state into its private sphere and wall materials and does not run a second clock.

Broadcasts require a hall ancestor and reach room-mode receivers within that ancestor only. The legacy standalone room is not recruited by a nearby panel. The dark orb keeps its independent clock. State ownership is the reason a comparison can hold while something else in the hall continues.

## Stage and preservation

stand:panel removes its unused large enclosure and builds the supported instrument. stand:room opts into a five-metre floor and 4.8 m wide room, with a 2.8 m ceiling and opposing 1.6 × 2.3 m door clearances. Its floor sits over the current level map floor; the central pit described in earlier reviews has since been filled. Quads have matching static box colliders; DRESS changes neither those shapes nor their positions. The original internal sphere remains, with the controlled material applied at the actual CSG combiner root. The orb has moved to solid floor near the exit. The panel now stands at (6,4), facing inward from the north wall; the room remains at (6,6). This placement revision changes no structure, utilities, shader source, geometry or controller behaviour.

## Evidence and limits

The accepted rendered museum run passes 39 checks. It compares sphere and wall shader output at 256 corresponding sampled pixels for each term prefix, with maximum captured red-channel difference zero. It checks a nondecreasing, changing rendered prefix, current-time freeze/resume, complete state broadcast, an excluded outside receiver, unchanged collision shapes and four actual desktop-pointer controls driven by synthetic mouse events. A desktop body crosses both doors and the floor; the surrounding museum route remains connected.

The 96 × 96 shader captures and their sampled red-channel means are display measurements, not raw noise values or a CPU/GPU precision proof. These checks do not certify headset comfort, reach or Quest performance. Earlier staging runs shared GPU time with another review; the accepted final run began with no other Godot process listed. No timing comparison is made.

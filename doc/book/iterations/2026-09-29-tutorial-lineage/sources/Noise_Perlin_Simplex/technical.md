> Current encounter and verification (25 September 2026): [encounter notes](encounter-notes.md). The earlier account below is retained; the current note governs changed placement, controls and validation.

# A live comparison contract

Current sources are SimplexNoise.gd, SimplexVisualizer.gd, PerlinNoise.gd, NoiseVisualizer.gd and the optional pair_study.gd. The original visualizer and scene resources remain unchanged in this pass. Map structure and utilities remain unchanged. The current authored row replaces the museum's stale six-work row.

## Two bases, matched conditions

The instantiated generators report TYPE_SIMPLEX (0, OpenSimplex2) and TYPE_PERLIN (3). Both use seed 20260910, generator frequency .05, fBM, four octaves, gain .5, lacunarity 2, coordinate multiplier 10 and zero sampling offset. Godot distinguishes OpenSimplex2 from TYPE_SIMPLEX_SMOOTH (OpenSimplex2S). [Godot 4.6 FastNoiseLite](https://docs.godotengine.org/en/4.6/classes/class_fastnoiselite.html#enumerations).

Both displays have 64 cubes, half-metre spacing, amplitude .8 and the existing shared colour ramp/finish. Local sample centres run from -2 to 1.5. Cube centres use y=value*.8 in relief and y=0 in plate. Colour uses the same signed-to-unit mapping in both views; it does not depend on whether height is displayed. The cube field has no added walking collision. Unlike Noise_Space_10, it is a visual comparison with an aisle.

## Local controls and truthful readback

The simplex placement selects `study:compare` and retains `witness:show`. The optional study looks up the Perlin twin within the nearest museum hall; it never chooses a streamed neighbour. Unconfigured placements retain their existing controls and display behaviour.

The existing front panels face the -z approach in this installation. Each retains its FREQ and OCTAVES sliders, REGEN and REPLAY buttons. The shared supported instrument adds SAMPLE, VIEW and MATCH. Five sample coordinates are (-1,.5), (1,-1), (-1,-1), (0,0) and (.5,1), all actual cube centres. Pink markers follow their current cube heights; the plate prints both generator values and perlin-minus-simplex.

VIEW applies the existing plate/relief configuration to both local roots. MATCH invokes their existing replay methods, restoring declared seeds, frequency multipliers and octave counts while retaining the selected display view and sample. It does not affect the small terrain or orb.

The witness previously updated only when constructed and always claimed that only the basis differed. The optional study refreshes the live plate every .15 seconds. The shared line formatter now reports changed contract terms. Integer seeds compare exactly, so a difference of one is not hidden by floating-point relative tolerance. The change applies to witness text in both root scripts; other artifact behaviour is retained.

## The small sheet is another experiment

perlin_noise_terrain now stands at y=1 above a low plinth. Its existing script, sampler and timer are unchanged. The live generator uses TYPE_SIMPLEX_SMOOTH, seed 1 and frequency .07. NoiseHelper sets seed/frequency and leaves the basis at the engine default. The inherited Perlin name is not evidence of a Perlin basis.

There are 484 mesh vertices (22 × 22) in a one-metre sheet. MeshHelper queries a 3D field in index coordinates: x_index*.1, y_index*.1, time_offset. Its .5-second timer adds .5 to the third coordinate. This is resampling successive slices, not integration of an evolving terrain state. The original scene also rotates its plane; its mapping is distinct from the cube pair.

## Routes and limits

The current optional portal cannot resolve Lab_Path through its implemented loaders. Its existing script and destination remain, but this placement sets active:false and explicitly labels it “Lab Path - not connected”. It does not silently attempt failed travel. The central museum passage is the continuation. Repairing the optional lab route remains recorded work.

The owned rendered review exercises real desktop pointer buttons and slider drags, sample/colour mapping, generator readback, replay, local ownership and the central aisle. Exact results, source hashes and images are in doc/space/pair-review-2026-09-13. Headset reach, comfort and Quest performance are deferred. No benchmark or universal isotropy claim is made from this hall.

# Noise, taught in the order the engine needs it

> Ninth sequence through the recipe (2026-08-27). Cheat-code: **`FastNoiseLite` —
> randomness with a neighbourhood.** And its property list IS the ladder: noise is a
> FUNCTION not a stream (same x, same answer, forever), `frequency` is how fast the
> neighbourhood forgets, `fractal_octaves` stacks scales, `noise_type` is four
> temperaments of coherence, `domain_warp` is noise controlling where noise is read.

June's canon named map blurbs as concepts ("White noise screams chaos", "Before Perlin,
noise was static"). Replaced by nine rungs; the blurb sections were **merged into Off
the ladder rather than dropped** — 34 bodies wait there for chips, and the hand layer
already lifted 16 onto real rungs. Truth kept: *"Noise is randomness that remembers its
neighbors."* Live at **localhost:3003/noise-concepts** — 45 tiles.

## The ladder
1. **The scream** — white noise: no neighbourhood at all.
2. **The promise** — `get_noise_2d`: nearby agrees, and the same point answers forever.
3. **Frequency** — how fast the neighbourhood forgets; zoom is vocabulary.
4. **Octaves** — fbm: big shapes plus their own gossip.
5. **The kinds** — Perlin / Simplex / Cellular / Value: four temperaments, one seed.
6. **The field** — samples read as angles; space acquires a lean.
7. **Displacement** — samples read as height; the surface that remembered a storm.
8. **Noise of noise** — `domain_warp`: bending WHERE the cloud is read.
9. **The world** — one threshold and it is a coastline; the door to proceduralgeneration.

## The super: the_same_cloud

A weather bureau where **every station reads ONE FastNoiseLite** (seed 4) and disagrees
only about how: the white scream beside the coherent promise; three frequency plates of
the same cloud; an octave stair summing 1/3/5 layers; four kind-tiles from one seed; a
vane field of samples-as-angles; a relief bench of samples-as-height; a real
`domain_warp` pair (plain, then read through itself); and a thresholded coastline.
3,146 meshes — every board is genuine per-cell sampling, not a texture. Probe 0 broken;
seated at The promise.

Instrument note: `var x := arr[i]` struck three more times here (mult, oct, the kinds
pair). The engine log named every one in a single read. Typed pulls remain the law.

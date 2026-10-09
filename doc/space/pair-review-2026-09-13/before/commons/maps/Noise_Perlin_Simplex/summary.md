# Noise Perlin Simplex — Summary

Noise_Perlin_Simplex closes the Noise sequence on the current spine. On 2026-09-10 its interior — an all-void basin that a 100 m terrain artifact used to fill, and that the pathfinder could not walk — was floored, and the three museum piers along the east side were removed, so the 13×15 hall is a plain walkable room with its spawn in the north-west corner and the optional Lab Path portal in the south-east.

Two fields of half-metre cubes stand either side of a one-metre aisle: `simplex_noise` at (3,7) and `perlin_noise` at (8,7), each 8 cells on a side, each placed with the same seed (20260910), the same octaves, frequency and gain, and the shared colour ramp. Only the Perlin field carries `generator:perlin`; before this it drew simplex under the Perlin name. Each field has a RackTemplates panel in front of it — FREQ and OCTAVES sliders, REGEN and REPLAY — and a readout above the panel that names the basis read back from the generator, the seed, the parameters, and the field's value at (0, 0) and (2.5, 2.5). The two readouts differ in the first word and in the two values, and in nothing else.

The lesson is the comparison contract: repeatability per basis (REPLAY restores the declared seed), a single-variable change (one dial), and the same integer in two bases producing unrelated fields. Behind the pair, `perlin_noise_terrain` turns the same sampling into ground as a secondary exhibit. The portal is labelled optional and is inert: measured on 2026-09-13, its destination resolves to nothing. The route continues to CA_Introduction by the spine's ordering and the museum's passage, not by anything this sequence's JSON encodes, and there cells are updated from their neighbours rather than sampled from a field.

## The witness (2026-09-13)

Between the two panels there is now a plate carrying both generators' own properties, side by side: seed, generator frequency, fractal octaves, gain, lacunarity, fractal type, the multiplier applied to the sampled coordinates, and the offset added to them. Every one of those is equal. `noise_type` is 0 on the left and 3 on the right.

Those numbers are read from the two FastNoiseLite objects that drew the fields, not from the placements that asked for them — the difference between "we set the frequency to 0.05" and "the generator's frequency is 0.05". They are read after every control in the room has been used, because the basis reaching the perlin field depends on which of two paths ran, and reading it once before anything is touched cannot see that.

The optional door is inert. Measured through its own code rather than its label: its destination resolves to nothing, because the two ways it knows to load a map do not exist in this project.

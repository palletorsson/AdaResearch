# Noise 6 Wall — Summary

Noise_6_Wall is the fifth map in the Noise sequence. It moves noise from CPU loops to the GPU. A tall wall across one side of the room displays six octaves of fractal Brownian motion in real time; each octave is visible as a strip, and the strip below sums the octaves so far.

The visualisation makes the logic of octaves legible at a glance. The top strip shows a single low-frequency noise field — broad, slow features. Each strip below that doubles the frequency and halves the amplitude. By the bottom of the wall, the signal looks like cloth or weathered stone: a texture built by repeated self-similar addition.

The computation runs as a shader. A fragment program samples a hash-based noise function at each pixel, loops over the six octaves, and writes the summed result. The map names the shift explicitly on a side panel: the same function that took a thousand CPU frames to render fills the wall once per frame on the GPU because every pixel evaluates in parallel.

A second display mirrors the wall at a different scale, so the learner can compare how fBm reads at high and low frequency without tuning sliders. Within the sequence, this map argues that noise is a resolution-independent resource, not a texture to bake.

## The sample panel (2026-09-12)

`shader_noise_space:180#stand:panel` stands at (9,2), beside the entrance path rather than across it, on a reading landing laid for it; the room artifact keeps its place at (6,6). The board carries four patches of one field at 1, 2, 4 and 6 layers — one seed, one coordinate frame, one contrast, one colour, one clock — differing only in how many terms of the sum are added.

The shader's accumulation loop takes its bound from a uniform since this pass (it was written `for (int i = 0; i < 6; i++)`, which is why the room's own final proposed an isolation nobody could perform), and a second uniform shows the sum on its own, without the turbulence and colour the room paints over it. Both default to the shipped picture.

The plate declares the weights rather than normalising them away: one layer carries 0.5 of the amplitude, two 0.75, four 0.9375, six 0.984375. That series is the whole of why the left patch is darker. All four are shown at one display gain, which the plate also states.

LAYERS takes the room's own materials to the same count, so the number on the plate and the number in the walls are never two different claims. FREEZE stops every animated term at once: the shader's clock, the colour cycling and the density breathing, on the walls and on all four patches. BASIS changes the generator and leaves the layer count alone, because six walls and six octaves are not the same six.

Measured and stated rather than fixed: the scene's enclosure measures 18.1 x 13.6 x 27.1 m in a hall 13 cells across, so in the museum its walls stand outside the hall's walls — a visitor here passes the cloud rather than entering it, and final.md says so. The scene is placed in twelve maps; resizing it is their decision, not a panel pass's.

Corrected in the same pass: the room's wall and room materials were shared resources, so a uniform set in one hall was set in every other placement's walls. Each instance now has its own, and the layer control reaches only rooms under its own hall.

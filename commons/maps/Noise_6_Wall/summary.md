# Noise 6 Wall — Summary

Noise_6_Wall is the fifth map in the Noise sequence. It moves noise from CPU loops to the GPU. A tall wall across one side of the room displays six octaves of fractal Brownian motion in real time; each octave is visible as a strip, and the strip below sums the octaves so far.

The visualisation makes the logic of octaves legible at a glance. The top strip shows a single low-frequency noise field — broad, slow features. Each strip below that doubles the frequency and halves the amplitude. By the bottom of the wall, the signal looks like cloth or weathered stone: a texture built by repeated self-similar addition.

The computation runs as a shader. A fragment program samples a hash-based noise function at each pixel, loops over the six octaves, and writes the summed result. The map names the shift explicitly on a side panel: the same function that took a thousand CPU frames to render fills the wall once per frame on the GPU because every pixel evaluates in parallel.

A second display mirrors the wall at a different scale, so the learner can compare how fBm reads at high and low frequency without tuning sliders. Within the sequence, this map argues that noise is a resolution-independent resource, not a texture to bake.

<<<ADA_BUNDLE>>>
sequence: noise
file: tutorial.md
maps: 10
skipped_passing: 0
created: 2026-04-24T09:20:12
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Random_Noise_Types>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Establishes that randomness is not monolithic — white noise and blue noise are both random but structurally opposite, and the full noise color spectrum (pink, brown, violet) maps frequency weighting to perceptual character. | Sequence role: First map in the Noise sequence (8th spine, phase E_entropy); the entry point where randomness acquires spectral identity. Bridges from the Randomness sequence's coin-flip independence into the structured disorder that defines everything ahead — coherent noise, domain warping, voxel worlds. What follows requires understanding that different noise dis | [... truncated ...]
# BLURB: White noise screams chaos — every frequency, every sample independent, pure static. Blue noise whispers structure — random but refusing to clump, maintaining distance. Between them: the spectrum of coherent randomness.  …
[empty — to generate]

<<<MAP: Noise_Columns>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Classical columns dissolve under 3D Perlin noise displacement — form melts into field, and the process is reversible. Noise is not destruction but sculpture: a coherent force that reshapes geometry while preserving the memory of what it deformed. | Sequence role: Second map in the Noise sequence; the first encounter with coherent noise as a spatial operation rather than a statistical distribution. After Random_Noise_Types established the spectrum, this map applies noise to geometry — the moment randomness becomes a tool. The Bernini reference is deliberate: classical form subjected to c | [... truncated ...]
# BLURB: Noise extruded vertically. Sample the 2D function, lift the result into height. Mountains rise from mathematics, valleys fall from continuous variation. The columnar terrain is noise made navigable — you walk through the…
[empty — to generate]

<<<MAP: Noise_One>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Noise octaves as fractal summation — layering multiple frequencies of coherent noise with decreasing amplitude produces complexity that no single frequency can achieve alone. The torus makes the layering tangible, wrapping noise across a surface where seams reveal continuity. | Sequence role: Third map in the Noise sequence; the pivot from single noise fields to composite noise. After Noise_Columns showed what one Perlin field does to geometry, this map introduces the technique that makes noise useful for natural textures: octave stacking. Frequency doubles, amplitude halves, and the su | [... truncated ...]
# BLURB: Before Perlin, noise was static — random values with no memory, no structure. Then came coherent noise: smooth, continuous, organic. Sample adjacent points and get adjacent values. The noise function remembers its neighb…
[empty — to generate]

<<<MAP: Noise_Voxel>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Continuous noise fields become discrete voxel structures through sampling and thresholding — the moment a smooth mathematical function hardens into habitable geometry. Minecraft-style procedural generation as the applied consequence of everything the sequence has taught so far. | Sequence role: Fourth map in the Noise sequence; the transition from noise-as-texture to noise-as-architecture. After three maps of continuous fields (spectrum, displacement, octaves), this map introduces discretization — the threshold that converts a floating-point field into binary solid/void decisions. This  | [... truncated ...]
# BLURB: Three-dimensional noise carved into blocks. Where the function exceeds threshold: solid. Where it falls below: void. Caves, overhangs, floating islands — topologies impossible with heightmaps alone. The voxel grid quanti…
[empty — to generate]

<<<MAP: Noise_6_Wall>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Noise moves to the GPU — shader-based procedural generation using hash functions and parallel computation. What ran as sequential CPU loops now executes simultaneously across millions of fragments, and the wall displays six octaves of fractal Brownian motion as real-time procedural texture. | Sequence role: Fifth map in the Noise sequence; the advanced implementation pivot. After four maps of conceptual and CPU-side noise, this map reframes noise as a shader problem — massively parallel, hash-driven, resolution-independent. The six-octave wall is both pedagogy and proof: each octave con | [... truncated ...]
# BLURB: Six octaves layered. Low frequency for large features, high frequency for fine detail. Each octave adds texture at a different scale. The wall displays the sum — how simple waves at different frequencies combine into com…
[empty — to generate]

<<<MAP: Noise_Inside_Noise>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Domain warping — noise distorts the coordinate system of another noise function, producing organic swirling patterns impossible through simple layering. When the input to noise is itself noisy, space folds and the result remembers turbulence the way marble remembers pressure. | Sequence role: Sixth map in the Noise sequence; the advanced composition technique that transcends additive octaves. After Noise_One layered noise by amplitude and Noise_6_Wall moved computation to the GPU, this map introduces multiplicative composition — noise as coordinate transformation. The output of f(x) bec | [... truncated ...]
# BLURB: Noise controlling noise. The output of one function becomes the input coordinate of another. Warped, distorted, folded space. What was smooth becomes turbulent. What was regular becomes organic. Domain warping: when the …
[empty — to generate]

<<<MAP: Noise_Space_10>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The full parameter space of noise made navigable — ten dimensions of control (position x/y/z, time, octaves, persistence, lacunarity, frequency, amplitude, seed) exposed as interactive sliders. Every terrain, texture, and cloud the sequence has shown is a single point in this space; now the learner traverses the space itself. | Sequence role: Seventh map in the Noise sequence; the exploratory synthesis that follows the advanced techniques. After domain warping and GPU shaders pushed noise into complex territory, this map pulls back to the parameter level — the meta-view. Every noise con | [... truncated ...]
# BLURB: Expand the canvas. Ten dimensions of parameters: position, time, octaves, persistence, lacunarity, seed. Each dimension adds variation, adds control, adds possibility. The space of all possible noise configurations is va…
[empty — to generate]

<<<MAP: Noise_Perlin_Simplex>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Two algorithms for the same problem — Perlin noise (1983) and Simplex noise (2001) compared side by side. Perlin interpolates gradients on a hypercubic grid; Simplex uses a triangular (simplicial) grid. Eighteen years of algorithmic refinement visible in the artifacts each method leaves behind. | Sequence role: Eighth map in the Noise sequence; the algorithmic comparison that grounds the sequence's practical knowledge in implementation history. After seven maps of using noise, this map asks how noise is made. The configurable_portal connects this map to other sequences, positioning it a | [... truncated ...]
# BLURB: Perlin noise: the original coherent gradient noise, 1983. Simplex noise: Ken Perlin's improved version, 2001. Compare them side by side. Perlin has axis-aligned artifacts; Simplex is cleaner in higher dimensions. Evoluti…
[empty — to generate]

<<<MAP: Lab_Path>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The corridor back. Every sequence ends here — not a lesson but a threshold. The dark sphere pulses in the passage between what was learned and what comes next, marking transition without teaching. | Sequence role: Ninth and final map in the Noise sequence; the exit shared by all spine sequences. The same 5x5 grid, the same low ceiling, the same teleporter. What changes is what the learner carries through it. Before noise, randomness was memoryless and discontinuous. Now it remembers its neighbors — Perlin gradients, Simplex simplices, octaves layered into terrain, domain warping folding | [... truncated ...]
# BLURB: The corridor back. Every sequence ends here — nine maps of noise, and now the return. A dark sphere pulses in purple light, slow rotation, breathing emission. Not a lesson. A threshold.  All paths converge on this point.…
[empty — to generate]

<<<MAP: Chamber_Noise>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: World-building — the player becomes environment designer rather than combatant. The chamber replaces the creature encounter with a place-making practice, and the catalyst acts on terrain rather than on a body. | Sequence role: Catalyst chamber for the Noise sequence, the last map before returning to the Lab. The only chamber in the curriculum without a creature, because the sequence's argument — that coherent noise is a generative medium — lands best when the learner uses it to author a small place rather than to negotiate with something else. | Technical angle: Catalyst mode none, becaus | [... truncated ...]
# BLURB: No weapon, no creature. You sculpt the terrain with Perlin noise. The landscape rises and falls. You are making a world.  This is the catalyst chamber for the Noise sequence — the only chamber where you do not shoot and …
[empty — to generate]

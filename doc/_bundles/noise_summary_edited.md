<<<ADA_BUNDLE>>>
sequence: noise
file: summary.md
maps: 9
skipped_passing: 1
created: 2026-04-23T19:13:48
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Noise_Columns>>>
# Noise Columns — Summary

Noise_Columns is the second map in the Noise sequence. It introduces coherent noise as a tool that operates on geometry rather than as a statistical distribution to be described. The space is a small terrain field. Classical stone columns stand in rows at the edges; between them, the ground rises and falls according to a 2D Perlin field lifted into height.

The terrain is built by sampling the noise function at each grid cell and extruding the sample as the cell's altitude. Low values become valleys, high values become ridges. The result is continuous rather than jagged: each point agrees with its neighbours, because the noise function is smooth. The learner can walk the whole field without stepping over discontinuities.

At the far end, a row of columns stands partly ruined. A slider at the entrance drives a displacement parameter that pushes each column's vertices outward along its normal according to a 3D noise function. Raising the slider melts the columns into drifting stone; lowering it returns them to classical form. The operation is reversible, so the learner sees noise as sculpture rather than damage.

Within the sequence, Columns is the first map where noise leaves the graph and becomes a spatial operator. Noise_One will extend the technique by stacking multiple frequencies into a composite field.

<<<MAP: Noise_One>>>
# Noise One — Summary

Noise_One is the third map in the Noise sequence. It introduces octave stacking — the technique that turns coherent noise from a single smooth layer into the rough, multi-scale patterns that read as natural. A large torus at the centre of the room carries the demonstration.

The torus surface is coloured by a noise function. A bank of sliders next to it controls four parameters: the number of octaves, the lacunarity, the persistence, and the base frequency. At one octave, the surface reads as a slow gradient. Adding octaves layers progressively finer noise on top, each at roughly twice the frequency and half the amplitude of the one before. The surface grows texture — first wide strokes, then grain, then pore-scale detail.

Because the torus is a closed surface, the learner can walk around it and see how the noise wraps. A seam is drawn lightly where the sampling coordinates restart, and the map uses that seam to show that coherent noise is continuous across space but not automatically across wrapping — the seam has to be handled deliberately.

Within the sequence, Noise_One is the pivot from single to composite fields. Noise_Voxel will next take this kind of layered field and discretise it into habitable architecture.

<<<MAP: Noise_Voxel>>>
# Noise Voxel — Summary

Noise_Voxel is the fourth map in the Noise sequence. It converts continuous noise into discrete solid-or-void geometry. The space is a cubic volume filled with a 3D noise field; a threshold slider at the entrance decides which cells become solid and which stay empty.

At low thresholds, most cells read as solid — a dense stone block with small scattered pockets. At high thresholds, most cells read as void, leaving floating stone islands suspended in the air. Between the extremes, caves open, overhangs form, shelves and bridges appear. The same noise field produces radically different topologies as the threshold changes, and the learner can scrub through the range live.

A smaller control set layers additional transformations. One slider selects the noise type; another adjusts the base frequency, so the learner can trade detail for feature size. A toggle switches between binary voxels and a softer surface that follows an iso-contour rather than a per-cell cut.

Within the sequence, Voxel is where noise starts behaving like architecture. The threshold operation is the minimum commitment a procedural world must make: somewhere there has to be a stone wall and somewhere there has to be air. Noise_6_Wall will next move the same kind of field to the GPU.

<<<MAP: Noise_6_Wall>>>
# Noise 6 Wall — Summary

Noise_6_Wall is the fifth map in the Noise sequence. It moves noise from CPU loops to the GPU. A tall wall across one side of the room displays six octaves of fractal Brownian motion in real time; each octave is visible as a strip, and the strip below sums the octaves so far.

The visualisation makes the logic of octaves legible at a glance. The top strip shows a single low-frequency noise field — broad, slow features. Each strip below that doubles the frequency and halves the amplitude. By the bottom of the wall, the signal looks like cloth or weathered stone: a texture built by repeated self-similar addition.

The computation runs as a shader. A fragment program samples a hash-based noise function at each pixel, loops over the six octaves, and writes the summed result. The map names the shift explicitly on a side panel: the same function that took a thousand CPU frames to render fills the wall once per frame on the GPU because every pixel evaluates in parallel.

A second display mirrors the wall at a different scale, so the learner can compare how fBm reads at high and low frequency without tuning sliders. Within the sequence, this map argues that noise is a resolution-independent resource, not a texture to bake.

<<<MAP: Noise_Inside_Noise>>>
# Noise Inside Noise — Summary

Noise_Inside_Noise is the sixth map in the Noise sequence. It introduces domain warping — the technique of using one noise field to distort the coordinate input to another. The result is the swirling, turbulent pattern that reads as marble, smoke, or wet paint.

At the centre of the space, a large slab carries the warped field. A control bench exposes the composition: the base field, the warp field, and the magnitude of the warp. At zero warp the slab shows clean horizontal bands. Raising the warp amount folds those bands into each other, because the coordinate fed into the base function is no longer a straight line through space but a noisy curve through it.

Two side displays break the operation down. One shows the raw warp field on its own, so the learner can see what the coordinate distortion looks like as a field. The other shows the base field sampled on an undistorted grid, so the before-state is visible. The warped slab is the combination of the two.

Within the sequence, Inside_Noise is where addition gives way to substitution. Previous maps layered noise on top of noise; this map feeds noise through noise. Noise_Space_10 will next pull back from technique to the full parameter space.

<<<MAP: Noise_Space_10>>>
# Noise Space 10 — Summary

Noise_Space_10 is the seventh map in the Noise sequence. It treats the full parameter space of noise as a thing to be navigated. Ten sliders at a long bench expose position x, y, z, time, octaves, persistence, lacunarity, frequency, amplitude, and seed. Every previous noise demonstration in the sequence lives somewhere in this space.

The central display shows the current point in that space as a rendered volume. Changing any slider redraws the volume immediately. Turning persistence up thickens the high-frequency detail; turning lacunarity up pulls the octaves further apart in frequency; shifting the seed replaces the noise with a different sample of the same distribution.

A small trail panel records the learner's recent parameter history, so the effect of a change is visible against what was there a moment ago. A preset bank saves points in the space as named configurations — "cloud", "marble", "stone", "foam" — and re-running a preset teleports the sliders back to that point.

Within the sequence, this map is the meta-view. The previous maps argued for specific techniques; this map says that all of those techniques are just coordinates in a shared space, and it hands the learner the vehicle for moving through it.

<<<MAP: Noise_Perlin_Simplex>>>
# Noise Perlin Simplex — Summary

Noise_Perlin_Simplex is the eighth map in the Noise sequence. It compares the two noise algorithms at the centre of the sequence, side by side. Two identical volumes sit next to each other on a central table; one is filled with Perlin noise, the other with Simplex noise. The two use the same seed, the same frequency, and the same amplitude, so any visible difference is algorithmic rather than parametric.

Perlin noise, introduced in 1983, interpolates random gradients across a hypercubic grid. Simplex noise, introduced by the same author in 2001, samples across a simplicial grid — triangles in two dimensions, tetrahedra in three. The replacement of cubes by simplices changes the cost of the algorithm and the shape of its artifacts. Perlin's outputs show weak alignment with the coordinate axes; Simplex's outputs do not.

The map annotates both volumes. Crosshairs on each axis highlight where axis-alignment artifacts appear in the Perlin sample. A toggle rotates the Perlin volume through forty-five degrees to demonstrate that the artifacts travel with the grid, not with the geometry. Side panels trace a brief history of each algorithm and list where each is preferred.

Within the sequence, this is the implementation map. The sequence has been teaching how to use noise; this map asks how noise is made.

<<<MAP: Lab_Path>>>
# Lab Path — Summary

Lab_Path is the corridor out of the Noise sequence and back toward the Lab. It is the ninth map in the sequence and shares its template with every other sequence's exit corridor: a small 5×5 grid, a low ceiling, a teleporter at the far end, and a single ambient element to mark the transition.

The corridor is lit softly. A dark sphere pulses at the midpoint, rotating slowly, emitting a low purple glow. No new artifact is introduced. No lesson is delivered. The space is deliberately under-decorated so the learner can register that a sequence has ended and that the next one is about to begin.

What makes this particular Lab_Path specific to Noise is the reading the learner carries through it. Nine maps earlier, randomness was memoryless — each sample independent, no relationship to its neighbours. After the Noise sequence, randomness has structure: Perlin gradients, octave stacks, domain warping, voxel thresholds. The walk back across Lab_Path is the pause in which that shift can settle before the Lab re-admits the learner to the broader curriculum.

Within the sequence, Lab_Path is the threshold. It teaches nothing and points at nothing, which is the point.

<<<MAP: Chamber_Noise>>>
# Chamber Noise — Summary

Chamber_Noise is the catalyst chamber for the Noise sequence. Unlike the other chambers, it hosts no creature to fight, calm, or befriend. Instead, the learner becomes the environment designer. A Perlin field lies under a small plot of ground, and the learner sculpts the terrain by adjusting the field in real time.

The chamber is quiet. A control bench at the entrance exposes noise parameters: frequency, amplitude, octaves, and a displacement magnitude. Turning the sliders lifts the ground into ridges and opens it into valleys. A second control selects between several distribution types — classical Perlin, Simplex, value noise — so the ground can take on the grain of each algorithm.

The science screen on the wall reads out the current field as a 2D map, a heightmap, and a parameter list. Saving a configuration writes it to a small gallery of terrains, so the learner can compare shapes they have made and return to them.

Within the sequence, Chamber_Noise reframes the catalyst practice. The other chambers treat catalyst, creature, and screen as a three-way relationship in which the learner holds a tool and the creature responds. This chamber removes the creature and lets the learner use the tool to make a place. The terrain itself is the thing cared for, and the screen names that work as world-building.

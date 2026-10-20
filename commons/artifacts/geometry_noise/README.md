# The Uncertain Surface

Installed in **Random_Noise_Types**, the opening hall of the Noise sequence. Find the two pale surfaces in the west bay, after the sampling displays and before the three temporal walls. The nearby slider changes the strength of one saved sample. NEXT SEED changes that sample; ZERO removes displacement; RESET restores seed 1847 and strength 0.18. EDGES hides or shows the same triangle-edge overlay on both surfaces.

This is a geometric noise experiment. It does not implement fuzzy inference, automatically locate a failure threshold, or claim that distortion is a glitch.

## What stays and what changes

Both surfaces begin as the same 2 × 2 metre plane: 17 × 17 vertices and 512 indexed triangles. Each vertex has a saved vector containing three Gaussian draws. Changing strength scales these same vectors; it does not draw new values or add displacement to an already displaced mesh.

`sigma_m = strength * 0.25`

At strength 0.18, the distribution's standard deviation is 4.5 cm per axis. This is not a probability of failure and not a maximum movement. Gaussian draws are unbounded in theory. This finite sample's largest movement is measured and displayed. The control constrains strength to 0–1; the geometry is visual and has no collision. The support plinths and ordinary controls retain their normal collisions.

The two copies use identical materials. Normals are recomputed from the actual displaced triangles. The optional wire overlay exposes connections; it adds no new faces. Indexed connectivity stays fixed, but the embedding can fold or intersect. The prototype does not count intersections or decide when a form stops being recognisable.

## Reading the measurements

- **Measured RMS:** square root of the mean squared displacement of the stored vertex coordinates. It is not the arithmetic mean of their distances.
- **Maximum:** largest measured distance for this sample.
- **Centroid drift:** distance between the mean original and mean displaced position. Zero-mean draws do not force a finite sample to have exactly zero mean; we do not recenter it.
- **Population RMS:** `sqrt(3) * sigma`. This is the square root of the population mean squared 3D displacement. A finite sample need not match it exactly, and it is not the expected value of the finite-sample RMS estimator.

Local Godot 4.6 measurement, seed 1847, strength 0.18: RMS 0.07759170 m; maximum 0.16402331 m; centroid drift 0.00148868 m. Reproducibility also requires the same engine generator, call order and code. Save the generated offsets when preservation across engine versions matters; the seed alone is not a version-independent archive. [Godot 4.6: RandomNumberGenerator](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html)

## Files and supplied dependencies

- `surface_sample.gd`: grid, local generator, displacement, measurements and indexed mesh construction.
- `GeometryNoiseTest.gd`: the actual museum artifact, its two surfaces, labels, plinths, controls and bounded in-memory event log.
- `GeometryNoiseTest.tscn`: root wrapper. Camera, museum environment, player, XR Tools and the shared ControlConsole come from the existing Ada project.
- `tutorial.md`: full source and explanation of the experiment.

The artifact constructs its own geometry. The shared control classes are explicit supplied infrastructure. There are no references to undeclared mesh children in a scene. Meshes rebuild only when a parameter changes; no experiment loop modifies the camera, player or project physics settings. The latest 64 parameter events remain available through `log_entries`; `experiment_updated` reports the complete current sample. The probe saves an evidence receipt. There is no automatic permanent player-session recording or clipboard button.

Run `python -X utf8 tools/test_geometry_noise.py` for native core/scene assertions. Run `python -X utf8 tools/run_encounter_probe.py Random_Noise_Types --sequence noise --render --probe tools/probes/geometry_noise_room.gd` for the actual hall. These tests exercise supplied poses/events; a physical headset and Quest performance remain untested.

## How this advances the sequence

Primitives supplied positions and triangle indices; Arrays supplied an address for each entry; Randomness supplied local seeds and draws. Here the student **keeps the connections and changes one saved displacement field's amplitude**. The later column, terrain and voxel halls can then distinguish the source of variation from its receiving operation. An independent Gaussian sample is not a coherent spatial field.

Transfer: halve strength without resampling and predict the RMS. Then change the seed and explain why the prediction for that particular mesh no longer follows from the previous sample. Neither exercise needs a new object.

Next research step: add one explicit geometric criterion, such as signed projected face area, and explain what it detects and misses. A projected reversal is not a complete self-intersection test. Physics disturbance and noisy navigation remain separate future experiments.

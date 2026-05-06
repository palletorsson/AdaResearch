# The Randomness Curriculum
## A Comprehensive Ground-Up Presentation Plan

This document outlines a structured progression for presenting **ALL** material in `algorithms/randomness`. It organizes the vast library of examples into a coherent 5-Map journey, moving from simple chance to complex emergent systems.

---

### 🎲 Map 1: The Dice (Chance & Distribution)
**Theme:** The atom of randomness. Understanding the roll of the die, the curve of the bell, and the nature of unpredictability.
**Environment:** Casino / Data Center / Clean White Void.

1.  **The Coin Flip (Basics)**
    *   `randomnumbergeneration`: Basic RNG functions.
    *   `trng_vs_prng`: The difference between True and Pseudo randomness.
    *   `randompoint` / `randompoints`: Generating points in space.
    *   `randomadd` / `randomup`: Simple additive randomness.
2.  **The Bell Curve (Statistics)**
    *   `distributions` / `distribution_visualization`: Visualizing how randomness clusters.
    *   `GaussianDistribution.gd` / `gaussian_random.tscn`: The Normal Distribution.
    *   `randombellcurve`: Practical application of Gaussian math.
    *   `randomdecay`: Exponential decay probabilities.

---

### 🚶 Map 2: The Drunkard (Walks & Paths)
**Theme:** Randomness in motion. From the "Drunkard's Walk" to maze generation.
**Environment:** City Streets / Labyrinth / Grid.

1.  **The Step (Random Walks)**
    *   `randomwalk`: The classic algorithm.
    *   `example_0_1_random_walk.tscn`: The "Nature of Code" implementation.
    *   `RandomWalk128Algorithm.gd` / `random_walk_128.tscn`: Optimized/Specific variations.
    *   `WalkRandom.gd` / `walk_random.tscn`: 3D walking agents.
2.  **The Walker (Agents)**
    *   `walkingsphere`: A sphere driven by random forces.
    *   `random_bubbles`: Floating entities with random motion.
3.  **The Maze (Structured Chaos)**
    *   `ten_print`: The famous Commodore 64 maze algorithm (`10 PRINT CHR$(205.5+RND(1)); : GOTO 10`).
    *   `randomlines`: Drawing chaotic connections.

---

### ☁️ Map 3: The Cloud (Noise & Fields)
**Theme:** Coherent randomness. Smooth transitions, landscapes, and textures.
**Environment:** Mountain Range / Cloud Layer / Static TV.

1.  **The Static (Uncorrelated Noise)**
    *   `whitenoise`: Pure random static.
    *   `blue_noise`: Evenly distributed random points (anti-clumping).
2.  **The Smooth (Coherent Noise)**
    *   `noise` / `perlinnoise`: The foundation of procedural generation.
    *   `simplexnoise`: An improvement on Perlin.
    *   `valuenoise`: A simpler, blockier noise.
    *   `noiselayers`: Combining octaves for detail (Fractal Brownian Motion).
3.  **The Terrain (Application)**
    *   `noiseterrain`: Generating landscapes.
    *   `noisesphere`: Displacing a sphere (Planets).
    *   `noisetorus`: Displacing a donut.
    *   `perlinnoiseclouds` / `pixelcloud`: Volumetric effects.
    *   `shadernoisespace`: Noise on the GPU.
    *   `noisetext`: Noise applied to typography.
    *   `voxelnoise`: 3D blocky noise.

---

### 🏗️ Map 4: The Builder (Placement & Variation)
**Theme:** Using randomness to construct, scatter, and modify the world.
**Environment:** Construction Site / Sculpture Garden.

1.  **The Scatter (Spawning)**
    *   `random_object_spawner.gd`: Placing objects arbitrarily.
    *   `PickupCubePlacer.gd` / `pickup_cube_placer.tscn`: Gameplay-focused placement.
    *   `PlaneRandom` / `plane_effects`: Scattering on a surface.
2.  **The Variation (Transform)**
    *   `random_transformations`: Jittering position, rotation, scale.
    *   `RotateRandomY` / `RandomRotateRandomXYZ`: Orientation variance.
    *   `RotateGridCubes.gd` / `RotateGridCubes.tscn`: Grid-based variation.
    *   `HeightRandomness.gd` / `height_random.tscn`: Varying verticality.
    *   `ProfileRandom.gd` / `profile_random.tscn` / `RandomProfile.gd`: Shape variation.
3.  **The Sculptor (Subtraction)**
    *   `RemoveRandom.gd` / `remove_random.tscn`: Creating holes/ruins by deleting parts.
    *   `RandomizeCubesOverZ`: Progressive variation.

---

### 🌌 Map 5: The System (Entropy & Emergence)
**Theme:** Complex systems where randomness leads to art, decay, or life.
**Environment:** Glitched Reality / Alien Ecosystem.

1.  **The Glitch (Digital Materiality)**
    *   `digital_materiality_glitch`: When randomness breaks the medium.
    *   `entropy_axiom`: The tendency towards disorder.
2.  **The Art (Generative)**
    *   `generative` / `proceduralrandomness`: Algorithms creating aesthetics.
    *   `sculpt_one.tscn` / `SculptOne.gd`: Procedural sculpture.
    *   `env_one.tscn` / `envOne.gd`: Procedural environment.
    *   `bell_alley`: A specific generative scene.
    *   `pipedream`: Networked generative structures.
3.  **The Life (Emergence)**
    *   `pheromone_terrain`: Ant-like trails and emergent paths.

---

### 📝 Implementation Strategy
Similar to the Wavefunctions curriculum, we should create a **"Casino of Chaos"** or **"Entropy Lab"** Hub World.
*   **Map 1** is a clean, white lab (understanding the basics).
*   **Map 2** is a neon city grid (walkers).
*   **Map 3** is a terraforming station (noise).
*   **Map 4** is a factory (builder).
*   **Map 5** is a surreal, abstract void (systems).

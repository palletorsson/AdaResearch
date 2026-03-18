# Artifact Registry

Central directory of JSON registry files that define all artifacts in the project. Each file contains artifact entries with lookup names, scene paths, metadata, and configuration. This is the authoritative source for artifact definitions, loaded by ArtifactCatalogDataProvider and GridInteractablesComponent.

## How It Works

Each JSON file defines a dictionary of artifacts keyed by lookup name. Entries include fields such as `scene`, `name`, `description`, `sequence`, `category`, `tags`, and optional grid config defaults. The files are organized by domain (e.g., `physics_simulation.json`, `randomness.json`, `transforms.json`). At runtime, all files in this directory are loaded and merged into a unified registry.

## Files

49 JSON registry files covering domains including algorithms, arrays, cellular automata, chaos, color, computational biology, data structures, foundations, grammar systems, grid operations, hazards, isosurfaces, L-systems, machine learning, mesh grammar, nature systems, neuroscience, parametric, physics simulation, primitives, procedural generation, QFEP, quantum algorithms, randomness, shaders, soft bodies, speech, statistics, steering, swarm intelligence, transforms, vectors, and wave functions.

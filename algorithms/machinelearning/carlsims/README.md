# Karl Sims Inspired Evolution


## Folder Summary

The `Karl Sims Inspired Evolution` module provides a 3D sandbox for exploring the ideas behind the Karl Sims Inspired Evolution workflows. It invites visitors to tune parameters, watch spatial feedback evolve in real time, and connect the algorithm's theory to an intuitive scene.

It ships with the scene file `evolved_creatures.tscn`, controller scripts such as `carlsims_tutorial.gd` and `evolvedcreatures.gd`, and supporting assets including `code_prompt.txt` and `meta.json`.

## Scene Assets
- `evolvedcreatures.tscn` — camera + light; the script builds the ground plane and creatures at runtime.
- `evolvedcreatures.gd` — controller that maintains the population, applies joint motors, evaluates fitness, and breeds new generations.
- `code_prompt.txt` — instructions for regenerating the script with an AI assistant.
- `carlsims_tutorial.gd` — in-world BBCode tutorial board.
- `meta.json` — catalog entry for VR menus/search.

## How It Works
1. `_build_ground()` adds a static floor so physics can settle.
2. `spawn_initial_population()` samples random genomes (hip amplitudes/frequencies/phases, body masses) and builds walkers with rigid body torsos + two hinged legs.
3. `_physics_process()` drives each hip joint with a sinusoidal motor derived from the genome.
4. After `GENERATION_DURATION` seconds, `_evaluate_population()` measures forward displacement and height bonus to compute fitness.
5. `_evolve_generation()` keeps the top genomes, breeds children via weighted crossover, mutates traits, and respawns the population.

## Exported Controls
- `random_seed` — deterministic seed for genome sampling.
- `enable_random_restart` — optionally add fresh random genomes when filling the population.
- `enable_debug_prints` — print per-generation fitness values.

## Usage Tips
- Watch for walkers that develop asymmetric gaits; mutation can produce interesting cycles.
- Toggle `enable_random_restart` to keep injecting new genomes if the population converges too soon.
- Adjust `GENERATION_DURATION`, `HIP_MAX_TORQUE`, or mutation constants in the script for faster/slower evolution.

## Extending
- Add knee joints or extra body segments for richer morphologies.
- Implement obstacles and evaluate how walkers cope.
- Track average fitness per generation and visualise trends with labels or graphs.

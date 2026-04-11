# Neuroevolution -- Nature of Code Chapter 11

Six progressive examples translated from Daniel Shiffman's *Nature of Code* (Processing) into Godot 4 GDScript for VR. Together they teach **neural networks, evolutionary algorithms, fitness-proportional selection, and emergent behavior** -- from a manual Flappy Bird to a self-sustaining neuroevolved ecosystem.

## How It Works

Each example builds on the previous one, introducing a new concept:

### 11.1 -- Flappy Bird (manual control)
A single bird with gravity, flap input, scrolling pipe obstacles, and box-based collision. This baseline demonstrates the game mechanics that later examples will learn to play autonomously.

### 11.2 -- Flappy Bird Neuroevolution
A population of 20 birds, each with a small neural network brain (5 inputs, 8 hidden, 1 output). Inputs are the bird's Y position, Y velocity, distance to the nearest pipe, and the gap boundaries. When all birds die, the next generation is bred via **fitness-proportional selection**: a mating pool is filled in proportion to each bird's fitness (distance traveled + pipes passed), a parent is chosen at random, its brain is copied and mutated, and the process repeats.

### 11.3 -- Smart Rockets Neuroevolution
Rockets with 6-input / 8-hidden / 4-output brains must navigate around box obstacles to reach a glowing target. Fitness rewards proximity to the target, heavily bonuses hitting it, and penalizes obstacle collisions. Trail ribbons visualize each rocket's path. The same fitness-proportional selection and mutation pipeline drives evolution.

### 11.4 -- Neuroevolution Steering: Seek
Steering creatures with 8 inputs (position, velocity, goal direction) and 2 outputs (steering force X, Y) evolve to seek a moving goal while avoiding rotating hazard cubes. The goal respawns at a random location each time a creature reaches it, and fitness accumulates over time, rewarding both proximity and survival.

### 11.5 -- Creature Sensors
A single creature has five forward-facing sensors arranged in a 120-degree arc. Each sensor casts into a 30-degree cone and returns a normalized distance reading for the nearest food item. The creature reactively turns toward the strongest signal -- no neural network yet, just a demonstration of **sensory perception** as neural-network input.

### 11.6 -- Neuroevolution Ecosystem
The full synthesis: a population of sensor-equipped creatures with neural network brains forage on spawning food orbs. Health drains over time; eating restores it. Creatures that accumulate enough health reproduce asexually, passing a mutated copy of their brain to the offspring. Dead creatures are removed. The ecosystem is open-ended -- population size fluctuates naturally. A pink "energy fog" plane and fading trails visualize the living system.

## Parameters

Parameters are defined as class-level variables in each example:

| Parameter | Example | Default | Description |
|-----------|---------|---------|-------------|
| `population_size` | 11.2--11.4, 11.6 | 10--25 | Number of agents per generation |
| `mutation_rate` | 11.2--11.4 | 0.1 | Probability of weight perturbation per gene |
| `max_lifetime` | 11.4 | 20.0 s | Maximum seconds before forced death |
| `num_sensors` | 11.5, 11.6 | 4--5 | Number of directional sensors |
| `sensor_range` | 11.5, 11.6 | 0.25--0.3 | Detection radius per sensor |
| `max_population` | 11.6 | 30 | Hard cap on ecosystem size |
| `food_spawn_rate` | 11.6 | 2.0 s | Seconds between food spawns |
| `reproduction_threshold` | 11.6 | 80.0 | Health required to reproduce |

## Features

- Progressive complexity from manual play to emergent ecosystem.
- Fitness-proportional selection with mating pools.
- Neural network brains with `predict()`, `copy()`, and `mutate()` interfaces.
- Sensor cone system for creature perception (angle-based, distance-normalized).
- Asexual reproduction with brain mutation in the ecosystem example.
- Health, aging, and natural death for population self-regulation.
- Visual feedback: trail ribbons, sensor cones, glowing targets, fading dead agents, and population/generation HUD labels.
- All examples adapted for VR with billboard labels and 3D spatial layouts.

## Files

| File | Purpose |
|------|---------|
| `example_11_1_flappy_bird_vr.gd` | Manual Flappy Bird -- gravity, pipes, collision |
| `example_11_2_flappy_bird_neuroevolution_vr.gd` | Neuroevolved Flappy Bird population |
| `example_11_3_smart_rockets_neuroevolution_vr.gd` | Rockets evolving to reach a target past obstacles |
| `example_11_4_neuroevolution_steering_seek_vr.gd` | Steering creatures evolving to seek goals and avoid hazards |
| `example_11_5_creature_sensors_vr.gd` | Single creature with directional sensor array |
| `example_11_6_neuroevolution_ecosystem_vr.gd` | Self-sustaining ecosystem with reproduction and death |

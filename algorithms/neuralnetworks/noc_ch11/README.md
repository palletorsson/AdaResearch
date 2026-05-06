# Nature of Code Chapter 11: Neuroevolution

VR translations of Daniel Shiffman's neuroevolution examples — neural networks that learn through evolution, not backpropagation.

## QFEP Connection

Neuroevolution is **evolution applied to brains**. Random mutations (E) create neural network variations; selection pressure keeps the best performers (F). No teacher, no gradient — just survival. This mirrors biological intelligence: brains that work persist, brains that don't disappear.

## Examples Included

| File | Topic | Description |
|------|-------|-------------|
| `11_1_flappy_bird_vr` | **Manual Flappy Bird** | Human-playable baseline |
| `11_2_flappy_bird_neuro_vr` | **Neuro Flappy Bird** | NN-controlled bird evolution |
| `11_3_smart_rockets_neuro_vr` | **Smart Rockets** | Rockets evolving to hit target |
| `11_4_neuro_steering_vr` | **Neuro Steering** | Evolved steering behaviors |
| `11_5_creature_sensors_vr` | **Creature Sensors** | Creatures with evolved perception |
| `11_6_neuroecosystem_vr` | **Neuro Ecosystem** | Full ecosystem with evolved agents |

## Core Concepts

### Neural Network as Genome

```
Inputs → Hidden → Outputs
  [5]  →  [8]  →   [2]

Weights are the "genes" that evolve.
```

### Evolutionary Process

```
1. Create population of random networks
2. Evaluate fitness (score, survival time)
3. Select best performers
4. Create offspring with mutation
5. Repeat
```

### Fitness Functions

| Example | Fitness Measure |
|---------|-----------------|
| Flappy Bird | Time survived |
| Smart Rockets | Distance to target |
| Ecosystem | Food eaten - energy spent |

### Mutation

```gdscript
# Small random changes to weights
for i in weights.size():
    if randf() < mutation_rate:
        weights[i] += randf_range(-0.1, 0.1)
```

## Flappy Bird Neuro

The classic example:
- **Inputs**: Bird Y, velocity, pipe distance, pipe gap Y
- **Outputs**: Flap or not
- **Fitness**: Frames survived

After ~50 generations, birds learn to navigate pipes perfectly.

## Parameters (vary by example)

| Parameter | Typical Value | Description |
|-----------|---------------|-------------|
| `population_size` | 100-500 | Agents per generation |
| `mutation_rate` | 0.1 | Chance of weight change |
| `mutation_amount` | 0.1 | Size of weight changes |
| `elitism` | 0.1 | Top % kept unchanged |

## Source

All implementations translated from:
- **The Nature of Code** by Daniel Shiffman
- Original: Processing/p5.js
- License: CC BY-NC-SA 3.0

Adapted for Godot 4, 3D space, and VR interaction.

## Usage

```gdscript
var flappy = preload("res://algorithms/neuralnetworks/noc_ch11/11_2_flappy_bird_neuro_vr.tscn").instantiate()
add_child(flappy)
# Watch birds evolve over generations
```

## VR Experience

Watch populations of agents learn in real-time. Early generations flail randomly; later generations show coordinated, purposeful behavior. The ecosystem example is particularly mesmerizing — creatures evolve predator/prey dynamics without explicit programming.

## Educational Value

Neuroevolution teaches:
- **Alternative to backprop**: Learning without gradients
- **Genetic algorithms**: Selection, crossover, mutation
- **Emergence**: Complex behavior from simple rules
- **Open-ended evolution**: No fixed goal, just survival

## See Also

- `machinelearning/` — Gradient-based learning
- `neuroevolution/` — More evolution examples
- `emergentsystems/` — Evolved ecosystems

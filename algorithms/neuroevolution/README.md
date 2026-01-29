# Neuroevolution

Evolve neural networks through natural selection. No backpropagation needed.

## QFEP Connection

Neuroevolution is **φΔE in pure form** — populations of networks mutate, compete, and evolve. Unlike gradient descent (smooth F-minimization), evolution is noisy, exploratory, queer. It finds solutions that gradient descent cannot: discontinuous, multi-modal, creative.

## Contents

Based on **Nature of Code Chapter 11: Neuroevolution**.

| File | Description |
|------|-------------|
| `example_11_1_flappy_bird_vr.gd` | Flappy Bird environment |
| `example_11_2_flappy_bird_neuroevolution_vr.gd` | Evolve birds that play Flappy |
| `example_11_3_smart_rockets_neuroevolution_vr.gd` | Evolve rockets that reach target |
| `example_11_4_neuroevolution_steering_seek_vr.gd` | Evolve steering behaviors |
| `example_11_5_creature_sensors_vr.gd` | Creatures with evolved sensors |
| `example_11_6_neuroevolution_ecosystem_vr.gd` | Full ecosystem with predator/prey evolution |

## Key Differences from Backprop

| Backpropagation | Neuroevolution |
|-----------------|----------------|
| Gradient-based | Population-based |
| Needs differentiable loss | Any fitness function |
| Single solution | Multiple diverse solutions |
| Smooth optimization | Jumpy, exploratory |
| Fast convergence | Slower but more creative |

## Evolution Cycle

```
1. Create population of random networks
2. Evaluate fitness (play game, survive, etc.)
3. Select best performers
4. Reproduce with mutation/crossover
5. Replace old population
6. Repeat for many generations
```

## NEAT (Topology Evolution)

Advanced neuroevolution doesn't just evolve weights — it evolves **structure**:
- Add neurons
- Add connections
- Remove connections
- Speciation (protect innovation)

## VR Experience

- Watch generations evolve in real-time
- See fitness improve over time
- Visualize diverse strategies
- Intervene in evolution (select survivors)

## Files

- 6 GDScript files
- 6 scene files

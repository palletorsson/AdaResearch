# Neural Networks

Artificial brains. Learn from data, make decisions.

## QFEP Connection

Neural networks are **F-minimization machines** — they reduce prediction error through gradient descent. But they also embody QFEP's queer nature: the same network can learn order (classification) or generate entropy (hallucination, creativity). Learning *is* the φΔE.

## Contents

Based on **Nature of Code Chapter 11: Neural Networks**.

| File | Description |
|------|-------------|
| `training_point.gd` | Training data point with label |
| `11_1_flappy_bird_vr.gd` | Flappy Bird game environment |
| `11_2_flappy_bird_neuro_vr.gd` | Neural network plays Flappy Bird |
| `11_3_smart_rockets_neuro_vr.gd` | Rockets with neural controllers |
| `11_4_neuro_steering_vr.gd` | Neural network steering behaviors |
| `11_5_creature_sensors_vr.gd` | Creatures with sensory inputs |
| `11_6_neuroecosystem_vr.gd` | Ecosystem of neural creatures |

## Key Concepts

1. **Perceptron** — Single neuron: weighted sum + activation
2. **Layers** — Input → Hidden → Output
3. **Feedforward** — Data flows through network
4. **Backpropagation** — Error flows backward, adjusts weights
5. **Activation functions** — sigmoid, tanh, ReLU
6. **Training** — Minimize loss over dataset

## Neural Network Structure

```
Input     Hidden    Output
  ○─────────○
  ○─────╲  ╱○─────────○
  ○──────╲╱
  ○──────╱╲○─────────○
  ○─────╱  ╲○
```

## Learning Process

```
1. Forward pass: compute output from input
2. Calculate error: output vs expected
3. Backward pass: propagate error, compute gradients
4. Update weights: move toward less error
5. Repeat
```

## VR Experience

- Watch neural networks learn in real-time
- See weight visualizations (thickness = strength)
- Interact with learning creatures
- Evolve networks that survive

## Files

- 7 GDScript files
- 5 scene files

# Evolving Creatures Simulation

## Overview
This implementation demonstrates evolutionary algorithms applied to creature locomotion. Virtual creatures with randomly generated body structures evolve over generations to improve their walking, running, or swimming abilities through natural selection and genetic variation.

## Algorithm Description
The evolving creatures system combines genetic algorithms with physics simulation to evolve creature morphology and behavior. Each creature has a genotype encoding its body structure and neural network, which determines its fitness through locomotion performance.

### Key Components
1. **Creature Generation**: Procedural body creation with joints, limbs, and muscles
2. **Genetic Encoding**: DNA representation of morphology and neural networks
3. **Physics Simulation**: Realistic creature movement and environmental interaction
4. **Fitness Evaluation**: Performance measurement (distance, speed, stability)
5. **Evolutionary Operators**: Selection, crossover, and mutation

### Evolutionary Process
1. **Initial Population**: Generate diverse creatures with random genetics
2. **Simulation Phase**: Test each creature's locomotion ability
3. **Fitness Assessment**: Evaluate performance against survival criteria
4. **Selection**: Choose best-performing creatures for reproduction
5. **Reproduction**: Create offspring through genetic crossover and mutation
6. **Generation Cycle**: Repeat process with new population

## Algorithm Flow
1. **Population Initialization**: Create initial generation of random creatures
2. **Individual Testing**: For each creature:
   - Decode genetics into physical structure
   - Run physics simulation for movement
   - Measure fitness (distance traveled, energy efficiency)
3. **Evolution Step**: 
   - Select parents based on fitness
   - Generate offspring through crossover
   - Apply mutations for genetic diversity
4. **Population Replacement**: Replace old generation with evolved offspring
5. **Analysis**: Track evolutionary progress and convergence

## Files Structure
- `EvolvingCreatures.gd`: Main evolutionary algorithm and creature management
- `creature_simulation.tscn`: Physics environment for creature testing
- Genetic encoding, neural network, and physics components

## Parameters
- **Population Size**: Number of creatures per generation (50-200)
- **Generation Count**: Evolution duration (100-1000 generations)
- **Mutation Rate**: Genetic variation frequency (1-10%)
- **Selection Pressure**: Fitness-based reproduction bias
- **Body Constraints**: Limb count, joint limits, mass restrictions

## Genetic Representation
- **Morphology Genes**: Body structure, limb proportions, joint types
- **Neural Network**: Connection weights for muscle control
- **Behavior Parameters**: Movement patterns, reflexes, coordination
- **Material Properties**: Density, elasticity, friction coefficients

## Theoretical Foundation
Based on:
- **Evolutionary Algorithms**: Genetic algorithms and evolutionary strategies
- **Artificial Life**: Computer simulation of biological evolution
- **Neural Networks**: Creature brain simulation for motor control
- **Physics Simulation**: Realistic body dynamics and environmental interaction

## Applications
- Evolutionary robotics research
- Game AI development (creature behaviors)
- Biomechanics and locomotion studies
- Educational evolution demonstration
- Procedural animation generation
- Artificial life research

## Evolutionary Outcomes
Typical evolutionary results include:
- **Locomotion Gaits**: Walking, running, hopping patterns
- **Body Optimization**: Efficient limb proportions and joint placement
- **Behavioral Adaptation**: Environmental response strategies
- **Emergent Complexity**: Unexpected movement solutions

## Usage
Start the simulation to observe creatures evolving locomotion abilities over generations. Monitor fitness progression, analyze successful body plans, and experiment with different environmental challenges to drive evolutionary adaptation.
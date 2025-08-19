# Ecosystem Simulation

## Overview
This implementation provides a comprehensive predator-prey ecosystem simulation demonstrating emergent behavior, population dynamics, and evolutionary adaptation. The system models the complex interactions between different species including predators, prey, and food sources in a 2D environment.

## Algorithm Description
The ecosystem simulation implements a multi-agent system where individual creatures (predators and prey) follow simple behavioral rules that collectively produce complex emergent patterns. The simulation demonstrates ecological principles such as population cycles, carrying capacity, and natural selection.

### Key Components
1. **Creature Base Class**: Defines common properties and behaviors for all living entities
2. **Prey Agents**: Herbivorous creatures that seek food and avoid predators
3. **Predator Agents**: Carnivorous creatures that hunt prey for survival
4. **Food System**: Distributes and regenerates food sources throughout the environment
5. **Population Dynamics**: Birth, death, and reproduction mechanics
6. **Genetic System**: Simple mutation and inheritance for evolutionary adaptation

### Algorithm Flow
1. **Initialization**: Spawn initial populations of prey, predators, and food
2. **Agent Behavior**: Each creature follows its behavioral rules:
   - **Prey**: Seek food, avoid predators, reproduce when well-fed
   - **Predators**: Hunt prey, reproduce when successful
   - **Movement**: Physics-based movement with energy consumption
3. **Ecosystem Dynamics**:
   - Food regeneration maintains resource availability
   - Population pressure affects reproduction rates
   - Energy depletion leads to death
4. **Evolution**: Genetic traits mutate and are passed to offspring

## Files Structure
- `ecosystem.gd`: Main simulation controller and environment manager
- `Creature.gd`: Base class for all living entities with common behaviors
- `predator.gd`: Predator-specific behavior and hunting logic
- `pray.gd`: Prey-specific behavior and foraging logic (note: "pray" likely means "prey")
- `food.gd`: Food source management and consumption
- `ecosystem.tscn`: Scene file with initial setup
- Texture files: Visual representations for each entity type

## Parameters
- **Initial Populations**: Prey (50), Predators (5), Food (100)
- **Reproduction**: Mutation rate (0.1), proximity for mating (30.0)
- **Behavior**: Energy consumption, movement speed, detection ranges

## Theoretical Foundation
This simulation is based on:
- **Lotka-Volterra Equations**: Mathematical model of predator-prey dynamics
- **Emergent Systems Theory**: Complex behavior arising from simple rules
- **Evolutionary Algorithms**: Genetic variation and natural selection
- **Multi-Agent Systems**: Distributed autonomous entities interacting

## Applications
- Ecological modeling and conservation planning
- Population dynamics research
- Evolutionary algorithm development
- Game AI for realistic creature behaviors
- Educational simulation of natural selection

## Visual Features
- Real-time population counters
- Color-coded entities (prey, predators, food)
- Dynamic population visualization
- Interactive environment

## Usage
Run the ecosystem scene to observe population dynamics. Watch how predator and prey populations oscillate in cycles, and observe how genetic traits evolve over generations to improve survival strategies.
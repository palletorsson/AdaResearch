# Ant Colony Optimization Ecosystem

## Overview
This implementation provides a comprehensive 3D ant colony optimization (ACO) ecosystem simulation combining terrain generation, pheromone-based pathfinding, and emergent swarm behavior. The system demonstrates how simple individual ant behaviors can lead to complex collective intelligence for finding optimal paths between food sources and the colony.

## Algorithm Description
The ant colony optimization algorithm simulates the behavior of real ant colonies where individual ants leave pheromone trails that guide other ants to food sources. This creates a positive feedback loop that reinforces successful paths while unsuccessful paths fade over time.

### Key Components
1. **Procedural Terrain Generation**: Creates realistic 3D landscapes using noise functions
2. **Pheromone System**: Implements chemical trail laying, diffusion, and evaporation
3. **Ant Agents**: Individual ants with state-based behavior (foraging, returning, following trails)
4. **Food System**: Distributes and manages food sources throughout the terrain
5. **Colony Management**: Central nest location and ant spawning system

### Algorithm Flow
1. **Initialization**: Generate terrain, place colony and food sources, spawn ants
2. **Ant Behavior**: Each ant follows state-based logic:
   - **Exploring**: Random walk while searching for food
   - **Following Trails**: Use pheromone gradients to guide movement
   - **Returning**: Navigate back to colony when carrying food
3. **Pheromone Dynamics**: 
   - Ants deposit pheromones based on their state
   - Pheromones diffuse to neighboring cells
   - Natural decay prevents stagnation
4. **Path Optimization**: Successful paths are reinforced while poor paths fade

## Files Structure
- `AntColonyEcosystem.gd`: Main simulation controller
- `AntAgent.gd`: Individual ant behavior and state management
- `AntColony.gd`: Colony management and ant spawning
- `PheromoneSystem.gd`: Pheromone trail management and diffusion
- `FoodSystem.gd`: Food source placement and consumption
- `ProceduralTerrain.gd`: 3D terrain generation
- `main.gd`: Scene coordination and user interface
- `main.tscn`: Scene file

## Parameters
- **Terrain**: Size (50x50), resolution (100), height scale (5.0)
- **Colony**: Number of ants (100), speed (2.0)
- **Pheromones**: Decay rate (0.995), diffusion rate (0.1)
- **Food**: Source count (3), amount per source (100)

## Theoretical Foundation
This implementation is based on the Ant Colony System (ACS) metaheuristic, which has been successfully applied to:
- Traveling Salesman Problem (TSP)
- Vehicle routing optimization
- Network routing protocols
- Supply chain management

## Applications
- Path planning and navigation
- Network optimization
- Resource allocation
- Logistics and routing problems
- Distributed problem solving

## Visual Features
- Real-time 3D visualization of terrain and ant movement
- Pheromone trail visualization with color intensity
- Debug information showing colony statistics
- Interactive camera controls for observation

## Usage
Run the main scene to start the simulation. Observe how ants initially explore randomly but gradually develop efficient paths between the colony and food sources as pheromone trails strengthen successful routes. 
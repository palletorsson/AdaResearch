# Ant Colony Optimization V2

An organic, high-performance simulation of ant colony behavior using Pheromone Steering and GPU-based terrain visualization.

## Overview
This system simulates ants foraging for food and creating efficient paths (trails) back to their home nest. Unlike grid-based cellular automata, this implementation uses continuous **Steering Behaviors**, resulting in natural, curvy, and organic movement patterns.

The simulation also features a **Valley Path Shader**, where the pheromone trails physically displace the terrain downwards, creating visual "canyons" where the ants travel.

## Key Features
*   **Organic Movement:** Ants use a "Sensory Horizon" (Left, Center, Right) to steer towards pheromones, combined with a damped wandering force for exploration.
*   **Performance:** The underlying pheromone grid uses `PackedFloat32Array` for fast CPU processing, capable of handling large grids.
*   **Visual Feedback:** Terrain deformation shader (`ant_valley.gdshader`) visualizes trails in real-time.

## File Structure
*   `AntColonyV2.tscn`: **Main Scene**. Run this to start the simulation.
*   `AntColonyV2.gd`: Manager script. Handles grid updates, ant spawning, and food placement.
*   `PheromoneGrid.gd`: Core data structure handling pheromone values, decay, and texture generation.
*   `SimpleAnt.gd`: The agent logic. Handles sensing, steering, and boundary constraints.
*   `ant_valley.gdshader`: The terrain shader.

## How it Works
1.  **Foraging:** Ants start at the Home (Center) and wander randomly (`wander_strength`).
2.  **Discovery:** When an ant enters a Food Zone (Green), it grabs food, turns around, and switches to "Returning" mode.
3.  **Trails:**
    *   **Foraging Ants** drop "Home Pheromone" (Blue) as they search.
    *   **Returning Ants** drop "Food Pheromone" (Red) as they carry food back.
4.  **Steering:** Ants attracted to the *opposite* pheromone (Foragers look for Red, Returners look for Blue).
5.  **Optimization:** Over time, the random wander paths are optimized into direct routes as ants reinforce the shortest/strongest trails.

## Concepts & Theory
This simulation implements **Chemotaxis** (Gradient Ascent), a biological navigation method where agents move towards higher concentrations of a signal.

1.  **Static Gradients (Centers of Power):** The Home and Food areas actively emit pheromones that diffuse outwards. This creates a global "Scent Horizon" that guides ants roughly in the right direction even without established trails.
2.  **Dynamic Trails:** As ants walk, they paint local lines of high intensity.
3.  **Hybrid Navigation:** The ants combine these signals—climbing the global static gradient to find the general area, while locking onto specific dynamic trails for optimized routing.
4.  **Dissipation:** Pheromones diffuse (blur) over time. This softens sharp "pixel trails" into natural gradients, preventing "hard roads" and allowing trails to merge organically.

## Parameters
Tunable variables in `SimpleAnt.gd`:
*   `wander_strength`: Controls the chaos/exploration rate.
*   `steer_strength`: Controls how strongly they lock onto trails.
*   `sensor_dist`: How far ahead they see.

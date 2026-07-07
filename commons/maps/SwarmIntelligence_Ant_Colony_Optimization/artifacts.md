# SwarmIntelligence Ant Colony Optimization — Artifacts
*Swarm Intelligence: No Leader, Yet Coordinated · lambda_edge · 1 artifacts*

> Ants leave pheromones as they walk. Paths with more pheromone attract more ants. Paths with shorter distances get walked more often. Positive feedback loops find optimal routes through mazes. Dumb agents, smart swarm. Stigmergy: communication through environment.

The map, read through what it holds — its artifacts in the order you meet them:

## AntColonyV2
![AntColonyV2](/scene-catalog/AntColonyV2.png)

ant.move() = gradient_ascent(pheromone_grid) + wander; pheromone_grid *= decay + diffuse — ant and environment co-evolve

`AntColonyV2`

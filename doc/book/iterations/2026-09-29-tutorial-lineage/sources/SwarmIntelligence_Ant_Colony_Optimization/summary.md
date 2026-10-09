# SwarmIntelligence_Ant_Colony_Optimization — Summary

Ants leave pheromones as they walk. Paths with more pheromone attract more ants. Shorter paths get walked more often and accumulate pheromone faster. Positive feedback loops converge on near-optimal routes through branching corridor networks. No ant knows the shortest path. The pheromone gradient knows.

The `AntColony` artifact implements Dorigo's 1992 algorithm: artificial ants traverse a graph where corridors are edges and junctions are nodes. Edge selection probability is a function of pheromone intensity (alpha weighting) and heuristic desirability (beta weighting, based on inverse distance). Pheromone evaporation rate rho prevents premature convergence — without evaporation, the first good path dominates forever. With it, the colony forgets and rediscovers, maintaining exploration alongside exploitation.

Thirty ants start from the nest node. Each builds a complete path by choosing edges probabilistically at every junction, constrained by a visited set that prevents cycles. After completing a tour, each ant deposits pheromone proportional to inverse path length — shorter tours deposit more. The pheromone landscape differentiates from uniform initial conditions through hundreds of iterations. The colony solves the traveling salesman problem (NP-hard in general form) within a few percent of optimal, through purely local probabilistic decisions.

The Y-shaped branching corridor layout makes the algorithm spatially legible — pheromone brightens on favored edges, fades on neglected ones, and the learner watches the colony's consensus emerge and shift. This is the fifth map in the Swarm Intelligence sequence, pairing with the next map (PSO) as stigmergic optimization versus social optimization.

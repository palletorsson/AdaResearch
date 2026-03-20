# SwarmIntelligence_Particle_Swarm_Optimization — Summary

Each particle remembers its best position. All particles know the global best. From this dual memory, a population navigates a fitness landscape toward optima without gradients. The velocity update equation — `v = w*v + c1*r1*(personal_best - x) + c2*r2*(global_best - x)` — balances three forces: inertia (keep moving), cognitive pull (trust your own experience), and social pull (trust the swarm's best find).

The `PSOVisualization` artifact renders a fitness landscape as terrain — Rastrigin or Ackley test functions with many local minima and one global minimum at the valley floor. Fifty particles scatter across the landscape, evaluate fitness, update personal and global bests, and adjust velocity each frame. The observation deck provides a bird's-eye view of convergence: initial scatter, rapid approach to the first good region, then tightening spirals as inertia weight decays from exploration to exploitation.

PSO inverts ACO's architecture. Where ants stored memory in the environment (pheromone on edges) and the agents were stateless, PSO stores memory in the agents (personal best, global best) and the environment is passive. The fitness landscape is read but never written. Coordination is social rather than stigmergic — particles learn from each other's evaluations, not from environmental traces.

The map's concentric height rings descending to a central valley mirror the fitness landscape's topology. This is the sixth map in the Swarm Intelligence sequence, pairing with ACO as two complementary models of collective optimization. The teleporter leads to the final gallery map where all swarm algorithms stand side by side.

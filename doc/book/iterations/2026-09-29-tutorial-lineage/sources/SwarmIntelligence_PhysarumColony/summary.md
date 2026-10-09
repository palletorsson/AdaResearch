# SwarmIntelligence_PhysarumColony — Summary

Slime mold builds networks. Physarum polycephalum — a single-celled organism with no brain and no neurons — solves mazes, recreates the Tokyo rail network, and finds shortest paths through sheer material computation. The organism spreads, explores, finds food, then optimizes: reinforcing tubes where flow is high, withdrawing from tubes where flow drops. Intelligence without centralization.

The `PhysarumColony` artifact simulates this process. Five thousand virtual agents deposit chemical trail on a 256x256 grid, sense trail concentration at three forward-offset sensors, and turn toward higher concentration. Trail diffuses via a 3x3 box blur and decays each frame. Active paths maintain concentration through continuous reinforcement. Abandoned paths fade. The emergent network approximates a Steiner tree — the minimum-cost structure connecting food sources — achieved through purely local operations. No agent knows the food sources exist. Each follows its nose.

Six parameters shape the network: sensor angle (field of view), sensor offset (planning horizon), turn angle (responsiveness), deposit rate (coupling strength), decay rate (memory), and diffusion kernel (communication range). Below a critical deposit rate, no network forms. Above it, networks snap into existence — a phase transition in an information-processing system.

This is the first map in the Swarm Intelligence sequence, establishing the thesis that will run through all seven maps: no leader, yet coordinated. The environment is the message. The organic cave layout with void nutrient pools mirrors the biological substrate. The teleporter leads to SwarmIntelligence_FlowFields, where the principle generalizes into vector field mathematics.

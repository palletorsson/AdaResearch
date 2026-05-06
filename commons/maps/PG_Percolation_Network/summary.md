# PG Percolation Network — Summary

PG_Percolation_Network is the third map in the Procedural Generation sequence. It demonstrates percolation — the phase transition at which a random grid suddenly becomes connected from one side to the other. A large grid covers the floor; each cell fills with a probability set by a slider at the entrance.

At low probabilities, the grid is sparse. Occupied cells scatter in small clusters that touch no edge of the arena. Raising the probability thickens the clusters; they grow, merge, and eventually one of them spans the grid. The threshold at which that spanning event becomes likely — about 59.27 percent for a 2D square lattice — is marked on the slider, and crossing it produces a clear visual switch from disconnected islands to a continuous path.

A highlight mode colours the spanning cluster so the connected path is easy to follow. A side panel reports the largest-cluster size as a function of the fill probability, so the phase transition is legible as a curve as well as a visual effect.

Within the sequence, Percolation is the connectivity chapter. The previous two maps generated structure by growth; this one generates structure by threshold. PG_Branching_Growth will next put two growth paradigms side by side.

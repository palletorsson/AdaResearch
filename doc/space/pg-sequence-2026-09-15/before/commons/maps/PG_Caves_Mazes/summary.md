# PG Caves Mazes — Summary

PG_Caves_Mazes is the fifth map in the Procedural Generation sequence. It turns to subtractive generation — carving navigable interiors out of solid mass — and stages two strategies on either side of a central wall.

The left side carves a cave. A random walker starts at a single point and staggers through the block, removing cells as it moves. Each step is independent; the walker has no plan. Over time, the removed cells form a meandering passage with uneven widths and occasional dead ends. The cave feels natural because it was not designed; it was eroded.

The right side builds a maze. A deterministic algorithm partitions the block into a grid, selects a spanning tree over that grid, and opens the cells connected by tree edges while leaving the rest as walls. The result is a corridor network that always has exactly one path between any two points, because a spanning tree is acyclic. The maze feels engineered because it was.

Sliders on each side expose the parameters: walk length and step size on the cave side, grid resolution and branch bias on the maze side. A comparison panel between the two sides notes the shared feature — both produce navigable voids in solid mass — and the divergent character that the choice of algorithm enforces.

Within the sequence, Caves_Mazes is the subtractive chapter. PG_Sculpted_Forms will next return to additive strategies by stacking rather than branching.

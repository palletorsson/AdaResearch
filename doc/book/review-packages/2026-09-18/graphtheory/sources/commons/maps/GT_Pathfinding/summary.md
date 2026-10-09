# GT Pathfinding — Summary

GT_Pathfinding is the third map in the Graph Theory sequence. It builds a maze and asks the learner to become the search algorithm. The corridors are edges, the junctions are nodes, and the dead ends are branches that promised a route and did not deliver.

The learner walks the maze to find the exit. A trail is drawn behind them so the path taken is visible as it is built. When a dead end is reached, the trail records the backtrack. The resulting record is a depth-first search traced by a body rather than by a queue.

Three alternate mode panels sit along the route. Activating one switches the maze to a breadth-first visualisation, in which every corridor at the current radius is highlighted before the search advances another step. Another activates A* mode, which overlays a heuristic distance to the exit on every junction and picks the lowest-cost next step. A third returns the maze to bare walls, so the learner can compare the felt experience of searching with the three algorithms superimposed.

A small readout tracks steps taken, walls touched, and path length for each mode. Within the sequence, Pathfinding is where graph traversal becomes embodied. GT_Network_Analysis will next ask not how to move through a graph but how to read it.

# GT Connectivity — Summary

GT_Connectivity is the fifth map in the Graph Theory sequence. It introduces directed graphs and the asymmetric reachability that follows from directing edges. Three rooms sit in a row, and the connections between them are one-way rather than bidirectional.

Within each room, the learner can move freely between nodes — a corridor leads from any node to any other. The rooms correspond to strongly connected components: maximal subsets of the graph in which every node can reach every other. Between rooms, the doors are one-way. The learner can walk from Room A to Room B, but the return path is blocked. From Room B, another one-way door leads to Room C. Moving between rooms traces the structure of the directed graph.

A visualisation on one wall shows the whole graph with its three components circled and the direction of each inter-component edge marked with an arrow. A toggle runs Tarjan's algorithm live, highlighting nodes in the order they are visited and identifying each component as it is completed. A second toggle runs Kosaraju's algorithm as a different route to the same classification.

The components collapse to a directed acyclic graph, which the map displays and topologically sorts on a side panel. Within the sequence, Connectivity is where direction becomes load-bearing. GT_Spanning_Trees will next ask how to cover a graph most cheaply.

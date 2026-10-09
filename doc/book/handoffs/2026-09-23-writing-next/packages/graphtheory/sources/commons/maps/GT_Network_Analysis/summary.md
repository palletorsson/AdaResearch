# GT Network Analysis — Summary

GT_Network_Analysis is the fourth map in the Graph Theory sequence. It asks a different kind of question than the earlier maps: which node in a graph matters most, and by what measure? Several notions of centrality produce different answers on the same graph, and the map lays them out side by side.

The space is built as a hub-and-spoke network. A central platform sits at the middle of the room, with many edges radiating outward to peripheral nodes. The centrality of the central platform depends on which metric the learner selects. Degree centrality, the count of direct edges, favours it unambiguously. Betweenness centrality, the count of shortest paths that pass through a node, favours it as well, but also lifts any peripheral bridge that sits on a major route. Eigenvector centrality, which rewards nodes connected to other well-connected nodes, redistributes importance toward clusters.

A fourth station runs a network-flow demonstration. Pipes replace edges; a source floods the network with capacity-bounded flow; and the network's throughput becomes a different form of importance — structural rather than topological. A panel at each station names the metric and shows its formula.

Within the sequence, Network_Analysis is the measurement chapter. GT_Connectivity will next introduce directed edges and the asymmetries they produce.

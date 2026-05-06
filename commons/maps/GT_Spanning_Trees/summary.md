# GT Spanning Trees — Summary

GT_Spanning_Trees is the sixth map in the Graph Theory sequence. It asks for the cheapest way to connect every node once and for all: strip every cycle, keep every vertex reachable, minimise total edge weight. The answer is a minimum spanning tree.

The space is a scattered collection of platforms at different heights. Edges are drawn between platforms, and each edge's length is its weight; the longer a connection, the more it costs. The learner's task is to pick a subset of edges that forms a spanning tree — connected and acyclic — at the lowest possible total weight.

Two stations run the canonical algorithms. Kruskal's algorithm sorts all edges by weight and adds them greedily, skipping any edge that would form a cycle with those already chosen. Prim's algorithm starts from a root node and grows the tree outward, always adding the lightest edge that connects a new node. Each station animates its algorithm step by step and ends on the same tree, because for a graph with distinct weights the minimum spanning tree is unique.

A display at the centre of the room tracks the running total cost of each algorithm's tree as it is built. Within the sequence, Spanning_Trees is the optimisation chapter on structure. GT_Flow will next ask the optimisation question on throughput.

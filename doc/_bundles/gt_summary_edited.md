<<<ADA_BUNDLE>>>
sequence: graphtheory
file: summary.md
maps: 8
skipped_passing: 0
created: 2026-04-23T19:19:51
only_failing: false
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: GT_Foundations>>>
# GT Foundations — Summary

GT_Foundations opens the Graph Theory sequence by re-enacting the problem that started the field. The Königsberg of 1736 sits at the centre of the space as a small model: four land masses, seven bridges, one question — can you cross every bridge exactly once without repeating any? Euler said no, and proved it by ignoring everything except the pattern of connection.

The learner can walk the physical model, which will not work. Then the model collapses. The islands compress to four nodes; the bridges become seven edges; the river falls away. What remains is a graph in the abstract sense: a set of vertices and a set of edges joining some of them. Euler's argument becomes visible: a walk that uses every edge exactly once exists only when at most two vertices have odd degree, and Königsberg has four.

Around this centrepiece, the map stages the foundational vocabulary. A small graphspace artifact lets the learner drag nodes and edges around; a degree readout updates live. A side demonstration shows directed graphs, weighted edges, and simple and multi-graphs. The lesson is not the taxonomy but the move behind it — graph theory begins where geometry is forgotten.

Within the sequence, Foundations sets the language. GT_Layout will next ask how a graph presents itself in space.

<<<MAP: GT_Layout>>>
# GT Layout — Summary

GT_Layout is the second map in the Graph Theory sequence. It treats the visual arrangement of a graph as a physics problem. Nodes repel each other like charges; edges pull their endpoints together like springs; the whole graph is left to settle.

The room itself is the demonstration. A large graph is scattered across the floor and into the air, with nodes at different heights and edges running between them. A timer button starts the simulation: Coulomb repulsion pushes every node away from every other, Hooke attraction pulls connected nodes together, and after a short time the graph settles into a stable arrangement in which the two forces balance.

A controls bench adjusts the parameters. Repulsion strength spreads the graph wider or tightens it inward. Spring constant pulls connected nodes harder or lets them drift. A re-seed button randomises the starting positions so the learner can run the same graph repeatedly and see that the final layout is not unique — initial conditions shape which stable configuration the physics finds.

A second display shows the graph as an adjacency matrix alongside the spatial view, so the structural information stays separate from its visual realisation. Within the sequence, Layout borrows the force vocabulary from the Forces sequence and applies it to the problem of making a graph legible. GT_Pathfinding will next put the learner's body into the graph.

<<<MAP: GT_Pathfinding>>>
# GT Pathfinding — Summary

GT_Pathfinding is the third map in the Graph Theory sequence. It builds a maze and asks the learner to become the search algorithm. The corridors are edges, the junctions are nodes, and the dead ends are branches that promised a route and did not deliver.

The learner walks the maze to find the exit. A trail is drawn behind them so the path taken is visible as it is built. When a dead end is reached, the trail records the backtrack. The resulting record is a depth-first search traced by a body rather than by a queue.

Three alternate mode panels sit along the route. Activating one switches the maze to a breadth-first visualisation, in which every corridor at the current radius is highlighted before the search advances another step. Another activates A* mode, which overlays a heuristic distance to the exit on every junction and picks the lowest-cost next step. A third returns the maze to bare walls, so the learner can compare the felt experience of searching with the three algorithms superimposed.

A small readout tracks steps taken, walls touched, and path length for each mode. Within the sequence, Pathfinding is where graph traversal becomes embodied. GT_Network_Analysis will next ask not how to move through a graph but how to read it.

<<<MAP: GT_Network_Analysis>>>
# GT Network Analysis — Summary

GT_Network_Analysis is the fourth map in the Graph Theory sequence. It asks a different kind of question than the earlier maps: which node in a graph matters most, and by what measure? Several notions of centrality produce different answers on the same graph, and the map lays them out side by side.

The space is built as a hub-and-spoke network. A central platform sits at the middle of the room, with many edges radiating outward to peripheral nodes. The centrality of the central platform depends on which metric the learner selects. Degree centrality, the count of direct edges, favours it unambiguously. Betweenness centrality, the count of shortest paths that pass through a node, favours it as well, but also lifts any peripheral bridge that sits on a major route. Eigenvector centrality, which rewards nodes connected to other well-connected nodes, redistributes importance toward clusters.

A fourth station runs a network-flow demonstration. Pipes replace edges; a source floods the network with capacity-bounded flow; and the network's throughput becomes a different form of importance — structural rather than topological. A panel at each station names the metric and shows its formula.

Within the sequence, Network_Analysis is the measurement chapter. GT_Connectivity will next introduce directed edges and the asymmetries they produce.

<<<MAP: GT_Connectivity>>>
# GT Connectivity — Summary

GT_Connectivity is the fifth map in the Graph Theory sequence. It introduces directed graphs and the asymmetric reachability that follows from directing edges. Three rooms sit in a row, and the connections between them are one-way rather than bidirectional.

Within each room, the learner can move freely between nodes — a corridor leads from any node to any other. The rooms correspond to strongly connected components: maximal subsets of the graph in which every node can reach every other. Between rooms, the doors are one-way. The learner can walk from Room A to Room B, but the return path is blocked. From Room B, another one-way door leads to Room C. Moving between rooms traces the structure of the directed graph.

A visualisation on one wall shows the whole graph with its three components circled and the direction of each inter-component edge marked with an arrow. A toggle runs Tarjan's algorithm live, highlighting nodes in the order they are visited and identifying each component as it is completed. A second toggle runs Kosaraju's algorithm as a different route to the same classification.

The components collapse to a directed acyclic graph, which the map displays and topologically sorts on a side panel. Within the sequence, Connectivity is where direction becomes load-bearing. GT_Spanning_Trees will next ask how to cover a graph most cheaply.

<<<MAP: GT_Spanning_Trees>>>
# GT Spanning Trees — Summary

GT_Spanning_Trees is the sixth map in the Graph Theory sequence. It asks for the cheapest way to connect every node once and for all: strip every cycle, keep every vertex reachable, minimise total edge weight. The answer is a minimum spanning tree.

The space is a scattered collection of platforms at different heights. Edges are drawn between platforms, and each edge's length is its weight; the longer a connection, the more it costs. The learner's task is to pick a subset of edges that forms a spanning tree — connected and acyclic — at the lowest possible total weight.

Two stations run the canonical algorithms. Kruskal's algorithm sorts all edges by weight and adds them greedily, skipping any edge that would form a cycle with those already chosen. Prim's algorithm starts from a root node and grows the tree outward, always adding the lightest edge that connects a new node. Each station animates its algorithm step by step and ends on the same tree, because for a graph with distinct weights the minimum spanning tree is unique.

A display at the centre of the room tracks the running total cost of each algorithm's tree as it is built. Within the sequence, Spanning_Trees is the optimisation chapter on structure. GT_Flow will next ask the optimisation question on throughput.

<<<MAP: GT_Flow>>>
# GT Flow — Summary

GT_Flow is the seventh map in the Graph Theory sequence. It introduces capacity as a first-class property of edges and asks how much can pass from a source to a sink before the network saturates. The answer lives in the narrowest passage the graph contains.

The room is shaped as a funnel. A wide entrance holds many incoming pipes; a narrow exit at the far end holds few. Between them, a network of intermediate pipes with different capacities routes the flow. The learner walks the funnel and feels the constraint: the exit is tight, and whatever the network's internal capacity, the total throughput cannot exceed it.

A live simulation pushes flow from source to sink. Pipes fill until they saturate; saturated pipes glow and cap their throughput at their capacity. A running total above the sink reports the current flow. The algorithm is selectable — the map runs push-relabel or Ford-Fulkerson on demand, and both converge to the same answer.

The max-flow value is compared to a min-cut display on the side wall. The cut is drawn as a coloured line across the network separating source from sink; its total capacity equals the flow rate. The identity that max-flow equals min-cut becomes visible rather than memorised. Within the sequence, Flow is the throughput chapter. GT_Matching will next bring the sequence to its close.

<<<MAP: GT_Matching>>>
# GT Matching — Summary

GT_Matching is the eighth and final map in the Graph Theory sequence, and the last map in the whole spine. The task is pairing: each node claimed by at most one edge, each pair an exclusive assignment. A perfect matching claims every node; an optimal matching minimises cost under some weighting.

The room is divided into two symmetric halves. The learner stands on a walkway between them. On each side, a set of nodes waits to be paired with a partner on the other side. A greedy algorithm runs first and fails visibly: it commits to easy pairs early and strands some nodes unmatched. A second station runs the Hungarian algorithm for the bipartite case, lifts the blockage, and produces a complete assignment.

A third station takes the problem to general graphs, where pairs can form across arbitrary edges. The blossom algorithm contracts odd cycles into pseudo-nodes, finds augmenting paths through the contracted graph, and expands the contractions back out when the matching is complete. The algorithm animates the contractions and re-expansions; the room's two halves visibly bend as blossoms form.

Within the sequence, Matching is the capstone. Within the whole spine, it is the last thing the learner encounters before the curriculum hands back to the Lab. The argument is that allocation — fair, exclusive, complete — is a graph problem, and the tools the sequence has built are enough to solve it.

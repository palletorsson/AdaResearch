A directed graph splits into pieces — not by cutting, but by asking: from here, can I reach there *and* come back? A strongly connected component is a maximal set of nodes where every pair answers yes. Mutual reachability. Full reciprocity within the group.

Tarjan finds them in a single pass. One depth-first search, a stack, a lowlink counter — the algorithm discovers components as it retreats, identifying the root of each cluster the moment it finishes exploring. Kosaraju takes two passes: traverse the graph, reverse every edge, traverse again. What survives the reversal was strongly connected all along. Two methods, same truth.

Topological sort orders what remains — the DAG of components, stripped of cycles, laid flat.

Three rooms. Three components. The passages between them run one way. Connection without reciprocity is just direction. Structure is what survives when you flip every arrow.
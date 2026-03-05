A strongly connected component is a maximal subgraph where every node can reach every other node. Mutual reachability. Complete entanglement within a boundary.

Kosaraju finds them in two passes. First: run DFS on the original graph, recording finish order. Second: transpose the graph — reverse every edge — then run DFS again in reverse finish order. Each tree in the second pass is one component. Two traversals, one reversal. The transpose doesn't destroy structure; it reveals it. Only mutual connections survive the inversion.

The algorithm asks a question that adjacency alone cannot answer: not "can I reach you?" but "can you also reach me?" Direction matters. Reciprocity is the test. What remains after every relationship is reversed is what was real.
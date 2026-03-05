# Edmonds' Algorithm

A matching pairs vertices — each vertex claimed by at most one edge. The maximum matching claims as many as possible. Greedy approaches fail. Augmenting paths help, but only in bipartite graphs. General graphs contain odd cycles, and odd cycles break everything.

Jack Edmonds saw the problem in 1965. An odd cycle looks like a trap — three vertices, five vertices, seven — where augmenting paths enter and cannot exit correctly. His solution: collapse the entire cycle into a single pseudo-vertex. A blossom. Contract it, search the simplified graph, expand it back. The blossom remembers what it consumed.

Contraction is the operation that makes matching possible. Shrink the obstruction until it becomes a point. Solve the reduced problem. Unfold. The algorithm succeeds precisely because it refuses to treat the odd cycle as an error — it treats it as a structure that can be temporarily compressed and later restored. Identity folded into itself, then released.
Stepped platforms at heights that follow no obvious pattern — until you see it in binary. The first platform covers one cell. The second covers two. The fourth covers four. Responsibilities assigned by the lowest set bit.

A Fenwick tree computes prefix sums. Each node is responsible for a range determined by its index in binary: the lowest set bit tells you how many elements that node aggregates. Index 6 (binary 110) covers 2 elements. Index 8 (binary 1000) covers 8. Update cascades upward by adding the lowest set bit. Query cascades downward by subtracting it. Both operations: log-n.

The trick is that binary arithmetic already encodes a tree structure. No pointers, no child references — just an array whose indices, read in binary, reveal the hierarchy. The storage is flat. The structure is implicit. Binary arithmetic as architecture.

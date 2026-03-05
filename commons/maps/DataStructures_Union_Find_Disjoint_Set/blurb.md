# Union-Find Clusters

Two elements. Same set or different? Union-Find answers the only question that matters — who belongs together. The structure tracks partitions. `find` returns a representative. `union` merges two groups into one. Path compression flattens the tree on every query, rewriting history so future lookups cost almost nothing. Union by rank keeps the structure shallow. Together, these tricks reduce amortized cost to the inverse Ackermann function — effectively constant, but not quite. A bound so slow-growing it never exceeds 4 for any input that fits in the observable universe.

Distinct platforms float across a 10×10 grid. Each cluster is a disjoint set — self-contained, internally connected, separated by void. Walk between platforms and the gap closes. Two territories become one. The operation is irreversible. Union-Find only merges. It never splits.

Every `union` destroys a boundary. Every `find` erases the path that led to the answer. The structure optimizes by forgetting — collapsing elaborate hierarchies into flat references, trading structural memory for speed. Identity reduces to a single pointer. Who you are is who you point to.
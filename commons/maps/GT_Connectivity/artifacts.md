# GT Connectivity — Artifacts
*Graph Theory: Connections Define Structure · relation · 3 artifacts*

> A directed graph splits into pieces — not by cutting, but by asking: from here, can I reach there *and* come back? A strongly connected component is a maximal set of nodes where every pair answers yes. Mutual reachability. Full reciprocity within the group.

The map, read through what it holds — its artifacts in the order you meet them:

## Tarjan's Algorithm
![Tarjan's Algorithm](/scene-catalog/tarjan_algorithm.png)

TRACE low-link propagation and see where directed cycles collapse into strongly connected components.

`tarjan_algorithm`

## Kosaraju's Algorithm
![Kosaraju's Algorithm](/scene-catalog/kosaraju_algorithm.png)

FOLLOW the two DFS passes and explain why SCCs survive graph transposition.

`kosaraju_algorithm`

## Topological Sort
![Topological Sort](/scene-catalog/topological_sort.png)

Topological sort — linear ordering of vertices in a directed acyclic graph

`topological_sort`

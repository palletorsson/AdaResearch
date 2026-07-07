# GT Matching — Artifacts
*Graph Theory: Connections Define Structure · relation · 1 artifacts*

> A matching pairs nodes — each node claimed by at most one edge. A perfect matching claims every node. No leftovers, no loose ends. The problem sounds simple: pair things optimally. But in general graphs, with odd cycles and tangled structure, greedy approaches fail. Edmonds solved it in 1965 with a move no one expected — he shrank odd cycles into single nodes, matched the reduced graph, then expanded them back. Blossoms. The algorithm treats obstruction as compression.

The map, read through what it holds — its artifacts in the order you meet them:

## Edmonds' Algorithm
![Edmonds' Algorithm](/scene-catalog/edmonds_algorithm.png)

EVALUATE how graph structure enables or blocks pairings and why greedy matching can fall short of the optimum.

`edmonds_algorithm`

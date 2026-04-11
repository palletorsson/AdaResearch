# Grid3D Cartridges

Algorithm cartridges for the Grid3D substrate. Each extends `Grid3DCartridge` and implements `initialize()`, `step()`, `get_node_color()`, and `get_node_emission()` to drive a 3D graph visualization with sphere nodes and cylinder edges.

## How It Works

A cartridge generates a random graph (positions, edges, weights) during `initialize()` and then steps through a graph algorithm. Each step returns updated node states, edge states, and optional highlight colors. The renderer maps states to colors for both nodes and edges, with emission conveying algorithmic activity.

## Files

- `cartridge_bfs_graph.gd` -- Breadth-first search. Wavefront expansion from a source node. Cyan frontier, green visited.
- `cartridge_dfs_graph.gd` -- Depth-first search. Stack-based exploration with backtracking. Orange active stack, green finished.
- `cartridge_dijkstra.gd` -- Dijkstra's shortest path. Greedy expansion by distance. Cyan frontier, green settled, magenta source.
- `cartridge_kruskal_mst.gd` -- Kruskal's minimum spanning tree. Sorted edge selection with union-find.
- `cartridge_prim_mst.gd` -- Prim's minimum spanning tree. Greedy growth from a source node.
- `cartridge_random_graph.gd` -- Random graph generator. Displays a static random graph with no algorithm progression.
- `cartridge_force_directed.gd` -- Force-directed layout. Nodes repel, edges attract, settling into an organic arrangement.
- `cartridge_entropy_field.gd` -- Entropy field visualization. Node colors encode local entropy of the graph neighborhood.

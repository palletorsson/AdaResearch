# Graph Weaver

Network creature with 8 sphere nodes connected by edges — reconfigures its graph to hunt via BFS shortest path.

## Behavior

Extends `HazardCreatureBase`. 80 HP. Teaches graph theory, spanning trees, and BFS traversal.

- 8 colored nodes arranged in a circle (radius 0.5)
- Starts with a random spanning tree
- During CHASE: reconfigures edges to form shortest path toward player
- BFS traversal wave animates along the active path
- Can fire edge projectiles
- Orbit speed 0.15, reconfigure interval 4.0s

## Files

| File | Purpose |
|------|---------|
| `graph_weaver.gd` | Main script — graph construction, BFS, edge projectiles |
| `graph_weaver.tscn` | Scene |

## Visual

- Node spheres with per-node coloring
- Gray edges for inactive connections, red for active chase path
- Traversal wave animation highlights nodes in BFS order

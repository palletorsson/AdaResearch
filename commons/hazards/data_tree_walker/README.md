# Data Tree Walker

Walking binary search tree — sphere nodes connected by cylinder edges, with visible AVL rotations on damage.

## Behavior

Extends `HazardCreatureBase`. Teaches tree data structures and rebalancing.

- Starts as a balanced BST with values 1–7 (max depth 3)
- Walks on leaf nodes
- Taking damage triggers visible AVL rotation animations
- Node radius 0.06, edge radius 0.015, level height 0.2

## Files

| File | Purpose |
|------|---------|
| `data_tree_walker.gd` | Main script — BST construction, AVL rotation, walking |
| `data_tree_walker.tscn` | Scene |

## Visual

- Root node: gold sphere
- Regular nodes: blue spheres
- Edges: gray cylinders
- "BST" label at top of tree

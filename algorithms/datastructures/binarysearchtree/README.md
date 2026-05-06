# Binary Search Tree

Interactive 3D visualization of a binary search tree — watch insertions, deletions, and traversals animate through the structure.

## QFEP Connection

The BST is **structured ordering** — every node maintains the invariant: left children smaller, right children larger. This is pure F (order, predictability). But the tree's shape depends on insertion order — same values, different sequences produce different structures. The gap between O(log n) and O(n) is the price of disorder.

## How It Works

```
        [50]
       /    \
    [30]    [70]
    /  \    /  \
  [20][40][60][80]
```

BST property:
- All values in left subtree < node value
- All values in right subtree > node value
- Applies recursively

### Operations

| Operation | Process |
|-----------|---------|
| **Insert** | Compare with root, go left if smaller, right if larger, repeat until leaf |
| **Search** | Same path as insert, return when found |
| **Delete** | Find node, replace with successor or predecessor |
| **Traverse** | In-order (sorted), pre-order (root first), post-order (root last) |

## Parameters

### Tree
| Export | Default | Description |
|--------|---------|-------------|
| `auto_insert_values` | true | Insert on load |
| `initial_values` | [50,30,70,20,40,60,80] | Starting values |
| `insertion_speed` | 1.0 | Seconds per operation |
| `show_traversal` | true | Animate tree walks |

### Visual
| Export | Default | Description |
|--------|---------|-------------|
| `node_radius` | 0.5 | Node sphere size |
| `level_spacing` | 3.0 | Vertical gap between levels |
| `horizontal_spacing` | 2.0 | Horizontal spread |
| `show_connections` | true | Draw edge lines |

## Color Coding

| Color | Meaning |
|-------|---------|
| Blue-gray | Default node state |
| Yellow | Currently highlighted/selected |
| Green | Being inserted |
| Red | Being deleted |

## Files

| File | Purpose |
|------|---------|
| `bst_visualization.tscn` | Scene |
| `bst_visualization.gd` | Tree logic and animation |

## Usage

```gdscript
var bst = preload("res://algorithms/datastructures/binarysearchtree/bst_visualization.tscn").instantiate()
bst.initial_values = [100, 50, 150, 25, 75, 125, 175]
bst.insertion_speed = 0.5  # Faster animations
add_child(bst)
```

## Complexity

| Operation | Average | Worst (unbalanced) |
|-----------|---------|-------------------|
| Search | O(log n) | O(n) |
| Insert | O(log n) | O(n) |
| Delete | O(log n) | O(n) |

Worst case occurs when values arrive sorted — tree degenerates to a linked list.

## Educational Value

BSTs teach:
- **Recursive structures**: Subtrees are BSTs themselves
- **Ordering invariants**: Local rules → global order
- **Trade-offs**: Structure vs flexibility
- **Balance matters**: Self-balancing variants (AVL, Red-Black) fix worst case

## VR Experience

Watch values flow down through the tree during insertion, highlighting nodes as they're compared. The spatial layout makes the hierarchical structure tangible. Try mentally predicting which path a new value will take.

## See Also

- `datastructures/` — Other structure visualizations
- `graphtheory/` — General graph algorithms
- `searchpathfinding/` — Search algorithms

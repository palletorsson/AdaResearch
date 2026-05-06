# Cellular Automata 3D Tree

Tree growth simulation using 3D cellular automata rules — organic branching patterns from local pruning decisions.

## QFEP Connection

Real trees don't follow blueprints — they **grow and prune based on local conditions**. This CA models that: cells activate based on neighbors, then probabilistically prune. The `edge_pruning_chance` and `isolation_pruning_chance` parameters control how aggressive the F-constraints are. Higher pruning = more structured trees; lower = bushier growth (E).

## How It Works

```
Level 0:    ▣▣
            ▣▣

Level 1:   ▣▣▣▣
           ▣  ▣
           ▣  ▣
           ▣▣▣▣

Level 2:  (expands + prunes)
           ▣▣▣▣▣▣
           ▣    ▣
           ▣ ▣▣ ▣
           ▣ ▣▣ ▣
           ▣    ▣
           ▣▣▣▣▣▣
```

Growth rules:
1. Each level, cells expand to neighbors
2. Edge cells have pruning chance
3. Isolated cells have higher pruning chance
4. Random pruning adds natural variation

## Parameters

### Tree Settings
| Export | Default | Description |
|--------|---------|-------------|
| `base_size` | 4 | Starting trunk size |
| `max_height` | 20 | Maximum levels |
| `generation_interval` | 0.1 | Seconds per level |
| `auto_play` | true | Grow automatically |
| `gradient` | — | Color by height |

### Pruning Rules
| Export | Default | Description |
|--------|---------|-------------|
| `edge_pruning_chance` | 0.4 | Outer cell death rate |
| `isolation_pruning_chance` | 0.5 | Lonely cell death rate |
| `random_pruning_base` | 0.1 | General death rate |

## Files

| File | Purpose |
|------|---------|
| `cellular_automata_3d_tree.gd` | Growth simulation |
| `*.tscn` | Scene setup |

## Usage

```gdscript
var tree = preload("res://algorithms/cellularautomata/cellular_automata_3d_tree/ca_tree.tscn").instantiate()
tree.edge_pruning_chance = 0.6  # More aggressive pruning
tree.max_height = 30  # Taller tree
add_child(tree)
```

## Growth Algorithm

```gdscript
for each cell at current level:
    expand to empty neighbors above
    
for each new cell:
    if on edge and random() < edge_pruning_chance:
        prune
    if isolated and random() < isolation_pruning_chance:
        prune
    if random() < random_pruning_base:
        prune
```

## VR Experience

Watch the tree grow level by level. Voxels appear, then some disappear as pruning takes effect. The gradient colors height — roots are one color, crown another. Different pruning parameters produce different tree shapes: low pruning = dense bushes; high pruning = sparse, elegant trees.

## Biological Inspiration

Real tree growth involves:
- **Apical dominance**: Central trunk suppresses side branches
- **Light competition**: Shaded branches die
- **Resource limitation**: Can't support infinite branches

The probabilistic pruning approximates these effects without modeling them directly.

## See Also

- `lsystems/` — Rule-based tree generation
- `cellularautomata/` — Other CA simulations
- `emergentsystems/` — Growth patterns

# Wave Function Collapse — Technical

## Core Algorithm

```gdscript
# WFC Algorithm Pseudocode
func wave_function_collapse():
    # 1. Initialize: all cells can be any tile
    for cell in grid:
        cell.possible_states = all_tiles.duplicate()
        cell.entropy = all_tiles.size()
    
    # 2. Main loop
    while not all_collapsed():
        # Find cell with minimum entropy (most constrained)
        var cell = find_min_entropy_cell()
        
        if cell.entropy == 0:
            # Contradiction! Backtrack or restart
            handle_contradiction()
            continue
        
        # Collapse: pick random state from possibilities
        var chosen = cell.possible_states.pick_random()
        cell.collapse(chosen)
        
        # Propagate constraints to neighbors
        propagate(cell)

func propagate(cell):
    var stack = [cell]
    while not stack.is_empty():
        var current = stack.pop_back()
        for neighbor in current.get_neighbors():
            # Remove states incompatible with current
            var changed = neighbor.constrain(current.state)
            if changed:
                stack.append(neighbor)
```

## Adjacency Rules

```gdscript
# Define which tiles can be adjacent
var adjacency_rules = {
    "floor": {
        "north": ["floor", "wall_south"],
        "south": ["floor", "wall_north"],
        "east": ["floor", "wall_west"],
        "west": ["floor", "wall_east"]
    },
    "wall_north": {
        "north": ["empty"],
        "south": ["floor"],
        # ...
    }
}

func can_be_adjacent(tile_a, tile_b, direction) -> bool:
    return tile_b in adjacency_rules[tile_a][direction]
```

## Entropy Calculation

```gdscript
func calculate_entropy(cell) -> float:
    # Shannon entropy for weighted selection
    var sum = 0.0
    for state in cell.possible_states:
        var weight = state.weight
        sum += weight * log(weight)
    return -sum

# Or simple count for unweighted
func simple_entropy(cell) -> int:
    return cell.possible_states.size()
```

## 3D Extension

```gdscript
# 3D WFC adds two more directions
var directions_3d = [
    Vector3i(1, 0, 0),   # east
    Vector3i(-1, 0, 0),  # west
    Vector3i(0, 1, 0),   # up
    Vector3i(0, -1, 0),  # down
    Vector3i(0, 0, 1),   # north
    Vector3i(0, 0, -1)   # south
]
```

## Performance Tips

1. **Use bitmasks** for possible states (fast set operations)
2. **Priority queue** for entropy selection
3. **Lazy propagation** — only update when needed
4. **Chunked generation** for infinite worlds

# CA Beyond Binary

Totalistic rules. Hex grids. Multi-state cells.

Totalistic rule (counts only).

```gdscript
func totalistic_rule(self_state: int, neighbour_sum: int, rule_table: Array) -> int:
    var index: int = self_state * (MAX_NEIGHBOURS + 1) + neighbour_sum
    return rule_table[index] if index < rule_table.size() else 0
```

The rule depends on the sum of neighbour states, not their arrangement. Table size: (states) × (max_sum + 1).

Generate a random totalistic rule.

```gdscript
func random_totalistic_rule(states: int, neighbours: int) -> Array:
    var table_size: int = states * (states * neighbours + 1)
    var rule: Array = []
    for _i in table_size:
        rule.append(randi() % states)
    return rule
```

Random entries from 0 to states-1. Most random rules produce boring chaos; a few produce interesting structure.

Hex grid cell neighbours.

```gdscript
func hex_neighbours(x: int, y: int) -> Array:
    var odd: bool = y % 2 == 1
    var offsets: Array = [
        Vector2i(-1, 0), Vector2i(1, 0),
        Vector2i(0, -1), Vector2i(0, 1),
    ]
    if odd:
        offsets.append(Vector2i(1, -1)); offsets.append(Vector2i(1, 1))
    else:
        offsets.append(Vector2i(-1, -1)); offsets.append(Vector2i(-1, 1))
    var result: Array = []
    for off in offsets:
        result.append(Vector2i((x + off.x + size.x) % size.x, (y + off.y + size.y) % size.y))
    return result
```

Six neighbours on a hex grid. Offset parity depends on whether the row is even or odd (offset-coordinate layout).

Count hex neighbours.

```gdscript
func count_hex_neighbours(x: int, y: int) -> int:
    var count: int = 0
    for nb in hex_neighbours(x, y):
        count += grid[nb.y][nb.x]
    return count
```

Same pattern as square grids; different coordinate lookup.

VR hex grid display.

```gdscript
func world_position_for_hex(x: int, y: int, spacing: float = 1.0) -> Vector3:
    var odd_offset: float = 0.5 if y % 2 == 1 else 0.0
    return Vector3((x + odd_offset) * spacing, 0, y * spacing * sqrt(3) / 2)
```

Hex cells tile with a staggered offset. The world positions produce the characteristic honeycomb pattern.

Multi-state cell.

```gdscript
func multi_state_rule(self_state: int, neighbours: Array) -> int:
    var sum_by_state: Dictionary = {}
    for n in neighbours:
        sum_by_state[n] = sum_by_state.get(n, 0) + 1
    var dominant_state: int = 0
    var dominant_count: int = 0
    for state in sum_by_state:
        if sum_by_state[state] > dominant_count:
            dominant_count = sum_by_state[state]; dominant_state = state
    return dominant_state if dominant_count > 2 else self_state
```

Cells take on the dominant neighbour state. Produces smoothing / blob behaviour; resembles Turing patterns.

Render cells by state.

```gdscript
const STATE_COLORS := [Color.BLACK, Color.BLUE, Color.GREEN, Color.RED, Color.YELLOW]

func paint_cell_by_state(x: int, y: int, state: int) -> void:
    get_cell(x, y).material_override.albedo_color = STATE_COLORS[state]
```

Each state maps to a colour. The grid becomes a multi-colour mosaic that evolves over time.

You can now build totalistic rules, hex-neighbour lookup, random rule generation, multi-state cells, and colour-coded rendering. CA_ExpandingSpace extends the neighbourhood reach.

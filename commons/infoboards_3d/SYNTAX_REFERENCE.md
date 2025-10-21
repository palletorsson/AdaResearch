# Info Board Syntax Reference

## ✅ New Syntax (Recommended)

The info board system now uses `ib:` prefix syntax, consistent with other utility parameters like `t:next`.

### Format

```
ib:<board_type>[:<parameter1>[:<parameter2>...]]
```

### Examples

**Basic placement:**
```json
"utilities": [
    [" ", "ib:randomwalk", " "],
    [" ", " ", "ib:bfs"]
]
```

**With height offset:**
```json
"utilities": [
    ["ib:randomwalk:0.5", " ", " "],   // Raised 0.5m
    [" ", "ib:bfs:1.0", " "],          // Raised 1.0m
    [" ", " ", "ib:neural:2.0"]        // Raised 2.0m
]
```

**Multiple parameters:**
```json
"utilities": [
    ["ib:randomwalk:0.5:someotherparam", " ", " "]
]
```

---

## 📋 Available Board Types

Use these after `ib:`:

| Type | Full Syntax | Description |
|------|-------------|-------------|
| `randomwalk` | `ib:randomwalk` | Random Walk algorithm |
| `bfs` | `ib:bfs` | Breadth-First Search |
| `neural` | `ib:neural` | Neural Networks |
| `sorting` | `ib:sorting` | Sorting Algorithms |

---

## 🎨 Complete Example

**map_data.json:**
```json
{
    "layers": {
        "utilities": [
            [" ", " ", " ", " ", "t"],
            [" ", "ib:randomwalk", " ", "ib:bfs", " "],
            [" ", " ", " ", " ", " "],
            [" ", "ib:neural:0.5", " ", "ib:sorting:1.0", " "]
        ]
    },
    "utility_definitions": {
        "t": {...},
        "ib:randomwalk": {
            "type": "info_board",
            "name": "Random Walk Info Board",
            "properties": {
                "category": "Randomness",
                "category_color": [0.8, 0.5, 0.9]
            }
        },
        "ib:bfs": {
            "type": "info_board",
            "properties": {
                "category": "Graph Theory"
            }
        }
    }
}
```

---

## 🔄 Backwards Compatibility

The old syntax still works:

```json
"utilities": [
    ["ib_randomwalk", " ", " "],      // OLD: ib_randomwalk
    ["ib:randomwalk", " ", " "]       // NEW: ib:randomwalk
]
```

Both are equivalent, but **use the new `ib:` syntax** for consistency with utilities like `t:next`, `l:5`, etc.

---

## 🎯 Comparison with Other Utilities

Info boards follow the same pattern as other utilities:

```json
"utilities": [
    ["t:next", " ", " "],              // Teleporter: next in sequence
    ["l:5", " ", " "],                 // Lift: 5 units high
    ["ib:randomwalk", " ", " "],       // Info board: randomwalk type
    ["ib:randomwalk:0.5", " ", " "],   // Info board: with height offset
    ["wp:90:blue", " ", " "]           // Walkway: rotation + color
]
```

---

## 🔧 In Code

### Grid Layout (Component Pattern)

```gdscript
var board_layout = [
    [" ", "ib:randomwalk", " "],
    [" ", " ", "ib:bfs:0.5"]
]

info_board_component.generate_boards(board_layout)
```

### Direct Placement (API)

```gdscript
# Note: Use just the type name, not "ib:" prefix
info_board_component.place_board_at("randomwalk", Vector3(0, 1.5, 0))
```

### Parse Board Cell

```gdscript
var parsed = InfoBoardRegistry.parse_board_cell("ib:randomwalk:0.5")
# Returns: {type: "randomwalk", parameters: ["0.5"]}
```

---

## ❓ Why This Syntax?

**Consistency:**
- `t:next` - Teleporter with destination
- `l:5` - Lift with height
- `ib:randomwalk` - Info board with type
- `ib:randomwalk:0.5` - Info board with type + offset

**Cleaner:**
- Groups all info boards under `ib` namespace
- Board type becomes a parameter rather than prefix
- Easier to extend with more parameters

**Flexible:**
- Can add more parameters: `ib:randomwalk:0.5:page2`
- Can filter utilities: "Give me all `ib:*`"
- Matches utility system patterns

---

## 📚 Full Documentation

See:
- `COMPONENT_USAGE.md` - How to use components
- `MAP_INTEGRATION_GUIDE.md` - Integrating with map system
- `README.md` - Overview and features

---

**Quick Reference:**
```
ib:randomwalk         → Random Walk board
ib:randomwalk:0.5     → Random Walk board, 0.5m height offset
ib:bfs                → BFS board
ib:neural:1.0         → Neural Network board, 1.0m height offset
```

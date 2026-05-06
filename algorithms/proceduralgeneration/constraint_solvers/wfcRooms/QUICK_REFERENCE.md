# WFC Room Tiles - Quick Reference 🚀

## 3-Minute Setup

```bash
1. Run wfc_rooms.gd → Creates algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn
2. Open wfc_dungeon_generator.tscn
3. Press F6 → Dungeon appears!
```

---

## File Purposes

| File | Purpose | When to Use |
|------|---------|-------------|
| `wfc_rooms.gd` | **Tile Generator** (EditorScript) | Run once to create tiles |
| `wfc_solver.gd` | **Runtime WFC Algorithm** | Attach to Node3D to generate dungeons |
| `tile_template_examples.gd` | **7 Example Tile Sets** | Copy templates for different themes |
| `wfc_dungeon_generator.tscn` | **Demo Scene** | Play to see WFC in action |
| `RoomTiles_Aligned.tscn` | **Generated Tiles** | Created by wfc_rooms.gd |

---

## Socket Types Cheatsheet

```
"open"   → Empty space     □ Connects to: "open"
"wall"   → Solid barrier   ▓ Connects to: "wall"
"door"   → Doorway         ⊓ Connects to: "door"

Custom sockets only match themselves:
"bars"   → Jail bars       ≡ Connects to: "bars"
"window" → See-through     ○ Connects to: "window"
"rock"   → Cave wall       ◘ Connects to: "rock"
```

---

## Tile Definition Template

```gdscript
var tiles : Array = [
    # Name          N       E       S       W
    ["Floor",    {"N":"open","E":"open","S":"open","W":"open"}],
    ["Wall_N",   {"N":"wall","E":"open","S":"open","W":"open"}],
    ["Door_E",   {"N":"open","E":"door","S":"open","W":"open"}],
    ["Corner_NE",{"N":"wall","E":"wall","S":"open","W":"open"}],
]
```

---

## Common Tile Patterns

### Empty Room (All sides open)
```
     open
    ┌────┐
open│    │open
    └────┘
     open
```
```gdscript
["Floor", {"N":"open", "E":"open", "S":"open", "W":"open"}]
```

### Wall on North
```
     wall
    ┌────┐
open│    │open
    └────┘
     open
```
```gdscript
["Wall_N", {"N":"wall", "E":"open", "S":"open", "W":"open"}]
```

### Corner (NE)
```
     wall
    ┌────┐
open│    │wall
    └────┘
     open
```
```gdscript
["Corner_NE", {"N":"wall", "E":"wall", "S":"open", "W":"open"}]
```

### Door on South
```
     open
    ┌────┐
open│    │open
    └─┬┬─┘
     door
```
```gdscript
["Door_S", {"N":"open", "E":"open", "S":"door", "W":"open"}]
```

### Hallway (NS)
```
     door
    ┌────┐
wall│    │wall
    └────┘
     door
```
```gdscript
["Hall_NS", {"N":"door", "E":"wall", "S":"door", "W":"wall"}]
```

### T-Junction (NES)
```
     wall
    ┌────┐
wall│    │wall
    └────┘
     wall
```
```gdscript
["T_NES", {"N":"wall", "E":"wall", "S":"wall", "W":"open"}]
```

---

## Parameter Quick Reference

### wfc_rooms.gd (Tile Generator)
```gdscript
const TILE_SIZE   = 2.0    // Room size (2m x 2m)
const WALL_HEIGHT = 2.6    // Wall height (2.6m tall)
const WALL_THICK  = 0.18   // Wall thickness
const DOOR_WIDTH  = 1.0    // Door opening width
const DOOR_HEIGHT = 2.1    // Door opening height
```

### wfc_solver.gd (Dungeon Generator)
```gdscript
grid_width = 12            // Dungeon width (tiles)
grid_height = 12           // Dungeon height (tiles)
tile_size = 2.0            // Must match TILE_SIZE
generation_seed = -1       // Random seed (-1 = random)
max_iterations = 10000     // Safety limit
auto_generate = true       // Generate on _ready()?
```

---

## Common Modifications

### Make Bigger Rooms
```gdscript
# wfc_rooms.gd
const TILE_SIZE = 4.0      // 4m x 4m rooms instead of 2m x 2m
```

### Taller Ceilings
```gdscript
const WALL_HEIGHT = 4.0    // 4m tall instead of 2.6m
```

### Wider Doors
```gdscript
const DOOR_WIDTH = 1.5     // 1.5m wide instead of 1m
```

### Bigger Dungeon
```gdscript
# wfc_solver.gd in Inspector
grid_width = 20
grid_height = 20
```

### Different Layout
```gdscript
generation_seed = 12345    // Specific seed
generation_seed = -1       // Random each time
```

---

## Tile Set Sizes

| Complexity | Tile Count | Use Case |
|------------|-----------|----------|
| Minimal | 9 tiles | Testing, simple layouts |
| Standard | 18 tiles | **Most common** - full featured |
| Extended | 25+ tiles | Special rooms, variety |
| Complex | 40+ tiles | Maximum variety (slower WFC) |

**Recommended**: Start with 18 tiles (standard set)

---

## WFC Algorithm Steps

```
1. Initialize grid (all tiles possible everywhere)
   ↓
2. Find cell with minimum entropy (fewest possibilities)
   ↓
3. Randomly collapse cell to one tile
   ↓
4. Propagate constraints to neighbors
   ↓
5. Repeat 2-4 until all cells collapsed
   ↓
6. Place tiles in 3D world
```

---

## Debugging

### Print Socket Rules
```gdscript
print(generator.socket_rules)
```

### Print Grid Layout
```gdscript
generator.print_grid()
# Output:
# F W D C T ...
# W F F W ...
```

### Check Specific Tile
```gdscript
var tile = generator.get_tile_at(5, 3)
print(tile.name)
print(tile.get_meta("sockets"))
```

### Visualize Possibilities
```gdscript
# In wfc_solver.gd, add to _find_min_entropy_cell()
print("Cell (", x, ",", y, ") has ", possible[y][x].size(), " possibilities")
```

---

## Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "No tiles found" | RoomTiles_Aligned.tscn missing in wfcRooms/ | Run wfc_rooms.gd first |
| "WFC failed" | No valid solution | Smaller grid or more tiles |
| "Max iterations" | WFC stuck | Try different seed |
| "Contradiction" | Impossible tile placement | Check socket rules |

---

## Code Snippets

### Generate Dungeon from Code
```gdscript
var gen = preload("res://path/to/wfc_solver.gd").new()
add_child(gen)
gen.grid_width = 15
gen.grid_height = 15
gen.generate_dungeon()
```

### Regenerate with New Seed
```gdscript
gen.regenerate(randi())
```

### Add Custom Tile Type
```gdscript
# In wfc_rooms.gd tiles array
["MyTile", {"N":"wall", "E":"door", "S":"open", "W":"wall"}]
```

### Change Tile Colors
```gdscript
# In _build_tile()
_add_box_csg("Floor", floor_min, floor_max, Color(0.8, 0.6, 0.4))
```

---

## Socket Compatibility Matrix

|       | open | wall | door | bars | rock |
|-------|------|------|------|------|------|
| **open** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **wall** | ❌ | ✅ | ❌ | ❌ | ❌ |
| **door** | ❌ | ❌ | ✅ | ❌ | ❌ |
| **bars** | ❌ | ❌ | ❌ | ✅ | ❌ |
| **rock** | ❌ | ❌ | ❌ | ❌ | ✅ |

**Rule**: Sockets only match themselves!

---

## Direction Reference

```
      North (N)
          ↑
          |
West (W) ←+→ East (E)
          |
          ↓
      South (S)
```

When tiles connect:
- Tile A's East connects to Tile B's West
- Tile A's North connects to Tile B's South
- etc.

---

## Performance Guide

| Grid Size | Tiles | Generation Time | Use Case |
|-----------|-------|----------------|----------|
| 5x5 | 18 | < 0.1s | Testing |
| 10x10 | 18 | < 0.5s | Small dungeon |
| 15x15 | 18 | 1-2s | Medium dungeon |
| 20x20 | 18 | 2-5s | Large dungeon |
| 30x30 | 18 | 5-15s | Huge dungeon |
| 50x50 | 18 | 30s+ | Very slow! |

**Tip**: For huge dungeons, generate in chunks!

---

## Complete Minimal Example

### 1. Create tiles (wfc_rooms.gd)
```gdscript
var tiles = [
    ["Floor", {"N":"open","E":"open","S":"open","W":"open"}],
    ["Door_N",{"N":"door","E":"open","S":"open","W":"open"}],
]
```

### 2. Run script
```
File → Run in Script Editor
```

### 3. Generate dungeon
```gdscript
# In scene
var gen = WFCSolver.new()
gen.grid_width = 8
gen.grid_height = 8
add_child(gen)
gen.generate_dungeon()
```

---

## 7 Example Tile Sets

1. **Minimal** (9) - Basic dungeon
2. **Complete** (18) - Full featured ⭐ DEFAULT
3. **Hallway** (16) - Rooms + corridors
4. **Prison** (10) - Cells with bars
5. **Cave** (15) - Natural rock formations
6. **Multi-Story** (16) - With stairs (6 sockets)
7. **Zelda** (18) - Boss rooms, locked doors

See `tile_template_examples.gd` for code!

---

## Workflow

```
Choose Template → Run Generator → View Tiles → Adjust → Generate Dungeon → Iterate
     (1)              (2)            (3)        (4)         (5)           (6)
```

---

## Resources

- Full Guide: `WFC_GUIDE.md`
- Templates: `tile_template_examples.gd`
- README: `README.md`
- This: `QUICK_REFERENCE.md`

---

**Remember**: 
- Sockets must match
- Start small (10x10)
- Test tiles manually first
- Use standard 18-tile set

Happy dungeon building! 🏰✨


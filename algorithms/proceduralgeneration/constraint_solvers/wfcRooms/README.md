# WFC Room Tile System 🏰

A complete **Wave Function Collapse** (WFC) procedural dungeon generator for Godot 4.x

## 🚀 Quick Start (5 Steps)

### 1. Generate Tile Templates
```
1. Open wfc_rooms.gd in Script Editor
2. Click File → Run (or Ctrl+Shift+X)
3. This creates res://algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn
```

### 2. View the Tiles
```
1. Open algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn
2. You'll see 18 different room tiles in a grid
3. Each tile has walls, doors, or openings
```

### 3. Generate a Dungeon
```
1. Open wfc_dungeon_generator.tscn
2. Press F6 to play the scene
3. A 12x12 dungeon generates automatically!
```

### 4. Customize Parameters
```
Select the root node and adjust:
- grid_width/height: Size of dungeon
- tile_size: Size of each room
- generation_seed: Different layouts
```

### 5. Create Custom Tiles
```
1. Open tile_template_examples.gd
2. Run it to see 7 example tile sets
3. Copy one into wfc_rooms.gd
4. Re-run to generate new tiles!
```

---

## 📁 File Overview

### Core Files
- **`wfc_rooms.gd`** - Tile generator (EditorScript)
  - Creates 3D room tiles with walls/doors
  - Defines socket rules for WFC
  - Saves to `algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn`

- **`wfc_solver.gd`** - Runtime dungeon generator
  - Wave Function Collapse algorithm
  - Reads tiles from scene
  - Generates procedural dungeons

### Helper Files
- **`tile_template_examples.gd`** - Example tile configurations
  - 7 pre-made tile sets
  - Different themes (cave, prison, zelda-style, etc.)
  - Copy into wfc_rooms.gd

### Scenes
- **`wfc_rooms.tscn`** - Empty scene (placeholder)
- **`wfc_dungeon_generator.tscn`** - Runtime generator demo
- **`RoomTiles_Aligned.tscn`** - Generated tiles (created when you run wfc_rooms.gd)

### Documentation
- **`WFC_GUIDE.md`** - Complete guide to customizing tiles
- **`README.md`** - This file

---

## 🎮 How It Works

### Socket System

Each tile has 4 edges (North, East, South, West) with socket types:

```
┌──────────┐
│    N     │
│ W     E  │  Sockets: {N:"wall", E:"door", S:"open", W:"wall"}
│    S     │
└──────────┘
```

**Socket Types:**
- `"open"` - Empty space (connects to other open)
- `"wall"` - Solid wall (connects to other walls)
- `"door"` - Doorway (connects to other doors)

**WFC Rule:** Adjacent tiles can only connect if their touching edges have **matching socket types**.

---

## 🎨 Example Tile Configurations

### 1. Minimal (9 tiles)
Basic dungeon with just floors, walls, and doors.
```gdscript
["Floor",  {"N":"open", "E":"open", "S":"open", "W":"open"}],
["Wall_N", {"N":"wall", "E":"open", "S":"open", "W":"open"}],
// ... 4 walls + 4 doors
```

### 2. Complete (18 tiles) - DEFAULT
Full dungeon with corners, T-junctions, and cross sections.
```gdscript
Includes: Floor, 4 Walls, 4 Corners, 4 T-junctions, 1 Cross, 4 Doors
```

### 3. Hallway System (16 tiles)
Rooms connected by narrow corridors.

### 4. Prison (10 tiles)
Cells with bars, guard rooms, corridors.

### 5. Cave (15 tiles)
Natural rock formations, tunnels, crevices.

### 6. Multi-Story (16 tiles)
Includes stairs going up/down (6 sockets: N,E,S,W,U,D).

### 7. Zelda-Style (18 tiles)
Boss rooms, treasure rooms, locked doors.

See `tile_template_examples.gd` for complete code!

---

## 🔧 Customization

### Change Tile Size
```gdscript
# In wfc_rooms.gd
const TILE_SIZE = 2.0  // Smaller rooms
const TILE_SIZE = 4.0  // Larger rooms
```

### Change Wall Height
```gdscript
const WALL_HEIGHT = 2.6  // Normal
const WALL_HEIGHT = 4.0  // Tall ceilings
const WALL_HEIGHT = 1.8  // Low dungeons
```

### Add Furniture
```gdscript
func _build_tile(name: String, sockets: Dictionary) -> Node3D:
    var tile := Node3D.new()
    // ... existing code ...
    
    if name == "Floor":
        _add_table(tile)
        _add_chairs(tile)
    
    return tile
```

### Change Colors
```gdscript
# Floor color
tile.add_child(_add_box_csg("Floor", floor_min, floor_max, 
    Color(0.6, 0.5, 0.4)))  // Brown

# Wall color
Color(0.7, 0.7, 0.8)  // Light gray
Color(0.3, 0.2, 0.2)  // Dark stone
Color(0.1, 0.5, 0.2)  // Mossy
```

---

## 🎲 Using the Runtime Generator

### In a Scene
```gdscript
# 1. Add wfc_solver.gd to a Node3D
# 2. Set parameters in Inspector:
grid_width = 15
grid_height = 15
tiles_scene_path = "res://algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn"
auto_generate = true

# 3. Play scene - dungeon generates automatically!
```

### From Code
```gdscript
var generator = preload("res://algorithms/proceduralgeneration/wfcRooms/wfc_solver.gd").new()
add_child(generator)
generator.grid_width = 20
generator.grid_height = 20
generator.generate_dungeon()

# Regenerate with new seed
generator.regenerate(12345)
```

### Access Generated Tiles
```gdscript
# Get tile at position
var tile = generator.get_tile_at(5, 3)
print(tile.name)  // "Corner_NE"

# Print entire grid layout
generator.print_grid()
```

---

## 🐛 Troubleshooting

### "No tiles found in scene!"
- Make sure you ran `wfc_rooms.gd` first
- Check that `RoomTiles_Aligned.tscn` exists
- Verify tiles_scene_path is correct

### "WFC failed to find valid solution"
- Grid might be too large for tile set
- Try smaller grid (8x8 or 10x10)
- Add more tile variety
- Increase max_iterations

### "Max iterations reached!"
- WFC got stuck (rare)
- Try different seed
- Simplify tile set
- Check socket rules are correct

### Tiles don't connect properly
- Verify socket types match
- Print socket rules: `print(generator.socket_rules)`
- Check tile metadata is set correctly

---

## 📚 Advanced Topics

### Custom Socket Types

Add new socket types beyond wall/door/open:

```gdscript
# In tile definition
["Window_N", {"N":"window", "E":"wall", "S":"wall", "W":"wall"}]
["Bars_N",   {"N":"bars", "E":"wall", "S":"wall", "W":"wall"}]
["Water_E",  {"N":"wall", "E":"water", "S":"wall", "W":"wall"}]

# Note: Custom sockets only match themselves
# "window" only connects to "window", etc.
```

### Weighted Tiles

Make some tiles appear more often:

```gdscript
# Duplicate common tiles in the array
var tiles = [
    ["Floor", {"N":"open", "E":"open", "S":"open", "W":"open"}],
    ["Floor", {"N":"open", "E":"open", "S":"open", "W":"open"}],  // 2x
    ["Floor", {"N":"open", "E":"open", "S":"open", "W":"open"}],  // 3x
    ["Treasure", {"N":"wall", "E":"wall", "S":"wall", "W":"wall"}],  // 1x rare
]
```

### Boundary Constraints

Force certain tiles at edges:

```gdscript
# In wfc_solver.gd _initialize_grid()
# Force walls on boundaries
for x in range(grid_width):
    possible[0][x] = [tile_wall_south]  // North edge
    possible[grid_height-1][x] = [tile_wall_north]  // South edge
```

### Multi-Layer Dungeons

Generate multiple floors:

```gdscript
var floors = []
for floor_num in range(3):
    var gen = wfc_solver.new()
    gen.generate_dungeon()
    floors.append(gen)
    
    # Position each floor vertically
    gen.position.y = floor_num * 3.0
    add_child(gen)
```

---

## 🎯 Tips for Good Dungeons

### 1. Balance Tile Variety
- Too few tiles → repetitive
- Too many tiles → slow WFC
- Sweet spot: 15-25 tile types

### 2. Ensure Connectivity
- Include straight hallway tiles
- Add corner pieces
- Don't make dead-ends too common

### 3. Use Themed Sets
- Cave theme: all rock/crevice sockets
- Dungeon theme: all wall/door sockets
- Don't mix themes in one set

### 4. Test Manually First
- Place tiles by hand in 3D editor
- Verify they connect correctly
- Check visual alignment

### 5. Start Small
- Begin with 8x8 grid
- Verify generation works
- Scale up to 20x20+ later

---

## 📖 Learn More

- **WFC Algorithm**: [Original WFC repo](https://github.com/mxgmn/WaveFunctionCollapse)
- **Socket-Based WFC**: "Model Synthesis" variant
- **Godot Docs**: [3D Nodes](https://docs.godotengine.org/en/stable/classes/class_node3d.html)

---

## 🎬 Complete Workflow

```
1. Choose a tile template from tile_template_examples.gd
   ↓
2. Copy it into wfc_rooms.gd's tiles array
   ↓
3. Run wfc_rooms.gd to generate tile scene
   ↓
4. Open wfc_dungeon_generator.tscn
   ↓
5. Adjust grid_width/height/seed in Inspector
   ↓
6. Press F6 to generate dungeon
   ↓
7. Iterate: tweak tiles, regenerate, test
```

---

## ✨ Examples

### Generate 10 Different Dungeons
```gdscript
for i in range(10):
    var gen = preload("res://algorithms/proceduralgeneration/wfcRooms/wfc_solver.gd").new()
    gen.generation_seed = i
    gen.grid_width = 12
    gen.grid_height = 12
    gen.tile_size = 2.0
    add_child(gen)
    gen.position.x = i * 30  // Space them out
    gen.generate_dungeon()
```

### Save Dungeon to File
```gdscript
# After generation
var scene = PackedScene.new()
scene.pack(generator)
ResourceSaver.save(scene, "res://my_dungeon.tscn")
```

### Add Player Spawn
```gdscript
# Find a floor tile and spawn player there
for y in range(generator.grid_height):
    for x in range(generator.grid_width):
        var tile = generator.get_tile_at(x, y)
        if tile and tile.name == "Floor":
            player.position = Vector3(x * tile_size, 1, y * tile_size)
            return
```

---

Made with 🏗️ for procedural dungeon generation!


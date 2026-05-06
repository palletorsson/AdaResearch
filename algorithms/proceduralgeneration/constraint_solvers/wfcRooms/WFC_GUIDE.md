# WFC Room Tiles System - Complete Guide 🏗️

## What This Does

The `wfc_rooms.gd` script generates **3D room tiles** that can be combined using Wave Function Collapse (WFC) algorithm to create procedural dungeons/buildings.

### Core Concept: Socket Matching

Each tile has 4 edges (N, E, S, W) with **socket types**:
- **`"open"`** - Empty edge, can connect to other open edges
- **`"wall"`** - Solid wall, must connect to other walls
- **`"door"`** - Doorway, must connect to other doors

**Rule**: Adjacent tiles can only connect if their touching edges have **matching socket types**.

---

## How to Use the Current Script

### Step 1: Run the Generator

1. Open `wfc_rooms.gd` in the Godot Script Editor
2. Click **File → Run** (or Ctrl+Shift+X)
3. This creates `res://algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn` with all tiles in a grid

### Step 2: View the Tiles

The generated scene shows 18 tile types:
- **Floor** - Empty room (all sides open)
- **Wall_N/E/S/W** - Room with 1 wall
- **Corner_NE/ES/SW/WN** - Room with 2 walls forming corner
- **T_NES/ESW/SWN/WNE** - T-junctions (3 walls)
- **+_Cross** - All 4 walls
- **Door_N/E/S/W** - Doorways in each direction

---

## Customizing the Tile Template

### Adding New Tile Types

Edit the `tiles` array in `_run()`:

```gdscript
var tiles : Array = [
	# Name,         Sockets
	["Floor",       {"N":"open", "E":"open", "S":"open", "W":"open"}],
	
	# Add your custom tiles here!
	["Pillar",      {"N":"wall", "E":"wall", "S":"wall", "W":"wall"}],
	["Hallway_NS",  {"N":"door", "E":"wall", "S":"door", "W":"wall"}],
	["Hallway_EW",  {"N":"wall", "E":"door", "S":"wall", "W":"door"}],
	["Room_Large",  {"N":"door", "E":"door", "S":"wall", "W":"wall"}],
]
```

### Customizing Dimensions

Adjust these constants at the top:

```gdscript
const TILE_SIZE   = 2.0    # Size of each tile in world units
const FLOOR_THICK = 0.04   # Floor thickness
const WALL_THICK  = 0.18   # Wall thickness
const WALL_HEIGHT = 2.6    # How tall walls are
const DOOR_WIDTH  = 1.0    # Width of doorways
const DOOR_HEIGHT = 2.1    # Height of doorways
```

### Changing Colors

Modify the colors in `_add_box_csg()`:

```gdscript
# Floor color
tile.add_child(_add_box_csg("Floor", floor_min, floor_max, 
	Color(0.8, 0.7, 0.6, 1.0)))  # Brown floor

# Wall color (change in _place_wall_edge)
parent.add_child(_add_box_csg("Wall_N", Vector3(...), Vector3(...),
	Color(0.6, 0.6, 0.7, 1.0)))  # Blue-gray walls
```

---

## Understanding Socket Compatibility

### Valid Connections

```
┌─────┬─────┐
│ N:  │ N:  │
│open │open │  ✅ VALID - both open
└─────┴─────┘

┌─────┬─────┐
│ N:  │ N:  │
│wall │wall │  ✅ VALID - both walls align
└─────┴─────┘

┌─────┬─────┐
│ N:  │ N:  │
│door │door │  ✅ VALID - doors connect
└─────┴─────┘
```

### Invalid Connections

```
┌─────┬─────┐
│ N:  │ N:  │
│open │wall │  ❌ INVALID - mismatch
└─────┴─────┘

┌─────┬─────┐
│ N:  │ N:  │
│wall │door │  ❌ INVALID - mismatch
└─────┴─────┘
```

---

## Adding Custom Geometry to Tiles

### Example: Add Furniture

```gdscript
func _build_tile(name: String, sockets: Dictionary) -> Node3D:
	var tile := Node3D.new()
	# ... existing code ...
	
	# Add custom geometry based on tile name
	if name == "Floor":
		_add_furniture(tile)
	elif name.begins_with("Corner"):
		_add_corner_decoration(tile)
	
	return tile

func _add_furniture(tile: Node3D) -> void:
	# Add a table in the center
	var table := _add_box_csg("Table",
		Vector3(0.7, FLOOR_THICK, 0.7),
		Vector3(1.3, FLOOR_THICK + 0.8, 1.3),
		Color(0.6, 0.4, 0.2))  # Brown table
	tile.add_child(table)
```

### Example: Add Ceiling

```gdscript
func _build_tile(name: String, sockets: Dictionary) -> Node3D:
	var tile := Node3D.new()
	# ... existing code ...
	
	# Add ceiling
	var ceiling_y = FLOOR_THICK + WALL_HEIGHT
	var ceiling := _add_box_csg("Ceiling",
		Vector3(0, ceiling_y, 0),
		Vector3(TILE_SIZE, ceiling_y + FLOOR_THICK, TILE_SIZE),
		Color(0.95, 0.95, 1.0))
	tile.add_child(ceiling)
	
	return tile
```

---

## Creating Themed Tile Sets

### Cave Theme

```gdscript
const TILE_SIZE = 3.0      # Larger, irregular caves
const WALL_HEIGHT = 3.5    # Taller caves
const WALL_THICK = 0.4     # Thicker rock walls

# Use darker, earthy colors
var floor_color = Color(0.3, 0.25, 0.2)  # Dark brown
var wall_color = Color(0.4, 0.35, 0.3)   # Gray-brown rock
```

### Sci-Fi Theme

```gdscript
const WALL_THICK = 0.3     # Thicker metal walls
const DOOR_WIDTH = 1.2     # Wider automatic doors

# Metallic colors
var floor_color = Color(0.5, 0.5, 0.6)   # Metal floor
var wall_color = Color(0.6, 0.65, 0.7)   # Light metal
```

### Medieval Castle

```gdscript
const TILE_SIZE = 4.0      # Larger rooms
const WALL_HEIGHT = 4.0    # Taller rooms
const WALL_THICK = 0.5     # Very thick stone walls

# Stone colors
var floor_color = Color(0.6, 0.55, 0.5)  # Stone floor
var wall_color = Color(0.7, 0.65, 0.6)   # Stone walls
```

---

## Advanced: Multi-Story Tiles

Add vertical sockets for creating multi-floor dungeons:

```gdscript
var tiles : Array = [
	# Add Up/Down sockets
	["Stairs_Up",   {"N":"wall", "E":"wall", "S":"door", "W":"wall", "U":"stairs", "D":"open"}],
	["Stairs_Down", {"N":"wall", "E":"wall", "S":"door", "W":"wall", "U":"open", "D":"stairs"}],
	["Ladder",      {"N":"open", "E":"open", "S":"open", "W":"open", "U":"ladder", "D":"ladder"}],
]
```

---

## Tile Naming Convention

**Recommended pattern**: `Type_Details`

```gdscript
// Good names
"Floor"              // Simple, clear
"Wall_N"             // Wall on north side
"Corner_NE"          // Corner with N and E walls
"T_Junction_NES"     // T with walls on N, E, S
"Room_Treasure"      // Special room type
"Hallway_NS"         // Hallway running North-South

// Avoid
"Tile1", "Tile2"     // Not descriptive
"NWSE"               // Unclear abbreviation
```

---

## Socket Type Examples

### Standard Set
```gdscript
"open"  // Empty space
"wall"  // Solid barrier
"door"  // Passageway
```

### Extended Set (Custom)
```gdscript
"window"     // Can see through, can't pass
"bars"       // Jail bars
"cliff"      // Drop-off edge
"water"      // Water boundary
"lava"       // Lava boundary
"portal"     // Magical connection
"locked"     // Locked door
```

**Note**: Extended sockets need custom matching rules in your WFC solver!

---

## Exporting Tiles for WFC

The generated tiles store socket info as metadata:

```gdscript
tile.set_meta("sockets", {"N":"wall", "E":"open", "S":"open", "W":"wall"})
tile.add_to_group("tile")
```

Your WFC solver can read this:

```gdscript
func get_tile_sockets(tile: Node3D) -> Dictionary:
	return tile.get_meta("sockets", {})

func tiles_can_connect(tile_a: Node3D, tile_b: Node3D, direction: String) -> bool:
	var sockets_a = get_tile_sockets(tile_a)
	var sockets_b = get_tile_sockets(tile_b)
	
	# Get opposite direction
	var opposite = {"N":"S", "S":"N", "E":"W", "W":"E"}[direction]
	
	# Check if sockets match
	return sockets_a[direction] == sockets_b[opposite]
```

---

## Common Tile Patterns

### Basic Room Set (Minimum)
- 1 Floor (all open)
- 4 Walls (one per direction)
- 4 Doors (one per direction)

### Complete Room Set
- Floor
- 4 Single walls
- 4 Corners
- 4 T-junctions
- 1 Cross (all walls)
- 4 Doors
- **Total: 18 tiles**

### Extended Room Set
Add:
- Windows (see-through walls)
- Large rooms (2x2 tiles)
- Hallways (long corridors)
- Special rooms (treasure, boss, spawn)
- Stairs/elevators
- **Total: 30+ tiles**

---

## Performance Tips

1. **Keep tile count reasonable** (< 50 types)
   - More tiles = slower WFC solving
   - Focus on versatile, reusable tiles

2. **Use instances for repeated geometry**
   ```gdscript
   # Create once
   var wall_mesh = _create_wall_mesh()
   
   # Instance many times
   for i in range(100):
	   var instance = wall_mesh.duplicate()
   ```

3. **Use simple collision shapes**
   - Box collision for walls
   - Avoid complex trimesh unless needed

---

## Next Steps

1. **Create your tile set** - Run the script and view tiles
2. **Customize tiles** - Add furniture, decorations, special rooms
3. **Implement WFC solver** - Use the tiles to generate dungeons (see next guide)
4. **Test combinations** - Manually place tiles to verify they connect correctly
5. **Add variety** - Create multiple versions of each tile type

---

## See Also

- `WFC_SOLVER_RUNTIME.md` - Runtime WFC dungeon generator
- `TILE_TEMPLATE_EXAMPLES.md` - Pre-made tile configurations
- Tiles are saved to: `res://algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn`

---

Happy dungeon building! 🏰✨

# WFC Office Generator Guide

## Quick Start

1. **Generate Office Tiles** (one-time setup):
   - Open `wfc_office_tiles.gd` in the Script Editor
   - Run it: `File → Run` or `Ctrl+Shift+X`
   - This creates `OfficeTiles.tscn` with all tile prefabs

2. **Generate an Office Floor Plan**:
   - Open `wfc_office_generator.tscn`
   - Press `F6` to run the scene
   - A procedural office layout will be generated!

3. **Customize**:
   - Adjust `grid_width` and `grid_height` in the Inspector
   - Change `generation_seed` for reproducible layouts
   - Modify corridor ratios to control hallway density

## Socket System

The office tiles use these socket types for connections:

| Socket Type | Connects To | Description |
|-------------|-------------|-------------|
| `open`      | `open`      | Open space (no barrier) |
| `wall`      | `wall`      | Solid wall |
| `door`      | `door`      | Standard door opening |
| `glass`     | `glass`     | Glass partition wall |
| `corridor`  | `corridor`  | Wide hallway opening |
| `cubicle`   | `cubicle`   | Cubicle partition (1.5m height) |

## Tile Categories

### Corridors (16 tiles)
- `Corridor_NS`, `Corridor_EW` - Straight hallways
- `Corridor_Corner_*` - 90° turns
- `Corridor_T_*` - T-junctions
- `Corridor_Cross` - 4-way intersection

### Private Offices (4 tiles)
- `Office_Door_N/E/S/W` - Single offices with door on one side
- Carpet flooring, solid walls, desk included

### Conference Rooms (8 tiles)
- `Conference_Glass_*` - Glass wall variations
- Carpet flooring, conference table included
- Single glass wall or corner glass wall variants

### Open Plan Areas (5 tiles)
- `OpenPlan` - Fully open space
- `OpenPlan_Wall_*` - Open plan with one exterior wall

### Cubicle Areas (5 tiles)
- `Cubicle_Open` - Central cubicle area
- `Cubicle_Wall_*` - Cubicles against wall
- 1.5m partitions with desk

### Transition Tiles (12 tiles)
- Connect different area types together
- `Trans_Corridor_Office_*` - Corridor to office door
- `Trans_Corridor_Open_*` - Corridor to open plan
- `Trans_Corridor_Glass_*` - Corridor to conference room
- `Trans_Open_Cubicle_*` - Open plan to cubicle area

### Utility Rooms (4 tiles)
- Server rooms, storage, mechanical rooms
- Tile flooring, single door entry

## Dimensions

| Element | Size |
|---------|------|
| Tile size | 4m × 4m |
| Ceiling height | 2.8m |
| Wall thickness | 12cm |
| Door width | 90cm |
| Door height | 2.1m |
| Glass partition height | 2.4m |
| Cubicle partition height | 1.5m |

## Generator Settings

```gdscript
# In wfc_office_generator.gd

@export var grid_width : int = 8         # Office width in tiles (32m)
@export var grid_height : int = 8        # Office depth in tiles (32m)
@export var tile_size : float = 4.0      # Tile size in meters

@export var force_perimeter_walls : bool = true   # Walls around edges
@export var min_corridor_ratio : float = 0.15     # Min 15% corridors
@export var max_corridor_ratio : float = 0.35     # Max 35% corridors
```

## Extending the System

### Adding New Tile Types

1. Edit `wfc_office_tiles.gd`
2. Add to the `tiles` array:
```gdscript
["TileName", {"N":"socket", "E":"socket", "S":"socket", "W":"socket"}, "floor_type", "room_type"],
```

3. Add geometry in `_add_room_details()` if needed
4. Re-run the script to regenerate tiles

### Custom Socket Types

Add new socket types for special areas:
```gdscript
# Example: Elevator shaft
["Elevator", {"N":"elevator", "E":"wall", "S":"elevator", "W":"wall"}, "tile", "elevator"],

# Elevator lobby (connects elevator to corridor)
["ElevatorLobby_N", {"N":"elevator", "E":"wall", "S":"corridor", "W":"wall"}, "tile", "lobby"],
```

### Weighted Generation

Modify `_weighted_select()` in `wfc_office_generator.gd` to adjust room type probabilities.

## Troubleshooting

**"Could not load tiles scene"**
- Run `wfc_office_tiles.gd` first to generate `OfficeTiles.tscn`

**Generation fails / contradictions**
- Try a different seed
- Reduce grid size
- Check that transition tiles exist for all socket type combinations

**Office looks too maze-like**
- Increase `min_corridor_ratio`
- Add more open plan tiles
- Reduce the number of office/utility tiles

## File Structure

```
wfcRooms/
├── wfc_office_tiles.gd        # Tile generator script
├── wfc_office_generator.gd    # Runtime WFC solver
├── wfc_office_generator.tscn  # Demo scene
├── OfficeTiles.tscn           # Generated tile prefabs
└── OFFICE_GUIDE.md            # This file
```

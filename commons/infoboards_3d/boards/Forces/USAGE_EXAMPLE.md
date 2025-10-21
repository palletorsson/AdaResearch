# Forces Info Board - Usage Example

## Map Data Integration

### Basic Usage

Add the Forces info board to your map by including it in the `utilities` layer:

```json
{
  "layers": {
    "utilities": [
      [" ", " ", " ", " ", " "],
      [" ", "ib:forces", " ", " ", " "],
      [" ", " ", " ", " ", " "]
    ]
  },
  "utility_definitions": {
    "ib:forces": {
      "type": "info_board",
      "name": "Forces Info Board",
      "description": "Learn about forces, gravity, and motion",
      "properties": {
        "category": "Physics",
        "category_color": [0.9, 0.5, 0.6]
      }
    }
  }
}
```

### With Height Offset

You can specify a height offset parameter:

```json
{
  "layers": {
    "utilities": [
      [" ", " ", " ", " ", " "],
      [" ", "ib:forces:0.5", " ", " ", " "],
      [" ", " ", " ", " ", " "]
    ]
  }
}
```

This will place the info board 0.5 units higher than the default position.

## Registry Information

The Forces info board is registered in `InfoBoardRegistry.gd` as:

```gdscript
"forces": {
    "name": "Forces Info Board",
    "category": "Physics",
    "scene": "Forces/ForcesInfoBoard.tscn",
    "description": "Forces, gravity, friction, and motion",
    "color": Color(0.9, 0.5, 0.6),
    "supports_parameters": true
}
```

## File Structure

```
commons/infoboards_3d/boards/Forces/
├── ForcesInfoBoard.tscn          # Main handheld board scene
├── ForcesInfoBoard.gd             # Content and logic script
├── ForcesInfoBoardUI.tscn         # UI scene extending base template
├── ForcesVisualization.gd         # Physics visualization script
└── README_CONVERSION.md           # Conversion documentation
```

## Testing

### Desktop Mode
Run the scene directly:
```
res://commons/infoboards_3d/boards/Forces/ForcesInfoBoard.tscn
```

### VR Mode
1. Create a test map with `ib:forces` in the utilities layer
2. Load the map in VR
3. The info board should appear at the specified grid position
4. You can grab it with VR controllers

## Syntax Reference

### General Info Board Syntax

```
ib:<board_type>[:<height_offset>]
```

**Examples:**
- `ib:forces` - Forces board at default height
- `ib:forces:1.0` - Forces board raised 1 unit
- `ib:forces:0.5` - Forces board raised 0.5 units

### Available Info Boards

Current registered boards:
- `ib:randomwalk` - Random Walk algorithms
- `ib:vectors` - Vector mathematics
- `ib:forces` - Forces and physics (NEW!)
- `ib:unitcircle` - Trigonometry and waves
- `ib:bfs` - Breadth-First Search
- `ib:neural` - Neural Networks
- `ib:sorting` - Sorting Algorithms

## Utility Registry

The info board system is referenced in `UtilityRegistry.gd`:

```gdscript
"ib": {
    "name": "info_board_handheld",
    "file": "",
    "category": "education",
    "description": "Handheld 3D info board for algorithm education (ib:randomwalk, ib:bfs, etc.)",
    "supports_parameters": true  # board_type, height_offset, page_number
}
```

The `InfoBoardComponent` in the GridSystem handles the instantiation based on the `InfoBoardRegistry` definitions.

## Complete Example Map

Here's a complete example map using the Forces info board:

```json
{
  "map_info": {
    "name": "Physics Learning Area",
    "description": "Interactive physics demonstrations",
    "version": "1.0"
  },
  "layers": {
    "structure": [
      ["2", "2", "2", "2", "2"],
      ["2", "1", "1", "1", "2"],
      ["2", "1", "1", "1", "2"],
      ["2", "1", "1", "1", "2"],
      ["2", "2", "2", "0", "2"]
    ],
    "utilities": [
      [" ", " ", " ", " ", "t"],
      [" ", "ib:forces", " ", " ", " "],
      [" ", " ", " ", "ib:vectors", " "],
      [" ", " ", " ", " ", " "],
      [" ", " ", " ", " ", " "]
    ],
    "interactables": [
      [" ", " ", " ", " ", " "],
      [" ", " ", " ", " ", " "],
      [" ", " ", " ", " ", " "],
      [" ", " ", " ", " ", " "],
      [" ", " ", " ", " ", " "]
    ]
  },
  "utility_definitions": {
    "t": {
      "type": "teleporter",
      "name": "Exit",
      "properties": {
        "action": "next_in_sequence"
      }
    },
    "ib:forces": {
      "type": "info_board",
      "name": "Forces Info Board",
      "description": "Learn about forces and motion",
      "properties": {
        "category": "Physics",
        "category_color": [0.9, 0.5, 0.6]
      }
    },
    "ib:vectors": {
      "type": "info_board",
      "name": "Vectors Info Board",
      "description": "Vector mathematics basics",
      "properties": {
        "category": "Mathematics",
        "category_color": [0.6, 0.8, 0.9]
      }
    }
  },
  "settings": {
    "cube_size": 1.0,
    "gutter": 0.0,
    "show_grid": true,
    "enable_physics": true
  }
}
```

## Troubleshooting

### Info board not appearing
- Check that `ib:forces` is in the registry
- Verify the scene path is correct in `InfoBoardRegistry.gd`
- Ensure the utility definition is present in the map JSON

### Info board appears but no content
- Check that `ForcesInfoBoard.gd` is properly attached
- Verify `initialize_content()` is being called
- Check console for errors

### Visualization not working
- Ensure `ForcesVisualization.gd` exists
- Check that visualization type matches page content
- Verify `AlgorithmVisualizationBase` is available

## Performance Notes

- Each info board is instantiated as needed
- Visualizations are lightweight for VR
- Physics simulations use delta time for consistency
- Multiple info boards can exist simultaneously


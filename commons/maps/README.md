# Map Creation Tutorial

This guide explains how to create new maps for the Ada Research VR educational system using the JSON-based map format.

## Overview

Maps in Ada Research are built from modular components using a grid-based system. Instead of creating static 3D scenes, maps are defined through JSON configuration files that specify:

- **Structure**: The 3D layout of cubes and platforms
- **Utilities**: Interactive objects like teleporters, spawn points, and doors
- **Interactables**: Educational algorithms and interactive elements
- **Environment**: Lighting, settings, and visual configuration

## Quick Start

### 1. Create Map Directory

Create a new folder in `res://commons/maps/` with your map name:

```
res://commons/maps/YourMapName/
└── map_data.json
```

### 2. Basic Map Template

Use this template for your `map_data.json`:

```json
{
  "map_info": {
	"name": "YourMapName",
	"description": "Brief description of your map",
	"version": "1.0",
	"format": "json",
	"dimensions": {
	  "width": 5,
	  "depth": 5,
	  "max_height": 6
	},
	"metadata": {
	  "difficulty": "beginner",
	  "category": "tutorial",
	  "estimated_time": "2-3 minutes",
	  "learning_objectives": ["Your learning goals here"]
	}
  },
  "layers": {
	"structure": [
	  ["1", "1", "1", "1", "1"],
	  ["1", "0", "0", "0", "1"],
	  ["1", "0", "2", "0", "1"],
	  ["1", "0", "0", "0", "1"],
	  ["1", "1", "1", "1", "1"]
	],
	"utilities": [
	  ["s", " ", " ", " ", " "],
	  [" ", " ", " ", " ", " "],
	  [" ", " ", " ", " ", " "],
	  [" ", " ", " ", " ", " "],
	  [" ", " ", " ", " ", "t"]
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
	  "description": "Complete the map to continue",
	  "properties": {
		"destination": "NextMapName",
		"visual_effect": "portal_glow"
	  }
	}
  },
  "settings": {
	"cube_size": 1.0,
	"gutter": 0.0,
	"show_grid": false,
	"enable_physics": true
  }
}
```

## Detailed Configuration

### Map Information (`map_info`)

```json
{
  "map_info": {
	"name": "Tutorial_Example",              // Must match folder name
	"description": "Example tutorial map",   // Short description
	"version": "1.0",                       // Version number
	"format": "json",                       // Always "json"
	"dimensions": {
	  "width": 7,                           // Grid width (X-axis)
	  "depth": 7,                           // Grid depth (Z-axis)  
	  "max_height": 6                       // Maximum build height (Y-axis)
	},
	"metadata": {
	  "difficulty": "beginner",             // beginner, intermediate, advanced
	  "category": "tutorial",               // tutorial, exploration, challenge
	  "estimated_time": "3-5 minutes",      // Expected completion time
	  "learning_objectives": [              // Educational goals
		"Grid navigation",
		"Spatial reasoning"
	  ]
	}
  }
}
```

### Structure Layer (`layers.structure`)

Defines the 3D layout using height values:

```json
{
  "structure": [
	["2", "1", "1", "1", "2"],  // Row 0 (Z=0): Heights at each X position
	["1", "0", "0", "0", "1"],  // Row 1 (Z=1): 0 = no cube, 1+ = stack height
	["1", "0", "3", "0", "1"],  // Row 2 (Z=2): 3 = stack 3 cubes high
	["1", "0", "0", "0", "1"],  // Row 3 (Z=3)
	["2", "1", "1", "1", "2"]   // Row 4 (Z=4)
  ]
}
```

**Tips:**
- Each row represents the Z-axis (depth)
- Each column represents the X-axis (width)
- Numbers represent cube stack height (0 = empty, 1+ = cubes)
- Keep within your defined dimensions

### Utilities Layer (`layers.utilities`)

Places functional objects on the grid:

```json
{
  "utilities": [
	["s", " ", " ", " ", " "],  // s = spawn point
	[" ", "l", " ", "b", " "],  // l = lift, b = table
	[" ", " ", "d", " ", " "],  // d = door
	[" ", "w", " ", "w", " "],  // w = window
	[" ", " ", " ", " ", "t"]   // t = teleporter
  ]
}
```

### Available Utility Types

| Code | Name | Description | Parameters |
|------|------|-------------|------------|
| `s` | Spawn Point | Player starting position | height, rotation |
| `t` | Teleporter | Scene transitions | destination, visual_effect |
| `l` | Platform Lift | Vertical movement | height, speed |
| `d` | Door | Area transitions | destination |
| `w` | Window | Visual portals | - |
| `a` | Wall | Barriers | material, transparency |
| `b` | Table | Surface objects | - |
| `p` | Pick Up | Grabbable items | - |
| `arrow` | Exit Arrow | Directional indicators | direction |
| ` ` | Empty | No utility | - |

### Utility Definitions (`utility_definitions`)

Define properties for utilities used in your map:

```json
{
  "utility_definitions": {
	"t": {
	  "type": "teleporter",
	  "name": "Next Level",
	  "description": "Advance to the next tutorial",
	  "properties": {
		"destination": "Tutorial_Advanced",
		"visual_effect": "portal_glow"
	  }
	},
	"s": {
	  "type": "spawn_point", 
	  "name": "Start Position",
	  "properties": {
		"height": 1.8,
		"player_rotation": 0.0,
		"visible_in_game": false
	  }
	},
	"l": {
	  "type": "platform_lift",
	  "properties": {
		"height": 3.0,
		"speed": 2.0
	  }
	}
  }
}
```

### Interactables Layer (`layers.interactables`)

Places educational algorithms and interactive objects:

```json
{
  "interactables": [
	[" ", " ", " ", " ", " "],
	[" ", "basic_sort", " ", " ", " "],
	[" ", " ", " ", " ", " "],
	[" ", " ", "array_demo", " ", " "],
	[" ", " ", " ", " ", " "]
  ]
}
```

**Note:** Interactable IDs must match entries in `res://algorithms/algorithms.json`

### Lighting Configuration (`lighting`)

Control the visual atmosphere:

```json
{
  "lighting": {
	"ambient_color": [0.4, 0.4, 0.5],
	"ambient_energy": 0.7,
	"directional_light": {
	  "enabled": true,
	  "direction": [-0.3, -0.8, -0.2],
	  "color": [1.0, 0.95, 0.9],
	  "energy": 1.0
	}
  }
}
```

### Settings (`settings`)

Technical and gameplay configuration:

```json
{
  "settings": {
	"cube_size": 1.0,              // Size of each grid cube
	"gutter": 0.0,                 // Spacing between cubes
	"show_grid": false,            // Display grid lines
	"enable_physics": true,        // Enable physics simulation
	"background": {
	  "type": "sky",               // sky, color
	  "color": [0.3, 0.4, 0.6]     // Background color
	}
  }
}
```

## Design Guidelines

### Educational Maps

**Structure:**
- Clear start and end points
- Progressive difficulty
- Multiple paths for exploration
- Safe areas for learning

**Utilities:**
- Spawn point at logical starting position
- Teleporter at completion point
- Tables for displaying information
- Lifts for vertical progression

**Example Progression:**
1. Simple linear path (Tutorial_Row)
2. Basic 2D navigation (Tutorial_2D)
3. Complex multi-level exploration
4. Challenge scenarios

### Spatial Design Tips

**Coordinate System:**
- X-axis: Left-right (width)
- Y-axis: Up-down (height via structure values)
- Z-axis: Forward-back (depth via array rows)

**Grid Planning:**
```
Z=0: [" ", "s", " "]  ← Player starts here (spawn)
Z=1: [" ", "1", " "]  ← Path cube
Z=2: [" ", "2", " "]  ← Higher platform
Z=3: [" ", "t", " "]  ← Exit teleporter
```

**Visual Flow:**
- Use height variation for visual interest
- Create clear sight lines to objectives
- Balance open spaces with guided paths
- Consider VR comfort (avoid tight spaces)

## Testing Your Map

### 1. Validation

Load your map in the editor to check for errors:

```gdscript
# In editor console or debug script
var loader = JsonMapLoader.new()
if loader.load_map("res://commons/maps/YourMapName/map_data.json"):
	print(loader.generate_report())
	var validation = loader.validate()
	if not validation.valid:
		print("Errors found:")
		for error in validation.errors:
			print("  - " + error)
```

### 2. Quick Test

Add debug key to test your map quickly:

```gdscript
# In any scene script
func _input(event):
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			SceneManager.load_map("YourMapName")
```

### 3. Sequence Integration

To add your map to a sequence, edit `res://commons/maps/map_sequences.json`:

```json
{
  "sequences": {
	"your_sequence": {
	  "name": "Your Tutorial Sequence",
	  "maps": ["MapOne", "YourMapName", "MapThree"],
	  "return_to": "lab"
	}
  }
}
```

## Common Patterns

### Linear Tutorial
- Single path from start to finish
- Spawn at one end, teleporter at the other
- Height variation for visual interest

```json
"structure": [
  ["1", "1", "1", "1", "1"],
  ["0", "0", "0", "0", "0"], 
  ["0", "0", "0", "0", "0"]
],
"utilities": [
  ["s", " ", " ", " ", "t"],
  [" ", " ", " ", " ", " "],
  [" ", " ", " ", " ", " "]
]
```

### Exploration Grid
- Multiple paths and areas
- Tables with learning materials
- Interactive algorithms scattered throughout

```json
"structure": [
  ["1", "1", "1", "1", "1"],
  ["1", "0", "1", "0", "1"],
  ["1", "1", "2", "1", "1"],
  ["1", "0", "1", "0", "1"],
  ["1", "1", "1", "1", "1"]
],
"utilities": [
  ["s", " ", " ", " ", " "],
  [" ", "b", " ", "b", " "],
  [" ", " ", " ", " ", " "],
  [" ", "b", " ", "b", " "],
  [" ", " ", " ", " ", "t"]
]
```

### Challenge Arena
- Central platform with surrounding challenges
- Multiple interactive elements
- Vertical progression with lifts

```json
"structure": [
  ["2", "1", "2", "1", "2"],
  ["1", "0", "1", "0", "1"],
  ["2", "1", "3", "1", "2"],
  ["1", "0", "1", "0", "1"],
  ["2", "1", "2", "1", "2"]
],
"utilities": [
  [" ", " ", "s", " ", " "],
  [" ", "l", " ", "l", " "],
  [" ", " ", " ", " ", " "],
  [" ", "l", " ", "l", " "],
  [" ", " ", "t", " ", " "]
]
```

## Troubleshooting

### Common Errors

**"Map not found"**
- Check folder name matches map_info.name
- Verify file is named `map_data.json`
- Ensure proper file path

**"Invalid JSON"**
- Use JSON validator to check syntax
- Check for missing commas or quotes
- Verify bracket matching

**"Dimension mismatch"**
- Structure array size must match declared dimensions
- Each row must have same number of columns
- Check width × depth consistency

**"Unknown utility type"**
- Verify utility codes against available types
- Check utility_definitions section
- Use proper single-character codes

### Debug Commands

Add to any scene for testing:

```gdscript
func _input(event):
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1: SceneManager.load_map("YourMapName")
			KEY_F2: print(SceneManager.get_current_sequence_data())
			KEY_F3: SceneManager.return_to_lab()
```

## Best Practices

### Performance
- Keep grid dimensions reasonable (under 20×20 for complex maps)
- Use empty spaces (" ") to optimize rendering
- Limit utility count per map

### Educational Design
- One primary learning objective per map
- Clear visual progression indicators
- Multiple interaction opportunities
- Safe exploration areas

### Accessibility
- Avoid narrow passages (VR comfort)
- Provide multiple paths when possible
- Clear visual landmarks
- Reasonable completion times (2-10 minutes)

### Version Control
- Use descriptive commit messages for map changes
- Test maps after JSON modifications
- Document significant design decisions

## Advanced Features

### Parameterized Utilities

Use colon-separated parameters for advanced utility configuration:

```json
"utilities": [
  ["t:NextMap:spawn2", " ", "l:3.0:fast"]
]
```

### Custom Materials

Reference custom materials in settings:

```json
"settings": {
  "materials": {
	"1": {"name": "stone", "color": [0.7, 0.7, 0.8]},
	"2": {"name": "metal", "color": [0.8, 0.8, 0.9]}
  }
}
```

### Environment Effects

Add atmosphere with lighting and background:

```json
"lighting": {
  "ambient_color": [0.6, 0.8, 1.0],
  "directional_light": {
	"direction": [-0.5, -0.8, -0.3],
	"color": [1.0, 0.9, 0.7]
  }
},
"settings": {
  "background": {
	"type": "color",
	"color": [0.1, 0.2, 0.4]
  }
}
```

---

## Summary

Creating maps in Ada Research involves:

1. **Plan** your educational objectives and spatial layout
2. **Create** the directory and JSON configuration file
3. **Design** structure, utilities, and interactables using the grid system
4. **Test** for errors and gameplay flow
5. **Integrate** into sequences as needed

The modular, data-driven approach allows for rapid iteration and consistent quality across all educational experiences.

For more examples, examine existing maps in this directory and refer to the full system documentation.

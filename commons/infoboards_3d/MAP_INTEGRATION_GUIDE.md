# Integrating Info Boards with Map System

## ✅ What You Just Did

You added an info board to `Random_One/map_data.json`:

```json
"utilities": [
    [" ", " ", " ", " ", "t"],
    [" ", "ib_randomwalk", " ", " ", " "],  // ← Info board at position (1, 1)
    ...
]
```

And defined its properties:

```json
"utility_definitions": {
    "ib_randomwalk": {
        "type": "info_board",
        "name": "Random Walk Info Board",
        "description": "Learn about random walk algorithms",
        "properties": {
            "category": "Randomness",
            "category_color": [0.8, 0.5, 0.9]
        }
    }
}
```

---

## 🔧 Now: Update Your Map Loader

### Option 1: If You Have a GridSystem Scene

If your map uses a GridSystem with GridUtilitiesComponent, you need to add InfoBoardComponent alongside it.

**Your scene structure should be:**

```
MapScene
├── GridSystem
│   ├── GridStructureComponent
│   ├── GridUtilitiesComponent        ← Handles "t", "l", "d", etc.
│   ├── InfoBoardComponent            ← ADD THIS for "ib_*" types
│   └── GridInteractablesComponent
```

**In your GridSystem script:**

```gdscript
# grid_system.gd (or whatever loads map_data.json)
extends Node3D

@onready var structure_component = $GridStructureComponent
@onready var utilities_component = $GridUtilitiesComponent
@onready var info_board_component = $InfoBoardComponent  # ADD THIS

func load_map(map_data: Dictionary):
    var layers = map_data.get("layers", {})
    var utility_definitions = map_data.get("utility_definitions", {})

    # Load structure
    structure_component.generate_grid(layers.get("structure", []))

    # Initialize components
    var settings = {
        "cube_size": map_data.settings.get("cube_size", 1.0),
        "gutter": map_data.settings.get("gutter", 0.0)
    }

    utilities_component.initialize(self, structure_component, settings)
    info_board_component.initialize_with_structure(self, structure_component, settings)

    # Generate utilities and info boards from same layer
    var utilities_data = {"layout_data": layers.get("utilities", [])}

    utilities_component.generate_utilities(utilities_data, utility_definitions)
    info_board_component.generate_boards(utilities_data, utility_definitions)
```

---

### Option 2: If You Load Maps Dynamically

If you use `JsonMapLoader` or similar:

**Check:** `commons/managers/JsonMapLoader.gd`

You'll need to add info board generation alongside utility generation:

```gdscript
# In JsonMapLoader.gd (or equivalent)
func load_map_from_json(map_path: String):
    var map_data = load_json(map_path)

    # Create grid
    var grid_system = create_grid_system(map_data)

    # ADD: Create and initialize InfoBoardComponent
    var info_board_component = InfoBoardComponent.new()
    grid_system.add_child(info_board_component)

    var settings = get_map_settings(map_data)
    info_board_component.initialize_with_structure(
        grid_system,
        grid_system.structure_component,
        settings
    )

    # Generate boards
    var utilities_data = {"layout_data": map_data.layers.utilities}
    info_board_component.generate_boards(
        utilities_data,
        map_data.utility_definitions
    )
```

---

## 🎯 Register Info Board in UtilityRegistry (Alternative Approach)

If you want info boards to be handled **exactly like other utilities**, you can register them in `UtilityRegistry`:

**In `commons/grid/UtilityRegistry.gd`, add:**

```gdscript
const UTILITY_TYPES = {
    // ... existing utilities ...

    "ib_randomwalk": {
        "name": "random_walk_info_board",
        "file": "../../infoboards_3d/boards/RandomWalkInfoBoard.tscn",
        "category": "info_board",
        "description": "Random Walk algorithm info board",
        "supports_parameters": true
    },
    "ib_bfs": {
        "name": "bfs_info_board",
        "file": "../../infoboards_3d/boards/BFSInfoBoard.tscn",
        "category": "info_board",
        "description": "Breadth-First Search info board",
        "supports_parameters": true
    }
}
```

Then `GridUtilitiesComponent` will automatically handle them!

---

## 📐 Info Board Notation in JSON

### Basic Placement

```json
"utilities": [
    [" ", "ib_randomwalk", " "],  // Random Walk board at (1, 0)
    [" ", " ", "ib_bfs"],          // BFS board at (2, 1)
]
```

### With Height Offset

```json
"utilities": [
    ["ib_randomwalk:0.5", " ", " "],  // Raised 0.5m above ground
    [" ", "ib_bfs:1.0", " "],         // Raised 1.0m above ground
]
```

### With Custom Properties (via utility_definitions)

```json
"utility_definitions": {
    "ib_randomwalk": {
        "type": "info_board",
        "properties": {
            "category": "Randomness",
            "category_color": [0.8, 0.5, 0.9],
            "auto_advance": false
        }
    }
}
```

---

## 🔍 Debugging

### Check if InfoBoardComponent is initialized:

```gdscript
func _ready():
    print("Has InfoBoardComponent: ", has_node("InfoBoardComponent"))

    if has_node("InfoBoardComponent"):
        var ibc = $InfoBoardComponent
        print("Board count: ", ibc.get_board_count())
```

### Check Registry:

```gdscript
func _ready():
    # Verify registry knows about the board type
    print("Is valid: ", InfoBoardRegistry.is_valid_board_type("ib_randomwalk"))
    print("Scene path: ", InfoBoardRegistry.get_board_scene_path("ib_randomwalk"))
```

### Check Scene Paths:

Make sure the scene exists:
```
res://commons/infoboards_3d/boards/RandomWalkInfoBoard.tscn
```

---

## 🎨 Available Board Types

Currently registered:

| Type | Name | Category |
|------|------|----------|
| `ib_randomwalk` | Random Walk Info Board | Randomness |
| `ib_bfs` | BFS Info Board | Graph Theory |
| `ib_neural` | Neural Network Info Board | Machine Learning |
| `ib_sorting` | Sorting Algorithms Info Board | Algorithms |

Add more in: `InfoBoardRegistry.gd`

---

## ✅ Complete Example

**map_data.json:**
```json
{
    "layers": {
        "structure": [...],
        "utilities": [
            [" ", " ", " ", " ", "t"],
            [" ", "ib_randomwalk", " ", "ib_bfs", " "],
            [" ", " ", " ", " ", " "]
        ]
    },
    "utility_definitions": {
        "t": {...},
        "ib_randomwalk": {
            "type": "info_board",
            "properties": {
                "category": "Randomness"
            }
        },
        "ib_bfs": {
            "type": "info_board",
            "properties": {
                "category": "Graph Theory"
            }
        }
    }
}
```

**grid_system.gd:**
```gdscript
extends Node3D

@onready var structure = $GridStructureComponent
@onready var utilities = $GridUtilitiesComponent
@onready var info_boards = $InfoBoardComponent

func load_map(data: Dictionary):
    var settings = {
        "cube_size": 1.0,
        "gutter": 0.0
    }

    structure.generate_grid(data.layers.structure)

    utilities.initialize(self, structure, settings)
    info_boards.initialize_with_structure(self, structure, settings)

    var utility_data = {"layout_data": data.layers.utilities}
    utilities.generate_utilities(utility_data, data.utility_definitions)
    info_boards.generate_boards(utility_data, data.utility_definitions)
```

---

## 🚀 Next Steps

1. **Add InfoBoardComponent node** to your map scene
2. **Initialize it** in your map loader
3. **Test the map** - info board should appear at position (1, 1)
4. **Add more boards** to other maps as needed

---

**Questions?**
- Not sure where your map loader is? Search for files that load `map_data.json`
- Need help finding GridSystem? Look for scenes with GridStructureComponent
- Want to add more board types? Edit `InfoBoardRegistry.gd`

---

**Files Modified:**
- ✅ `commons/maps/Random_One/map_data.json` (added board to utilities)
- ⏳ Your map loader script (needs InfoBoardComponent initialization)
- ⏳ Your map scene (needs InfoBoardComponent node)

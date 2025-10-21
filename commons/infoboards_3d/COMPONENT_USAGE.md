# Info Board Component Usage Guide

This guide shows how to use the **InfoBoardComponent** to add info boards to your scenes using the same pattern as GridUtilitiesComponent.

## 🎯 Why Use the Component Pattern?

✅ **Consistent** - Same pattern as other utilities (teleports, lifts, etc.)
✅ **Flexible** - Place boards in grids OR at arbitrary positions
✅ **Organized** - All board logic in one component
✅ **Reusable** - Add to any scene with minimal code
✅ **Signals** - Get notifications when boards are interacted with

---

## 📋 Quick Start

### Method 1: Component Pattern (Recommended)

**Step 1: Add Component to Your Scene**

```gdscript
# your_scene.gd
extends Node3D

@onready var info_board_component: InfoBoardComponent = $InfoBoardComponent

func _ready():
    setup_info_boards()
```

**Step 2: Add Node in Scene Tree**

In Godot Editor:
1. Add a `Node` to your scene
2. Rename it to "InfoBoardComponent"
3. Attach script: `res://commons/infoboards_3d/content/InfoBoardComponent.gd`

**Step 3: Initialize and Generate**

```gdscript
func setup_info_boards():
    # Configure settings
    var settings = {
        "cube_size": 2.0,      # 2m between grid positions
        "gutter": 0.5,         # 0.5m spacing
        "default_height": 1.5  # Boards at 1.5m height
    }

    # Initialize component
    info_board_component.initialize(self, settings)

    # Connect signals (optional)
    info_board_component.board_generation_complete.connect(_on_boards_generated)
    info_board_component.board_interacted.connect(_on_board_interacted)

    # Generate boards from layout
    var layout = [
        [" ", " ", " "],
        [" ", "ib_randomwalk", " "],
        [" ", " ", " "]
    ]

    info_board_component.generate_boards(layout)

func _on_boards_generated(count: int):
    print("Generated %d boards!" % count)

func _on_board_interacted(board_type: String, position: Vector3, data: Dictionary):
    print("Board '%s' interacted!" % board_type)
```

---

## 📐 Grid Layout Format

Define board positions using a 2D array:

```gdscript
var board_layout = [
    #  X: 0                1                  2                  3
    [" ",              " ",                " ",               " "        ],  # Z: 0
    [" ",              "ib_randomwalk",    " ",               " "        ],  # Z: 1
    [" ",              " ",                "ib_bfs",          " "        ],  # Z: 2
    [" ",              " ",                " ",               "ib_neural"]   # Z: 3
]
```

**Notation:**
- `" "` = Empty space
- `"ib_randomwalk"` = Random Walk board
- `"ib_randomwalk:0.5"` = Random Walk board with 0.5m height offset
- `"ib_bfs"` = Breadth-First Search board

---

## 🎨 Board Definitions (Optional)

Customize board properties:

```gdscript
var board_definitions = {
    "ib_randomwalk": {
        "properties": {
            "category": "Randomness",
            "auto_advance": false,
            "category_color": Color(0.8, 0.5, 0.9)
        }
    },
    "ib_bfs": {
        "properties": {
            "category": "Graph Theory",
            "category_color": Color(0.3, 0.8, 0.5)
        }
    }
}

info_board_component.generate_boards(layout, board_definitions)
```

---

## 📍 Placing Individual Boards

Instead of using a grid, place boards at specific positions:

```gdscript
# Place a single board at position
var board = info_board_component.place_board_at(
    "ib_randomwalk",           # Board type
    Vector3(5, 1.5, 0),        # Position
    [],                        # Parameters (optional)
    {}                         # Definition (optional)
)
```

---

## 🔌 Signals

### `board_generation_complete(board_count: int)`

Emitted when all boards have been generated.

```gdscript
info_board_component.board_generation_complete.connect(func(count):
    print("Generated %d boards" % count)
)
```

### `board_interacted(board_type: String, position: Vector3, data: Dictionary)`

Emitted when a board is interacted with (page changed, etc.).

```gdscript
info_board_component.board_interacted.connect(func(type, pos, data):
    print("Board type: %s" % type)
    print("Page: %d" % data.get("page_index", 0))
)
```

---

## 🎮 Available Board Types

Currently registered board types (from InfoBoardRegistry):

| Type | Name | Category | Description |
|------|------|----------|-------------|
| `ib_randomwalk` | Random Walk Info Board | Randomness | Random walk algorithms |
| `ib_bfs` | BFS Info Board | Graph Theory | Breadth-First Search |
| `ib_neural` | Neural Network Info Board | Machine Learning | Neural network fundamentals |
| `ib_sorting` | Sorting Algorithms Info Board | Algorithms | Sorting algorithm comparison |

**Add more in:** `commons/infoboards_3d/content/InfoBoardRegistry.gd`

---

## 🔧 Advanced Usage

### With Grid Structure Component

If you have a GridStructureComponent (for grid-based worlds):

```gdscript
@onready var structure_component: GridStructureComponent = $GridStructureComponent
@onready var info_board_component: InfoBoardComponent = $InfoBoardComponent

func setup():
    # Initialize with structure component
    var settings = {
        "cube_size": structure_component.cube_size,
        "gutter": structure_component.gutter
    }

    info_board_component.initialize_with_structure(
        self,
        structure_component,
        settings
    )

    # Boards will automatically find correct height from grid
    info_board_component.generate_boards(layout)
```

### Dynamic Board Placement

Add boards during gameplay:

```gdscript
func spawn_board_at_player():
    var player_pos = $Player.global_position
    var spawn_pos = player_pos + Vector3(2, 0, 0)  # 2m to the right

    info_board_component.place_board_at("ib_randomwalk", spawn_pos)
```

### Query Boards

```gdscript
# Check if board exists at grid position
if info_board_component.has_board_at(1, 1, 1):
    print("Board exists at (1,1,1)")

# Get board at position
var board = info_board_component.get_board_at(1, 1, 1)
if board:
    print("Found board: %s" % board.name)

# Get all board positions
var positions = info_board_component.get_all_board_positions()
print("Total boards: %d" % positions.size())
```

---

## 📝 Complete Example

See `example_component_scene.tscn` for a working example.

```gdscript
# complete_example.gd
extends Node3D

@onready var info_board_component: InfoBoardComponent = $InfoBoardComponent

var board_layout = [
    [" ", " ", " ", " ", " "],
    [" ", "ib_randomwalk", " ", "ib_bfs", " "],
    [" ", " ", " ", " ", " "],
    [" ", "ib_neural", " ", "ib_sorting", " "],
    [" ", " ", " ", " ", " "]
]

func _ready():
    # Setup
    info_board_component.initialize(self, {
        "cube_size": 3.0,
        "default_height": 1.5
    })

    # Connect signals
    info_board_component.board_generation_complete.connect(_on_boards_ready)
    info_board_component.board_interacted.connect(_on_board_used)

    # Generate
    info_board_component.generate_boards(board_layout)

func _on_boards_ready(count: int):
    print("Info board gallery ready with %d boards!" % count)

func _on_board_used(type: String, pos: Vector3, data: Dictionary):
    # Award XP for reading
    if data.get("page_index", 0) > 0:
        GameManager.add_xp(10)
        print("Earned 10 XP for learning!")
```

---

## 🆚 Component vs Direct Instantiation

### Component Pattern (✅ Recommended)
```gdscript
# Add InfoBoardComponent node to scene
@onready var boards = $InfoBoardComponent

func _ready():
    boards.initialize(self, {})
    boards.generate_boards(layout)
```

**Pros:** Clean, organized, consistent with other systems

### Direct Instantiation
```gdscript
func _ready():
    var board = preload("res://commons/infoboards_3d/boards/RandomWalkInfoBoard.tscn").instantiate()
    board.position = Vector3(0, 1.5, 0)
    add_child(board)
```

**Pros:** Simple for single boards
**Cons:** More code for multiple boards, no grid support

---

## 🎯 Best Practices

1. **Use component for multiple boards** - Grid layouts, galleries, collections
2. **Use direct instantiation for single boards** - One-off placements
3. **Connect signals** - Track user interaction for XP/progression
4. **Set category colors** - Visual consistency across your game
5. **Test in example scene** - Verify boards work before adding to main scenes

---

## 🔗 Related Files

- `InfoBoardComponent.gd` - Main component script
- `InfoBoardRegistry.gd` - Board type definitions
- `example_component_scene.tscn` - Working example
- `README.md` - Full documentation

---

**Created**: 2025-10-20
**Pattern**: Same as GridUtilitiesComponent
**Compatible**: Godot 4.x

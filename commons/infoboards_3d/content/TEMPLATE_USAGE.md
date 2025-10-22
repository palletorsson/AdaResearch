# Universal InfoBoard Template Usage

## Overview

The **UniversalInfoBoard** is a single template script that can display ANY InfoBoard by simply setting the `board_id`. No need for separate scripts for each board!

## The Big Improvement

### Before (Old Way)
```
boards/
├── Point/PointInfoBoard.gd           # 200+ lines
├── Line/LineInfoBoard.gd             # 200+ lines (same code!)
├── Triangle/TriangleInfoBoard.gd     # 200+ lines (same code!)
└── RandomWalk/RandomWalkInfoBoard.gd # 200+ lines (same code!)
```

### After (New Way)
```
base/UniversalInfoBoard.gd            # ONE script for ALL boards
```

Just set `board_id` and it loads the right content from JSON!

## Three Ways to Use It

### Method 1: In the Inspector (Easiest)

1. Create a scene with the InfoBoard UI layout
2. Attach `UniversalInfoBoard.gd` to the root Control node
3. In the Inspector, set `Board Id` to your board:
   - `"point"` for Point InfoBoard
   - `"line"` for Line InfoBoard
   - `"triangle"` for Triangle InfoBoard
   - etc.

Done! The board will automatically load content from JSON.

### Method 2: Via Code (Dynamic)

```gdscript
# Create InfoBoard and set board_id
var info_board = preload("res://commons/infoboards_3d/base/UniversalInfoBoard.tscn").instantiate()
info_board.board_id = "triangle"  # Which board to show
add_child(info_board)

# That's it! Content loads automatically
```

### Method 3: Switch Boards at Runtime

```gdscript
# Start with Point board
var info_board = preload("res://commons/infoboards_3d/base/UniversalInfoBoard.tscn").instantiate()
info_board.board_id = "point"
add_child(info_board)

# Later, switch to Line board
info_board.switch_to_board("line")

# Now showing Line content!
```

## Creating Board-Specific Scenes

If you want a dedicated scene for each board (for easy instantiation):

### Point InfoBoard Scene
```gdscript
# boards/Point/PointInfoBoard.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" path="res://commons/infoboards_3d/base/InfoBoardUI.tscn" id="1"]
[ext_resource type="Script" path="res://commons/infoboards_3d/base/UniversalInfoBoard.gd" id="2"]

[node name="PointInfoBoard" instance=ExtResource("1")]
script = ExtResource("2")
board_id = "point"  # Set the board ID here
```

Then use it:
```gdscript
var point_board = preload("res://commons/infoboards_3d/boards/Point/PointInfoBoard.tscn").instantiate()
add_child(point_board)
```

## Adding a New InfoBoard

To add a completely new InfoBoard, you just need:

### 1. Add Content to JSON
```json
"meshes": {
  "board_id": "meshes",
  "title": "Meshes",
  "subtitle": "Surfaces from Triangles",
  "category": "Fundamentals",
  "order": 4,
  "description": "How triangles combine to create complex surfaces",
  "pages": [
    {
      "page_number": 1,
      "title": "What is a Mesh?",
      "text": ["A mesh is a collection of triangles..."],
      "visualization": "mesh_intro",
      "concepts": ["mesh", "vertices", "faces"]
    }
  ]
}
```

### 2. Create Visualization Scene (Optional)
```
boards/Meshes/MeshesVisualizationControl.tscn
```

### 3. Use It!
```gdscript
var mesh_board = UniversalInfoBoard.new()
mesh_board.board_id = "meshes"
add_child(mesh_board)
```

**That's it! No GDScript needed!**

## API Reference

### Properties

```gdscript
@export var board_id: String = "point"
# Which board to load (matches JSON key)

@export var auto_load_on_ready: bool = true
# Load content automatically when _ready() is called
```

### Methods

```gdscript
# Load a specific board
func load_board(new_board_id: String) -> bool

# Switch to different board at runtime
func switch_to_board(new_board_id: String) -> bool

# Get current board ID
func get_current_board_id() -> String

# Get current page number (0-indexed)
func get_current_page_number() -> int

# Get total number of pages
func get_total_pages() -> int

# Get board metadata
func get_board_metadata() -> Dictionary
```

### Example: Board Switcher UI

```gdscript
extends Control

@onready var info_board = $UniversalInfoBoard
@onready var board_selector = $BoardSelector  # OptionButton

func _ready():
    # Populate selector with all available boards
    var boards = InfoBoardContentLoader.get_all_board_ids()
    for board_id in boards:
        var meta = InfoBoardContentLoader.get_board_meta(board_id)
        board_selector.add_item(meta.title)
        board_selector.set_item_metadata(board_selector.item_count - 1, board_id)

    board_selector.item_selected.connect(_on_board_selected)

func _on_board_selected(index: int):
    var selected_board_id = board_selector.get_item_metadata(index)
    info_board.switch_to_board(selected_board_id)
    print("Switched to: %s" % selected_board_id)
```

## Visualization Scene Convention

The template automatically looks for visualization scenes at:

```
res://commons/infoboards_3d/boards/{Capitalized}/{Capitalized}VisualizationControl.tscn
```

Examples:
- `board_id = "point"` → `boards/Point/PointVisualizationControl.tscn`
- `board_id = "line"` → `boards/Line/LineVisualizationControl.tscn`
- `board_id = "triangle"` → `boards/Triangle/TriangleVisualizationControl.tscn`

If your visualization scene is elsewhere, override `get_visualization_scene_path()`.

## Custom Visualization Path

```gdscript
extends UniversalInfoBoard

func get_visualization_scene_path(board_id_param: String) -> String:
    # Custom path logic
    match board_id_param:
        "myboard":
            return "res://custom/path/MyVis.tscn"
        _:
            return super(board_id_param)  # Use default
```

## Migration from Old InfoBoard Scripts

### Before
```gdscript
# PointInfoBoard.gd
extends Control

const BOARD_ID = "point"
var page_content = [
    {
        "title": "...",
        "text": ["..."],
        "visualization": "..."
    }
]
# ... 200 lines of UI logic ...
```

### After
Just use UniversalInfoBoard with `board_id = "point"`

Delete the old script! All content is now in JSON.

## Benefits

✅ **Zero Code for New Boards** - Just add JSON
✅ **Single Source of Truth** - All content in one file
✅ **Easy Maintenance** - One script to update, not many
✅ **Runtime Board Switching** - Change boards dynamically
✅ **Consistent Behavior** - All boards work the same
✅ **Less Duplication** - No repeated UI code

## Complete Example

```gdscript
# Create an InfoBoard gallery
extends Node3D

func _ready():
    create_board_at_position("point", Vector3(-2, 1.5, 0))
    create_board_at_position("line", Vector3(0, 1.5, 0))
    create_board_at_position("triangle", Vector3(2, 1.5, 0))

func create_board_at_position(board_id: String, pos: Vector3):
    # Create 3D InfoBoard wrapper
    var board_3d = preload("res://commons/infoboards_3d/base/HandheldInfoBoard.tscn").instantiate()
    board_3d.position = pos

    # Get the UI viewport and set our universal template
    var ui = board_3d.get_node("BoardFrame/TabletFrame/Viewport2Din3D/Viewport/InfoBoardUI")
    var template = preload("res://commons/infoboards_3d/base/UniversalInfoBoard.gd")
    ui.set_script(template)
    ui.board_id = board_id

    add_child(board_3d)
```

## Updating InfoBoardComponent

Update `InfoBoardComponent.gd` to use the universal template:

```gdscript
func create_info_board(board_type: String) -> Node3D:
    var board_3d = preload("res://commons/infoboards_3d/base/HandheldInfoBoard.tscn").instantiate()

    # Set up the universal template
    var ui = board_3d.get_node("BoardFrame/TabletFrame/Viewport2Din3D/Viewport/InfoBoardUI")
    var template = preload("res://commons/infoboards_3d/base/UniversalInfoBoard.gd")
    ui.set_script(template)
    ui.board_id = board_type  # "point", "line", etc.

    return board_3d
```

Now your component system automatically works with ANY board defined in JSON!

---

**The Universal Template + Centralized JSON = Complete Separation of Content and Code**

Add new educational content by editing JSON only. No code needed!

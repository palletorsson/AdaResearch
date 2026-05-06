# How to Load InfoBoards - Quick Reference

## 🚀 Simplest Way (After updating .tscn files)

### Load Line InfoBoard
```gdscript
var line_board = preload("res://commons/infoboards_3d/boards/Line/LineInfoBoard.tscn").instantiate()
add_child(line_board)
```

### Load Triangle InfoBoard
First, update the Triangle scene file the same way I updated Line:

**In `boards/Triangle/TriangleInfoBoard.tscn`** (if it exists), change:
- Script path to: `res://commons/infoboards_3d/base/UniversalInfoBoard.gd`
- Add: `board_id = "triangle"`

Then:
```gdscript
var triangle_board = preload("res://commons/infoboards_3d/boards/Triangle/TriangleInfoBoard.tscn").instantiate()
add_child(triangle_board)
```

### Load Point InfoBoard
Same process - update the scene file, then:
```gdscript
var point_board = preload("res://commons/infoboards_3d/boards/Point/PointInfoBoard.tscn").instantiate()
add_child(point_board)
```

---

## 🔧 If Scene Files Don't Exist Yet

Use the helper function approach:

```gdscript
func create_info_board(board_id: String, position: Vector3 = Vector3.ZERO) -> Node3D:
    var board_3d = preload("res://commons/infoboards_3d/base/HandheldInfoBoard.tscn").instantiate()

    var ui = board_3d.get_node("BoardFrame/TabletFrame/Viewport2Din3D/Viewport/InfoBoardUI")
    ui.set_script(preload("res://commons/infoboards_3d/base/UniversalInfoBoard.gd"))
    ui.board_id = board_id

    board_3d.position = position
    add_child(board_3d)
    return board_3d

# Then use it:
func _ready():
    create_info_board("line", Vector3(-2, 1.5, 0))
    create_info_board("triangle", Vector3(0, 1.5, 0))
    create_info_board("point", Vector3(2, 1.5, 0))
```

---

## 📋 All Available Board IDs

From `infoboard_content.json`:

```gdscript
"point"       # The Point - The Atom of Space (5 pages)
"line"        # The Line - Connecting Points (5 pages)
"triangle"    # The Triangle - The First Surface (5 pages)
"randomwalk"  # Random Walk - Exploring Through Chance (1 page)
```

---

## 🎨 Create a Gallery

Display all fundamental boards in a row:

```gdscript
func create_fundamentals_gallery():
    var boards = ["point", "line", "triangle"]
    var x = -3.0

    for board_id in boards:
        create_info_board(board_id, Vector3(x, 1.5, 0))
        x += 3.0  # Space them 3 meters apart
```

---

## 🔄 Switch Boards Dynamically

```gdscript
var board: Node3D

func _ready():
    # Start with Line
    board = create_info_board("line", Vector3(0, 1.5, 0))

func switch_to_triangle():
    var ui = board.get_node("SubViewport/InfoBoardUI")
    ui.switch_to_board("triangle")
    print("Now showing Triangle!")
```

---

## 🗺️ Load from Map/Grid System

If you're using InfoBoardComponent:

```gdscript
# In your map JSON
{
  "utilities": [
    ["ib:line", "ib:triangle", "ib:point"]
  ]
}
```

Update InfoBoardComponent to use universal template:

```gdscript
# In InfoBoardComponent.gd
func create_board(board_type: String) -> Node3D:
    var board_3d = preload("res://commons/infoboards_3d/base/HandheldInfoBoard.tscn").instantiate()

    var ui = board_3d.get_node("BoardFrame/TabletFrame/Viewport2Din3D/Viewport/InfoBoardUI")
    ui.set_script(preload("res://commons/infoboards_3d/base/UniversalInfoBoard.gd"))
    ui.board_id = board_type  # "line", "triangle", etc.

    return board_3d
```

---

## 📖 Get Board Info Before Loading

```gdscript
# Check what's in a board before loading
var meta = InfoBoardContentLoader.get_board_meta("triangle")
print("Title: %s" % meta.title)           # "The Triangle"
print("Subtitle: %s" % meta.subtitle)     # "The First Surface"
print("Pages: %d" % InfoBoardContentLoader.get_page_count("triangle"))  # 5
```

---

## ⚡ Complete Working Example

Copy-paste ready code:

```gdscript
extends Node3D

func _ready():
    load_all_fundamental_boards()

func load_all_fundamental_boards():
    # Line InfoBoard
    var line = create_board("line", Vector3(-2, 1.5, 0))

    # Triangle InfoBoard
    var triangle = create_board("triangle", Vector3(0, 1.5, 0))

    # Point InfoBoard
    var point = create_board("point", Vector3(2, 1.5, 0))

func create_board(board_id: String, pos: Vector3) -> Node3D:
    var board_3d = preload("res://commons/infoboards_3d/base/HandheldInfoBoard.tscn").instantiate()

    var ui = board_3d.get_node("BoardFrame/TabletFrame/Viewport2Din3D/Viewport/InfoBoardUI")
    ui.set_script(preload("res://commons/infoboards_3d/base/UniversalInfoBoard.gd"))
    ui.board_id = board_id

    board_3d.position = pos
    add_child(board_3d)
    return board_3d
```

Save this as a new scene, press F5, and you'll see all three boards!

---

## 🎯 Next Steps

1. **Update existing .tscn files** to use UniversalInfoBoard.gd
2. **Try the example** above to see boards load
3. **Add more boards** to JSON and load them the same way

All boards work identically - just change the `board_id`!

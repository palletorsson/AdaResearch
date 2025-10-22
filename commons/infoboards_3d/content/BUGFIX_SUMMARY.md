# InfoBoard Integration Bugfixes

## Issue Reported
User tried `ib:triangle` syntax in `res://commons/maps/Point_Triangle_1_1/map_data.json` but the InfoBoard did not appear.

## Root Causes Found

### 1. Missing Triangle Registration
**Problem:** The InfoBoardRegistry had `point` and `line` registered, but was missing `triangle`.

**Location:** `commons/infoboards_3d/content/InfoBoardRegistry.gd`

**Fix:** Added triangle to the INFO_BOARD_TYPES dictionary:
```gdscript
"triangle": {
    "name": "Triangle Info Board",
    "category": "Fundamentals",
    "scene": "Triangle/TriangleInfoBoard.tscn",
    "description": "The first surface - triangles, planes, and mesh fundamentals",
    "color": Color(0.9, 0.3, 0.9),
    "supports_parameters": true
}
```

### 2. Incorrect Node Path to InfoBoardUI
**Problem:** Code was looking for `"SubViewport/InfoBoardUI"` but the actual path in HandheldInfoBoard.tscn is much deeper.

**Actual Structure:**
```
HandheldInfoBoard (root)
└── BoardFrame
    └── TabletFrame
        └── Viewport2Din3D (from godot-xr-tools)
            └── Viewport (SubViewport, created by Viewport2Din3D)
                └── InfoBoardUI (the UI scene content)
```

**Correct Path:** `"BoardFrame/TabletFrame/Viewport2Din3D/Viewport/InfoBoardUI"`

**Files Fixed:**
1. `commons/grid/GridUtilitiesComponent.gd` (line 784)
2. `commons/infoboards_3d/content/InfoBoardComponent.gd` (line 125)
3. `commons/infoboards_3d/content/HOW_TO_LOAD_BOARDS.md` (documentation)
4. `commons/infoboards_3d/content/TEMPLATE_USAGE.md` (documentation)
5. `commons/infoboards_3d/examples/load_boards_example.gd` (examples)

## Testing the Fix

### Try This in Your Map
In `commons/maps/Point_Triangle_1_1/map_data.json`:
```json
{
  "layers": {
    "utilities": [
      [" ", " ", "ib:triangle", " ", " "]
    ]
  }
}
```

### Expected Console Output
```
InfoBoardContentLoader: Loaded content for 4 boards
GridUtilitiesComponent: Generating utilities
GridUtilitiesComponent: Created 'triangle' InfoBoard using UniversalTemplate (Content: 5 pages)
GridUtilitiesComponent: Placed triangle info board at (...) (height offset: 0.0)
```

### What You Should See
- A handheld 3D tablet at the specified grid position
- Triangle InfoBoard content with 5 pages
- Navigation buttons to move between pages
- Content from `infoboard_content.json`

## Available InfoBoard IDs

Now working in maps:
```
ib:point        # The Point - The Atom of Space (5 pages)
ib:line         # The Line - Connecting Points (5 pages)
ib:triangle     # The Triangle - The First Surface (5 pages)
ib:randomwalk   # Random Walk - Exploring Through Chance (1 page)
```

## Syntax Examples

### Basic
```json
"ib:triangle"
```

### With Height Offset
```json
"ib:triangle:0.5"   // Raise 0.5m
"ib:triangle:-0.3"  // Lower 0.3m
```

## Technical Details

### Why the Path Was Wrong
The original implementation assumed `SubViewport` was a direct child of the root, but:
1. HandheldInfoBoard.tscn inherits from Viewport2Din3D
2. Viewport2Din3D creates a Viewport (SubViewport) child
3. The scene property is instantiated INSIDE that Viewport
4. So the full path from root requires going through the frame structure

### How the Universal Template Works
1. GridUtilitiesComponent detects `ib:triangle` in utilities layer
2. Validates that "triangle" is registered in InfoBoardRegistry
3. Calls `_create_info_board_with_universal_template("triangle")`
4. Loads HandheldInfoBoard.tscn base scene
5. Gets the InfoBoardUI node using the correct path
6. Replaces its script with UniversalInfoBoard.gd
7. Sets `board_id = "triangle"`
8. UniversalInfoBoard loads content from `infoboard_content.json`
9. InfoBoard appears in 3D world with all content

## Status
✅ Triangle registered in InfoBoardRegistry
✅ Node paths corrected in all code files
✅ Documentation updated with correct paths
✅ Example code updated

The `ib:triangle` syntax should now work correctly in your maps!

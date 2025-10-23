# Universal InfoBoard System

A flexible, JSON-driven InfoBoard system for displaying educational content with visualizations in VR.

## Overview

The Universal InfoBoard system has been refactored to use **one main scene** (`UniversalInfoBoard.tscn`) that loads content dynamically from JSON. Each slide has a unique ID for precise control.

## Three Display Modes

### 1. SINGLE_SLIDE Mode
Display **one specific slide** without navigation. Perfect for embedding specific content in different scenes.

**Usage:**
```gdscript
var infoboard = UniversalInfoBoard.new()
infoboard.display_mode = UniversalInfoBoard.DisplayMode.SINGLE_SLIDE
infoboard.slide_id = "line_3"  # Show only the "Line Direction and Magnitude" slide
infoboard.auto_load_on_ready = true
add_child(infoboard)
```

**Or via Inspector:**
- Set `Display Mode` → `SINGLE_SLIDE`
- Set `Slide Id` → `"line_3"`

### 2. SINGLE_BOARD Mode (Default)
Display **all pages from one board** with prev/next navigation. This is the original behavior.

**Usage:**
```gdscript
var infoboard = UniversalInfoBoard.new()
infoboard.display_mode = UniversalInfoBoard.DisplayMode.SINGLE_BOARD
infoboard.board_id = "triangle"  # Show all triangle slides
infoboard.auto_load_on_ready = true
add_child(infoboard)
```

**Or via Inspector:**
- Set `Display Mode` → `SINGLE_BOARD`
- Set `Board Id` → `"triangle"`

### 3. ALL_SLIDES Mode
Display **all slides across all boards** with navigation. Perfect for debugging and overview.

**Usage:**
```gdscript
var infoboard = UniversalInfoBoard.new()
infoboard.display_mode = UniversalInfoBoard.DisplayMode.ALL_SLIDES
infoboard.auto_load_on_ready = true
add_child(infoboard)
```

**Or via Inspector:**
- Set `Display Mode` → `ALL_SLIDES`

## Slide ID Format

Each slide has a unique ID following the pattern: `<board>_<number>`

Examples:
- `point_1` - First slide about points
- `point_2` - Second slide about points
- `line_1` - First slide about lines
- `line_3` - Third slide about lines
- `triangle_5` - Fifth slide about triangles
- `randomwalk_1` - First slide about random walks

## Content Structure (JSON)

Location: `res://commons/infoboards_3d/content/infoboard_content.json`

```json
{
  "boards": {
    "point": {
      "board_id": "point",
      "title": "The Point",
      "pages": [
        {
          "slide_id": "point_1",
          "page_number": 1,
          "title": "The Point: The Atom of Space",
          "text": [
            "Content here..."
          ],
          "visualization": "origin",
          "concepts": ["Vector3", "position"]
        }
      ]
    }
  }
}
```

## API Reference

### Loading Methods

```gdscript
# Load a single slide
infoboard.load_slide("line_3")

# Load a single board
infoboard.load_board("triangle")

# Load all slides
infoboard.load_all_slides()
```

### InfoBoardContentLoader Static Methods

```gdscript
# Get a specific slide by ID
var slide = InfoBoardContentLoader.get_slide_by_id("point_2")

# Get all slides from a board
var pages = InfoBoardContentLoader.get_pages("line")

# Get all slides across all boards
var all_slides = InfoBoardContentLoader.get_all_slides()

# Get slide IDs for a board
var slide_ids = InfoBoardContentLoader.get_slide_ids("triangle")

# Get all slide IDs
var all_ids = InfoBoardContentLoader.get_all_slide_ids()
```

## Example Use Cases

### Case 1: Specific Scene Shows Specific Slide
```gdscript
# In your TesseractTunnel scene, show only line_4 about cylinders
var infoboard = preload("res://commons/infoboards_3d/base/UniversalInfoBoard.tscn").instantiate()
infoboard.display_mode = UniversalInfoBoard.DisplayMode.SINGLE_SLIDE
infoboard.slide_id = "line_4"
add_child(infoboard)
```

### Case 2: Debug/Overview Mode
```gdscript
# Create an overview board showing all slides
var overview = preload("res://commons/infoboards_3d/base/UniversalInfoBoard.tscn").instantiate()
overview.display_mode = UniversalInfoBoard.DisplayMode.ALL_SLIDES
add_child(overview)
# User can now navigate through ALL slides from ALL boards
```

### Case 3: Dynamic Content Switching
```gdscript
# Start with one slide, then switch to another
var infoboard = UniversalInfoBoard.new()
infoboard.load_slide("point_1")
add_child(infoboard)

# Later, switch to a different slide
infoboard.load_slide("triangle_3")

# Or switch to show entire board
infoboard.load_board("line")
```

## File Structure

```
commons/infoboards_3d/
├── base/
│   ├── UniversalInfoBoard.gd         # Main controller (refactored)
│   ├── UniversalInfoBoard.tscn       # Universal scene template
│   └── AlgorithmInfoBoardBase.gd     # Base for custom boards
├── boards/
│   ├── Point/
│   │   └── PointVisualizationControl.tscn
│   ├── Line/
│   │   └── LineVisualizationControl.tscn
│   └── Triangle/
│       └── TriangleVisualizationControl.tscn
├── content/
│   ├── infoboard_content.json        # All content (with slide_ids)
│   └── InfoBoardContentLoader.gd     # Loader (with slide_id support)
└── README_UniversalInfoBoard.md      # This file
```

## Benefits of This System

1. **One Scene, Multiple Uses**: Single `UniversalInfoBoard` scene works for all cases
2. **Precise Control**: Target exact slides with `slide_id`
3. **Easy Debugging**: `ALL_SLIDES` mode lets you see everything
4. **JSON-Driven**: All content in one place
5. **Flexible**: Switch modes and content at runtime
6. **No Duplication**: Reuse same visualization scenes

## Migration Guide

**Before:**
```gdscript
# Had to create separate scene instances for different boards
var point_board = preload("res://commons/infoboards_3d/boards/Point/PointInfoBoard.tscn").instantiate()
```

**After:**
```gdscript
# One universal scene, configure with properties
var infoboard = preload("res://commons/infoboards_3d/base/UniversalInfoBoard.tscn").instantiate()
infoboard.board_id = "point"  # or use slide_id for single slide
```

## Notes

- Navigation buttons automatically hide in `SINGLE_SLIDE` mode
- In `ALL_SLIDES` mode, titles show board context: `[Line] Drawing Lines`
- Visualizations load based on parent board_id
- Content is cached for performance

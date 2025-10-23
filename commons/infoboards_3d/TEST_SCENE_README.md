# Test Universal InfoBoard Scene

## Location
`res://commons/infoboards_3d/test_universal_infoboard_2d.tscn`

## What It Does
A simple 2D test scene that lets you flip through all InfoBoard slides using the new Universal InfoBoard system.

## How to Run

1. **Open in Godot**: Open the scene file in Godot Editor
2. **Press F6** or click "Run Current Scene"
3. **Use the controls** to navigate

## Controls

### Mouse
- Click **PREVIOUS** / **NEXT** buttons to navigate slides

### Keyboard
- **LEFT/RIGHT Arrow Keys** - Navigate between slides
- **ESC** - Exit the test scene
- **1** - Switch to SINGLE_SLIDE mode (shows only "line_3")
- **2** - Switch to SINGLE_BOARD mode (shows all "triangle" slides)
- **3** - Switch to ALL_SLIDES mode (shows all slides from all boards)
- **D** - Print debug info about current slide to console

## What You'll See

The test scene starts in **ALL_SLIDES** mode, which means:
- You can browse through ALL slides from ALL boards
- Slide titles show board context: `[Line] Drawing Lines`
- Visualizations load automatically based on each slide's parent board
- You can navigate through all 16 slides (point_1 through randomwalk_1)

## Testing Different Modes

Press the number keys to test different display modes:

### Mode 1: SINGLE_SLIDE (Press 1)
- Shows only one slide: "line_3" (Line Direction and Magnitude)
- Navigation buttons are hidden
- Perfect for embedding specific content in scenes

### Mode 2: SINGLE_BOARD (Press 2)
- Shows all slides from the "triangle" board
- Navigation between triangle_1 through triangle_5
- This is the traditional board view

### Mode 3: ALL_SLIDES (Press 3)
- Returns to showing all slides from all boards
- Great for debugging and overview

## Console Output

The test scene prints useful information to the console:
- Available controls
- Mode switching confirmations
- Debug info when pressing 'D'

## What's Being Tested

This scene validates:
1. ✓ JSON content loading with slide_ids
2. ✓ Dynamic switching between display modes
3. ✓ Visualization loading per slide
4. ✓ Navigation functionality
5. ✓ Text content rendering from JSON

## Available Slides

Current slides in the system:
- **point_1** to **point_5** (5 slides)
- **line_1** to **line_5** (5 slides)
- **triangle_1** to **triangle_5** (5 slides)
- **randomwalk_1** (1 slide)

**Total: 16 slides**

## Notes

- Content is loaded from `res://commons/infoboards_3d/content/infoboard_content.json`
- Visualizations are loaded from `res://commons/infoboards_3d/boards/{BoardName}/{BoardName}VisualizationControl.tscn`
- The scene uses the Universal InfoBoard system, so only ONE scene file works for all content

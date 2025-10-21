# Handheld 3D Info Boards for AdaResearch

A system for creating grabbable, interactive 3D info boards with scrollable content and live visualizations for algorithm education.

## 🎯 Features

- **Handheld & Grabbable**: Physical tablet-like objects in VR/3D space
- **Multi-Page Content**: Navigate through educational content with Previous/Next buttons
- **Interactive Visualizations**: Live algorithm demos that update in real-time
- **Scrollable Text**: Rich text content with proper formatting
- **Animation Controls**: Play/Pause buttons for visualizations
- **Category Theming**: Color-coded by algorithm category
- **3D Visual Effects**: Holographic screen glow and frame lighting

## 🎮 Two Ways to Use Info Boards

### Method 1: Component Pattern (⭐ Recommended)

Add info boards using the **InfoBoardComponent** - same pattern as GridUtilitiesComponent:

```gdscript
@onready var info_board_component: InfoBoardComponent = $InfoBoardComponent

func _ready():
    info_board_component.initialize(self, {"default_height": 1.5})

    var layout = [
        [" ", "ib_randomwalk", " "],
        [" ", " ", "ib_bfs"]
    ]

    info_board_component.generate_boards(layout)
```

**See:** `COMPONENT_USAGE.md` for full guide

### Method 2: Direct Instantiation

For single boards or custom placement:

```gdscript
var board = preload("res://commons/infoboards_3d/boards/RandomWalkInfoBoard.tscn").instantiate()
board.position = Vector3(0, 1.5, 0)
add_child(board)
```

---

## 📁 File Structure

```
commons/infoboards_3d/
├── base/
│   ├── AlgorithmInfoBoardBase.gd        # Base controller for all boards
│   ├── AlgorithmVisualizationBase.gd    # Base class for visualizations
│   ├── InfoBoardUI.tscn                 # 2D UI layout template
│   └── HandheldInfoBoard.tscn           # 3D handheld tablet wrapper
├── content/
│   ├── InfoBoardComponent.gd            # Component for placing boards
│   └── InfoBoardRegistry.gd             # Registry of board types
├── visualizations/
│   └── RandomWalkVisualization.gd       # Example: Random Walk viz
├── boards/
│   ├── RandomWalkInfoBoard.gd           # Example: Random Walk content
│   └── RandomWalkInfoBoard.tscn         # Example: Instantiated board
├── test_infoboard_scene.tscn            # Demo/test scene
├── example_component_scene.tscn         # Component usage example
├── README.md                            # This file
└── COMPONENT_USAGE.md                   # Component pattern guide
```

## 🚀 Quick Start

### Testing the Example

1. Open `test_infoboard_scene.tscn` in Godot
2. Run the scene (F5)
3. You should see a floating tablet with Random Walk content
4. If using VR mode, grab the tablet to move it around
5. Click Previous/Next to navigate pages

### Creating a New Info Board

#### Step 1: Create a Visualization (Optional)

```gdscript
# visualizations/MyAlgorithmVisualization.gd
extends AlgorithmVisualizationBase

func on_reset() -> void:
    # Initialize visualization state
    pass

func on_periodic_update() -> void:
    # Update visualization logic (called every update_interval)
    pass

func draw_visualization() -> void:
    # Draw your visualization using _draw() functions
    draw_circle(get_center(), 50.0, Color.RED)
    draw_label("My Algorithm", Vector2(10, 20))
```

#### Step 2: Create Content Script

```gdscript
# boards/MyAlgorithmInfoBoard.gd
extends AlgorithmInfoBoardBase

const MyAlgorithmVis = preload("res://commons/infoboards_3d/visualizations/MyAlgorithmVisualization.gd")

func initialize_content() -> void:
    board_title = "My Algorithm"
    category_color = Color(0.3, 0.8, 0.5, 1.0)  # Green

    page_content = [
        {
            "title": "Introduction",
            "text": [
                "This is page 1 of my algorithm explanation.",
                "You can have multiple paragraphs here.",
                "Code examples work too!"
            ],
            "visualization": "my_algorithm_viz"
        },
        {
            "title": "How It Works",
            "text": [
                "Page 2 content goes here..."
            ],
            "visualization": "my_algorithm_viz"
        }
    ]

func create_visualization(vis_type: String) -> Control:
    match vis_type:
        "my_algorithm_viz":
            var vis = Control.new()
            vis.set_script(MyAlgorithmVis)
            vis.custom_minimum_size = Vector2(400, 400)
            return vis
        _:
            return null
```

#### Step 3: Create Scene Instance

```gdscript
# boards/MyAlgorithmInfoBoard.tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="res://commons/infoboards_3d/base/HandheldInfoBoard.tscn" id="1"]
[ext_resource type="Script" path="res://commons/infoboards_3d/boards/MyAlgorithmInfoBoard.gd" id="2"]

[node name="MyAlgorithmInfoBoard" instance=ExtResource("1")]

[node name="InfoBoardUI" parent="SubViewport" index="0"]
script = ExtResource("2")
board_title = "My Algorithm"
category_color = Color(0.3, 0.8, 0.5, 1)
```

#### Step 4: Add to Your Scene

```gdscript
# In any 3D scene
var info_board = preload("res://commons/infoboards_3d/boards/MyAlgorithmInfoBoard.tscn").instantiate()
info_board.position = Vector3(0, 1.5, -2)
add_child(info_board)
```

## 🎨 Customization

### Changing Colors

Each board can have a custom category color:

```gdscript
category_color = Color(0.8, 0.3, 0.5, 1.0)  # Pink for sorting algorithms
```

### Adjusting Physical Size

Edit `HandheldInfoBoard.tscn`:
- Modify `QuadMesh_screen` size for screen dimensions
- Update `BoxShape3D_frame` for collision
- Adjust `BoxMesh_frame` and `BoxMesh_edge` for visual appearance

### Viewport Resolution

In `HandheldInfoBoard.tscn`, change SubViewport size:
```gdscript
size = Vector2i(1024, 768)  # Higher = sharper text, but more memory
```

## 🎮 Visualization API

### AlgorithmVisualizationBase Methods

**Drawing Utilities:**
- `draw_grid(cell_size, color)` - Draw grid overlay
- `draw_axis(origin, length, color)` - Draw X/Y axes
- `draw_circle_outline(center, radius, color, segments, width)` - Circle outline
- `draw_arrow(from, to, color, width, arrow_size)` - Directional arrow
- `draw_text_centered(text, position, font_size, color)` - Centered text
- `draw_label(text, position, font_size, color)` - Simple label

**Animation Helpers:**
- `oscillate(amplitude, frequency, phase)` - Sine wave oscillation
- `pulse(min_val, max_val, frequency)` - Pulsing value
- `get_center()` - Get center point of visualization
- `get_random_point()` - Random point in bounds
- `get_random_color()` - Random color

**State Variables:**
- `animation_playing: bool` - Whether animation is active
- `time_elapsed: float` - Total time since start
- `animation_speed: float` - Speed multiplier

## 📊 Content Structure

Each page in `page_content` array has this structure:

```gdscript
{
    "title": "Page Title",           # Displayed at top
    "text": [                         # Array of paragraphs
        "Paragraph 1",
        "Paragraph 2 with more info",
        "Code examples work too:\nfunc example() -> void:\n    pass"
    ],
    "visualization": "viz_type_id"   # ID for visualization type
}
```

## 🔧 Technical Specifications

- **Viewport Resolution**: 1024x768 (customizable)
- **Physical Tablet Size**: 0.5m x 0.375m x 0.04m
- **Frame Depth**: 0.04m (thin tablet aesthetic)
- **Screen Offset**: 0.021m above frame
- **Mass**: 0.5 kg (feels realistic when grabbed)
- **Update Interval**: 0.1s for visualization updates

## 🎯 Next Steps

### Immediate Enhancements

1. **Add More Algorithm Boards**
   - Create boards for each category in algorithms.json
   - Focus on popular algorithms first (sorting, pathfinding, ML)

2. **Improve Visualizations**
   - Add more visualization types per algorithm
   - Include step-by-step breakdowns
   - Add parameter sliders for user control

3. **Content Generation**
   - Build AlgorithmDataParser.gd to auto-generate from algorithms.json
   - Create templates for different algorithm types
   - Add complexity analysis displays

4. **Visual Polish**
   - Create holographic screen shader
   - Add animated scanlines effect
   - Implement category-specific themes
   - Add floating/idle animation

5. **Integration**
   - Place boards in lab/hub areas
   - Create info board gallery/library
   - Add XP/SP rewards for reading
   - Link to actual algorithm demos

### Advanced Features

- **Search & Index**: Find algorithms by name/category
- **Bookmarks**: Save favorite pages
- **Cross-References**: Link related algorithms
- **Interactive Code**: Execute code snippets
- **Comparison Mode**: View two algorithms side-by-side
- **Quiz Integration**: Test knowledge

## 🐛 Known Issues

1. **VR Interaction**: Requires `grab_cube.gd` script to be present
2. **Text Readability**: May need font size adjustments for VR
3. **Performance**: Many active visualizations may impact framerate
4. **Mouse Input**: 2D UI needs proper Viewport2Din3D setup for mouse picking

## 📝 Notes

- Based on the infoBoards system from `C:\Users\palle\Documents\godot\infoboards`
- Combines clipboard.tscn grabbable mechanics with infodisplay.tscn scrolling
- Uses Viewport2Din3D pattern for rendering 2D UI in 3D space
- Follows Godot 4.x best practices

## 🤝 Contributing

To add a new algorithm board:
1. Create visualization script (if needed)
2. Create content script extending AlgorithmInfoBoardBase
3. Create scene instance
4. Test in test scene
5. Add to algorithm category collection

---

**Created**: 2025-10-20
**Version**: 1.0
**For**: AdaResearch VR Educational Experience

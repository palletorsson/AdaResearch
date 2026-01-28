# Translation Primitives

Simple, tactile tools for teaching **X, Y, Z axis translation** in VR.

## Overview

These primitives are **not puzzles** - they're interactive obstacles and objects that slide along a single axis to help understand 3D translation directly.

## Components

### `axis_slider.gd`
Base script for any object that slides along one axis (X, Y, or Z).

**Features:**
- Constrained movement to single axis
- Configurable min/max range
- Optional grid snapping
- Visual rail showing slide path
- Position marker showing current location
- Extends `grab_sphere.gd` for VR interaction

**Export Parameters:**
```gdscript
@export_enum("X", "Y", "Z") var slide_axis: String = "X"
@export var slide_min: float = -2.0
@export var slide_max: float = 2.0
@export var snap_to_grid: bool = false
@export var grid_spacing: float = 0.5
@export var show_rail: bool = true
@export var rail_color: Color = Color(0.3, 0.6, 1.0, 0.5)
@export var show_position_marker: bool = true
```

**Methods:**
- `get_axis_progress() -> float` - Returns 0.0 to 1.0 position along axis
- `reset_position()` - Returns to starting position

---

## Example Scenes

### `sliding_door.tscn`
A door that slides left/right on X axis.
- Snaps to grid positions
- Shows rail guide
- Use to block/reveal passages

### `elevator_platform.tscn`
A platform that slides up/down on Y axis.
- Snaps to floor levels
- Visual indicator for elevator concept
- Great for vertical movement teaching

### `translation_demo.tscn`
Complete demo with two blocking obstacles:
- **Red obstacle**: Slides on X axis (left/right)
- **Blue obstacle**: Slides on Y axis (up/down)
- Goal sphere behind obstacles
- Obstacles turn green when path is cleared

### `translation_cube_demo.tscn`
Compact 1m³ focused demo:
- Contained in wireframe cube boundary
- **Two door elements** (red on left, blue on right)
- Both slide only on **X axis**
- Visual path indicators show movement sequence
- Path arrows indicate: "up first, then to the side"
- Perfect for teaching single-axis constraint

---

## Usage Examples

### In Map Data JSON
```json
"interactables": [
    ["sliding_door:0:1:0.5", " ", " "],
    [" ", "elevator_platform:0:1:0.3", " "],
    [" ", " ", "translation_demo:90:1:0.8"]
]
```

### As Standalone Scene
Simply instantiate any `.tscn` file in your scene tree and it works immediately.

### Custom Axis Slider
Create your own by attaching `axis_slider.gd` to a RigidBody3D with a mesh and collision shape.

---

## Educational Use Cases

### 1. **Sliding Puzzles**
Create paths blocked by obstacles that must be slid aside in sequence.

### 2. **Elevator Systems**
Teach vertical translation with floor-to-floor platforms.

### 3. **Drawers & Cabinets**
Objects that slide in/out on Z axis.

### 4. **Coordinate Teaching**
Show how changing X, Y, or Z independently affects position.

### 5. **Obstacle Courses**
Paths where players must manipulate sliding barriers.

---

## Design Philosophy

- **Simple**: One axis at a time
- **Direct**: Grab and slide, no complex mechanics
- **Visual**: Rails and markers show constraints clearly
- **Tactile**: VR-optimized with haptic potential
- **Modular**: Easy to combine multiple sliders

---

## Future Extensions

- Add sound effects when sliding
- Haptic feedback at grid snap points
- Multi-axis combinations (XY plane, etc.)
- Velocity-based sliding (push to slide continuously)
- Locked positions requiring key/trigger to unlock

# Snap Point Mesh Builder System

An interactive VR system for building geometric meshes by snapping points together. Points remain as persistent, draggable handles that allow live editing of all created shapes.

## Overview

The snap point system progressively builds geometric primitives:
- **2 Points** → Line
- **3 Connected Points** → Triangle
- **4 Fully Connected Points** → Tetrahedron

All shapes update dynamically as you move their constituent points in VR.

## Core Principle: Persistent Handles

**All snap points remain interactive throughout the entire lifecycle**. When shapes are created:
- Points stay visible and grabbable
- Lines update their geometry as points move
- Triangles and tetrahedrons rebuild their meshes every frame
- The entire structure remains fully editable at all times

This is similar to how vector graphics programs work - points are control handles, shapes follow the handles.

## Files

- `snap_point.gd/tscn` - Interactive grabbable point with snap detection
- `snap_connection_manager.gd` - Manages graph topology and shape detection
- `snap_line.gd/tscn` - Dynamic line between two points
- `snap_triangle.gd/tscn` - Dynamic triangle mesh (3 points)
- `snap_tetrahedron.gd/tscn` - Dynamic tetrahedron mesh (4 points)
- `snap_demo.tscn` - Demo scene with 6 snap points

## Usage

### In Your VR Scene

1. **Add the Connection Manager**:
   ```
   Add SnapConnectionManager as a child node in your scene
   Or register it as an autoload in project settings
   ```

2. **Add Snap Points**:
   ```
   Instance snap_point.tscn at desired positions
   Points automatically register with the manager on _ready()
   ```

3. **Snap Points Together**:
   - Grab a point with VR controller
   - Move it within 0.15m (15cm) of another point
   - Release to snap - a line appears
   - Points glow green when in snap range

### Creating Shapes

**Line** (2 points):
- Snap any two points together
- A purple line appears connecting them
- Line updates as you move either point

**Triangle** (3 points):
- Snap 3 points in a closed loop (A→B, B→C, C→A)
- A pink triangle fills the area
- Triangle updates as you reshape by moving points

**Tetrahedron** (4 points):
- Connect 4 points to each other (all 6 possible edges)
- A blue tetrahedron appears
- Tetrahedron deforms as you move any of the 4 points

## Configuration

### Snap Point Properties

```gdscript
@export var snap_distance: float = 0.15  # Snap threshold (meters)
@export var snap_on_drop_only: bool = true  # Only snap when released
@export var show_snap_preview: bool = true  # Show green glow preview
@export var snap_glow_color: Color = Color(0.3, 1.0, 0.3, 1.0)
```

### Visual Customization

**Line Colors**:
```gdscript
var line = get_node("SnapLine")
line.set_line_color(Color.RED)
line.set_line_thickness(0.02)
```

**Shape Colors**:
```gdscript
var triangle = get_node("SnapTriangle")
triangle.set_triangle_color(Color.YELLOW)
```

## Haptic & Audio Feedback

- **Pickup**: Vibration + tone when grabbing point
- **Snap**: Stronger vibration + higher pitch when points connect
- **Preview**: Green glow when in snap range
- All feedback uses VR controller haptics via XRToolsPickable

## Implementation Details

### Architecture

```
SnapPoint (XRToolsPickable)
  ↓ detects proximity
SnapConnectionManager
  ↓ creates
SnapLine (Node3D with MeshInstance3D)
  ↓ notifies
SnapConnectionManager
  ↓ detects topology
SnapTriangle / SnapTetrahedron
```

### Dynamic Geometry Update Pattern

Each shape stores references to its point nodes:
```gdscript
var point_a: Node3D = null
var point_b: Node3D = null
var point_c: Node3D = null

func _process(_delta: float) -> void:
    if points_moved():
        _update_mesh_geometry()
```

Every frame, shapes read current `global_position` of their points and rebuild geometry using `SurfaceTool`.

### Graph Topology Detection

The ConnectionManager maintains an adjacency list:
```gdscript
var _adjacency: Dictionary = {}  # Node3D -> Array[Node3D]
```

**Triangle Detection**:
- Find all 3-cycles in the graph
- For each point A, check if any two neighbors B and C are connected
- If B↔C exists, create triangle ABC

**Tetrahedron Detection**:
- Find all complete graphs K4 (4 points all connected)
- Check if a point A has 3 neighbors B, C, D
- Check if B↔C, B↔D, and C↔D all exist
- If yes, create tetrahedron ABCD

## Demo Scene

Load `snap_demo.tscn` into your VR world:
- Contains 6 snap points arranged in space
- Includes SnapConnectionManager
- Has instruction label
- Ready to use immediately

## Tips

1. **Start Simple**: Connect 2 points to make a line
2. **Close the Loop**: Connect 3 points in a triangle pattern
3. **Go 3D**: Add a 4th point and connect to all 3 others for tetrahedron
4. **Edit Anytime**: Grab and move any point to reshape all connected forms
5. **Break Connections**: Move points far apart (>0.5m) to break connections

## Limitations

- Maximum automatic shape: Tetrahedron (4 points)
- No automatic detection of 5+ point polyhedra
- No convex hull operation (yet)
- Triangles and tetrahedrons only (no n-gons)

## Future Extensions

Potential additions:
- Quad detection (two triangles sharing an edge)
- Convex hull builder for N points
- Template spawner (cube, octahedron, etc.)
- Face fill tool for open meshes
- Mesh export functionality


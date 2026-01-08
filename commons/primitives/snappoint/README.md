# Snap Point System

A flexible VR interaction system for creating geometric puzzles using grabbable 3D points that snap together and form visual connections.

## Overview

The snap point system allows players to grab floating spherical points and connect them to form geometric shapes. When specific shapes are completed, puzzles trigger events like spawning objects or hiding the construction.

## Core Components

### 1. SnapPoint (`snap_point.gd/tscn`)

Individual grabbable sphere points that can snap together.

**Key Features:**
- Extends `XRToolsPickable` for VR grab interaction
- Proximity-based snapping (configurable distance)
- Visual feedback: glows green when near another point
- Audio and haptic feedback on snap
- Frozen by default but grabbable
- Transparent emissive material in puzzles

**Exports:**
```gdscript
@export var snap_distance: float = 0.15        # Distance for auto-snap
@export var snap_on_drop_only: bool = true     # Only snap when released
@export var show_snap_preview: bool = true     # Green glow when near
@export var snap_glow_color: Color             # Preview color
```

**Signals:**
```gdscript
signal snap_completed(target_point: Node3D)    # When snapped to another point
signal snap_broken(target_point: Node3D)       # When connection breaks
```

### 2. SnapConnectionManager (`snap_connection_manager.gd`)

Manages all snap point connections and detects geometric shapes formed.

**Responsibilities:**
- Maintains graph topology (adjacency list) of all connections
- Creates visual representations (lines, triangles)
- Detects completed shapes: lines, triangles, tetrahedrons, octahedrons, pyramids
- Emits signals when shapes are formed

**Key Methods:**
```gdscript
register_snap_point(point: Node3D)                    # Add point to system
create_connection(point_a: Node3D, point_b: Node3D)   # Connect two points
break_connection(point_a: Node3D, point_b: Node3D)    # Disconnect
are_points_connected(point_a: Node3D, point_b: Node3D) -> bool
```

**Shape Detection Signals:**
```gdscript
signal triangle_formed(points: Array)          # 3 points forming triangle
signal tetrahedron_formed(points: Array)       # 4 points all connected
signal octahedron_formed(points: Array)        # 6 points (4 equatorial + 2 polar)
signal square_pyramid_formed(points: Array)    # 5 points (4 base + 1 apex)
```

**Detection Algorithms:**

- **Triangle**: 3-cycle in graph (A-B-C-A)
- **Tetrahedron**: Complete graph K4 (all 4 points connected to each other)
- **Octahedron**: 6 vertices each with 4 connections, forming 2 polar + 4 equatorial square
- **Square Pyramid**: 5 vertices, 4 forming square base, 1 apex connecting to all 4
- **Wedge**: 6 points, 4 forming rectangular base, 2 forming top edge

### 3. Visual Connection Objects

**SnapLine (`snap_line.gd/tscn`)**
- Cylinder mesh connecting two points
- Updates dynamically as points move
- Emissive material with transparency (50% alpha)
- Auto-destroys if either point is invalid

**SnapTriangle (`snap_triangle.gd/tscn`)**
- Dynamic mesh updating based on 3 point positions
- Uses `GridMaterialFactory` for wireframe appearance
- Fills interior while showing edges
- Updates only when points move significantly (1mm threshold)

## Puzzle System

Three pre-built puzzles demonstrating different behaviors:

### Octahedron Puzzle (`snap_octahedron_puzzle.gd/tscn`)

**Points:** 6 (4 equatorial square + 2 polar)
**On Complete:** Spawns walkable prism/ramp
**Use Case:** Environmental puzzle, creates traversable geometry for complex shapes

**Configuration:**
```gdscript
@export var auto_solve: bool = true
@export var spawn_position: Vector3 = Vector3(0, 0, 2)
@export var spawn_scale: float = 1.0
@export var prism_rotation: Vector3 = Vector3(0, 0, 0)
```

**Behavior:**
1. Player connects 6 points to form octahedron (12 edges total)
2. Walkable prism spawns at configured position
3. Success message displays (3 seconds)
4. After delay, points and connections fade away
5. Prism remains for traversal

### Tetrahedron Puzzle (`snap_tetrahedron_puzzle.gd/tscn`)

**Points:** 4 (all connected to each other)
**On Complete:** Spawns a 1-unit cube
**Use Case:** Reward system, creates object at completion

**Configuration:**
```gdscript
@export var spawn_position: Vector3 = Vector3(0, 0, 1.5)
@export var spawn_scale: float = 1.0
@export var auto_solve: bool = true
```

**Behavior:**
1. Player connects all 4 points to each other (6 edges total)
2. Cube spawns at center of tetrahedron
3. Success message displays (3 seconds)
4. After 1 second, puzzle points/connections hide
5. Cube remains

### Pyramid Puzzle (`snap_pyramid_puzzle.gd/tscn`)

**Points:** 5 (4 base square + 1 apex)
**On Complete:** Spawns walkable prism/ramp
**Use Case:** Environmental puzzle, creates traversable geometry

**Configuration:**
```gdscript
@export var spawn_position: Vector3 = Vector3(0, 0, 2)
@export var spawn_scale: float = 1.0
@export var prism_rotation: Vector3 = Vector3(0, 0, 0)
@export var auto_solve: bool = true
```

**Behavior:**
1. Player connects 4 base points in square, then apex to all 4
2. Walkable prism spawns at configured position
3. Success message displays (3 seconds)
4. After 1 second, puzzle points/connections hide
5. Prism remains for traversal

## Usage in Maps

### Basic Placement

In map JSON `interactables` layer:

```json
"interactables": [
    [" ", "snap_octahedron_puzzle", " "],
    [" ", "snap_tetrahedron_puzzle", " "],
    [" ", "snap_pyramid_puzzle", " "]
]
```

### With Transforms

```json
"snap_pyramid_puzzle:90:0:1.5"
```
- Rotation: 90° Y-axis
- Y-offset: 0
- Scale: 1.5x

### Artifact Registration

All puzzles are registered in `commons/artifacts/grid_artifacts.json`:

```json
"snap_octahedron_puzzle": {
    "name": "Snap Octahedron Puzzle",
    "lookup_name": "snap_octahedron_puzzle",
    "description": "Interactive puzzle where connecting 6 snap points forms an octahedron...",
    "scene": "res://commons/primitives/snappoint/puzzles/snap_octahedron_puzzle.tscn"
}
```

## Creating Custom Puzzles

### Step 1: Create Scene

1. Create new scene inheriting from `Node3D`
2. Add `SnapConnectionManager` as child node
3. Add snap point instances as children (from `snap_point.tscn`)
4. Position points in desired configuration
5. Add instruction `Label3D`

### Step 2: Create Controller Script

```gdscript
extends Node3D
class_name MyCustomPuzzle

@export var auto_solve: bool = true

var snap_points: Array[Node3D] = []
var connection_manager: SnapConnectionManager

func _ready() -> void:
    # Find all snap points as children
    for child in get_children():
        if child is XRToolsPickable and child.has_signal("snap_completed"):
            snap_points.append(child)
    
    # Apply visual materials
    _apply_puzzle_materials()
    
    # Find connection manager
    connection_manager = _find_connection_manager()
    
    # Connect to shape signal
    connection_manager.triangle_formed.connect(_on_triangle_formed)

func _on_triangle_formed(points: Array) -> void:
    # Check if points are ours
    var our_count = 0
    for point in points:
        if point in snap_points:
            our_count += 1
    
    if our_count == 3:  # All points are ours
        _solve_puzzle()

func _solve_puzzle() -> void:
    # Your custom behavior here
    print("Puzzle solved!")
```

### Step 3: Visual Materials

Apply transparent emissive materials to puzzle points:

```gdscript
func _apply_puzzle_materials() -> void:
    var material = StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = Color(1.0, 0.8, 0.3, 0.6)  # 60% transparent
    material.emission_enabled = true
    material.emission = Color(1.0, 0.8, 0.3, 1.0)
    material.emission_energy_multiplier = 2.0
    
    for point in snap_points:
        var mesh = point.get_node_or_null("MeshInstance3D")
        if mesh:
            mesh.material_override = material
```

### Step 4: Hide Puzzle After Completion

```gdscript
func _hide_puzzle() -> void:
    for point in snap_points:
        if is_instance_valid(point):
            point.visible = false
    
    _hide_visual_connections()

func _hide_visual_connections() -> void:
    var scene_root = get_tree().current_scene
    _hide_connections_recursive(scene_root)

func _hide_connections_recursive(node: Node) -> void:
    if "point_a" in node and "point_b" in node:
        if node.point_a in snap_points or node.point_b in snap_points:
            node.visible = false
    
    for child in node.get_children():
        _hide_connections_recursive(child)
```

## Shape Detection Details

### Tetrahedron Detection

```gdscript
# 4 points where each connects to all 3 others
# Forms complete graph K4 with 6 edges
# Check: every point has exactly 3 neighbors within the set
```

### Octahedron Detection

```gdscript
# 6 vertices each with exactly 4 connections
# 2 polar vertices: each connects to all 4 equatorial points
# 4 equatorial vertices: form square (each connects to 2 neighbors + 2 polars)
# Polar vertices are NOT connected to each other
# Validates square by checking each equatorial point has exactly 2 equatorial neighbors
```

### Square Pyramid Detection

```gdscript
# 5 vertices total
# 4 base vertices form a square cycle (A-B-C-D-A)
# 1 apex vertex connects to all 4 base vertices
# Base points connect in cycle, apex only connects to base
```

## Performance Considerations

1. **Shape Detection**: Runs on every connection/disconnection
   - Uses early exit when possible
   - Caches shape keys to avoid duplicates
   - Only checks changed topology

2. **Visual Updates**: 
   - Lines update every frame (cheap)
   - Triangles only update when points move >1mm
   - Uses instance validity checks before operations

3. **Scene Instancing**:
   - Puzzles instantiate from packed scenes
   - Points share base scene (`snap_point.tscn`)
   - Materials created procedurally

## Technical Notes

### Coordinate System
- All positions in 3D world space
- Snap distance in meters (default 0.15m)
- Frozen points stay in place until grabbed

### State Management
```gdscript
enum PuzzleState {
    BUILDING,      # Points are movable
    VALIDATING,    # Checking if shape is correct
    LOCKED,        # Shape formed, points frozen
    COMPLETED      # Object spawned/puzzle finished
}
```

### Grid Scene Integration
Spawned objects are added to `GridScene` node if found, otherwise fall back to current scene root.

```gdscript
func _find_grid_scene() -> Node:
    # Search up parent chain for "GridScene"
    # Search scene tree recursively
    # Fallback to current_scene
```

## Debugging

**Enable debug output:**
```gdscript
# In SnapConnectionManager
print("SnapConnectionManager: Created connection ", key)
print("SnapConnectionManager: Detected triangle")
```

**Common Issues:**

1. **Points won't snap**: Check `snap_distance` export
2. **Shape not detected**: Verify all required connections exist
3. **Puzzle not solving**: Check signal connections in `_ready()`
4. **Objects not spawning**: Verify scene paths in exports
5. **"has() doesn't exist" error**: Use `"property" in node` not `node.has("property")`

## Future Extensions

**Potential additions:**
- Icosahedron (12 vertices)
- Dodecahedron (20 vertices)
- Custom shape validator (define edge list)
- Animation on shape completion
- Multi-stage puzzles (sequence of shapes)
- Time-based challenges
- Color-coded points for complex patterns
- Snap point teleportation/duplication
- Negative space puzzles (form void)

## References

- Base scene: `commons/primitives/snappoint/snap_point.tscn`
- Manager: `commons/primitives/snappoint/snap_connection_manager.gd`
- Puzzles: `commons/primitives/snappoint/puzzles/`
- Artifacts: `commons/artifacts/grid_artifacts.json`

# Point Zero - Technical Tutorial

## The Origin in Code

### Vector3.ZERO
The origin is defined as a constant in Godot:

```gdscript
var origin = Vector3.ZERO  # Equivalent to Vector3(0, 0, 0)
```

This is not a mathematical point but a **memory address** containing three float values, each set to 0.0.

### Transform and Position
Every Node3D in Godot has a transform property:

```gdscript
var node = Node3D.new()
print(node.position)  # Outputs: (0, 0, 0)
```

By default, all nodes begin at the origin. This "beginning" is not metaphysical - it's the default initialization value written into Godot's source code.

### The Coordinate System
The 3D coordinate system visible in the map is constructed from three orthogonal vectors:

```gdscript
# Coordinate axes
var x_axis = Vector3.RIGHT   # (1, 0, 0) - Red
var y_axis = Vector3.UP       # (0, 1, 0) - Green
var z_axis = Vector3.BACK     # (0, 0, 1) - Blue
```

These form a **right-handed coordinate system** where:
- X points right (east)
- Y points up (vertical)
- Z points toward the camera (south)

### Creating an Origin Marker
To visualize the origin:

```gdscript
extends Node3D

func _ready():
    # Create sphere at origin
    var mesh_instance = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = 0.05
    mesh_instance.mesh = sphere

    # Create material with emission
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1, 1, 1)
    material.emission_enabled = true
    material.emission = Color(0.5, 0.8, 1)
    material.emission_energy = 2.0
    mesh_instance.material_override = material

    add_child(mesh_instance)
```

### The Rendering Pipeline
The frame counter display shows the continuous update loop:

```gdscript
var frame_count = 0

func _process(delta):
    frame_count += 1
    # This runs 60-90 times per second in VR
    # The origin persists across frames
```

### Reference Frames
In VR, there are multiple coordinate systems:

```gdscript
# World space - the global coordinate system
var world_position = global_position

# Local space - relative to parent
var local_position = position

# XR space - relative to headset tracking origin
var xr_origin = $XROrigin3D
var tracking_origin = xr_origin.global_position
```

The "origin" is different in each frame of reference.

## Implementation Notes

### Why Height 0.3m?
The origin marker is placed at `height: 0.3` to be visible above the floor tiles (which are at y=0). This is a **display choice**, not a mathematical property.

### Rotation 180°
The origin marker is rotated 180° to face the player's spawn direction. The origin itself has no orientation - we impose one for visibility.

### Performance
The frame counter reveals that maintaining the origin requires:
- Memory allocation (12 bytes for 3 floats)
- Coordinate transform calculations every frame
- Rendering pipeline execution

There is no "free" origin - it exists as computational work.

## Key Takeaway
Vector3.ZERO is not discovered, it is **declared**. It exists because Godot's developers wrote `const ZERO = Vector3(0, 0, 0)` into the engine source code. The origin is a **convention**, sustained by continuous execution.

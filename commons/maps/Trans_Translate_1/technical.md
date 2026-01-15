# Trans_Translate_1 - Technical Tutorial

## Translation in Code

### Basic Translation
Translation changes position without affecting rotation or scale:

```gdscript
# Direct position assignment
node.position = Vector3(5, 2, 3)

# Relative translation (add to current position)
node.position += Vector3(1, 0, 0)  # Move 1 unit right

# Using translate method
node.translate(Vector3(0, 1, 0))  # Move up in local space
```

### Displacement as Vector

The displacement is not a position - it is a direction and magnitude:

```gdscript
# Position: absolute location in world space
var position = Vector3(10, 5, 3)  # "I am here"

# Displacement: relative movement
var displacement = Vector3(2, 0, -1)  # "Move this way"

# Translation combines them
position += displacement  # Vector3(12, 5, 2)

# Displacement has no absolute location
# It exists only as difference, as change
```

### Global vs Local Translation

```gdscript
# Global translation - moves in world coordinates
node.global_position += Vector3(1, 0, 0)

# Local translation - moves relative to object's orientation
node.translate(Vector3(1, 0, 0))  # Moves along object's local X

# If object is rotated 90°, local X might point in world Z!
```

### Interpolated Translation

In code, translation is instant - position jumps from A to B. We interpolate to create smooth motion:

```gdscript
var start_position = Vector3(0, 0, 0)
var end_position = Vector3(10, 0, 0)
var t = 0.0  # Progress from 0 to 1

func _process(delta):
    t += delta * 0.5  # Speed of transition
    if t > 1.0:
        t = 1.0

    # Linear interpolation creates smooth motion
    position = start_position.lerp(end_position, t)
    # Discrete state changes rendered as continuous movement
```

### Transport Cube Implementation

The transport cubes (tc) in this map use animated translation:

```gdscript
extends AnimatableBody3D

@export var distance: float = 3.0
@export var axis: String = "y"  # "x", "y", or "z"
@export var auto_start: bool = false
@export var duration: float = 2.0

var start_position: Vector3
var end_position: Vector3

func _ready():
    start_position = position
    match axis:
        "x": end_position = start_position + Vector3(distance, 0, 0)
        "y": end_position = start_position + Vector3(0, distance, 0)
        "z": end_position = start_position + Vector3(0, 0, distance)

    if auto_start:
        start_movement()

func start_movement():
    var tween = create_tween()
    tween.set_loops()
    tween.tween_property(self, "position", end_position, duration)
    tween.tween_property(self, "position", start_position, duration)
```

### Why AnimatableBody3D?

```gdscript
# AnimatableBody3D is crucial for platforms that carry players:
# - It's a physics body that moves kinematically
# - Objects standing on it move WITH the platform
# - sync_to_physics must be true for smooth VR

extends AnimatableBody3D

func _ready():
    sync_to_physics = true  # Essential for VR!
```

### Walkway Translation

Walkways extend dynamically, translating their endpoint:

```gdscript
extends Node3D

@export var length: float = 5.0
@export var extend_duration: float = 1.0

func extend_walkway():
    var tween = create_tween()
    # Scale only on Z axis (length)
    tween.tween_property(
        $WalkwayMesh,
        "scale:z",
        length,
        extend_duration
    )
```

### Parsing Transport Cube Parameters

Map utilities use string format `tc:distance:axis:auto`:

```gdscript
func parse_transport_cube(params: String) -> Dictionary:
    var parts = params.split(":")
    return {
        "distance": float(parts[0]) if parts.size() > 0 else 3.0,
        "axis": parts[1] if parts.size() > 1 else "y",
        "auto": parts[2] == "auto" if parts.size() > 2 else false
    }

# Examples from this map:
# "tc:3:z" -> distance 3, Z axis, manual trigger
# "tc:1:y:auto" -> distance 1, Y axis, auto-start
# "tc:6:y" -> distance 6, Y axis, manual trigger
```

### Player on Moving Platform

When player stands on transport cube:

```gdscript
# The XRToolsMovementProvider handles this automatically
# But internally it works like:

func _physics_process(delta):
    if is_on_floor():
        var floor_body = get_floor_body()
        if floor_body is AnimatableBody3D:
            # Inherit platform velocity
            var platform_velocity = floor_body.get_velocity()
            player_velocity += platform_velocity
```

### Pickup Collection System

```gdscript
# PickupGate checks collection count
extends Area3D

@export var required_pickups: int = 3
var collected: int = 0

func _on_pickup_collected():
    collected += 1
    if collected >= required_pickups:
        open_gate()

func open_gate():
    # Animate gate opening
    var tween = create_tween()
    tween.tween_property($GateMesh, "position:y", 3.0, 0.5)
```

## Key Takeaway

Translation is the simplest transformation - just addition to position. But when applied to platforms carrying bodies, it becomes a **system of transit**. The player learns that their own movement is just one form of translation; they can also be translated by machines, delegating displacement to automated systems.

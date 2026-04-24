# Transformation Introduction

Three transformations, three lanes. Translate, rotate, scale.

Define a transform from scratch.

```gdscript
var t := Transform3D.IDENTITY
```

The identity transform: origin at zero, no rotation, unit scale.

Apply translation.

```gdscript
func translate(t: Transform3D, offset: Vector3) -> Transform3D:
    return t.translated(offset)
```

Adds the offset to the origin. The orientation and scale are preserved.

Apply rotation.

```gdscript
func rotate_y(t: Transform3D, angle_rad: float) -> Transform3D:
    return t.rotated(Vector3.UP, angle_rad)
```

Rotates around the Y axis by the given angle. Other axes work the same way.

Apply scale.

```gdscript
func scale(t: Transform3D, factors: Vector3) -> Transform3D:
    return t.scaled(factors)
```

Scales each axis independently. Uniform scale uses Vector3.ONE times a single factor.

Compose three transforms in order.

```gdscript
func srt(position: Vector3, rotation_rad: Vector3, scale_factors: Vector3) -> Transform3D:
    var t := Transform3D.IDENTITY
    t = t.scaled(scale_factors)
    t = t.rotated(Vector3.UP, rotation_rad.y)
    t = t.rotated(Vector3.RIGHT, rotation_rad.x)
    t = t.rotated(Vector3.FORWARD, rotation_rad.z)
    t.origin = position
    return t
```

Scale, then rotate, then translate. The order matters: different orders produce different final transforms.

Build a transport cube.

```gdscript
class_name TransportCube extends StaticBody3D

@export var translation_offset: Vector3 = Vector3(3, 0, 0)

func activate(target: Node3D) -> void:
    target.global_position += translation_offset
```

Picking up the cube teleports the target by the offset. Translation as a gap-closing move.

Build a rotation cube.

```gdscript
class_name RotationCube extends StaticBody3D

@export var rotation_axis: Vector3 = Vector3.UP
@export var rotation_angle_deg: float = 90.0

func activate(target: Node3D) -> void:
    target.rotate(rotation_axis, deg_to_rad(rotation_angle_deg))
```

Ninety degrees around a chosen axis. Rotation as a reorientation.

Build a scale cube.

```gdscript
class_name ScaleCube extends StaticBody3D

@export var scale_factor: float = 2.0

func activate(target: Node3D) -> void:
    target.scale *= scale_factor
```

Doubles the target's size. Scale as a presence expansion.

You can now compose scale, rotate, and translate in order, and build lane cubes that enact each transformation. Trans_Translation extends translation into its own detailed map.

Check identity.

```gdscript
func is_identity(t: Transform3D) -> bool:
    return t.is_equal_approx(Transform3D.IDENTITY)
```

Identity preserves the input. Useful as a test for whether a chain of transforms cancels out.

Invert a transform.

```gdscript
func invert(t: Transform3D) -> Transform3D:
    return t.affine_inverse()
```

Undo the transform. Composing t with t.affine_inverse() produces identity.

Compose with multiplication.

```gdscript
func combine(a: Transform3D, b: Transform3D) -> Transform3D:
    return a * b
```

Right-to-left application order. a * b applies b first, then a.

Extract the origin.

```gdscript
func get_origin(t: Transform3D) -> Vector3:
    return t.origin
```

The origin is the translation part of the transform. Ignore the basis to get just the position.

# Transformation Introduction

Three gaps in sequence: translation, scale, rotation. First watch what changes, then cross during the opening. The source scenes are `transport_cube.tscn`, `scale_cube.tscn` and `rotation_cube.tscn` in `commons/scenes/mapobjects/`.

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

The first crossing changes position.

```gdscript
global_position = global_position.move_toward(target_position, move_speed * delta)
var movement_delta = global_position - previous_position
_translate_rider(carried_player, movement_delta)
```

These are excerpts from `transport_cube.gd`. The hall's `tc:2:z:auto` places a one-metre cube over a three-metre gap and moves its centre two metres along Z. At each endpoint one edge meets the bank. Automatic motion lets the visitor watch first and board when it returns. `_translate_rider` applies each small displacement to the supported rider; in VR it keeps the collision body and the camera's rig together. Moving only an image, or only the player's collision body, would leave part of the crossing behind.

The second crossing changes size.

```gdscript
var scale_vec: Vector3 = Vector3(safe_scale, safe_scale, safe_scale)
mesh_instance.scale = scale_vec
box_shape.size = scale_vec
```

In `scale_cube.gd`, `current_scale` travels between 0.5 and 3.0, then holds at full size for four seconds. The centre is 1.5 metres below the bank. At maximum size its top reaches the floor; at minimum it withdraws below it. Both the visible mesh and the collision box change size. The map uses `#seat:deck` with zero additional Y offset: seating already accounts for the box's half-height.

The third crossing changes orientation.

```gdscript
mesh_instance.rotation_degrees = rotation_axis * current_angle
static_body.transform = mesh_instance.transform
```

These excerpts from `rotation_cube.gd` connect the visible angle to the physical surface. The hall opts into `profile:bridge`: a plank 3.6 metres long, one metre wide and 0.2 metres thick. Its centre stays fixed. At zero degrees it lies across the route, with a gap ahead and behind; at ninety degrees its length reaches across the three-metre opening, overlapping each bank by 0.3 metres. Its top stays level with the floor throughout the Y turn. The four-second pauses give time to cross while aligned.

Now compare the three events. Translation carries the surface between banks. Scale grows a surface until it meets them. Rotation aligns a length with them. The banks supply a shared reference, while the player's body tests whether the apparent opening is physically usable.

The helpers below concern transforms as data. They are additional experiments for the nearby matrix and composition artifacts, rather than the controls of these three crossings.

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

## Change the reference: an adjustable landing

After the third crossing, MOVE THE BANK gives the far landing a one-metre range along local +z. Its top remains at the grid deck. A single slider sets `target_displacement`; `_physics_process` advances at 0.25 m/s. RESET returns both the target and slider to zero. The original 3.6-metre plank and its timer are unchanged.

At the aligned pose, the plank reaches 0.30 metres into the original bank. The surface separation is `displacement - 0.30`: negative means overlap, positive means an open gap. This is not a traversal predicate. Body radius, floor snapping, gravity and movement all enter the crossing test. Walk the side aisle to compare settings and return without crossing the moving joint.

Source: `commons/artifacts/adjustable_landing/adjustable_landing.gd`. The artifact owns the movable slab and its controls; the map leaves a recess for it and supplies fixed side aisles. It does not resize or rotate the bridge.

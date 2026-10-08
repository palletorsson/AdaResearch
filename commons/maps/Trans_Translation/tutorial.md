# Trans Translation

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Waypoint lists
- Direction and length
- Guard conditions
- Route state

Moving. Displacement. Position as coefficients.

Translate a single object.

```gdscript
func move_to(node: Node3D, target: Vector3) -> void:
    node.global_position = target
```

Direct assignment. One frame, the object is there.

Translate smoothly over time.

```gdscript
func tween_to(node: Node3D, target: Vector3, duration: float) -> void:
    var tween := create_tween()
    tween.tween_property(node, "global_position", target, duration)
```

The tween interpolates linearly. Duration in seconds.

Translate along a local axis.

```gdscript
func move_forward(node: Node3D, distance: float) -> void:
    var forward: Vector3 = -node.global_transform.basis.z
    node.global_position += forward * distance
```

Local translation respects the node's current orientation. Forward is -Z in Godot.

Apply a translation impulse to a rigid body.

```gdscript
func nudge(body: RigidBody3D, impulse: Vector3) -> void:
    body.apply_central_impulse(impulse)
```

Impulse is velocity times mass. Physics integrates the impulse into velocity on the next step.

Translate relative to another node.

```gdscript
func move_relative_to(node: Node3D, reference: Node3D, offset_local: Vector3) -> void:
    var offset_world: Vector3 = reference.global_transform.basis * offset_local
    node.global_position = reference.global_position + offset_world
```

Local offset is transformed through the reference's basis. The result is a world-space position.

Chain multiple translations.

```gdscript
func move_sequence(node: Node3D, steps: Array, duration_per_step: float) -> void:
    var tween := create_tween().set_parallel(false)
    for target in steps:
        tween.tween_property(node, "global_position", target, duration_per_step)
```

Sequential tweens move the node through a sequence of positions. Useful for scripted paths.

Interpolate along a curved path.

```gdscript
func move_along_bezier(node: Node3D, curve: Curve3D, duration: float) -> void:
    var tween := create_tween()
    tween.tween_method(
        func(t): node.global_position = curve.sample_baked(t * curve.get_baked_length()),
        0.0, 1.0, duration
    )
```

Sample the Bezier curve at interpolated positions. The node follows the curve's shape over the duration.

You can now translate a node instantly or over time, locally or relative to another node, along straight lines or curves. The seven rides in this hall already separate and combine those components. Trans_Rotation follows in the active sequence.

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


## Same destination, different permission

On the final terrace, `translation_cube_demo` is instantiated twice: `course:lift_lateral` with a rail guide, and `course:free` with ghost endpoints. Their knobs begin 0.5 m above each artifact root; the 0.8 m plinth brings that to 1.3 m above the deck.

The guided mechanism projects hand displacement onto a permitted axis, clamps the distance and admits the next axis only after the lift threshold. The free mechanism admits both components at once within the same bounds. In `constrained_door.gd`:

```gdscript
var t = _clamp_run((knob_pos - start).dot(phase1_dir), target_y, 0.0, 0.05)
knob_pos = start + phase1_dir * t
```

Pure translations commute: adding the same two displacement vectors in reverse order gives the same endpoint. This puzzle imposes an order through its constraints; that is a property of the mechanism, not a limitation of vector addition.

## Watch the accepted movement

The exit mechanisms now leave a pale trace when a handle is held. Try the same small upward-and-outward gesture on each. The guided door records the lift after discarding the sideways component; the free door keeps both components within its bounds. Then follow the rail to its corner and outwards. Compare that bend with a direct diagonal in the other mechanism.

The free handle can be brought back towards its starting corner to try a curved route. The short recent history remains visible, with older samples eventually rolling off. This returns to Point_Trace with a changed receiver: the record belongs to the constrained knob, not to the whole hand gesture. Release does not reset the mechanism or erase its trail; the artifact’s existing reset method clears it when called, and reloading the hall starts a fresh record.

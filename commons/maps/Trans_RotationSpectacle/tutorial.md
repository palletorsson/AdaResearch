# Rotation Spectacle

A carousel of rotating objects. Layers turn at different rates.

Build the carousel frame.

```gdscript
func build_frame() -> Node3D:
    var frame := Node3D.new()
    add_child(frame)
    return frame
```

A parent Node3D to hold the spinning children. Rotating the frame rotates everything under it.

Attach objects to the frame at different radii.

```gdscript
func attach_ring(frame: Node3D, count: int, radius: float) -> void:
    for i in count:
        var angle: float = i * TAU / count
        var obj := MeshInstance3D.new()
        obj.mesh = BoxMesh.new()
        obj.position = Vector3(cos(angle), 0, sin(angle)) * radius
        frame.add_child(obj)
```

The children sit at even angles around a circle. Rotating the frame sweeps the whole ring.

Animate the frame.

```gdscript
@export var rotation_speed: float = 0.5  # radians per second

func _process(delta: float) -> void:
    frame.rotate_y(rotation_speed * delta)
```

Constant angular velocity. The frame turns smoothly at the configured rate.

Layer multiple rings.

```gdscript
func build_multi_ring() -> void:
    for layer in range(4):
        var sub_frame := Node3D.new()
        sub_frame.position.y = layer * 0.5
        add_child(sub_frame)
        attach_ring(sub_frame, 8, 1.0 + layer * 0.3)
        sub_frame.set_meta("speed", 0.3 + layer * 0.2)
```

Each layer has its own frame and its own speed. The combined motion is a stack of rotating rings.

Animate each layer at its own speed.

```gdscript
func _process(delta: float) -> void:
    for child in get_children():
        if child.has_meta("speed"):
            child.rotate_y(child.get_meta("speed") * delta)
```

Per-child speed lookup. The layers diverge and realign over time.

Add counter-rotation.

```gdscript
func add_counter_layer(radius: float, speed: float) -> void:
    var frame := Node3D.new()
    attach_ring(frame, 8, radius)
    frame.set_meta("speed", -speed)
    add_child(frame)
```

Negative speed reverses the direction. Alternating layers counter-rotate for visual rhythm.

Synchronise rotation to music.

```gdscript
func sync_to_beat(bpm: float) -> void:
    var beats_per_second: float = bpm / 60.0
    for child in get_children():
        if child.has_meta("speed"):
            var base_speed: float = child.get_meta("speed")
            child.rotate_y(base_speed * beats_per_second * (1.0 / Engine.get_frames_per_second()))
```

Speed scales with tempo. The carousel pulses with the audio.

You can now build a multi-layered rotating carousel with per-layer speeds, counter-rotation, and beat synchronisation. Trans_Scale extends scaling into its own detailed map.

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

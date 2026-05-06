# Chamber Foundations

Two overlapping ghosts. One is real, one is not. Build a chamber whose lesson is the impossibility of telling them apart from inside.

Declare the twin spawner.

```gdscript
class_name TwinSpawner
extends Node3D

@export var twin_scene: PackedScene
@export var offset: Vector3 = Vector3(0.2, 0.0, 0.0)
```

Two instances spawn from the same scene at a small offset. The offset keeps them distinct to the learner's eye but not to the system's classifier.

Spawn the twins.

```gdscript
func spawn_twins(parent: Node3D) -> void:
    var a := twin_scene.instantiate()
    var b := twin_scene.instantiate()
    a.position = Vector3.ZERO
    b.position = offset
    parent.add_child(a)
    parent.add_child(b)
    twins = [a, b]
```

The twins share the same class and the same behaviour. Only position differs. The chamber treats them as interchangeable.

Randomise which is real.

```gdscript
func assign_reality() -> void:
    var real_idx := randi() % twins.size()
    for i in twins.size():
        twins[i].is_real = (i == real_idx)
```

One twin is real; the other is a ghost. The system knows; the learner does not. The chamber refuses to disclose.

Render both identically.

```gdscript
func render_twin(twin: Node3D) -> void:
    twin.material_override = shared_material
    twin.modulate = Color(1.0, 1.0, 1.0, 0.7)
```

Identical translucency. Identical colour. Identical animation timings.

The classifier has nothing to tell them apart with.

Reject attempts to probe reality.

```gdscript
func probe(twin: Node3D) -> String:
    if twin.is_real:
        return "ambiguous"
    return "ambiguous"
```

Both answers are the same. The function does not lie; the system genuinely does not distinguish. Gödel's theorem is spoken by the chamber's refusal.

Dispense the catalyst mode.

```gdscript
func give_catalyst() -> void:
    CatalystBracelet.enable_mode("suspend")
    bracelet_label.text = "suspend: accept the undecidable"
```

The catalyst mode is "suspend". It does not resolve the twin; it lets the learner act without resolution.

Check completion by suspension rather than kill.

```gdscript
func on_suspend_used(target: Node3D) -> void:
    if target in twins:
        all_suspended.append(target)
    if all_suspended.size() == twins.size():
        open_exit()
```

Suspending both twins opens the exit. Choosing one and attacking fails. Incompleteness becomes a practice of deferral.

Write the lesson on the threshold.

```gdscript
func write_threshold(label: Label3D) -> void:
    label.text = "some questions cannot be answered from inside"
    label.modulate = Color(0.9, 0.85, 0.7)
```

The sentence closes the sequence. Incompleteness is not an obstacle. It is a shape of the practice.

You have closed the Foundations Crisis sequence. The next sequences ask what you build once you accept that some questions stay open.
<<</MAP>>>

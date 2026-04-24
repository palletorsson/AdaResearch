# Forces Composition

Two draggable vectors drive six live operations. Superposition makes many forces into one.

Declare the two driving vectors.

```gdscript
@export var vector_a: Vector3 = Vector3(1, 0, 0)
@export var vector_b: Vector3 = Vector3(0, 1, 0)
```

Exported so they appear in the editor. The user can drag them and see every derived quantity update.

Compute all six outputs at once.

```gdscript
func update_operations() -> Dictionary:
    return {
        "add": vector_a + vector_b,
        "sub": vector_a - vector_b,
        "dot": vector_a.dot(vector_b),
        "cross": vector_a.cross(vector_b),
        "project": vector_a.project(vector_b),
        "reflect": vector_a - 2.0 * vector_a.dot(vector_b.normalized()) * vector_b.normalized(),
    }
```

A single dictionary of results. Called every frame while the inputs are being dragged.

Display each operation on its own panel.

```gdscript
func update_panels(results: Dictionary) -> void:
    panel_add.text = "A + B = %s" % results.add
    panel_sub.text = "A - B = %s" % results.sub
    panel_dot.text = "A · B = %.2f" % results.dot
    panel_cross.text = "A × B = %s" % results.cross
    panel_project.text = "proj_B(A) = %s" % results.project
    panel_reflect.text = "reflect_B(A) = %s" % results.reflect
```

Labelled panels around the workbench. Each updates as the inputs change.

Add many forces to a single body.

```gdscript
class_name SuperpositionBody extends RigidBody3D

var applied_forces: Array[Vector3] = []

func _physics_process(_delta: float) -> void:
    var net: Vector3 = Vector3.ZERO
    for f in applied_forces:
        net += f
    apply_central_force(net)
```

Every listed force adds to the net. The body accelerates along the sum.

Add and remove forces dynamically.

```gdscript
func add_force(f: Vector3) -> int:
    applied_forces.append(f)
    return applied_forces.size() - 1  # index for later removal

func remove_force(index: int) -> void:
    if index >= 0 and index < applied_forces.size():
        applied_forces.remove_at(index)
```

Indices stay stable as long as no earlier forces are removed. For dynamic removal, use a dictionary keyed by ID.

Visualise the net force arrow.

```gdscript
func draw_net_force_arrow(body: Node3D, net: Vector3) -> void:
    var arrow := NET_ARROW_SCENE.instantiate()
    arrow.global_position = body.global_position
    arrow.set_direction(net)
    add_child(arrow)
```

A single thick arrow in a distinctive colour. Shows the aggregate even when individual forces are hidden.

You can now manipulate two vectors and watch six operations update live, and add many forces to a body and see the net drive it. ForcesSystems will next scale from single bodies to populations.

Check that net force is zero (equilibrium).

```gdscript
func is_in_equilibrium(forces: Array, tolerance: float = 0.01) -> bool:
    var net: Vector3 = Vector3.ZERO
    for f in forces: net += f
    return net.length() < tolerance
```

The body is at rest (or moving at constant velocity) iff the net force is zero. Static structures rely on this balance.

# Forces Composition — Technical

The map stages a workbench where two draggable vectors A and B drive six live operations: addition, subtraction, dot product, cross product, projection, and reflection. Each operation's output updates in real time as A and B are manipulated.

```gdscript
class_name VectorWorkbench extends Node3D

var vector_a: Vector3 = Vector3(1, 0, 0)
var vector_b: Vector3 = Vector3(0, 1, 0)

func _process(_delta: float) -> void:
    update_display_add(vector_a + vector_b)
    update_display_sub(vector_a - vector_b)
    update_display_dot(vector_a.dot(vector_b))
    update_display_cross(vector_a.cross(vector_b))
    update_display_projection(vector_a.project(vector_b))
    update_display_reflection(reflect(vector_a, vector_b.normalized()))

func reflect(v: Vector3, n: Vector3) -> Vector3:
    return v - 2.0 * v.dot(n) * n
```

## Superposition Demonstration

A single body receives many force arrows; the net force is drawn as the sum, and the body accelerates along the net vector.

```gdscript
class_name SuperpositionBody extends RigidBody3D

var applied_forces: Array = []  # list of Vector3

func _physics_process(_delta: float) -> void:
    var net_force: Vector3 = Vector3.ZERO
    for f in applied_forces:
        net_force += f
    apply_central_force(net_force)
    update_net_force_display(net_force)

func add_force(f: Vector3) -> void:
    applied_forces.append(f)

func remove_force_at_index(i: int) -> void:
    applied_forces.remove_at(i)
```

## Why Six Operations

The choice of six operations reflects the complete vector toolkit for low-dimensional geometry. Addition and subtraction produce vector-valued outputs that represent composition and difference. The dot product produces a scalar that measures alignment. The cross product produces a vector perpendicular to both inputs. Projection produces the component of one vector along another. Reflection produces the mirror image across a surface normal.

Higher-dimensional linear algebra extends the vocabulary (determinants, eigenvectors, inner products in arbitrary spaces), but for 3D geometry these six cover the vast majority of practical needs.

## Complexity

All six operations are O(1). The display updates are driven by `_process`, which runs once per rendered frame. The workbench is interactive at 60 fps with hundreds of force arrows — the bottleneck is the display rendering, not the arithmetic.

Within the sequence, Composition consolidates the operations into one table. ForcesSystems will next scale from single bodies to populations.

## Associativity and Commutativity

Vector addition is both associative and commutative. Given three forces, their sum is the same regardless of order: (a + b) + c = a + (b + c) = a + c + b. This is why superposition works cleanly in Newtonian mechanics: the order in which forces are applied does not matter.

```gdscript
func sum_forces(forces: Array) -> Vector3:
    var total := Vector3.ZERO
    for f in forces:
        total += f
    return total
```

Non-linear force interactions break this property. Friction depends on normal force, which depends on gravity, which is itself a force — introducing coupling that breaks simple superposition. The map stays within the linear regime.

## Reflection Geometry

Reflection across a plane with normal n sends the vector v to v - 2*(v.n̂)*n̂. This is equivalent to rotating 180° around the plane. Reflection is an isometry — it preserves distances and angles — but reverses orientation (handedness).

```gdscript
func reflect_about_plane(v: Vector3, plane_normal: Vector3) -> Vector3:
    var n_unit: Vector3 = plane_normal.normalized()
    return v - 2.0 * v.dot(n_unit) * n_unit
```

Applying reflection twice about the same plane returns the original vector. Composing reflections about two different planes produces a rotation around their intersection.

## Force Magnitude Clamping

Real systems rarely admit unbounded forces. Motors saturate, muscles fatigue, springs have ultimate strength. Clamping the composed force to a maximum magnitude is a realistic addition.

```gdscript
func apply_bounded_force(body: RigidBody3D, force: Vector3, max_magnitude: float) -> void:
    body.apply_central_force(force.limit_length(max_magnitude))
```

The map demonstrates unbounded forces for pedagogical clarity; the limits show up in later maps where realism matters.

## Workbench Interaction

The draggable vectors A and B are grabbed by the learner with standard XR interactable events. Each grab updates the vector's direction and length based on the grabber's position relative to the vector's tail.

```gdscript
func _on_tip_grabbed(grabber: XRController3D) -> void:
    while grabber.is_grabbing:
        vector = grabber.global_position - tail_position
        await get_tree().process_frame
```

## Multi-Body Coupling

Extending the workbench to multi-body coupling — adding a chain of bodies connected by forces — requires careful order-of-operations. In each physics step, all forces are computed first from the current configuration, then all bodies are integrated. Applying forces and integrating immediately would produce order-dependent results.

## Constraint Solvers

Beyond explicit force composition, physics engines solve constraints — rigid-body joints, contacts, limits — using iterative constraint-solver algorithms. Sequential impulses and projected Gauss-Seidel are standard. The workbench on this map uses only explicit forces for pedagogical clarity; the constraint machinery becomes important in the later physics sequences.

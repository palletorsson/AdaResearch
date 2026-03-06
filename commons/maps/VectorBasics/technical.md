# Explore vector magnitude and direction with a raised observa

In Primitives you built shapes. In Transformation you moved them — translate, rotate, scale. Every one of those operations took numbers as input. But which numbers? A translation of `(3, 0, 0)` moves right. `(0, 3, 0)` moves up. Same magnitude, different direction, completely different result. The numbers weren't just quantities. They were arrows.

A vector is a quantity with direction. That's the textbook line, and it's correct, but it undersells the idea. Vectors aren't a special case. They're the default. Position is a vector. Velocity is a vector. Force, acceleration, surface normals, the direction a camera faces — all vectors. Scalars (plain numbers) are the exception. The physical world speaks in arrows.

## Components: The Three Numbers

Every 3D vector decomposes into three scalar components: x, y, z. In Godot, this is `Vector3`.

```gdscript
var position := Vector3(2.0, 5.0, -3.0)
var velocity := Vector3(0.0, -9.8, 0.0)
var direction := Vector3(1.0, 0.0, 0.0)
```

Three different vectors. Same type, same structure. The meaning comes from context — position describes where, velocity describes how fast and which way, direction describes facing. The container is identical. What you pour into it determines what it is.

Components are projections onto axes. The x-component of `(2, 5, -3)` is 2 — that's how far the vector extends along the x-axis. The y-component is 5 — how far up. The z-component is -3 — how far into negative z. Each component is a shadow cast onto one axis. Three shadows reconstruct the whole arrow.

The dark sphere artifact in this map uses vectors constantly without naming them as such:

```gdscript
# Float above the ground
_sphere_mesh.position = Vector3(0, float_height + sphere_radius, 0)
```

That's a position vector. The x and z components are zero — centered on the origin. The y component lifts the sphere off the ground by the sum of its float height and radius. One vector, three components, one meaning: "put it here."

```gdscript
# Halo sits just above the ground plane
_halo_ring.position = Vector3(0, 0.01, 0)
```

Same structure. Different values. The halo ring hovers one centimeter above the floor. The vector `(0, 0.01, 0)` is almost entirely "no displacement" — only the y tells you anything. Two zeros and a whisper.

## Magnitude: How Long Is the Arrow

Magnitude is length. Given a vector `v = (x, y, z)`, its magnitude is:

```
|v| = √(x² + y² + z²)
```

Pythagoras in three dimensions. The same theorem that measures the diagonal of a rectangle extends upward into space. A vector of `(3, 4, 0)` has magnitude 5. A vector of `(1, 1, 1)` has magnitude √3 ≈ 1.732. A vector of `(0, 0, 0)` has magnitude 0 — the zero vector, an arrow that points nowhere and has no length.

In GDScript:

```gdscript
var v := Vector3(3.0, 4.0, 0.0)
var mag := v.length()  # 5.0
```

Magnitude strips away direction. It answers "how much" while discarding "which way." Speed is the magnitude of velocity. Distance is the magnitude of displacement. The scalar lurks inside every vector — you just have to measure the arrow.

Why does this matter? Because comparison requires magnitude. Is this force stronger than that one? Is the player close enough to interact? Is the velocity dangerously high? You can't compare arrows directly — they point in different directions. But you can compare their lengths.

```gdscript
# Is the target within interaction range?
var displacement := target_position - current_position
var distance := displacement.length()
if distance < interaction_radius:
    trigger_interaction()
```

Notice: `displacement` is a vector (direction and distance to target). `distance` is a scalar (how far, direction forgotten). The vector carries more information. The scalar is what you needed for the comparison.

A performance note: `length()` computes a square root. Square roots are expensive. If you only need to compare magnitudes — not know the actual value — use `length_squared()` instead:

```gdscript
# Cheaper comparison — no square root
if displacement.length_squared() < interaction_radius * interaction_radius:
    trigger_interaction()
```

Same result. Fewer cycles. The square root is the bottleneck in distance calculations, and half the time you don't need it.

## Direction: Which Way the Arrow Points

Strip the magnitude and what remains is direction. A unit vector — magnitude exactly 1.0 — encodes pure direction with no intensity. Normalizing a vector divides each component by the magnitude:

```
û = v / |v|
```

In GDScript:

```gdscript
var v := Vector3(3.0, 4.0, 0.0)
var unit := v.normalized()  # Vector3(0.6, 0.8, 0.0)
```

The normalized vector `(0.6, 0.8, 0.0)` points in the same direction as `(3, 4, 0)` but has length 1. It's the arrow's heading without its speed. The compass without the odometer.

This decomposition — magnitude times direction — is fundamental:

```gdscript
var v := Vector3(3.0, 4.0, 0.0)
var mag := v.length()         # 5.0
var dir := v.normalized()     # (0.6, 0.8, 0.0)
# Reconstruction: dir * mag == v
var reconstructed := dir * mag  # (3.0, 4.0, 0.0)
```

Any vector equals its direction scaled by its magnitude. Two independent pieces of information, cleanly separated. This is why unit vectors matter — they let you control direction and intensity independently. Want to move at speed 5 toward a target?

```gdscript
var to_target := (target_pos - current_pos).normalized()
var velocity := to_target * 5.0
```

Direction from geometry. Speed from design. Combined into motion.

The dark sphere uses this principle implicitly in its rotation:

```gdscript
# Slow rotation around Y axis with slight wobble on X
_sphere_mesh.rotation.y += rotation_speed * delta
_sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05
```

The rotation axes (Y and X) are directions. The values (`rotation_speed * delta`, `sin(...) * 0.05`) are magnitudes — how much to rotate. Direction times magnitude. The pattern repeats everywhere.

## Basis Vectors: The Coordinate Frame

Three special unit vectors define the coordinate system itself:

- **î** = `Vector3(1, 0, 0)` — points along x
- **ĵ** = `Vector3(0, 1, 0)` — points along y
- **k̂** = `Vector3(0, 0, 1)` — points along z

These are the basis vectors. Every other vector is a linear combination of them:

```
P = xî + yĵ + zk̂
```

The point `(2, 5, -3)` is "2 units along î, plus 5 units along ĵ, plus -3 units along k̂." Components aren't just numbers — they're weights applied to basis vectors. The basis is the frame of reference from which all positions are measured.

The `basis_vectors_rig` artifact in this map makes this visible. It constructs three colored arrows — one per axis — and decomposes a target point into its basis components:

```gdscript
@export var axis_length: float = 5.0
@export var arrow_thickness: float = 0.02
@export var target_point: Vector3 = Vector3(3.0, 2.0, 4.0)
```

The `target_point` is the vector being decomposed. The rig draws î, ĵ, k̂ as physical arrows in space, then shows the component lines — dashed projections from the target point down to each axis. The learner sees, spatially, that `(3, 2, 4)` means "walk 3 along red, 2 along green, 4 along blue."

The rig builds each basis arrow as a composite of shaft, head, glow, and label:

```gdscript
func _create_basis_arrow(arrow_name: String, color: Color, 
                         unit_label: String, axis_label: String) -> Node3D:
    # Each arrow is a Node3D containing:
    # - A cylinder shaft along the axis direction
    # - A cone arrowhead at the tip
    # - An emission glow for visibility
    # - Labels: "î" / "ĵ" / "k̂" and "x" / "y" / "z"
```

Four layers per arrow. The shaft gives form. The head gives direction — you know which end is which. The glow ensures visibility in VR. The labels connect the visual to the mathematical notation. Each layer serves a distinct purpose. None are decorative.

## Linear Combination: Building Any Point

The core insight: **any point in 3D space is a linear combination of the three basis vectors**. "Linear combination" means "scale each basis vector by some amount and add them up."

```gdscript
# These are equivalent
var point := Vector3(3.0, 2.0, 4.0)

# Explicit linear combination
var i_hat := Vector3(1, 0, 0)
var j_hat := Vector3(0, 1, 0)
var k_hat := Vector3(0, 0, 1)
var point_expanded := 3.0 * i_hat + 2.0 * j_hat + 4.0 * k_hat
# point_expanded == Vector3(3.0, 2.0, 4.0)
```

Writing `Vector3(3, 2, 4)` is shorthand for the linear combination. The constructor hides the basis vectors, but they're always there. Every coordinate system has a basis. Change the basis, and the same physical point gets different component values — but the arrow hasn't moved. The map changes. The territory stays.

The `basis_vectors_rig` draws component lines to make this tangible:

```gdscript
func _create_component_lines():
    # Dashed lines from the target point to each axis
    # Shows the "shadow" each component casts
    # x-component: horizontal line at the point's y and z, from x=0 to x=target_point.x
    # y-component: vertical line at the point's x and z, from y=0 to y=target_point.y
    # z-component: depth line at the point's x and y, from z=0 to z=target_point.z
```

Three dashed lines, three projections. The point floats in space. The lines drop down to the axes like puppet strings. Cut any one string and the point collapses onto the plane defined by the other two. Cut two and it falls to a single axis. This is what decomposition means — breaking a vector into independent contributions along each basis direction.

## Vectors as State

Look at the dark sphere's `_process` function:

```gdscript
func _process(delta: float) -> void:
    _time_elapsed += delta

    if _sphere_mesh:
        _sphere_mesh.rotation.y += rotation_speed * delta
        _sphere_mesh.rotation.x = sin(_time_elapsed * 0.4) * 0.05

    if _sphere_material:
        var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
        _sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

Every frame, the sphere's rotation vector changes. `rotation.y` accumulates — it increases steadily, spinning the sphere. `rotation.x` oscillates — a sine wave creating a gentle wobble. The rotation vector `(wobble, spin, 0)` encodes the sphere's angular state at any instant. Two components, two different behaviors, one vector.

`delta` appears everywhere. It's the time elapsed since the last frame — a scalar that converts "per second" rates into "this frame" amounts. `rotation_speed * delta` means "rotate this many radians this frame." Without delta, speed would depend on framerate. With it, motion is consistent regardless of performance. Delta is the bridge between continuous mathematics and discrete simulation.

The `pulse_t` variable maps a sine wave from `[-1, 1]` to `[0, 1]`:

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
```

Add 1 to shift the range to `[0, 2]`. Multiply by 0.5 to compress to `[0, 1]`. Now `pulse_t` smoothly oscillates between 0 and 1 — a normalized parameter that drives the `lerpf` between minimum and maximum emission. This is a scalar, not a vector, but the technique of mapping oscillation to a normalized range applies directly to vector interpolation in later maps.

## The Observation Platform

This map places the learner on a raised platform. The elevation matters. From above, vectors on the ground plane reveal their x-z components clearly — the bird's-eye view collapses the y-axis, showing the "floor plan" of each arrow. Step to the platform edge, look down at a steep angle, and the y-component reasserts itself. The same vector looks different from different vantage points.

This is not a rendering trick. It's the point. Vectors exist independently of observation. Their components — the numbers you write in code — depend on the coordinate system. From above, a vector that points "forward and right" has obvious x and z components but the y is foreshortened. From the side, the y dominates. The vector hasn't changed. Your frame of reference has.

The `basis_vectors_rig` anchors this experience. Its three arrows define the coordinate frame visually. Walk around them. See how the î arrow (x-axis) shortens as you align with it head-on. See how k̂ (z-axis) appears as a single point when viewed along its own direction. A vector viewed along its own axis collapses to zero apparent length. Perpendicular views show full magnitude. This is the geometric core of the dot product — but that's for a later map.

## Vectors in Practice: Building Geometry

Every 3D object you've created in previous maps was built with vectors. The dark sphere constructs its mesh with explicit vector quantities:

```gdscript
func _create_sphere() -> void:
    _sphere_mesh = MeshInstance3D.new()
    
    var mesh := SphereMesh.new()
    mesh.radius = sphere_radius        # scalar: how big
    mesh.height = sphere_radius * 2.0  # scalar: derived from radius
    mesh.radial_segments = 32          # scalar: resolution
    mesh.rings = 16                    # scalar: resolution
    _sphere_mesh.mesh = mesh
    
    # Position is a vector
    _sphere_mesh.position = Vector3(0, float_height + sphere_radius, 0)
    add_child(_sphere_mesh)
```

The mesh parameters are scalars — radius, height, segment counts. They define shape. The position is a vector — it defines placement. Shape is scalar. Placement is directional. The sphere doesn't care where it sits; it's round either way. But the scene graph cares. The `position` vector tells the engine exactly where to render those triangles.

The halo ring adds another layer:

```gdscript
func _create_halo_ring() -> void:
    var ring_mesh := CylinderMesh.new()
    ring_mesh.top_radius = sphere_radius * 1.2
    ring_mesh.bottom_radius = sphere_radius * 1.2
    ring_mesh.height = 0.005
    _halo_ring.mesh = ring_mesh
    
    _halo_ring.position = Vector3(0, 0.01, 0)
    add_child(_halo_ring)
```

Two objects. Two position vectors. The sphere at `(0, float_height + radius, 0)`. The halo at `(0, 0.01, 0)`. The vertical gap between them is the difference of their y-components. That difference — the vector from one position to another — is subtraction. Which is where the next map begins.

## What Vectors Encode

Magnitude is the scalar hiding inside every vector. Direction is what makes a vector more than a scalar. Basis vectors are the invisible scaffold on which every coordinate hangs. Linear combination is the act of building any point from three weighted arrows.

These aren't abstract definitions. They're the operational grammar of 3D space. Every position you set, every velocity you compute, every force you apply decomposes into components along basis vectors with a magnitude and a direction. The `basis_vectors_rig` makes the invisible scaffold visible. The dark sphere demonstrates vectors in constant use — rotation, position, oscillation — without ever calling attention to them.

This is what vectors are before you start doing things with them. VectorSubtraction takes the next step: given two vectors, what does it mean to subtract one from the other? The answer is displacement — the arrow between two points. And displacement is the seed of velocity, which is the seed of force, which is the seed of everything that moves.

## Possible Artifacts

**magnitude_visualizer** — An interactive artifact that takes a user-adjustable vector and displays both the arrow and its computed magnitude as a visible length bar alongside the √(x² + y² + z²) formula with live values. The basis rig shows decomposition; this would show reconstruction — how three components produce one length. Critical for building intuition about when magnitude matters (distance checks, speed limits, normalization).

**unit_vector_normalizer** — Takes an arbitrary vector arrow and shows the normalization process: the original arrow, then the same arrow scaled to length 1, with the magnitude factor displayed separately. Learners drag the original vector and watch the unit vector maintain direction while snapping to unit length. Connects direction-as-concept to the `.normalized()` operation they'll use constantly.

**vector_component_projector** — An artifact that lets the learner rotate the observation platform (or camera) and watches how the apparent lengths of the basis vectors change with viewing angle, while their true magnitudes remain constant. Directly demonstrates that components depend on frame of reference — a concept the raised platform implies but doesn't yet make interactive.
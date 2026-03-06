# Room with perpendicular wall segments for cross product visu

In VectorSubtraction we learned that two vectors can describe difference — the gap between positions, the arrow from here to there. Subtraction keeps you in the same dimension. The cross product does something stranger. It takes two vectors that define a plane and produces a third vector that escapes that plane entirely. Perpendicular to both inputs. A direction neither vector pointed. Something new from two things that already existed.

The room makes this visible. Perpendicular wall segments meet at right angles — the architecture itself encoding the output of the operation it teaches. Walk along one wall, then the other. The direction you can't walk is the cross product.

## The Formula

The cross product of two 3D vectors **A** and **B** produces a third vector **C**:

```gdscript
# Cross product computed component by component
func cross_product(a: Vector3, b: Vector3) -> Vector3:
    return Vector3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
```

Each component of the result depends on the *other two* components of the inputs. The x-component uses y and z. The y-component uses z and x. The z-component uses x and y. A rotation through the indices — cyclic permutation. The formula looks arbitrary until you see what it produces: a vector orthogonal to both inputs.

Godot provides this natively:

```gdscript
var a := Vector3(1, 0, 0)  # Points along x-axis
var b := Vector3(0, 1, 0)  # Points along y-axis
var c := a.cross(b)         # Returns Vector3(0, 0, 1) — the z-axis
```

î × ĵ = k̂. The basis vectors rig in this map shows exactly this relationship. Three arrows — red, green, blue — each perpendicular to the other two. The cross product is the operation that generates the third from any two.

```gdscript
# The three fundamental cross products of basis vectors
var i_hat := Vector3(1, 0, 0)
var j_hat := Vector3(0, 1, 0)
var k_hat := Vector3(0, 0, 1)

# Each basis vector is the cross product of the other two
assert(i_hat.cross(j_hat) == k_hat)
assert(j_hat.cross(k_hat) == i_hat)
assert(k_hat.cross(i_hat) == j_hat)
```

Three equations. One pattern. The basis vectors form a closed loop under the cross product — each one generating the next.

## The Right-Hand Rule

The cross product is not commutative. **A × B ≠ B × A**. In fact:

```gdscript
var a := Vector3(1, 0, 0)
var b := Vector3(0, 1, 0)

print(a.cross(b))  # Vector3(0, 0, 1)  — points up
print(b.cross(a))  # Vector3(0, 0, -1) — points down
```

**A × B = −(B × A)**. Anticommutative. Swap the inputs, flip the output. Order matters. Direction depends on which vector comes first.

The right-hand rule encodes this convention. Point your fingers along **A**. Curl them toward **B**. Your thumb points in the direction of **A × B**. This is not physics — it is a choice. A convention baked into coordinate systems, into Godot's Vector3.cross(), into the way 3D graphics have worked since the beginning. Left-handed coordinate systems exist. They flip the rule. The math still works — the sign changes.

```gdscript
# Visualizing the right-hand rule with arrow orientations
func show_cross_product_direction(a: Vector3, b: Vector3) -> void:
    var result := a.cross(b)
    
    # The result is perpendicular to both inputs
    # Verify orthogonality via dot product
    assert(is_zero_approx(result.dot(a)))  # result ⊥ a
    assert(is_zero_approx(result.dot(b)))  # result ⊥ b
```

Two dot products, both zero. That's the proof. The cross product output has zero alignment with either input. Pure perpendicularity.

## Magnitude as Area

The cross product gives more than direction. Its magnitude encodes geometry:

|**A × B**| = |**A**| · |**B**| · sin(θ)

Where θ is the angle between the two vectors. Compare this to the dot product from earlier in the sequence: **A · B** = |**A**| · |**B**| · cos(θ). Dot uses cosine — it measures how much two vectors agree. Cross uses sine — it measures how much they *disagree*. Maximum alignment means zero cross product. Maximum perpendicularity means maximum cross product.

```gdscript
# The magnitude of the cross product = area of the parallelogram
func parallelogram_area(a: Vector3, b: Vector3) -> float:
    return a.cross(b).length()

# Two unit vectors at 90 degrees span a unit square
var area_90 := parallelogram_area(Vector3(1, 0, 0), Vector3(0, 1, 0))
# area_90 = 1.0

# Two unit vectors at 45 degrees span less area
var diagonal := Vector3(1, 1, 0).normalized()
var area_45 := parallelogram_area(Vector3(1, 0, 0), diagonal)
# area_45 ≈ 0.707 = sin(45°)

# Two parallel vectors span zero area
var area_0 := parallelogram_area(Vector3(1, 0, 0), Vector3(2, 0, 0))
# area_0 = 0.0 — no parallelogram, no cross product
```

Parallel vectors produce a zero cross product. There is no perpendicular direction to two vectors that point the same way — they don't define a plane. They define a line. And a line has no normal.

The triangle area is half the parallelogram:

```gdscript
# Triangle area from three vertices
func triangle_area(p0: Vector3, p1: Vector3, p2: Vector3) -> float:
    var edge_a := p1 - p0  # Vector subtraction — from the previous map
    var edge_b := p2 - p0
    return edge_a.cross(edge_b).length() * 0.5
```

Vector subtraction to get edges. Cross product to get area. The operations chain together. Every triangle in every mesh in every 3D scene has an area computed this way.

## Normal Vectors

A surface normal is a unit vector perpendicular to a surface at a given point. For a flat triangle defined by three vertices, the normal is constant across the whole face:

```gdscript
# Compute the face normal of a triangle
func face_normal(p0: Vector3, p1: Vector3, p2: Vector3) -> Vector3:
    var edge_a := p1 - p0
    var edge_b := p2 - p0
    return edge_a.cross(edge_b).normalized()
```

`.normalized()` strips the magnitude, leaving only direction. The cross product gives the raw perpendicular vector — normalize it to get the pure normal.

Normals determine everything about how a surface interacts with light. A surface facing the light source is bright. A surface facing away is dark. The dot product between the normal and the light direction gives the illumination:

```gdscript
# Lambert's cosine law — the simplest lighting model
func lambert_intensity(normal: Vector3, light_dir: Vector3) -> float:
    # light_dir points FROM the surface TOWARD the light
    return maxf(0.0, normal.dot(light_dir.normalized()))
```

Cross product to get the normal. Dot product to get the brightness. The two operations interlock — cross creates perpendicularity, dot measures alignment.

This is why the order of vertices matters in 3D graphics. Swap two vertices and the cross product flips — the normal points inward instead of outward. The surface renders inside-out. Backface culling removes it entirely. The winding order of a triangle is a convention, like the right-hand rule, and it must be consistent.

```gdscript
# Winding order determines normal direction
var p0 := Vector3(0, 0, 0)
var p1 := Vector3(1, 0, 0)
var p2 := Vector3(0, 1, 0)

var normal_ccw := face_normal(p0, p1, p2)  # Counter-clockwise: normal points up
var normal_cw := face_normal(p0, p2, p1)   # Clockwise: normal points down

# normal_ccw = -normal_cw
```

The dark sphere artifact demonstrates this implicitly. Its `SphereMesh` uses `BaseMaterial3D.CULL_BACK` — only outward-facing triangles render. Every triangle on that sphere has a normal pointing away from the center. The cross product of each triangle's edges, taken in the right winding order, produces those outward normals.

```gdscript
# From dark_sphere.gd — backface culling relies on correct normals
_sphere_material.cull_mode = BaseMaterial3D.CULL_BACK
```

One line. But behind it: every triangle's vertex order was chosen so the cross product points outward. The renderer tests each fragment's normal against the camera direction. If the dot product is negative — the normal faces away — the triangle is culled. Cross product builds the normals. Dot product tests them. The pipeline depends on both.

## Perpendicularity in Three Dimensions

The basis vectors rig makes perpendicularity tangible. Three arrows at right angles. Each one the cross product of the other two. The rig decomposes any point in space as a linear combination of these three directions:

```gdscript
# From basis_vectors_rig — any point is a linear combination of basis vectors
# P = x·î + y·ĵ + z·k̂
@export var target_point: Vector3
```

The target point is decomposed along each axis — shown as colored component lines tracing from the origin along î, then ĵ, then k̂ until they reach the target. The cross product is what guarantees these axes are independent. Three vectors that are mutually perpendicular span all of 3D space. No redundancy. No gaps.

What happens when the basis vectors are *not* perpendicular? You can still span the space — any three non-coplanar vectors form a basis. But the decomposition gets complicated. Components interfere with each other. The clean separation that the cross product guarantees is lost. Orthogonal bases are not required. They are preferred because they simplify everything.

```gdscript
# Build an orthonormal basis from a single direction vector
func orthonormal_basis_from(forward: Vector3) -> Array[Vector3]:
    forward = forward.normalized()
    
    # Pick a reference vector that isn't parallel to forward
    var ref := Vector3.UP
    if abs(forward.dot(ref)) > 0.99:
        ref = Vector3.RIGHT  # Fallback if forward ≈ up
    
    # First cross product: get a vector perpendicular to forward
    var right := forward.cross(ref).normalized()
    
    # Second cross product: get the third perpendicular vector
    var up := right.cross(forward).normalized()
    
    return [right, up, forward]
```

Two cross products. From one direction, an entire coordinate frame. Camera systems use this — the "look at" function takes a forward direction and constructs right and up vectors from it. The cross product is the tool that manufactures perpendicularity on demand.

```gdscript
# Godot's Basis type encodes exactly this: three perpendicular vectors
var transform := Transform3D()
var basis := transform.basis

# The columns of the basis matrix are the local axes
var local_right := basis.x    # î in local space
var local_up := basis.y       # ĵ in local space
var local_forward := basis.z  # k̂ in local space

# They are mutually perpendicular (for orthonormal bases)
assert(is_zero_approx(local_right.dot(local_up)))
assert(is_zero_approx(local_up.dot(local_forward)))
assert(is_zero_approx(local_forward.dot(local_right)))
```

Godot's `Basis` type is three vectors stored as a matrix. When the basis is orthonormal — the default — each column is the cross product of the other two. The entire rotation system of Godot is built on cross products whether you see them or not.

## Torque and Angular Momentum

Force applied at a distance from a pivot creates rotation. Torque is the measure of that rotational force:

**τ = r × F**

The position vector **r** from the pivot to the point of force application, crossed with the force vector **F**. The result points along the axis of rotation.

```gdscript
# Torque from a force applied at a position relative to pivot
func compute_torque(pivot: Vector3, force_point: Vector3, force: Vector3) -> Vector3:
    var r := force_point - pivot  # Displacement from pivot
    return r.cross(force)          # Torque vector
```

Push a door at its edge — maximum torque. Push at the hinge — zero torque. The cross product's sine dependence means that only the component of force perpendicular to the lever arm contributes to rotation. Force parallel to the lever arm pushes but doesn't rotate.

```gdscript
# Demonstrating torque magnitude vs force application point
var pivot := Vector3.ZERO
var force := Vector3(0, 0, -10)  # Push forward

# Force applied at the edge of a 1-meter door
var torque_edge := compute_torque(pivot, Vector3(1, 0, 0), force)
print(torque_edge.length())  # 10.0 — full torque

# Force applied halfway
var torque_mid := compute_torque(pivot, Vector3(0.5, 0, 0), force)
print(torque_mid.length())   # 5.0 — half the torque

# Force applied at the hinge
var torque_hinge := compute_torque(pivot, Vector3(0, 0, 0), force)
print(torque_hinge.length()) # 0.0 — no torque
```

Angular momentum follows the same pattern: **L = r × p**, where **p** is linear momentum. The cross product converts linear quantities into rotational ones. It is the bridge between translation and rotation — the operation that turns straight-line motion around a point into spin.

This is where the cross product connects to the QFEP framework. Force changes velocity. Torque changes angular velocity. Both are instances of φ·ΔE(S,t) — the rate of change term. The cross product doesn't just describe perpendicularity. It describes how perpendicular forces create rotational change. Dynamics hidden inside geometry.

## The Zero Cross Product

Two special cases produce a zero cross product. When the vectors are parallel (θ = 0°) and when they are antiparallel (θ = 180°):

```gdscript
# Parallel vectors — same direction, no perpendicular exists
var a := Vector3(1, 0, 0)
var b := Vector3(3, 0, 0)
print(a.cross(b))  # Vector3(0, 0, 0)

# Antiparallel — opposite directions, still no perpendicular
print(a.cross(-b))  # Vector3(0, 0, 0)

# Test for parallelism using cross product magnitude
func are_parallel(a: Vector3, b: Vector3) -> bool:
    return a.cross(b).length_squared() < 1e-6
```

This is the complement of the dot product's zero case. Dot product is zero when vectors are perpendicular. Cross product is zero when vectors are parallel. Together they cover all angles — cosine and sine, alignment and divergence.

The zero cross product appears practically when building orthonormal bases. The `orthonormal_basis_from` function above has a fallback for when the forward direction is nearly parallel to the reference vector. Without that check, the cross product would return near-zero — a degenerate basis. Numeric instability from geometric degeneracy.

```gdscript
# The danger of near-parallel inputs
var forward := Vector3(0, 0.999, 0.001).normalized()
var ref := Vector3.UP  # Almost parallel to forward

var right := forward.cross(ref)
print(right.length())  # ≈ 0.001 — nearly zero, unstable direction
```

This is why the basis vectors rig chooses its axes along the coordinate directions — maximum separation, maximum stability, zero risk of degeneracy.

## From Cross Product to Projection

The cross product creates perpendicularity. But sometimes you need the opposite — the component of one vector that lies *along* another. Projection. And once you can project, you can reflect.

VectorProjectionReflection explores this directly. Projection decomposes a vector into parallel and perpendicular components relative to a surface. The perpendicular component? That's the normal direction — the direction the cross product gave us. Projection and the cross product are two perspectives on the same geometric decomposition: what's parallel, and what's perpendicular.

```gdscript
# Preview: projection uses dot product, but the surface it projects onto
# is defined by the normal — which comes from the cross product
func project_onto_plane(point: Vector3, plane_normal: Vector3) -> Vector3:
    var n := plane_normal.normalized()
    return point - point.dot(n) * n  # Remove the normal component
```

Cross product builds the surface normal. Dot product measures distance from the surface. Subtraction removes the perpendicular component. Three operations from three different maps, chained into one geometric action. The sequence is building a vocabulary, and the words start combining.

## Possible Artifacts

**cross_product_visualizer** — Interactive artifact that takes two input vectors (draggable arrows), computes their cross product in real-time, and displays the result as a third arrow perpendicular to both. Should show the parallelogram spanned by the two inputs as a semi-transparent quad, with area displayed numerically. The right-hand rule becomes spatial intuition when you can grab vector A, rotate it toward B, and watch the cross product arrow respond. Core gap in this map — the wall segments suggest perpendicularity but don't let the learner construct it.

**torque_demo** — A hinge-mounted panel or door that the learner pushes at different points. Visualizes the torque vector along the hinge axis, with magnitude shown as arrow length and color intensity. Sliding the force application point from hinge to edge shows torque scaling linearly with lever arm distance. Connects the cross product formula to physical intuition about rotation.

**normal_visualizer** — Generates a simple mesh (triangle, quad, or curved surface patch) and renders face normals as arrows protruding from each face. Toggling vertex winding order flips the normals visibly. Pairs with a directional light to show Lambert shading in real-time — rotating the mesh relative to the light demonstrates how normal direction controls brightness. The link between cross product, normals, and rendering becomes something you see and manipulate.
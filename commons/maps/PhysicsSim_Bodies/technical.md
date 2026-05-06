# Physics Simulation: Rigid Bodies & Collisions - Technical

## Chapter 2: Things That Crash

In Foundations, we learned to move points through space. Now those points become *objects* — shapes with mass, orientation, and the ability to collide. This chapter covers the four pillars: rigid body state, collision detection, constraint solving, and the canonical bouncing ball.

---

## 1. Rigid Body Representation

A rigid body is a point mass promoted to a solid object. It needs six degrees of freedom in 3D — three for position, three for orientation:

### State Vector

$$\text{State} = [\vec{x}, \vec{q}, \vec{v}, \vec{\omega}]$$

- **x**: position (center of mass)
- **q**: orientation (quaternion)
- **v**: linear velocity
- **ω**: angular velocity

```gdscript
class RigidBody:
    # Linear state
    var position: Vector3
    var velocity: Vector3
    var mass: float
    var inv_mass: float  # 1/mass, cached for efficiency. 0 = infinite mass (static)

    # Angular state
    var orientation: Quaternion
    var angular_velocity: Vector3
    var inertia_tensor: Basis        # 3x3 matrix in body space
    var inv_inertia_tensor: Basis    # inverse, cached
    var inv_inertia_world: Basis     # rotated to world space each frame

    # Force accumulators
    var force: Vector3
    var torque: Vector3

    func _init(_mass: float, _inertia: Basis):
        mass = _mass
        inv_mass = 1.0 / _mass if _mass > 0 else 0.0
        inertia_tensor = _inertia
        inv_inertia_tensor = _inertia.inverse()
        orientation = Quaternion.IDENTITY
```

### The Inertia Tensor

Mass resists linear acceleration. The **inertia tensor** resists angular acceleration. It's a 3×3 matrix that says "how hard is this object to spin around each axis?"

For simple shapes:

```gdscript
# Inertia tensors for common shapes
static func sphere_inertia(mass: float, radius: float) -> Basis:
    var i = 2.0 / 5.0 * mass * radius * radius
    return Basis(Vector3(i,0,0), Vector3(0,i,0), Vector3(0,0,i))

static func box_inertia(mass: float, size: Vector3) -> Basis:
    var f = mass / 12.0
    return Basis(
        Vector3(f * (size.y*size.y + size.z*size.z), 0, 0),
        Vector3(0, f * (size.x*size.x + size.z*size.z), 0),
        Vector3(0, 0, f * (size.x*size.x + size.y*size.y))
    )
```

### Integration (Using Velocity Verlet from Chapter 1)

```gdscript
func integrate(dt: float):
    # Linear
    var acceleration = force * inv_mass
    position += velocity * dt + 0.5 * acceleration * dt * dt
    var new_accel = force * inv_mass  # recalculate if forces depend on position
    velocity += 0.5 * (acceleration + new_accel) * dt

    # Angular
    inv_inertia_world = orientation * inv_inertia_tensor * orientation.inverse()
    var angular_accel = inv_inertia_world * torque
    angular_velocity += angular_accel * dt

    # Update orientation (quaternion integration)
    var spin = Quaternion(angular_velocity.x, angular_velocity.y, angular_velocity.z, 0)
    orientation += 0.5 * spin * orientation * dt
    orientation = orientation.normalized()  # prevent drift

    # Clear accumulators
    force = Vector3.ZERO
    torque = Vector3.ZERO
```

### Applying Forces at a Point

When a force is applied off-center, it creates torque:

$$\vec{\tau} = \vec{r} \times \vec{F}$$

```gdscript
func apply_force_at_point(f: Vector3, world_point: Vector3):
    force += f
    var r = world_point - position
    torque += r.cross(f)
```

---

## 2. Collision Detection

### The Two-Phase Approach

Checking every pair of objects against every other is O(n²) in narrow-phase, which is expensive. Solution: two phases.

**Broad phase**: Cheap test to eliminate pairs that *definitely* don't collide.
**Narrow phase**: Expensive test for pairs that *might* collide.

### Broad Phase: AABB (Axis-Aligned Bounding Box)

```gdscript
class AABB_:
    var min_point: Vector3
    var max_point: Vector3

    func intersects(other: AABB_) -> bool:
        return (min_point.x <= other.max_point.x and max_point.x >= other.min_point.x and
                min_point.y <= other.max_point.y and max_point.y >= other.min_point.y and
                min_point.z <= other.max_point.z and max_point.z >= other.min_point.z)
```

Cost: 6 comparisons per pair. Fast, conservative (some false positives, no false negatives).

### Narrow Phase: Sphere-Sphere (Simplest)

```gdscript
class CollisionResult:
    var colliding: bool
    var normal: Vector3       # direction to separate
    var depth: float          # penetration depth
    var contact_point: Vector3

func sphere_vs_sphere(a: RigidBody, ra: float, b: RigidBody, rb: float) -> CollisionResult:
    var result = CollisionResult.new()
    var delta = b.position - a.position
    var dist = delta.length()
    var min_dist = ra + rb

    result.colliding = dist < min_dist
    if result.colliding:
        result.normal = delta.normalized()
        result.depth = min_dist - dist
        result.contact_point = a.position + result.normal * ra

    return result
```

### Narrow Phase: Separating Axis Theorem (SAT) for Convex Shapes

The SAT says: two convex shapes do NOT overlap if and only if there exists an axis along which their projections are separated.

```gdscript
func project_shape_onto_axis(vertices: Array[Vector3], axis: Vector3) -> Vector2:
    var min_proj = INF
    var max_proj = -INF
    for v in vertices:
        var proj = v.dot(axis)
        min_proj = min(min_proj, proj)
        max_proj = max(max_proj, proj)
    return Vector2(min_proj, max_proj)  # (min, max)

func intervals_overlap(a: Vector2, b: Vector2) -> float:
    # Returns overlap depth, or -1 if no overlap
    var overlap = min(a.y, b.y) - max(a.x, b.x)
    return overlap if overlap > 0 else -1.0

func sat_test(verts_a: Array, verts_b: Array, axes: Array[Vector3]) -> CollisionResult:
    var result = CollisionResult.new()
    var min_overlap = INF
    var min_axis = Vector3.ZERO

    for axis in axes:
        var proj_a = project_shape_onto_axis(verts_a, axis)
        var proj_b = project_shape_onto_axis(verts_b, axis)
        var overlap = intervals_overlap(proj_a, proj_b)

        if overlap < 0:
            result.colliding = false
            return result  # Separating axis found → no collision

        if overlap < min_overlap:
            min_overlap = overlap
            min_axis = axis

    result.colliding = true
    result.normal = min_axis
    result.depth = min_overlap
    return result
```

---

## 3. Collision Response

Once we detect a collision, we need to respond. The two approaches:

### Position Correction (Verlet-friendly)

Just push the objects apart. Since Verlet derives velocity from position, this automatically changes velocity:

```gdscript
func resolve_collision_position(a: RigidBody, b: RigidBody, result: CollisionResult):
    var total_inv_mass = a.inv_mass + b.inv_mass
    if total_inv_mass == 0:
        return  # both static

    var correction = result.normal * result.depth / total_inv_mass
    a.position -= correction * a.inv_mass
    b.position += correction * b.inv_mass
```

### Impulse-Based Response (Velocity-based engines)

For velocity-based engines, we compute an impulse that changes velocity instantaneously:

$$j = \frac{-(1 + e) \cdot \vec{v}_{rel} \cdot \hat{n}}{\frac{1}{m_a} + \frac{1}{m_b}}$$

where `e` is the coefficient of restitution (0 = perfectly inelastic, 1 = perfectly elastic).

```gdscript
func resolve_collision_impulse(a: RigidBody, b: RigidBody, result: CollisionResult, restitution: float = 0.5):
    var relative_vel = b.velocity - a.velocity
    var vel_along_normal = relative_vel.dot(result.normal)

    if vel_along_normal > 0:
        return  # moving apart already

    var j = -(1.0 + restitution) * vel_along_normal
    j /= a.inv_mass + b.inv_mass

    var impulse = result.normal * j
    a.velocity -= impulse * a.inv_mass
    b.velocity += impulse * b.inv_mass
```

---

## 4. Constraints

Constraints restrict the relative motion of bodies. A **hinge** allows rotation around one axis. A **ball joint** allows rotation around all axes. A **distance constraint** keeps two points a fixed distance apart.

### Distance Constraint (Verlet)

The simplest and most useful constraint:

```gdscript
func solve_distance_constraint(a: RigidBody, b: RigidBody, target_distance: float):
    var delta = b.position - a.position
    var current_distance = delta.length()
    var error = current_distance - target_distance
    var correction = delta.normalized() * error

    var total_inv_mass = a.inv_mass + b.inv_mass
    a.position += correction * (a.inv_mass / total_inv_mass)
    b.position -= correction * (b.inv_mass / total_inv_mass)
```

This is beautifully simple in Verlet — just move positions. No impulses, no velocity manipulation.

### Iterative Constraint Solving

One pass isn't enough when constraints interact. Run multiple iterations:

```gdscript
func solve_constraints(bodies: Array, constraints: Array, iterations: int = 10):
    for i in range(iterations):
        for c in constraints:
            c.solve(bodies)
```

More iterations → more accurate. Typically 4-10 iterations suffice for games.

---

## 5. The Bouncing Ball: Everything Together

```gdscript
# The complete bouncing ball — the "hello world" of physics simulation
class BouncingBall:
    var pos: Vector3
    var prev_pos: Vector3
    var radius: float = 0.5
    var restitution: float = 0.8  # energy retained per bounce
    var gravity: Vector3 = Vector3(0, -9.81, 0)
    var dt: float = 1.0 / 60.0

    func _init(start_pos: Vector3):
        pos = start_pos
        prev_pos = start_pos  # starts at rest

    func step():
        # Verlet integration
        var temp = pos
        pos = 2.0 * pos - prev_pos + gravity * dt * dt
        prev_pos = temp

        # Ground collision (constraint)
        if pos.y < radius:
            pos.y = radius
            # Reflect vertical velocity with energy loss
            var vy = (pos.y - prev_pos.y) / dt
            prev_pos.y = pos.y + vy * dt * restitution
```

This 20-line simulation contains:
- **Newton's Second Law** (gravity as force/mass = acceleration)
- **Verlet Integration** (position-based, from Chapter 1)
- **Collision Detection** (pos.y < radius — the simplest possible check)
- **Collision Response** (position correction + velocity reflection)
- **Energy Loss** (restitution coefficient)

---

## What's Next

In **PhysicsSim_Springs**, we connect bodies with elastic forces. The distance constraint from this chapter becomes the spring-damper system — add a stiffness coefficient and a rest length, and rigid constraints become elastic connections. The Verlet engine from Chapter 1 + the rigid bodies from this chapter + the springs from Chapter 3 = cloth simulation.

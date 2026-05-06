# Symmetric mirror room where vectors split into shadow and bounce

The cross product manufactured perpendicularity — a direction neither input contained, escaping the plane they defined. Projection does the inverse. It collapses a vector *onto* a direction, discarding what doesn't align. Where the cross product generates new dimensions, projection deliberately loses one. And reflection — the operation that follows projection the way an echo follows a shout — flips the lost component while preserving the rest. Together they complete the core vector toolkit: add, subtract, cross, project, reflect. Every collision response, every mirror, every shadow in a 3D engine reduces to these five.

The room is symmetric. Two mirrored halves, identical geometry reflected across a central plane. The architecture teaches the concept before a single formula appears. Stand on one side, look across, and see your environment duplicated and reversed. This is reflection made spatial — not a function call but a place you inhabit.

## Projection: The Shadow on a Direction

Projection answers one question: how much of vector **A** lies along vector **B**? Not the full arrow — just the component that aligns with **B**. The rest is discarded. Dimensional reduction on purpose.

The scalar projection gives the signed length of the shadow:

```gdscript
# Scalar projection of A onto B
func scalar_projection(a: Vector3, b: Vector3) -> float:
    return a.dot(b.normalized())
```

The dot product measures alignment. Normalizing **B** ensures the result is a pure length, not scaled by **B**'s magnitude. Positive means **A** has a component in **B**'s direction. Negative means the component opposes **B**. Zero means **A** is perpendicular to **B** — no shadow at all.

The vector projection returns the actual arrow — the shadow as a vector, not just a length:

```
proj_b(A) = (A . B / B . B) * B
```

```gdscript
# Vector projection of A onto B
func vector_projection(a: Vector3, b: Vector3) -> Vector3:
    var b_dot_b := b.dot(b)
    if b_dot_b < 1e-8:
        return Vector3.ZERO  # Degenerate: can't project onto zero vector
    return (a.dot(b) / b_dot_b) * b
```

Two dot products. One division. One scalar multiplication. The result is a vector that points along **B** with a magnitude equal to the shadow of **A**. The denominator `b.dot(b)` is the squared length of **B** — it normalizes implicitly without computing a square root. When **B** is already a unit vector, `b.dot(b)` equals 1 and the formula simplifies to `a.dot(b) * b`.

The basis vectors rig from earlier maps decomposed a point into three components along the coordinate axes. That decomposition was projection — three projections, one per axis. The x-component of a vector is its projection onto i-hat. The y-component is its projection onto j-hat. The z is its projection onto k-hat. Components were projections all along.

```gdscript
# Basis decomposition IS three projections
var point := Vector3(3.0, 2.0, 4.0)

var proj_x := point.dot(Vector3.RIGHT) * Vector3.RIGHT    # Vector3(3, 0, 0)
var proj_y := point.dot(Vector3.UP) * Vector3.UP           # Vector3(0, 2, 0)
var proj_z := point.dot(Vector3.FORWARD) * Vector3.FORWARD # Vector3(0, 0, 4)

# Reconstruction: sum of projections equals original
var reconstructed := proj_x + proj_y + proj_z  # Vector3(3, 2, 4)
```

Three shadows, one per axis, perfectly reconstruct the original. This works because the basis vectors are orthonormal — unit length and mutually perpendicular. Projection onto orthogonal axes is lossless. The information isn't destroyed; it's sorted into bins.

## Decomposition: Parallel and Perpendicular

Projection onto an arbitrary direction splits a vector into exactly two parts: the component parallel to the direction, and the component perpendicular to it.

```gdscript
# Decompose A into parallel and perpendicular components relative to N
func decompose(a: Vector3, n: Vector3) -> Array:
    var parallel := vector_projection(a, n)
    var perpendicular := a - parallel
    return [parallel, perpendicular]
```

Subtraction extracts the perpendicular component. The full vector minus its shadow equals everything the shadow missed — the part that has no alignment with **N** at all. This is the geometric core of projection: any vector is the sum of its parallel and perpendicular parts relative to any direction.

```gdscript
var velocity := Vector3(3.0, 4.0, 0.0)
var surface_normal := Vector3(0.0, 1.0, 0.0)

var v_parallel := vector_projection(velocity, surface_normal)
# Vector3(0, 4, 0) — the component moving into the surface

var v_perpendicular := velocity - v_parallel
# Vector3(3, 0, 0) — the component sliding along the surface
```

A ball hits a floor. Its velocity has two parts: the component pushing into the surface (parallel to the normal) and the component sliding along it (perpendicular to the normal). Projection separates them. Collision response acts on one while preserving the other.

The QFEP framework's F term — the structural parameter — operates here as the surface itself. The normal defines an axis of order. The parallel component is the part that interacts with that structure. The perpendicular component passes through unchanged. Projection is the operation that sorts motion into "relevant to this surface" and "irrelevant to this surface." Structure as filter.

## Projection onto a Plane

Projecting onto a direction collapses to a line. Projecting onto a plane preserves two dimensions and collapses the third — the normal direction.

```gdscript
# Project a point onto a plane defined by a normal through the origin
func project_onto_plane(point: Vector3, plane_normal: Vector3) -> Vector3:
    var n := plane_normal.normalized()
    return point - point.dot(n) * n
```

One dot product, one scalar multiply, one subtraction. The formula removes the normal component and keeps everything else. The result lies on the plane — it has zero displacement along the normal.

```gdscript
# Project a 3D velocity onto the ground plane (Y-up)
var velocity := Vector3(2.0, -5.0, 3.0)
var ground_normal := Vector3.UP

var ground_velocity := project_onto_plane(velocity, ground_normal)
# Vector3(2, 0, 3) — the horizontal component of motion
```

The vertical component vanishes. Only the horizontal remains. This is what a character controller does every frame: project the intended movement onto the walkable surface. Slopes, ramps, uneven terrain — the normal changes but the operation stays the same. Project the movement direction onto the surface plane. Walk along the result.

The dark sphere in the map floats above the ground. Its position vector has a y-component that lifts it. If that position were projected onto the ground plane, the y would zero out and the sphere would sit at the origin — its "floor shadow." Projection strips the vertical and reveals horizontal placement.

```gdscript
# Where on the floor is the sphere's shadow?
var sphere_pos := Vector3(0, float_height + sphere_radius, 0)
var floor_shadow := project_onto_plane(sphere_pos, Vector3.UP)
# Vector3(0, 0, 0) — directly below, as expected for a centered sphere
```

The halo ring already sits at that shadow position. It is the projection made visible — a disc on the ground plane showing where the sphere would land if the y-component were removed. The artifact teaches projection before the formula is introduced.

## Reflection: Flipping the Perpendicular

Reflection preserves what's parallel and negates what's perpendicular — or equivalently, preserves what's perpendicular to the mirror and negates the normal component. The formula falls directly out of the decomposition:

```
reflect(A, N) = A - 2 * proj_N(A)
```

```gdscript
# Reflect vector A across a surface with normal N
func reflect_vector(a: Vector3, n: Vector3) -> Vector3:
    var n_unit := n.normalized()
    return a - 2.0 * a.dot(n_unit) * n_unit
```

Subtract the normal component once to reach the surface. Subtract it again to go the same distance on the other side. The factor of 2 is the geometry of mirrors — equal distance in, equal distance out.

```gdscript
# Ball bouncing off a horizontal floor
var incoming := Vector3(1.0, -3.0, 0.0)  # Moving right and down
var floor_normal := Vector3(0.0, 1.0, 0.0)

var reflected := reflect_vector(incoming, floor_normal)
# Vector3(1.0, 3.0, 0.0) — moving right and UP

# The horizontal component (1, 0, 0) is unchanged
# The vertical component flipped from -3 to +3
```

The ball keeps its horizontal motion. Only the vertical inverts. This is what "bounce" means mathematically: reflect the velocity across the surface normal. The angle of incidence equals the angle of reflection — not because of a separate rule, but because the reflection formula preserves the magnitude and flips exactly one component.

Godot provides reflection natively:

```gdscript
var incoming := Vector3(1.0, -3.0, 0.0)
var floor_normal := Vector3(0.0, 1.0, 0.0).normalized()
var bounced := incoming.reflect(floor_normal)
```

One method call. Under the hood, the same formula: subtract twice the normal projection. The function exists because reflection appears in collision response, optical ray tracing, audio propagation, and any system where things bounce.

## The Mirror Room

The room's symmetry is not decorative. Two halves of the space mirror each other across a central plane. A wall segment on the left has a corresponding segment on the right. The spatial layout physically demonstrates what the `reflect_vector` function computes — every position on one side has a reflected counterpart on the other.

Stand at position `(2, 0, 1)` in the left half. The mirror plane is at x = 0 with normal `(1, 0, 0)`. The reflected position is `(-2, 0, 1)`. Same y, same z, negated x. The room is built from this operation. Each structural element was placed once and reflected.

```gdscript
# Reflecting a position across a vertical mirror plane at x = 0
var original_pos := Vector3(2.0, 0.0, 1.0)
var mirror_normal := Vector3(1.0, 0.0, 0.0)

var reflected_pos := reflect_vector(original_pos, mirror_normal)
# Vector3(-2.0, 0.0, 1.0)
```

Reflection preserves distances. The reflected point is the same distance from the mirror as the original. Reflection preserves angles between vectors. If two walls meet at 90 degrees, their reflections meet at 90 degrees. What reflection does not preserve is handedness. A right-handed coordinate system becomes left-handed under reflection. Clockwise becomes counterclockwise. A screw that turns right now turns left.

This connects to the cross product from the previous map. The cross product of two reflected vectors equals the negative of the reflected cross product. Handedness flips. The right-hand rule becomes the left-hand rule on the other side of the mirror. Reflection is the first operation in the vector toolkit that breaks chirality — length and angle survive, but orientation does not.

## Collision Response

Projection and reflection combine in collision response. When a moving object hits a surface:

1. Decompose the velocity into normal and tangential components (projection).
2. Negate or scale the normal component (reflection with optional energy loss).
3. Reconstruct the velocity from the modified normal and the untouched tangential.

```gdscript
# Collision response with restitution (bounciness)
func bounce(velocity: Vector3, surface_normal: Vector3, restitution: float) -> Vector3:
    var n := surface_normal.normalized()
    var v_normal := velocity.dot(n) * n          # Normal component
    var v_tangent := velocity - v_normal          # Tangential component
    return v_tangent - restitution * v_normal     # Flip and scale normal
```

Restitution of 1.0 gives a perfect bounce — full reflection, no energy loss. Restitution of 0.0 gives a dead stop in the normal direction — the object slides along the surface with only its tangential velocity. Values between simulate rubber, wood, steel. The parameter controls how much of the normal component survives the flip.

```gdscript
# A ball at full bounce hits a tilted wall
var velocity := Vector3(5.0, 0.0, 0.0)  # Moving right
var wall_normal := Vector3(-0.707, 0.707, 0.0)  # Wall tilted 45 degrees

var bounced := bounce(velocity, wall_normal, 1.0)
# Redirects upward — the wall deflects horizontal motion into vertical
```

The tilted wall has a normal that is neither horizontal nor vertical. Projection onto that normal extracts the component of motion pushing into the wall. Negating it redirects the ball away from the wall. The tangential component — motion parallel to the wall surface — survives unchanged. The ball doesn't stop. It redirects.

This is where the QFEP dynamics term becomes concrete. The rate of change in velocity (acceleration) is determined by the surface's orientation (structure) and the incoming motion (state). The collision normal acts as the phi term — the coupling between state and structural constraint. The restitution parameter modulates how much energy the interaction preserves. Full restitution: the bounce is reversible. Zero restitution: energy is absorbed. The collision is a site where structure imposes order on motion.

## Mirrors and Light

Optical reflection follows the same vector math. A ray of light hits a surface. The reflected ray is the velocity reflection formula applied to the light direction:

```gdscript
# Optical ray reflection
func reflect_ray(incoming_dir: Vector3, surface_normal: Vector3) -> Vector3:
    var n := surface_normal.normalized()
    return incoming_dir - 2.0 * incoming_dir.dot(n) * n
```

Every mirror, every shiny surface, every specular highlight in a 3D renderer uses this formula. Ray tracing casts rays from the camera, reflects them off surfaces, and traces the reflected rays to find what the mirror shows. The recursive version — reflect, hit another surface, reflect again — produces multiple bounces. Each bounce is the same operation applied to the previous result.

```gdscript
# Trace a ray through multiple reflections
func trace_reflections(origin: Vector3, direction: Vector3,
                       max_bounces: int) -> Array[Vector3]:
    var path: Array[Vector3] = [origin]
    var dir := direction.normalized()

    for i in max_bounces:
        var hit := cast_ray(origin, dir)  # Engine raycast
        if not hit:
            break
        path.append(hit.position)
        dir = reflect_vector(dir, hit.normal)
        origin = hit.position + dir * 0.001  # Offset to avoid self-hit
    return path
```

The offset on the last line prevents the reflected ray from immediately hitting the same surface it just bounced off. A common numerical issue — the ray origin sits exactly on the surface, and floating-point imprecision causes it to intersect again. Nudging it slightly along the reflected direction solves the problem. Geometric correctness defeated by arithmetic reality, patched with an epsilon.

The mirror room invites this thinking. Light entering from one side reflects off the central boundary and illuminates the other side. The room's directional light at `[-0.4, -0.7, -0.4]` casts shadows that demonstrate projection — each shadow is a 2D projection of a 3D object onto the floor plane. Shadows are projections. Reflections are reflections. The room contains both operations in its visual language.

## What Projection and Reflection Preserve

Projection destroys information. It takes a 3D vector and reduces it to a 1D scalar (scalar projection) or a vector constrained to a single direction (vector projection). The perpendicular component is discarded. This is intentional — projection answers "how much along this direction" by ignoring everything else.

Reflection preserves magnitude. The reflected vector has the same length as the original. It preserves the angle relative to the mirror surface. It preserves the tangential component entirely. What it changes is the sign of one component — the normal projection. One component out of an arbitrary decomposition, negated. Minimal change, maximum geometric consequence.

```gdscript
# Reflection preserves magnitude
var v := Vector3(3.0, -4.0, 1.0)
var n := Vector3(0.0, 1.0, 0.0)

var r := reflect_vector(v, n)
print(v.length())  # 5.099
print(r.length())  # 5.099 — identical
```

Length survives. Direction changes. The arrow rotates around the mirror surface without stretching or shrinking. This makes reflection the first reversible vector operation in the sequence beyond simple negation. Reflect twice across the same normal and the original vector returns. The operation is its own inverse.

```gdscript
# Double reflection = identity
var v := Vector3(3.0, -4.0, 1.0)
var n := Vector3(0.0, 1.0, 0.0)

var once := reflect_vector(v, n)
var twice := reflect_vector(once, n)
# twice == v — back where we started
```

This self-inverse property matters in simulation. If a physics engine reflects a velocity on collision, it can unreflect to recover the pre-collision state. Time reversal. The mirror room's symmetry encodes this — walk to the mirror, turn around, and the same geometry greets you. Forward and backward are the same path reflected.

## Possible Artifacts

**projection_reflection_tool** — An interactive artifact where the learner adjusts an incoming vector arrow and a surface normal arrow. The tool computes and displays three things simultaneously: the vector projection onto the normal (the shadow), the perpendicular remainder, and the full reflection. The shadow and remainder should be drawn as colored component arrows that sum to the original. The reflected vector appears on the opposite side of the surface, connected by a dashed path through the contact point. Dragging the normal rotates the decomposition axis in real-time — the parallel and perpendicular components redistribute as the surface tilts. Core gap identified in the intent: the room implies the geometry but provides no interactive decomposition.

**bounce_simulator** — A launchable ball that reflects off the mirror room's walls with adjustable restitution. The ball draws its velocity vector as a visible arrow, and on each collision the arrow decomposes into normal and tangential components before reassembling as the post-bounce velocity. A restitution slider ranges from 0.0 (dead stop against the wall, only tangential velocity survives) to 1.0 (perfect elastic bounce). At 0.5 the ball gradually loses energy and comes to rest. The simulation makes the collision response formula tactile — each bounce is a visible projection-negate-reconstruct cycle.

**shadow_caster** — An artifact that places geometric primitives (cube, sphere, pyramid) in the room and projects their silhouettes onto the floor and walls as flat colored shapes. The learner rotates a virtual light source and watches the shadow shapes deform as the projection direction changes. Orthographic projection produces uniform shadows; perspective projection produces diverging ones. Connects the vector projection formula to the everyday experience of shadows, and to the rendering pipeline where projection matrices transform 3D scenes into 2D screen coordinates.

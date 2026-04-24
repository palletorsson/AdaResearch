# Vector Advanced — Technical

Four islands push vectors from observation into action. Torque, bouncing, attraction, and throwing each demonstrate vector operations applied to physical dynamics.

## Torque

Torque is the cross product of the force application point (relative to the centre of mass) with the force itself. It produces rotational acceleration.

```gdscript
class_name TorqueRig extends RigidBody3D

func apply_off_center_force(force: Vector3, application_point: Vector3) -> void:
    var relative_point: Vector3 = application_point - global_position
    apply_force(force, relative_point)
    # Equivalent: apply central force + torque
    # var torque: Vector3 = relative_point.cross(force)
    # apply_central_force(force)
    # apply_torque(torque)
```

Godot's `apply_force(force, position)` handles both the linear and rotational components automatically.

## Bouncing

Reflection is the projection operation from VectorOperations applied to the velocity at impact. The reflected velocity is `v - 2*(v.n̂)*n̂` where n̂ is the surface normal.

```gdscript
func reflect_velocity(v: Vector3, n: Vector3) -> Vector3:
    return v - 2.0 * v.dot(n) * n

func _on_body_entered(body: Node, collision: KinematicCollision3D) -> void:
    var incoming: Vector3 = linear_velocity
    var normal: Vector3 = collision.get_normal()
    linear_velocity = reflect_velocity(incoming, normal) * restitution
```

## Attraction

An attractor pulls a satellite with a force proportional to the inverse square of distance — Newton's law of gravitation in miniature.

```gdscript
class_name Attractor extends Node3D

@export var mass: float = 100.0

func force_on(target: RigidBody3D) -> Vector3:
    var direction: Vector3 = global_position - target.global_position
    var distance: float = direction.length()
    if distance < 0.1: return Vector3.ZERO
    var force_magnitude: float = mass * target.mass / (distance * distance)
    return direction.normalized() * force_magnitude
```

## Steering

An agent follows a desired velocity by applying a steering force — the difference between desired and current velocities.

```gdscript
func steering_force(current_velocity: Vector3, target_position: Vector3, max_speed: float) -> Vector3:
    var desired: Vector3 = (target_position - global_position).normalized() * max_speed
    return desired - current_velocity
```

## Throwing

The throw releases an object with a velocity computed from the hand's recent motion.

```gdscript
var hand_positions: Array = []  # ring buffer of recent positions

func _process(delta: float) -> void:
    hand_positions.append(global_position)
    if hand_positions.size() > 8:
        hand_positions.pop_front()

func release() -> Vector3:
    if hand_positions.size() < 2: return Vector3.ZERO
    var recent: Vector3 = hand_positions[-1] - hand_positions[-3]
    var dt: float = 2.0 / Engine.get_frames_per_second()
    return recent / dt  # velocity in meters per second
```

## Complexity

Each station's arithmetic is O(1) per update. Integrating many particles under attraction is O(N²) if every pair interacts, which is the bottleneck in n-body simulation. The map limits pairwise attraction to a handful of bodies to stay real-time.

Within the sequence, VectorAdvanced ends the pure-vector sub-sequence. ForcesFoundations will next ground Newton's laws in physical demonstration.

## Inertia and Angular Velocity

Torque applied to a rigid body produces angular acceleration scaled by the inertia tensor. A uniform cube has a diagonal inertia tensor equal to (m/6) * side² in all three axes. A sphere has (2mr²/5) in all three axes. The angular equation of motion is I * ω_dot = τ, analogous to F = ma but with I replacing m and ω replacing v.

```gdscript
class_name RotatingBody extends Node3D

var angular_velocity: Vector3 = Vector3.ZERO
@export var inertia_diagonal: Vector3 = Vector3(1, 1, 1)

func apply_torque(torque: Vector3, delta: float) -> void:
    var angular_acceleration := Vector3(
        torque.x / inertia_diagonal.x,
        torque.y / inertia_diagonal.y,
        torque.z / inertia_diagonal.z
    )
    angular_velocity += angular_acceleration * delta
    rotate(angular_velocity.normalized(), angular_velocity.length() * delta)
```

Godot's RigidBody3D handles this internally; the code above exposes the mechanism.

## Attractor Stability

Orbit stability depends on the velocity-distance relationship. For circular orbit at radius r around mass M, the orbital velocity is sqrt(G*M/r). Too slow, and the satellite falls inward; too fast, and it escapes. The satellite's eccentricity measures how elliptical the orbit is; eccentricity 0 is circular, 1 is parabolic escape.

```gdscript
func orbital_velocity_for_circular(attractor_mass: float, radius: float) -> float:
    return sqrt(gravitational_constant * attractor_mass / radius)
```

## Steering Composition

Complex steering behaviours compose multiple simple ones: seek, flee, arrival, wander, align, cohere, separate. Each contributes a steering force; the total is their weighted sum.

```gdscript
class_name CompositeSteering

@export var seek_weight: float = 1.0
@export var flee_weight: float = 0.0
@export var wander_weight: float = 0.2

func compute_steering(agent, target) -> Vector3:
    var total := Vector3.ZERO
    total += seek(agent, target) * seek_weight
    total += flee(agent, threat) * flee_weight
    total += wander(agent) * wander_weight
    return total.limit_length(max_steering_force)
```

Craig Reynolds' classic "Steering Behaviors for Autonomous Characters" paper (1999) enumerates the full catalog. The map's fourth island uses a simplified subset.

## Throw Vector Estimation

Estimating throw velocity from hand motion requires sampling the hand's positions over a short window and computing a derivative. Too short a window produces noise; too long, lag. The map uses a 3-sample window at 60 Hz, giving 50 ms of smoothing.

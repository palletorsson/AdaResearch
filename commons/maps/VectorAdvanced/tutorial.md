# Vector Advanced

Torque, bouncing, attraction, throwing. Each station is a station for your body.

Apply an off-centre force.

```gdscript
func apply_off_center(body: RigidBody3D, force: Vector3, application_point: Vector3) -> void:
    var relative: Vector3 = application_point - body.global_position
    body.apply_force(force, relative)
```

Godot computes torque automatically from the offset. The body both translates and rotates.

Compute the torque from a force.

```gdscript
func torque(relative_point: Vector3, force: Vector3) -> Vector3:
    return relative_point.cross(force)
```

The cross product of position and force is the torque. Direction follows the right-hand rule.

Reflect a velocity off a surface.

```gdscript
func reflect(velocity: Vector3, surface_normal: Vector3) -> Vector3:
    return velocity - 2.0 * velocity.dot(surface_normal) * surface_normal
```

Subtract twice the velocity's normal component. The tangential component is preserved.

Handle a bounce with restitution.

```gdscript
func bounce(velocity: Vector3, normal: Vector3, restitution: float = 0.8) -> Vector3:
    return reflect(velocity, normal) * restitution
```

Restitution scales the reflected velocity. 1.0 is perfectly elastic; 0.0 is perfectly inelastic.

Compute attraction to a central mass.

```gdscript
func gravitational_pull(target: Vector3, attractor: Vector3, attractor_mass: float, G: float = 1.0) -> Vector3:
    var to_attractor: Vector3 = attractor - target
    var distance_sq: float = to_attractor.length_squared()
    if distance_sq < 0.01: return Vector3.ZERO
    return to_attractor.normalized() * G * attractor_mass / distance_sq
```

Newton's inverse-square law. The force magnitude falls off as distance squared; direction points from target toward attractor.

Steer toward a moving target.

```gdscript
func steer_to_target(current_velocity: Vector3, target_position: Vector3, target_velocity: Vector3, max_speed: float = 5.0) -> Vector3:
    var predicted: Vector3 = target_position + target_velocity * 0.5
    var desired: Vector3 = (predicted - current_velocity).normalized() * max_speed
    return desired - current_velocity
```

Lead the target by half a second. The steering force pushes toward the predicted future position.

Record a throw vector.

```gdscript
var hand_positions: Array = []

func record_hand_position(p: Vector3) -> void:
    hand_positions.append(p)
    if hand_positions.size() > 8: hand_positions.pop_front()

func release_velocity() -> Vector3:
    if hand_positions.size() < 2: return Vector3.ZERO
    var recent: Vector3 = hand_positions[-1] - hand_positions[-3]
    return recent / 0.033  # ~30 Hz sampling
```

A short ring buffer of recent hand positions. The throw velocity is the recent derivative.

You can now apply torque, reflect, attract, steer, and throw. ForcesFoundations will next ground these operations in Newton's three laws.

Wrap a small orbit around an attractor.

```gdscript
func wrap_orbit(satellite: RigidBody3D, attractor: Vector3, orbital_speed: float) -> void:
    var radial: Vector3 = (satellite.global_position - attractor).normalized()
    var tangent: Vector3 = radial.cross(Vector3.UP).normalized()
    satellite.linear_velocity = tangent * orbital_speed
```

The tangent is perpendicular to the radial direction. Setting velocity along the tangent produces circular motion.

Check whether a throw will clear a target.

```gdscript
func will_throw_reach(start: Vector3, target: Vector3, throw_speed: float) -> bool:
    var horizontal: Vector3 = Vector3(target.x - start.x, 0, target.z - start.z)
    var vertical: float = target.y - start.y
    var range_max: float = throw_speed * throw_speed / 9.81
    return horizontal.length() <= range_max
```

Maximum range is v²/g at 45°. Any target within the range can be reached with some launch angle.

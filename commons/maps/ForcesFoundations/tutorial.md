# Forces Foundations

Newton's laws, enacted. A sliding block, two carts on a spring, a jump pad.

Demonstrate F = ma.

```gdscript
func apply_push_to_block(block: RigidBody3D, force: Vector3) -> void:
    block.apply_central_force(force)
    var acceleration: Vector3 = force / block.mass
    print("F=%s, m=%s, a=%s" % [force, block.mass, acceleration])
```

Godot's physics integrator does the arithmetic internally. The print statement makes the relationship explicit.

Double the mass, halve the acceleration.

```gdscript
func test_f_equals_ma() -> void:
    var block := spawn_block(1.0)  # 1 kg
    apply_push_to_block(block, Vector3.RIGHT * 10)  # 10 N
    # Expect acceleration 10 m/s²
    
    var heavy := spawn_block(2.0)  # 2 kg
    apply_push_to_block(heavy, Vector3.RIGHT * 10)  # 10 N
    # Expect acceleration 5 m/s²
```

Same force, different masses, different accelerations. The ratio is exactly the mass ratio.

Connect two carts with a spring.

```gdscript
func spring_between(a: RigidBody3D, b: RigidBody3D, k: float, rest_length: float) -> void:
    var displacement: Vector3 = b.global_position - a.global_position
    var current_length: float = displacement.length()
    var force_magnitude: float = k * (current_length - rest_length)
    var force_on_a: Vector3 = displacement.normalized() * force_magnitude
    a.apply_central_force(force_on_a)
    b.apply_central_force(-force_on_a)
```

Equal and opposite forces on the two carts. Newton's third law appears as the symmetry of the forces.

Launch a projectile from a cannon.

```gdscript
func fire_cannon(cannon_position: Vector3, direction: Vector3, muzzle_velocity: float) -> RigidBody3D:
    var projectile := RigidBody3D.new()
    projectile.global_position = cannon_position
    projectile.linear_velocity = direction.normalized() * muzzle_velocity
    get_tree().root.add_child(projectile)
    return projectile
```

Initial velocity plus gravity produces a parabolic trajectory. Godot handles the integration.

Apply kinematic friction.

```gdscript
func friction_force(velocity: Vector3, normal_force: float, mu: float = 0.3) -> Vector3:
    if velocity.length() < 0.001: return Vector3.ZERO
    return -velocity.normalized() * mu * normal_force
```

Opposes motion, proportional to the normal force. The coefficient mu is material-specific.

Apply quadratic drag.

```gdscript
func drag_force(velocity: Vector3, drag_coefficient: float = 0.5) -> Vector3:
    var speed: float = velocity.length()
    if speed < 0.001: return Vector3.ZERO
    return -velocity.normalized() * drag_coefficient * speed * speed
```

Drag increases with the square of speed. Terminal velocity is where drag equals the driving force.

Build a jump pad.

```gdscript
func _on_jump_pad_body_entered(body: CharacterBody3D) -> void:
    var impulse := Vector3(0, 10, -15)  # up and forward
    body.velocity = impulse
```

Sets the body's velocity directly. The arc is governed by gravity after release.

You can now push a block, observe F=ma, couple carts with springs, fire projectiles, apply friction and drag, and trigger jump pads. ForcesComposition will next consolidate every operation into one workbench.

Compute projectile range at 45°.

```gdscript
func max_range(muzzle_velocity: float, gravity: float = 9.81) -> float:
    return muzzle_velocity * muzzle_velocity / gravity
```

The closed-form range formula for 45° launch angle. Higher or lower angles reduce range.

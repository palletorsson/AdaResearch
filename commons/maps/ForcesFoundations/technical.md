# Forces Foundations — Technical

Three islands demonstrate Newton's three laws, projectile motion, and friction-plus-drag. A jump pad between islands is itself a Newton's second law demonstration — an impulse applied to the learner's body.

## Newton's Second Law

F = ma: force equals mass times acceleration. The sliding block's resistance to push scales with mass.

```gdscript
class_name SlidingBlock extends RigidBody3D

func apply_push(force: Vector3) -> void:
    apply_central_force(force)
    # Godot's physics integrator computes acceleration = force / mass
    # and updates velocity by acceleration * delta

# Explicit display of the relationship
func _physics_process(delta: float) -> void:
    var acceleration: Vector3 = (linear_velocity - last_velocity) / delta
    var net_force: Vector3 = acceleration * mass
    update_display(net_force, mass, acceleration)
    last_velocity = linear_velocity
```

## Newton's Third Law

Two carts on a shared spring demonstrate action-reaction. When either cart is pushed, the spring transmits an equal and opposite force to the other cart.

```gdscript
class_name SpringCartPair extends Node3D

@export var spring_k: float = 10.0
@export var rest_length: float = 2.0

var cart_a: RigidBody3D
var cart_b: RigidBody3D

func _physics_process(_delta: float) -> void:
    var separation: Vector3 = cart_b.global_position - cart_a.global_position
    var current_length: float = separation.length()
    var displacement: float = current_length - rest_length
    var force_magnitude: float = spring_k * displacement
    var force_on_a: Vector3 = separation.normalized() * force_magnitude
    var force_on_b: Vector3 = -force_on_a
    cart_a.apply_central_force(force_on_a)
    cart_b.apply_central_force(force_on_b)
```

## Projectile Motion

A projectile's trajectory under gravity alone is a parabola: horizontal velocity is constant, vertical velocity decreases linearly due to gravity.

```gdscript
class_name Cannon extends Node3D

@export var muzzle_velocity: float = 20.0

func fire(direction: Vector3) -> void:
    var projectile: RigidBody3D = PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = direction.normalized() * muzzle_velocity
    get_tree().root.add_child(projectile)
    # From here, Godot's gravity handles the parabolic trajectory
```

The jump pad is a similar mechanism applied to the player. An impulse sends the learner's body on a parabolic arc across the gap.

## Friction and Drag

Friction opposes motion proportional to the normal force. Drag opposes motion proportional to the velocity squared (for high Reynolds numbers).

```gdscript
class_name FrictionRamp extends RigidBody3D

@export var friction_coefficient: float = 0.3

func _physics_process(delta: float) -> void:
    var normal_force: Vector3 = -gravity * mass * cos(slope_angle)
    var friction_magnitude: float = friction_coefficient * normal_force.length()
    var friction: Vector3 = -linear_velocity.normalized() * friction_magnitude
    apply_central_force(friction)

# Drag force
func drag_force(velocity: Vector3, drag_coefficient: float) -> Vector3:
    var speed: float = velocity.length()
    return -velocity.normalized() * drag_coefficient * speed * speed
```

## Complexity

Godot's physics engine handles the heavy lifting — each rigid body is O(1) per step to integrate, and collision detection is O(N log N) with spatial partitioning. The map's bodies are few enough that performance is not a concern.

Within the sequence, Foundations sets the vocabulary ForcesComposition will next consolidate into a single workbench.

## Integration Methods

Godot's physics integrator is semi-implicit Euler by default — compute accelerations, advance velocities, then advance positions using the new velocities. This is stable for typical rigid body dynamics and simple to implement.

```gdscript
# Semi-implicit Euler
func integrate(delta: float) -> void:
    velocity += force / mass * delta
    position += velocity * delta
```

More accurate methods include Verlet (preserves energy better), RK4 (higher-order accuracy), and symplectic integrators (conserve phase-space volume). The trade-off is accuracy versus performance; semi-implicit Euler is the game-industry default because it is cheap and behaves reasonably.

## Friction Models

The Coulomb friction model uses a coefficient of friction times the normal force. Real materials have two coefficients: static (the threshold required to start moving) and kinetic (the resistance during sliding), with static usually larger than kinetic. This produces the characteristic "stick-slip" behaviour — objects stick in place until pushed hard enough, then slide.

```gdscript
func friction_force(velocity: Vector3, normal_force: Vector3, mu_static: float, mu_kinetic: float) -> Vector3:
    var speed: float = velocity.length()
    var coefficient: float = mu_kinetic if speed > 0.01 else mu_static
    return -velocity.normalized() * coefficient * normal_force.length()
```

## Drag at Different Reynolds Numbers

Linear drag (proportional to velocity) applies at low Reynolds numbers — small particles in viscous fluid. Quadratic drag (proportional to velocity squared) applies at high Reynolds numbers — typical everyday objects. Terminal velocity is where drag equals gravity; the object stops accelerating and falls at a constant speed.

```gdscript
func terminal_velocity(mass: float, drag_coefficient: float, cross_section: float, fluid_density: float) -> float:
    var g: float = 9.81
    return sqrt(2.0 * mass * g / (drag_coefficient * cross_section * fluid_density))
```

## Jump Pad Physics

The jump pad applies a single impulse (force integrated over an infinitesimal time) to the learner's body. The resulting trajectory is the classic parabolic projectile arc.

```gdscript
class_name JumpPad extends Area3D

@export var impulse: Vector3 = Vector3(0, 15, -10)

func _on_body_entered(body: CharacterBody3D) -> void:
    if body.has_method("apply_impulse"):
        body.apply_impulse(impulse)
    else:
        body.velocity = impulse  # approximate for non-rigid
```

The impulse's magnitude and direction are tuned to land the learner on the adjacent island; too much energy overshoots, too little undershoots.

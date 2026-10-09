# Pendulum

Gravity creates rhythm. Build a weight on a string and watch sine become physical.

Declare the pendulum state.

```gdscript
class_name Pendulum
extends Node3D

@export var length: float = 2.0
@export var gravity: float = 9.81
@export var angle: float = 0.3
var angular_velocity: float = 0.0
```

Length, gravity, angle, angular velocity. Four numbers describe the entire swing.

Integrate the small-angle equation.

```gdscript
func step(dt: float) -> void:
    var accel: float = -(gravity / length) * sin(angle)
    angular_velocity += accel * dt
    angle += angular_velocity * dt
```

Newton's second law applied to arc length. For small angles, `sin(angle)` approaches angle and the motion becomes simple harmonic.

Position the bob.

```gdscript
func update_bob(bob: Node3D, pivot: Vector3) -> void:
    bob.position = pivot + Vector3(sin(angle) * length, -cos(angle) * length, 0.0)
```

The bob hangs below the pivot. At zero angle, it is directly under. The shape of the swing is a circular arc.

Display the period.

```gdscript
func period() -> float:
    return TAU * sqrt(length / gravity)
```

The formula reads as a signature. Longer strings swing slower; stronger gravity swings faster. Nothing depends on mass.

Trace the angle against time.

```gdscript
func trace_angle(line: Line2D, time: float) -> void:
    line.add_point(Vector2(time * 60.0, -angle * 80.0))
    if line.get_point_count() > 240:
        line.remove_point(0)
```

The trace is a scrolling sine wave. The pendulum in the air and the green line on the scope show the same motion.

Add the Foucault twist.

```gdscript
func apply_foucault(dt: float, latitude_deg: float) -> void:
    var omega: float = 0.000072921
    var angle_of_plane: float = omega * sin(deg_to_rad(latitude_deg)) * dt
    pivot_yaw += angle_of_plane
```

At non-equator latitudes, Earth's rotation twists the swing plane. The room rotates slowly around a stationary pendulum. Geography becomes a parameter.

Introduce the double pendulum.

```gdscript
func step_double(dt: float, b: Pendulum) -> void:
    b.angular_velocity += coupled_accel(self, b) * dt
    b.angle += b.angular_velocity * dt
```

Two pendulums coupled at a pivot. Energy flows between them. Chaos emerges because the coupled equations have no closed-form solution.

You have met sine as gravity's handwriting. The next map, Sine Space, turns the wave spatial.
<<</MAP>>>

Draw the path of the bob as a fading trail.

```gdscript
func update_trail(trail: Line3D) -> void:
    trail.add_point(bob.position)
    if trail.get_point_count() > 80:
        trail.remove_point(0)
```

The arc of the swing becomes visible as a fading curve. Motion leaves a readable mark.

Pause on apex.

```gdscript
func pause_on_apex() -> void:
    if abs(angular_velocity) < 0.02:
        paused_time += get_process_delta_time()
```

The apex is where motion stops. A brief pause label highlights the moment. Pendulum physics becomes attention.

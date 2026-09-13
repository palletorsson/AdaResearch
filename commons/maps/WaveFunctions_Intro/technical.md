# A pendulum released by hand, among cubes told where to be

In Forces, oscillation was a side effect of a restoring force. This hall puts the repetition first. One pendulum is integrated step by step; around it stand cubes whose height is `sin` of a clock, cubes spinning at a constant rate, a cube driven by the pendulum's output, a screen and a time trace. The comparison is about state: what each object carries from one frame to the next, and what a hand can change.

## What the hall places

`commons/maps/WaveFunctions_Intro/map_data.json` is 13 by 22 cells, with the spawn at (0,0) and the teleporter at (4,19). Near the entrance, three small cubes at scale 0.2 stand at (2,4), (3,4) and (5,4): a plain `cube_scene`, a `transformation_cube` that bobs and a `rotating_cube` that spins. Behind them the labelled versions of those two motions, `y_oscillation_cube` at (3,5) and `rotating_cube_demo` at (5,5), and a single `science_screen` in `wave` mode at (7,5). Down the column x = 4 run `rotatescalecubes` (4,1), `pickup_cube_static` (4,2), `pickup_cube_transforming` (4,7), `pickup_cube_rotating` (4,8) and a `dark_sphere` (4,9).

The primary, `control_pendulum:0:1.5:1#reference:plumb#evidence:trace`, hangs at (2,11). Beside it, on the raised strip at x = 4, five `pick_up_cube` tokens from row 11 to row 15 carry the scales 0.6, 0.7, 0.8, 0.9 and 1.0 in their fourth field. Behind the pendulum stand `oscillation_controlled_cube` (2,13) and `mario_cube_time_trace` (6,13). Two `SphericalHarmonics` instruments at (1,18) and (7,18) close the hall.

## The equation the pendulum steps

As a formula, the motion of a rigid pendulum of length L under gravity g is:

```
θ'' = -(g/L)·sin θ
```

The script never solves this. It steps it, once per physics frame, in `_physics_process` of `commons/artifacts/control_pendulum/control_pendulum.gd`:

```gdscript
var angular_acceleration: float = -(gravity / pendulum_length) * sin(_angle)
if regime == "resonance":
    _drive_t += delta
    angular_acceleration += _drive_accel() * cos(_omega0() * _drive_t)
_angular_velocity += angular_acceleration * delta
_angular_velocity *= _damping_multiplier(delta)
_angle += _angular_velocity * delta
...
_angle = clampf(_angle, -PI * 0.45, PI * 0.45)
```

The placement names no `regime`, so the default `free` runs and the drive lines never execute. Velocity is updated first and moves the angle: semi-implicit Euler. The sine sits in the acceleration, not the position, and nothing here reads a clock; `delta` is only the step size. The whole state is two numbers, `_angle` and `_angular_velocity`. The clamp at ±0.45π stops a hard release from carrying the bob over the pivot.

Under `free`, `_damping_multiplier` returns the raw export `damping`, 0.995 per physics frame, which the file's own comment puts at a damping ratio of ζ = 0.037 against ω₀ = √(g/L). With `gravity` 9.8 and `pendulum_length` 0.6, the familiar period is a small-angle result. As a formula:

```
sin θ ≈ θ   gives   T = 2π·√(L/g)
```

The integrator never makes that substitution, so a wide release swings more slowly than T says. The token lifts the pivot 1.5 and the rod is 0.6 long; the probe below measured the rest point at 0.90 m.

## The release is an initial condition

While the bob is held, `commons/artifacts/control_pendulum/control_pendulum.gd` stops integrating. It reads the angle back from wherever the bob is and zeroes the velocity:

```gdscript
var local_pos = to_local(_bob_sphere.global_position)
var new_angle = atan2(local_pos.x, -local_pos.y)
new_angle = clampf(new_angle, -PI * 0.45, PI * 0.45)
...
_last_bob_position = current_pos
_angle = new_angle
_angular_velocity = 0.0
```

It also keeps the last five frame-to-frame velocities of the bob. On release, `_on_bob_dropped` in `commons/artifacts/control_pendulum/control_pendulum.gd` averages them, turns them into the pivot's frame and keeps only the part along the swing:

```gdscript
avg_velocity /= _grab_velocity_samples.size()
...
avg_velocity = global_basis.inverse() * avg_velocity
...
var tangent_direction = Vector3(cos(_angle), sin(_angle), 0)
var tangent_velocity = avg_velocity.dot(tangent_direction)
_angular_velocity = tangent_velocity / pendulum_length
```

The sign of that tangent follows from where the free pendulum puts the bob, in the same `commons/artifacts/control_pendulum/control_pendulum.gd`:

```gdscript
func _update_bob_position():
    # Calculate bob position from angle
    if _bob_sphere and not _is_grabbed:
        var bob_x = sin(_angle) * pendulum_length
        var bob_y = -cos(_angle) * pendulum_length
        _bob_sphere.global_position = to_global(Vector3(bob_x, bob_y, 0))
```

Differentiating that position with respect to the angle gives the tangent. As a formula:

```
bob(θ)     = L·( sin θ, -cos θ )
d bob / dθ = L·( cos θ,  sin θ )
```

An earlier version of this document printed the tangent with both components negated, which would reverse every angular velocity taken from a throw. The hand gives the pendulum exactly two numbers: `atan2` discards how far from the pivot the bob was held, and the dot product discards sideways motion. On the next free frame `_update_bob_position` returns the bob to its circle.

## A desktop hand

VR reaches those handlers through the pickable's own signals, connected in `_create_grabbable_bob`. A desktop visitor has no pickable signals: the pointer in `commons/scenes/DesktopInteractionPointer.gd` carries a RigidBody on right-click and puts it down on the next one:

```gdscript
if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
    if _held:
        _drop_held()
    else:
        var p := _find_grabbable()
        if p:
            _grab_held(p)
```

The bob is a grab-sphere scene shared by many artifacts, so the hooks cannot live in the bob's own script. Since 2026-09-13 `commons/scenes/DesktopInteractionPointer.gd` asks the carried body who should hear the carry, and calls that object from `_grab_held`, and from `_drop_held` once freeze and collision layers are restored:

```gdscript
func _desktop_hook_target(p: Node) -> Object:
    if p != null and is_instance_valid(p) and p.has_meta("desktop_hook_target"):
        var t: Variant = p.get_meta("desktop_hook_target")
        if t is Object and is_instance_valid(t):
            return t
    return p
...
var grab_hook: Object = _desktop_hook_target(p)
if grab_hook != null and grab_hook.has_method("on_desktop_grab"):
    grab_hook.call("on_desktop_grab", self)
...
var drop_hook: Object = _desktop_hook_target(_held)
if drop_hook != null and drop_hook.has_method("on_desktop_drop"):
    drop_hook.call("on_desktop_drop", self)
```

The pendulum names itself on its bob and routes both hooks into the same handlers the VR signals reach, in `commons/artifacts/control_pendulum/control_pendulum.gd`:

```gdscript
if _bob_sphere.has_signal("picked_up"):
    _bob_sphere.picked_up.connect(_on_bob_picked_up)
if _bob_sphere.has_signal("dropped"):
    _bob_sphere.dropped.connect(_on_bob_dropped)
...
_bob_sphere.set_meta("desktop_hook_target", self)
...
func on_desktop_grab(_pointer: Node) -> void:
    if _bob_sphere != null and not _is_grabbed:
        _on_bob_picked_up(_bob_sphere)
...
func on_desktop_drop(_pointer: Node) -> void:
    if _bob_sphere != null and _is_grabbed:
        _on_bob_dropped(_bob_sphere)
```

Before this, a desktop carry never reached the pendulum, so the integrator kept rewriting the bob's position. The pointer froze and moved the bob, but `_is_grabbed` stayed false, so the guard in `_update_bob_position` passed and the bob was put back on its circle every physics frame; the release handler never ran. The pointer also eases a carried body towards a point in front of the camera, so the velocity samples measure that eased motion, not the mouse.

## Two visits to the centre

`reference:plumb` builds a hairline from the pivot to the rest point and a ring there that the bob threads. In `commons/artifacts/control_pendulum/control_pendulum.gd` a crossing is a sign change of the angle while the bob is moving:

```gdscript
if signf(_angle) != signf(_prev_angle) and signf(_angle) != 0.0 \
        and absf(_angular_velocity) > CROSSING_MIN_OMEGA:
    _crossings += 1
    _last_crossing_dir = 1 if _angular_velocity > 0.0 else -1
    _ring_glow = 1.0
    centre_crossed.emit(_last_crossing_dir, _angular_velocity)
...
var line := "θ %+.1f°   ω %+.2f rad/s" % [rad_to_deg(_angle), _angular_velocity]
```

The label prints the signed angular velocity, because the sign is what tells two visits to the same place apart.

A live probe on 2026-09-13 carried the bob with the pointer's right-click and released it from +0.600 rad and from -0.600 rad at ω = 0.0, both values read inside the pendulum's own `released` signal. After the right release, the first two crossings were ω = -2.250 then +1.996 rad/s. After the left release they were +2.249 then -1.995. The bob passes θ = 0 at each crossing, so position alone cannot distinguish them; the velocity has opposite signs. The two releases are mirror images, differing only in the third decimal, as they should be for an equation odd in θ. The second crossing in each pair is slower than the first, which is the 0.995 multiplier at work.

During the swing the bob's x ran from 2.17 to 2.83 in the hall's cell coordinates. The aisle at that row is 1.11 m clear of the swing on each side, and at the clamp of ±0.45π the worst case is 0.85 m.

## The predicted trace

`evidence:trace` draws θ(t) behind the swing for six seconds, computed at build time by `_predict` in `commons/artifacts/control_pendulum/control_pendulum.gd` with the same rule, from the fixed `START_ANGLE` of 0.3 rather than from any release:

```gdscript
var th: float = START_ANGLE
...
var acc: float = -(gravity / pendulum_length) * sin(th)
...
om += acc * dt
om *= mult
th += om * dt
```

The curve is a prediction, not a record, so a release from 0.6 rad will not match it.

## Motions told where to be

`y_oscillation_cube` keeps one number, a clock, in `commons/artifacts/y_oscillation_cube/y_oscillation_cube.gd`:

```gdscript
    _time += delta
...
var omega = frequency * TAU  # ω = 2πf
var sin_value = sin(omega * _time)
var y_offset = amplitude * sin_value
...
_cube_mesh.position.y = _base_y + y_offset
```

With no config, `_time` simply accumulates; `amplitude` is 0.2 and `frequency` 1.0. There is no velocity variable: every frame the position is a fresh evaluation of the formula, so a disturbance would have nowhere to persist. `commons/primitives/cubes/animation/TransformationTween.gd`, under `transformation_cube` and `pickup_cube_transforming`, does the same with `var bob_offset = sin(time_passed * bob_speed) * bob_height`. The five pick-up cubes do it too, in `commons/scenes/mapobjects/pick_up_cube.gd`:

```gdscript
rotate_y(rotation_speed * delta)
...
time_passed += delta
var bob_offset = sin(time_passed * bob_speed) * bob_height
global_position.y = original_y + bob_offset
```

Because the bob writes `global_position.y`, the five sizes share one amplitude in metres.

## Constant rotation

`rotating_cube_demo` is an accumulator, in `commons/artifacts/rotating_cube_demo/rotating_cube_demo.gd`:

```gdscript
_current_angle += rotation_speed * delta
...
    _cube_instance.rotation.y = _current_angle
```

Its first line has the shape of the pendulum's `_angle += _angular_velocity * delta`, but `rotation_speed` is a constant 1.5 and nothing feeds the angle back into the rate. It returns to an orientation every 2π by geometry alone, never slowing, never turning back. `rotating_cube` and `pickup_cube_rotating` spin the same way through `target_node.rotate_y(rotation_speed * delta)` in `commons/primitives/cubes/animation/RotationTween.gd`.

## One signal, three transformations

Every physics frame, held or free, the pendulum emits its state in `commons/artifacts/control_pendulum/control_pendulum.gd`:

```gdscript
current_y_offset = sin(_angle) * pendulum_length
current_angular_velocity = _angular_velocity
current_amplitude = abs(_angle) / (PI * 0.45)  # Normalized 0-1
...
oscillation_updated.emit(current_y_offset, current_angular_velocity, current_amplitude)
```

Despite its name, `y_offset` is the bob's horizontal displacement. `commons/artifacts/oscillation_controlled_cube/oscillation_controlled_cube.gd` looks among its parent's children for a `ControlPendulum`, connects, and maps the three values onto height, heading and size:

```gdscript
if _pendulum and _pendulum.has_signal("oscillation_updated"):
    _pendulum.oscillation_updated.connect(_on_oscillation_updated)
...
position.y = _base_position.y + (y_offset * translation_scale if _face_height else 0.0)
...
    _current_rotation += angular_velocity * rotation_scale * get_process_delta_time()
...
var scale_factor = (lerp(scale_range.x, scale_range.y, amplitude) if _face_size else 1.0)
```

While the bob is held the signal keeps coming: the cube's height follows the held angle, its spin stops because the held velocity is 0.0, and its size follows |θ|.

## The screen and the time trace

Two seconds after it enters the tree, the screen looks once among its siblings for the nearest node with an `_angle` property, closer than `scan_radius + 1.0`. In this hall only the pendulum's script declares one; if nothing is found, the screen draws from its own defaults. It then draws, in `commons/artifacts/science_screen/science_screen.gd`:

```gdscript
var t: float = Time.get_ticks_msec() / 1000.0
...
if "current_amplitude" in art: amplitude = float(art.get("current_amplitude"))
if "current_angular_velocity" in art: angular_vel = float(art.get("current_angular_velocity"))
if "_angle" in art: cur_angle = float(art.get("_angle"))
...
if cur_angle != 0.0:
    frequency = maxf(absf(angular_vel) / TAU, 0.1)
...
var y_val: float = amplitude * sin(frequency * (x_val + t) * TAU + cur_angle)
```

The screen is a told-where-to-be curve with borrowed parameters: a sine of the wall clock whose amplitude, frequency and phase are the pendulum's state of the moment. Its wave is flattest exactly when the bob passes the centre fastest, because the normalised amplitude is then near zero.

`mario_cube_time_trace` records, but not the pendulum. Its target is its own child `PickUpCube`, in `commons/scenes/mapobjects/mario_cube_time_trace.gd`:

```gdscript
var z_offset = time_axis_speed * delta
for i in range(_trail_points.size()):
    _trail_points[i].z += z_offset
...
var current_global = _target.global_position
...
var trace_point = Vector3(current_global.x, current_global.y, _origin_z)
_trail_points.append(trace_point)
```

The scene sets `time_axis_speed` to 0.6. Left alone, the child runs the pick-up bob, so the trace lays a prescribed sine out along +Z: time turned into distance. The pendulum keeps its own past only as a crossing count and a last direction.

## The rest of the room

`dark_sphere` breathes on the same pattern as the clock cubes, in `commons/artifacts/dark_sphere/dark_sphere.gd`:

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min * _emit_mul, pulse_max * _emit_mul, pulse_t)
```

`rotatescalecubes` is a MultiMesh field of cubes each turning at its own rate, and `SphericalHarmonics` sends a small sphere around a large one with a square-wave chirp. The three `pickup_cube_*` tokens share `commons/primitives/cubes/pickups/pickup_wrapper.gd`, whose scenes set every rate on the wrapper to zero; their motion comes from the cube scene inside.

The hall sets three kinds of state side by side. A clock cube holds time and nothing else. A spinning cube holds an angle and a constant rate. The pendulum holds an angle and a velocity that feed each other, which is why a hand can give it a new beginning and why its centre can be visited in two directions.

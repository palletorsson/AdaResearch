<<<ADA_BUNDLE>>>
sequence: transformation
file: tutorial.md
maps: 8
skipped_passing: 0
created: 2026-04-24T02:45:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Trans_Introduction>>>
# Transformation Introduction

Three transformations, three lanes. Translate, rotate, scale.

Define a transform from scratch.

```gdscript
var t := Transform3D.IDENTITY
```

The identity transform: origin at zero, no rotation, unit scale.

Apply translation.

```gdscript
func translate(t: Transform3D, offset: Vector3) -> Transform3D:
    return t.translated(offset)
```

Adds the offset to the origin. The orientation and scale are preserved.

Apply rotation.

```gdscript
func rotate_y(t: Transform3D, angle_rad: float) -> Transform3D:
    return t.rotated(Vector3.UP, angle_rad)
```

Rotates around the Y axis by the given angle. Other axes work the same way.

Apply scale.

```gdscript
func scale(t: Transform3D, factors: Vector3) -> Transform3D:
    return t.scaled(factors)
```

Scales each axis independently. Uniform scale uses Vector3.ONE times a single factor.

Compose three transforms in order.

```gdscript
func srt(position: Vector3, rotation_rad: Vector3, scale_factors: Vector3) -> Transform3D:
    var t := Transform3D.IDENTITY
    t = t.scaled(scale_factors)
    t = t.rotated(Vector3.UP, rotation_rad.y)
    t = t.rotated(Vector3.RIGHT, rotation_rad.x)
    t = t.rotated(Vector3.FORWARD, rotation_rad.z)
    t.origin = position
    return t
```

Scale, then rotate, then translate. The order matters: different orders produce different final transforms.

Build a transport cube.

```gdscript
class_name TransportCube extends StaticBody3D

@export var translation_offset: Vector3 = Vector3(3, 0, 0)

func activate(target: Node3D) -> void:
    target.global_position += translation_offset
```

Picking up the cube teleports the target by the offset. Translation as a gap-closing move.

Build a rotation cube.

```gdscript
class_name RotationCube extends StaticBody3D

@export var rotation_axis: Vector3 = Vector3.UP
@export var rotation_angle_deg: float = 90.0

func activate(target: Node3D) -> void:
    target.rotate(rotation_axis, deg_to_rad(rotation_angle_deg))
```

Ninety degrees around a chosen axis. Rotation as a reorientation.

Build a scale cube.

```gdscript
class_name ScaleCube extends StaticBody3D

@export var scale_factor: float = 2.0

func activate(target: Node3D) -> void:
    target.scale *= scale_factor
```

Doubles the target's size. Scale as a presence expansion.

You can now compose scale, rotate, and translate in order, and build lane cubes that enact each transformation. Trans_Translation extends translation into its own detailed map.

<<<MAP: Trans_Translation>>>
# Trans Translation

Moving. Displacement. Position as coefficients.

Translate a single object.

```gdscript
func move_to(node: Node3D, target: Vector3) -> void:
    node.global_position = target
```

Direct assignment. One frame, the object is there.

Translate smoothly over time.

```gdscript
func tween_to(node: Node3D, target: Vector3, duration: float) -> void:
    var tween := create_tween()
    tween.tween_property(node, "global_position", target, duration)
```

The tween interpolates linearly. Duration in seconds.

Translate along a local axis.

```gdscript
func move_forward(node: Node3D, distance: float) -> void:
    var forward: Vector3 = -node.global_transform.basis.z
    node.global_position += forward * distance
```

Local translation respects the node's current orientation. Forward is -Z in Godot.

Apply a translation impulse to a rigid body.

```gdscript
func nudge(body: RigidBody3D, impulse: Vector3) -> void:
    body.apply_central_impulse(impulse)
```

Impulse is velocity times mass. Physics integrates the impulse into velocity on the next step.

Translate relative to another node.

```gdscript
func move_relative_to(node: Node3D, reference: Node3D, offset_local: Vector3) -> void:
    var offset_world: Vector3 = reference.global_transform.basis * offset_local
    node.global_position = reference.global_position + offset_world
```

Local offset is transformed through the reference's basis. The result is a world-space position.

Chain multiple translations.

```gdscript
func move_sequence(node: Node3D, steps: Array, duration_per_step: float) -> void:
    var tween := create_tween().set_parallel(false)
    for target in steps:
        tween.tween_property(node, "global_position", target, duration_per_step)
```

Sequential tweens move the node through a sequence of positions. Useful for scripted paths.

Interpolate along a curved path.

```gdscript
func move_along_bezier(node: Node3D, curve: Curve3D, duration: float) -> void:
    var tween := create_tween()
    tween.tween_method(
        func(t): node.global_position = curve.sample_baked(t * curve.get_baked_length()),
        0.0, 1.0, duration
    )
```

Sample the Bezier curve at interpolated positions. The node follows the curve's shape over the duration.

You can now translate a node instantly or over time, locally or relative to another node, along straight lines or curves. Trans_AxisDecomposition extends the translation into component-wise thinking.

<<<MAP: Trans_AxisDecomposition>>>
# Axis Decomposition

Decompose any vector into its component along each axis.

Extract the components.

```gdscript
func components_on_axes(v: Vector3) -> Array:
    return [v.x, v.y, v.z]
```

Direct access. The triple of components is a decomposition against the standard basis.

Compute the component along an arbitrary axis.

```gdscript
func component_along(v: Vector3, axis: Vector3) -> float:
    return v.dot(axis.normalized())
```

The dot product with a unit-length axis gives the signed projection. Positive if aligned, negative if opposing.

Reconstruct a vector from its components.

```gdscript
func reconstruct(cx: float, cy: float, cz: float) -> Vector3:
    return Vector3.RIGHT * cx + Vector3.UP * cy + Vector3.FORWARD * cz
```

Weighted sum of basis vectors. The reconstructed vector matches the original exactly.

Decompose against a custom basis.

```gdscript
func decompose_custom(v: Vector3, basis: Array) -> Array:
    return [v.dot(basis[0].normalized()), v.dot(basis[1].normalized()), v.dot(basis[2].normalized())]
```

Three dot products, one per basis vector. The basis must be orthogonal and normalised for correct reconstruction.

Visualise each component as a coloured arrow.

```gdscript
func draw_decomposition(v: Vector3) -> void:
    draw_arrow(Vector3.ZERO, Vector3.RIGHT * v.x, Color.RED)
    draw_arrow(Vector3.RIGHT * v.x, Vector3.RIGHT * v.x + Vector3.UP * v.y, Color.GREEN)
    draw_arrow(Vector3.RIGHT * v.x + Vector3.UP * v.y, v, Color.BLUE)
```

Three arrows, tip to tail. The sum reaches the original vector.

Sum multiple vectors component-wise.

```gdscript
func sum_components(vectors: Array) -> Vector3:
    var total := Vector3.ZERO
    for v in vectors:
        total += v
    return total
```

Each axis sums independently. The total's x is the sum of all x components, etc.

Project a vector onto a plane.

```gdscript
func project_onto_plane(v: Vector3, plane_normal: Vector3) -> Vector3:
    return v - v.project(plane_normal)
```

Subtract the component perpendicular to the plane. What remains lies in the plane.

You can now decompose a vector onto any basis, reconstruct it, and project it onto any plane. Trans_Rotation extends the geometric operations into angular space.

<<<MAP: Trans_Rotation>>>
# Trans Rotation

Rotation around an axis. Angles. Quaternions.

Rotate a node around the Y axis.

```gdscript
func rotate_y(node: Node3D, angle_rad: float) -> void:
    node.rotate(Vector3.UP, angle_rad)
```

The axis is the rotation's pivot. The angle is signed: positive counter-clockwise looking down the axis.

Rotate a vector without a node.

```gdscript
func rotate_vector(v: Vector3, axis: Vector3, angle_rad: float) -> Vector3:
    return v.rotated(axis.normalized(), angle_rad)
```

Vector3.rotated does the arithmetic directly. The axis must be unit length for correct results.

Rotate around a pivot point.

```gdscript
func rotate_around(node: Node3D, pivot: Vector3, axis: Vector3, angle_rad: float) -> void:
    var offset: Vector3 = node.global_position - pivot
    var rotated: Vector3 = offset.rotated(axis, angle_rad)
    node.global_position = pivot + rotated
    node.rotate(axis, angle_rad)
```

Translate to pivot frame, rotate, translate back. Both position and orientation update.

Chain three Euler-angle rotations.

```gdscript
func euler_rotate(node: Node3D, euler: Vector3) -> void:
    node.rotate(Vector3.UP, euler.y)
    node.rotate(Vector3.RIGHT, euler.x)
    node.rotate(Vector3.FORWARD, euler.z)
```

YXZ order. Different orders produce different results because rotations don't commute in 3D.

Use a quaternion to avoid gimbal lock.

```gdscript
func quaternion_rotation(axis: Vector3, angle_rad: float) -> Quaternion:
    return Quaternion(axis.normalized(), angle_rad)

func apply_quaternion(node: Node3D, q: Quaternion) -> void:
    node.quaternion = q * node.quaternion
```

Quaternions combine without gimbal lock. Two quaternions multiply cleanly; composing a chain is just multiplication.

Slerp between two rotations.

```gdscript
func slerp_rotation(from_q: Quaternion, to_q: Quaternion, t: float) -> Quaternion:
    return from_q.slerp(to_q, t)
```

Spherical linear interpolation. Unlike lerp, slerp maintains constant angular velocity.

Animate a rotation over time.

```gdscript
func animate_rotation(node: Node3D, target_quaternion: Quaternion, duration: float) -> void:
    var start_q: Quaternion = node.quaternion
    var tween := create_tween()
    tween.tween_method(
        func(t): node.quaternion = start_q.slerp(target_quaternion, t),
        0.0, 1.0, duration
    )
```

The tween interpolates the slerp parameter. The node rotates smoothly between start and target orientations.

You can now rotate around arbitrary axes and pivots, chain Euler rotations, combine quaternions without gimbal lock, and animate rotations with slerp. Trans_RotationSpectacle extends rotation into a stage performance.

<<<MAP: Trans_RotationSpectacle>>>
# Rotation Spectacle

A carousel of rotating objects. Layers turn at different rates.

Build the carousel frame.

```gdscript
func build_frame() -> Node3D:
    var frame := Node3D.new()
    add_child(frame)
    return frame
```

A parent Node3D to hold the spinning children. Rotating the frame rotates everything under it.

Attach objects to the frame at different radii.

```gdscript
func attach_ring(frame: Node3D, count: int, radius: float) -> void:
    for i in count:
        var angle: float = i * TAU / count
        var obj := MeshInstance3D.new()
        obj.mesh = BoxMesh.new()
        obj.position = Vector3(cos(angle), 0, sin(angle)) * radius
        frame.add_child(obj)
```

The children sit at even angles around a circle. Rotating the frame sweeps the whole ring.

Animate the frame.

```gdscript
@export var rotation_speed: float = 0.5  # radians per second

func _process(delta: float) -> void:
    frame.rotate_y(rotation_speed * delta)
```

Constant angular velocity. The frame turns smoothly at the configured rate.

Layer multiple rings.

```gdscript
func build_multi_ring() -> void:
    for layer in range(4):
        var sub_frame := Node3D.new()
        sub_frame.position.y = layer * 0.5
        add_child(sub_frame)
        attach_ring(sub_frame, 8, 1.0 + layer * 0.3)
        sub_frame.set_meta("speed", 0.3 + layer * 0.2)
```

Each layer has its own frame and its own speed. The combined motion is a stack of rotating rings.

Animate each layer at its own speed.

```gdscript
func _process(delta: float) -> void:
    for child in get_children():
        if child.has_meta("speed"):
            child.rotate_y(child.get_meta("speed") * delta)
```

Per-child speed lookup. The layers diverge and realign over time.

Add counter-rotation.

```gdscript
func add_counter_layer(radius: float, speed: float) -> void:
    var frame := Node3D.new()
    attach_ring(frame, 8, radius)
    frame.set_meta("speed", -speed)
    add_child(frame)
```

Negative speed reverses the direction. Alternating layers counter-rotate for visual rhythm.

Synchronise rotation to music.

```gdscript
func sync_to_beat(bpm: float) -> void:
    var beats_per_second: float = bpm / 60.0
    for child in get_children():
        if child.has_meta("speed"):
            var base_speed: float = child.get_meta("speed")
            child.rotate_y(base_speed * beats_per_second * (1.0 / Engine.get_frames_per_second()))
```

Speed scales with tempo. The carousel pulses with the audio.

You can now build a multi-layered rotating carousel with per-layer speeds, counter-rotation, and beat synchronisation. Trans_Scale extends scaling into its own detailed map.

<<<MAP: Trans_Scale>>>
# Trans Scale

Scaling. Size. Volume scales cubically.

Uniform scale.

```gdscript
func scale_uniform(node: Node3D, factor: float) -> void:
    node.scale = Vector3.ONE * factor
```

All three axes by the same factor. Shape preserved, size changed.

Non-uniform scale.

```gdscript
func scale_non_uniform(node: Node3D, factors: Vector3) -> void:
    node.scale = factors
```

Each axis independent. A Vector3(2, 1, 0.5) stretches horizontally, preserves vertical, shortens depth.

Compute the volume ratio.

```gdscript
func volume_ratio(before: Vector3, after: Vector3) -> float:
    return (after.x * after.y * after.z) / (before.x * before.y * before.z)
```

The product of scale factors gives the volume scale. Double the linear dimensions, multiply volume by 8.

Scale with VR gestures.

```gdscript
var initial_hand_distance: float = 0.0
var initial_scale: Vector3

func start_scaling(target: Node3D, left: XRController3D, right: XRController3D) -> void:
    initial_hand_distance = left.global_position.distance_to(right.global_position)
    initial_scale = target.scale

func update_scaling(target: Node3D, left: XRController3D, right: XRController3D) -> void:
    var current: float = left.global_position.distance_to(right.global_position)
    var factor: float = current / initial_hand_distance
    target.scale = initial_scale * factor
```

Two-handed scale gesture. Spread hands apart to grow, bring them together to shrink.

Clamp the scale.

```gdscript
const MIN_SCALE: float = 0.1
const MAX_SCALE: float = 5.0

func clamp_scale(node: Node3D) -> void:
    var s: Vector3 = node.scale
    node.scale = Vector3(clamp(s.x, MIN_SCALE, MAX_SCALE), clamp(s.y, MIN_SCALE, MAX_SCALE), clamp(s.z, MIN_SCALE, MAX_SCALE))
```

Prevent scale from going to extremes that break interaction or rendering.

Scale physics body with collision shape.

```gdscript
func scale_with_collision(body: RigidBody3D, factor: float) -> void:
    body.scale = Vector3.ONE * factor
    for child in body.get_children():
        if child is CollisionShape3D:
            child.scale = Vector3.ONE * factor
    body.mass = body.mass * pow(factor, 3)
```

Collision scales with the body automatically. Mass needs manual adjustment to reflect the cubic volume change.

Animate a scale transition.

```gdscript
func tween_scale(node: Node3D, target_scale: Vector3, duration: float) -> void:
    var tween := create_tween()
    tween.tween_property(node, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
```

Quadratic ease-out feels natural for growth. Linear scaling feels mechanical.

You can now scale uniformly or non-uniformly, with VR gestures or tweens, while keeping collision shapes and mass consistent. Trans_Pit extends scaling into a lethal hazard room.

<<<MAP: Trans_Pit>>>
# Trans Pit

Three rooms, three transformations, three hazards. The pit does not care which move sent you into it.

Build a pusher block.

```gdscript
class_name PusherBlock extends StaticBody3D

@export var axis: Vector3 = Vector3.RIGHT
@export var distance: float = 4.0
@export var speed: float = 2.0

var start_position: Vector3
var phase: float = 0.0

func _ready() -> void:
    start_position = global_position

func _physics_process(delta: float) -> void:
    phase = fmod(phase + delta * speed / distance, 2.0)
    var t: float = phase if phase < 1.0 else 2.0 - phase  # triangle wave
    global_position = start_position + axis * distance * t
```

The phase cycles between 0 and 2; the t value produces a triangle wave for smooth back-and-forth motion.

Build a revolving wall.

```gdscript
class_name RevolvingWall extends StaticBody3D

@export var angular_velocity: float = 1.0

func _physics_process(delta: float) -> void:
    rotate_y(angular_velocity * delta)
```

Constant rotation around the Y axis. The wall sweeps in a circle around its pivot.

Build a grower block.

```gdscript
class_name GrowerBlock extends StaticBody3D

@export var scale_rate: float = 0.2
@export var max_scale: float = 3.0

var current: float = 1.0

func _physics_process(delta: float) -> void:
    current = min(max_scale, current + scale_rate * delta)
    scale = Vector3.ONE * current
```

Grows until max_scale. The learner's safe footprint shrinks as the block expands.

Place fire pits around the hazards.

```gdscript
func place_fire_pits(rectangle: Rect2) -> void:
    for i in rectangle.size.x:
        for j in rectangle.size.y:
            var pit := FIRE_PIT_SCENE.instantiate()
            pit.position = Vector3(rectangle.position.x + i, 0, rectangle.position.y + j)
            add_child(pit)
```

The pits are the constant across the three rooms. Their positions vary with the room's layout.

Handle fire pit contact.

```gdscript
func _on_fire_pit_body_entered(body: Node) -> void:
    if body.is_in_group("learner"):
        DeathEffect.trigger(body, "fire")
```

The DeathEffect autoload handles the death sequence: flash, freeze, haptic, reload.

Trigger map reload.

```gdscript
func reload_map() -> void:
    get_tree().reload_current_scene()
```

The scene reloads from scratch. All hazards reset to their starting positions.

You can now build pusher blocks, revolving walls, grower blocks, and fire pits, and trigger the death-and-reload sequence on contact. Chamber_Transformation converts transformation into a creature encounter.

<<<MAP: Chamber_Transformation>>>
# Chamber Transformation

The miura_crawler folds rather than dies. The catalyst induces a state change.

Build the transformation catalyst.

```gdscript
class_name TransformationCatalyst extends Node3D

func fire(direction: Vector3) -> void:
    var projectile := FOLD_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = direction * 8.0
    projectile.operator = "fold"
    get_tree().root.add_child(projectile)
```

Projectiles carry a folding operator. On impact, the operator runs against whatever they hit.

Build the miura crawler.

```gdscript
class_name MiuraCrawler extends CharacterBody3D

@export var fold_decay_rate: float = 0.1
@export var hit_fold_increment: float = 0.3

var fold_amount: float = 0.0  # 0 = unfolded, 1 = fully folded

func _process(delta: float) -> void:
    fold_amount = max(0.0, fold_amount - fold_decay_rate * delta)
    update_mesh(fold_amount)
```

The fold decays toward zero over time. Each hit resets it partway up.

Respond to a fold hit.

```gdscript
func on_fold_operator() -> void:
    fold_amount = min(1.0, fold_amount + hit_fold_increment)
```

Each hit bumps the fold amount by 0.3. Three well-timed hits fold the creature completely.

Deform the mesh based on fold amount.

```gdscript
func update_mesh(amount: float) -> void:
    var compression: float = 1.0 - amount * 0.8
    scale = Vector3(1, compression, 1)
```

Vertical compression scales with the fold amount. Zero fold is full height; full fold is 20% height.

Detect befriending.

```gdscript
var sustained_fold_time: float = 0.0

func _process(delta: float) -> void:
    super(delta)
    if fold_amount > 0.8:
        sustained_fold_time += delta
    else:
        sustained_fold_time = 0.0
    if sustained_fold_time > 3.0:
        befriend()
```

Three seconds of sustained folding triggers befriending. Short hits don't count; you have to keep the fold.

Record befriending.

```gdscript
func befriend() -> void:
    var save = get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature("miura_crawler")
```

The creature joins the learner's roster of companions. It appears in later chambers as a witness.

Log events to the science screen.

```gdscript
func log_fold_event(amount: float) -> void:
    var screen = get_tree().get_first_node_in_group("science_screen")
    screen.log_scatter(Vector2(Time.get_ticks_msec() / 1000.0, amount))
```

Each hit becomes a scatter-plot point. The screen accumulates the history as a small dataset.

You can now build the transformation catalyst, project folding operators, deform the miura_crawler's mesh according to fold amount, and trigger befriending through sustained folding. The sequence hands you back to the Lab with the transformation catalyst in your kit and the miura_crawler as a companion.

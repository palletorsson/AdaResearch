@tool
extends "res://commons/primitives/point/interactive_point_origin.gd"
class_name InteractivePointOriginForce

# @identity
# essence: pickable_point + held → vertex-shader morph into force field that drags nearby RigidBodies inward; held + two_hands_close → fires luminous projectile balls
# desire: the body learns the relation point↔force↔gesture — same single artifact passing through three states as the player engages
# critical_parameter: morph_t (0 = point, 1 = force-field shell); attraction_radius + attraction_strength (inverse-square pull); OrbGestureDetector two-handed trigger (balls only fire from a sustained two-hand pose)
# triggers: picked_up → _morph_target=1; dropped → _morph_target=0; orb_formed(two_handed=true) → spawn ball; _physics_process while held + morph_t>0.5 → attract nearby RigidBody3D
# emerges: capability-as-gesture — the artifact's force-field powers exist only WHILE you hold it AND keep both hands engaged. Drop it or part your hands and the field collapses back to a point.
# needs: parent class interactive_point_origin (XRToolsPickable + line-to-origin + position label); OrbGestureDetector node in tree (group "orb_gesture_detector") for two-hand gesture signals; force_catalyst.gdshader for the morph
# relationships: extends interactive_point_origin; listens to OrbGestureDetector; spawns its own RigidBody3D ball projectiles
# truth: a point is the seed of a force, a force is the seed of a gesture — same artifact, three nested capabilities, each emerging only when its embodied condition is met.

## Force-catalyst variant of interactive_point_origin.
##
## On pickup the spherical visual morphs (vertex displacement, color
## shift, brighter emission) into a "force-field" shell. While held
## with morph engaged, nearby RigidBody3D objects feel an inverse-
## square pull toward the artifact's position. When the player brings
## both hands close (the OrbGestureDetector two-hand gesture), the
## artifact spits a luminous projectile ball in the gesture's forward
## direction. Drop it → morph reverses, attraction stops, projectiles
## stop firing.

const FORCE_SHADER: Shader = preload("res://commons/primitives/point/force_catalyst.gdshader")

# ── Morph state ──────────────────────────────────────────────────────────
@export var morph_speed: float = 1.4              # seconds 0 → 1
@export var morph_engage_threshold: float = 0.5   # attraction + projectile fire above this
var _morph_t: float = 0.0
var _morph_target: float = 0.0
var _force_shader_mat: ShaderMaterial = null

# ── Force-field attraction ──────────────────────────────────────────────
@export var attraction_radius: float = 1.5
@export var attraction_strength: float = 8.0      # force = k / max(d^2, 0.04)
@export var attraction_max_force: float = 40.0
@export var attractor_collision_mask: int = 0xFFFFFFFF

# ── Two-hand projectile fire ────────────────────────────────────────────
@export var ball_speed: float = 6.0
@export var ball_radius: float = 0.04
@export var ball_lifetime: float = 2.0
@export var ball_color: Color = Color(1.0, 0.62, 0.18)
@export var ball_emission_energy: float = 2.5
## Minimum time between projectile spawns (prevents the orb_formed
## signal from creating a stream of overlapping balls).
@export var ball_cooldown: float = 0.20
var _ball_cooldown_t: float = 0.0

# ── XR rig + gesture-detector refs ──────────────────────────────────────
var _orb_detector: Node = null
var _orb_signal_connected: bool = false


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	_install_force_shader()
	_connect_orb_detector()


# Replace the base class's _glow_material with our shader material so the
# vertex morph runs on the SAME MeshInstance3D the base class set up.
func _install_force_shader() -> void:
	var mi: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mi == null:
		return
	_force_shader_mat = ShaderMaterial.new()
	_force_shader_mat.shader = FORCE_SHADER
	_force_shader_mat.set_shader_parameter("morph_t", 0.0)
	# Push the base look (white) and the force-field look (warm orange)
	# into the shader. Tweakable per-instance via export if needed.
	_force_shader_mat.set_shader_parameter("base_color", Color(0.95, 0.95, 0.92, 1.0))
	_force_shader_mat.set_shader_parameter("force_color", Color(1.0, 0.55, 0.10, 1.0))
	mi.material_override = _force_shader_mat


# Try to grab the OrbGestureDetector at startup. If it isn't in the
# scene yet (the rig finishes building a frame or two later in some
# maps), keep polling lazily inside _process.
func _connect_orb_detector() -> void:
	_orb_detector = get_tree().get_first_node_in_group("orb_gesture_detector")
	if _orb_detector and _orb_detector.has_signal("orb_formed") and not _orb_signal_connected:
		_orb_detector.orb_formed.connect(_on_orb_formed)
		_orb_signal_connected = true


# Pickup / drop are inherited from interactive_point_origin.gd, which
# sets _is_held. We use _process to drive the morph independently so
# the morph keeps animating even when the base class isn't drawing
# its line-to-origin (e.g. tool mode).
func _process(delta: float) -> void:
	super._process(delta)
	if Engine.is_editor_hint():
		return

	# Lazy-bind detector if it wasn't ready at _ready.
	if not _orb_signal_connected:
		_connect_orb_detector()

	# Target morph follows _is_held — the base class flips this on
	# picked_up / dropped.
	_morph_target = 1.0 if _is_held else 0.0
	if _morph_t != _morph_target:
		_morph_t = move_toward(_morph_t, _morph_target, morph_speed * delta)
		if _force_shader_mat:
			_force_shader_mat.set_shader_parameter("morph_t", _morph_t)

	# Tick the per-fire cooldown so two-hand bursts can be spaced.
	if _ball_cooldown_t > 0.0:
		_ball_cooldown_t = max(0.0, _ball_cooldown_t - delta)


# Apply the force-field pull every physics tick.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _is_held or _morph_t < morph_engage_threshold:
		return
	_attract_nearby_bodies()


func _attract_nearby_bodies() -> void:
	var world := get_world_3d()
	if world == null:
		return
	var space := world.direct_space_state
	if space == null:
		return
	var pos: Vector3 = global_position
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = attraction_radius
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, pos)
	query.collision_mask = attractor_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	# Exclude ourselves so we don't yank our own RigidBody.
	query.exclude = [self.get_rid()] if self.has_method("get_rid") else []
	var hits: Array = space.intersect_shape(query, 24)
	for h in hits:
		var collider = h.get("collider")
		if collider is RigidBody3D and collider != self:
			var to_us: Vector3 = pos - collider.global_position
			var dist: float = to_us.length()
			if dist < 0.01:
				continue
			# Inverse-square pull, clamped so very close objects don't
			# explode out of bounds.
			var mag: float = clamp(
				attraction_strength / max(dist * dist, 0.04),
				0.0, attraction_max_force)
			collider.apply_central_force(to_us.normalized() * mag)


# OrbGestureDetector fires this when the player closes both palms with
# the catalyst engaged. While THIS artifact is held with morph engaged,
# we treat it as our "fire" trigger and spawn a projectile.
func _on_orb_formed(_mode: String, origin: Vector3, direction: Vector3, two_handed: bool) -> void:
	if Engine.is_editor_hint():
		return
	if not _is_held or _morph_t < morph_engage_threshold:
		return
	if not two_handed:
		return
	if _ball_cooldown_t > 0.0:
		return
	_ball_cooldown_t = ball_cooldown
	_spawn_projectile_ball(origin, direction)


func _spawn_projectile_ball(origin: Vector3, direction: Vector3) -> void:
	var ball := RigidBody3D.new()
	ball.name = "ForceBall"
	ball.gravity_scale = 0.3
	ball.continuous_cd = true
	ball.contact_monitor = false
	ball.linear_damp = 0.05

	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = ball_radius
	sm.height = ball_radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm

	var mat := StandardMaterial3D.new()
	mat.albedo_color = ball_color
	mat.emission_enabled = true
	mat.emission = ball_color
	mat.emission_energy_multiplier = ball_emission_energy
	mat.metallic = 0.1
	mat.roughness = 0.25
	mi.material_override = mat
	ball.add_child(mi)

	var cs := CollisionShape3D.new()
	var ss := SphereShape3D.new()
	ss.radius = ball_radius
	cs.shape = ss
	ball.add_child(cs)

	# Spawn slightly forward of the artifact along the gesture direction
	# so the ball doesn't clip into the held mesh on first frame.
	var dir: Vector3 = direction.normalized() if direction.length_squared() > 0.0 else Vector3.FORWARD
	var spawn_pos: Vector3 = global_position + dir * (ball_radius * 2.5)
	# Fall back to the gesture origin if it's a reasonable place — gives
	# the player the sense the ball comes from between the hands.
	if origin.distance_to(global_position) < 0.6:
		spawn_pos = origin + dir * (ball_radius * 2.5)

	get_tree().current_scene.add_child(ball)
	ball.global_position = spawn_pos
	ball.linear_velocity = dir * ball_speed

	# Auto-cleanup so the world doesn't fill up with stale balls.
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = ball_lifetime
	t.timeout.connect(func(): if is_instance_valid(ball): ball.queue_free())
	ball.add_child(t)
	t.start()


# Allow per-instance tweaks from the lab editor / map_data tokens.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("attraction_radius"):
		attraction_radius = float(config_data["attraction_radius"])
	if config_data.has("attraction_strength"):
		attraction_strength = float(config_data["attraction_strength"])
	if config_data.has("ball_speed"):
		ball_speed = float(config_data["ball_speed"])
	if config_data.has("ball_lifetime"):
		ball_lifetime = float(config_data["ball_lifetime"])
	if config_data.has("morph_speed"):
		morph_speed = float(config_data["morph_speed"])

class_name JumpPad
extends Node3D

## Launches the player in a parabolic arc using real projectile physics.
## The pad computes v₀ from the kinematic equations: given start, target, and
## desired peak height, it solves for the initial velocity that produces
## the correct parabola under gravity. Then it applies that velocity as an
## impulse and lets F = ma do the rest.
##
## Placed via the utilities layer as "jp:target_x:target_z[:arc_height]".
## Introduced in the forces sequence as a knowledge reward after learning
## projectile motion — the player becomes the parabola they just studied.
##
## A landing zone Area3D at the target guarantees safe arrival.

signal jump_started(target_pos: Vector3)
signal jump_landed(target_pos: Vector3)

## Target grid coordinates (set by GridUtilitiesComponent)
@export var target_grid_x: int = 0
@export var target_grid_z: int = 0

## Peak height above the highest endpoint (meters)
@export var arc_height: float = 6.0

## Cooldown after landing before pad can be used again
@export var cooldown_time: float = 1.5

## Landing zone radius — catches player within this distance of target
@export var landing_snap_radius: float = 1.8

## Maximum flight time before forced landing (safety timeout)
@export var max_flight_time: float = 6.0

## World-space target position (computed from grid coords)
var target_world_pos: Vector3 = Vector3.ZERO

## Grid spacing info (set by GridUtilitiesComponent)
var _cube_size: float = 1.0
var _gutter: float = 0.0

# Flight state
var _player_node: Node3D = null
var _is_launching: bool = false
var _cooldown_timer: float = 0.0
var _flight_time: float = 0.0
var _expected_land_time: float = 0.0
var _launch_velocity: Vector3 = Vector3.ZERO
var _launch_start_pos: Vector3 = Vector3.ZERO
var _was_floor_snap: float = 0.0
var _gravity: float = 9.8

# Visuals
var _pad_mesh: MeshInstance3D
var _arrow_mesh: MeshInstance3D
var _glow_light: OmniLight3D
var _label: Label3D
var _particles: GPUParticles3D
var _pulse_time: float = 0.0
var _landing_zone: Area3D

# Colors
const PAD_COLOR := Color(0.1, 0.9, 0.6)  # green-cyan
const PAD_EMISSION := Color(0.1, 0.9, 0.6)
const ARROW_COLOR := Color(0.2, 1.0, 0.7)
const INACTIVE_COLOR := Color(0.3, 0.3, 0.3)
const LANDING_COLOR := Color(0.2, 0.8, 1.0, 0.3)  # soft blue for landing zone


func _ready() -> void:
	_gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	_build_visual()
	_setup_launch_area()


func _process(delta: float) -> void:
	# Cooldown
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_set_active_visual(true)

	# Gentle pulse animation on the pad
	if not _is_launching and _cooldown_timer <= 0.0:
		_pulse_time += delta
		var pulse: float = 0.8 + 0.2 * sin(_pulse_time * 3.0)
		if _glow_light:
			_glow_light.light_energy = 1.5 * pulse
		if _pad_mesh and _pad_mesh.material_override:
			_pad_mesh.material_override.emission_energy_multiplier = 2.0 * pulse


func _physics_process(delta: float) -> void:
	if not _is_launching or not is_instance_valid(_player_node):
		return

	_flight_time += delta

	if _player_node is CharacterBody3D:
		# Lock horizontal velocity to launch values — player input can't steer mid-flight
		# Gravity is applied by the player's own movement script (real F = ma)
		_player_node.velocity.x = _launch_velocity.x
		_player_node.velocity.z = _launch_velocity.z

	# Check landing conditions
	var pos: Vector3 = _player_node.global_position
	var horizontal_dist: float = Vector2(pos.x - target_world_pos.x, pos.z - target_world_pos.z).length()
	var is_descending: bool = true
	if _player_node is CharacterBody3D:
		is_descending = _player_node.velocity.y <= 0.0

	# Land if: close to target horizontally AND descending AND below or near target Y
	var near_target: bool = horizontal_dist < landing_snap_radius and is_descending
	var at_height: bool = pos.y <= target_world_pos.y + 0.5
	var on_floor: bool = _player_node is CharacterBody3D and _player_node.is_on_floor()
	var timed_out: bool = _flight_time > max_flight_time

	if (near_target and (at_height or on_floor)) or timed_out:
		_on_landing()


func _build_visual() -> void:
	# --- Pad disc ---
	_pad_mesh = MeshInstance3D.new()
	_pad_mesh.name = "PadDisc"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 0.08
	cyl.radial_segments = 24
	_pad_mesh.mesh = cyl
	_pad_mesh.position = Vector3(0, 0.04, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = PAD_COLOR
	mat.emission_enabled = true
	mat.emission = PAD_EMISSION
	mat.emission_energy_multiplier = 2.0
	mat.metallic = 0.3
	mat.roughness = 0.4
	_pad_mesh.material_override = mat
	_pad_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pad_mesh)

	# --- Upward arrow on pad surface ---
	_arrow_mesh = MeshInstance3D.new()
	_arrow_mesh.name = "Arrow"
	var arrow_im := ImmediateMesh.new()
	_arrow_mesh.mesh = arrow_im

	# Draw a simple upward chevron (^)
	arrow_im.surface_begin(Mesh.PRIMITIVE_LINES)
	arrow_im.surface_add_vertex(Vector3(-0.15, 0.0, 0.08))
	arrow_im.surface_add_vertex(Vector3(0.0, 0.0, -0.12))
	arrow_im.surface_add_vertex(Vector3(0.15, 0.0, 0.08))
	arrow_im.surface_add_vertex(Vector3(0.0, 0.0, -0.12))
	arrow_im.surface_add_vertex(Vector3(-0.12, 0.0, 0.18))
	arrow_im.surface_add_vertex(Vector3(0.0, 0.0, 0.0))
	arrow_im.surface_add_vertex(Vector3(0.12, 0.0, 0.18))
	arrow_im.surface_add_vertex(Vector3(0.0, 0.0, 0.0))
	arrow_im.surface_end()

	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow_mat.albedo_color = ARROW_COLOR
	arrow_mat.emission_enabled = true
	arrow_mat.emission = ARROW_COLOR
	arrow_mat.emission_energy_multiplier = 3.0
	_arrow_mesh.material_override = arrow_mat
	_arrow_mesh.position = Vector3(0, 0.09, 0)
	_arrow_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_arrow_mesh)

	# --- Glow light ---
	_glow_light = OmniLight3D.new()
	_glow_light.name = "PadGlow"
	_glow_light.light_color = PAD_COLOR
	_glow_light.light_energy = 1.5
	_glow_light.omni_range = 3.0
	_glow_light.omni_attenuation = 2.0
	_glow_light.position = Vector3(0, 0.5, 0)
	_glow_light.shadow_enabled = false
	add_child(_glow_light)

	# --- Label ---
	_label = Label3D.new()
	_label.name = "PadLabel"
	_label.text = "JUMP"
	_label.font_size = 24
	_label.outline_size = 4
	_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	_label.modulate = Color(PAD_COLOR, 0.9)
	_label.pixel_size = 0.002
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 0.8, 0)
	_label.render_priority = 1
	add_child(_label)

	# --- Vertical particles ---
	_particles = GPUParticles3D.new()
	_particles.name = "LaunchParticles"
	_particles.amount = 12
	_particles.lifetime = 1.2
	_particles.emitting = true

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 10.0
	pmat.initial_velocity_min = 0.5
	pmat.initial_velocity_max = 1.5
	pmat.gravity = Vector3(0, -0.5, 0)
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.emission_ring_radius = 0.4
	pmat.emission_ring_inner_radius = 0.3
	pmat.emission_ring_height = 0.02
	pmat.scale_min = 0.02
	pmat.scale_max = 0.05
	pmat.color = PAD_COLOR
	_particles.process_material = pmat

	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	_particles.draw_pass_1 = quad
	_particles.position = Vector3(0, 0.1, 0)
	add_child(_particles)


func _setup_launch_area() -> void:
	var area := Area3D.new()
	area.name = "LaunchArea"
	area.collision_layer = 0
	area.collision_mask = 524288  # detects player_body (layer 20)

	var col_shape := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.45
	shape.height = 0.6
	col_shape.shape = shape
	col_shape.position = Vector3(0, 0.3, 0)

	area.add_child(col_shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _build_landing_zone() -> void:
	# Visual landing target at destination — a glowing ring the player can see
	if target_world_pos == Vector3.ZERO:
		return

	_landing_zone = Area3D.new()
	_landing_zone.name = "LandingZone"
	_landing_zone.collision_layer = 0
	_landing_zone.collision_mask = 524288  # detects player_body

	var lz_shape := CollisionShape3D.new()
	var lz_cyl := CylinderShape3D.new()
	lz_cyl.radius = landing_snap_radius
	lz_cyl.height = 3.0  # tall enough to catch player approaching from above
	lz_shape.shape = lz_cyl

	_landing_zone.add_child(lz_shape)

	# Visual ring at landing spot
	var ring_mesh := MeshInstance3D.new()
	ring_mesh.name = "LandingRing"
	var torus := TorusMesh.new()
	torus.inner_radius = landing_snap_radius - 0.15
	torus.outer_radius = landing_snap_radius
	torus.rings = 24
	torus.ring_segments = 8
	ring_mesh.mesh = torus

	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = LANDING_COLOR
	ring_mat.emission_enabled = true
	ring_mat.emission = PAD_COLOR * 0.5
	ring_mat.emission_energy_multiplier = 1.5
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mesh.material_override = ring_mat
	ring_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_landing_zone.add_child(ring_mesh)

	# Position landing zone at target in world space
	_landing_zone.global_position = target_world_pos + Vector3(0, 1.5, 0)

	# Add to parent (the grid, not the jump pad itself — so it's at world coords)
	if get_parent():
		get_parent().add_child.call_deferred(_landing_zone)
	else:
		add_child(_landing_zone)


func _on_body_entered(body: Node3D) -> void:
	if _is_launching or _cooldown_timer > 0.0:
		return
	if not body.is_in_group("player_body"):
		return

	_player_node = _find_player_root(body)
	if _player_node:
		_launch()


func _find_player_root(body: Node3D) -> Node3D:
	# Walk up to find XROrigin3D (VR) or CharacterBody3D (desktop)
	var node: Node = body
	while node:
		if node is CharacterBody3D:
			return node
		if node.get_class() == "XROrigin3D":
			return node
		node = node.get_parent()
	return body  # fallback


func _launch() -> void:
	_is_launching = true
	_flight_time = 0.0
	_set_active_visual(false)

	var start: Vector3 = _player_node.global_position
	var target: Vector3 = target_world_pos
	_launch_start_pos = start

	# === Projectile physics: solve for v₀ ===
	#
	# Given: start (x₀,y₀,z₀), target (x₁,y₁,z₁), desired peak height, gravity g
	#
	# Peak is at: y_peak = max(y₀, y₁) + arc_height
	# From kinematics: y_peak = y₀ + v₀y²/(2g)
	# Therefore: v₀y = √(2g · (y_peak - y₀))
	#
	# Landing time from: y₁ = y₀ + v₀y·t - ½g·t²
	# Rearranged: ½g·t² - v₀y·t + (y₁ - y₀) = 0
	# Quadratic: t = (v₀y + √(v₀y² - 2g·(y₁ - y₀))) / g
	#
	# Horizontal: v₀x = (x₁ - x₀)/t, v₀z = (z₁ - z₀)/t
	#
	var peak_y: float = maxf(start.y, target.y) + arc_height
	var v0_y: float = sqrt(maxf(2.0 * _gravity * (peak_y - start.y), 0.1))

	var discriminant: float = v0_y * v0_y - 2.0 * _gravity * (target.y - start.y)
	var t_land: float
	if discriminant >= 0.0:
		t_land = (v0_y + sqrt(discriminant)) / _gravity
	else:
		# Fallback: estimate from peak time × 2
		t_land = 2.0 * v0_y / _gravity

	# Clamp to sane range
	t_land = clampf(t_land, 0.5, max_flight_time)
	_expected_land_time = t_land

	var v0_x: float = (target.x - start.x) / t_land
	var v0_z: float = (target.z - start.z) / t_land

	_launch_velocity = Vector3(v0_x, v0_y, v0_z)

	# Disable floor snapping so CharacterBody3D actually leaves the ground
	if _player_node is CharacterBody3D:
		_was_floor_snap = _player_node.floor_snap_length
		_player_node.floor_snap_length = 0.0
		# Apply the impulse — this IS the force
		_player_node.velocity = _launch_velocity

	# Mark player as in-flight (other scripts can check this group)
	_player_node.add_to_group("jump_pad_flight")

	jump_started.emit(target_world_pos)

	print("JumpPad: LAUNCH v₀=(%.2f, %.2f, %.2f) t_land=%.2fs g=%.1f" % [
		_launch_velocity.x, _launch_velocity.y, _launch_velocity.z,
		_expected_land_time, _gravity
	])


func _on_landing() -> void:
	if not is_instance_valid(_player_node):
		_is_launching = false
		return

	# Snap to exact landing position
	_player_node.global_position = target_world_pos

	# Kill all velocity
	if _player_node is CharacterBody3D:
		_player_node.velocity = Vector3.ZERO
		# Restore floor snapping
		_player_node.floor_snap_length = _was_floor_snap if _was_floor_snap > 0.0 else 0.1

	# Remove flight group
	if _player_node.is_in_group("jump_pad_flight"):
		_player_node.remove_from_group("jump_pad_flight")

	_is_launching = false
	_cooldown_timer = cooldown_time
	jump_landed.emit(target_world_pos)

	print("JumpPad: LANDED at %s (flight time: %.2fs, expected: %.2fs)" % [
		target_world_pos, _flight_time, _expected_land_time
	])

	_player_node = null


func _set_active_visual(active: bool) -> void:
	var color: Color = PAD_COLOR if active else INACTIVE_COLOR
	if _pad_mesh and _pad_mesh.material_override:
		_pad_mesh.material_override.albedo_color = color
		_pad_mesh.material_override.emission = color if active else Color.BLACK
		_pad_mesh.material_override.emission_energy_multiplier = 2.0 if active else 0.0
	if _glow_light:
		_glow_light.light_energy = 1.5 if active else 0.0
	if _particles:
		_particles.emitting = active
	if _arrow_mesh and _arrow_mesh.material_override:
		_arrow_mesh.material_override.emission_energy_multiplier = 3.0 if active else 0.0
		_arrow_mesh.material_override.albedo_color = ARROW_COLOR if active else INACTIVE_COLOR


func apply_grid_config(data: Dictionary) -> void:
	if data.has("target_x"):
		target_grid_x = int(data["target_x"])
	if data.has("target_z"):
		target_grid_z = int(data["target_z"])
	if data.has("arc_height"):
		arc_height = float(data["arc_height"])
	if data.has("label"):
		if _label:
			_label.text = str(data["label"])
	_recompute_target()


func set_grid_spacing(p_cube_size: float, p_gutter: float) -> void:
	_cube_size = p_cube_size
	_gutter = p_gutter
	_recompute_target()


func _recompute_target() -> void:
	var total: float = _cube_size + _gutter
	target_world_pos = Vector3(
		target_grid_x * total + total * 0.5,
		0.0,  # Y will be set by GridUtilitiesComponent from structure height
		target_grid_z * total + total * 0.5
	)
	# Rebuild landing zone if target changed and we're in the tree
	if is_inside_tree():
		if is_instance_valid(_landing_zone):
			_landing_zone.queue_free()
		_build_landing_zone.call_deferred()

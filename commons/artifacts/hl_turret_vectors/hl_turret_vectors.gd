# hl_turret_vectors.gd
# Half-Life Inspired Sentry Turret - Vector Operations Compendium
#
# A single artifact demonstrating ALL core vector operations:
# - SUBTRACTION: target - turret = direction to target
# - MAGNITUDE: distance to target (range check)
# - NORMALIZATION: unit aim direction
# - DOT PRODUCT: field of view check (angle to target)
# - CROSS PRODUCT: rotation axis to turn toward target
# - PROJECTION: target projected onto turret's ground plane
# - ADDITION: turret position + aim direction = laser endpoint
# - SCALAR MULTIPLICATION: bullet velocity = direction * speed
# - VELOCITY INTEGRATION: new_pos = pos + velocity * delta
#
# VR-enabled: grab the bouncing ball target, use sliders for settings
# QFEP: The turret as "computational subject" - vectors as the math of surveillance

extends Node3D

class_name HLTurretVectors

## Turret settings
@export var turret_height: float = 0.4
@export var barrel_length: float = 0.25
@export var field_of_view_degrees: float = 90.0:
	set(value):
		field_of_view_degrees = clampf(value, 30.0, 180.0)
		_sync_fov_slider()
@export var max_range: float = 2.5
@export var tracking_speed: float = 2.0

## Shooting settings
@export var shooting_enabled: bool = true
@export var fire_rate: float = 3.0:
	set(value):
		fire_rate = clampf(value, 0.5, 10.0)
		_sync_fire_rate_slider()
@export var bullet_speed: float = 4.0:
	set(value):
		bullet_speed = clampf(value, 1.0, 10.0)
		_sync_bullet_speed_slider()
@export var bullet_lifetime: float = 2.0
@export var show_bullet_vectors: bool = true

## Ball settings
@export var ball_color: Color = Color(0.2, 0.8, 1.0):
	set(value):
		ball_color = value
		_update_ball_color()
@export var ball_bounce: float = 0.8
@export var ball_radius: float = 0.08

## Colors - Industrial/Military palette
@export var color_turret: Color = Color(0.4, 0.42, 0.45)
@export var color_barrel: Color = Color(0.25, 0.25, 0.28)
@export var color_laser: Color = Color(1.0, 0.1, 0.1)
@export var color_fov_in: Color = Color(0.2, 1.0, 0.3, 0.15)
@export var color_fov_out: Color = Color(1.0, 0.3, 0.2, 0.15)
@export var color_direction: Color = Color(1.0, 0.9, 0.3)
@export var color_projection: Color = Color(0.3, 0.8, 1.0, 0.6)
@export var color_cross: Color = Color(0.8, 0.4, 1.0)
@export var panel_color: Color = Color(0.04, 0.04, 0.06, 0.92)

# Turret components
var _turret_base: Node3D
var _turret_body: Node3D
var _turret_barrel: Node3D
var _laser_beam: MeshInstance3D
var _laser_dot: MeshInstance3D
var _eye_light: OmniLight3D

# Ball target (RigidBody3D for physics)
var _ball: RigidBody3D
var _ball_mesh: MeshInstance3D
var _ball_material: StandardMaterial3D
var _ball_ground_projection: MeshInstance3D
var _drop_line: MeshInstance3D

# Vector visualization arrows
var _arrow_direction: Node3D
var _arrow_unit_direction: Node3D
var _arrow_cross: Node3D
var _arrow_projection: Node3D
var _arrow_velocity: Node3D  # Ball velocity

# FOV cone
var _fov_cone: MeshInstance3D

# Shooting state
var _time_since_last_shot: float = 0.0
var _bullets: Array[Dictionary] = []
var _muzzle_flash: MeshInstance3D
var _muzzle_light: OmniLight3D
var _muzzle_flash_timer: float = 0.0
var _bullets_container: Node3D
var _hit_count: int = 0
var _shots_fired: int = 0

# Info panels
var _title_panel: Node3D
var _status_panel: Node3D
var _math_panel: Node3D
var _operations_panel: Node3D

# VR Controls
var _control_panel: Node3D
var _fov_slider: Node
var _fire_rate_slider: Node
var _bullet_speed_slider: Node
var _spawn_ball_button: Node
var _toggle_shooting_button: Node

# Labels
var _label_direction: Label3D
var _label_distance: Label3D
var _label_dot: Label3D
var _label_cross: Label3D
var _label_proj: Label3D
var _label_velocity: Label3D
var _label_ball_velocity: Label3D

# State
var _current_aim_direction: Vector3 = Vector3.FORWARD
var _target_in_fov: bool = false
var _target_in_range: bool = false
var _turret_yaw: float = 0.0
var _turret_pitch: float = 0.0

# Preloads
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

const ARROW_THICKNESS = 0.018
const BULLET_RADIUS = 0.02
const HIT_DISTANCE = 0.12

# Ball colors for cycling
const BALL_COLORS = [
	Color(0.2, 0.8, 1.0),   # Cyan
	Color(1.0, 0.4, 0.2),   # Orange
	Color(0.4, 1.0, 0.4),   # Green
	Color(1.0, 0.3, 0.8),   # Pink
	Color(0.9, 0.9, 0.2),   # Yellow
	Color(0.6, 0.4, 1.0),   # Purple
]
var _ball_color_index: int = 0

func _ready():
	_create_environment()
	_create_turret()
	_create_ball_target()
	_create_vector_arrows()
	_create_fov_visualization()
	_create_labels()
	_create_info_panels()
	_create_vr_controls()
	_create_shooting_system()
	_update_visualization()

#region Environment
func _create_environment():
	# Ground plane with physics
	var ground_body = StaticBody3D.new()
	ground_body.name = "GroundBody"
	add_child(ground_body)
	
	var ground_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(max_range * 3, 0.1, max_range * 3)
	ground_shape.shape = box_shape
	ground_shape.position = Vector3(0, -0.05, 0)
	ground_body.add_child(ground_shape)
	
	# Visual ground
	var ground = MeshInstance3D.new()
	ground.name = "Ground"
	var plane = PlaneMesh.new()
	plane.size = Vector2(max_range * 2.5, max_range * 2.5)
	ground.mesh = plane
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.14, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ground.material_override = mat
	ground.position = Vector3(0, -0.01, 0)
	ground_body.add_child(ground)
	
	# Walls to keep ball in bounds
	_create_arena_walls()
	
	# Grid lines
	_create_grid()
	
	# Range circle
	_create_range_indicator()

func _create_arena_walls():
	var wall_height = 1.5
	var wall_dist = max_range * 1.2
	var walls = [
		[Vector3(wall_dist, wall_height/2, 0), Vector3(0.1, wall_height, wall_dist * 2)],
		[Vector3(-wall_dist, wall_height/2, 0), Vector3(0.1, wall_height, wall_dist * 2)],
		[Vector3(0, wall_height/2, wall_dist), Vector3(wall_dist * 2, wall_height, 0.1)],
		[Vector3(0, wall_height/2, -wall_dist), Vector3(wall_dist * 2, wall_height, 0.1)],
	]
	
	for wall_data in walls:
		var wall_body = StaticBody3D.new()
		wall_body.position = wall_data[0]
		add_child(wall_body)
		
		var wall_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = wall_data[1]
		wall_shape.shape = shape
		wall_body.add_child(wall_shape)
		
		# Invisible walls (or semi-transparent)
		var wall_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = wall_data[1]
		wall_mesh.mesh = box
		var wall_mat = StandardMaterial3D.new()
		wall_mat.albedo_color = Color(0.3, 0.3, 0.4, 0.1)
		wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wall_mesh.material_override = wall_mat
		wall_body.add_child(wall_mesh)

func _create_grid():
	var grid = Node3D.new()
	grid.name = "Grid"
	
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.25, 0.25, 0.3, 0.4)
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var grid_size = max_range * 2.0
	var spacing = 0.5
	
	for i in range(-int(grid_size/spacing), int(grid_size/spacing) + 1):
		var x = i * spacing
		var line_x = _create_line_mesh(Vector3(x, 0, -grid_size), Vector3(x, 0, grid_size), line_mat)
		grid.add_child(line_x)
		var line_z = _create_line_mesh(Vector3(-grid_size, 0, x), Vector3(grid_size, 0, x), line_mat)
		grid.add_child(line_z)
	
	add_child(grid)

func _create_line_mesh(start: Vector3, end: Vector3, mat: Material) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	var direction = end - start
	var length = direction.length()
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.003
	cylinder.bottom_radius = 0.003
	cylinder.height = length
	line.mesh = cylinder
	line.material_override = mat
	
	line.position = (start + end) / 2.0
	
	if abs(direction.normalized().dot(Vector3.UP)) < 0.99:
		line.look_at(line.position + direction, Vector3.UP)
		line.rotate_object_local(Vector3.RIGHT, PI/2)
	
	return line

func _create_range_indicator():
	var range_circle = Node3D.new()
	range_circle.name = "RangeIndicator"
	
	var segments = 64
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.2, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	for i in range(segments):
		var angle1 = (float(i) / segments) * TAU
		var angle2 = (float(i + 1) / segments) * TAU
		var p1 = Vector3(cos(angle1), 0, sin(angle1)) * max_range
		var p2 = Vector3(cos(angle2), 0, sin(angle2)) * max_range
		var line = _create_line_mesh(p1, p2, mat)
		range_circle.add_child(line)
	
	var range_label = Label3D.new()
	range_label.text = "MAX RANGE: %.1fm" % max_range
	range_label.pixel_size = 0.002
	range_label.font_size = 14
	range_label.modulate = Color(1.0, 0.4, 0.2, 0.8)
	range_label.position = Vector3(max_range + 0.15, 0.02, 0)
	range_label.rotation_degrees = Vector3(-90, 0, 0)
	range_circle.add_child(range_label)
	
	add_child(range_circle)
#endregion

#region Turret
func _create_turret():
	_turret_base = Node3D.new()
	_turret_base.name = "TurretBase"
	add_child(_turret_base)
	
	# Base platform
	var base_platform = MeshInstance3D.new()
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.12
	base_mesh.bottom_radius = 0.15
	base_mesh.height = 0.05
	base_platform.mesh = base_mesh
	
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = color_turret
	base_mat.metallic = 0.6
	base_mat.roughness = 0.4
	base_platform.material_override = base_mat
	base_platform.position = Vector3(0, 0.025, 0)
	_turret_base.add_child(base_platform)
	
	# Tripod legs
	for i in range(3):
		var angle = i * (TAU / 3.0) + PI/6
		var leg = MeshInstance3D.new()
		var leg_mesh = BoxMesh.new()
		leg_mesh.size = Vector3(0.025, 0.06, 0.18)
		leg.mesh = leg_mesh
		leg.material_override = base_mat
		leg.position = Vector3(cos(angle) * 0.08, 0.01, sin(angle) * 0.08)
		leg.rotation.y = -angle
		_turret_base.add_child(leg)
	
	# Central column
	var column = MeshInstance3D.new()
	var col_mesh = CylinderMesh.new()
	col_mesh.top_radius = 0.04
	col_mesh.bottom_radius = 0.06
	col_mesh.height = turret_height * 0.6
	column.mesh = col_mesh
	column.material_override = base_mat
	column.position = Vector3(0, turret_height * 0.3 + 0.05, 0)
	_turret_base.add_child(column)
	
	# Rotating body (yaw)
	_turret_body = Node3D.new()
	_turret_body.name = "TurretBody"
	_turret_body.position = Vector3(0, turret_height, 0)
	_turret_base.add_child(_turret_body)
	
	# Head housing
	var head = MeshInstance3D.new()
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.12, 0.1, 0.15)
	head.mesh = head_mesh
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = color_turret * 0.9
	head_mat.metallic = 0.5
	head_mat.roughness = 0.5
	head.material_override = head_mat
	_turret_body.add_child(head)
	
	# Eye/sensor
	var eye_housing = MeshInstance3D.new()
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.025
	eye_mesh.height = 0.05
	eye_housing.mesh = eye_mesh
	
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.1, 0.1, 0.1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.1, 0.0)
	eye_mat.emission_energy_multiplier = 2.0
	eye_housing.material_override = eye_mat
	eye_housing.position = Vector3(0, 0.02, 0.08)
	_turret_body.add_child(eye_housing)
	
	# Eye light
	_eye_light = OmniLight3D.new()
	_eye_light.light_color = Color(1.0, 0.2, 0.1)
	_eye_light.light_energy = 0.5
	_eye_light.omni_range = 0.3
	_eye_light.position = Vector3(0, 0.02, 0.08)
	_turret_body.add_child(_eye_light)
	
	# Barrel (pitch)
	_turret_barrel = Node3D.new()
	_turret_barrel.name = "TurretBarrel"
	_turret_barrel.position = Vector3(0, 0, 0.08)
	_turret_body.add_child(_turret_barrel)
	
	var barrel = MeshInstance3D.new()
	var barrel_mesh = CylinderMesh.new()
	barrel_mesh.top_radius = 0.015
	barrel_mesh.bottom_radius = 0.02
	barrel_mesh.height = barrel_length
	barrel.mesh = barrel_mesh
	
	var barrel_mat = StandardMaterial3D.new()
	barrel_mat.albedo_color = color_barrel
	barrel_mat.metallic = 0.7
	barrel_mat.roughness = 0.3
	barrel.material_override = barrel_mat
	barrel.position = Vector3(0, 0, barrel_length / 2.0)
	barrel.rotation.x = PI/2
	_turret_barrel.add_child(barrel)
	
	# Laser beam
	_laser_beam = MeshInstance3D.new()
	_laser_beam.name = "LaserBeam"
	var laser_mesh = CylinderMesh.new()
	laser_mesh.top_radius = 0.003
	laser_mesh.bottom_radius = 0.003
	laser_mesh.height = 1.0
	_laser_beam.mesh = laser_mesh
	
	var laser_mat = StandardMaterial3D.new()
	laser_mat.albedo_color = color_laser
	laser_mat.emission_enabled = true
	laser_mat.emission = color_laser
	laser_mat.emission_energy_multiplier = 3.0
	laser_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_laser_beam.material_override = laser_mat
	_turret_barrel.add_child(_laser_beam)
	
	# Laser dot
	_laser_dot = MeshInstance3D.new()
	_laser_dot.name = "LaserDot"
	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.02
	dot_mesh.height = 0.04
	_laser_dot.mesh = dot_mesh
	
	var dot_mat = StandardMaterial3D.new()
	dot_mat.albedo_color = color_laser
	dot_mat.emission_enabled = true
	dot_mat.emission = color_laser
	dot_mat.emission_energy_multiplier = 4.0
	_laser_dot.material_override = dot_mat
	add_child(_laser_dot)
#endregion

#region Ball Target
func _create_ball_target():
	# Create RigidBody3D ball that can be grabbed in VR
	_ball = RigidBody3D.new()
	_ball.name = "BallTarget"
	_ball.mass = 0.5
	_ball.gravity_scale = 1.0
	_ball.linear_damp = 0.2
	_ball.angular_damp = 0.5
	
	# Physics material for bounce
	var physics_mat = PhysicsMaterial.new()
	physics_mat.bounce = ball_bounce
	physics_mat.friction = 0.3
	_ball.physics_material_override = physics_mat
	
	# Collision shape
	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = ball_radius
	collision.shape = sphere_shape
	_ball.add_child(collision)
	
	# Visual mesh
	_ball_mesh = MeshInstance3D.new()
	_ball_mesh.name = "BallMesh"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = ball_radius
	sphere_mesh.height = ball_radius * 2
	_ball_mesh.mesh = sphere_mesh
	
	_ball_material = StandardMaterial3D.new()
	_ball_material.albedo_color = ball_color
	_ball_material.emission_enabled = true
	_ball_material.emission = ball_color
	_ball_material.emission_energy_multiplier = 0.8
	_ball_mesh.material_override = _ball_material
	_ball.add_child(_ball_mesh)
	
	# Target rings on ball
	for i in range(2):
		var ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = ball_radius * 0.9 + i * 0.015
		torus.outer_radius = ball_radius * 0.95 + i * 0.015
		ring.mesh = torus
		ring.material_override = _ball_material
		ring.rotation.x = PI/2
		_ball.add_child(ring)
	
	# Ball label
	var ball_label = Label3D.new()
	ball_label.name = "BallLabel"
	ball_label.text = "TARGET"
	ball_label.pixel_size = 0.002
	ball_label.font_size = 12
	ball_label.modulate = ball_color
	ball_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ball_label.position = Vector3(0, ball_radius + 0.08, 0)
	_ball.add_child(ball_label)
	
	# Add XRToolsPickable script for VR grabbing
	if ResourceLoader.exists("res://addons/godot-xr-tools/objects/pickable.gd"):
		var pickable_script = load("res://addons/godot-xr-tools/objects/pickable.gd")
		_ball.set_script(pickable_script)
		_ball.set("enabled", true)
		_ball.set("press_to_hold", false)  # Toggle grab
	
	# Initial position
	_ball.position = Vector3(1.0, 0.5, 0.8)
	add_child(_ball)
	
	# Give it an initial push
	_ball.apply_impulse(Vector3(randf_range(-0.5, 0.5), 0.3, randf_range(-0.5, 0.5)))
	
	# Ground projection marker
	_ball_ground_projection = MeshInstance3D.new()
	_ball_ground_projection.name = "GroundProjection"
	var proj_mesh = CylinderMesh.new()
	proj_mesh.top_radius = 0.05
	proj_mesh.bottom_radius = 0.05
	proj_mesh.height = 0.005
	_ball_ground_projection.mesh = proj_mesh
	
	var proj_mat = StandardMaterial3D.new()
	proj_mat.albedo_color = color_projection
	proj_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ball_ground_projection.material_override = proj_mat
	add_child(_ball_ground_projection)
	
	# Drop line
	_drop_line = MeshInstance3D.new()
	_drop_line.name = "DropLine"
	add_child(_drop_line)

func _update_ball_color():
	if _ball_material:
		_ball_material.albedo_color = ball_color
		_ball_material.emission = ball_color
	
	# Update label too
	if _ball:
		var label = _ball.get_node_or_null("BallLabel")
		if label:
			label.modulate = ball_color

func _spawn_new_ball():
	# Change color
	_ball_color_index = (_ball_color_index + 1) % BALL_COLORS.size()
	ball_color = BALL_COLORS[_ball_color_index]
	
	# Reset position with random offset
	_ball.linear_velocity = Vector3.ZERO
	_ball.angular_velocity = Vector3.ZERO
	_ball.position = Vector3(
		randf_range(-0.5, 0.5),
		1.0,
		randf_range(0.5, 1.5)
	)
	
	# Random impulse
	_ball.apply_impulse(Vector3(
		randf_range(-1.0, 1.0),
		randf_range(0.2, 0.5),
		randf_range(-1.0, 1.0)
	))
	
	# Reset stats
	_hit_count = 0
	_shots_fired = 0
#endregion

#region Shooting System
func _create_shooting_system():
	_bullets_container = Node3D.new()
	_bullets_container.name = "Bullets"
	add_child(_bullets_container)
	
	# Muzzle flash
	_muzzle_flash = MeshInstance3D.new()
	_muzzle_flash.name = "MuzzleFlash"
	var flash_mesh = SphereMesh.new()
	flash_mesh.radius = 0.04
	flash_mesh.height = 0.08
	_muzzle_flash.mesh = flash_mesh
	
	var flash_mat = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.8, 0.3)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.7, 0.2)
	flash_mat.emission_energy_multiplier = 5.0
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_muzzle_flash.material_override = flash_mat
	_muzzle_flash.visible = false
	_muzzle_flash.position = Vector3(0, 0, barrel_length + 0.02)
	_turret_barrel.add_child(_muzzle_flash)
	
	# Muzzle light
	_muzzle_light = OmniLight3D.new()
	_muzzle_light.name = "MuzzleLight"
	_muzzle_light.light_color = Color(1.0, 0.7, 0.3)
	_muzzle_light.light_energy = 0.0
	_muzzle_light.omni_range = 0.5
	_muzzle_light.position = Vector3(0, 0, barrel_length + 0.02)
	_turret_barrel.add_child(_muzzle_light)

func _fire_bullet():
	if not _target_in_fov or not shooting_enabled:
		return
	
	var barrel_tip = _turret_barrel.global_position + _turret_barrel.global_transform.basis.z * barrel_length
	var target_pos = _ball.global_position
	
	# Lead the target based on ball velocity
	var ball_vel = _ball.linear_velocity
	var time_to_target = (target_pos - barrel_tip).length() / bullet_speed
	var predicted_pos = target_pos + ball_vel * time_to_target * 0.5
	
	# Direction to predicted position (SUBTRACTION + NORMALIZATION)
	var direction = (predicted_pos - barrel_tip).normalized()
	
	# Velocity (SCALAR MULTIPLICATION)
	var velocity = direction * bullet_speed
	
	# Create bullet
	var bullet_node = Node3D.new()
	bullet_node.name = "Bullet_%d" % _shots_fired
	bullet_node.position = barrel_tip
	_bullets_container.add_child(bullet_node)
	
	# Bullet mesh
	var bullet_mesh = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = BULLET_RADIUS
	capsule.height = BULLET_RADIUS * 4
	bullet_mesh.mesh = capsule
	
	var bullet_mat = StandardMaterial3D.new()
	bullet_mat.albedo_color = Color(1.0, 0.8, 0.3)
	bullet_mat.emission_enabled = true
	bullet_mat.emission = Color(1.0, 0.6, 0.2)
	bullet_mat.emission_energy_multiplier = 2.0
	bullet_mesh.material_override = bullet_mat
	
	if velocity.length() > 0.001:
		var up = Vector3.UP
		if abs(velocity.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		bullet_mesh.look_at(bullet_mesh.position + velocity, up)
		bullet_mesh.rotate_object_local(Vector3.RIGHT, PI/2)
	
	bullet_node.add_child(bullet_mesh)
	
	# Velocity arrow
	var velocity_arrow: Node3D = null
	if show_bullet_vectors:
		velocity_arrow = _create_arrow("VelocityArrow", Color(1.0, 0.6, 0.2, 0.8))
		velocity_arrow.scale = Vector3(0.5, 0.5, 0.5)
		bullet_node.add_child(velocity_arrow)
	
	# Trail
	var trail = MeshInstance3D.new()
	var trail_mesh = CylinderMesh.new()
	trail_mesh.top_radius = BULLET_RADIUS * 0.5
	trail_mesh.bottom_radius = BULLET_RADIUS * 0.3
	trail_mesh.height = 0.15
	trail.mesh = trail_mesh
	
	var trail_mat = StandardMaterial3D.new()
	trail_mat.albedo_color = Color(1.0, 0.5, 0.2, 0.5)
	trail_mat.emission_enabled = true
	trail_mat.emission = Color(1.0, 0.4, 0.1)
	trail_mat.emission_energy_multiplier = 1.5
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail.material_override = trail_mat
	trail.position = Vector3(0, -0.08, 0)
	bullet_node.add_child(trail)
	
	_bullets.append({
		"node": bullet_node,
		"position": barrel_tip,
		"velocity": velocity,
		"direction": direction,
		"age": 0.0,
		"velocity_arrow": velocity_arrow
	})
	
	# Muzzle flash
	_muzzle_flash.visible = true
	_muzzle_flash_timer = 0.05
	_muzzle_light.light_energy = 3.0
	
	_shots_fired += 1

func _update_bullets(delta: float):
	var bullets_to_remove: Array[int] = []
	
	for i in range(_bullets.size()):
		var bullet = _bullets[i]
		bullet["age"] += delta
		
		if bullet["age"] > bullet_lifetime:
			bullets_to_remove.append(i)
			continue
		
		# VELOCITY INTEGRATION: P' = P + V * dt
		var old_pos = bullet["position"]
		var new_pos = old_pos + bullet["velocity"] * delta
		bullet["position"] = new_pos
		
		var node = bullet["node"] as Node3D
		if node:
			node.position = new_pos
			
			if bullet["velocity_arrow"]:
				var vel = bullet["velocity"]
				var arrow_end = vel.normalized() * 0.3
				_position_arrow(bullet["velocity_arrow"], Vector3.ZERO, arrow_end)
		
		# Hit detection against ball
		var dist_to_ball = new_pos.distance_to(_ball.global_position)
		if dist_to_ball < HIT_DISTANCE:
			_on_bullet_hit(bullet, new_pos)
			bullets_to_remove.append(i)
			continue
		
		if new_pos.length() > max_range * 2:
			bullets_to_remove.append(i)
	
	for i in range(bullets_to_remove.size() - 1, -1, -1):
		var idx = bullets_to_remove[i]
		var bullet = _bullets[idx]
		if bullet["node"]:
			bullet["node"].queue_free()
		_bullets.remove_at(idx)
	
	if _muzzle_flash_timer > 0:
		_muzzle_flash_timer -= delta
		if _muzzle_flash_timer <= 0:
			_muzzle_flash.visible = false
			_muzzle_light.light_energy = 0.0

func _on_bullet_hit(bullet: Dictionary, hit_pos: Vector3):
	_hit_count += 1
	
	# Apply impulse to ball
	var hit_direction = bullet["velocity"].normalized()
	_ball.apply_impulse(hit_direction * 0.5, hit_pos - _ball.global_position)
	
	# Hit effect
	var hit_effect = Node3D.new()
	hit_effect.name = "HitEffect"
	hit_effect.position = hit_pos
	add_child(hit_effect)
	
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.05
	torus.outer_radius = 0.06
	ring.mesh = torus
	
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.3, 0.1, 0.8)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.2, 0.0)
	ring_mat.emission_energy_multiplier = 3.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	hit_effect.add_child(ring)
	
	for j in range(5):
		var spark = MeshInstance3D.new()
		var spark_mesh = SphereMesh.new()
		spark_mesh.radius = 0.015
		spark_mesh.height = 0.03
		spark.mesh = spark_mesh
		spark.material_override = ring_mat
		spark.position = Vector3(
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1)
		)
		hit_effect.add_child(spark)
	
	_flash_ball()
	
	var timer = get_tree().create_timer(0.3)
	timer.timeout.connect(func(): 
		if is_instance_valid(hit_effect):
			hit_effect.queue_free()
	)

func _flash_ball():
	if _ball_material:
		var original_emission = _ball_material.emission_energy_multiplier
		_ball_material.emission = Color(1.0, 1.0, 1.0)
		_ball_material.emission_energy_multiplier = 4.0
		
		var timer = get_tree().create_timer(0.1)
		timer.timeout.connect(func():
			if _ball_material:
				_ball_material.emission = ball_color
				_ball_material.emission_energy_multiplier = 0.8
		)
#endregion

#region Vector Arrows
func _create_vector_arrows():
	_arrow_direction = _create_arrow("ArrowDirection", color_direction)
	add_child(_arrow_direction)
	
	_arrow_unit_direction = _create_arrow("ArrowUnitDirection", color_direction * 0.7, true)
	add_child(_arrow_unit_direction)
	
	_arrow_cross = _create_arrow("ArrowCross", color_cross)
	add_child(_arrow_cross)
	
	_arrow_projection = _create_arrow("ArrowProjection", color_projection, true)
	add_child(_arrow_projection)
	
	_arrow_velocity = _create_arrow("ArrowBallVelocity", Color(0.2, 1.0, 0.6))
	add_child(_arrow_velocity)

func _create_arrow(arrow_name: String, color: Color, ghost: bool = false) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name
	
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = ARROW_THICKNESS * (0.5 if ghost else 1.0)
	cylinder.bottom_radius = ARROW_THICKNESS * (0.5 if ghost else 1.0)
	cylinder.height = 1.0
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if ghost:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.3
	shaft.material_override = mat
	arrow.add_child(shaft)
	
	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = ARROW_THICKNESS * 2.5 * (0.5 if ghost else 1.0)
	cone.height = ARROW_THICKNESS * 5
	head.mesh = cone
	head.material_override = mat
	arrow.add_child(head)
	
	return arrow

func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3):
	var direction = end - start
	var length = direction.length()
	
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true
	
	arrow.transform = Transform3D.IDENTITY
	arrow.position = start
	
	var shaft = arrow.get_node("Shaft")
	var head = arrow.get_node("Head")
	
	var shaft_length = length - ARROW_THICKNESS * 5
	shaft.scale = Vector3(1, max(shaft_length, 0.01), 1)
	shaft.position = direction.normalized() * (shaft_length / 2.0)
	
	head.position = direction.normalized() * (length - ARROW_THICKNESS * 2.5)
	
	if direction.length() > 0.001:
		var up = Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		arrow.look_at(arrow.global_position + direction, up)
		arrow.rotate_object_local(Vector3.RIGHT, PI/2)
#endregion

#region FOV Visualization
func _create_fov_visualization():
	_fov_cone = MeshInstance3D.new()
	_fov_cone.name = "FOVCone"
	_fov_cone.position = Vector3(0, turret_height, 0)
	add_child(_fov_cone)
#endregion

#region Labels
func _create_labels():
	_label_direction = Label3D.new()
	_label_direction.name = "LabelDirection"
	_label_direction.text = "D = T - P"
	_label_direction.pixel_size = 0.0015
	_label_direction.font_size = 14
	_label_direction.modulate = color_direction
	_label_direction.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_direction.outline_size = 6
	_label_direction.outline_modulate = Color(0, 0, 0, 0.8)
	add_child(_label_direction)
	
	_label_distance = Label3D.new()
	_label_distance.name = "LabelDistance"
	_label_distance.text = "|D|"
	_label_distance.pixel_size = 0.0015
	_label_distance.font_size = 12
	_label_distance.modulate = Color(1, 1, 1, 0.8)
	_label_distance.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label_distance)
	
	_label_dot = Label3D.new()
	_label_dot.name = "LabelDot"
	_label_dot.text = "cos(θ)"
	_label_dot.pixel_size = 0.0015
	_label_dot.font_size = 12
	_label_dot.modulate = Color(0.8, 1.0, 0.8)
	_label_dot.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label_dot)
	
	_label_cross = Label3D.new()
	_label_cross.name = "LabelCross"
	_label_cross.text = "F × D"
	_label_cross.pixel_size = 0.0015
	_label_cross.font_size = 12
	_label_cross.modulate = color_cross
	_label_cross.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label_cross)
	
	_label_proj = Label3D.new()
	_label_proj.name = "LabelProj"
	_label_proj.text = "proj"
	_label_proj.pixel_size = 0.0015
	_label_proj.font_size = 12
	_label_proj.modulate = color_projection
	_label_proj.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label_proj)
	
	_label_velocity = Label3D.new()
	_label_velocity.name = "LabelVelocity"
	_label_velocity.text = "V = D̂ × speed"
	_label_velocity.pixel_size = 0.0015
	_label_velocity.font_size = 12
	_label_velocity.modulate = Color(1.0, 0.6, 0.2)
	_label_velocity.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_velocity.visible = false
	add_child(_label_velocity)
	
	_label_ball_velocity = Label3D.new()
	_label_ball_velocity.name = "LabelBallVelocity"
	_label_ball_velocity.text = "Ball V"
	_label_ball_velocity.pixel_size = 0.0015
	_label_ball_velocity.font_size = 12
	_label_ball_velocity.modulate = Color(0.2, 1.0, 0.6)
	_label_ball_velocity.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label_ball_velocity)
#endregion

#region Info Panels
func _create_text_panel(panel_name: String, text: String, pos: Vector3, 
		size: Vector2 = Vector2(0.5, 0.12), font_size: int = 16, 
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Node3D:
	var panel = Node3D.new()
	panel.name = panel_name
	panel.position = pos
	
	var backing = MeshInstance3D.new()
	backing.name = "Backing"
	var box = BoxMesh.new()
	box.size = Vector3(size.x, size.y, 0.008)
	backing.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = panel_color
	mat.metallic = 0.2
	mat.roughness = 0.8
	backing.material_override = mat
	backing.position.z = -0.005
	panel.add_child(backing)
	
	_add_panel_frame(panel, size)
	
	var label = Label3D.new()
	label.name = "Label"
	label.text = text
	label.pixel_size = 0.001
	label.font_size = font_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position.z = 0.002
	panel.add_child(label)
	
	return panel

func _add_panel_frame(panel: Node3D, size: Vector2):
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.3, 0.32, 0.35)
	frame_mat.metallic = 0.5
	frame_mat.roughness = 0.4
	
	var thickness = 0.004
	var depth = 0.01
	var half_w = size.x / 2.0
	var half_h = size.y / 2.0
	
	for y_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(size.x + thickness * 2, thickness, depth)
		edge.mesh = box
		edge.material_override = frame_mat
		edge.position = Vector3(0, half_h * y_mult, -depth/2 + 0.002)
		panel.add_child(edge)
	
	for x_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(thickness, size.y, depth)
		edge.mesh = box
		edge.material_override = frame_mat
		edge.position = Vector3(half_w * x_mult, 0, -depth/2 + 0.002)
		panel.add_child(edge)

func _get_panel_label(panel: Node3D) -> Label3D:
	return panel.get_node_or_null("Label") as Label3D

func _create_info_panels():
	_title_panel = _create_text_panel(
		"TitlePanel",
		"SENTRY TURRET\nVECTOR OPERATIONS",
		Vector3(0, turret_height + 0.55, -0.5),
		Vector2(0.5, 0.12),
		18
	)
	_title_panel.rotation_degrees = Vector3(0, 180, 0)
	add_child(_title_panel)
	
	_status_panel = _create_text_panel(
		"StatusPanel",
		"SEARCHING...",
		Vector3(0, turret_height + 0.38, -0.5),
		Vector2(0.4, 0.08),
		16
	)
	_status_panel.rotation_degrees = Vector3(0, 180, 0)
	add_child(_status_panel)
	
	_math_panel = _create_text_panel(
		"MathPanel",
		"",
		Vector3(-1.3, turret_height + 0.25, 0),
		Vector2(0.72, 0.55),
		11,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	_math_panel.rotation_degrees = Vector3(0, 90, 0)
	add_child(_math_panel)
	
	_operations_panel = _create_text_panel(
		"OperationsPanel",
		"VECTOR OPERATIONS:\n" +
		"━━━━━━━━━━━━━━━━━━━━━━\n" +
		"SUBTRACT: D = T - P (direction)\n" +
		"MAGNITUDE: |D| (distance)\n" +
		"NORMALIZE: D̂ = D/|D| (unit dir)\n" +
		"DOT: F̂·D̂ = cos(θ) (FOV check)\n" +
		"CROSS: F × D (rotation axis)\n" +
		"PROJECT: D onto XZ (ground)\n" +
		"━━━━━━━━━━━━━━━━━━━━━━\n" +
		"BULLET PHYSICS:\n" +
		"SCALAR MULT: V = D̂ × speed\n" +
		"INTEGRATE: P' = P + V × Δt",
		Vector3(1.3, turret_height + 0.1, 0),
		Vector2(0.58, 0.45),
		10,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	_operations_panel.rotation_degrees = Vector3(0, -90, 0)
	add_child(_operations_panel)
#endregion

#region VR Controls
func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.08, max_range + 0.5)
	_control_panel.rotation_degrees = Vector3(-35, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.65, 0.28, 0.015)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.06, 0.06, 0.08)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Title
	var title = Label3D.new()
	title.text = "TURRET CONTROLS"
	title.pixel_size = 0.001
	title.font_size = 14
	title.position = Vector3(0, 0.11, 0.01)
	_control_panel.add_child(title)
	
	# FOV Slider
	_fov_slider = SLIDER_HORIZONTAL.instantiate()
	_fov_slider.name = "FOVSlider"
	_fov_slider.position = Vector3(-0.2, 0.05, 0.01)
	_fov_slider.scale = Vector3(0.8, 0.8, 0.8)
	_control_panel.add_child(_fov_slider)
	_add_slider_label(_fov_slider, "FOV", -0.12)
	_connect_slider(_fov_slider, _on_fov_changed)
	
	# Fire Rate Slider
	_fire_rate_slider = SLIDER_HORIZONTAL.instantiate()
	_fire_rate_slider.name = "FireRateSlider"
	_fire_rate_slider.position = Vector3(-0.2, 0.0, 0.01)
	_fire_rate_slider.scale = Vector3(0.8, 0.8, 0.8)
	_control_panel.add_child(_fire_rate_slider)
	_add_slider_label(_fire_rate_slider, "RATE", -0.12)
	_connect_slider(_fire_rate_slider, _on_fire_rate_changed)
	
	# Bullet Speed Slider
	_bullet_speed_slider = SLIDER_HORIZONTAL.instantiate()
	_bullet_speed_slider.name = "BulletSpeedSlider"
	_bullet_speed_slider.position = Vector3(-0.2, -0.05, 0.01)
	_bullet_speed_slider.scale = Vector3(0.8, 0.8, 0.8)
	_control_panel.add_child(_bullet_speed_slider)
	_add_slider_label(_bullet_speed_slider, "SPEED", -0.12)
	_connect_slider(_bullet_speed_slider, _on_bullet_speed_changed)
	
	# Spawn Ball Button
	_spawn_ball_button = PUSH_BUTTON.instantiate()
	_spawn_ball_button.name = "SpawnBallButton"
	_spawn_ball_button.position = Vector3(0.18, 0.03, 0.01)
	_spawn_ball_button.scale = Vector3(1.0, 1.0, 1.0)
	_control_panel.add_child(_spawn_ball_button)
	_add_button_label(_spawn_ball_button, "NEW BALL")
	_connect_button(_spawn_ball_button, _spawn_new_ball)
	
	# Toggle Shooting Button
	_toggle_shooting_button = PUSH_BUTTON.instantiate()
	_toggle_shooting_button.name = "ToggleShootingButton"
	_toggle_shooting_button.position = Vector3(0.18, -0.05, 0.01)
	_toggle_shooting_button.scale = Vector3(1.0, 1.0, 1.0)
	_control_panel.add_child(_toggle_shooting_button)
	_add_button_label(_toggle_shooting_button, "FIRE: ON")
	_connect_button(_toggle_shooting_button, _toggle_shooting)

func _add_slider_label(slider: Node, text: String, x_offset: float):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 10
	lbl.position = Vector3(x_offset, 0, 0)
	slider.add_child(lbl)

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.name = "ButtonLabel"
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 9
	lbl.position = Vector3(0, -0.03, 0)
	btn.add_child(lbl)

func _connect_slider(slider: Node, callback: Callable):
	await get_tree().process_frame
	var interactable = slider.get_node_or_null("SliderHorizontal")
	if interactable and interactable.has_signal("value_changed"):
		interactable.value_changed.connect(callback)

func _connect_button(btn: Node, callback: Callable):
	await get_tree().process_frame
	var interactable = btn.get_node_or_null("InteractableAreaButton")
	if interactable and interactable.has_signal("button_pressed"):
		interactable.button_pressed.connect(func(_b): callback.call())
	# Also connect to the button's own signal
	if btn.has_signal("pressed"):
		btn.pressed.connect(callback)

func _on_fov_changed(value: float):
	field_of_view_degrees = lerp(30.0, 180.0, value)

func _on_fire_rate_changed(value: float):
	fire_rate = lerp(0.5, 10.0, value)

func _on_bullet_speed_changed(value: float):
	bullet_speed = lerp(1.0, 10.0, value)

func _toggle_shooting():
	shooting_enabled = not shooting_enabled
	var label = _toggle_shooting_button.get_node_or_null("ButtonLabel")
	if label:
		label.text = "FIRE: ON" if shooting_enabled else "FIRE: OFF"

func _sync_fov_slider():
	if _fov_slider:
		var interactable = _fov_slider.get_node_or_null("SliderHorizontal")
		if interactable and interactable.has_method("set_value"):
			interactable.set_value(inverse_lerp(30.0, 180.0, field_of_view_degrees))

func _sync_fire_rate_slider():
	if _fire_rate_slider:
		var interactable = _fire_rate_slider.get_node_or_null("SliderHorizontal")
		if interactable and interactable.has_method("set_value"):
			interactable.set_value(inverse_lerp(0.5, 10.0, fire_rate))

func _sync_bullet_speed_slider():
	if _bullet_speed_slider:
		var interactable = _bullet_speed_slider.get_node_or_null("SliderHorizontal")
		if interactable and interactable.has_method("set_value"):
			interactable.set_value(inverse_lerp(1.0, 10.0, bullet_speed))
#endregion

#region Update Logic
func _update_visualization():
	var turret_pos = Vector3(0, turret_height, 0)
	var target_pos = _ball.global_position if _ball else Vector3(1, 0.5, 1)
	
	# === SUBTRACTION: Direction to target ===
	var direction = target_pos - turret_pos
	var distance = direction.length()
	
	# === MAGNITUDE: Distance check ===
	_target_in_range = distance <= max_range
	
	# === NORMALIZATION: Unit direction ===
	var unit_direction = direction.normalized() if distance > 0.001 else Vector3.FORWARD
	
	# === DOT PRODUCT: FOV check ===
	var forward = _turret_body.global_transform.basis.z if _turret_body else Vector3.FORWARD
	var cos_angle = forward.dot(unit_direction)
	var angle_to_target = acos(clampf(cos_angle, -1.0, 1.0))
	var fov_half_rad = deg_to_rad(field_of_view_degrees / 2.0)
	_target_in_fov = angle_to_target <= fov_half_rad and _target_in_range
	
	# === CROSS PRODUCT: Rotation axis ===
	var cross = forward.cross(unit_direction)
	
	# === PROJECTION: Target on ground plane ===
	var ground_projection = Vector3(target_pos.x, 0, target_pos.z)
	
	# Update turret aim
	_update_turret_aim(unit_direction)
	
	# Direction arrow
	_position_arrow(_arrow_direction, turret_pos, target_pos)
	_label_direction.position = turret_pos + direction * 0.5 + Vector3(0.08, 0.08, 0)
	_label_direction.text = "D = T - P"
	
	_label_distance.position = turret_pos + direction * 0.5 + Vector3(-0.08, -0.05, 0)
	_label_distance.text = "|D| = %.2f" % distance
	
	# Unit direction arrow
	var unit_end = turret_pos + unit_direction * 0.4
	_position_arrow(_arrow_unit_direction, turret_pos + Vector3(0, 0.1, 0), turret_pos + Vector3(0, 0.1, 0) + unit_direction * 0.35)
	
	# Cross product arrow
	if cross.length() > 0.01:
		var cross_start = turret_pos + Vector3(0, -0.1, 0)
		var cross_display = cross.normalized() * 0.25
		_position_arrow(_arrow_cross, cross_start, cross_start + cross_display)
		_label_cross.position = cross_start + cross_display * 0.5 + Vector3(0.05, 0, 0.05)
		_label_cross.text = "F × D̂"
		_arrow_cross.visible = true
		_label_cross.visible = true
	else:
		_arrow_cross.visible = false
		_label_cross.visible = false
	
	# Projection arrow
	var proj_dir = ground_projection - Vector3(0, 0, 0)
	if proj_dir.length() > 0.01:
		_position_arrow(_arrow_projection, Vector3.ZERO, ground_projection)
		_label_proj.position = ground_projection * 0.5 + Vector3(0, 0.05, 0)
		_label_proj.text = "proj(D, XZ)"
	
	# Ground projection marker
	_ball_ground_projection.position = ground_projection + Vector3(0, 0.003, 0)
	
	# Drop line
	_update_drop_line(target_pos, ground_projection)
	
	# Ball velocity arrow
	if _ball:
		var ball_vel = _ball.linear_velocity
		if ball_vel.length() > 0.1:
			_position_arrow(_arrow_velocity, target_pos, target_pos + ball_vel.normalized() * 0.4)
			_label_ball_velocity.position = target_pos + ball_vel.normalized() * 0.25 + Vector3(0.1, 0.05, 0)
			_label_ball_velocity.text = "V: %.1f" % ball_vel.length()
			_arrow_velocity.visible = true
			_label_ball_velocity.visible = true
		else:
			_arrow_velocity.visible = false
			_label_ball_velocity.visible = false
	
	# Dot product label
	_label_dot.position = turret_pos + forward * 0.3 + Vector3(0, 0.15, 0)
	_label_dot.text = "cos(θ) = %.2f\nθ = %.1f°" % [cos_angle, rad_to_deg(angle_to_target)]
	_label_dot.modulate = color_fov_in if _target_in_fov else Color(1.0, 0.4, 0.3)
	
	# Laser
	_update_laser(target_pos)
	
	# FOV cone
	_update_fov_cone()
	
	# Info panels
	_update_info_panels(turret_pos, direction, distance, unit_direction, cos_angle, cross, ground_projection)

func _update_turret_aim(target_dir: Vector3):
	var target_yaw = atan2(target_dir.x, target_dir.z)
	var horizontal_dist = Vector2(target_dir.x, target_dir.z).length()
	var target_pitch = atan2(target_dir.y, horizontal_dist)
	
	_turret_yaw = lerp_angle(_turret_yaw, target_yaw, 0.1)
	_turret_pitch = lerp_angle(_turret_pitch, clampf(target_pitch, -PI/4, PI/4), 0.1)
	
	_turret_body.rotation.y = _turret_yaw
	_turret_barrel.rotation.x = -_turret_pitch

func _update_laser(target_pos: Vector3):
	var barrel_tip = _turret_barrel.global_position + _turret_barrel.global_transform.basis.z * barrel_length
	
	if _target_in_fov:
		_laser_beam.visible = true
		_laser_dot.visible = true
		
		var laser_length = (target_pos - barrel_tip).length()
		_laser_beam.position = Vector3(0, 0, barrel_length + laser_length / 2.0)
		_laser_beam.scale = Vector3(1, laser_length, 1)
		_laser_beam.rotation = Vector3.ZERO
		_laser_beam.rotation.x = PI/2
		
		_laser_dot.position = target_pos
		
		var pulse = 0.8 + sin(Time.get_ticks_msec() * 0.01) * 0.2
		_eye_light.light_energy = pulse
	else:
		_laser_beam.visible = false
		_laser_dot.visible = false
		_eye_light.light_energy = 0.2

func _update_drop_line(target: Vector3, ground: Vector3):
	var dir = target - ground
	var length = dir.length()
	
	if length < 0.01:
		_drop_line.visible = false
		return
	_drop_line.visible = true
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.004
	cylinder.bottom_radius = 0.004
	cylinder.height = length
	_drop_line.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.8, 1.0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_drop_line.material_override = mat
	
	_drop_line.position = (target + ground) / 2.0

func _update_fov_cone():
	var cone_length = max_range
	var cone_radius = tan(deg_to_rad(field_of_view_degrees / 2.0)) * cone_length
	
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var segments = 32
	var apex = Vector3.ZERO
	
	for i in range(segments):
		var angle1 = (float(i) / segments) * TAU
		var angle2 = (float(i + 1) / segments) * TAU
		
		var p1 = Vector3(cos(angle1) * cone_radius, sin(angle1) * cone_radius, cone_length)
		var p2 = Vector3(cos(angle2) * cone_radius, sin(angle2) * cone_radius, cone_length)
		
		immediate_mesh.surface_add_vertex(apex)
		immediate_mesh.surface_add_vertex(p1)
		immediate_mesh.surface_add_vertex(p2)
	
	immediate_mesh.surface_end()
	_fov_cone.mesh = immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_fov_in if _target_in_fov else color_fov_out
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fov_cone.material_override = mat
	
	_fov_cone.rotation = _turret_body.rotation

func _update_info_panels(turret_pos: Vector3, direction: Vector3, distance: float, 
		unit_dir: Vector3, cos_angle: float, cross: Vector3, ground_proj: Vector3):
	
	var status_label = _get_panel_label(_status_panel)
	if status_label:
		if _target_in_fov:
			if shooting_enabled and _muzzle_flash_timer > 0:
				status_label.text = "⚡ FIRING ⚡"
				status_label.modulate = Color(1.0, 0.5, 0.2)
			else:
				status_label.text = "▶ TARGET ACQUIRED ◀"
				status_label.modulate = Color(0.3, 1.0, 0.4)
		elif not _target_in_range:
			status_label.text = "OUT OF RANGE"
			status_label.modulate = Color(1.0, 0.5, 0.2)
		else:
			status_label.text = "SEARCHING..."
			status_label.modulate = Color(1.0, 1.0, 0.3)
	
	var math_label = _get_panel_label(_math_panel)
	if math_label:
		var angle_deg = rad_to_deg(acos(clampf(cos_angle, -1.0, 1.0)))
		var ball_vel = _ball.linear_velocity if _ball else Vector3.ZERO
		
		math_label.text = "TURRET (P): (%.2f, %.2f, %.2f)\n" % [turret_pos.x, turret_pos.y, turret_pos.z]
		math_label.text += "TARGET (T): (%.2f, %.2f, %.2f)\n\n" % [_ball.global_position.x, _ball.global_position.y, _ball.global_position.z] if _ball else ""
		
		math_label.text += "DIRECTION (D = T - P):\n"
		math_label.text += "  (%.2f, %.2f, %.2f)\n\n" % [direction.x, direction.y, direction.z]
		
		math_label.text += "DISTANCE |D| = %.3f\n\n" % distance
		
		math_label.text += "UNIT DIR D̂: (%.2f, %.2f, %.2f)\n\n" % [unit_dir.x, unit_dir.y, unit_dir.z]
		
		math_label.text += "DOT (F̂·D̂) = %.3f → θ = %.1f°\n" % [cos_angle, angle_deg]
		math_label.text += "FOV/2 = %.1f° %s\n\n" % [field_of_view_degrees / 2.0, 
			"✓ IN VIEW" if _target_in_fov else "✗ OUTSIDE"]
		
		math_label.text += "BALL VELOCITY: (%.1f, %.1f, %.1f)\n\n" % [ball_vel.x, ball_vel.y, ball_vel.z]
		
		if shooting_enabled:
			var accuracy = float(_hit_count) / max(_shots_fired, 1) * 100.0
			math_label.text += "━━━ FIRING DATA ━━━\n"
			math_label.text += "Shots: %d  Hits: %d  (%.0f%%)" % [_shots_fired, _hit_count, accuracy]
#endregion

func _process(delta):
	_update_visualization()
	
	# Shooting logic
	if shooting_enabled and _target_in_fov:
		_time_since_last_shot += delta
		var fire_interval = 1.0 / fire_rate
		if _time_since_last_shot >= fire_interval:
			_fire_bullet()
			_time_since_last_shot = 0.0
	
	_update_bullets(delta)
	
	# Update velocity label for bullets
	if _bullets.size() > 0 and show_bullet_vectors:
		var newest = _bullets[_bullets.size() - 1]
		var vel = newest["velocity"]
		_label_velocity.visible = true
		_label_velocity.position = newest["position"] + Vector3(0.1, 0.1, 0)
		_label_velocity.text = "V = D̂ × %.1f\n(%.1f, %.1f, %.1f)" % [
			bullet_speed, vel.x, vel.y, vel.z
		]
	else:
		_label_velocity.visible = false

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE: _fire_bullet()
			KEY_F: _toggle_shooting()
			KEY_N: _spawn_new_ball()
			KEY_1: field_of_view_degrees = 60.0
			KEY_2: field_of_view_degrees = 90.0
			KEY_3: field_of_view_degrees = 120.0

func get_target_status() -> Dictionary:
	return {
		"in_fov": _target_in_fov,
		"in_range": _target_in_range,
		"distance": (_ball.global_position - Vector3(0, turret_height, 0)).length() if _ball else 0.0,
		"shots_fired": _shots_fired,
		"hits": _hit_count,
		"accuracy": float(_hit_count) / max(_shots_fired, 1) * 100.0
	}

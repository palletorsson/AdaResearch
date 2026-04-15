# ===========================================================================
# SlingshotLauncher.gd - Player Catapult Platform
# Step onto the platform, it charges, then LAUNCHES you into the air
# Like the Horizon Worlds cannon from the reference image
# Shows impulse, projectile motion, and Newton's third law
#
# QFEP: Impulse — a short burst of force that changes everything.
# ===========================================================================
extends Node3D

class_name SlingshotLauncher

## Launch parameters
@export var launch_force: float = 18.0:
	set(value):
		launch_force = clampf(value, 5.0, 40.0)
@export var launch_angle_deg: float = 60.0:
	set(value):
		launch_angle_deg = clampf(value, 15.0, 85.0)
@export var charge_time: float = 2.0

## Platform dimensions
@export var platform_radius: float = 0.5
@export var platform_height: float = 0.08
@export var arm_length: float = 1.2

## Colors
@export var base_color: Color = Color(0.2, 0.2, 0.25)
@export var platform_color: Color = Color(0.4, 0.6, 1.0)
@export var charged_color: Color = Color(1.0, 0.4, 0.2)
@export var arm_color: Color = Color(0.6, 0.6, 0.65)

# State
enum State { IDLE, CHARGING, READY, LAUNCHING }
var _state: int = State.IDLE
var _charge_progress: float = 0.0
var _player_on_platform: bool = false
var _launch_timer: float = 0.0

# Visuals
var _base_mesh: MeshInstance3D
var _platform_mesh: MeshInstance3D
var _arm_mesh: MeshInstance3D
var _arm_pivot: Node3D
var _charge_ring: MeshInstance3D
var _trajectory_mesh: MeshInstance3D
var _info_label: Label3D
var _control_panel: Node3D
var _detection_area: Area3D

# Arrow showing launch direction
var _launch_arrow: Node3D


func _ready() -> void:
	_create_base()
	_create_arm_mechanism()
	_create_platform_with_detection()
	_create_charge_indicator()
	_create_launch_arrow()
	_create_trajectory_preview()
	_create_labels()
	_create_vr_controls()

func _create_base() -> void:
	# Heavy base block
	_base_mesh = MeshInstance3D.new()
	_base_mesh.name = "Base"
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.4, 1.0)
	_base_mesh.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.metallic = 0.5
	mat.roughness = 0.4
	_base_mesh.material_override = mat
	_base_mesh.position = Vector3(0, 0.2, 0)
	add_child(_base_mesh)

	# Pivot housing
	var housing := MeshInstance3D.new()
	housing.name = "PivotHousing"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.12
	cyl.height = 0.15
	housing.mesh = cyl
	housing.material_override = mat
	housing.position = Vector3(0, 0.45, 0)
	add_child(housing)

func _create_arm_mechanism() -> void:
	# Pivot point for the arm
	_arm_pivot = Node3D.new()
	_arm_pivot.name = "ArmPivot"
	_arm_pivot.position = Vector3(0, 0.5, 0)
	add_child(_arm_pivot)

	# Catapult arm
	_arm_mesh = MeshInstance3D.new()
	_arm_mesh.name = "Arm"
	var box := BoxMesh.new()
	box.size = Vector3(0.08, arm_length, 0.08)
	_arm_mesh.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = arm_color
	mat.metallic = 0.6
	mat.roughness = 0.3
	_arm_mesh.material_override = mat
	_arm_mesh.position = Vector3(0, arm_length / 2.0, 0)
	_arm_pivot.add_child(_arm_mesh)

func _create_platform_with_detection() -> void:
	# Platform at the end of the arm
	_platform_mesh = MeshInstance3D.new()
	_platform_mesh.name = "Platform"
	var cyl := CylinderMesh.new()
	cyl.top_radius = platform_radius
	cyl.bottom_radius = platform_radius
	cyl.height = platform_height
	_platform_mesh.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = platform_color
	mat.emission_enabled = true
	mat.emission = platform_color * 0.3
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.4
	_platform_mesh.material_override = mat
	_platform_mesh.position = Vector3(0, arm_length + platform_height / 2.0, 0)
	_arm_pivot.add_child(_platform_mesh)

	# Detection area to know when player steps on
	_detection_area = Area3D.new()
	_detection_area.name = "PlayerDetector"
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = platform_radius * 0.8
	shape.height = 0.5
	col.shape = shape
	_detection_area.add_child(col)
	_detection_area.position = Vector3(0, arm_length + 0.3, 0)
	_detection_area.monitoring = true
	_detection_area.body_entered.connect(_on_body_entered)
	_detection_area.body_exited.connect(_on_body_exited)
	_arm_pivot.add_child(_detection_area)

func _create_charge_indicator() -> void:
	# Ring around platform that fills as it charges
	_charge_ring = MeshInstance3D.new()
	_charge_ring.name = "ChargeRing"
	var torus := TorusMesh.new()
	torus.inner_radius = platform_radius - 0.02
	torus.outer_radius = platform_radius + 0.02
	_charge_ring.mesh = torus
	_charge_ring.rotation_degrees.x = 90

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.8, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.4, 0.8)
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_charge_ring.material_override = mat
	_charge_ring.position = Vector3(0, arm_length + platform_height + 0.01, 0)
	_arm_pivot.add_child(_charge_ring)

func _create_launch_arrow() -> void:
	_launch_arrow = Node3D.new()
	_launch_arrow.name = "LaunchArrow"

	# Shaft
	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.02
	cyl.height = 0.5
	shaft.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.2)
	mat.emission_energy_multiplier = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft.material_override = mat
	shaft.position = Vector3(0, 0.25, 0)
	_launch_arrow.add_child(shaft)

	# Head
	var head := MeshInstance3D.new()
	head.name = "Head"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.06
	cone.height = 0.1
	head.mesh = cone
	head.material_override = mat
	head.position = Vector3(0, 0.55, 0)
	_launch_arrow.add_child(head)

	# Orient along launch direction
	_update_launch_arrow()
	_launch_arrow.position = Vector3(0, arm_length + 0.2, 0)
	_arm_pivot.add_child(_launch_arrow)

func _update_launch_arrow() -> void:
	var angle_rad := deg_to_rad(launch_angle_deg)
	var dir := Vector3(0, sin(angle_rad), -cos(angle_rad)).normalized()
	_launch_arrow.transform.basis = Basis.IDENTITY
	if dir.length() > 0.001:
		var up := Vector3.RIGHT if abs(dir.dot(Vector3.UP)) > 0.99 else Vector3.UP
		_launch_arrow.look_at(_launch_arrow.position + dir, up)
		_launch_arrow.rotate_object_local(Vector3.RIGHT, -PI / 2.0)

func _create_trajectory_preview() -> void:
	_trajectory_mesh = MeshInstance3D.new()
	_trajectory_mesh.name = "TrajectoryPreview"
	add_child(_trajectory_mesh)
	_update_trajectory()

func _update_trajectory() -> void:
	# Show predicted parabolic arc
	var angle_rad := deg_to_rad(launch_angle_deg)
	var vx := launch_force * cos(angle_rad)
	var vy := launch_force * sin(angle_rad)
	var launch_y := arm_length + 0.5  # Approximate launch height

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var dt := 0.05
	var g := 9.8
	for step in range(60):
		var t := step * dt
		var x := 0.0
		var y := launch_y + vy * t - 0.5 * g * t * t
		var z := -vx * t
		if y < 0:
			break
		var alpha := 1.0 - float(step) / 60.0
		im.surface_set_color(Color(1.0, 0.6, 0.2, alpha * 0.5))
		im.surface_add_vertex(Vector3(x, y, z))

	im.surface_end()
	_trajectory_mesh.mesh = im

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trajectory_mesh.material_override = mat

func _on_body_entered(body: Node3D) -> void:
	if _is_player(body) and _state == State.IDLE:
		_player_on_platform = true
		_state = State.CHARGING
		_charge_progress = 0.0

func _on_body_exited(body: Node3D) -> void:
	if _is_player(body):
		_player_on_platform = false
		if _state == State.CHARGING:
			_state = State.IDLE
			_charge_progress = 0.0

func _is_player(body: Node3D) -> bool:
	return body.is_in_group("player") or body.is_in_group("player_body") or \
		   "player" in body.name.to_lower()

func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE:
			_update_charge_visual(0.0)
		State.CHARGING:
			_charge_progress += delta / charge_time
			_update_charge_visual(_charge_progress)
			if _charge_progress >= 1.0:
				_state = State.READY
				_launch()
		State.LAUNCHING:
			_launch_timer -= delta
			if _launch_timer <= 0:
				_state = State.IDLE

func _launch() -> void:
	_state = State.LAUNCHING
	_launch_timer = 1.0

	# Apply velocity to the player
	var angle_rad := deg_to_rad(launch_angle_deg)
	var launch_velocity := Vector3(0, sin(angle_rad), -cos(angle_rad)) * launch_force

	# Find the XR origin and apply impulse
	var xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if xr_origin:
		# Try CharacterBody3D-based player
		var player_body = xr_origin.get_parent() if xr_origin.get_parent() else xr_origin
		if player_body.has_method("set_velocity"):
			player_body.velocity = launch_velocity
		elif player_body is RigidBody3D:
			player_body.linear_velocity = launch_velocity
		elif player_body.has_method("apply_impulse"):
			player_body.apply_impulse(launch_velocity)
		# Fallback: directly translate via position (last resort)
		else:
			# Use a tween to simulate the launch arc
			var tween := create_tween()
			var start_pos: Vector3 = player_body.global_position
			tween.tween_property(player_body, "global_position",
				start_pos + launch_velocity * 0.3, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Also launch some visual test balls for the physics demo
	_launch_demo_balls()

func _launch_demo_balls() -> void:
	# Fire 3 colored balls along the trajectory so the physics is visible
	for i in range(3):
		var rb := RigidBody3D.new()
		rb.name = "LaunchBall_%d" % i

		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.06
		col.shape = shape
		rb.add_child(col)

		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		mesh.mesh = sphere
		var mat := StandardMaterial3D.new()
		var color := Color.from_hsv(float(i) / 3.0, 0.8, 1.0)
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color * 0.5
		mat.emission_energy_multiplier = 1.5
		mesh.material_override = mat
		rb.add_child(mesh)

		var angle_rad := deg_to_rad(launch_angle_deg)
		var spread := (float(i) - 1.0) * 0.15
		var vel := Vector3(spread, sin(angle_rad), -cos(angle_rad)) * launch_force * 0.8
		rb.position = _arm_pivot.global_position + Vector3(0, arm_length + 0.3, 0)
		rb.linear_velocity = vel

		get_tree().current_scene.add_child(rb)

		# Auto-cleanup after 8 seconds
		var timer := Timer.new()
		timer.wait_time = 8.0
		timer.one_shot = true
		timer.timeout.connect(func(): rb.queue_free())
		rb.add_child(timer)
		timer.start()

func _update_charge_visual(progress: float) -> void:
	progress = clampf(progress, 0, 1)
	var ring_mat := _charge_ring.material_override as StandardMaterial3D
	if ring_mat:
		var color := platform_color.lerp(charged_color, progress)
		ring_mat.albedo_color = Color(color.r, color.g, color.b, 0.3 + progress * 0.5)
		ring_mat.emission = color
		ring_mat.emission_energy_multiplier = 0.5 + progress * 2.0

	# Pulse the platform
	var plat_mat := _platform_mesh.material_override as StandardMaterial3D
	if plat_mat:
		var color := platform_color.lerp(charged_color, progress)
		plat_mat.emission = color * (0.3 + progress * 0.7)
		plat_mat.emission_energy_multiplier = 0.5 + progress * 2.5

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, arm_length + 1.0, 0)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.outline_size = 3
	_info_label.outline_modulate = Color.BLACK
	_info_label.text = "SLINGSHOT LAUNCHER\nStep on the platform!"
	add_child(_info_label)

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("SLINGSHOT", [
		[
			{"type": "slider_h", "label": "POWER", "default": (launch_force - 5.0) / 35.0},
			{"type": "slider_h", "label": "ANGLE", "default": (launch_angle_deg - 15.0) / 70.0},
		],
		[{"type": "button", "label": "LAUNCH!"}],
	])
	_control_panel.position = Vector3(0.7, 0.8, 0)
	_control_panel.rotation_degrees = Vector3(0, -90, 0)
	add_child(_control_panel)

	# POWER slider (Param_0)
	var power_slider: Node = _control_panel.find_child("Param_0", true, false)
	if power_slider and power_slider.has_signal("slider_moved"):
		power_slider.slider_moved.connect(func(_pos):
			if power_slider.has_method("get_normalized_value"):
				launch_force = 5.0 + power_slider.get_normalized_value() * 35.0
				_update_trajectory()
				_update_launch_arrow()
		)

	# ANGLE slider (Param_1)
	var angle_slider: Node = _control_panel.find_child("Param_1", true, false)
	if angle_slider and angle_slider.has_signal("slider_moved"):
		angle_slider.slider_moved.connect(func(_pos):
			if angle_slider.has_method("get_normalized_value"):
				launch_angle_deg = 15.0 + angle_slider.get_normalized_value() * 70.0
				_update_trajectory()
				_update_launch_arrow()
		)

	# LAUNCH button (Btn_0)
	var launch_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if launch_btn:
		var launch_area = launch_btn.get_node_or_null("InteractableAreaButton")
		if launch_area:
			launch_area.button_pressed.connect(func(_b):
				if _state == State.IDLE or _state == State.CHARGING:
					_charge_progress = 1.0
					_state = State.READY
					_launch()
			)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_charge_progress = 1.0
				_state = State.READY
				_launch()
			KEY_UP: launch_force = minf(launch_force + 2.0, 40.0); _update_trajectory()
			KEY_DOWN: launch_force = maxf(launch_force - 2.0, 5.0); _update_trajectory()

func reset() -> void:
	_state = State.IDLE
	_charge_progress = 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass

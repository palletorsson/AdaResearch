# ===========================================================================
# NOC Example 2.4: Friction
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const PARAMETER_CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const DEFAULT_GRAVITY := 0.9
const DEFAULT_COEFF := 0.15
const FLOOR_ZONES: Array = [
	{ "start": -0.4, "end": -0.1, "coeff": 0.05, "label": "Polished" },
	{ "start": -0.1, "end": 0.2, "coeff": 0.15, "label": "Wood" },
	{ "start": 0.2, "end": 0.45, "coeff": 0.35, "label": "Rough" }
]

var mover: Mover

var gravity_strength: float = DEFAULT_GRAVITY
var base_coefficient: float = DEFAULT_COEFF

var info_label: Label3D
var instructions_label: Label3D
var coeff_controller: ParameterController3D
var gravity_controller: ParameterController3D
var friction_arrow: Node3D
var auto_reset_timer: Timer

func _ready() -> void:
	create_floor_segments()
	create_ui()
	spawn_mover()
	setup_auto_reset()
	print("Example 2.4: Friction")

func setup_auto_reset() -> void:
	auto_reset_timer = Timer.new()
	auto_reset_timer.wait_time = 20.0
	auto_reset_timer.autostart = true
	auto_reset_timer.timeout.connect(reset_scene)
	add_child(auto_reset_timer)

func _process(_delta: float) -> void:
	update_info_label()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(mover):
		return

	var gravity_force: Vector3 = Vector3(0, -gravity_strength * mover.mass, 0)
	mover.apply_force(gravity_force)

	var friction_force: Vector3 = compute_friction(mover.velocity)
	mover.apply_force(friction_force)

	update_friction_arrow(friction_force)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_scene()
			KEY_SPACE:
				impulse_forward()

func create_floor_segments() -> void:
	for zone in FLOOR_ZONES:
		var width: float = 0.9
		var depth: float = float(zone["end"]) - float(zone["start"])

		var plane := MeshInstance3D.new()
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(width, depth)
		plane.mesh = mesh
		plane.rotation_degrees = Vector3(-90, 0, 0)
		plane.position = Vector3(0, -0.3, (float(zone["start"]) + float(zone["end"])) * 0.5)

		var mat := StandardMaterial3D.new()
		var coeff := float(zone["coeff"])
		var intensity: float = lerp(0.4, 0.75, coeff)
		mat.albedo_color = Color(1.0, intensity, 0.9, 0.7)
		mat.roughness = clamp(coeff * 1.5, 0.2, 1.0)
		mat.metallic = 0.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		plane.material_override = mat
		add_child(plane)

		var label := Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 16
		label.modulate = Color(1.0, 0.85, 1.0)
		label.position = plane.position + Vector3(0, 0.02, 0)
		label.text = "%s mu=%.2f" % [String(zone["label"]), coeff]
		add_child(label)

func create_ui() -> void:
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.68, -0.25)
	add_child(info_label)

	instructions_label = Label3D.new()
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.font_size = 18
	instructions_label.modulate = Color(0.8, 1.0, 0.9)
	instructions_label.position = Vector3(0, 0.58, -0.25)
	instructions_label.text = "[SPACE] Push forward  |  [R] Reset"
	add_child(instructions_label)

	coeff_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	coeff_controller.parameter_name = "mu base"
	coeff_controller.min_value = 0.0
	coeff_controller.max_value = 0.4
	coeff_controller.default_value = base_coefficient
	coeff_controller.step_size = 0.01
	coeff_controller.position = Vector3(-0.45, 0.48, 0.2)
	coeff_controller.rotation_degrees = Vector3(0, 25, 0)
	add_child(coeff_controller)
	coeff_controller.value_changed.connect(_on_coeff_changed)
	coeff_controller.set_value(base_coefficient)

	gravity_controller = PARAMETER_CONTROLLER_SCENE.instantiate()
	gravity_controller.parameter_name = "Gravity"
	gravity_controller.min_value = 0.3
	gravity_controller.max_value = 2.0
	gravity_controller.default_value = gravity_strength
	gravity_controller.step_size = 0.05
	gravity_controller.position = Vector3(0.45, 0.48, 0.2)
	gravity_controller.rotation_degrees = Vector3(0, -25, 0)
	add_child(gravity_controller)
	gravity_controller.value_changed.connect(_on_gravity_changed)
	gravity_controller.set_value(gravity_strength)

func spawn_mover() -> void:
	if is_instance_valid(mover):
		mover.queue_free()

	mover = Mover.new()
	mover.mass = 1.5
	mover.position_v = Vector3(0, 0.0, -0.45)
	mover.velocity = Vector3.ZERO
	mover.bounce_damping = 0.2
	add_child(mover)
	mover.set_size(0.08)
	mover.set_color(Color(1.0, 0.7, 0.9))

	friction_arrow = create_friction_arrow()
	mover.add_child(friction_arrow)

func impulse_forward() -> void:
	if is_instance_valid(mover):
		mover.velocity += Vector3(0, 0, 0.8)

func compute_friction(velocity: Vector3) -> Vector3:
	if velocity.length() < 0.02:
		return Vector3.ZERO

	var normal_force: float = gravity_strength * mover.mass
	var zone_coeff: float = lookup_zone_coefficient(mover.position_v.z)
	var mu: float = base_coefficient + zone_coeff
	var friction_mag: float = mu * normal_force
	return -velocity.normalized() * friction_mag

func lookup_zone_coefficient(z_pos: float) -> float:
	for zone in FLOOR_ZONES:
		var start_z: float = float(zone["start"])
		var end_z: float = float(zone["end"])
		if z_pos >= start_z and z_pos <= end_z:
			return float(zone["coeff"])
	return DEFAULT_COEFF

func create_friction_arrow() -> Node3D:
	var arrow_root := Node3D.new()
	arrow_root.name = "FrictionArrow"

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.005
	shaft_mesh.bottom_radius = 0.005
	shaft_mesh.height = 1.0
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0, -0.5)
	shaft.rotation_degrees = Vector3(90, 0, 0)
	shaft.material_override = create_arrow_material()
	arrow_root.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.02
	head_mesh.height = 0.08
	head.mesh = head_mesh
	head.position = Vector3(0, 0, -1.0)
	head.rotation_degrees = Vector3(90, 0, 0)
	head.material_override = create_arrow_material()
	arrow_root.add_child(head)

	arrow_root.visible = false
	return arrow_root

func create_arrow_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 1.0, 0.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 1.0) * 0.3
	mat.emission_energy_multiplier = 0.5
	return mat

func update_info_label() -> void:
	if info_label and is_instance_valid(mover):
		var speed: float = mover.velocity.length()
		var mu: float = base_coefficient + lookup_zone_coefficient(mover.position_v.z)
		info_label.text = "Example 2.4: Friction\nmu %.2f  |  speed %.2f" % [mu, speed]

func update_friction_arrow(force: Vector3) -> void:
	if not friction_arrow or not is_instance_valid(friction_arrow):
		return

	var magnitude: float = force.length()
	if magnitude < 0.01:
		friction_arrow.visible = false
		return

	friction_arrow.visible = true
	var length: float = clamp(magnitude * 0.4, 0.08, 0.8)

	var shaft := friction_arrow.get_node("Shaft") if friction_arrow.has_node("Shaft") else null
	var head := friction_arrow.get_node("Head") if friction_arrow.has_node("Head") else null

	if shaft and shaft is MeshInstance3D:
		shaft.scale = Vector3(1, 1, length)
		shaft.position = Vector3(0, 0, -length * 0.5)

	if head and head is MeshInstance3D:
		head.position = Vector3(0, 0, -length)
		head.scale = Vector3(1, 1, clamp(length * 0.4, 0.3, 0.9))

	var direction: Vector3 = -mover.velocity.normalized()
	var up_vector := Vector3.UP
	if abs(direction.dot(up_vector)) > 0.95:
		up_vector = Vector3.RIGHT
	var basis := Basis().looking_at(direction, up_vector)
	friction_arrow.transform = Transform3D(basis, Vector3.ZERO)

func reset_scene() -> void:
	gravity_strength = DEFAULT_GRAVITY
	base_coefficient = DEFAULT_COEFF
	if coeff_controller:
		coeff_controller.set_value(base_coefficient)
	if gravity_controller:
		gravity_controller.set_value(gravity_strength)
	spawn_mover()

func _on_coeff_changed(value: float) -> void:
	base_coefficient = value

func _on_gravity_changed(value: float) -> void:
	gravity_strength = value
	if is_instance_valid(mover):
		mover.velocity = Vector3.ZERO

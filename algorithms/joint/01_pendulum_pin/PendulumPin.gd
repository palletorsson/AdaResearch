# @identity
# essence: anchor + pin + bob. One constraint, one body, one degree of freedom.
# desire: To swing and slowly die — the simplest possible joint demo.
# critical_parameter: linear_damp (0.02) — controls how fast the pendulum decays to rest.
# triggers: Automatic — bob is nudged on ready; space key re-impulses.
# emerges: The circular arc of a simple pendulum. The gradual decay as damping bleeds energy.
# needs: Auto-running simulation [has]. Missing: damping slider, trail visualization.
# relationships: Atom of joints sequence. Foundation for ChainSwing (multiple links). Contrasts with DrawbridgeHinge (motor-driven).
# truth: A pendulum is a clock that runs down. The pin joint is the simplest promise: you may rotate, nothing else.

class_name PendulumPinDemo
extends "res://algorithms/joint/shared/joint_demo_base.gd"

var bob: RigidBody3D

# --- Visual additions ---
var _trail_points: Array[Vector3] = []
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _max_trail_length: int = 200
var _info_label: Label3D

const COLOR_ANCHOR := Color(0.95, 0.85, 0.2)
const COLOR_BOB := Color(0.3, 0.75, 1.0)
const COLOR_JOINT := Color(1.0, 0.55, 0.1)
const COLOR_TRAIL := Color(0.3, 0.75, 1.0, 0.3)

func _make_emissive(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	mat.emission_energy_multiplier = energy
	mat.metallic = 0.3
	mat.roughness = 0.4
	return mat

func _build_demo() -> void:
	# --- Anchor (glowing yellow) ---
	var anchor := StaticBody3D.new()
	anchor.name = "Anchor"
	anchor.position = Vector3(0.0, 5.0, 0.0)
	var anchor_shape := CollisionShape3D.new()
	anchor_shape.shape = SphereShape3D.new()
	(anchor_shape.shape as SphereShape3D).radius = 0.2
	anchor.add_child(anchor_shape)
	var anchor_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	anchor_mesh.mesh = sphere
	anchor_mesh.material_override = _make_emissive(COLOR_ANCHOR, 2.0)
	anchor.add_child(anchor_mesh)
	add_child(anchor)

	# --- Bob (emissive blue) ---
	bob = create_sphere("Bob", 0.45, Vector3(0.0, 2.5, 0.0), 2.0, COLOR_BOB)
	bob.linear_damp = 0.02
	bob.angular_damp = 0.02
	var bob_mesh: MeshInstance3D = bob.get_child(1)
	bob_mesh.material_override = _make_emissive(COLOR_BOB, 2.0)

	# --- Pin joint ---
	var joint := PinJoint3D.new()
	joint.name = "PinJoint"
	joint.node_a = anchor.get_path()
	joint.node_b = bob.get_path()
	joint.position = anchor.position
	joint.set_exclude_nodes_from_collision(true)
	add_child(joint)

	# --- Joint marker ---
	var marker := MeshInstance3D.new()
	var marker_sphere := SphereMesh.new()
	marker_sphere.radius = 0.12
	marker_sphere.height = 0.24
	marker.mesh = marker_sphere
	marker.material_override = _make_emissive(COLOR_JOINT, 2.5)
	marker.position = anchor.position
	add_child(marker)

	# --- Connection line (anchor to bob) ---
	var _line_mesh := ImmediateMesh.new()
	var _line_instance := MeshInstance3D.new()
	_line_instance.mesh = _line_mesh
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.7, 0.7, 0.7, 0.6)
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_instance.material_override = line_mat
	add_child(_line_instance)

	# --- Trail ---
	_setup_trail()

	# --- Info label ---
	_info_label = Label3D.new()
	_info_label.font_size = 16
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.modulate = Color(1, 1, 1, 0.8)
	_info_label.position = Vector3(0.0, 6.2, 0.0)
	add_child(_info_label)

	add_label("Pin Joint Pendulum", Vector3(0.0, 6.8, 2.5))
	call_deferred("_nudge")

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = COLOR_TRAIL
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.emission_enabled = true
	trail_mat.emission = Color(COLOR_BOB.r, COLOR_BOB.g, COLOR_BOB.b) * 0.3
	trail_mat.emission_energy_multiplier = 0.8
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_instance.material_override = trail_mat
	add_child(_trail_instance)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		bob.apply_impulse(Vector3.RIGHT * 1.5 + Vector3.FORWARD * 0.8)

	# Update trail
	if is_instance_valid(bob):
		_trail_points.append(bob.global_position)
		if _trail_points.size() > _max_trail_length:
			_trail_points.remove_at(0)
		_update_trail()

		# Update info
		var vel := bob.linear_velocity.length()
		_info_label.text = "vel: %.2f" % vel

func _update_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points:
		_trail_mesh.surface_add_vertex(point)
	_trail_mesh.surface_end()

func _nudge() -> void:
	if is_instance_valid(bob):
		bob.apply_impulse(Vector3(0.6, 0.0, 0.3))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass

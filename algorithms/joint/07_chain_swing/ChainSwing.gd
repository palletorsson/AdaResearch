# @identity
# essence: anchor → pin → link → pin → link → pin → seat. A chain of rigid bodies connected by pin joints, driven by periodic force.
# desire: To swing — to feel how constraints propagate force through a chain, each link amplifying or dampening the one above.
# critical_parameter: link_count and joint damping — more links = longer period, more damping = faster decay.
# triggers: Automatic — seat receives periodic sinusoidal force, arrow keys for manual push.
# emerges: The double-pendulum whip when the chain catches resonance. The trail drawing the seat's arc through space.
# needs: Auto-running simulation [has], periodic drive [has]. Missing: chain length slider, damping control, resonance finder.
# relationships: Simplest chain joint demo. Foundation for CharacterRagdoll (branching chains). Contrasts with PendulumPin (single link).
# truth: A chain swing is a conversation between gravity and constraint. Each link votes on where the seat should go.

class_name ChainSwingDemo
extends "res://algorithms/joint/shared/joint_demo_base.gd"

var seat: RigidBody3D
var _t := 0.0

# --- Visual additions ---
var _trail_points: Array[Vector3] = []
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _max_trail_length: int = 200
var _joint_markers: Array[MeshInstance3D] = []
var _info_label: Label3D

# Colors
const COLOR_FRAME := Color(0.35, 0.38, 0.45)
const COLOR_LINK := Color(0.6, 0.85, 0.95)
const COLOR_SEAT := Color(0.2, 0.9, 0.85)
const COLOR_JOINT := Color(1.0, 0.55, 0.1)
const COLOR_TRAIL := Color(0.2, 0.9, 0.85, 0.3)

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
	# --- Structure (frame) ---
	var frame_left := create_static_box("FrameLeft", Vector3(0.4, 4.0, 0.4), Vector3(-2.0, 3.0, -1.5), COLOR_FRAME)
	var frame_right := create_static_box("FrameRight", Vector3(0.4, 4.0, 0.4), Vector3(2.0, 3.0, -1.5), COLOR_FRAME)
	var beam := create_static_box("TopBeam", Vector3(4.5, 0.4, 0.4), Vector3(0.0, 5.0, -1.5), COLOR_FRAME)

	# Add subtle emission to frame
	for body in [frame_left, frame_right, beam]:
		var mesh: MeshInstance3D = body.get_child(1)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLOR_FRAME
		mat.emission_enabled = true
		mat.emission = COLOR_FRAME * 0.15
		mat.emission_energy_multiplier = 0.5
		mat.roughness = 0.6
		mesh.material_override = mat

	# --- Anchor ---
	var anchor := StaticBody3D.new()
	anchor.name = "SwingAnchor"
	anchor.position = Vector3(0.0, 4.7, -1.5)
	add_child(anchor)

	# --- Links (emissive) ---
	var link_top := create_cylinder("LinkTop", 0.08, 1.0, Vector3(0.0, 3.9, -1.5), 0.5, COLOR_LINK)
	link_top.angular_damp = 0.1
	var link_top_mesh: MeshInstance3D = link_top.get_child(1)
	link_top_mesh.material_override = _make_emissive(COLOR_LINK, 1.0)

	var link_bottom := create_cylinder("LinkBottom", 0.08, 1.0, Vector3(0.0, 2.9, -1.5), 0.5, COLOR_LINK)
	var link_bottom_mesh: MeshInstance3D = link_bottom.get_child(1)
	link_bottom_mesh.material_override = _make_emissive(COLOR_LINK, 1.0)

	# --- Seat (bright emissive mover) ---
	seat = create_box("Seat", Vector3(1.2, 0.2, 0.6), Vector3(0.0, 2.2, -1.5), 1.2, COLOR_SEAT)
	seat.linear_damp = 0.05
	var seat_mesh: MeshInstance3D = seat.get_child(1)
	seat_mesh.material_override = _make_emissive(COLOR_SEAT, 2.0)

	# --- Joints ---
	var joint_positions: Array[Vector3] = []

	var joint_top := PinJoint3D.new()
	joint_top.node_a = anchor.get_path()
	joint_top.node_b = link_top.get_path()
	joint_top.position = anchor.position
	joint_top.set_exclude_nodes_from_collision(true)
	add_child(joint_top)
	joint_positions.append(anchor.position)

	var joint_mid := PinJoint3D.new()
	joint_mid.node_a = link_top.get_path()
	joint_mid.node_b = link_bottom.get_path()
	joint_mid.position = Vector3(0.0, 3.4, -1.5)
	joint_mid.set_exclude_nodes_from_collision(true)
	add_child(joint_mid)
	joint_positions.append(Vector3(0.0, 3.4, -1.5))

	var joint_bottom := PinJoint3D.new()
	joint_bottom.node_a = link_bottom.get_path()
	joint_bottom.node_b = seat.get_path()
	joint_bottom.position = Vector3(0.0, 2.5, -1.5)
	joint_bottom.set_exclude_nodes_from_collision(true)
	add_child(joint_bottom)
	joint_positions.append(Vector3(0.0, 2.5, -1.5))

	# --- Joint markers (glowing spheres at constraint points) ---
	for pos in joint_positions:
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		marker.mesh = sphere
		marker.material_override = _make_emissive(COLOR_JOINT, 2.5)
		marker.position = pos
		add_child(marker)
		_joint_markers.append(marker)

	# --- Trail (seat motion history) ---
	_setup_trail()

	# --- Info label ---
	_info_label = Label3D.new()
	_info_label.font_size = 16
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.modulate = Color(1, 1, 1, 0.8)
	_info_label.position = Vector3(0.0, 6.0, -1.5)
	add_child(_info_label)

	add_label("Chain Swing", Vector3(0.0, 6.8, -3.5))

	call_deferred("_nudge")

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = COLOR_TRAIL
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.emission_enabled = true
	trail_mat.emission = Color(COLOR_SEAT.r, COLOR_SEAT.g, COLOR_SEAT.b) * 0.3
	trail_mat.emission_energy_multiplier = 0.8
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_instance.material_override = trail_mat
	add_child(_trail_instance)

func _process(delta: float) -> void:
	_t += delta
	if Input.is_action_pressed("ui_right"):
		seat.apply_central_force(Vector3(5.0, 0.0, 0.0))
	elif Input.is_action_pressed("ui_left"):
		seat.apply_central_force(Vector3(-5.0, 0.0, 0.0))
	else:
		var f := sin(_t * 1.2) * 2.2
		seat.apply_central_force(Vector3(f, 0.0, 0.0))

	# Update trail
	if is_instance_valid(seat):
		_trail_points.append(seat.global_position)
		if _trail_points.size() > _max_trail_length:
			_trail_points.remove_at(0)
		_update_trail()

		# Update info label
		var vel := seat.linear_velocity.length()
		var swing_x := seat.position.x
		_info_label.text = "vel: %.2f  x: %.2f" % [vel, swing_x]

func _update_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points:
		_trail_mesh.surface_add_vertex(point)
	_trail_mesh.surface_end()

func _nudge() -> void:
	if is_instance_valid(seat):
		seat.apply_impulse(Vector3(0.8, 0.0, 0.0))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass

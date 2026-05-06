# @identity
# essence: hinge joint + motor + angular limit. One axis of rotation, motorized.
# desire: To lift and lower — the drawbridge makes the hinge joint visible as architecture.
# critical_parameter: motor target_velocity and angular limit (-85°) — speed of lift and range of motion.
# triggers: Arrow keys control motor velocity; idle mode oscillates gently.
# emerges: The satisfying mechanical motion of a bridge rising and falling on command.
# needs: Motor control [has], idle oscillation [has]. Missing: weight on bridge, chain visualization.
# relationships: Pure hinge demo. Contrasts with HingeCrank (hinge as part of mechanism). Pairs with GimbalStabilizer (two hinges composed).
# truth: A hinge is the most intuitive constraint. Everything else is locked; one axis is free. Doors, bridges, jaws.

extends "res://algorithms/joint/shared/joint_demo_base.gd"
class_name DrawbridgeHingeDemo

# --- colors ---
const COLOR_TOWER  := Color(0.72, 0.60, 0.44)   # warm sandstone
const COLOR_BRIDGE := Color(0.20, 0.80, 0.85)   # cyan
const COLOR_HINGE  := Color(1.00, 0.55, 0.10)   # orange

# --- trail ---
const TRAIL_MAX := 200

var hinge: HingeJoint3D
var _bridge: RigidBody3D

# trail
var _trail_mesh:    MeshInstance3D
var _trail_im:      ImmediateMesh
var _trail_pts:     PackedVector3Array

# hinge marker
var _hinge_marker: MeshInstance3D

# info label
var _info_label: Label3D

# ─────────────────────────────────────────────
func _make_emissive(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	mat.emission_energy_multiplier = energy
	mat.metallic = 0.3
	mat.roughness = 0.4
	return mat

# ─────────────────────────────────────────────
func _build_demo() -> void:
	# 2. CONTAINMENT — tower as stone frame
	var tower := create_static_box("Tower", Vector3(4.0, 6.0, 2.0), Vector3(-2.0, 3.0, 0.0), COLOR_TOWER)
	tower.get_child(1).material_override = _make_emissive(COLOR_TOWER, 0.6)

	# 1. VISIBILITY — bridge, clearly lit
	_bridge = create_box("Bridge", Vector3(6.0, 0.4, 3.0), Vector3(1.5, 1.0, 0.0), 12.0, COLOR_BRIDGE)
	_bridge.get_child(1).material_override = _make_emissive(COLOR_BRIDGE, 1.8)

	# joint
	hinge = HingeJoint3D.new()
	hinge.name = "BridgeHinge"
	hinge.node_a = tower.get_path()
	hinge.node_b = _bridge.get_path()
	hinge.position = Vector3(-1.0, 1.8, 0.0)
	hinge.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-85.0))
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)
	hinge.set_exclude_nodes_from_collision(true)
	add_child(hinge)

	# 4. CONNECTIONS — glowing hinge marker sphere
	var hinge_body := MeshInstance3D.new()
	hinge_body.name = "HingeMarker"
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.28
	sphere_mesh.height = 0.56
	hinge_body.mesh = sphere_mesh
	hinge_body.position = hinge.position
	hinge_body.material_override = _make_emissive(COLOR_HINGE, 3.0)
	add_child(hinge_body)
	_hinge_marker = hinge_body

	# 3. TRAILS — ImmediateMesh arc on the bridge's far edge
	_trail_im = ImmediateMesh.new()
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "BridgeTrail"
	_trail_mesh.mesh = _trail_im
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = COLOR_BRIDGE
	trail_mat.emission_enabled = true
	trail_mat.emission = COLOR_BRIDGE * 0.6
	trail_mat.emission_energy_multiplier = 1.2
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_mat.vertex_color_use_as_albedo = true
	_trail_mesh.material_override = trail_mat
	add_child(_trail_mesh)

	# 7. INFORMATION — angle label near hinge
	_info_label = Label3D.new()
	_info_label.name = "AngleLabel"
	_info_label.font_size = 18
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.modulate = COLOR_HINGE
	_info_label.position = hinge.position + Vector3(0.0, 1.2, 0.0)
	_info_label.text = "0°"
	add_child(_info_label)

	add_label("Motorised Drawbridge", Vector3(0.0, 4.0, 3.5))

	call_deferred("_center_and_oscillate")

# ─────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	var velocity := 0.0
	if Input.is_action_pressed("ui_up"):
		velocity = 1.2
	elif Input.is_action_pressed("ui_down"):
		velocity = -1.2
	else:
		var t := Time.get_ticks_msec() * 0.001
		velocity = 0.4 * sin(t * 0.8)
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, velocity)

	# --- update trail ---
	if is_instance_valid(_bridge):
		# sample the far outer edge of the bridge (positive-X end, centre-Z)
		var local_tip := Vector3(3.2, 0.0, 0.0)
		var world_tip := _bridge.global_transform * local_tip
		_trail_pts.append(world_tip)
		if _trail_pts.size() > TRAIL_MAX:
			_trail_pts.remove_at(0)
		_rebuild_trail()

		# --- update info label ---
		if is_instance_valid(_info_label):
			var angle_deg := rad_to_deg(hinge.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY))
			# Display actual bridge rotation relative to global Y-axis (readable approximation)
			var bridge_angle := rad_to_deg(_bridge.rotation.z)
			_info_label.text = "%.0f°  |  vel %.1f" % [bridge_angle, velocity]

# ─────────────────────────────────────────────
func _rebuild_trail() -> void:
	_trail_im.clear_surfaces()
	if _trail_pts.size() < 2:
		return
	_trail_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var n := _trail_pts.size()
	for i in n:
		var alpha := float(i) / float(n - 1)
		_trail_im.surface_set_color(Color(COLOR_BRIDGE.r, COLOR_BRIDGE.g, COLOR_BRIDGE.b, alpha))
		_trail_im.surface_add_vertex(_trail_pts[i])
	_trail_im.surface_end()

# ─────────────────────────────────────────────
func _center_and_oscillate() -> void:
	if is_instance_valid(hinge):
		pass

func apply_grid_config(config: Dictionary) -> void:
	pass

# @identity
# essence: cone-twist joint — ball-and-socket with angular limits. Swing span 45°, twist span 15°.
# desire: To swing within a cone and twist within a narrower one — angular freedom with boundaries.
# critical_parameter: swing_span (45°) and twist_span (15°) — the cone's opening angle and axial rotation limit.
# triggers: Space key applies impulse; bag swings within cone boundary.
# emerges: Pendular motion confined to an invisible cone. The bag never escapes its angular prison.
# needs: Impulse interaction [has]. Missing: cone visualization, span sliders.
# relationships: Same joint type as CharacterRagdoll (hip). Contrasts with PendulumPin (unconstrained swing). Pairs with GimbalStabilizer (angular control).
# truth: A cone-twist joint draws an invisible boundary in angle-space. The bag knows where it cannot go.

extends "res://algorithms/joint/shared/joint_demo_base.gd"
class_name ConeTwistBagDemo

# --- Colors ---
const COLOR_BAG    := Color(1.0,  0.55, 0.05)   # warm orange
const COLOR_ANCHOR := Color(1.0,  0.92, 0.15)   # yellow
const COLOR_JOINT  := Color(1.0,  0.45, 0.05)   # orange joint marker
const COLOR_BEAM   := Color(0.35, 0.35, 0.40)

# --- Refs ---
var bag: RigidBody3D
var _joint_marker: MeshInstance3D
var _trail_mesh: MeshInstance3D
var _trail_imm: ImmediateMesh
var _trail_points: Array[Vector3] = []
const TRAIL_MAX := 200

# --- Info label ---
var _info_label: Label3D

# ── helpers ────────────────────────────────────────────────────────────────

func _make_emissive(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	mat.emission_energy_multiplier = energy
	mat.metallic = 0.3
	mat.roughness = 0.4
	return mat

func _make_emissive_transparent(color: Color, alpha: float = 0.6, energy: float = 1.2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color * 0.4
	mat.emission_energy_multiplier = energy
	mat.metallic = 0.0
	mat.roughness = 0.6
	return mat

# ── build ───────────────────────────────────────────────────────────────────

func _build_demo() -> void:
	# 1. Beam (static overhead support)
	var beam := create_static_box("Beam", Vector3(6.0, 0.3, 0.5), Vector3(0.0, 5.0, 0.0), COLOR_BEAM)
	# Override beam material with mild glow
	var beam_mesh: MeshInstance3D = beam.get_child(1)
	beam_mesh.material_override = _make_emissive(COLOR_BEAM, 0.6)

	# 2. Invisible anchor body (cone-twist pivot)
	var anchor := StaticBody3D.new()
	anchor.name = "BagAnchor"
	anchor.position = Vector3(0.0, 4.6, 0.0)
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	(shape.shape as SphereShape3D).radius = 0.15
	anchor.add_child(shape)
	add_child(anchor)

	# 3. Glowing anchor sphere (CONNECTIONS — item 4)
	var anchor_sphere := MeshInstance3D.new()
	anchor_sphere.name = "AnchorGlow"
	var sph_mesh := SphereMesh.new()
	sph_mesh.radius = 0.14
	sph_mesh.height = 0.28
	anchor_sphere.mesh = sph_mesh
	anchor_sphere.material_override = _make_emissive(COLOR_ANCHOR, 2.0)
	anchor.add_child(anchor_sphere)

	# 4. The bag (warm orange, emissive — items 5 & 6)
	bag = create_cylinder("PunchBag", 0.4, 1.4, Vector3(0.0, 2.5, 0.0), 3.5, COLOR_BAG)
	bag.linear_damp = 0.05
	bag.angular_damp = 0.1
	# Override the mesh material created by create_cylinder
	var bag_mesh: MeshInstance3D = bag.get_child(1)
	bag_mesh.material_override = _make_emissive(COLOR_BAG, 1.8)

	# 5. Small glowing joint-position marker sphere (CONNECTIONS — item 4)
	_joint_marker = MeshInstance3D.new()
	_joint_marker.name = "JointMarker"
	var jm_mesh := SphereMesh.new()
	jm_mesh.radius = 0.08
	jm_mesh.height = 0.16
	_joint_marker.mesh = jm_mesh
	_joint_marker.material_override = _make_emissive(COLOR_JOINT, 2.5)
	add_child(_joint_marker)

	# 6. Cone-twist joint (physics)
	var joint := ConeTwistJoint3D.new()
	joint.name = "BagJoint"
	joint.node_a = anchor.get_path()
	joint.node_b = bag.get_path()
	joint.position = anchor.position
	joint.swing_span = deg_to_rad(45.0)
	joint.twist_span = deg_to_rad(15.0)
	joint.bias = 0.3
	joint.softness = 0.8
	joint.relaxation = 1.0
	joint.set_exclude_nodes_from_collision(true)
	add_child(joint)

	# 7. Trail ImmediateMesh (TRAILS — item 3)
	_trail_imm = ImmediateMesh.new()
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "BagTrail"
	_trail_mesh.mesh = _trail_imm
	_trail_mesh.material_override = _make_emissive_transparent(COLOR_BAG, 0.55, 1.4)
	add_child(_trail_mesh)

	# 8. Title label (existing)
	add_label("Cone Twist Punching Bag", Vector3(0.0, 4.0, 2.8))

	# 9. Dynamic info label (INFORMATION — item 7)
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 18
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.modulate = Color(1.0, 0.9, 0.6, 0.95)
	_info_label.position = Vector3(2.2, 3.0, 0.0)
	add_child(_info_label)

	# Nudge to set it in motion
	call_deferred("_nudge")

# ── per-frame ───────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		bag.apply_impulse((Vector3.FORWARD + Vector3.RIGHT) * 4.0)

	if not is_instance_valid(bag):
		return

	_update_trail()
	_update_joint_marker()
	_update_info_label()

func _update_trail() -> void:
	# Sample the bottom-center of the bag
	var bottom := bag.global_position + Vector3(0.0, -0.7, 0.0)
	_trail_points.push_back(bottom)
	if _trail_points.size() > TRAIL_MAX:
		_trail_points.pop_front()

	_trail_imm.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in _trail_points.size():
		var t := float(i) / float(_trail_points.size() - 1)
		_trail_imm.surface_set_color(Color(1.0, 0.55, 0.05, t * 0.8))
		_trail_imm.surface_add_vertex(_trail_points[i])
	_trail_imm.surface_end()

func _update_joint_marker() -> void:
	# Keep the joint marker floating at the anchor position
	_joint_marker.global_position = Vector3(0.0, 4.6, 0.0)

func _update_info_label() -> void:
	var vel := bag.linear_velocity
	var speed := snappedf(vel.length(), 0.01)
	# Swing angle: angle between bag's up-vector and world up
	var bag_up  := bag.global_transform.basis.y.normalized()
	var swing_deg := snappedf(rad_to_deg(acos(clamp(bag_up.dot(Vector3.UP), -1.0, 1.0))), 0.1)
	_info_label.text = "speed: %.2f m/s\nswing: %.1f°" % [speed, swing_deg]

# ── helpers ──────────────────────────────────────────────────────────────────

func _nudge() -> void:
	if is_instance_valid(bag):
		bag.apply_impulse(Vector3(1.0, 0.0, 1.2))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass

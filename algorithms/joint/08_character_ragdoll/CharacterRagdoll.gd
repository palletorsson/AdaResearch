# @identity
# essence: torso + leg + cone-twist hip. The minimal ragdoll — one joint, two bodies, biomechanical limits.
# desire: To look alive while being purely mechanical. The cone-twist hip makes the leg swing like a leg.
# critical_parameter: swing_span (35°) and twist_span (25°) — mimicking human hip range of motion.
# triggers: Space key impulses the leg; cone-twist channels the force into naturalistic swing.
# emerges: Ragdoll-like motion from a single constrained joint. The illusion of intent from pure physics.
# needs: Hip impulse [has]. Missing: more limbs, full ragdoll chain, grab interaction.
# relationships: Seed of character physics. Uses same joint as ConeTwistBag. Foundation for full ragdoll systems.
# truth: A body built from constraints begins to look like it has intention. That is the uncanny valley of physics.

class_name CharacterRagdollDemo
extends "res://algorithms/joint/shared/joint_demo_base.gd"

var leg: RigidBody3D

# --- Visual additions ---
var _trail_points: Array[Vector3] = []
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _max_trail_length: int = 200
var _info_label: Label3D

const COLOR_TORSO := Color(0.25, 0.65, 0.55)
const COLOR_LEG := Color(0.85, 0.35, 0.35)
const COLOR_JOINT := Color(1.0, 0.55, 0.1)
const COLOR_TRAIL := Color(0.85, 0.35, 0.35, 0.3)

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
	# --- Torso (emissive teal) ---
	var torso := create_box("Torso", Vector3(1.0, 2.0, 0.5), Vector3(0.0, 4.0, 0.0), 6.0, COLOR_TORSO)
	var torso_mesh: MeshInstance3D = torso.get_child(1)
	torso_mesh.material_override = _make_emissive(COLOR_TORSO, 1.0)

	# --- Leg (emissive red) ---
	leg = create_box("Leg", Vector3(0.6, 2.0, 0.5), Vector3(0.0, 1.8, 0.0), 4.0, COLOR_LEG)
	var leg_mesh: MeshInstance3D = leg.get_child(1)
	leg_mesh.material_override = _make_emissive(COLOR_LEG, 1.8)

	# --- Hip joint ---
	var joint := ConeTwistJoint3D.new()
	joint.name = "HipJoint"
	joint.node_a = torso.get_path()
	joint.node_b = leg.get_path()
	joint.position = Vector3(0.0, 3.0, 0.0)
	joint.swing_span = deg_to_rad(35.0)
	joint.twist_span = deg_to_rad(25.0)
	joint.bias = 0.3
	joint.softness = 0.8
	joint.relaxation = 1.0
	joint.set_exclude_nodes_from_collision(true)
	add_child(joint)

	# --- Joint marker (hip) ---
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.30
	marker.mesh = sphere
	marker.material_override = _make_emissive(COLOR_JOINT, 2.5)
	marker.position = Vector3(0.0, 3.0, 0.0)
	add_child(marker)

	# --- Trail (leg foot position) ---
	_setup_trail()

	# --- Info label ---
	_info_label = Label3D.new()
	_info_label.font_size = 16
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.modulate = Color(1, 1, 1, 0.8)
	_info_label.position = Vector3(0.0, 6.0, 0.0)
	add_child(_info_label)

	add_label("Character Joint Hip", Vector3(0.0, 6.6, 2.5))

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = COLOR_TRAIL
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.emission_enabled = true
	trail_mat.emission = Color(COLOR_LEG.r, COLOR_LEG.g, COLOR_LEG.b) * 0.3
	trail_mat.emission_energy_multiplier = 0.8
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_instance.material_override = trail_mat
	add_child(_trail_instance)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		leg.apply_impulse(Vector3(2.0, 0.0, 1.5))

	if is_instance_valid(leg):
		# Track the foot (bottom of leg)
		var foot := leg.global_position + Vector3(0.0, -1.0, 0.0)
		_trail_points.append(foot)
		if _trail_points.size() > _max_trail_length:
			_trail_points.remove_at(0)
		_update_trail()

		var vel := leg.linear_velocity.length()
		_info_label.text = "vel: %.2f" % vel

func _update_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points:
		_trail_mesh.surface_add_vertex(point)
	_trail_mesh.surface_end()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass

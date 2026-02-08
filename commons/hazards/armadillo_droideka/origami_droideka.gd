extends "res://commons/hazards/armadillo_droideka/armadillo_droideka.gd"
class_name OrigamiDroideka

@export_group("Origami Inflation")
@export var inflation_enabled: bool = true
@export var inflation_speed: float = 0.12
@export var inflation_amplitude: float = 0.12
@export var inflation_min_scale: float = 0.72
@export var inflation_fire_bias: float = 0.28
@export var inflated_radius_scale: float = 1.24
@export var deflated_radius_scale: float = 0.56
@export var inflated_thickness_scale: float = 0.74
@export var deflated_thickness_scale: float = 0.20
@export var pleat_fold_degrees: float = 68.0
@export var pleat_twist_degrees: float = 34.0
@export var aperture_open_scale: float = 1.0
@export var aperture_closed_scale: float = 0.34
@export var outer_collar_closed_scale: float = 0.78
@export var split_faces_enabled: bool = true
@export var split_closed_dihedral_degrees: float = 56.0
@export var split_open_dihedral_degrees: float = 4.0
@export var split_jitter_degrees: float = 3.2

var _inner_ring_top: MeshInstance3D = null
var _inner_ring_bottom: MeshInstance3D = null
var _outer_ring_top: MeshInstance3D = null
var _outer_ring_bottom: MeshInstance3D = null
var _split_left_hinges: Array[Node3D] = []
var _split_right_hinges: Array[Node3D] = []

func _ready() -> void:
	max_health = 92.0
	roll_speed = 2.55
	strafe_speed = 1.95
	turn_speed = 6.4
	detection_radius = 11.5
	disengage_radius = 17.0
	shots_per_burst = 4
	fire_interval = 0.31
	fire_speed = 15.5
	fire_damage = 16.0
	contact_damage = 10.0
	contact_damage_cooldown = 0.58

	# 16-20 radial pleats approximates the wheel shown in your reference.
	scute_count = 18
	shell_radius = 0.66
	shell_height = 0.96
	shell_thickness = 0.06
	scute_open_degrees = 84.0
	scute_wave_degrees = 14.0
	ring_open_degrees = 64.0
	core_raise_height = 0.58

	super._ready()
	add_to_group("origami_enemy")

func _build_visual_rig() -> void:
	var shell_material: StandardMaterial3D = _make_material(
		Color(0.60, 0.90, 0.82, 1.0),
		Color(0.08, 0.28, 0.24, 1.0),
		0.12,
		0.62
	)
	var ring_material: StandardMaterial3D = _make_material(
		Color(0.68, 0.84, 0.78, 1.0),
		Color(0.96, 0.43, 0.14, 1.0),
		0.34,
		0.44
	)
	var core_material: StandardMaterial3D = _make_material(
		Color(0.17, 0.17, 0.2, 1.0),
		Color(1.0, 0.33, 0.08, 1.0),
		0.35,
		0.55
	)

	_shell_root = Node3D.new()
	_shell_root.name = "ShellRoot"
	add_child(_shell_root)

	_create_scutes(shell_material)
	_create_equator_rings(ring_material)
	_create_leg_modules(ring_material)
	_create_core(core_material, ring_material)

func _create_scutes(shell_material: Material) -> void:
	_scute_hinges.clear()
	_split_left_hinges.clear()
	_split_right_hinges.clear()
	var count: int = max(14, scute_count)
	var rib_material: StandardMaterial3D = _make_material(
		Color(0.95, 0.96, 0.92, 1.0),
		Color(0.35, 0.37, 0.30, 1.0),
		0.06,
		0.45
	)

	var inner_mesh: BoxMesh = BoxMesh.new()
	inner_mesh.size = Vector3(shell_radius * 0.54, shell_thickness * 0.40, shell_thickness * 1.45)

	var outer_mesh: BoxMesh = BoxMesh.new()
	outer_mesh.size = Vector3(shell_radius * 0.86, shell_thickness * 0.45, shell_thickness * 1.58)

	var rib_mesh: BoxMesh = BoxMesh.new()
	rib_mesh.size = Vector3(shell_radius * 0.80, shell_thickness * 0.09, shell_thickness * 1.66)
	var split_mesh: BoxMesh = BoxMesh.new()
	split_mesh.size = Vector3(shell_radius * 0.86, shell_thickness * 0.45, shell_thickness * 0.80)

	for i in range(count):
		var orbit: Node3D = Node3D.new()
		orbit.name = "ScuteOrbit_%d" % i
		orbit.rotation_degrees.z = 360.0 * float(i) / float(count)
		_shell_root.add_child(orbit)

		var hinge: Node3D = Node3D.new()
		hinge.name = "ScuteHinge_%d" % i
		orbit.add_child(hinge)

		var inner_panel: MeshInstance3D = MeshInstance3D.new()
		inner_panel.name = "OrigamiInnerPanel"
		inner_panel.mesh = inner_mesh
		inner_panel.material_override = shell_material
		inner_panel.position = Vector3(shell_radius * 0.23, 0.0, 0.0)
		inner_panel.rotation_degrees.z = -3.0
		hinge.add_child(inner_panel)

		if split_faces_enabled:
			var split_root: Node3D = Node3D.new()
			split_root.name = "SplitFaceRoot"
			split_root.position = Vector3(shell_radius * 0.68, 0.0, 0.0)
			split_root.rotation_degrees.z = 2.0
			hinge.add_child(split_root)

			var left_hinge: Node3D = Node3D.new()
			left_hinge.name = "SplitLeftHinge"
			split_root.add_child(left_hinge)

			var right_hinge: Node3D = Node3D.new()
			right_hinge.name = "SplitRightHinge"
			split_root.add_child(right_hinge)

			var left_panel: MeshInstance3D = MeshInstance3D.new()
			left_panel.name = "OrigamiOuterPanelLeft"
			left_panel.mesh = split_mesh
			left_panel.material_override = shell_material
			left_panel.position = Vector3(0.0, 0.0, -split_mesh.size.z * 0.5)
			left_hinge.add_child(left_panel)

			var right_panel: MeshInstance3D = MeshInstance3D.new()
			right_panel.name = "OrigamiOuterPanelRight"
			right_panel.mesh = split_mesh
			right_panel.material_override = shell_material
			right_panel.position = Vector3(0.0, 0.0, split_mesh.size.z * 0.5)
			right_hinge.add_child(right_panel)

			var seam_rib: MeshInstance3D = MeshInstance3D.new()
			seam_rib.name = "OrigamiSeamRib"
			var seam_mesh: BoxMesh = BoxMesh.new()
			seam_mesh.size = Vector3(shell_radius * 0.88, shell_thickness * 0.10, shell_thickness * 0.18)
			seam_rib.mesh = seam_mesh
			seam_rib.material_override = rib_material
			split_root.add_child(seam_rib)

			_split_left_hinges.append(left_hinge)
			_split_right_hinges.append(right_hinge)
		else:
			var outer_panel: MeshInstance3D = MeshInstance3D.new()
			outer_panel.name = "OrigamiOuterPanel"
			outer_panel.mesh = outer_mesh
			outer_panel.material_override = shell_material
			outer_panel.position = Vector3(shell_radius * 0.68, 0.0, 0.0)
			outer_panel.rotation_degrees.z = 2.0
			hinge.add_child(outer_panel)

		var rib: MeshInstance3D = MeshInstance3D.new()
		rib.name = "OrigamiRib"
		rib.mesh = rib_mesh
		rib.material_override = rib_material
		rib.position = Vector3(shell_radius * 0.62, shell_thickness * 0.15, shell_thickness * 0.03)
		hinge.add_child(rib)

		_scute_hinges.append(hinge)

func _create_equator_rings(material: Material) -> void:
	_equator_upper = Node3D.new()
	_equator_upper.name = "EquatorUpper"
	_shell_root.add_child(_equator_upper)

	_equator_lower = Node3D.new()
	_equator_lower.name = "EquatorLower"
	_shell_root.add_child(_equator_lower)

	# Inner aperture ring (hole seen in the wheel reference).
	_inner_ring_top = _create_torus_ring(shell_radius * 0.21, shell_thickness * 0.42, material)
	_inner_ring_bottom = _create_torus_ring(shell_radius * 0.21, shell_thickness * 0.42, material)
	_inner_ring_top.rotation_degrees.x = 90.0
	_inner_ring_bottom.rotation_degrees.x = 90.0
	_equator_upper.add_child(_inner_ring_top)
	_equator_lower.add_child(_inner_ring_bottom)
	_inner_ring_top.position.z = shell_thickness * 0.42
	_inner_ring_bottom.position.z = -shell_thickness * 0.42

	# Outer collar ring to frame pleat ends.
	_outer_ring_top = _create_torus_ring(shell_radius * 0.94, shell_thickness * 0.22, material)
	_outer_ring_bottom = _create_torus_ring(shell_radius * 0.94, shell_thickness * 0.22, material)
	_outer_ring_top.rotation_degrees.x = 90.0
	_outer_ring_bottom.rotation_degrees.x = 90.0
	_equator_upper.add_child(_outer_ring_top)
	_equator_lower.add_child(_outer_ring_bottom)
	_outer_ring_top.position.z = shell_thickness * 0.72
	_outer_ring_bottom.position.z = -shell_thickness * 0.72

func _apply_fold_pose(fold: float) -> void:
	super._apply_fold_pose(fold)

	if _shell_root == null:
		return

	var fold_clamped: float = clamp(fold, 0.0, 1.0)
	var roll_bias: float = 1.0 - fold_clamped
	var planar_speed: float = Vector2(velocity.x, velocity.z).length()
	var speed_ratio: float = clamp(planar_speed / max(roll_speed, 0.01), 0.0, 1.6)
	var load: float = clamp(speed_ratio * 0.16, 0.0, 0.22) * roll_bias

	var target_inflate: float = clamp((1.0 - fold_clamped) * 0.75 + 0.2, 0.0, 1.0)
	match _state:
		State.ROLL:
			target_inflate = max(target_inflate, 0.82)
		State.DETECT:
			target_inflate = clamp(target_inflate, 0.55, 0.72)
		State.DEPLOY:
			target_inflate = clamp(target_inflate, 0.42, 0.66)
		State.AIM, State.FIRE:
			target_inflate = clamp(inflation_fire_bias, 0.05, 0.75)
		State.DEAD:
			target_inflate = 0.12
		_:
			pass

	var pulse: float = 0.0
	if inflation_enabled:
		var phase_speed: float = max(0.02, inflation_speed)
		var raw_pulse: float = sin(_state_time * TAU * phase_speed)
		var pulse_weight: float = clamp(0.35 + roll_bias * 0.65, 0.0, 1.0)
		pulse = raw_pulse * inflation_amplitude * pulse_weight

	var inflate: float = clamp(target_inflate + pulse - load * 0.20, 0.02, 1.0)

	# Inflate/deflate profile: wheel expands radially while thickness collapses/expands.
	var radius_scale: float = lerp(deflated_radius_scale, inflated_radius_scale, inflate)
	var thickness_scale: float = lerp(deflated_thickness_scale, inflated_thickness_scale, inflate)
	radius_scale += load * 0.18
	thickness_scale -= load * 0.22
	thickness_scale = max(inflation_min_scale * 0.25, thickness_scale)
	_shell_root.scale = Vector3(radius_scale, radius_scale, thickness_scale)

	# Offset rings so the center aperture remains visible through compression.
	if _equator_upper:
		_equator_upper.position.z = shell_thickness * (0.42 + (1.0 - inflate) * 0.44)
		_equator_upper.rotation_degrees.x = -lerp(4.0, 24.0, 1.0 - inflate)
	if _equator_lower:
		_equator_lower.position.z = -shell_thickness * (0.42 + (1.0 - inflate) * 0.44)
		_equator_lower.rotation_degrees.x = lerp(4.0, 24.0, 1.0 - inflate)

	var aperture_scale: float = lerp(aperture_closed_scale, aperture_open_scale, inflate)
	if _inner_ring_top:
		_inner_ring_top.scale.x = aperture_scale
		_inner_ring_top.scale.y = aperture_scale
	if _inner_ring_bottom:
		_inner_ring_bottom.scale.x = aperture_scale
		_inner_ring_bottom.scale.y = aperture_scale

	var collar_scale: float = lerp(outer_collar_closed_scale, 1.0, inflate)
	if _outer_ring_top:
		_outer_ring_top.scale.x = collar_scale
		_outer_ring_top.scale.y = collar_scale
	if _outer_ring_bottom:
		_outer_ring_bottom.scale.x = collar_scale
		_outer_ring_bottom.scale.y = collar_scale

	var scute_total: int = _scute_hinges.size()
	for i in range(scute_total):
		var hinge: Node3D = _scute_hinges[i]
		var phase: float = TAU * float(i) / float(max(scute_total, 1))
		var parity: float = 1.0 if (i % 2 == 0) else -1.0
		var accordion: float = lerp(pleat_fold_degrees, 4.0, inflate)
		var twist: float = lerp(pleat_twist_degrees, 6.0, inflate)
		var micro_wave: float = sin(_state_time * 0.8 + phase * 2.0) * 1.9 * (1.0 - inflate)

		hinge.rotation_degrees.y = parity * (accordion + micro_wave)
		hinge.rotation_degrees.x = parity * twist * 0.5
		hinge.rotation_degrees.z = sin(phase + _state_time * 0.21) * (3.5 * (1.0 - inflate))

		var radial_length_scale: float = lerp(0.38, 1.08, inflate)
		var width_scale: float = lerp(0.80, 1.0, inflate)
		var panel_thickness_scale: float = lerp(0.68, 1.0, inflate)
		var split_dihedral: float = lerp(split_closed_dihedral_degrees, split_open_dihedral_degrees, inflate)
		var split_jitter: float = sin(_state_time * 0.52 + phase * 3.0) * split_jitter_degrees * (1.0 - inflate)

		if i < _split_left_hinges.size() and i < _split_right_hinges.size():
			_split_left_hinges[i].rotation_degrees.x = -0.5 * (split_dihedral + split_jitter)
			_split_right_hinges[i].rotation_degrees.x = 0.5 * (split_dihedral + split_jitter)

		for child in hinge.get_children():
			if child is MeshInstance3D:
				var mesh_child: MeshInstance3D = child as MeshInstance3D
				mesh_child.scale.x = radial_length_scale
				mesh_child.scale.y = width_scale
				mesh_child.scale.z = panel_thickness_scale
			elif child is Node3D:
				var node_child: Node3D = child as Node3D
				for grandchild in node_child.get_children():
					if grandchild is MeshInstance3D:
						var mesh_grandchild: MeshInstance3D = grandchild as MeshInstance3D
						mesh_grandchild.scale.x = radial_length_scale
						mesh_grandchild.scale.y = width_scale
						mesh_grandchild.scale.z = panel_thickness_scale

func _rebuild_visual_rig() -> void:
	if _shell_root:
		remove_child(_shell_root)
		_shell_root.queue_free()
		_shell_root = null

	_scute_hinges.clear()
	_leg_hips.clear()
	_leg_knees.clear()
	_split_left_hinges.clear()
	_split_right_hinges.clear()
	_equator_upper = null
	_equator_lower = null
	_core_root = null
	_muzzle = null

	_build_visual_rig()
	_apply_fold_pose(_fold_amount)

func configure(config_data: Dictionary) -> void:
	super.configure(config_data)
	if config_data.is_empty():
		return

	var split_before_config: bool = split_faces_enabled

	if config_data.has("inflate"):
		inflation_enabled = _to_bool(config_data["inflate"], inflation_enabled)
	if config_data.has("inflate_speed"):
		inflation_speed = _to_float(config_data["inflate_speed"], inflation_speed)
	if config_data.has("inflate_amp"):
		inflation_amplitude = _to_float(config_data["inflate_amp"], inflation_amplitude)
	if config_data.has("inflate_min"):
		inflation_min_scale = _to_float(config_data["inflate_min"], inflation_min_scale)
	if config_data.has("inflate_fire_bias"):
		inflation_fire_bias = _to_float(config_data["inflate_fire_bias"], inflation_fire_bias)
	if config_data.has("inflate_radius_max"):
		inflated_radius_scale = _to_float(config_data["inflate_radius_max"], inflated_radius_scale)
	if config_data.has("inflate_radius_min"):
		deflated_radius_scale = _to_float(config_data["inflate_radius_min"], deflated_radius_scale)
	if config_data.has("inflate_thickness_max"):
		inflated_thickness_scale = _to_float(config_data["inflate_thickness_max"], inflated_thickness_scale)
	if config_data.has("inflate_thickness_min"):
		deflated_thickness_scale = _to_float(config_data["inflate_thickness_min"], deflated_thickness_scale)
	if config_data.has("pleat_fold"):
		pleat_fold_degrees = _to_float(config_data["pleat_fold"], pleat_fold_degrees)
	if config_data.has("pleat_twist"):
		pleat_twist_degrees = _to_float(config_data["pleat_twist"], pleat_twist_degrees)
	if config_data.has("aperture_open"):
		aperture_open_scale = _to_float(config_data["aperture_open"], aperture_open_scale)
	if config_data.has("aperture_closed"):
		aperture_closed_scale = _to_float(config_data["aperture_closed"], aperture_closed_scale)
	if config_data.has("collar_closed"):
		outer_collar_closed_scale = _to_float(config_data["collar_closed"], outer_collar_closed_scale)
	if config_data.has("split_faces"):
		split_faces_enabled = _to_bool(config_data["split_faces"], split_faces_enabled)
	if config_data.has("split_closed"):
		split_closed_dihedral_degrees = _to_float(config_data["split_closed"], split_closed_dihedral_degrees)
	if config_data.has("split_open"):
		split_open_dihedral_degrees = _to_float(config_data["split_open"], split_open_dihedral_degrees)
	if config_data.has("split_jitter"):
		split_jitter_degrees = _to_float(config_data["split_jitter"], split_jitter_degrees)

	if split_before_config != split_faces_enabled and _shell_root != null:
		_rebuild_visual_rig()

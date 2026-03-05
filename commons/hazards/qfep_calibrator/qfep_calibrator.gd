extends HazardCreatureBase
class_name QFEPCalibrator
## QFEP Laboratory sequence creature — morphing dodecahedron with 3 parameter beams.
## Parameters oscillate sinusoidally and dynamically change the creature's behavior:
##   phi (gold beam): controls rotation speed — high phi = fast spin, hard to hit
##   delta_e (cyan beam): controls damage — high delta_e = more damage but slower
##   constraint (magenta beam): controls detection — larger detection, smaller attack range
## Body pulses with emission based on combined parameter energy.

@export_group("Parameters")
@export var phi_frequency: float = 0.7
@export var delta_e_frequency: float = 0.5
@export var constraint_frequency: float = 0.3
@export var phi_amplitude: float = 1.0
@export var delta_e_amplitude: float = 1.0
@export var constraint_amplitude: float = 1.0

@export_group("Beam Visual")
@export var beam_length: float = 0.6
@export var beam_radius: float = 0.02

@export_group("Attack")
@export var base_damage: float = 10.0
@export var base_detection: float = 7.0
@export var base_attack_range: float = 1.5

# Parameters (0..1 oscillating)
var _phi: float = 0.5
var _delta_e: float = 0.5
var _constraint: float = 0.5

# Visual refs
var _body_mesh: MeshInstance3D = null
var _body_mat: StandardMaterial3D = null
var _phi_beam: MeshInstance3D = null
var _phi_mat: StandardMaterial3D = null
var _delta_e_beam: MeshInstance3D = null
var _delta_e_mat: StandardMaterial3D = null
var _constraint_beam: MeshInstance3D = null
var _constraint_mat: StandardMaterial3D = null
var _label: Label3D = null
var _leg_roots: Array[Node3D] = []
var _leg_meshes: Array[MeshInstance3D] = []
var _walk_phase: float = 0.0

# State
var _time: float = 0.0
var _spin_angle: float = 0.0
var _attack_cooldown: float = 0.0

# Colors
const PHI_COLOR: Color = Color(0.95, 0.8, 0.1)       # Gold
const DELTA_E_COLOR: Color = Color(0.1, 0.9, 0.9)     # Cyan
const CONSTRAINT_COLOR: Color = Color(0.9, 0.1, 0.85)  # Magenta
const BODY_COLOR: Color = Color(0.3, 0.25, 0.5)        # Deep purple


func _on_ready() -> void:
	max_health = 90.0
	_health = max_health
	patrol_speed = 1.5
	chase_speed = 2.5
	contact_damage = base_damage
	detection_radius = base_detection


func _create_materials() -> void:
	_body_mat = _make_material(BODY_COLOR, BODY_COLOR * 0.8)

	_phi_mat = _make_material(PHI_COLOR, PHI_COLOR)
	_phi_mat.emission_energy_multiplier = 2.0

	_delta_e_mat = _make_material(DELTA_E_COLOR, DELTA_E_COLOR)
	_delta_e_mat.emission_energy_multiplier = 2.0

	_constraint_mat = _make_material(CONSTRAINT_COLOR, CONSTRAINT_COLOR)
	_constraint_mat.emission_energy_multiplier = 2.0


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.65
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.65

	# Dodecahedron approximated with IcoSphereMesh (low subdivision)
	var ico := SphereMesh.new()
	ico.radius = 0.3
	ico.height = 0.6
	ico.radial_segments = 10
	ico.rings = 5
	_body_mesh = _add_mesh(ico, _body_mat)
	_body_mesh.name = "Body"

	# Phi beam (gold) — extends upward-right
	var phi_cyl := CylinderMesh.new()
	phi_cyl.height = beam_length
	phi_cyl.top_radius = beam_radius * 0.5
	phi_cyl.bottom_radius = beam_radius
	_phi_beam = _add_mesh(phi_cyl, _phi_mat, Vector3(0.0, 0.0, 0.0))
	_phi_beam.name = "PhiBeam"
	_phi_beam.rotation.z = -PI / 4.0
	_phi_beam.position = Vector3(0.2, 0.2, 0.0)

	# Phi tip sphere
	var phi_tip := SphereMesh.new()
	phi_tip.radius = 0.04
	phi_tip.height = 0.08
	var phi_tip_mi := MeshInstance3D.new()
	phi_tip_mi.mesh = phi_tip
	phi_tip_mi.set_surface_override_material(0, _phi_mat)
	phi_tip_mi.position = Vector3(0.0, beam_length * 0.5, 0.0)
	_phi_beam.add_child(phi_tip_mi)

	# Delta_e beam (cyan) — extends upward-left
	var de_cyl := CylinderMesh.new()
	de_cyl.height = beam_length
	de_cyl.top_radius = beam_radius * 0.5
	de_cyl.bottom_radius = beam_radius
	_delta_e_beam = _add_mesh(de_cyl, _delta_e_mat, Vector3(0.0, 0.0, 0.0))
	_delta_e_beam.name = "DeltaEBeam"
	_delta_e_beam.rotation.z = PI / 4.0
	_delta_e_beam.position = Vector3(-0.2, 0.2, 0.0)

	# Delta_e tip sphere
	var de_tip := SphereMesh.new()
	de_tip.radius = 0.04
	de_tip.height = 0.08
	var de_tip_mi := MeshInstance3D.new()
	de_tip_mi.mesh = de_tip
	de_tip_mi.set_surface_override_material(0, _delta_e_mat)
	de_tip_mi.position = Vector3(0.0, beam_length * 0.5, 0.0)
	_delta_e_beam.add_child(de_tip_mi)

	# Constraint beam (magenta) — extends backward
	var c_cyl := CylinderMesh.new()
	c_cyl.height = beam_length
	c_cyl.top_radius = beam_radius * 0.5
	c_cyl.bottom_radius = beam_radius
	_constraint_beam = _add_mesh(c_cyl, _constraint_mat, Vector3(0.0, 0.0, 0.0))
	_constraint_beam.name = "ConstraintBeam"
	_constraint_beam.rotation.x = -PI / 4.0
	_constraint_beam.position = Vector3(0.0, 0.15, -0.2)

	# Constraint tip sphere
	var c_tip := SphereMesh.new()
	c_tip.radius = 0.04
	c_tip.height = 0.08
	var c_tip_mi := MeshInstance3D.new()
	c_tip_mi.mesh = c_tip
	c_tip_mi.set_surface_override_material(0, _constraint_mat)
	c_tip_mi.position = Vector3(0.0, beam_length * 0.5, 0.0)
	_constraint_beam.add_child(c_tip_mi)

	# Build 2 legs
	for i in range(2):
		_build_leg(i)

	# Label
	_label = Label3D.new()
	_label.text = _get_param_text()
	_label.font_size = 32
	_label.pixel_size = 0.003
	_label.modulate = Color(0.9, 0.9, 0.9, 0.9)
	_label.position = Vector3(0, 0.7, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mesh_root.add_child(_label)


func _build_leg(index: int) -> void:
	var root := Node3D.new()
	root.name = "Leg_%d" % index
	var x_offset: float = 0.12 if index == 0 else -0.12
	root.position = Vector3(x_offset, -0.35, 0.0)
	_mesh_root.add_child(root)
	_leg_roots.append(root)

	var cyl := CylinderMesh.new()
	cyl.height = 0.3
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.02
	var leg_mat := _make_material(Color(0.2, 0.15, 0.3), BODY_COLOR * 0.3)
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, leg_mat)
	mi.position = Vector3(0, -0.15, 0)
	root.add_child(mi)
	_leg_meshes.append(mi)


func _get_param_text() -> String:
	return "phi=%.2f  de=%.2f  C=%.2f" % [_phi, _delta_e, _constraint]


func _process_visual(delta: float) -> void:
	_time += delta
	_attack_cooldown = max(0.0, _attack_cooldown - delta)

	# Oscillate parameters
	_phi = (sin(_time * phi_frequency * TAU) + 1.0) * 0.5 * phi_amplitude
	_delta_e = (sin(_time * delta_e_frequency * TAU) + 1.0) * 0.5 * delta_e_amplitude
	_constraint = (sin(_time * constraint_frequency * TAU) + 1.0) * 0.5 * constraint_amplitude

	# Apply parameter effects to behavior
	_apply_parameter_effects()

	# Body rotation — influenced by phi
	var spin_speed: float = 1.0 + _phi * 8.0
	_spin_angle += delta * spin_speed
	_body_mesh.rotation.y = _spin_angle
	_body_mesh.rotation.x = sin(_time * 1.5) * 0.15

	# Body emission pulse — combined parameter energy
	var combined_energy: float = (_phi + _delta_e + _constraint) / 3.0
	var pulse_color := BODY_COLOR.lerp(Color.WHITE, combined_energy * 0.4)
	_body_mat.albedo_color = pulse_color
	if _body_mat.emission_enabled:
		_body_mat.emission = pulse_color * 0.8
		_body_mat.emission_energy_multiplier = 1.0 + combined_energy * 3.0

	# Body scale pulsing
	var scale_pulse: float = 1.0 + sin(_time * 3.0) * combined_energy * 0.1
	_body_mesh.scale = Vector3(scale_pulse, scale_pulse, scale_pulse)

	# Update beam visuals — length scales with parameter value
	_update_beam(_phi_beam, _phi_mat, _phi, PHI_COLOR)
	_update_beam(_delta_e_beam, _delta_e_mat, _delta_e, DELTA_E_COLOR)
	_update_beam(_constraint_beam, _constraint_mat, _constraint, CONSTRAINT_COLOR)

	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 5.0
		for i in range(_leg_roots.size()):
			var phase_offset: float = float(i) * PI
			_leg_roots[i].rotation.x = sin(_walk_phase + phase_offset) * 0.3
			_leg_roots[i].rotation.z = cos(_walk_phase + phase_offset) * 0.1

	# Update label
	if _label:
		_label.text = _get_param_text()


func _update_beam(beam: MeshInstance3D, mat: StandardMaterial3D, param_val: float, base_color: Color) -> void:
	if not is_instance_valid(beam):
		return

	# Scale beam length with parameter
	var s: float = 0.3 + param_val * 0.7
	beam.scale.y = s

	# Emission intensity
	var brightness: float = 1.0 + param_val * 3.0
	mat.emission_energy_multiplier = brightness

	# Color intensity
	var c: Color = base_color.lerp(Color.WHITE, param_val * 0.3)
	mat.albedo_color = c
	mat.emission = c


func _apply_parameter_effects() -> void:
	# Phi: high = fast spin, harder to hit (already applied via spin_speed)
	# Also affects patrol/chase speed slightly
	var phi_speed_bonus: float = _phi * 1.5
	chase_speed = 2.0 + phi_speed_bonus

	# Delta_e: high = more damage, but slower movement
	contact_damage = base_damage + _delta_e * 20.0
	var de_speed_penalty: float = _delta_e * 1.5
	chase_speed = max(1.0, chase_speed - de_speed_penalty)

	# Constraint: high = larger detection, smaller attack range
	detection_radius = base_detection + _constraint * 5.0
	# Attack range is used in _process_chase


func _process_chase(delta: float) -> void:
	var dist: float = _get_player_distance()

	if dist > disengage_radius:
		_set_state(BaseState.PATROL)
		return

	# Move toward player
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.1:
			var move_dir: Vector3 = to_player.normalized()
			velocity.x = move_dir.x * chase_speed
			velocity.z = move_dir.z * chase_speed
			_face_direction(move_dir, delta * 5.0)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0

	# Attack when in range — range is inversely affected by constraint param
	var attack_range: float = base_attack_range * (1.0 - _constraint * 0.6)
	attack_range = max(0.5, attack_range)

	if dist < attack_range and _attack_cooldown <= 0.0:
		_perform_attack()


func _perform_attack() -> void:
	_attack_cooldown = 1.2

	if not is_instance_valid(_player_node):
		return

	# Damage scaled by delta_e
	var dmg: float = contact_damage
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("apply_health_damage"):
		gm.apply_health_damage(dmg)

	# Visual: all beams flash
	_flash_beam(_phi_beam, _phi_mat, PHI_COLOR)
	_flash_beam(_delta_e_beam, _delta_e_mat, DELTA_E_COLOR)
	_flash_beam(_constraint_beam, _constraint_mat, CONSTRAINT_COLOR)

	# Body pulse
	var attack_tween := create_tween()
	attack_tween.tween_property(_body_mesh, "scale", Vector3(1.3, 1.3, 1.3), 0.08)
	attack_tween.tween_property(_body_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.15)


func _flash_beam(beam: MeshInstance3D, mat: StandardMaterial3D, base_color: Color) -> void:
	if not is_instance_valid(beam):
		return
	var tween := create_tween()
	tween.tween_property(mat, "emission_energy_multiplier", 8.0, 0.05)
	tween.tween_property(mat, "emission_energy_multiplier", 2.0, 0.3)


func _on_damaged(_amount: float) -> void:
	# Damage disrupts parameter oscillation phases
	_time += randf_range(0.5, 2.0)
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.DEAD:
		# Death: beams collapse inward, body shrinks
		var death_tween := create_tween()
		death_tween.set_parallel(true)
		death_tween.tween_property(_mesh_root, "scale", Vector3.ZERO, 0.6)
		death_tween.tween_property(_body_mat, "emission_energy_multiplier", 0.0, 0.6)

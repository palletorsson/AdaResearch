# @identity
# essence: morph(sphere -> cube -> torus -> cylinder) -- 4 topological shapes, each a different attack
# desire: a creature shifting between sphere, cube, torus, cylinder -- genus as combat strategy
# critical_parameter: _current_topo / _morph_timer -- which topology is active determines attack type
# triggers: morph_timer triggers change; transition_phase interpolates shapes; each has unique attack
# emerges: topology as identity -- the creature's nature changes with genus, not just appearance
# needs: HazardCreatureBase [has]; 4 topology meshes [has]; morph interpolation [has]; per-topology attacks [has]; VR interaction [missing]
# relationships: embodies meshes sequence; contrasts with bricoleur_golem (fixed topologies vs improvised)
# truth: genus is not cosmetic -- sphere, cube, torus, cylinder each encode different threats.

extends HazardCreatureBase
class_name MeshMorpher
## Meshes sequence creature — morphs between 4 topological shapes.
## Each shape has a distinct attack pattern:
##   SPHERE (genus 0, chi=2): rolls fast toward player
##   CUBE (genus 0, chi=2): slams down with area damage
##   TORUS (genus 1, chi=0): spins horizontally like a buzzsaw
##   CYLINDER (genus 0, chi=2): extends height and sweeps like a bat
## Morphs every 5 seconds with a scale-down/scale-up transition.

enum Topology { SPHERE, CUBE, TORUS, CYLINDER }

@export_group("Morph")
@export var morph_interval: float = 5.0
@export var transition_duration: float = 0.4

@export_group("Attack")
@export var slam_damage: float = 25.0
@export var slam_radius: float = 1.5
@export var spin_damage_per_second: float = 15.0
@export var sweep_damage: float = 18.0

# Topology info
const TOPO_NAMES: Array[String] = ["SPHERE", "CUBE", "TORUS", "CYLINDER"]
const TOPO_GENUS: Array[int] = [0, 0, 1, 0]
const TOPO_CHI: Array[int] = [2, 2, 0, 2]

const TOPO_COLORS: Array[Color] = [
	Color(0.2, 0.4, 0.95),   # Sphere - blue
	Color(0.95, 0.55, 0.1),  # Cube - orange
	Color(0.7, 0.15, 0.9),   # Torus - purple
	Color(0.15, 0.85, 0.3),  # Cylinder - green
]

# Current state
var _current_topo: int = Topology.SPHERE
var _morph_timer: float = 0.0
var _transitioning: bool = false
var _transition_phase: float = 0.0  # 0..1 (0..0.5 = shrink, 0.5..1 = grow)
var _next_topo: int = -1

# Attack state
var _spin_angle: float = 0.0
var _slam_active: bool = false
var _slam_phase: float = 0.0
var _sweep_angle: float = 0.0
var _attack_cooldown: float = 0.0

# Visual
var _body_mesh: MeshInstance3D = null
var _body_mat: StandardMaterial3D = null
var _label: Label3D = null
var _leg_roots: Array[Node3D] = []
var _leg_meshes: Array[MeshInstance3D] = []
var _walk_phase: float = 0.0


func _on_ready() -> void:
	max_health = 100.0
	_health = max_health
	patrol_speed = 1.5
	chase_speed = 2.8
	contact_damage = 12.0
	detection_radius = 8.0


func _create_materials() -> void:
	_body_mat = _make_material(
		TOPO_COLORS[Topology.SPHERE],
		TOPO_COLORS[Topology.SPHERE] * 0.6
	)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.6
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.6

	# Start with sphere shape
	_body_mesh = MeshInstance3D.new()
	_body_mesh.name = "BodyMesh"
	_set_body_shape(Topology.SPHERE)
	_body_mesh.set_surface_override_material(0, _body_mat)
	_mesh_root.add_child(_body_mesh)

	# Build 2 legs
	for i in range(2):
		_build_leg(i)

	# Label
	_label = Label3D.new()
	_label.text = _get_topo_label_text()
	_label.font_size = 36
	_label.pixel_size = 0.003
	_label.modulate = Color(1, 1, 1, 0.9)
	_label.position = Vector3(0, 0.6, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mesh_root.add_child(_label)


func _build_leg(index: int) -> void:
	var root := Node3D.new()
	root.name = "Leg_%d" % index
	var x_offset: float = 0.15 if index == 0 else -0.15
	root.position = Vector3(x_offset, -0.35, 0.0)
	_mesh_root.add_child(root)
	_leg_roots.append(root)

	var cyl := CylinderMesh.new()
	cyl.height = 0.25
	cyl.top_radius = 0.03
	cyl.bottom_radius = 0.025
	var leg_mat := _make_material(Color(0.25, 0.25, 0.3), Color.BLACK)
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, leg_mat)
	mi.position = Vector3(0, -0.125, 0)
	root.add_child(mi)
	_leg_meshes.append(mi)


func _set_body_shape(topo: int) -> void:
	match topo:
		Topology.SPHERE:
			var m := SphereMesh.new()
			m.radius = 0.3
			m.height = 0.6
			m.radial_segments = 24
			m.rings = 12
			_body_mesh.mesh = m
		Topology.CUBE:
			var m := BoxMesh.new()
			m.size = Vector3(0.5, 0.5, 0.5)
			_body_mesh.mesh = m
		Topology.TORUS:
			var m := TorusMesh.new()
			m.inner_radius = 0.08
			m.outer_radius = 0.3
			_body_mesh.mesh = m
		Topology.CYLINDER:
			var m := CylinderMesh.new()
			m.height = 0.6
			m.top_radius = 0.2
			m.bottom_radius = 0.2
			_body_mesh.mesh = m


func _get_topo_label_text() -> String:
	var name: String = TOPO_NAMES[_current_topo]
	var genus: int = TOPO_GENUS[_current_topo]
	var chi: int = TOPO_CHI[_current_topo]
	return "%s  g=%d  X=%d" % [name, genus, chi]


func _process_visual(delta: float) -> void:
	_morph_timer += delta
	_attack_cooldown = max(0.0, _attack_cooldown - delta)

	# Morph timing
	if not _transitioning and _morph_timer >= morph_interval:
		_start_morph_transition()

	# Handle transition animation
	if _transitioning:
		_transition_phase += delta / transition_duration
		if _transition_phase >= 1.0:
			_finish_morph_transition()
		else:
			_update_transition()

	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 6.0
		for i in range(_leg_roots.size()):
			var phase_offset: float = float(i) * PI
			_leg_roots[i].rotation.x = sin(_walk_phase + phase_offset) * 0.35
			_leg_roots[i].rotation.z = cos(_walk_phase + phase_offset) * 0.1

	# Topology-specific visual effects
	match _current_topo:
		Topology.SPHERE:
			# Gentle rotation while rolling
			if _state == BaseState.CHASE:
				_body_mesh.rotation.z += delta * 8.0
		Topology.CUBE:
			# Slight wobble
			_body_mesh.rotation.y += delta * 0.5
			if _slam_active:
				_update_slam(delta)
		Topology.TORUS:
			# Spin like a buzzsaw
			_spin_angle += delta * 12.0
			_body_mesh.rotation.y = _spin_angle
			if _state == BaseState.CHASE:
				_body_mesh.rotation.x = sin(_spin_angle * 0.3) * 0.2
		Topology.CYLINDER:
			# Sweep rotation
			if _state == BaseState.CHASE:
				_sweep_angle += delta * 3.0
				_body_mesh.rotation.z = sin(_sweep_angle) * 0.4

	# Update label
	if _label:
		_label.text = _get_topo_label_text()
		_label.modulate = TOPO_COLORS[_current_topo]


func _start_morph_transition() -> void:
	_transitioning = true
	_transition_phase = 0.0
	_morph_timer = 0.0

	# Pick next topology (different from current)
	_next_topo = _current_topo
	while _next_topo == _current_topo:
		_next_topo = randi() % 4


func _update_transition() -> void:
	if _transition_phase < 0.5:
		# Shrink phase
		var t: float = _transition_phase / 0.5
		var s: float = 1.0 - t
		_body_mesh.scale = Vector3(s, s, s)
	else:
		# At midpoint, swap the mesh
		if _body_mesh.mesh != null:
			var mid_check: float = _transition_phase - 0.5
			if mid_check < 0.05:
				_current_topo = _next_topo
				_set_body_shape(_current_topo)
				_update_material_for_topo()
				_update_speed_for_topo()

		# Grow phase
		var t: float = (_transition_phase - 0.5) / 0.5
		var s: float = t
		_body_mesh.scale = Vector3(s, s, s)


func _finish_morph_transition() -> void:
	_transitioning = false
	_transition_phase = 0.0
	_body_mesh.scale = Vector3(1, 1, 1)
	_current_topo = _next_topo
	_set_body_shape(_current_topo)
	_update_material_for_topo()
	_update_speed_for_topo()


func _update_material_for_topo() -> void:
	var c: Color = TOPO_COLORS[_current_topo]
	_body_mat.albedo_color = c
	if _body_mat.emission_enabled:
		_body_mat.emission = c * 0.6
		_body_mat.emission_energy_multiplier = 1.5


func _update_speed_for_topo() -> void:
	match _current_topo:
		Topology.SPHERE:
			chase_speed = 4.5   # Rolls fast
			contact_damage = 10.0
		Topology.CUBE:
			chase_speed = 2.0   # Slow but slams
			contact_damage = 8.0
		Topology.TORUS:
			chase_speed = 3.0   # Medium speed buzzsaw
			contact_damage = 15.0
		Topology.CYLINDER:
			chase_speed = 2.5   # Medium speed sweep
			contact_damage = 12.0


func _process_chase(delta: float) -> void:
	# Topology-specific chase behavior
	match _current_topo:
		Topology.SPHERE:
			# Standard fast chase
			super._process_chase(delta)
		Topology.CUBE:
			# Move toward player, then slam
			super._process_chase(delta)
			if _get_player_distance() < 1.5 and _attack_cooldown <= 0.0:
				_start_slam()
		Topology.TORUS:
			# Chase with spinning damage
			super._process_chase(delta)
			if _get_player_distance() < 1.0 and _attack_cooldown <= 0.0:
				_apply_spin_damage(delta)
		Topology.CYLINDER:
			# Chase with sweep attack
			super._process_chase(delta)
			if _get_player_distance() < 1.8 and _attack_cooldown <= 0.0:
				_apply_sweep_damage()


func _start_slam() -> void:
	_slam_active = true
	_slam_phase = 0.0
	_attack_cooldown = 2.0

	# Jump up then slam
	var tween := create_tween()
	tween.tween_property(_mesh_root, "position:y", 1.8, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(_mesh_root, "position:y", 0.6, 0.12).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_slam_land)


func _update_slam(_delta: float) -> void:
	if _slam_active:
		_slam_phase += _delta
		if _slam_phase > 0.5:
			_slam_active = false


func _on_slam_land() -> void:
	_slam_active = false
	# Area damage on landing
	if is_instance_valid(_player_node):
		var dist: float = _get_player_distance()
		if dist < slam_radius:
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("apply_health_damage"):
				gm.apply_health_damage(slam_damage)

	# Visual impact: brief scale pulse on mesh root
	var impact_tween := create_tween()
	impact_tween.tween_property(_body_mesh, "scale", Vector3(1.4, 0.6, 1.4), 0.08)
	impact_tween.tween_property(_body_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.15)


func _apply_spin_damage(_delta: float) -> void:
	_attack_cooldown = 0.5
	if is_instance_valid(_player_node):
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("apply_health_damage"):
			gm.apply_health_damage(spin_damage_per_second * 0.5)


func _apply_sweep_damage() -> void:
	_attack_cooldown = 1.5
	if is_instance_valid(_player_node):
		var dist: float = _get_player_distance()
		if dist < 1.8:
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("apply_health_damage"):
				gm.apply_health_damage(sweep_damage)

	# Visual: extend cylinder height briefly
	var sweep_tween := create_tween()
	sweep_tween.tween_property(_body_mesh, "scale", Vector3(0.6, 2.0, 0.6), 0.15)
	sweep_tween.tween_property(_body_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.25)


func _on_damaged(_amount: float) -> void:
	# Getting hit forces a morph
	_start_morph_transition()
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.CHASE:
		_update_speed_for_topo()
	elif new_state == BaseState.DEAD:
		# Death animation: rapid shrink
		var death_tween := create_tween()
		death_tween.tween_property(_mesh_root, "scale", Vector3.ZERO, 0.5)

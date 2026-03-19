# @identity
# essence: cell(x) = argmin_i(|x - seed_i|) -- ground partitioned into Voronoi territories by nearest seed
# desire: drifting seed points dividing ground into territories -- safe, damage, slow, heal -- borders wander
# critical_parameter: _seed_positions / _seed_types -- locations determine boundaries; types assign effects
# triggers: seeds drift continuously; boundaries recompute; player cell type determines effect
# emerges: Voronoi partitioning as territorial hazard -- map reorganizes by nearest-neighbor geometry
# needs: Area3D [has]; seed tracking [has]; Voronoi computation [has]; type effects [has]; VR interaction [missing]
# relationships: embodies spatial_partitioning sequence; pairs with noise_field (cell vs continuous field)
# truth: Voronoi cells partition space by proximity -- borders between safe and lethal are always moving.

extends Area3D
class_name SpatialVoronoi
## Spatial-partitioning sequence hazard — ground plane divided into Voronoi cells.
## ~8 seed points drift slowly; each cell has a danger type (SAFE, DAMAGE, SLOW, HEAL).
## The player's nearest seed determines which cell they're in.
## Seeds periodically shuffle danger types. Boundaries shown with thin cylinder edges.

signal enemy_destroyed(enemy: Node3D)

enum CellType { SAFE, DAMAGE, SLOW, HEAL }

@export_group("Grid")
@export var field_size: float = 5.0
@export var seed_count: int = 8

@export_group("Combat")
@export var damage_per_second: float = 12.0
@export var slow_factor: float = 0.4
@export var heal_per_second: float = 3.0

@export_group("Behavior")
@export var seed_drift_speed: float = 0.3
@export var shuffle_interval: float = 6.0
@export var boundary_resolution: int = 40

# Seed data
var _seed_positions: Array[Vector3] = []
var _seed_velocities: Array[Vector3] = []
var _seed_types: Array[int] = []  # CellType values
var _seed_meshes: Array[MeshInstance3D] = []
var _seed_materials: Array[StandardMaterial3D] = []

# Boundary visualization
var _boundary_meshes: Array[MeshInstance3D] = []
var _boundary_materials: Array[StandardMaterial3D] = []

# State
var _player_node: Node3D = null
var _player_inside: bool = false
var _damage_accumulator: float = 0.0
var _time: float = 0.0
var _shuffle_timer: float = 0.0

# Visual
var _label: Label3D = null
var _ground_plane: MeshInstance3D = null

# Type colors
const TYPE_COLORS: Dictionary = {
	0: Color(0.1, 0.8, 0.2),    # SAFE - green
	1: Color(0.95, 0.15, 0.1),  # DAMAGE - red
	2: Color(0.2, 0.4, 0.95),   # SLOW - blue
	3: Color(0.9, 0.9, 0.9),    # HEAL - white
}

const TYPE_NAMES: Array[String] = ["SAFE", "DMG", "SLOW", "HEAL"]


func _ready() -> void:
	# Collision — covers the field
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(field_size, 2.0, field_size)
	col.shape = shape
	col.position = Vector3(0.0, 1.0, 0.0)
	add_child(col)

	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_build_ground()
	_init_seeds()
	_build_seed_meshes()
	_build_boundary_markers()
	_build_label()
	_find_player()
	add_to_group("enemy")


func _process(delta: float) -> void:
	_time += delta
	_shuffle_timer += delta

	# Shuffle cell types periodically
	if _shuffle_timer >= shuffle_interval:
		_shuffle_timer = 0.0
		_shuffle_types()

	# Drift seeds
	_drift_seeds(delta)

	# Update seed visuals
	for i in range(seed_count):
		_seed_meshes[i].position = _seed_positions[i]
		var c: Color = TYPE_COLORS[_seed_types[i]]
		_seed_materials[i].albedo_color = c
		_seed_materials[i].emission = c
		var pulse: float = 1.2 + sin(_time * 3.0 + float(i) * 1.5) * 0.6
		_seed_materials[i].emission_energy_multiplier = pulse

	# Update boundary visualization
	_update_boundaries()

	# Apply effect to player
	if _player_inside and is_instance_valid(_player_node):
		var cell_type: int = _get_player_cell_type()
		match cell_type:
			CellType.DAMAGE:
				_damage_accumulator += delta * damage_per_second
				if _damage_accumulator >= 1.0:
					var dmg: float = floor(_damage_accumulator)
					_damage_accumulator -= dmg
					var gm = get_node_or_null("/root/GameManager")
					if gm and gm.has_method("apply_health_damage"):
						gm.apply_health_damage(dmg)
			CellType.HEAL:
				# Healing is optional — only if GameManager supports it
				var gm = get_node_or_null("/root/GameManager")
				if gm and gm.has_method("apply_health_heal"):
					gm.apply_health_heal(heal_per_second * delta)
			CellType.SLOW:
				# Slow effect — we signal via label, actual slow is game-specific
				pass
			CellType.SAFE:
				_damage_accumulator = max(0.0, _damage_accumulator - delta)

	# Update label
	if _label:
		var cell_name: String = "---"
		if _player_inside and is_instance_valid(_player_node):
			var ct: int = _get_player_cell_type()
			cell_name = TYPE_NAMES[ct]
		_label.text = "VORONOI CELLS: %d seeds [%s]" % [seed_count, cell_name]


func _build_ground() -> void:
	var plane_mesh := BoxMesh.new()
	plane_mesh.size = Vector3(field_size, 0.02, field_size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.06, 0.1, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.03, 0.03, 0.08)
	mat.emission_energy_multiplier = 0.3
	_ground_plane = MeshInstance3D.new()
	_ground_plane.mesh = plane_mesh
	_ground_plane.set_surface_override_material(0, mat)
	_ground_plane.position = Vector3(0.0, 0.0, 0.0)
	add_child(_ground_plane)


func _init_seeds() -> void:
	var half: float = field_size * 0.4
	for i in range(seed_count):
		var pos := Vector3(
			randf_range(-half, half),
			0.15,
			randf_range(-half, half)
		)
		_seed_positions.append(pos)

		var vel := Vector3(
			randf_range(-1.0, 1.0),
			0.0,
			randf_range(-1.0, 1.0)
		).normalized() * seed_drift_speed
		_seed_velocities.append(vel)

		# Assign types: mostly SAFE/DAMAGE, some SLOW/HEAL
		var type_val: int
		var r: float = randf()
		if r < 0.3:
			type_val = CellType.SAFE
		elif r < 0.65:
			type_val = CellType.DAMAGE
		elif r < 0.85:
			type_val = CellType.SLOW
		else:
			type_val = CellType.HEAL
		_seed_types.append(type_val)


func _build_seed_meshes() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.radial_segments = 12
	sphere.rings = 6

	for i in range(seed_count):
		var c: Color = TYPE_COLORS[_seed_types[i]]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = c
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = 1.5

		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		mi.set_surface_override_material(0, mat)
		mi.position = _seed_positions[i]
		add_child(mi)

		_seed_meshes.append(mi)
		_seed_materials.append(mat)


func _build_boundary_markers() -> void:
	# Create a pool of small cylinder markers to visualize boundaries
	var marker_mesh := CylinderMesh.new()
	marker_mesh.height = 0.3
	marker_mesh.top_radius = 0.015
	marker_mesh.bottom_radius = 0.015

	for i in range(boundary_resolution * boundary_resolution):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.7, 0.7, 0.7, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.5, 0.5, 0.5)
		mat.emission_energy_multiplier = 0.5

		var mi := MeshInstance3D.new()
		mi.mesh = marker_mesh
		mi.set_surface_override_material(0, mat)
		mi.visible = false
		add_child(mi)

		_boundary_meshes.append(mi)
		_boundary_materials.append(mat)


func _update_boundaries() -> void:
	# Sample grid points and show markers at Voronoi boundaries
	var half: float = field_size * 0.5
	var step: float = field_size / float(boundary_resolution)
	var marker_idx: int = 0

	for row in range(boundary_resolution):
		for col_idx in range(boundary_resolution):
			if marker_idx >= _boundary_meshes.size():
				break

			var sample_pos := Vector3(
				-half + (float(col_idx) + 0.5) * step,
				0.0,
				-half + (float(row) + 0.5) * step
			)

			# Find two nearest seeds
			var nearest: int = _find_nearest_seed(sample_pos)
			var nearest_dist: float = sample_pos.distance_to(_seed_positions[nearest])

			# Check if close to boundary (second nearest is almost as close)
			var second_dist: float = INF
			for s in range(seed_count):
				if s == nearest:
					continue
				var d: float = sample_pos.distance_to(_seed_positions[s])
				if d < second_dist:
					second_dist = d

			var diff: float = second_dist - nearest_dist
			var is_boundary: bool = diff < step * 1.2

			if is_boundary:
				_boundary_meshes[marker_idx].visible = true
				_boundary_meshes[marker_idx].position = Vector3(sample_pos.x, 0.15, sample_pos.z)
				var c: Color = TYPE_COLORS[_seed_types[nearest]]
				_boundary_materials[marker_idx].albedo_color = Color(c.r, c.g, c.b, 0.5)
				_boundary_materials[marker_idx].emission = c * 0.3
			else:
				_boundary_meshes[marker_idx].visible = false

			marker_idx += 1


func _drift_seeds(delta: float) -> void:
	var half: float = field_size * 0.45
	for i in range(seed_count):
		_seed_positions[i] += _seed_velocities[i] * delta
		_seed_positions[i].y = 0.15  # Keep seeds at ground level

		# Bounce off boundaries
		if abs(_seed_positions[i].x) > half:
			_seed_velocities[i].x *= -1.0
			_seed_positions[i].x = clampf(_seed_positions[i].x, -half, half)
		if abs(_seed_positions[i].z) > half:
			_seed_velocities[i].z *= -1.0
			_seed_positions[i].z = clampf(_seed_positions[i].z, -half, half)


func _shuffle_types() -> void:
	# Fisher-Yates shuffle of the type assignments
	var types_copy: Array[int] = _seed_types.duplicate()
	for i in range(types_copy.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: int = types_copy[i]
		types_copy[i] = types_copy[j]
		types_copy[j] = tmp
	_seed_types = types_copy


func _find_nearest_seed(pos: Vector3) -> int:
	var best_idx: int = 0
	var best_dist: float = INF
	for i in range(seed_count):
		var d: float = pos.distance_to(_seed_positions[i])
		if d < best_dist:
			best_dist = d
			best_idx = i
	return best_idx


func _get_player_cell_type() -> int:
	if not is_instance_valid(_player_node):
		return CellType.SAFE
	var player_pos: Vector3 = _player_node.global_position - global_position
	player_pos.y = 0.0
	var nearest: int = _find_nearest_seed(player_pos)
	return _seed_types[nearest]


func _build_label() -> void:
	_label = Label3D.new()
	_label.text = "VORONOI CELLS: %d seeds" % seed_count
	_label.font_size = 24
	_label.pixel_size = 0.003
	_label.modulate = Color(0.9, 0.9, 0.3)
	_label.position = Vector3(0.0, 1.5, -field_size * 0.5 - 0.3)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_player_node = body
		_damage_accumulator = 0.0

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false


func _find_player() -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	for candidate in [
		get_tree().get_first_node_in_group("player"),
		scene.find_child("XROrigin3D", true, false),
		scene.find_child("Player", true, false),
	]:
		if candidate is Node3D:
			_player_node = candidate
			return


# ── Damage Interface ────────────────────────────────────────────────────
func take_damage(_amount: float) -> void:
	pass  # Zone hazard — indestructible

func apply_damage(_amount: float) -> void:
	pass

func damage(_amount: float) -> void:
	pass

func configure(config: Dictionary) -> void:
	if config.has("damage"):
		damage_per_second = float(config["damage"])
	if config.has("seed_count"):
		seed_count = int(config["seed_count"])
	if config.has("field_size"):
		field_size = float(config["field_size"])

func apply_grid_config(config: Dictionary) -> void:
	configure(config)

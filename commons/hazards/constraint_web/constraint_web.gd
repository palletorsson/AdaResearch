extends Area3D
class_name ConstraintWeb
## Constraint-solvers sequence hazard — a 5x5 grid of tiles representing a CSP.
## Each tile has a domain of possible colors. Tiles start in superposition
## (flickering semi-transparent). When the player steps on a tile it collapses
## to one color. Adjacent tiles then propagate constraints (no two adjacent
## tiles may share the same color). If a contradiction is reached (empty domain),
## that tile explodes and deals damage to the player.

signal enemy_destroyed(enemy: Node3D)

@export_group("Grid")
@export var grid_cols: int = 5
@export var grid_rows: int = 5
@export var tile_size: float = 0.45
@export var tile_gap: float = 0.05
@export var tile_height: float = 0.08

@export_group("Combat")
@export var explosion_damage: float = 20.0
@export var explosion_radius: float = 1.5

@export_group("Timing")
@export var flicker_speed: float = 6.0
@export var propagation_delay: float = 0.3

# Domain colors
const DOMAIN_COLORS: Array[Color] = [
	Color(0.9, 0.15, 0.1),   # Red
	Color(0.15, 0.4, 0.9),   # Blue
	Color(0.1, 0.85, 0.2),   # Green
	Color(0.95, 0.85, 0.1),  # Yellow
]

const DOMAIN_NAMES: Array[String] = ["R", "B", "G", "Y"]

# Per-tile state
var _tile_meshes: Array[MeshInstance3D] = []
var _tile_materials: Array[StandardMaterial3D] = []
var _tile_domains: Array[Array] = []        # Each entry: array of valid color indices
var _tile_collapsed: Array[bool] = []       # Whether the tile has been assigned a color
var _tile_assigned: Array[int] = []         # Assigned color index (-1 = unassigned)
var _tile_exploded: Array[bool] = []        # Whether a contradiction exploded this tile

# Propagation queue: [[tile_index, delay_remaining]]
var _propagation_queue: Array[Array] = []

# State
var _player_node: Node3D = null
var _player_inside: bool = false
var _time: float = 0.0
var _constraints_satisfied: int = 0
var _constraints_total: int = 0

# Visual
var _label: Label3D = null
var _base_plane: MeshInstance3D = null


func _ready() -> void:
	# Collision — covers the full grid
	var total_w: float = grid_cols * (tile_size + tile_gap)
	var total_d: float = grid_rows * (tile_size + tile_gap)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(total_w, 2.0, total_d)
	col.shape = shape
	col.position = Vector3(
		total_w * 0.5 - (tile_size + tile_gap) * 0.5,
		1.0,
		total_d * 0.5 - (tile_size + tile_gap) * 0.5
	)
	add_child(col)

	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_build_base_plane()
	_build_grid()
	_build_label()
	_find_player()
	add_to_group("enemy")


func _process(delta: float) -> void:
	_time += delta

	# Process propagation queue
	var completed_indices: Array[int] = []
	for i in range(_propagation_queue.size()):
		_propagation_queue[i][1] -= delta
		if _propagation_queue[i][1] <= 0.0:
			completed_indices.append(i)

	# Process in reverse to avoid index shifting
	completed_indices.reverse()
	for idx in completed_indices:
		var tile_idx: int = _propagation_queue[idx][0]
		_propagation_queue.remove_at(idx)
		_propagate_constraints(tile_idx)

	# Update visuals for uncollapsed tiles (flicker effect)
	for i in range(_tile_meshes.size()):
		if _tile_exploded[i]:
			continue
		if not _tile_collapsed[i]:
			# Superposition flicker: cycle through domain colors
			var domain: Array = _tile_domains[i]
			if domain.size() > 0:
				var flicker_idx: int = int(_time * flicker_speed + float(i) * 1.7) % domain.size()
				var c: Color = DOMAIN_COLORS[domain[flicker_idx]]
				_tile_materials[i].albedo_color = Color(c.r, c.g, c.b, 0.35)
				_tile_materials[i].emission = c * 0.3
				_tile_materials[i].emission_energy_multiplier = 0.8 + sin(_time * 4.0 + float(i)) * 0.4
		else:
			# Collapsed tile: solid color with gentle pulse
			var c: Color = DOMAIN_COLORS[_tile_assigned[i]]
			var pulse: float = 1.0 + sin(_time * 2.0) * 0.1
			_tile_materials[i].albedo_color = c
			_tile_materials[i].emission = c * 0.5
			_tile_materials[i].emission_energy_multiplier = pulse

	# Check player position and collapse tile under them
	if _player_inside and is_instance_valid(_player_node):
		var tile_idx: int = _get_tile_under_player()
		if tile_idx >= 0 and not _tile_collapsed[tile_idx] and not _tile_exploded[tile_idx]:
			_collapse_tile(tile_idx)

	# Update constraint count
	_count_constraints()

	# Update label
	if _label:
		_label.text = "CONSTRAINTS: %d/%d satisfied" % [_constraints_satisfied, _constraints_total]


func _build_base_plane() -> void:
	var total_w: float = grid_cols * (tile_size + tile_gap)
	var total_d: float = grid_rows * (tile_size + tile_gap)
	var plane_mesh := BoxMesh.new()
	plane_mesh.size = Vector3(total_w + 0.1, 0.02, total_d + 0.1)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.12)
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.05, 0.1)
	mat.emission_energy_multiplier = 0.3
	_base_plane = MeshInstance3D.new()
	_base_plane.mesh = plane_mesh
	_base_plane.set_surface_override_material(0, mat)
	_base_plane.position = Vector3(
		(grid_cols - 1) * (tile_size + tile_gap) * 0.5,
		-0.01,
		(grid_rows - 1) * (tile_size + tile_gap) * 0.5
	)
	add_child(_base_plane)


func _build_grid() -> void:
	var step: float = tile_size + tile_gap
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(tile_size, tile_height, tile_size)

	for row in range(grid_rows):
		for col_idx in range(grid_cols):
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.5, 0.5, 0.5, 0.35)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.3, 0.3)
			mat.emission_energy_multiplier = 0.5

			var mi := MeshInstance3D.new()
			mi.mesh = tile_mesh
			mi.set_surface_override_material(0, mat)
			mi.position = Vector3(col_idx * step, tile_height * 0.5, row * step)
			add_child(mi)

			_tile_meshes.append(mi)
			_tile_materials.append(mat)

			# Full domain initially (all 4 colors)
			_tile_domains.append([0, 1, 2, 3])
			_tile_collapsed.append(false)
			_tile_assigned.append(-1)
			_tile_exploded.append(false)


func _build_label() -> void:
	_label = Label3D.new()
	_label.text = "CONSTRAINTS: 0/0 satisfied"
	_label.font_size = 24
	_label.pixel_size = 0.003
	_label.modulate = Color(0.9, 0.9, 0.3)
	var total_w: float = grid_cols * (tile_size + tile_gap)
	_label.position = Vector3(total_w * 0.5 - (tile_size + tile_gap) * 0.5, 1.2, -0.4)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)


func _get_tile_under_player() -> int:
	if not is_instance_valid(_player_node):
		return -1
	var local_pos: Vector3 = _player_node.global_position - global_position
	var step: float = tile_size + tile_gap
	var col_f: int = int(round(local_pos.x / step))
	var row_f: int = int(round(local_pos.z / step))
	if col_f < 0 or col_f >= grid_cols or row_f < 0 or row_f >= grid_rows:
		return -1
	return row_f * grid_cols + col_f


func _collapse_tile(idx: int) -> void:
	if _tile_collapsed[idx] or _tile_exploded[idx]:
		return
	var domain: Array = _tile_domains[idx]
	if domain.is_empty():
		_explode_tile(idx)
		return

	# Choose a random color from the remaining domain
	var chosen: int = domain[randi() % domain.size()]
	_tile_assigned[idx] = chosen
	_tile_collapsed[idx] = true

	# Solid material
	var c: Color = DOMAIN_COLORS[chosen]
	_tile_materials[idx].albedo_color = c
	_tile_materials[idx].transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_tile_materials[idx].emission = c * 0.6
	_tile_materials[idx].emission_energy_multiplier = 1.5

	# Slight pop-up animation
	var tween := create_tween()
	tween.tween_property(_tile_meshes[idx], "scale", Vector3(1.2, 2.0, 1.2), 0.1)
	tween.tween_property(_tile_meshes[idx], "scale", Vector3(1.0, 1.0, 1.0), 0.15)

	# Queue propagation to neighbors
	var neighbors: Array[int] = _get_neighbors(idx)
	for n_idx in neighbors:
		if not _tile_collapsed[n_idx] and not _tile_exploded[n_idx]:
			_propagation_queue.append([n_idx, propagation_delay])

	# Remove chosen color from neighbor domains immediately
	for n_idx in neighbors:
		if not _tile_collapsed[n_idx] and not _tile_exploded[n_idx]:
			var n_domain: Array = _tile_domains[n_idx]
			if chosen in n_domain:
				n_domain.erase(chosen)
				_tile_domains[n_idx] = n_domain


func _propagate_constraints(idx: int) -> void:
	if _tile_collapsed[idx] or _tile_exploded[idx]:
		return
	var domain: Array = _tile_domains[idx]

	if domain.is_empty():
		_explode_tile(idx)
		return

	# If only one color remains, auto-collapse
	if domain.size() == 1:
		_collapse_tile(idx)


func _explode_tile(idx: int) -> void:
	_tile_exploded[idx] = true
	_tile_collapsed[idx] = true
	_tile_assigned[idx] = -1

	# Visual: flash white then turn dark/cracked
	var mat: StandardMaterial3D = _tile_materials[idx]
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.emission = Color(1.0, 0.5, 0.1)
	mat.emission_energy_multiplier = 5.0

	var tween := create_tween()
	tween.tween_property(mat, "albedo_color", Color(0.15, 0.05, 0.05), 0.4)
	tween.tween_property(mat, "emission_energy_multiplier", 0.2, 0.3)

	# Scale shake
	var mesh: MeshInstance3D = _tile_meshes[idx]
	var shake_tween := create_tween()
	shake_tween.tween_property(mesh, "scale", Vector3(1.5, 3.0, 1.5), 0.08)
	shake_tween.tween_property(mesh, "scale", Vector3(0.8, 0.3, 0.8), 0.2)
	shake_tween.tween_property(mesh, "scale", Vector3(1.0, 0.5, 1.0), 0.15)

	# Deal damage to player if nearby
	if is_instance_valid(_player_node):
		var tile_world_pos: Vector3 = _tile_meshes[idx].global_position
		var dist: float = tile_world_pos.distance_to(_player_node.global_position)
		if dist < explosion_radius:
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("apply_health_damage"):
				gm.apply_health_damage(explosion_damage)


func _get_neighbors(idx: int) -> Array[int]:
	var neighbors: Array[int] = []
	var row: int = idx / grid_cols
	var col: int = idx % grid_cols
	# Up
	if row > 0:
		neighbors.append((row - 1) * grid_cols + col)
	# Down
	if row < grid_rows - 1:
		neighbors.append((row + 1) * grid_cols + col)
	# Left
	if col > 0:
		neighbors.append(row * grid_cols + (col - 1))
	# Right
	if col < grid_cols - 1:
		neighbors.append(row * grid_cols + (col + 1))
	return neighbors


func _count_constraints() -> void:
	_constraints_total = 0
	_constraints_satisfied = 0

	for idx in range(grid_cols * grid_rows):
		var row: int = idx / grid_cols
		var col: int = idx % grid_cols
		# Right neighbor
		if col < grid_cols - 1:
			_constraints_total += 1
			var r_idx: int = row * grid_cols + (col + 1)
			if _tile_collapsed[idx] and _tile_collapsed[r_idx]:
				if _tile_assigned[idx] != _tile_assigned[r_idx]:
					_constraints_satisfied += 1
				# Exploded tiles don't count as violations
				elif _tile_exploded[idx] or _tile_exploded[r_idx]:
					pass  # neither satisfied nor violated
			elif not _tile_collapsed[idx] or not _tile_collapsed[r_idx]:
				pass  # Not yet determined
		# Down neighbor
		if row < grid_rows - 1:
			_constraints_total += 1
			var d_idx: int = (row + 1) * grid_cols + col
			if _tile_collapsed[idx] and _tile_collapsed[d_idx]:
				if _tile_assigned[idx] != _tile_assigned[d_idx]:
					_constraints_satisfied += 1
				elif _tile_exploded[idx] or _tile_exploded[d_idx]:
					pass
			elif not _tile_collapsed[idx] or not _tile_collapsed[d_idx]:
				pass


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_player_node = body

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
		explosion_damage = float(config["damage"])
	if config.has("explosion_radius"):
		explosion_radius = float(config["explosion_radius"])

func apply_grid_config(config: Dictionary) -> void:
	configure(config)

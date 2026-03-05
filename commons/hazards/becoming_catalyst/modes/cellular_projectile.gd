# CellularProjectile.gd
# A slow-flying cube with a 3x3 CA grid that evolves as it travels.
# The pattern changes every step — alive cells glow, dead cells go dark.
extends CatalystProjectile

const GRID_SIZE := 3
const EVOLVE_INTERVAL := 0.6  # Seconds between CA steps

var _alive_cells: Array[bool] = []
var _cell_meshes: Array[MeshInstance3D] = []
var _cell_mats: Array[StandardMaterial3D] = []
var _rule: int = 30
var _evolve_timer: float = 0.0
var _generation: int = 0

# Local axes for cell positioning
var _local_right: Vector3
var _local_up: Vector3
var _local_forward: Vector3

func _build_visual() -> void:
	# Pick a random elementary CA rule
	_rule = [30, 90, 110, 150, 184, 60, 45, 73][randi() % 8]
	_alive_cells = _generate_initial_pattern()

	_local_forward = direction.normalized()
	if abs(_local_forward.dot(Vector3.UP)) < 0.99:
		_local_right = _local_forward.cross(Vector3.UP).normalized()
	else:
		_local_right = _local_forward.cross(Vector3.RIGHT).normalized()
	_local_up = _local_right.cross(_local_forward).normalized()

	# Main cube body — dark frame
	_mesh_instance = MeshInstance3D.new()
	var box := BoxMesh.new()
	var cube_size := 0.18 * projectile_scale
	box.size = Vector3.ONE * cube_size
	_mesh_instance.mesh = box
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.12, 0.12, 0.18)
	frame_mat.emission_enabled = true
	frame_mat.emission = color_secondary
	frame_mat.emission_energy_multiplier = 0.3
	frame_mat.metallic = 0.8
	frame_mat.roughness = 0.15
	_mesh_instance.material_override = frame_mat
	add_child(_mesh_instance)

	# Cell grid on front face
	var cell_size := cube_size * 0.28
	var spacing := cube_size * 0.32

	for row in GRID_SIZE:
		for col in GRID_SIZE:
			var idx := row * GRID_SIZE + col
			var alive := _alive_cells[idx]

			var cell := MeshInstance3D.new()
			var cell_box := BoxMesh.new()
			cell_box.size = Vector3.ONE * cell_size
			cell.mesh = cell_box

			var mat := StandardMaterial3D.new()
			_apply_cell_material(mat, alive)
			cell.material_override = mat

			var offset_r := (col - 1) * spacing
			var offset_u := (row - 1) * spacing
			cell.position = _local_right * offset_r + _local_up * offset_u + _local_forward * (cube_size * 0.52)
			add_child(cell)
			_cell_meshes.append(cell)
			_cell_mats.append(mat)

func _apply_cell_material(mat: StandardMaterial3D, alive: bool) -> void:
	if alive:
		mat.albedo_color = color_primary
		mat.emission_enabled = true
		mat.emission = color_primary
		mat.emission_energy_multiplier = emission_energy
	else:
		mat.albedo_color = Color(0.05, 0.05, 0.08)
		mat.emission_enabled = true
		mat.emission = Color(0.1, 0.1, 0.15)
		mat.emission_energy_multiplier = 0.2
	mat.metallic = 0.3
	mat.roughness = 0.4

func _build_collision() -> void:
	_collision_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * 0.2 * projectile_scale
	_collision_shape.shape = box
	add_child(_collision_shape)

func _update_trajectory(delta: float) -> void:
	# Slow tumble
	if _mesh_instance:
		_mesh_instance.rotate_y(delta * 1.0)
		_mesh_instance.rotate_x(delta * 0.5)
	for cell in _cell_meshes:
		cell.rotate_y(delta * 1.0)
		cell.rotate_x(delta * 0.5)

	# Evolve CA pattern
	_evolve_timer += delta
	if _evolve_timer >= EVOLVE_INTERVAL:
		_evolve_timer = 0.0
		_evolve_step()

func _evolve_step() -> void:
	_generation += 1
	var new_cells: Array[bool] = []
	new_cells.resize(GRID_SIZE * GRID_SIZE)

	for i in GRID_SIZE * GRID_SIZE:
		var left_idx := (i - 1 + 9) % 9
		var right_idx := (i + 1) % 9
		var neighborhood := 0
		if _alive_cells[left_idx]: neighborhood += 4
		if _alive_cells[i]: neighborhood += 2
		if _alive_cells[right_idx]: neighborhood += 1
		new_cells[i] = (_rule >> neighborhood) & 1 == 1

	# Ensure at least one alive
	if not new_cells.any(func(v): return v):
		new_cells[randi() % 9] = true

	_alive_cells = new_cells

	# Update cell visuals
	for i in _cell_meshes.size():
		if i < _alive_cells.size():
			_apply_cell_material(_cell_mats[i], _alive_cells[i])

func _generate_initial_pattern() -> Array[bool]:
	# Start with center cell alive
	var result: Array[bool] = []
	result.resize(9)
	for i in 9:
		result[i] = false
	result[4] = true
	# Evolve one step to get an interesting starting pattern
	var evolved: Array[bool] = []
	evolved.resize(9)
	for i in 9:
		var left_idx := (i - 1 + 9) % 9
		var right_idx := (i + 1) % 9
		var neighborhood := 0
		if result[left_idx]: neighborhood += 4
		if result[i]: neighborhood += 2
		if result[right_idx]: neighborhood += 1
		evolved[i] = (_rule >> neighborhood) & 1 == 1
	if not evolved.any(func(v): return v):
		evolved[4] = true
	return evolved

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	if body.has_method("hit_by_projectile"):
		body.hit_by_projectile(color_primary)

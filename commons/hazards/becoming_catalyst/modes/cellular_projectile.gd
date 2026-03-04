# CellularProjectile.gd
# A flying cube that reveals a 3×3 CA grid pattern on its faces.
# Alive cells glow, dead cells are dark voids. The cube IS the automaton.
extends CatalystProjectile

const GRID_SIZE := 3
const CELL_SPACING := 0.06

var _alive_cells: Array[bool] = []
var _cell_meshes: Array[MeshInstance3D] = []

func _build_visual() -> void:
	# Generate alive/dead pattern from a CA rule
	_alive_cells = _generate_pattern()

	# Main cube body — dark metallic frame
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

	# Overlay alive cells as glowing cubelets on the front face
	var forward := direction.normalized()
	var right: Vector3
	var up: Vector3
	if abs(forward.dot(Vector3.UP)) < 0.99:
		right = forward.cross(Vector3.UP).normalized()
	else:
		right = forward.cross(Vector3.RIGHT).normalized()
	up = right.cross(forward).normalized()

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
			cell.material_override = mat

			# Position on front face of the cube
			var offset_r := (col - 1) * spacing
			var offset_u := (row - 1) * spacing
			cell.position = right * offset_r + up * offset_u + forward * (cube_size * 0.52)
			add_child(cell)
			_cell_meshes.append(cell)

func _build_collision() -> void:
	_collision_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * 0.2 * projectile_scale
	_collision_shape.shape = box
	add_child(_collision_shape)

func _update_trajectory(delta: float) -> void:
	# Slow deliberate rotation — the cube tumbles as it flies
	if _mesh_instance:
		_mesh_instance.rotate_y(delta * 1.5)
		_mesh_instance.rotate_x(delta * 0.8)
	# Rotate cell overlay with the cube
	for cell in _cell_meshes:
		cell.rotate_y(delta * 1.5)
		cell.rotate_x(delta * 0.8)

func _generate_pattern() -> Array[bool]:
	# Use Rule 30 (or random rule) to generate a 3×3 pattern
	var rule: int = [30, 90, 110, 150, 184][randi() % 5]
	# Start with middle cell alive, evolve 1 step
	var prev: Array[bool] = [false, false, false, false, true, false, false, false, false]
	var result: Array[bool] = []
	result.resize(9)
	for i in 9:
		var left_idx := (i - 1 + 9) % 9
		var right_idx := (i + 1) % 9
		var neighborhood := 0
		if prev[left_idx]: neighborhood += 4
		if prev[i]: neighborhood += 2
		if prev[right_idx]: neighborhood += 1
		result[i] = (rule >> neighborhood) & 1 == 1
	# Ensure at least one alive
	if not result.any(func(v): return v):
		result[4] = true
	return result

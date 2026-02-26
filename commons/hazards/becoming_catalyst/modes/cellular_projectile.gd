# CellularProjectile.gd
# Fires a 3×3 grid of tiny cubes.  Alive cells collide, dead cells pass through.
# Pattern determined by a CA rule (Rule 30 / random rule per shot).
extends CatalystProjectile

const GRID_SIZE := 3
const CELL_SPACING := 0.06

var _alive_cells: Array[bool] = []
var _cell_meshes: Array[MeshInstance3D] = []

func _build_visual() -> void:
	# Generate alive/dead pattern from a CA rule
	_alive_cells = _generate_pattern()

	var forward := direction.normalized()
	var right: Vector3
	var up: Vector3
	if abs(forward.dot(Vector3.UP)) < 0.99:
		right = forward.cross(Vector3.UP).normalized()
	else:
		right = forward.cross(Vector3.RIGHT).normalized()
	up = right.cross(forward).normalized()

	for row in GRID_SIZE:
		for col in GRID_SIZE:
			var idx := row * GRID_SIZE + col
			var alive := _alive_cells[idx]

			var cell := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3.ONE * 0.035 * projectile_scale
			cell.mesh = box

			var mat := StandardMaterial3D.new()
			if alive:
				mat.albedo_color = color_primary
				mat.emission_enabled = true
				mat.emission = color_primary
				mat.emission_energy_multiplier = emission_energy
			else:
				mat.albedo_color = Color(0.3, 0.3, 0.4, 0.15)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.metallic = 0.1
			mat.roughness = 0.5
			cell.material_override = mat

			# Position in grid
			var offset_r := (col - 1) * CELL_SPACING * projectile_scale
			var offset_u := (row - 1) * CELL_SPACING * projectile_scale
			cell.position = right * offset_r + up * offset_u
			add_child(cell)
			_cell_meshes.append(cell)

func _build_collision() -> void:
	# Only alive cells get collision
	var forward := direction.normalized()
	var right: Vector3
	var up: Vector3
	if abs(forward.dot(Vector3.UP)) < 0.99:
		right = forward.cross(Vector3.UP).normalized()
	else:
		right = forward.cross(Vector3.RIGHT).normalized()
	up = right.cross(forward).normalized()

	for row in GRID_SIZE:
		for col in GRID_SIZE:
			var idx := row * GRID_SIZE + col
			if not _alive_cells[idx]:
				continue
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3.ONE * 0.04 * projectile_scale
			shape.shape = box
			var offset_r := (col - 1) * CELL_SPACING * projectile_scale
			var offset_u := (row - 1) * CELL_SPACING * projectile_scale
			shape.position = right * offset_r + up * offset_u
			add_child(shape)

func _update_trajectory(_delta: float) -> void:
	# Keep grid formation — no extra movement
	pass

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

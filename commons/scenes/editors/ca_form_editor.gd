# ca_form_editor.gd — 3D cellular automata
#
# Initializes a 3D boolean grid with random fill, runs CA generations
# using birth/survive neighbor rules, then renders alive cells as
# a MultiMesh of colored cubes.

extends BaseGeometryEditor

func _get_editor_name() -> String: return "Cellular Automata 3D"

func _get_parameter_groups() -> Array:
	return [
		{"name": "Grid", "params": [
			{"id": "grid_size", "label": "Size", "min": 4.0, "max": 18.0, "step": 2.0, "default": 10.0},
			{"id": "fill_chance", "label": "Fill %", "min": 0.1, "max": 0.6, "step": 0.05, "default": 0.3},
			{"id": "seed", "label": "Seed", "min": 0.0, "max": 9999.0, "step": 1.0, "default": 42.0},
		]},
		{"name": "Rules", "params": [
			{"id": "generations", "label": "Generations", "min": 1.0, "max": 20.0, "step": 1.0, "default": 5.0},
			{"id": "birth_min", "label": "Birth Min", "min": 1.0, "max": 10.0, "step": 1.0, "default": 5.0},
			{"id": "birth_max", "label": "Birth Max", "min": 1.0, "max": 12.0, "step": 1.0, "default": 7.0},
			{"id": "survive_min", "label": "Survive Min", "min": 1.0, "max": 10.0, "step": 1.0, "default": 4.0},
			{"id": "survive_max", "label": "Survive Max", "min": 1.0, "max": 12.0, "step": 1.0, "default": 6.0},
		]},
	]

func _rebuild() -> void:
	_clear_content()
	var gs: int = int(p("grid_size", 10))
	var fill: float = p("fill_chance", 0.3)
	var gens: int = int(p("generations", 5))
	var b_min: int = int(p("birth_min", 5))
	var b_max: int = int(p("birth_max", 7))
	var s_min: int = int(p("survive_min", 4))
	var s_max: int = int(p("survive_max", 6))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p("seed", 42))

	# Initialize grid
	var grid: Array = []
	for x in gs:
		var plane_arr: Array = []
		for y in gs:
			var row: Array = []
			for z in gs:
				row.append(rng.randf() < fill)
			plane_arr.append(row)
		grid.append(plane_arr)

	# Run CA generations
	for _gen in gens:
		var new_grid: Array = []
		for x in gs:
			var plane_arr: Array = []
			for y in gs:
				var row: Array = []
				for z in gs:
					var neighbors: int = 0
					for dx in range(-1, 2):
						for dy in range(-1, 2):
							for dz in range(-1, 2):
								if dx == 0 and dy == 0 and dz == 0:
									continue
								var nx: int = x + dx
								var ny: int = y + dy
								var nz: int = z + dz
								if nx >= 0 and nx < gs and ny >= 0 and ny < gs and nz >= 0 and nz < gs:
									if grid[nx][ny][nz]:
										neighbors += 1
					var alive: bool = grid[x][y][z]
					if alive:
						row.append(neighbors >= s_min and neighbors <= s_max)
					else:
						row.append(neighbors >= b_min and neighbors <= b_max)
				plane_arr.append(row)
			new_grid.append(plane_arr)
		grid = new_grid

	# Render alive cells as MultiMesh cubes
	var alive_positions: Array[Vector3] = []
	var cell_size: float = 2.0 / float(gs)
	var offset := Vector3(-1.0, -1.0, -1.0) + Vector3(cell_size, cell_size, cell_size) * 0.5
	for x in gs:
		for y in gs:
			for z in gs:
				if grid[x][y][z]:
					alive_positions.append(offset + Vector3(x, y, z) * cell_size)

	if alive_positions.is_empty():
		return

	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * cell_size * 0.9
	var transforms: Array = []
	var colors: Array = []
	for pos in alive_positions:
		transforms.append(Transform3D(Basis.IDENTITY, pos))
		var t: float = (pos.y + 1.0) / 2.0
		colors.append(Color(0.3, 0.5, 0.8).lerp(Color(0.8, 0.4, 0.3), t))

	var mmi := MorphoPrimitive.multimesh_scatter(cube, transforms, colors)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.6
	mmi.material_override = mat
	content_root.add_child(mmi)

	if info_label:
		info_label.text = "CA 3D | %d cells alive / %d total | %d gen" % [alive_positions.size(), gs * gs * gs, gens]

# wfc_editor.gd — Wave Function Collapse tile layout editor
# Simplified 2D WFC on a grid with varying tile heights rendered as 3D boxes.
extends BaseGeometryEditor


func _get_editor_name() -> String:
	return "WFC"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Grid", "params": [
			{"id": "grid_size", "label": "Grid Size", "min": 3.0, "max": 10.0, "step": 1.0, "default": 6.0},
			{"id": "tile_types", "label": "Tile Types", "min": 2.0, "max": 5.0, "step": 1.0, "default": 3.0},
		]},
		{"name": "Appearance", "params": [
			{"id": "height_var", "label": "Height Var", "min": 0.0, "max": 1.5, "step": 0.05, "default": 0.4},
			{"id": "gap", "label": "Gap", "min": 0.0, "max": 0.15, "step": 0.01, "default": 0.03},
		]},
		{"name": "Generation", "params": [
			{"id": "seed", "label": "Seed", "min": 0.0, "max": 9999.0, "step": 1.0, "default": 42.0},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	var grid_size: int = clampi(int(p("grid_size", 6)), 3, 10)
	var tile_types: int = clampi(int(p("tile_types", 3)), 2, 5)
	var height_var: float = p("height_var", 0.4)
	var seed_val: int = int(p("seed", 42))
	var gap: float = p("gap", 0.03)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# ── WFC Algorithm ────────────────────────────────────────
	var total: int = grid_size * grid_size

	# Each cell stores an array of possible tile indices
	var possible: Array = []
	possible.resize(total)
	for i in total:
		var opts: Array[int] = []
		for t in tile_types:
			opts.append(t)
		possible[i] = opts

	var collapsed: Array[int] = []
	collapsed.resize(total)
	for i in total:
		collapsed[i] = -1

	var max_attempts: int = 10
	var attempt: int = 0
	var success: bool = false

	while attempt < max_attempts:
		attempt += 1
		# Reset
		for i in total:
			var opts: Array[int] = []
			for t in tile_types:
				opts.append(t)
			possible[i] = opts
			collapsed[i] = -1

		rng.seed = seed_val + attempt - 1
		var failed: bool = false

		# Collapse loop
		for _iteration in total:
			# Find cell with minimum entropy (not yet collapsed)
			var min_entropy: int = tile_types + 1
			var min_idx: int = -1
			for i in total:
				if collapsed[i] != -1:
					continue
				var opts: Array = possible[i] as Array
				if opts.size() < min_entropy:
					min_entropy = opts.size()
					min_idx = i
			if min_idx == -1:
				break  # All collapsed

			var opts: Array = possible[min_idx] as Array
			if opts.is_empty():
				failed = true
				break

			# Collapse: pick random from possible
			var choice: int = opts[rng.randi_range(0, opts.size() - 1)] as int
			collapsed[min_idx] = choice
			possible[min_idx] = [choice]

			# Propagate to neighbors
			var cx: int = min_idx % grid_size
			var cz: int = min_idx / grid_size
			var neighbors: Array[int] = []
			if cx > 0:
				neighbors.append(min_idx - 1)
			if cx < grid_size - 1:
				neighbors.append(min_idx + 1)
			if cz > 0:
				neighbors.append(min_idx - grid_size)
			if cz < grid_size - 1:
				neighbors.append(min_idx + grid_size)

			for ni: int in neighbors:
				if collapsed[ni] != -1:
					continue
				var n_opts: Array = possible[ni] as Array
				var filtered: Array[int] = []
				for opt: int in n_opts:
					# Adjacency rule: tile values must differ by at most 1
					if absi(opt - choice) <= 1:
						filtered.append(opt)
				if filtered.is_empty():
					failed = true
					break
				possible[ni] = filtered

			if failed:
				break

		if not failed:
			success = true
			break

	# Fill any uncollapsed cells with 0
	if not success:
		for i in total:
			if collapsed[i] == -1:
				collapsed[i] = 0

	# ── Render ────────────────────────────────────────────────
	var tile_colors: Array[Color] = [
		Color(0.3, 0.5, 0.85),   # Blue
		Color(0.35, 0.75, 0.4),  # Green
		Color(0.9, 0.7, 0.2),    # Amber
		Color(0.85, 0.3, 0.3),   # Red
		Color(0.65, 0.35, 0.8),  # Purple
	]

	var cell_size: float = 1.0 / float(grid_size)
	var base_height: float = 0.15
	var offset: float = float(grid_size) * cell_size * 0.5

	for z in grid_size:
		for x in grid_size:
			var idx: int = z * grid_size + x
			var tile_val: int = collapsed[idx]
			var h: float = base_height + float(tile_val) * height_var

			var box := BoxMesh.new()
			box.size = Vector3(cell_size - gap, h, cell_size - gap)

			var mat := StandardMaterial3D.new()
			mat.albedo_color = tile_colors[tile_val % tile_colors.size()]
			mat.roughness = 0.6
			mat.metallic = 0.1

			var mi := MeshInstance3D.new()
			mi.mesh = box
			mi.material_override = mat
			mi.position = Vector3(
				float(x) * cell_size - offset + cell_size * 0.5,
				h * 0.5,
				float(z) * cell_size - offset + cell_size * 0.5
			)
			content_root.add_child(mi)

	info_label.text = "WFC %dx%d | %d types | seed=%d%s" % [
		grid_size, grid_size, tile_types, seed_val,
		"" if success else " (fallback)"
	]

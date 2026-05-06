# ca_surface.gd
# Seq 9: cellular automata. Patches of moss-tiles grown by a Game-of-Life-like
# rule on a grid around the map. First LIVING surface — local rules, emergence.

extends Node3D


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var tile_size: float = float(params.get("tile_size", 0.4))
	var iterations: int = int(params.get("iterations", 4))

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	var ca_w: int = 48
	var ca_d: int = 48
	var rng := RandomNumberGenerator.new()
	rng.seed = int(ctx.get("rng_seed", 0))

	# Seed with ~25% alive
	var cells: Array = []
	for x in ca_w:
		var row: Array = []
		for z in ca_d:
			row.append(1 if rng.randf() < 0.25 else 0)
		cells.append(row)

	# Run B3/S23 for a few iterations
	for _it in iterations:
		cells = _step_ca(cells, ca_w, ca_d)

	# Render live cells as small colored tiles around the grid
	var grid_half_x: float = float(grid_dims.x) * cube_size * 0.5
	var grid_half_z: float = float(grid_dims.z) * cube_size * 0.5
	var field_w: float = float(ca_w) * tile_size
	var field_d: float = float(ca_d) * tile_size

	for x in ca_w:
		for z in ca_d:
			if cells[x][z] == 0:
				continue
			var wx: float = -field_w * 0.5 + float(x) * tile_size
			var wz: float = -field_d * 0.5 + float(z) * tile_size
			# Skip inside grid footprint
			if absf(wx) < grid_half_x + 0.5 and absf(wz) < grid_half_z + 0.5:
				continue
			var tile := MeshInstance3D.new()
			var m := BoxMesh.new()
			m.size = Vector3(tile_size * 0.9, 0.05, tile_size * 0.9)
			tile.mesh = m
			tile.position = grid_center + Vector3(wx, 0.02, wz)
			var mat := StandardMaterial3D.new()
			# Moss-ish green, slightly varied
			var g: float = 0.4 + float((x + z) % 5) * 0.08
			var col := Color(0.15, g, 0.25)
			mat.albedo_color = col
			mat.emission_enabled = true
			mat.emission = col * 0.5
			mat.emission_energy_multiplier = 0.4
			tile.material_override = mat
			add_child(tile)


func _step_ca(cells: Array, w: int, d: int) -> Array:
	var out: Array = []
	for x in w:
		var row: Array = []
		for z in d:
			var n: int = _count_neighbors(cells, x, z, w, d)
			var alive: bool = cells[x][z] == 1
			var next: int = 0
			if alive and (n == 2 or n == 3): next = 1
			elif not alive and n == 3: next = 1
			row.append(next)
		out.append(row)
	return out


func _count_neighbors(cells: Array, x: int, z: int, w: int, d: int) -> int:
	var n: int = 0
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0: continue
			var nx: int = (x + dx + w) % w
			var nz: int = (z + dz + d) % d
			n += int(cells[nx][nz])
	return n

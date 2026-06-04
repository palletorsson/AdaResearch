# ca_surface.gd
# Seq 9: cellular automata. Patches of moss-tiles grown by a Game-of-Life-like
# rule on a grid around the map. First LIVING surface — local rules, emergence.
#
# RENDERING: ONE MultiMeshInstance3D — every live cell is an instance of a
# single shared box mesh/material, so a stabilized B3/S23 field (~450-800 live
# cells) costs ~1 draw call instead of hundreds. Per-cell colour variation
# rides use_colors + set_instance_color (vertex_color_use_as_albedo), matching
# the sibling-layer idiom (wave_displace / jitter_seed). VR-safe: expanded
# custom_aabb defeats frustum culling, gi_mode DISABLED. The CA stabilizes
# inside apply() and the field is static thereafter (no per-frame stepping in
# this layer), so the buffer is built once.

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

	# Render live cells as small colored tiles around the grid — collected into
	# one MultiMesh. Transforms place each cell; per-instance colour carries the
	# moss-green variation that used to live on per-cell unique materials.
	var grid_half_x: float = float(grid_dims.x) * cube_size * 0.5
	var grid_half_z: float = float(grid_dims.z) * cube_size * 0.5
	var field_w: float = float(ca_w) * tile_size
	var field_d: float = float(ca_d) * tile_size

	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for x in ca_w:
		for z in ca_d:
			if cells[x][z] == 0:
				continue
			var wx: float = -field_w * 0.5 + float(x) * tile_size
			var wz: float = -field_d * 0.5 + float(z) * tile_size
			# Skip inside grid footprint
			if absf(wx) < grid_half_x + 0.5 and absf(wz) < grid_half_z + 0.5:
				continue
			var pos: Vector3 = grid_center + Vector3(wx, 0.02, wz)
			transforms.append(Transform3D(Basis.IDENTITY, pos))
			# Moss-ish green, slightly varied (same formula as the old per-cell mat)
			var g: float = 0.4 + float((x + z) % 5) * 0.08
			colors.append(Color(0.15, g, 0.25))

	if transforms.is_empty():
		return

	# One shared box mesh + material for the whole field.
	var mesh := BoxMesh.new()
	mesh.size = Vector3(tile_size * 0.9, 0.05, tile_size * 0.9)
	mesh.surface_set_material(0, _tile_material())

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "MossField"
	mmi.multimesh = mm
	mmi.custom_aabb = AABB(Vector3(-30, -10, -30), Vector3(60, 30, 60))
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(mmi)


func _tile_material() -> StandardMaterial3D:
	# Per-instance colour (set via set_instance_color) carries the moss-green
	# variation the old per-cell StandardMaterial3D used to encode. Unshaded so
	# the tint is the final pixel at full strength — this reproduces the old
	# tiles' self-lit moss glow while keeping the colour TINTED per cell, rather
	# than white emission washing the tint out (see floating_primitives notes).
	# albedo_color stays white so instance colour multiplies through cleanly.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	return mat


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

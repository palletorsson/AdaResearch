# soft_body_shapes.gd — Factory + renderer for soft body simulations.
# Builds initial particle/spring configurations for common topologies,
# then renders the simulated result as an ArrayMesh or wireframe.
#
# Topologies:
#   cloth_grid    — M×N grid with structural + shear + bend springs
#   jelly_box     — 8 corner particles with all 28 pair springs (cube)
#   jelly_grid_3d — NxMxK dense grid with edge springs
#   blob          — sphere of particles with surface mesh triangles
#
# Rendering: cloth_grid → smooth triangle mesh, jelly → wire+sphere,
# blob → triangle sphere with displaced vertices.

extends RefCounted

const SoftBodySimScript = preload("res://commons/soft_body/soft_body_sim.gd")


# ─── Factories ────────────────────────────────────────────────

## Rectangular cloth grid with structural + shear springs.
## cols × rows particles covering cell_size × cell_size tiles.
## pin_top_corners / pin_top_row / pin_corners control anchoring.
static func make_cloth(cols: int, rows: int, cell_size: float,
		pin_mode: String = "top_corners",
		stiffness: float = 0.8,
		origin: Vector3 = Vector3.ZERO) -> RefCounted:
	var sim = SoftBodySimScript.new()
	sim.topology = "cloth_grid"
	sim.grid_cols = cols
	sim.grid_rows = rows
	sim.stiffness = stiffness

	# Create particles in a grid in the XY plane (before physics starts)
	# Cloth is oriented vertically — X horizontal, Y vertical, Z into page.
	for r in rows:
		for c in cols:
			var x: float = (float(c) - float(cols - 1) * 0.5) * cell_size
			var y: float = -float(r) * cell_size  # hangs down from y=0
			var pos: Vector3 = origin + Vector3(x, y, 0)
			var is_pin: bool = _cloth_is_pin(pin_mode, c, r, cols, rows)
			sim.add_particle(pos, is_pin)

	# Structural springs (horizontal + vertical)
	for r in rows:
		for c in cols:
			var idx: int = r * cols + c
			if c < cols - 1:
				sim.add_spring(idx, idx + 1)
			if r < rows - 1:
				sim.add_spring(idx, idx + cols)
	# Shear springs (diagonal) — prevent racking
	for r in rows - 1:
		for c in cols - 1:
			var idx: int = r * cols + c
			sim.add_spring(idx, idx + cols + 1)
			sim.add_spring(idx + 1, idx + cols)
	# Bend springs (every 2nd neighbour) — prevent folding onto itself
	for r in rows:
		for c in cols:
			var idx: int = r * cols + c
			if c < cols - 2:
				sim.add_spring(idx, idx + 2)
			if r < rows - 2:
				sim.add_spring(idx, idx + cols * 2)
	return sim


## Simple jelly cube — 8 corners + all pair springs.
static func make_jelly_box(size: float, stiffness: float = 0.9,
		origin: Vector3 = Vector3.ZERO) -> RefCounted:
	var sim = SoftBodySimScript.new()
	sim.topology = "jelly_box"
	sim.stiffness = stiffness
	var h: float = size * 0.5
	for z in [-1, 1]:
		for y in [-1, 1]:
			for x in [-1, 1]:
				sim.add_particle(origin + Vector3(x * h, y * h + size, z * h), false)
	# All 28 pair springs (8 choose 2)
	for i in range(8):
		for j in range(i + 1, 8):
			sim.add_spring(i, j)
	return sim


## Dense 3D grid of jelly particles — more cells = more flexible.
static func make_jelly_grid(nx: int, ny: int, nz: int, cell: float,
		stiffness: float = 0.7,
		origin: Vector3 = Vector3.ZERO) -> RefCounted:
	var sim = SoftBodySimScript.new()
	sim.topology = "jelly_grid_3d"
	sim.stiffness = stiffness
	var ox: float = -float(nx - 1) * 0.5 * cell
	var oz: float = -float(nz - 1) * 0.5 * cell
	for z in nz:
		for y in ny:
			for x in nx:
				var pos: Vector3 = origin + Vector3(
					ox + float(x) * cell,
					float(y) * cell + cell * float(ny),
					oz + float(z) * cell,
				)
				sim.add_particle(pos, false)
	# Edge springs + face diagonals
	var stride_z: int = nx * ny
	for z in nz:
		for y in ny:
			for x in nx:
				var idx: int = z * stride_z + y * nx + x
				if x < nx - 1: sim.add_spring(idx, idx + 1)
				if y < ny - 1: sim.add_spring(idx, idx + nx)
				if z < nz - 1: sim.add_spring(idx, idx + stride_z)
				# Face diagonals for stiffness
				if x < nx - 1 and y < ny - 1:
					sim.add_spring(idx, idx + nx + 1)
				if x < nx - 1 and z < nz - 1:
					sim.add_spring(idx, idx + stride_z + 1)
				if y < ny - 1 and z < nz - 1:
					sim.add_spring(idx, idx + stride_z + nx)
	return sim


static func _cloth_is_pin(mode: String, c: int, r: int, cols: int, rows: int) -> bool:
	match mode:
		"none":           return false
		"top_corners":    return r == 0 and (c == 0 or c == cols - 1)
		"top_row":        return r == 0
		"four_corners":   return (r == 0 or r == rows - 1) and (c == 0 or c == cols - 1)
		"left_column":    return c == 0
		"top_and_left":   return r == 0 or c == 0
	return false


# ─── Rendering ─────────────────────────────────────────────────

## Render simulation state as a Node3D. Returns a parent with meshes.
static func to_node3d(sim, cfg: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "SoftBody"
	var color_arr = cfg.get("color", [0.85, 0.35, 0.45])
	var color := Color(float(color_arr[0]), float(color_arr[1]), float(color_arr[2]))
	var show_wires: bool = bool(cfg.get("show_wires", false))
	var wire_color_arr = cfg.get("wire_color", [0.15, 0.12, 0.1])
	var wire_color := Color(float(wire_color_arr[0]), float(wire_color_arr[1]), float(wire_color_arr[2]))
	var roughness: float = float(cfg.get("roughness", 0.55))
	var double_sided: bool = bool(cfg.get("double_sided", true))

	match sim.topology:
		"cloth_grid":
			var mi := _cloth_mesh(sim, color, roughness, double_sided)
			root.add_child(mi)
		"jelly_box", "jelly_grid_3d", "blob", "generic":
			# Draw spheres at particles
			var sphere_mi := _particle_spheres(sim, color, roughness,
				float(cfg.get("particle_radius", 0.06)))
			root.add_child(sphere_mi)
			# Optionally draw wires along springs
			if show_wires:
				var wires := _spring_wires(sim, wire_color)
				root.add_child(wires)
	return root


static func _cloth_mesh(sim, color: Color, roughness: float, double_sided: bool) -> MeshInstance3D:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var cols: int = sim.grid_cols
	var rows: int = sim.grid_rows
	for i in sim.positions.size():
		verts.append(sim.positions[i])
		normals.append(Vector3.UP)   # recomputed below
	for r in rows - 1:
		for c in cols - 1:
			var i0: int = r * cols + c
			var i1: int = r * cols + c + 1
			var i2: int = (r + 1) * cols + c + 1
			var i3: int = (r + 1) * cols + c
			indices.append_array([i0, i1, i2, i0, i2, i3])
	_recompute_normals(verts, indices, normals)
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.0
	if double_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	return mi


static func _particle_spheres(sim, color: Color, roughness: float, radius: float) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 10
	sphere_mesh.rings = 5
	mm.mesh = sphere_mesh
	mm.instance_count = sim.positions.size()
	for i in sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = sim.positions[i]
		mm.set_instance_transform(i, t)
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mmi.material_override = mat
	return mmi


static func _spring_wires(sim, color: Color) -> MeshInstance3D:
	var root := Node3D.new()
	root.name = "Wires"
	var wires_mi := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	for s in sim.springs:
		var a: int = s[0]
		var b: int = s[1]
		im.surface_add_vertex(sim.positions[a])
		im.surface_add_vertex(sim.positions[b])
	im.surface_end()
	wires_mi.mesh = im
	return wires_mi


static func _recompute_normals(verts: PackedVector3Array, indices: PackedInt32Array,
		out_normals: PackedVector3Array) -> void:
	for i in out_normals.size():
		out_normals[i] = Vector3.ZERO
	var tri_count: int = indices.size() / 3
	for k in tri_count:
		var ia: int = indices[k * 3]
		var ib: int = indices[k * 3 + 1]
		var ic: int = indices[k * 3 + 2]
		var a: Vector3 = verts[ia]
		var b: Vector3 = verts[ib]
		var c: Vector3 = verts[ic]
		var n: Vector3 = (b - a).cross(c - a)
		if n.length_squared() > 1e-12:
			n = n.normalized()
		out_normals[ia] = out_normals[ia] + n
		out_normals[ib] = out_normals[ib] + n
		out_normals[ic] = out_normals[ic] + n
	for i in out_normals.size():
		var nn: Vector3 = out_normals[i]
		out_normals[i] = nn.normalized() if nn.length_squared() > 1e-12 else Vector3.UP

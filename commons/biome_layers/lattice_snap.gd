# lattice_snap.gd
# Seq 5: array_tutorial. Foregrounds the grid — a visible wireframe cubic
# lattice overlay around the map. The array becomes subject.

extends Node3D


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var spacing: float = float(params.get("spacing", 1.5))
	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	var bounds: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.7 + 10.0
	var grid_half_x: float = float(grid_dims.x) * cube_size * 0.5
	var grid_half_z: float = float(grid_dims.z) * cube_size * 0.5

	# Cubic wireframe cells in 3 vertical layers around the grid.
	var steps: int = int(ceilf(bounds / spacing))
	for ix in range(-steps, steps + 1):
		for iy in [0, 1, 2]:
			for iz in range(-steps, steps + 1):
				var x: float = float(ix) * spacing
				var z: float = float(iz) * spacing
				# Skip inside grid footprint
				if absf(x) < grid_half_x + spacing and absf(z) < grid_half_z + spacing:
					continue
				# Draw wireframe at (ix + iz) % 3 == iy — staircase rhythm
				if (ix + iz + iy * 2) % 3 != 0:
					continue
				var cell := _build_wire_cube(spacing * 0.9)
				cell.position = grid_center + Vector3(x, 0.5 + float(iy) * spacing, z)
				add_child(cell)


func _build_wire_cube(size: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	var s: float = size * 0.5
	var corners: Array = [
		Vector3(-s, -s, -s), Vector3(s, -s, -s), Vector3(s, s, -s), Vector3(-s, s, -s),
		Vector3(-s, -s, s),  Vector3(s, -s, s),  Vector3(s, s, s),  Vector3(-s, s, s),
	]
	var edges: Array = [
		[0,1],[1,2],[2,3],[3,0],  # bottom
		[4,5],[5,6],[6,7],[7,4],  # top
		[0,4],[1,5],[2,6],[3,7],  # verticals
	]
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for e in edges:
		im.surface_add_vertex(corners[e[0]])
		im.surface_add_vertex(corners[e[1]])
	im.surface_end()
	mi.mesh = im

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.9, 0.4, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.4, 1.0)
	mat.emission_energy_multiplier = 1.0
	mi.material_override = mat
	return mi

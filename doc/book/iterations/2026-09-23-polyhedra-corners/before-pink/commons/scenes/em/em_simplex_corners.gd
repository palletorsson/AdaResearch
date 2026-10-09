extends RefCounted
## Opt-in right tetrahedra fitted to existing, perpendicular museum walls.
## Four vertices: the floor corner and one intercept on each inward axis.
## Unlike a regular tetrahedron, three faces meet flush with the room envelope.

static func install(seg: Node3D, declarations: Array, tile: Array, material: Material,
		height: float, z_offset: int) -> Array:
	var blocked: Array = []
	var keep_out: Array = []
	var group := Node3D.new()
	group.name = "SimplexCorners"
	seg.add_child(group)
	for raw in declarations:
		if not raw is Dictionary: continue
		var corner: Array = raw.get("corner", [])
		var inward: Array = raw.get("inward", [])
		if corner.size() != 2 or inward.size() != 2: continue
		var sx := int(inward[0])
		var sz := int(inward[1])
		var reach := float(raw.get("reach_m", 1.5))
		if absi(sx) != 1 or absi(sz) != 1 or not is_finite(reach) or reach < 0.25 or reach > 3.0: continue
		var origin := Vector2(float(corner[0]), float(corner[1]))
		if not _fits_corner(tile, origin, sx, sz, reach):
			push_warning("Simplex corner does not meet two continuous walls: " + str(raw.get("name", corner)))
			continue
		var points := PackedVector3Array([Vector3.ZERO, Vector3(sx * reach, 0, 0),
			Vector3(0, 0, sz * reach), Vector3(0, height, 0)])
		var body := StaticBody3D.new()
		body.name = str(raw.get("name", "Corner"))
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Vector3(origin.x, 0, origin.y + z_offset)
		body.set_meta("reach_m", reach)
		body.set_meta("inward", inward)
		body.set_meta("map_corner", corner)
		group.add_child(body)
		var visual := MeshInstance3D.new()
		visual.name = "ClosedTetrahedron"
		visual.mesh = _mesh(points)
		visual.material_override = material
		body.add_child(visual)
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		var collision := CollisionShape3D.new()
		collision.name = "SolidBackfill"
		collision.shape = shape
		body.add_child(collision)
		var lo := origin + Vector2(minf(0, sx * reach), minf(0, sz * reach))
		var hi := lo + Vector2(reach, reach)
		# Suppress attached trim/props behind the fill, without removing a ceiling.
		keep_out.append(Rect2(lo + Vector2(-0.04, z_offset - 0.04), Vector2(reach + 0.08, reach + 0.08)))
		for z in range(int(floor(lo.y)), int(ceil(hi.y))):
			for x in range(int(floor(lo.x)), int(ceil(hi.x))):
				var dx := (x + 0.5 - origin.x) * sx
				var dz := (z + 0.5 - origin.y) * sz
				# Conservative floor navigation for a body of radius 0.25 m.
				if dx + dz <= reach + 0.25 * sqrt(2.0):
					var cell := Vector2i(x, z)
					if not blocked.has(cell): blocked.append(cell)
	seg.set_meta("em_simplex_keep_out", keep_out)
	seg.set_meta("em_simplex_blocked_cells", blocked)
	return blocked

static func _cell(tile: Array, p: Vector2) -> String:
	var x := int(floor(p.x))
	var z := int(floor(p.y))
	if z < 0 or z >= tile.size() or x < 0 or x >= tile[z].size(): return ""
	return str(tile[z][x])

static func _fits_corner(tile: Array, origin: Vector2, sx: int, sz: int, reach: float) -> bool:
	# Refuse a missing backing wall or a doorway, including a partial span.
	var samples := maxi(2, int(ceil(reach / 0.1)))
	for i in range(samples):
		var d := (i + 0.5) * reach / samples
		if _cell(tile, origin + Vector2(-sx * 0.05, sz * d)) != "4": return false
		if _cell(tile, origin + Vector2(sx * d, -sz * 0.05)) != "4": return false
		if _cell(tile, origin + Vector2(sx * d, sz * 0.05)) != "1": return false
		if _cell(tile, origin + Vector2(sx * 0.05, sz * d)) != "1": return false
	return true

static func _mesh(points: PackedVector3Array) -> ArrayMesh:
	var centre := (points[0] + points[1] + points[2] + points[3]) / 4.0
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]:
		var a: Vector3 = points[face[0]]
		var b: Vector3 = points[face[1]]
		var c: Vector3 = points[face[2]]
		var normal := (b - a).cross(c - a).normalized()
		# Godot fronts are clockwise. Keep an outward lighting normal and
		# choose winding independently, also for the mirrored corner fits.
		if normal.dot((a + b + c) / 3.0 - centre) > 0.0:
			var tmp := b
			b = c
			c = tmp
		else:
			normal = -normal
		for p in [a, b, c]:
			surface.set_normal(normal)
			surface.set_uv(Vector2(p.x + p.z, p.y))
			surface.add_vertex(p)
	return surface.commit()

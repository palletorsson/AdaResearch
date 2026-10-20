extends RefCounted
## Solid diagonal paint cut into the mesh. The same vertex colours export to GLB.
## Collision keeps the original solid; paint adds no surfaces outside its boundary.

static func material() -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.vertex_color_use_as_albedo = true
	result.roughness = 0.86
	return result

static func mesh(source: Mesh, band_width := 0.22) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var direction := Vector3(1.0, 0.85, 0.35).normalized()
	for s in range(source.get_surface_count()):
		var arrays: Array = source.surface_get_arrays(s)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices := PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: indices=arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for i in range(points.size()): indices.append(i)
		for i in range(0, indices.size(), 3):
			var triangle := PackedVector3Array([points[indices[i]], points[indices[i+1]], points[indices[i+2]]])
			var normal := normals[indices[i]] if not normals.is_empty() else (triangle[2]-triangle[0]).cross(triangle[1]-triangle[0]).normalized()
			var low := minf(direction.dot(triangle[0]), minf(direction.dot(triangle[1]), direction.dot(triangle[2])))
			var high := maxf(direction.dot(triangle[0]), maxf(direction.dot(triangle[1]), direction.dot(triangle[2])))
			for band in range(floori(low / band_width), floori(high / band_width)+1):
				var polygon := clip(clip(triangle, direction, band*band_width, true), direction, (band+1)*band_width, false)
				var colour := Color("e7ba4d") if posmod(band, 2)==0 else Color("292d31")
				for v in range(1, polygon.size()-1):
					if (polygon[v]-polygon[0]).cross(polygon[v+1]-polygon[0]).length_squared()<0.00000001: continue
					for point in [polygon[0], polygon[v], polygon[v+1]]:
						surface.set_normal(normal)
						surface.set_color(colour)
						surface.add_vertex(point)
	return surface.commit()

static func clip(polygon: PackedVector3Array, direction: Vector3, boundary: float, above: bool) -> PackedVector3Array:
	var result := PackedVector3Array()
	if polygon.is_empty(): return result
	var previous := polygon[-1]
	var previous_distance := direction.dot(previous)-boundary
	for point in polygon:
		var distance := direction.dot(point)-boundary
		var inside := distance>=0 if above else distance<=0
		var was_inside := previous_distance>=0 if above else previous_distance<=0
		if inside!=was_inside:
			result.append(previous.lerp(point, previous_distance/(previous_distance-distance)))
		if inside: result.append(point)
		previous=point
		previous_distance=distance
	return result

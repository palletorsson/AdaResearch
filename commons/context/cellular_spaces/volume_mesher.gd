extends RefCounted
## Marching tetrahedra. Shared lattice samples and a consistent cube split
## avoid cracks and ambiguous faces; SurfaceTool welds smooth shading normals.

const CORNERS := [Vector3i(0,0,0), Vector3i(1,0,0), Vector3i(1,1,0), Vector3i(0,1,0),
	Vector3i(0,0,1), Vector3i(1,0,1), Vector3i(1,1,1), Vector3i(0,1,1)]
const TETS := [[0,5,1,6], [0,1,2,6], [0,2,3,6], [0,3,7,6], [0,7,4,6], [0,4,5,6]]

static func build(field: Callable, bounds: AABB, step: float) -> ArrayMesh:
	var size := Vector3i(ceil(bounds.size.x / step), ceil(bounds.size.y / step), ceil(bounds.size.z / step))
	var spacing := bounds.size / Vector3(size)
	var nx := size.x + 1
	var ny := size.y + 1
	var samples := PackedFloat32Array()
	samples.resize(nx * ny * (size.z + 1))
	for z in range(size.z + 1):
		for y in range(ny):
			for x in range(nx):
				samples[x + nx * (y + ny * z)] = field.call(bounds.position + Vector3(x, y, z) * spacing)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(0)
	var points := PackedVector3Array()
	var values := PackedFloat32Array()
	points.resize(8)
	values.resize(8)
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				var negative := 0
				for c in range(8):
					var index: Vector3i = Vector3i(x, y, z) + CORNERS[c]
					values[c] = samples[index.x + nx * (index.y + ny * index.z)]
					if values[c] < 0.0:
						negative += 1
				if negative == 0 or negative == 8:
					continue
				for c in range(8):
					points[c] = bounds.position + Vector3(Vector3i(x, y, z) + CORNERS[c]) * spacing
				for tet in TETS:
					_polygonize(tool, tet, points, values)
	tool.index()
	tool.generate_normals()
	return tool.commit()

static func _polygonize(tool: SurfaceTool, tet: Array, points: PackedVector3Array, values: PackedFloat32Array) -> void:
	var inside: Array[int] = []
	var outside: Array[int] = []
	var inward := Vector3.ZERO
	var outward := Vector3.ZERO
	for i in tet:
		if values[i] < 0:
			inside.append(i)
			inward += points[i]
		else:
			outside.append(i)
			outward += points[i]
	if inside.is_empty() or outside.is_empty():
		return
	var normal := outward / outside.size() - inward / inside.size()
	if inside.size() == 1:
		_triangle(tool, _edge(inside[0], outside[0], points, values),
			_edge(inside[0], outside[1], points, values), _edge(inside[0], outside[2], points, values), normal)
	elif outside.size() == 1:
		_triangle(tool, _edge(outside[0], inside[0], points, values),
			_edge(outside[0], inside[1], points, values), _edge(outside[0], inside[2], points, values), normal)
	else:
		var a := _edge(inside[0], outside[0], points, values)
		var b := _edge(inside[0], outside[1], points, values)
		var c := _edge(inside[1], outside[0], points, values)
		var d := _edge(inside[1], outside[1], points, values)
		_triangle(tool, a, b, c, normal)
		_triangle(tool, b, d, c, normal)

static func _edge(a: int, b: int, points: PackedVector3Array, values: PackedFloat32Array) -> Vector3:
	# Always interpolate from the negative endpoint. Neighbouring tetrahedra
	# otherwise round the same edge differently, preventing exact vertex welds.
	if values[a] > values[b]:
		return points[b].lerp(points[a], values[b] / (values[b] - values[a]))
	return points[a].lerp(points[b], values[a] / (values[a] - values[b]))

static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var cross_product := (b - a).cross(c - a)
	if cross_product.length_squared() < 0.000000000001:
		return
	tool.add_vertex(a)
	# Godot front faces wind clockwise when viewed from outside the solid.
	if cross_product.dot(outward) > 0.0:
		tool.add_vertex(c)
		tool.add_vertex(b)
	else:
		tool.add_vertex(b)
		tool.add_vertex(c)

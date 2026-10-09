extends RefCounted
## A stroke is one connected sweep, with width and twist measured along its length.
## Godot front faces use clockwise winding; _triangle enforces that convention.

const LENGTH_EPS := 0.000001
const AREA_SQUARED_EPS := 1.0e-20


static func clean_points(points: PackedVector3Array) -> PackedVector3Array:
	var clean := PackedVector3Array()
	for point in points:
		if not point.is_finite():
			continue
		if clean.is_empty() or point.distance_squared_to(clean[-1]) > LENGTH_EPS * LENGTH_EPS:
			clean.append(point)
	return clean


static func resample(points: PackedVector3Array, spacing: float = 0.06) -> PackedVector3Array:
	## Uniform distances along the polyline, retaining both endpoints. A shorter final
	## interval is intentional: spacing is a distance, not an input sample count.
	var clean := clean_points(points)
	if clean.size() < 2:
		return clean
	if not is_finite(spacing) or spacing <= LENGTH_EPS:
		spacing = 0.06
	var lengths := _arc_lengths(clean)
	var total: float = lengths[-1]
	# Keep malformed caller input from requesting unbounded allocations.
	spacing = maxf(spacing, total / 65535.0)
	var result := PackedVector3Array([clean[0]])
	var segment := 1
	var distance := spacing
	while distance < total - LENGTH_EPS:
		while segment < clean.size() - 1 and lengths[segment] < distance:
			segment += 1
		var segment_length: float = lengths[segment] - lengths[segment - 1]
		var fraction: float = (distance - lengths[segment - 1]) / segment_length
		result.append(clean[segment - 1].lerp(clean[segment], fraction))
		distance += spacing
	result.append(clean[-1])
	return clean_points(result)


static func frames(points: PackedVector3Array) -> Array:
	## One orthonormal frame per CLEANED point. Opposite tangents have no unique
	## minimal rotation: carry the previous side through that cusp deterministically.
	var clean := clean_points(points)
	var result: Array = []
	if clean.size() < 2:
		return result
	var lengths := _arc_lengths(clean)
	var previous_tangent := Vector3.ZERO
	var side := Vector3.ZERO
	for index in clean.size():
		var tangent: Vector3
		if index == 0:
			tangent = (clean[1] - clean[0]).normalized()
		elif index == clean.size() - 1:
			tangent = (clean[index] - clean[index - 1]).normalized()
		else:
			var incoming := (clean[index] - clean[index - 1]).normalized()
			var outgoing := (clean[index + 1] - clean[index]).normalized()
			var average := incoming + outgoing
			tangent = average.normalized() if average.length_squared() > LENGTH_EPS * LENGTH_EPS else outgoing
		if index == 0:
			side = _initial_side(tangent)
		else:
			var axis := previous_tangent.cross(tangent)
			var sine := axis.length()
			var cosine := clampf(previous_tangent.dot(tangent), -1.0, 1.0)
			if sine > LENGTH_EPS:
				side = side.rotated(axis / sine, atan2(sine, cosine))
			# Also removes floating point drift after many transported frames.
			side = side - tangent * side.dot(tangent)
			if side.length_squared() <= LENGTH_EPS * LENGTH_EPS:
				side = _initial_side(tangent)
			else:
				side = side.normalized()
		var normal := tangent.cross(side).normalized()
		result.append({
			"tangent": tangent, "side": side, "normal": normal,
			"arc_length": lengths[index], "u": lengths[index] / lengths[-1]
		})
		previous_tangent = tangent
	return result


static func build_mesh(points: PackedVector3Array, options: Dictionary = {}) -> ArrayMesh:
	## width is the FULL ribbon width or tube diameter, in metres.
	## taper 0..1, twist total radians, sides 3..64; tube ends are capped by default.
	var mesh := ArrayMesh.new()
	var clean := clean_points(points)
	if clean.size() < 2:
		return mesh
	var width := float(options.get("width", 0.25))
	var taper := float(options.get("taper", 0.0))
	var twist := float(options.get("twist", 0.0))
	width = maxf(width, 0.0001) if is_finite(width) else 0.25
	taper = clampf(taper, 0.0, 1.0) if is_finite(taper) else 0.0
	twist = twist if is_finite(twist) else 0.0
	var tube := str(options.get("shape", "ribbon")) == "tube"
	var sides := clampi(int(options.get("sides", 8)), 3, 64)
	var transported := frames(clean)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var stride: int = sides + 1 if tube else 2
	for index in clean.size():
		var frame: Dictionary = transported[index]
		var tangent: Vector3 = frame.tangent
		var u: float = frame.u
		var side: Vector3 = frame.side
		side = side.rotated(tangent, twist * u)
		var normal := tangent.cross(side).normalized()
		# The 4% floor avoids collapsed endpoint rings and degenerate triangles.
		var radius := width * 0.5 * lerpf(1.0, maxf(0.04, sin(PI * u)), taper)
		if tube:
			for radial_index in sides + 1:
				var around := float(radial_index) / float(sides)
				var radial := side * cos(TAU * around) + normal * sin(TAU * around)
				vertices.append(clean[index] + radius * radial)
				normals.append(radial.normalized())
				uvs.append(Vector2(around, u))
		else:
			vertices.append(clean[index] - radius * side)
			vertices.append(clean[index] + radius * side)
			normals.append(normal)
			normals.append(normal)
			uvs.append(Vector2(0.0, u))
			uvs.append(Vector2(1.0, u))
	for index in clean.size() - 1:
		for column in stride - 1:
			var a := index * stride + column
			var b := a + 1
			var c := a + stride
			var d := c + 1
			_triangle(indices, vertices, normals, a, b, c)
			_triangle(indices, vertices, normals, b, d, c)
	if tube and bool(options.get("caps", true)):
		_cap(vertices, normals, uvs, indices, clean[0], -Vector3(transported[0].tangent), 0, sides)
		_cap(vertices, normals, uvs, indices, clean[-1], Vector3(transported[-1].tangent), (clean.size() - 1) * stride, sides)
	if indices.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _arc_lengths(points: PackedVector3Array) -> PackedFloat64Array:
	var lengths := PackedFloat64Array([0.0])
	for index in range(1, points.size()):
		lengths.append(lengths[-1] + points[index - 1].distance_to(points[index]))
	return lengths


static func _initial_side(tangent: Vector3) -> Vector3:
	var hint := Vector3.RIGHT
	if absf(tangent.dot(hint)) > 0.95:
		# Choose the least parallel axis only when the preferred RIGHT is unstable.
		hint = Vector3.UP if absf(tangent.y) <= absf(tangent.z) else Vector3.BACK
	return (hint - tangent * hint.dot(tangent)).normalized()


static func _triangle(indices: PackedInt32Array, vertices: PackedVector3Array, normals: PackedVector3Array, a: int, b: int, c: int) -> void:
	var clockwise_normal := (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a])
	if not clockwise_normal.is_finite() or clockwise_normal.length_squared() <= AREA_SQUARED_EPS:
		return
	var outward := normals[a] + normals[b] + normals[c]
	if outward.length_squared() < LENGTH_EPS * LENGTH_EPS:
		outward = normals[a]
	indices.append(a)
	if clockwise_normal.dot(outward) < 0.0:
		indices.append(c)
		indices.append(b)
	else:
		indices.append(b)
		indices.append(c)


static func _cap(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, center: Vector3, normal: Vector3, ring_start: int, sides: int) -> void:
	# Duplicate vertices at the rim: caps are flat and must not round the side normals.
	var center_index := vertices.size()
	vertices.append(center)
	normals.append(normal)
	uvs.append(Vector2(0.5, 0.5))
	for radial_index in sides + 1:
		var angle := TAU * float(radial_index) / float(sides)
		vertices.append(vertices[ring_start + radial_index])
		normals.append(normal)
		uvs.append(Vector2(0.5, 0.5) + 0.5 * Vector2(cos(angle), sin(angle)))
	for radial_index in sides:
		_triangle(indices, vertices, normals, center_index, center_index + 1 + radial_index, center_index + 2 + radial_index)

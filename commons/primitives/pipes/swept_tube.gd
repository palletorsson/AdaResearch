extends RefCounted
## A sampled centreline becomes a ring strip. Frame transport is supplied plumbing;
## radius, ring sides and the two triangles between neighbours are the first edits.
const RADII := [0.025, 0.065, 0.12]
const SIDE_COUNTS := [6, 12, 24]
const SAMPLE_SPACING := 0.045
const MAX_POINTS := 256
const MAX_STROKES := 8

static func build(path: PackedVector3Array, radius: float, sides: int, wall := 0.0) -> Dictionary:
	var points := PackedVector3Array()
	for p in path:
		if not p.is_finite(): continue
		if points.is_empty() or p.distance_to(points[-1]) > 0.0001: points.append(p)
	if points.size() < 2: return {}
	sides = clampi(sides, 3, 32)
	radius = clampf(radius, 0.005, 5.0)
	wall = clampf(wall, 0.0, radius * 0.9)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()
	var tangents: Array[Vector3] = []
	var frame_normal := Vector3.ZERO
	var previous_tangent := Vector3.ZERO
	for i in points.size():
		var tangent: Vector3
		if i == 0: tangent = (points[1]-points[0]).normalized()
		elif i == points.size()-1: tangent = (points[i]-points[i-1]).normalized()
		else:
			var incoming := (points[i]-points[i-1]).normalized()
			var outgoing := (points[i+1]-points[i]).normalized()
			tangent = (incoming+outgoing).normalized()
			if tangent.length_squared() < 0.1: tangent = outgoing
		if i == 0:
			var guide := Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
			frame_normal = tangent.cross(guide).normalized()
		elif previous_tangent.dot(tangent) > -0.9999:
			frame_normal = Quaternion(previous_tangent,tangent) * frame_normal
		# Orthogonalize also covers the exact reversal case, without an undefined rotation.
		frame_normal = (frame_normal-tangent*frame_normal.dot(tangent)).normalized()
		var binormal := tangent.cross(frame_normal).normalized()
		for j in sides:
			var angle := TAU * j / float(sides)
			var radial := frame_normal*cos(angle)+binormal*sin(angle)
			vertices.append(points[i]+radius*radial)
			normals.append(radial)
			uvs.append(Vector2(float(i)/(points.size()-1),float(j)/sides))
		tangents.append(tangent)
		previous_tangent = tangent
	# Connect corresponding ring addresses with two clockwise triangles per quad.
	for i in points.size()-1:
		for j in sides:
			var a := i*sides+j
			var b := i*sides+(j+1)%sides
			var c := (i+1)*sides+j
			var d := (i+1)*sides+(j+1)%sides
			indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
	var ring_vertices := vertices.duplicate()
	# A hollow pipe has an inward-facing skin and annular rims, never solid discs.
	if wall > 0.0:
		var inner_offset := vertices.size()
		for i in points.size():
			for j in sides:
				var n: Vector3 = normals[i*sides+j]
				vertices.append(points[i]+(radius-wall)*n); normals.append(-n)
				uvs.append(Vector2(float(i)/(points.size()-1),float(j)/sides))
		for i in points.size()-1:
			for j in sides:
				var a := inner_offset+i*sides+j
				var b := inner_offset+i*sides+(j+1)%sides
				var c := inner_offset+(i+1)*sides+j
				var d := inner_offset+(i+1)*sides+(j+1)%sides
				indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
	# Separate rim/cap vertices retain flat end normals and smooth side normals.
	for end in [0,points.size()-1]:
		var cap_normal: Vector3 = -tangents[end] if end == 0 else tangents[end]
		var center := vertices.size()
		if wall > 0.0:
			for j in sides:
				var n: Vector3 = (ring_vertices[end*sides+j]-points[end])/radius
				vertices.append(points[end]+radius*n); normals.append(cap_normal)
				vertices.append(points[end]+(radius-wall)*n); normals.append(cap_normal)
				uvs.append(Vector2(float(end)/(points.size()-1),float(j)/sides))
				uvs.append(uvs[-1])
			for j in sides:
				var a := center+2*j; var b := center+2*((j+1)%sides)
				var face := PackedInt32Array([a,b,a+1,b,b+1,a+1])
				if end != 0: face.reverse()
				indices.append_array(face)
			continue
		vertices.append(points[end]); normals.append(cap_normal)
		uvs.append(Vector2(float(end)/(points.size()-1),0.5))
		for j in sides:
			vertices.append(ring_vertices[end*sides+j]); normals.append(cap_normal)
			uvs.append(Vector2(float(end)/(points.size()-1),float(j)/sides))
		for j in sides:
			var a := center+1+j; var b := center+1+(j+1)%sides
			indices.append_array(PackedInt32Array([center,a,b] if end == 0 else [center,b,a]))
	var arrays: Array = []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices; arrays[Mesh.ARRAY_NORMAL] = normals; arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return {"mesh":mesh,"points":points,"rings":ring_vertices,"sides":sides,"vertices":vertices,"indices":indices,"normals":normals}

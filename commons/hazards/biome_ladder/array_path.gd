extends RefCounted
## An ordered position list, shared by the warning, projectile and its route drawing.
const CUE_SHADER := preload("res://commons/hazards/biome_ladder/path_cue.gdshader")

static func positions(start: Vector3, target: Vector3, handedness: float) -> PackedVector3Array:
	var forward := start.direction_to(target)
	var side := forward.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01: side = Vector3.RIGHT
	var width := minf(0.55, start.distance_to(target) * 0.1)
	return PackedVector3Array([start,
		start.lerp(target, 0.25) + side * width * handedness,
		start.lerp(target, 0.5) - side * width * handedness,
		start.lerp(target, 0.75) + side * width * handedness,
		target])

static func ending_on_floor(points: PackedVector3Array, frame: Transform3D) -> PackedVector3Array:
	# Preserve the five learned positions. One final, visible entry ends the miss on a tile.
	var result := points.duplicate()
	var target := frame.affine_inverse() * points[-1]
	if absf(target.x) > 5.5 or absf(target.z) > 10.8: return result
	var forward := target - frame.affine_inverse() * points[0]
	forward.y = 0
	var landing := target + forward.normalized() * 1.25
	# Address a cell centre, not a grout seam. Exact tile collision still decides whether it paints.
	landing.x = clampf(floor((landing.x + 6.0) / 2.0) * 2.0 - 5.0, -5.0, 5.0)
	landing.z = clampf(floor((landing.z + 12.0) / 2.0) * 2.0 - 11.0, -11.0, 11.0)
	landing.y = -0.12
	result.append(frame * landing)
	return result

static func drawing(points: PackedVector3Array, warning: bool = true) -> MeshInstance3D:
	var line := MeshInstance3D.new()
	line.name = "StoredPositionPath"
	line.top_level = true # Points are in world space; the drawing must not follow the ball.
	var mesh := ImmediateMesh.new()
	# A physical width survives distance and oblique views. Build once per warning/shot.
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius := 0.02 if warning else 0.009
	for i in range(1, points.size()):
		var axis := points[i] - points[i - 1]
		if axis.length_squared() < 0.000001: continue
		axis = axis.normalized()
		var side := axis.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.01: side = axis.cross(Vector3.RIGHT).normalized()
		var up := axis.cross(side).normalized()
		for j in range(8):
			var a := side * cos(TAU * j / 8.0) + up * sin(TAU * j / 8.0)
			var b := side * cos(TAU * (j + 1) / 8.0) + up * sin(TAU * (j + 1) / 8.0)
			var normals := [a, b, b, a, b, a]
			var centres := [points[i - 1], points[i - 1], points[i], points[i - 1], points[i], points[i]]
			for v in range(6):
				mesh.surface_set_normal(normals[v])
				mesh.surface_add_vertex(centres[v] + normals[v] * radius)
	mesh.surface_end()
	line.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = CUE_SHADER
	material.set_shader_parameter("cue_colour", Color.WHITE if warning else Color(0.50, 0.50, 0.50))
	line.material_override = material
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return line

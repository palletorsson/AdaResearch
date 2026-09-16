extends Node3D
## Reusable, non-interactive casing around a flat readout. Front is local +Z.
var _body: MeshInstance3D
var _rim: MeshInstance3D
var _accent: MeshInstance3D
var _last_size := Vector2.ZERO

func fit_rect(center: Vector2, screen_size: Vector2, ink: Color) -> void:
	if not is_instance_valid(_body):
		_body = _part("Shell", Color(0.075, 0.085, 0.105), 0.4, 0.45)
		_rim = _part("MetalRim", Color(0.48, 0.50, 0.53), 0.65, 0.3)
		_accent = _part("InkInlay", ink, 0.0, 0.6)
		var bar := BoxMesh.new()
		bar.size = Vector3(0.12, 0.006, 0.004)
		_accent.mesh = bar
	position = Vector3(center.x, center.y, 0)
	if not screen_size.is_equal_approx(_last_size):
		_body.mesh = _rounded_box(screen_size + Vector2(0.09, 0.09), 0.065, 0.035)
		_rim.mesh = _rounded_box(screen_size + Vector2(0.027, 0.027), 0.009, 0.012)
		_last_size = screen_size
	_body.position.z = -0.038
	_rim.position.z = -0.005
	_accent.position = Vector3(0, -screen_size.y * 0.5 - 0.027, -0.003)
	(_accent.material_override as StandardMaterial3D).albedo_color = ink

func _part(part_name: String, color: Color, metallic: float, roughness: float) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	part.material_override = material
	add_child(part)
	return part

func _rounded_box(size: Vector2, depth: float, radius: float) -> ArrayMesh:
	var ring: Array[Vector2] = []
	for corner in range(4):
		var angle := float(corner) * PI * 0.5
		var center := Vector2(1 if corner in [0,3] else -1, 1 if corner < 2 else -1) * (size * 0.5 - Vector2.ONE * radius)
		for step in range(9):
			var theta := angle + float(step) * PI / 16.0
			ring.append(center + Vector2(cos(theta), sin(theta)) * radius)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var af := Vector3(a.x, a.y, depth * 0.5)
		var bf := Vector3(b.x, b.y, depth * 0.5)
		var ab := Vector3(a.x, a.y, -depth * 0.5)
		var bb := Vector3(b.x, b.y, -depth * 0.5)
		# Clockwise front faces in Godot; explicit normals keep flat caps crisp.
		_triangle(st, Vector3(0,0,depth*0.5), bf, af, Vector3.FORWARD * -1)
		_triangle(st, Vector3(0,0,-depth*0.5), ab, bb, Vector3.FORWARD)
		var n := Vector3(b.y-a.y, a.x-b.x, 0).normalized()
		_triangle(st, af, bf, ab, n)
		_triangle(st, bf, bb, ab, n)
	return st.commit()

func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	st.set_normal(normal)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

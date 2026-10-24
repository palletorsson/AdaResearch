class_name ModularMesh
extends RefCounted
## Module: a mesh. {"p":"mesh","shape":sphere|box|plane|cylinder|cone|tetra|pyramid|wedge|torus|triangle|dodeca,
## "size":[…],"color":"hex","alpha":1,"at":[…],"rot":[…],"shader":"ink"} — sizes in metres.
## "shader":"ink" wears shaders/ink_stroke.gdshader: a drawn line (tapered ends, darker
## silhouette, a faint grain) instead of a lit tube — the modular line's stroke.

const INK_SHADER := "res://commons/modular/shaders/ink_stroke.gdshader"


static func make(spec: Dictionary) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var shape: String = str(spec.get("shape", "box"))
	var size: Array = spec.get("size", [0.3])
	var s0: float = float(size[0]) if size.size() > 0 else 0.3
	var s1: float = float(size[1]) if size.size() > 1 else s0
	var s2: float = float(size[2]) if size.size() > 2 else s0
	match shape:
		"sphere":
			var m := SphereMesh.new()
			m.radius = s0
			m.height = s0 * 2.0
			m.radial_segments = 20
			m.rings = 10
			mi.mesh = m
		"box":
			var m := BoxMesh.new()
			m.size = Vector3(s0, s1, s2)
			mi.mesh = m
		"plane":
			var m := PlaneMesh.new()
			m.size = Vector2(s0, s1)
			mi.mesh = m
		"cylinder":
			var m := CylinderMesh.new()
			m.top_radius = s0
			m.bottom_radius = s0
			m.height = s1
			m.radial_segments = 12
			mi.mesh = m
		"cone":
			var m := CylinderMesh.new()
			m.top_radius = 0.0
			m.bottom_radius = s0
			m.height = s1
			m.radial_segments = 20
			mi.mesh = m
		"torus":
			var m := TorusMesh.new()
			m.inner_radius = s0 - s1
			m.outer_radius = s0
			mi.mesh = m
		"wedge":
			var m := PrismMesh.new()
			m.size = Vector3(s0, s1, s2)
			m.left_to_right = 1.0
			mi.mesh = m
			mi.position.y = s1 / 2.0
		"tetra":
			mi.mesh = _tetra(s0)
		"pyramid":
			mi.mesh = _pyramid(s0, s1)
		"triangle":
			mi.mesh = _triangle(s0)
		"dodeca":
			mi.mesh = _dodeca(s0)
		_:
			var m := BoxMesh.new()
			m.size = Vector3(s0, s1, s2)
			mi.mesh = m
	var col := Color(str(spec.get("color", "f3ecdd")))
	var alpha: float = float(spec.get("alpha", 1.0))
	col.a = alpha
	if str(spec.get("shader", "")) == "ink":
		var ink := ShaderMaterial.new()
		ink.shader = load(INK_SHADER)
		ink.set_shader_parameter("ink", col)
		ink.set_shader_parameter("length_m", s1)
		mi.material_override = ink
		mi.set_meta("construction_mark", true)   # a surface never paints over the stroke
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = 0.9
		if alpha < 0.999:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		if shape == "triangle" or shape == "plane":
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = mat
	mi.name = "mesh_" + shape
	return mi


static func _faces(verts: PackedVector3Array, idx: PackedInt32Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, idx.size(), 3):
		var a: Vector3 = verts[idx[i]]
		var b: Vector3 = verts[idx[i + 1]]
		var c: Vector3 = verts[idx[i + 2]]
		var n: Vector3 = (b - a).cross(c - a).normalized()
		st.set_normal(n); st.add_vertex(a)
		st.set_normal(n); st.add_vertex(b)
		st.set_normal(n); st.add_vertex(c)
	return st.commit()


static func _tetra(edge: float) -> ArrayMesh:
	var r: float = edge / sqrt(3.0)
	var h: float = edge * sqrt(2.0 / 3.0)
	var v := PackedVector3Array([
		Vector3(r, 0, 0), Vector3(r * cos(TAU / 3), 0, r * sin(TAU / 3)), Vector3(r * cos(2 * TAU / 3), 0, r * sin(2 * TAU / 3)), Vector3(0, h, 0)])
	# clockwise seen from outside (Godot winds clockwise)
	return _faces(v, PackedInt32Array([0, 1, 2, 0, 3, 1, 1, 3, 2, 2, 3, 0]))


static func _pyramid(base: float, h: float) -> ArrayMesh:
	var b: float = base / 2.0
	var v := PackedVector3Array([Vector3(-b, 0, -b), Vector3(b, 0, -b), Vector3(b, 0, b), Vector3(-b, 0, b), Vector3(0, h, 0)])
	return _faces(v, PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 4, 1, 1, 4, 2, 2, 4, 3, 3, 4, 0]))


static func _triangle(edge: float) -> ArrayMesh:
	var r: float = edge / sqrt(3.0)
	var v := PackedVector3Array([Vector3(r, 0, 0), Vector3(r * cos(TAU / 3), 0, r * sin(TAU / 3)), Vector3(r * cos(2 * TAU / 3), 0, r * sin(2 * TAU / 3))])
	return _faces(v, PackedInt32Array([0, 2, 1]))


static func _dodeca(r: float) -> ArrayMesh:
	# an icosphere stands in for Dürer's solid at this scale
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 6
	m.rings = 3
	var st := SurfaceTool.new()
	st.create_from(m, 0)
	return st.commit()

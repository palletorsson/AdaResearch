# sine_object_editor.gd — Parametric mathematical surfaces editor
# Builds mobius strips, torus knots, superellipsoids, sphere harmonics, klein bottles
# using SurfaceTool + ArrayMesh (no MorphoPrimitive dependency).
extends BaseGeometryEditor


func _get_editor_name() -> String:
	return "Sine Object"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Shape", "params": [
			{"id": "type", "label": "Shape", "options": ["Mobius Strip", "Torus Knot", "Superellipsoid", "Sphere Harmonic", "Klein Bottle"], "default": 0.0},
		]},
		{"name": "Geometry", "params": [
			{"id": "major_radius", "label": "Major Radius", "min": 0.2, "max": 2.0, "step": 0.05, "default": 1.0},
			{"id": "minor_radius", "label": "Minor Radius", "min": 0.05, "max": 0.8, "step": 0.05, "default": 0.2},
			{"id": "twists", "label": "Twists / P", "min": 1.0, "max": 5.0, "step": 1.0, "default": 1.0},
			{"id": "q_param", "label": "Q", "min": 1.0, "max": 5.0, "step": 1.0, "default": 2.0},
			{"id": "exponent", "label": "Exponent", "min": 0.3, "max": 4.0, "step": 0.1, "default": 2.0},
		]},
		{"name": "Resolution", "params": [
			{"id": "segments", "label": "Segments", "min": 16.0, "max": 96.0, "step": 2.0, "default": 48.0},
			{"id": "width_segments", "label": "Width Segments", "min": 4.0, "max": 24.0, "step": 1.0, "default": 12.0},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	var shape_type: int = int(p("type", 0))
	var R: float = p("major_radius", 1.0)
	var r_val: float = p("minor_radius", 0.2)
	var tw: int = int(p("twists", 1))
	var q_val: int = int(p("q_param", 2))
	var exp_val: float = p("exponent", 2.0)
	var seg: int = int(p("segments", 48))
	var wseg: int = int(p("width_segments", 12))

	# Build vertex grid
	var verts: Array[PackedVector3Array] = []

	match shape_type:
		0: verts = _build_mobius(R, r_val, tw, seg, wseg)
		1: verts = _build_torus_knot(R, r_val, tw, q_val, seg, wseg)
		2: verts = _build_superellipsoid(R, exp_val, seg, wseg)
		3: verts = _build_sphere_harmonic(R, r_val, tw, q_val, seg, wseg)
		4: verts = _build_klein(R, r_val, seg, wseg)

	if verts.is_empty():
		return

	var mesh: ArrayMesh = _triangulate_grid(verts)
	if not mesh:
		return

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.7, 0.85)
	mat.roughness = 0.3
	mat.metallic = 0.1
	mat.cull_mode = StandardMaterial3D.CULL_DISABLED
	mi.material_override = mat
	content_root.add_child(mi)


# ── Parametric surface builders ──────────────────────────────

func _build_mobius(R: float, r_val: float, twists: int, seg: int, wseg: int) -> Array[PackedVector3Array]:
	var rows: Array[PackedVector3Array] = []
	for i in seg + 1:
		var row := PackedVector3Array()
		var theta: float = TAU * float(i) / float(seg)
		for j in wseg + 1:
			var s: float = r_val * (float(j) / float(wseg) - 0.5)
			var twist_angle: float = theta * float(twists) * 0.5
			var x: float = (R + s * cos(twist_angle)) * cos(theta)
			var y: float = s * sin(twist_angle)
			var z: float = (R + s * cos(twist_angle)) * sin(theta)
			row.append(Vector3(x, y, z))
		rows.append(row)
	return rows


func _build_torus_knot(R: float, r_val: float, p_val: int, q_val: int, seg: int, wseg: int) -> Array[PackedVector3Array]:
	# First build the spine curve
	var spine: PackedVector3Array = PackedVector3Array()
	for i in seg + 1:
		var t: float = TAU * float(i) / float(seg)
		var rv: float = R + r_val * cos(float(q_val) * t)
		spine.append(Vector3(rv * cos(float(p_val) * t), r_val * sin(float(q_val) * t), rv * sin(float(p_val) * t)))

	# Build tube around spine using Frenet frame
	var rows: Array[PackedVector3Array] = []
	var tube_radius: float = r_val * 0.4
	for i in seg + 1:
		var row := PackedVector3Array()
		var idx: int = i % seg
		var next_idx: int = (i + 1) % seg
		var tangent: Vector3 = (spine[next_idx] - spine[idx]).normalized()
		# Approximate normal using second derivative
		var prev_idx: int = (i - 1 + seg) % seg
		var binormal: Vector3 = tangent.cross(spine[next_idx] - 2.0 * spine[idx] + spine[prev_idx])
		if binormal.length_squared() < 0.0001:
			binormal = tangent.cross(Vector3.UP)
		if binormal.length_squared() < 0.0001:
			binormal = tangent.cross(Vector3.RIGHT)
		binormal = binormal.normalized()
		var normal: Vector3 = binormal.cross(tangent).normalized()
		for j in wseg + 1:
			var angle: float = TAU * float(j) / float(wseg)
			var offset: Vector3 = normal * cos(angle) + binormal * sin(angle)
			row.append(spine[idx] + offset * tube_radius)
		rows.append(row)
	return rows


func _build_superellipsoid(R: float, exp_val: float, seg: int, wseg: int) -> Array[PackedVector3Array]:
	var rows: Array[PackedVector3Array] = []
	var inv_e: float = 2.0 / exp_val
	for i in seg + 1:
		var row := PackedVector3Array()
		var phi: float = PI * float(i) / float(seg) - PI * 0.5
		var cp: float = cos(phi)
		var sp: float = sin(phi)
		for j in wseg + 1:
			var theta: float = TAU * float(j) / float(wseg)
			var ct: float = cos(theta)
			var st: float = sin(theta)
			var x: float = R * signf(cp) * pow(absf(cp), inv_e) * signf(ct) * pow(absf(ct), inv_e)
			var y: float = R * signf(sp) * pow(absf(sp), inv_e)
			var z: float = R * signf(cp) * pow(absf(cp), inv_e) * signf(st) * pow(absf(st), inv_e)
			row.append(Vector3(x, y, z))
		rows.append(row)
	return rows


func _build_sphere_harmonic(R: float, r_val: float, twists: int, q_val: int, seg: int, wseg: int) -> Array[PackedVector3Array]:
	var rows: Array[PackedVector3Array] = []
	for i in seg + 1:
		var row := PackedVector3Array()
		var phi: float = PI * float(i) / float(seg)
		for j in wseg + 1:
			var theta: float = TAU * float(j) / float(wseg)
			var rv: float = R + r_val * sin(float(twists) * phi) * cos(float(q_val) * theta)
			var x: float = rv * sin(phi) * cos(theta)
			var y: float = rv * cos(phi)
			var z: float = rv * sin(phi) * sin(theta)
			row.append(Vector3(x, y, z))
		rows.append(row)
	return rows


func _build_klein(R: float, r_val: float, seg: int, wseg: int) -> Array[PackedVector3Array]:
	var rows: Array[PackedVector3Array] = []
	for i in seg + 1:
		var row := PackedVector3Array()
		var u: float = TAU * float(i) / float(seg)
		for j in wseg + 1:
			var v: float = TAU * float(j) / float(wseg)
			# Figure-8 Klein bottle immersion
			var x: float = (R + r_val * cos(v)) * cos(u)
			var y: float = (R + r_val * cos(v)) * sin(u)
			var z: float = r_val * sin(v) * cos(u * 0.5)
			row.append(Vector3(x, y, z))
		rows.append(row)
	return rows


# ── Triangulation ────────────────────────────────────────────

func _triangulate_grid(rows: Array[PackedVector3Array]) -> ArrayMesh:
	if rows.size() < 2:
		return null

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var row_count: int = rows.size()
	var col_count: int = rows[0].size()

	for i in row_count - 1:
		for j in col_count - 1:
			var v00: Vector3 = rows[i][j]
			var v10: Vector3 = rows[i + 1][j]
			var v11: Vector3 = rows[i + 1][j + 1]
			var v01: Vector3 = rows[i][j + 1]

			# Triangle 1
			st.add_vertex(v00)
			st.add_vertex(v10)
			st.add_vertex(v11)

			# Triangle 2
			st.add_vertex(v00)
			st.add_vertex(v11)
			st.add_vertex(v01)

	st.generate_normals()
	return st.commit()

extends SceneTree
## godot --headless --path <study> --script res://geometry_verify.gd -- <report.json>

const Geometry = preload("res://stroke_geometry.gd")
var checks: Array[Dictionary] = []
var mesh_summaries: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, passed: bool, detail: String = "") -> void:
	checks.append({"name": label, "passed": passed, "detail": detail})
	if not passed:
		push_error(label + (": " + detail if not detail.is_empty() else ""))


func _run() -> void:
	var straight := PackedVector3Array([Vector3.ZERO, Vector3(0, 1, 0), Vector3(0, 2, 0)])
	var irregular := PackedVector3Array([Vector3.ZERO, Vector3(0, 0.1, 0), Vector3(0, 1.7, 0), Vector3(0, 2, 0)])
	var dirty := PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 2, 0)])
	var reversal := PackedVector3Array([Vector3.ZERO, Vector3.UP, Vector3.ZERO, Vector3.DOWN])
	var curve := PackedVector3Array()
	for index in 61:
		var t := float(index) / 60.0
		curve.append(Vector3(0.8 * sin(t * TAU), 2.5 * t, 0.5 * (cos(t * TAU) - 1.0)))
	_check("empty input has no surface", Geometry.build_mesh(PackedVector3Array()).get_surface_count() == 0)
	_check("one point has no surface", Geometry.build_mesh(PackedVector3Array([Vector3.ZERO])).get_surface_count() == 0)
	_check("repeated point has no surface", Geometry.build_mesh(PackedVector3Array([Vector3.ONE, Vector3.ONE])).get_surface_count() == 0)
	_check("duplicates are removed", Geometry.clean_points(dirty) == straight)
	var invalid := PackedVector3Array([Vector3.ZERO, Vector3(NAN, 0, 0), Vector3(INF, 0, 0), Vector3.UP])
	_check("nonfinite samples are removed", Geometry.clean_points(invalid) == PackedVector3Array([Vector3.ZERO, Vector3.UP]))
	_test_frames(straight, "vertical")
	_test_frames(PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.RIGHT * 2.0]), "horizontal fallback")
	_test_frames(curve, "spatial curve")
	_test_frames(reversal, "exact reversal")
	var curve_frames: Array = Geometry.frames(curve)
	var min_side_dot := 1.0
	for index in range(1, curve_frames.size()):
		min_side_dot = minf(min_side_dot, Vector3(curve_frames[index - 1].side).dot(Vector3(curve_frames[index].side)))
	_check("transport is continuous on smooth spatial curve", min_side_dot > 0.95, str(min_side_dot))
	var sampled_a := Geometry.resample(straight, 0.08)
	var sampled_b := Geometry.resample(irregular, 0.08)
	_check("sampling ignores input event density", _same_points(sampled_a, sampled_b))
	var dense_curve := PackedVector3Array([curve[0]])
	for index in range(1, curve.size()):
		dense_curve.append(curve[index - 1].lerp(curve[index], 0.3))
		dense_curve.append(curve[index])
	_check("spatial resampling ignores collinear subdivisions", _same_points(Geometry.resample(curve, 0.09), Geometry.resample(dense_curve, 0.09)))
	_check("resampling retains exact endpoints", sampled_a[0] == straight[0] and sampled_a[-1] == straight[-1])
	var uniform := true
	for index in range(1, sampled_a.size()):
		uniform = uniform and absf(sampled_a[index].distance_to(sampled_a[index - 1]) - 0.08) < 0.00001
	_check("resampling uses world distance", uniform)
	_check("invalid spacing uses safe default", Geometry.resample(straight, 0.0).size() == Geometry.resample(straight).size())
	var ribbon := _test_mesh(straight, {"shape": "ribbon", "width": 0.4}, "straight ribbon")
	var ribbon_vertices: PackedVector3Array = ribbon[Mesh.ARRAY_VERTEX]
	var ribbon_uvs: PackedVector2Array = ribbon[Mesh.ARRAY_TEX_UV]
	_check("ribbon full width is in metres", absf(ribbon_vertices[0].distance_to(ribbon_vertices[1]) - 0.4) < 0.00001)
	_check("ribbon shares adjacent cross sections", ribbon_vertices.size() == 6 and ribbon[Mesh.ARRAY_INDEX].size() == 12)
	_check("ribbon UV spans width and arc", ribbon_uvs[0].is_equal_approx(Vector2(0, 0)) and ribbon_uvs[1].is_equal_approx(Vector2(1, 0)) and ribbon_uvs[2].is_equal_approx(Vector2(0, 0.5)) and ribbon_uvs[-1].is_equal_approx(Vector2(1, 1)))
	var uneven_mesh := _test_mesh(irregular, {}, "uneven sample ribbon")
	var uneven_uvs: PackedVector2Array = uneven_mesh[Mesh.ARRAY_TEX_UV]
	_check("UV along stroke uses arc length rather than sample index", absf(uneven_uvs[2].y - 0.05) < 0.00001 and absf(uneven_uvs[4].y - 0.85) < 0.00001)
	var taper := _test_mesh(straight, {"width": 0.4, "taper": 1.0}, "tapered ribbon")
	var taper_vertices: PackedVector3Array = taper[Mesh.ARRAY_VERTEX]
	_check("taper keeps nonzero endpoints", absf(taper_vertices[0].distance_to(taper_vertices[1]) - 0.016) < 0.00001 and absf(taper_vertices[-2].distance_to(taper_vertices[-1]) - 0.016) < 0.00001)
	_check("taper retains full middle width", absf(taper_vertices[2].distance_to(taper_vertices[3]) - 0.4) < 0.00001)
	var twisted := _test_mesh(straight, {"width": 0.4, "twist": PI / 2.0}, "twisted ribbon")
	var twist_vertices: PackedVector3Array = twisted[Mesh.ARRAY_VERTEX]
	var start_side := (twist_vertices[1] - twist_vertices[0]).normalized()
	var end_side := (twist_vertices[-1] - twist_vertices[-2]).normalized()
	_check("total twist reaches requested angle", start_side.rotated(Vector3.UP, PI / 2.0).dot(end_side) > 0.99999)
	var sampled_mesh_a := Geometry.build_mesh(sampled_a, {"taper": 0.6, "twist": 0.8}).surface_get_arrays(0)
	var sampled_mesh_b := Geometry.build_mesh(sampled_b, {"taper": 0.6, "twist": 0.8}).surface_get_arrays(0)
	_check("taper and twist invariant after distance resampling", _same_points(sampled_mesh_a[Mesh.ARRAY_VERTEX], sampled_mesh_b[Mesh.ARRAY_VERTEX]))
	_test_mesh(dirty, {"shape": "ribbon"}, "duplicate ribbon")
	_test_mesh(reversal, {"shape": "ribbon"}, "reversal ribbon")
	_test_mesh(reversal, {"shape": "tube", "sides": 8}, "reversal tube")
	_test_mesh(curve, {"shape": "ribbon", "width": 0.22, "taper": 0.7, "twist": TAU}, "spatial twisted ribbon")
	var tube := _test_mesh(curve, {"shape": "tube", "width": 0.2, "sides": 12}, "spatial tube")
	_test_tube(curve, tube, 12, 0.1)
	var triangle_tube := _test_mesh(straight, {"shape": "tube", "sides": 3, "caps": false}, "triangle section tube")
	_check("optional open tube omits caps", triangle_tube[Mesh.ARRAY_VERTEX].size() == straight.size() * 4)
	_finish()


func _test_frames(points: PackedVector3Array, label: String) -> void:
	var frame_list: Array = Geometry.frames(points)
	var okay := frame_list.size() == Geometry.clean_points(points).size()
	for frame in frame_list:
		var tangent: Vector3 = frame.tangent
		var side: Vector3 = frame.side
		var normal: Vector3 = frame.normal
		okay = okay and tangent.is_finite() and side.is_finite() and normal.is_finite()
		okay = okay and absf(tangent.length() - 1.0) < 0.00001 and absf(side.length() - 1.0) < 0.00001 and absf(normal.length() - 1.0) < 0.00001
		okay = okay and absf(tangent.dot(side)) < 0.00001 and absf(tangent.dot(normal)) < 0.00001 and absf(side.dot(normal)) < 0.00001
		okay = okay and tangent.cross(side).dot(normal) > 0.99999
	_check(label + ": finite orthonormal frames", okay)


func _test_mesh(points: PackedVector3Array, options: Dictionary, label: String) -> Array:
	var mesh: ArrayMesh = Geometry.build_mesh(points, options)
	_check(label + ": one surface", mesh.get_surface_count() == 1)
	if mesh.get_surface_count() == 0:
		return []
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var finite := vertices.size() == normals.size() and vertices.size() == uvs.size()
	for index in vertices.size():
		finite = finite and vertices[index].is_finite() and normals[index].is_finite() and uvs[index].is_finite()
		finite = finite and absf(normals[index].length() - 1.0) < 0.0001
	_check(label + ": finite vertices and unit normals", finite)
	var nondegenerate := indices.size() % 3 == 0 and indices.size() > 0
	var clockwise := true
	for index in range(0, indices.size(), 3):
		var a := indices[index]
		var b := indices[index + 1]
		var c := indices[index + 2]
		if mini(a, mini(b, c)) < 0 or maxi(a, maxi(b, c)) >= vertices.size():
			nondegenerate = false
			clockwise = false
			continue
		var face := (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a])
		nondegenerate = nondegenerate and face.length_squared() > 1.0e-20
		clockwise = clockwise and face.dot(normals[a] + normals[b] + normals[c]) >= -0.0000001
	_check(label + ": no degenerate triangles", nondegenerate)
	_check(label + ": clockwise faces agree with normals", clockwise)
	mesh_summaries.append({"name": label, "vertices": vertices.size(), "triangles": indices.size() / 3})
	return arrays


func _test_tube(points: PackedVector3Array, arrays: Array, sides: int, radius: float) -> void:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var expected_side_count := points.size() * (sides + 1)
	_check("tube capped vertex count", vertices.size() == expected_side_count + 2 * (sides + 2))
	_check("tube complete triangle count", arrays[Mesh.ARRAY_INDEX].size() == ((points.size() - 1) * sides * 2 + sides * 2) * 3)
	var radial_ok := true
	var seam_ok := true
	for index in points.size():
		var first := index * (sides + 1)
		seam_ok = seam_ok and vertices[first].distance_to(vertices[first + sides]) < 0.000001
		seam_ok = seam_ok and absf(uvs[first].x) < 0.000001 and absf(uvs[first + sides].x - 1.0) < 0.000001
		for column in sides + 1:
			var vertex := first + column
			var radial := vertices[vertex] - points[index]
			radial_ok = radial_ok and absf(radial.length() - radius) < 0.000001 and radial.normalized().dot(normals[vertex]) > 0.99999
	_check("tube radius and outward radial normals", radial_ok)
	_check("tube seam closes position while splitting UV", seam_ok)
	var start_normal := -(points[1] - points[0]).normalized()
	var end_normal := (points[-1] - points[-2]).normalized()
	var caps_ok := vertices[expected_side_count].distance_to(points[0]) < 0.000001 and vertices[expected_side_count + sides + 2].distance_to(points[-1]) < 0.000001
	for index in sides + 2:
		caps_ok = caps_ok and normals[expected_side_count + index].dot(start_normal) > 0.99999
		caps_ok = caps_ok and normals[expected_side_count + sides + 2 + index].dot(end_normal) > 0.99999
	_check("tube caps have separate flat outward normals", caps_ok)
	# Weld equal positions for this topological check; UV seams and cap shading
	# deliberately have separate indices but must not leave geometric boundaries.
	var welded: Dictionary = {}
	var vertex_ids: Array[int] = []
	for vertex in vertices:
		var key := Vector3i(roundi(vertex.x * 100000.0), roundi(vertex.y * 100000.0), roundi(vertex.z * 100000.0))
		if not welded.has(key):
			welded[key] = welded.size()
		vertex_ids.append(int(welded[key]))
	var edges: Dictionary = {}
	var mesh_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for triangle in range(0, mesh_indices.size(), 3):
		for corner in 3:
			var a := vertex_ids[mesh_indices[triangle + corner]]
			var b := vertex_ids[mesh_indices[triangle + (corner + 1) % 3]]
			var edge := Vector2i(mini(a, b), maxi(a, b))
			edges[edge] = int(edges.get(edge, 0)) + 1
	var closed := true
	for count in edges.values():
		closed = closed and int(count) == 2
	_check("capped tube has no geometric boundary edges", closed)
	var box := AABB(vertices[0], Vector3.ZERO)
	for vertex in vertices:
		box = box.expand(vertex)
	_check("spatial sweep occupies all three dimensions", box.size.x > 1.0 and box.size.y > 2.0 and box.size.z > 0.8)


func _same_points(a: PackedVector3Array, b: PackedVector3Array) -> bool:
	if a.size() != b.size():
		return false
	for index in a.size():
		if a[index].distance_to(b[index]) > 0.00001:
			return false
	return true


func _finish() -> void:
	var passed := true
	for check in checks:
		passed = passed and bool(check.passed)
	var arguments := OS.get_cmdline_user_args()
	var report_path := str(arguments[0]) if arguments.size() > 0 else "res://geometry-verification.json"
	var report := {"passed": passed, "check_count": checks.size(), "checks": checks, "meshes": mesh_summaries}
	var output := FileAccess.open(report_path, FileAccess.WRITE)
	if output == null:
		push_error("Cannot write geometry report: " + report_path)
		quit(2)
		return
	output.store_string(JSON.stringify(report, "  "))
	output.close()
	print("Stroke geometry: %d checks; passed=%s; report=%s" % [checks.size(), str(passed), report_path])
	quit(0 if passed else 1)

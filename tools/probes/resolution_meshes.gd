extends SceneTree
## Exhaustive finite-range check for the three native mesh specimens.
## Run: Godot --headless --xr-mode off --path . --script res://tools/probes/resolution_meshes.gd
const OUT := "res://ada_run/resolution_reveal_monitor/mesh-report.json"
var checks: Array[Dictionary] = []
var helper: GDScript
var combinations := 0
var vertices_checked := 0

func _initialize() -> void:
	call_deferred("run")

func check(passed: bool, title: String) -> void:
	checks.append({"test": title, "passed": passed})
	print("PASS " if passed else "FAIL ", title)

func run() -> void:
	helper = load("res://commons/artifacts/concept_monitor/resolution_meshes.gd")
	check(helper != null and helper.can_instantiate(), "Resolution helper loads after autoload initialization")
	if helper == null or not helper.can_instantiate():
		finish()
		return
	for kind in range(3):
		var label: String = ["Cylinder", "Capsule", "Sphere"][kind]
		var legal := true
		var finite := true
		var topology := true
		var dimensions := true
		var minimum := 1 if kind == 2 else 0
		for segments in range(4, 65):
			for rings in range(minimum, 33):
				var mesh: PrimitiveMesh = helper.make(kind, segments, rings)
				combinations += 1
				legal = legal and int(mesh.get("radial_segments")) == segments and int(mesh.get("rings")) == rings
				var arrays: Array = mesh.surface_get_arrays(0)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				vertices_checked += vertices.size()
				for vertex in vertices:
					finite = finite and vertex.is_finite()
				for normal in normals:
					finite = finite and normal.is_finite()
				topology = topology and not vertices.is_empty() and indices.size() % 3 == 0 and normals.size() == vertices.size()
				var expected_vertices := (rings + 2) * (segments + 1)
				if kind == 0: expected_vertices += 2 * (segments + 2)
				if kind == 1: expected_vertices *= 3
				topology = topology and vertices.size() == expected_vertices and indices.size() == expected_submitted(kind, segments, rings) * 3
				var box := mesh.get_aabb()
				dimensions = dimensions and is_equal_approx(box.position.y, -1.2) and is_equal_approx(box.end.y, 1.2)
			if segments % 10 == 0: await process_frame
		check(legal, label + ": every integer segment/ring combination retains the requested legal values")
		check(finite, label + ": every vertex and normal is finite across the complete range")
		check(topology, label + ": all native vertex and index counts match the generated topology")
		check(dimensions, label + ": height stays 2.4 across the complete range")
		var lower: PrimitiveMesh = helper.make(kind, -100, -100)
		var upper: PrimitiveMesh = helper.make(kind, 999999, 999999)
		check(int(lower.get("radial_segments")) == 4 and int(lower.get("rings")) == minimum, label + ": inputs below the demonstration range clamp safely")
		check(int(upper.get("radial_segments")) == 64 and int(upper.get("rings")) == 32, label + ": inputs above the demonstration range clamp safely")
		for segments in [4, 5, 16, 64]:
			for rings in [minimum, 4, 32]:
				var mesh: PrimitiveMesh = helper.make(kind, segments, rings)
				var measured: Dictionary = helper.measure(mesh)
				check(measured.submitted == expected_submitted(kind, segments, rings) and measured.surface_triangles == expected_faces(kind, segments, rings), "%s %d/%d: measured faces exclude zero-area pole triangles" % [label, segments, rings])
				check(measured.vertex_count == mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() and measured.radial_segments == segments and measured.rings == rings and measured.wire is ImmediateMesh, "%s %d/%d: measurement supplies actual counts, parameters and wire edges" % [label, segments, rings])
	var cylinder_min: PrimitiveMesh = helper.make(0, 16, 0)
	var cylinder_max: PrimitiveMesh = helper.make(0, 16, 32)
	check(cylinder_min.get_aabb().is_equal_approx(cylinder_max.get_aabb()) and cross_section(cylinder_min) == cross_section(cylinder_max), "Cylinder rings add vertical cuts without changing its straight silhouette")
	check(y_levels(helper.make(1, 16, 0)).size() < y_levels(helper.make(1, 16, 8)).size(), "Capsule rings add sample levels through the caps and middle")
	check(y_levels(helper.make(2, 16, 1)).size() < y_levels(helper.make(2, 16, 8)).size(), "Sphere rings add sample levels between its poles")
	var first: PrimitiveMesh = helper.make(0, 8, 1)
	var second: PrimitiveMesh = helper.make(0, 8, 1)
	first.set("radial_segments", 32)
	check(first != second and second.get("radial_segments") == 8, "Specimens are independent resources; modifying one cannot alter another")
	check(combinations == 5978, "All 5,978 legal cylinder, capsule and sphere combinations were generated")
	finish()

func expected_submitted(kind: int, segments: int, rings: int) -> int:
	if kind == 0: return 2 * segments * (rings + 2)
	if kind == 1: return 6 * segments * (rings + 1)
	return 2 * segments * (rings + 1)

func expected_faces(kind: int, segments: int, rings: int) -> int:
	if kind == 0: return expected_submitted(kind, segments, rings)
	return expected_submitted(kind, segments, rings) - 2 * segments

func cross_section(mesh: PrimitiveMesh) -> Array[String]:
	var found := {}
	for vertex: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		found["%.6f,%.6f" % [vertex.x, vertex.z]] = true
	var points: Array[String] = []
	for key in found: points.append(key)
	points.sort()
	return points

func y_levels(mesh: PrimitiveMesh) -> Dictionary:
	var found := {}
	for vertex: Vector3 in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]: found["%.6f" % vertex.y] = true
	return found

func finish() -> void:
	var passed := true
	for item in checks: passed = passed and bool(item.passed)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "engine": Engine.get_version_info().string, "combinations": combinations, "vertices_checked": vertices_checked, "checks": checks}, "\t"))
	file.close()
	print("RESOLUTION MESHES ", "PASS" if passed else "FAIL", " ", combinations, " combinations")
	quit(0 if passed else 1)

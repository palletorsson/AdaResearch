extends SceneTree
## Runtime checks against the actual drawing tool. Fixtures are created in memory;
## neither the authored artifact nor a saved player trace is rewritten.
const Record = preload("res://commons/artifacts/concept_monitor/triangle_reveal_record.gd")
const SOURCE_PATH := "res://commons/primitives/point/draw_triangle_faces.tscn"
const OUT := "res://ada_run/triangle_reveal_monitor/record-report.json"
var checks: Array[Dictionary] = []
var source: Node3D
var world: Node3D
var trace_data: Node
var initial_bus: Dictionary
var max_vertex_error := 0.0
var max_normal_error := 0.0

func _initialize() -> void:
	call_deferred("run")

func check(passed: bool, title: String) -> void:
	checks.append({"test": title, "passed": passed})
	print("PASS " if passed else "FAIL ", title)

func bus_state() -> Dictionary:
	if trace_data == null:
		return {}
	return {"traces": trace_data.get("saved_traces").duplicate(true), "pattern": trace_data.call("get_pattern").duplicate(true)}

func source_state() -> Dictionary:
	var faces: Array = []
	for face: Dictionary in source.get("completed_triangles"):
		var instance: MeshInstance3D = face.mesh
		faces.append({"indices": face.points.duplicate(), "mesh_id": instance.mesh.get_instance_id(),
			"arrays": instance.mesh.surface_get_arrays(0).duplicate(true), "transform": instance.global_transform,
			"visible": instance.visible, "material_id": instance.material_override.get_instance_id()})
	var handles: Array = []
	for handle: Node3D in source.get("point_indicators"):
		handles.append([handle.get_instance_id(), handle.global_transform])
	return {"points": source.get("placed_points").duplicate(), "path": source.get("current_path").duplicate(),
		"faces": faces, "handles": handles, "fills": source.get("fills_visible"),
		"state": source.call("get_experiment_state").duplicate(true), "children": source.get_child_count(),
		"transform": source.global_transform, "held": source.get("_is_grabbed"),
		"colour_index": source.get("triangle_color_index"), "bus": bus_state()}

func fixture(local_points: Array[Vector3], transform_value: Transform3D = Transform3D.IDENTITY, close: bool = true) -> void:
	source.call("clear_all")
	source.transform = transform_value
	for point: Vector3 in local_points:
		source.call("_create_new_point", source.to_global(point))
	if close:
		source.call("_handle_snap_to_point", 0)
	source.call("_rebuild_lines")

func verify_exact(record: Dictionary, title: String) -> void:
	check(str(record.error).is_empty() and bool(record.closed), title + ": snapshot is closed and valid")
	if not str(record.error).is_empty() or not bool(record.closed):
		return
	var completed: Array = source.get("completed_triangles")
	var face: Dictionary = completed[-1]
	var mesh_instance: MeshInstance3D = face.mesh
	var source_arrays: Array = mesh_instance.mesh.surface_get_arrays(0)
	var source_vertices: PackedVector3Array = source_arrays[Mesh.ARRAY_VERTEX]
	var source_normals: PackedVector3Array = source_arrays[Mesh.ARRAY_NORMAL]
	var loop: Array = face.points
	var positions: Array = source.get("placed_points")
	var count_matches: bool = record.indices == loop and record.triangles.size() == loop.size() - 2
	check(count_matches, title + ": stored boundary order and logical fan count match")
	if not count_matches:
		return
	var boundary_matches: bool = record.points.size() == loop.size()
	for i in range(mini(record.points.size(), loop.size())):
		boundary_matches = boundary_matches and record.points[i].is_equal_approx(source.to_local(positions[loop[i]]))
	check(boundary_matches, title + ": boundary positions are copied in source-local coordinates")
	# Independently carry mesh normals into world space and then into the source
	# frame. This two-step form tests the helper's composed inverse transpose.
	var mesh_normal_to_world := mesh_instance.global_basis.inverse().transposed()
	var world_normal_to_source := source.global_basis.transposed()
	var vertices_match := true
	var normals_match := true
	var indices_match := true
	for t in range(record.triangles.size()):
		var tri: Dictionary = record.triangles[t]
		indices_match = indices_match and tri.indices == [loop[0], loop[t + 1], loop[t + 2]]
		vertices_match = vertices_match and tri.vertices.size() == 6
		normals_match = normals_match and tri.normals.size() == 6
		for k in range(mini(6, mini(tri.vertices.size(), tri.normals.size()))):
			var expected_vertex := source.to_local(mesh_instance.to_global(source_vertices[t * 6 + k]))
			var expected_normal := (world_normal_to_source * (mesh_normal_to_world * source_normals[t * 6 + k])).normalized()
			var vertex_error: float = tri.vertices[k].distance_to(expected_vertex)
			var normal_error: float = tri.normals[k].distance_to(expected_normal)
			max_vertex_error = maxf(max_vertex_error, vertex_error)
			max_normal_error = maxf(max_normal_error, normal_error)
			vertices_match = vertices_match and vertex_error < 0.0001
			normals_match = normals_match and normal_error < 0.0001
	check(vertices_match, title + ": exact six emitted vertices per fan triangle are copied")
	check(normals_match, title + ": source normals survive frame changes")
	check(indices_match, title + ": each fan triangle names the actual stored indices")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	trace_data = root.get_node_or_null("TraceData")
	initial_bus = bus_state()
	world = Node3D.new()
	root.add_child(world)
	# Load only after autoloads have entered the tree.
	source = load(SOURCE_PATH).instantiate()
	source.set("editable_points", false)
	world.add_child(source)
	source.set_process(false)
	source.set_physics_process(false)
	var pen: RigidBody3D = source.get_node("GrabPoint")
	pen.freeze = true
	pen.set_process(false)
	pen.set_physics_process(false)
	await physics_frame
	check(Record.capture(null).points.is_empty(), "Missing source gives an empty record")
	var fresh := Record.capture(source)
	check(fresh.points.is_empty() and fresh.triangles.is_empty() and str(fresh.error).is_empty(), "An untouched tool does not manufacture a drawing")
	var triangle: Array[Vector3] = [Vector3(-0.6, -0.3, 0), Vector3(0.7, -0.2, 0.2), Vector3(-0.1, 0.8, -0.1)]
	var quad: Array[Vector3] = [Vector3(-0.8, -0.4, 0), Vector3(0.6, -0.4, 0), Vector3(0.8, 0.6, 0), Vector3(-0.5, 0.8, 0)]
	var six: Array[Vector3] = [Vector3(-0.8, -0.3, 0.2), Vector3(-0.1, -0.7, -0.15), Vector3(0.7, -0.3, 0.4), Vector3(0.9, 0.5, -0.2), Vector3(0.1, 1, 0.3), Vector3(-0.7, 0.6, -0.4)]
	fixture(triangle)
	verify_exact(Record.capture(source), "Three-corner face")
	fixture(quad)
	verify_exact(Record.capture(source), "Four-corner fan")
	fixture(six)
	verify_exact(Record.capture(source), "Nonplanar six-corner fan")
	var transformed := Transform3D(Basis.from_euler(Vector3(0.37, -0.61, 0.22)).scaled_local(Vector3(1.8, 0.6, 1.3)), Vector3(2, 1.5, -3))
	fixture(six, transformed)
	verify_exact(Record.capture(source), "Rotated and nonuniformly scaled source")
	# Independently transform the emitted mesh node as well. The snapshot must
	# describe the mesh which actually renders, rather than reconstruct a fan.
	var emitted: MeshInstance3D = source.get("completed_triangles")[-1].mesh
	emitted.global_transform = Transform3D(Basis.from_euler(Vector3(-0.18, 0.29, 0.12)).scaled_local(Vector3(0.7, 1.4, 1.1)), Vector3(-0.5, 0.2, 0.8))
	verify_exact(Record.capture(source), "Independently transformed source mesh")
	fixture(quad)
	var before_shift := Record.capture(source)
	check(bool(source.call("shift_start")), "Actual source permits shifting the completed fan anchor")
	var after_shift := Record.capture(source)
	check(after_shift.indices == [1, 2, 3, 0] and after_shift.signature != before_shift.signature, "Shifted source order and signature reach the snapshot")
	verify_exact(after_shift, "Shifted source fan")
	var before_reads := source_state()
	var first_read := Record.capture(source)
	var stable := true
	for i in range(12):
		stable = stable and Record.capture(source).signature == first_read.signature
	check(stable, "Unchanged source gives a stable polling signature")
	check(source_state() == before_reads, "Repeated reads preserve source geometry, state, handles and TraceData")
	# Mutating returned copies must not reach the source arrays or mesh resource.
	first_read.points[0] = Vector3(20, 30, 40)
	first_read.indices[0] = 500
	first_read.triangles[0].vertices[0] = Vector3(40, 30, 20)
	first_read.triangles[0].normals[0] = Vector3.LEFT
	first_read.triangles[0].indices[0] = 600
	check(source_state() == before_reads, "Returned positions, normals and indices have no writable aliases into the source")
	source.call("toggle_fill_visibility")
	var hidden := Record.capture(source)
	check(not hidden.fills_visible and hidden.triangles.size() == 2, "Hidden fill remains a recorded mesh without changing its visibility")
	source.call("begin_new_outline")
	source.call("_create_new_point", Vector3(-0.2, 0.1, 0.4))
	source.call("_create_new_point", Vector3(0.3, 0.4, 0.5))
	source.call("_rebuild_lines")
	var open := Record.capture(source)
	check(not open.closed and open.points.size() == 2 and open.triangles.is_empty() and open.indices == [4, 5], "Current open path takes precedence over an older completed face")
	var invalid_path: Array[int] = [0, 999]
	source.set("current_path", invalid_path)
	var invalid := Record.capture(source)
	check(not str(invalid.error).is_empty() and invalid.points.is_empty(), "Out-of-range source index returns an explicit error")
	source.call("clear_all")
	var cleared := Record.capture(source)
	check(cleared.points.is_empty() and cleared.triangles.is_empty() and not cleared.closed and str(cleared.error).is_empty(), "Clearing the real tool clears the snapshot")
	# Bound handling is a snapshot concern. Supply real typed source arrays in
	# memory without creating 257 otherwise irrelevant scene-node fixtures.
	var many_points: Array[Vector3] = []
	var many_indices: Array[int] = []
	for i in range(256):
		many_points.append(Vector3(float(i), 0, 0))
		many_indices.append(i)
	source.set("placed_points", many_points)
	source.set("current_path", many_indices)
	var bound := Record.capture(source)
	check(bound.points.size() == 256 and str(bound.error).is_empty(), "A 256-corner open record is kept in full")
	many_points.append(Vector3(256, 0, 0))
	many_indices.append(256)
	source.set("placed_points", many_points)
	source.set("current_path", many_indices)
	var oversized := Record.capture(source)
	check(oversized.points.is_empty() and not str(oversized.error).is_empty(), "A 257-corner record is rejected rather than silently truncated")
	fixture(triangle)
	var singular := source.transform
	singular.basis = Basis.from_scale(Vector3(1, 0, 1))
	source.transform = singular
	var collapsed := Record.capture(source)
	check(collapsed.points.is_empty() and not str(collapsed.error).is_empty(), "A singular source transform is rejected before inversion")
	source.transform = Transform3D.IDENTITY
	fixture(triangle)
	var bad_face: MeshInstance3D = source.get("completed_triangles")[-1].mesh
	bad_face.mesh = null
	var missing := Record.capture(source)
	check(missing.points.is_empty() and not str(missing.error).is_empty(), "Missing completed geometry returns an explicit error")
	check(bus_state() == initial_bus, "All snapshot fixtures leave the TraceData store unchanged")
	var passed := true
	for item: Dictionary in checks:
		passed = passed and bool(item.passed)
	var report := {"passed": passed, "checks": checks, "max_vertex_error": max_vertex_error,
		"max_normal_error": max_normal_error, "source": SOURCE_PATH,
		"scope": "Real drawing tool with in-memory point fixtures; exact face snapshots, no authored map changes."}
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("TRIANGLE RECORD ", "PASS" if passed else "FAIL", " / ", checks.size(), " checks")
	quit(0 if passed else 1)

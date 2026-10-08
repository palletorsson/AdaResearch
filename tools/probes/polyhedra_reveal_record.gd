extends SceneTree
## Exercises the observer against the real source scene. All edits are confined
## to this temporary instance and never written back to the scene or source.
const Record = preload("res://commons/artifacts/concept_monitor/polyhedra_reveal_record.gd")
const SOURCE := "res://commons/primitives/tetrahedron/grab_tetrahedron.tscn"
const OUT := "res://ada_run/polyhedra_reveal_monitor/record-report.json"
var checks: Array[Dictionary] = []
var source: Node3D
var max_hinge_error := 0.0
var max_planarity_error := 0.0
var max_length_error := 0.0

func _initialize() -> void:
	call_deferred("run")

func check(passed: bool, title: String) -> void:
	checks.append({"test": title, "passed": passed})
	print("PASS " if passed else "FAIL ", title)

func source_state() -> Dictionary:
	var instance := source.get_node("MeshInstance3D") as MeshInstance3D
	var shape := source.get_node("CollisionShape3D") as CollisionShape3D
	return {"transform": source.global_transform, "mesh_transform": instance.transform,
		"mesh_id": instance.mesh.get_instance_id(), "arrays": instance.mesh.surface_get_arrays(0).duplicate(true),
		"material_id": instance.material_override.get_instance_id(), "shape_id": shape.shape.get_instance_id(),
		"collision": shape.shape.points.duplicate(), "scale": source.get("tetrahedron_scale"),
		"children": source.get_child_count(), "linear_velocity": source.get("linear_velocity")}

func check_geometry(record: Dictionary, title: String) -> void:
	check(str(record.error).is_empty() and record.points.size() == 4 and record.faces.size() == 4, title + ": valid four-position record")
	if not str(record.error).is_empty(): return
	var geometry: Dictionary = source.call("_tetrahedron_geometry")
	check(record.points == PackedVector3Array(geometry.vertices) and record.faces == geometry.faces, title + ": original vertex and face order retained")
	var mesh := source.get_node("MeshInstance3D") as MeshInstance3D
	var arrays := mesh.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var exact: bool = record.triangles.size() == 4
	var inward := true
	for i in range(record.triangles.size()):
		var tri: Dictionary = record.triangles[i]
		exact = exact and tri.vertices == verts.slice(i * 3, i * 3 + 3) and tri.normals == normals.slice(i * 3, i * 3 + 3)
		var centre: Vector3 = (tri.vertices[0] + tri.vertices[1] + tri.vertices[2]) / 3.0
		inward = inward and tri.normals[0].dot(centre) < 0.0
	check(exact, title + ": actual emitted vertices and normals copied exactly")
	check(inward, title + ": inward source normals preserved")
	check(PackedVector3Array(source.get_node("CollisionShape3D").shape.points) == record.points, title + ": actual convex hull uses the same four positions")

func check_net(record: Dictionary, title: String) -> void:
	var points: PackedVector3Array = record.points
	var base: Array = record.faces[3]
	var a: Vector3 = points[base[0]]
	var normal: Vector3 = (points[base[1]] - a).cross(points[base[2]] - a).normalized()
	var identity := true
	var base_fixed := true
	var hinge_fixed := true
	var rigid := true
	var planar := true
	var outside := true
	for i in range(4):
		identity = identity and Record.unfold_transform(record, i, 0.0) == Transform3D.IDENTITY
		var face: Array = record.faces[i]
		for amount in [0.0, 0.1, 0.37, 0.6, 0.99, 1.0]:
			var transform := Record.unfold_transform(record, i, amount)
			if i == 3: base_fixed = base_fixed and transform == Transform3D.IDENTITY
			rigid = rigid and absf(transform.basis.determinant() - 1.0) < 0.00001
			for j in range(3):
				var index: int = face[j]
				var p: Vector3 = points[index]
				var next: Vector3 = points[face[(j + 1) % 3]]
				var length_error := absf((transform * p).distance_to(transform * next) - p.distance_to(next))
				max_length_error = maxf(max_length_error, length_error)
				rigid = rigid and length_error < 0.00001
				if base.has(index):
					var error := (transform * p).distance_to(p)
					max_hinge_error = maxf(max_hinge_error, error)
					hinge_fixed = hinge_fixed and error < 0.00001
				if amount == 1.0:
					var error := absf(normal.dot(transform * p - a))
					max_planarity_error = maxf(max_planarity_error, error)
					planar = planar and error < 0.00001
		if i != 3:
			var shared: Array[int] = []
			var moving := -1
			var inside := -1
			for index: int in face:
				if base.has(index): shared.append(index)
				else: moving = index
			for index: int in base:
				if not face.has(index): inside = index
			var hinge: Vector3 = (points[shared[1]] - points[shared[0]]).normalized()
			var in_offset: Vector3 = points[inside] - points[shared[0]]
			var out_offset: Vector3 = Record.unfold_transform(record, i, 1.0) * points[moving] - points[shared[0]]
			outside = outside and (in_offset - hinge * in_offset.dot(hinge)).dot(out_offset - hinge * out_offset.dot(hinge)) < 0.0
	check(identity, title + ": closed amount is exact identity")
	check(base_fixed, title + ": base face stays fixed through every stage")
	check(hinge_fixed, title + ": both shared hinge vertices remain fixed")
	check(rigid, title + ": all edge lengths and orientation remain rigid throughout")
	check(planar, title + ": every unfolded corner reaches the base plane")
	check(outside, title + ": each flap unfolds outside the base triangle")
	var display := Record.display_basis(record)
	var centre := (points[0] + points[1] + points[2] + points[3]) * 0.25
	var outward := normal
	if outward.dot(centre - a) > 0.0: outward = -outward
	check((display * outward).is_equal_approx(Vector3.DOWN) and absf(display.determinant() - 1.0) < 0.00001, title + ": display frame puts outward base normal down without reflection")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	check(Record.capture(null).points.is_empty() and not str(Record.capture(null).error).is_empty(), "Missing source returns a useful empty record")
	var not_source := Node3D.new()
	root.add_child(not_source)
	check(Record.capture(not_source).points.is_empty(), "Unrelated node returns an empty record")
	not_source.queue_free()
	# Dynamic loading follows XRTools autoload setup.
	source = load(SOURCE).instantiate()
	check(not str(Record.capture(source).error).is_empty(), "Source outside the tree is not assumed ready")
	source.set("snap_to_shelf", false)
	source.set("freeze", true)
	root.add_child(source)
	source.set_process(false)
	source.set_physics_process(false)
	await physics_frame
	var record := Record.capture(source)
	check_geometry(record, "Default tetrahedron")
	if str(record.error).is_empty(): check_net(record, "Default tetrahedron")
	var original := source_state()
	var signature: int = record.signature
	var stable := true
	for i in range(16): stable = stable and Record.capture(source).signature == signature
	check(stable, "Repeated unchanged reads have a stable signature")
	check(source_state() == original, "Reading and unfolding never change the source, collision or material")
	var copy := Record.capture(source)
	copy.points[0] = Vector3(20, 30, 40)
	copy.faces[0][0] = 200
	copy.triangles[0].vertices[0] = Vector3(40, 30, 20)
	copy.triangles[0].normals[0] = Vector3(2, 3, 4)
	check(Record.capture(source).signature == signature and source_state() == original, "Returned arrays are independent copies")
	source.transform = Transform3D(Basis.from_euler(Vector3(0.3, -0.7, 0.2)).scaled_local(Vector3(1.7, 0.6, 1.2)), Vector3(4, 2, -3))
	var transformed := Record.capture(source)
	check_geometry(transformed, "Nonuniformly transformed root")
	check(transformed.signature == signature, "Root movement and nonuniform scale preserve source-local geometry signature")
	if str(transformed.error).is_empty(): check_net(transformed, "Nonuniformly transformed root")
	source.set("tetrahedron_scale", 0.35)
	check(not str(Record.capture(source).error).is_empty(), "Changed source data with stale rendered mesh is rejected")
	source.call("_rebuild_tetrahedron")
	var resized := Record.capture(source)
	check_geometry(resized, "Rebuilt smaller tetrahedron")
	check(resized.signature != signature, "A source geometry change updates the signature")
	if str(resized.error).is_empty(): check_net(resized, "Rebuilt smaller tetrahedron")
	var mesh := source.get_node("MeshInstance3D") as MeshInstance3D
	mesh.position = Vector3(0.1, 0, 0)
	check(not str(Record.capture(source).error).is_empty(), "Rendered mesh displaced from geometry is rejected")
	mesh.position = Vector3.ZERO
	source.set("tetrahedron_scale", 0.0)
	check(Record.capture(source).points.is_empty(), "Collapsed geometry is rejected without rebuilding the source")
	check(Record.unfold_transform({}, 0, 1.0) == Transform3D.IDENTITY and Record.display_basis({}) == Basis.IDENTITY, "Empty record has safe identity staging")
	var passed := true
	for item in checks: passed = passed and bool(item.passed)
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks, "max_hinge_error": max_hinge_error,
		"max_planarity_error": max_planarity_error, "max_length_error": max_length_error}, "\t"))
	file.close()
	source.queue_free()
	await process_frame
	print("POLYHEDRA RECORD ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)

extends SceneTree
## Exact arithmetic used by the new one-centre prose walkthrough.
func _initialize() -> void:
	var latest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-09-procedural-generation-complete-readings/latest-run.json"))
	var path: String = "res://doc/book/iterations/2026-10-09-procedural-generation-complete-readings/"+latest.directory+"/PG_Sculpted_Forms/printed/"
	var model = load(path+"sample.gd").new()
	model.sample([Vector3(0,1,0)],0.5)
	assert(model.origin == Vector3(-1,0,-1))
	assert(Vector3i(((Vector3(0,1,0)-model.origin)/model.cell_size).floor()) == Vector3i(2,2,2))
	assert(model.cells.size() == 125)
	var faces: Array = model.faces()
	assert(faces.has([Vector3i(4,2,2),Vector3i.RIGHT]))
	assert(not faces.any(func(f):return f[0] == Vector3i(2,2,2)))
	var mesh: ArrayMesh = load(path+"faces.gd").build([[Vector3i(4,2,2),Vector3i.RIGHT]],model.origin,0.5)
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert(vertices.size() == 6)
	for vertex in vertices: assert(is_equal_approx(vertex.x,1.25))
	FileAccess.open("res://doc/book/iterations/2026-10-09-procedural-generation-revised/walkthrough-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"checks":7,"cell_count":125,"face_x":1.25,"scope":"New prose example executed against exact current printed sampling and assembly code."},"  "))
	print("PG WALKTHROUGH 7/7")
	quit()

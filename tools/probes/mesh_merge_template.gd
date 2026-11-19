extends SceneTree
## Off-tree prefab construction must preserve the same vertices as a live mesh.
func _initialize() -> void:
	run.call_deferred()

func template() -> Node3D:
	var node := Node3D.new()
	node.position = Vector3(9, 8, 7)
	var group := Node3D.new()
	group.transform = Transform3D(Basis(Vector3.UP, .7).scaled(Vector3(2, 1, 3)), Vector3(1, 2, 3))
	node.add_child(group)
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.position = Vector3(-2, .5, 1)
	group.add_child(mesh)
	return node

func run() -> void:
	var detached := template()
	var live := template()
	root.add_child(live)
	var merge = load("res://commons/artifacts/mesh_merge.gd")
	var a: PackedVector3Array = merge.merge(detached).mesh.get_faces()
	var b: PackedVector3Array = merge.merge(live).mesh.get_faces()
	var passed := a.size() == b.size() and a.size() > 0
	for i in mini(a.size(), b.size()):
		passed = passed and a[i].is_equal_approx(b[i])
	print("MESH_MERGE_TEMPLATE ", JSON.stringify({"passed":passed,"vertices":a.size()}))
	detached.free(); live.free()
	await process_frame
	quit(0 if passed else 1)

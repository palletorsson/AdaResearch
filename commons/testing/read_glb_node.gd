extends SceneTree
## Print the world transform of a named node in one or more .glb files, and the
## delta between the first two. Used to read back a hand-edit from the console
## editor (e.g. where the BackPanel was moved to).
##   godot --path . --xr-mode off --no-window --script res://commons/testing/read_glb_node.gd -- --node=BackPanel --files=A.glb,B.glb

var _node_name := "BackPanel"
var _files: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--node="):
			_node_name = s.split("=", true, 1)[1]
		elif s.begins_with("--files="):
			_files = Array(s.split("=", true, 1)[1].split(","))
	_run()


func _run() -> void:
	var positions: Array = []
	for f in _files:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_file(f, state)
		if err != OK:
			print("  ! load failed %s (%d)" % [f, err]); positions.append(null); continue
		var scene: Node = doc.generate_scene(state)
		var root := Node3D.new()
		get_root().add_child(root)
		root.add_child(scene)
		var found: Node3D = _find(scene)
		if found == null:
			print("  ! node '%s' not in %s" % [_node_name, f]); positions.append(null)
		else:
			var p: Vector3 = found.global_transform.origin
			var r: Vector3 = found.global_transform.basis.get_euler() * 57.2958
			print("%s  pos=(%.4f, %.4f, %.4f)  rot=(%.2f, %.2f, %.2f)" % [f.get_file(), p.x, p.y, p.z, r.x, r.y, r.z])
			positions.append(p)
		root.queue_free()
		await process_frame

	if positions.size() >= 2 and positions[0] != null and positions[1] != null:
		var d: Vector3 = positions[1] - positions[0]
		print("DELTA (file2 - file1) = (%.4f, %.4f, %.4f)" % [d.x, d.y, d.z])
	quit()


func _find(n: Node) -> Node3D:
	if n.name == _node_name and n is Node3D:
		return n
	for c in n.get_children():
		var r := _find(c)
		if r != null:
			return r
	return null

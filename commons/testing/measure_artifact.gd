extends SceneTree
## Print the world-space size of an artifact (overall + a named sub-node).
##   godot --path . --xr-mode off --no-window --script res://commons/testing/measure_artifact.gd -- --scene=res://...tscn [--part=Console]

var _scene := ""
var _part := "Console"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--scene="): _scene = s.split("=", true, 1)[1]
		elif s.begins_with("--part="): _part = s.split("=", true, 1)[1]
	_run()


func _run() -> void:
	var root := Node3D.new(); get_root().add_child(root)
	var art: Node3D = (ResourceLoader.load(_scene) as PackedScene).instantiate()
	root.add_child(art)
	await process_frame
	await create_timer(1.0).timeout
	await process_frame

	var whole := _world_aabb(art)
	print("[size] OVERALL  W=%.3f  H=%.3f  D=%.3f m   (y %.2f → %.2f)" % [whole.size.x, whole.size.y, whole.size.z, whole.position.y, whole.position.y + whole.size.y])
	var part := _find(art, _part)
	if part:
		var pb := _world_aabb(part)
		print("[size] %s  W=%.3f  H=%.3f  D=%.3f m   (y %.2f → %.2f)" % [_part, pb.size.x, pb.size.y, pb.size.z, pb.position.y, pb.position.y + pb.size.y])
	quit()


func _find(node: Node, name_frag: String) -> Node3D:
	var f := name_frag.to_lower()
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Node3D and String(n.name).to_lower().contains(f):
			return n
		for c in n.get_children(): stack.append(c)
	return null


func _world_aabb(node: Node) -> AABB:
	var box := AABB(); var first := true; var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			ab = (n as Node3D).global_transform * ab
			if first: box = ab; first = false
			else: box = box.merge(ab)
		for c in n.get_children(): stack.append(c)
	return box

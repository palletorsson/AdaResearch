extends "res://commons/testing/capture_interactable_demo_config.gd"
## Uses the existing gallery capture, adding a descriptive runtime inventory.
## No inputs are activated: collision counts do not prove usable controls.

func _combined_aabb(node: Node3D) -> AABB:
	var box: AABB = super._combined_aabb(node)
	var groups: Array = []
	for child in node.get_children():
		var label := String(child.name)
		if label.begins_with("Control_") or label.begins_with("ExtraBtn_") or label.begins_with("Compound_") or label.begins_with("NewModule_"):
			groups.append(_describe_group(child))
	var data := {
		"scope": "Default demo instantiated in a studio capture; no player input or headset test",
		"aabb_position": [box.position.x, box.position.y, box.position.z],
		"aabb_size": [box.size.x, box.size.y, box.size.z],
		"groups": groups,
		"total": _describe_group(node),
	}
	var f := FileAccess.open("res://doc/reports/interfaces-2026-09-20/runtime.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	return box

func _describe_group(node: Node) -> Dictionary:
	var result := {"node": String(node.name), "nodes": 0, "meshes": 0, "collision_objects": 0, "rigid_bodies": 0, "script_paths": []}
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		result["nodes"] += 1
		if n is MeshInstance3D: result["meshes"] += 1
		if n is CollisionObject3D: result["collision_objects"] += 1
		if n is RigidBody3D: result["rigid_bodies"] += 1
		if n.get_script() != null:
			var path: String = n.get_script().resource_path
			if path not in result["script_paths"]: result["script_paths"].append(path)
		for child in n.get_children(): stack.append(child)
	return result

extends RefCounted
## Reuse the shipped staging fade/load path; direct editor boots use SceneTree.
const ROOM := "res://commons/scenes/room_memory.tscn"
const MUSEUM := "res://commons/scenes/endless_museum_staged.tscn"

static func go(from: Node, scene: String) -> bool:
	var ancestor := from.get_parent()
	while ancestor != null:
		if ancestor.has_method("_edit_flush"): ancestor.call("_edit_flush")
		if ancestor.has_method("load_scene") and ancestor.has_signal("scene_loaded"):
			ancestor.call_deferred("load_scene",scene)
			return true
		ancestor = ancestor.get_parent()
	if from.get_tree().current_scene != null:
		from.get_tree().call_deferred("change_scene_to_file",scene)
		return true
	return false

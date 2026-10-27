extends RefCounted
## A console can only bind a sibling on its own streamed floor.
static func find_artifact(hall: Node, key: String) -> Node3D:
	for mount in hall.get_children():
		var node := mount.get_node_or_null("Artifact")
		if node is Node3D and str(node.get_meta("artifact_lookup_name", "")) == key:
			return node
	return null

static func light(host: Node3D) -> void:
	var lamp := OmniLight3D.new()
	lamp.position=Vector3(0,4,3)
	lamp.omni_range=18
	lamp.light_energy=3
	host.add_child(lamp)

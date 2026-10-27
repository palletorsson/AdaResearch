extends RefCounted
## Resolve within this floor, including after an editor move or source-backed copy.
static func find(receiver: Node3D, lookup: String) -> Node3D:
	var floor_root: Node = receiver.get_parent()
	while floor_root!=null and not floor_root.has_meta("void_content_floor"):
		floor_root = floor_root.get_parent()
	if floor_root==null:return null
	var id := str(receiver.get_meta("config_source_id",""))
	for host in floor_root.get_children():
		var work := host.get_node_or_null("Artifact") as Node3D
		if work!=null and work.get_meta("artifact_lookup_name","")==lookup and (id.is_empty() or str(host.name)==id):
			return work
	return null

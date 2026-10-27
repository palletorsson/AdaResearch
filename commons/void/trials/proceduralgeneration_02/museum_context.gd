extends Node3D
## Read-only floor-local view of the museum's artifact records. The original
## workshop can bind its original algorithms without requiring the museum shell.
var VESTIBULE_H := 0
var _edit_records: Array:
	get:
		var records: Array = []
		var content: Node3D = get_parent()
		var index := int(get_meta("void_content_floor"))
		for item in content.data.floors[index].artifacts:
			var mount := get_node_or_null(str(item.id))
			if mount == null: continue
			var artifact := mount.get_node_or_null("Artifact")
			if artifact != null: records.append({"node":artifact,"token":str(item.artifact)})
		return records

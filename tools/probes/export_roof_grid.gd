extends "res://tools/probes/export_void_editor.gd"

func run() -> void:
	# Refresh just the fixed roof mesh. Keep all authored artifact models.
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content = true
	root.add_child(building)
	await process_frame
	manifest = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	manifest.floors["0"].structure = snapshot(building.floors[0],"floor-0")
	manifest.revision = str(manifest.revision) + "-origin-grid"
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	building.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

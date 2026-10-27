extends "res://tools/probes/export_void_editor.gd"
## Add two real prefab snapshots without rebuilding curated artifact models.
func run() -> void:
	manifest = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var host := Node3D.new();host.name="LaserPrefabExport";root.add_child(host);current_scene=host
	for kind in ["smoke_supply"]:
		var path := "res://commons/void/smoke_supply.tscn"
		var node: Node3D=load(path).instantiate();host.add_child(node)
		await process_frame
		var model := snapshot(node,"prop-"+kind)
		model.thumbnail=await thumbnail(node,"prop-"+kind)
		manifest.props[kind]=model
		node.queue_free();await process_frame
	manifest.revision=str(Time.get_unix_time_from_system())+"-smoke"
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	print("SMOKE_EXPORT ",JSON.stringify({"failures":failures}))
	quit(0 if failures.is_empty() else 1)

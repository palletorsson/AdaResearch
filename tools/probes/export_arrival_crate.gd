extends "res://tools/probes/export_void_editor.gd"

func run() -> void:
	var crate := preload("res://commons/void/arrival_crate.tscn").instantiate()
	root.add_child(crate)
	await process_frame
	manifest = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var model := snapshot(crate,"prop-arrival_crate")
	model.thumbnail = await thumbnail(crate,"prop-arrival_crate")
	manifest.props["arrival_crate"] = model
	manifest.revision = str(manifest.get("revision","")) + "-arrival"
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	crate.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

extends "res://tools/probes/export_void_editor.gd"

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var rooms:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/rooms.json"))
	var exported:Dictionary={}
	for item in rooms.floors[4].artifacts:
		if item.artifact != "trace_paint_box": continue
		var box:Node3D=load("res://commons/artifacts/trace_paint_box/trace_paint_box.tscn").instantiate()
		box.apply_grid_config(item.config)
		root.add_child(box)
		await process_frame
		exported[str(item.id)]={"artifact":item.artifact,"config":item.config.duplicate(true),"parts":{},"model":snapshot(box,"4-"+str(item.id))}
		box.queue_free()
		await process_frame
	FileAccess.open(out.path_join("trace-paint-boxes.json"),FileAccess.WRITE).store_string(JSON.stringify({"artifacts":exported,"failures":failures},"\t"))
	quit(0 if failures.is_empty() else 1)

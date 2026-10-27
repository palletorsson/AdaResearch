extends "res://tools/probes/export_void_editor.gd"
## Export only the real changed assembly; do not allocate the 209-floor frame.
func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var host := Node3D.new();host.name="ScaleDescentExport";host.set_meta("void_content_floor",14)
	root.add_child(host);current_scene=host
	var rooms: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/rooms.json"))
	var item: Dictionary={}
	for record in rooms.floors[14].artifacts:
		if record.id=="sequence":item=record;break
	assert(not item.is_empty())
	var artifact: Node3D=load("res://commons/void/trials/transformation/introduction_mezzanine.gd").new()
	host.add_child(artifact);artifact.apply_grid_config(item.config)
	artifact.process_mode=Node.PROCESS_MODE_DISABLED
	await artifact.prepare_editor_preview()
	await process_frame;await RenderingServer.frame_post_draw
	var data: Dictionary={"artifact":item.artifact,"config":item.config.duplicate(true),"parts":{}}
	for child in artifact.get_children():
		if child is Node3D and artifact.part_defaults.has(str(child.name)):
			var part: Dictionary=snapshot(child,"14-sequence-"+str(child.name))
			part["default"]=artifact.part_defaults[str(child.name)]
			part["scale"]=[child.scale.x,child.scale.y,child.scale.z]
			data.parts[str(child.name)]=part
	FileAccess.open(out.path_join("assembly.json"),FileAccess.WRITE).store_string(JSON.stringify({"artifact":data,"failures":failures,"notes":["Actual native assembly at its upper dock. The electrical shader is a static transparent preview with the original conducting strands; cycling and field collision run in Godot."]},"  "))
	host.queue_free();await process_frame
	print("SCALE_EXPORT_RESULT ",JSON.stringify({"parts":data.parts.size(),"failures":failures}));quit(0 if failures.is_empty() else 1)

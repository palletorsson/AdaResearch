extends "res://tools/probes/export_void_editor.gd"
## Refresh only this assembly after a geometry/editability change.
func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var host:=Node3D.new();root.add_child(host);current_scene=host
	var artifact: Node3D=load("res://commons/artifacts/movable_pivot/movable_pivot.tscn").instantiate();host.add_child(artifact)
	await artifact.prepare_editor_preview();await process_frame;await RenderingServer.frame_post_draw
	var data: Dictionary={"artifact":"movable_pivot_walkway","config":{"pivot_x":0,"angle_degrees":0},"parts":{}}
	for child in artifact.get_children():
		if child is Node3D and artifact.part_defaults.has(str(child.name)):
			var part: Dictionary=snapshot(child,"15-movable-pivot-"+str(child.name))
			part["default"]=artifact.part_defaults[str(child.name)];part["scale"]=[1,1,1];data.parts[str(child.name)]=part
	FileAccess.open(out.path_join("assembly.json"),FileAccess.WRITE).store_string(JSON.stringify({"artifact":data,"failures":failures},"  "))
	host.queue_free();for i in 5:await process_frame
	quit(0 if failures.is_empty() else 1)

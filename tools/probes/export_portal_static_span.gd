extends "res://tools/probes/export_void_editor.gd"
func run() -> void:
	var building: Node3D=load("res://commons/void/architecture.gd").new()
	building.stream_content=true
	root.add_child(building)
	current_scene=building
	building.content.load_floor(11)
	for i in 40: await physics_frame
	await RenderingServer.frame_post_draw
	building.process_mode=Node.PROCESS_MODE_DISABLED
	manifest=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var span: Node3D=building.content.exhibits["11/sky-walk"].get_node("Artifact")
	var item: Dictionary=building.content.data.floors[11].artifacts.filter(func(a):return a.id=="sky-walk")[0]
	var data: Dictionary={"artifact":item.artifact,"config":item.config.duplicate(true),"parts":{}}
	for child in span.get_children():
		if child is Node3D and span.part_defaults.has(str(child.name)):
			var part: Dictionary=snapshot(child,"11-sky-walk-%s"%child.name)
			part["default"]=span.part_defaults[str(child.name)]
			part["scale"]=[child.scale.x,child.scale.y,child.scale.z]
			data.parts[str(child.name)]=part
	manifest.floors["11"].artifacts["sky-walk"]=data
	manifest.props.portal_span=snapshot(span,"prop-portal_span")
	var bounds: AABB=span._mesh_bounds(span,span)
	manifest.props.portal_span["bounds"]=[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]
	manifest.props.portal_span["thumbnail"]=await thumbnail(span,"prop-portal_span")
	manifest.revision="portals-static-pink-"+str(Time.get_unix_time_from_system())
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t",true,true))
	building.queue_free()
	await process_frame
	print("STATIC_PORTALS_EXPORT ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

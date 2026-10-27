extends "res://comparison_tools/export_base.gd"
## This adapter runs against a complete, isolated historical Git archive.
var complete := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--public-base="): public_base=arg.trim_prefix("--public-base=")
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	run.call_deferred()

func discover(node: Node, items: Array[Node3D]) -> void:
	if node is Node3D and node.has_meta("artifact_lookup_name"):
		items.append(node)
		return
	for child in node.get_children(): discover(child,items)

func run() -> void:
	var map_name := "Trans_Rotation"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):map_name=arg.trim_prefix("--map=")
	root.size = Vector2i(1400,1000)
	var world := Node3D.new()
	world.name = "HistoricalGridExport"
	root.add_child(world)
	current_scene = world
	var grid: Node3D = load("res://commons/grid/grid_system.tscn").instantiate()
	grid.map_name = map_name
	grid.bare_world = false
	grid.prefer_corridor_variant = false
	grid.map_generation_complete.connect(func():complete=true)
	world.add_child(grid)
	var started := Time.get_ticks_msec()
	while not complete and Time.get_ticks_msec()-started < 120000: await process_frame
	if not complete:
		push_error("Historical Grid build did not complete")
		quit(1)
		return
	for i in 40: await process_frame
	cache_soft_body_meshes(grid)
	var sources: Array[Node3D] = []
	discover(grid,sources)
	var objects: Array = []
	for source in sources:
		if source.has_method("prepare_editor_preview"): await source.prepare_editor_preview()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	for source in sources:
		var cell: Vector2i = source.get_meta("grid_cell",Vector2i(-1,-1))
		var pose := grid.global_transform.affine_inverse()*source.global_transform
		var config := {}
		for key in source.get_meta_list():
			if str(key).begins_with("config_"):
				config[str(key).trim_prefix("config_")] = source.get_meta(key)
		objects.append({"id":"%d,%d" % [cell.x,cell.y],"artifact":str(source.get_meta("artifact_lookup_name")),"cell":[cell.x,cell.y],"position":[pose.origin.x,pose.origin.y,pose.origin.z],"rotation":[source.rotation_degrees.x,source.rotation_degrees.y,source.rotation_degrees.z],"scale":[source.scale.x,source.scale.y,source.scale.z],"configuration":config,"sourceScene":source.scene_file_path,"sourceScript":source.get_script().resource_path if source.get_script()!=null else "","model":snapshot(source,map_name+"-historic-%d-%d" % [cell.x,cell.y])})
	for source in sources: source.hide()
	var structure := snapshot(grid,map_name+"-historic-structure")
	for source in sources: source.show()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_name+"/map_data.json"))
	var dimensions: Dictionary = data.get("map_info",{}).get("dimensions",{})
	var width := float(dimensions.get("width",7))
	var depth := float(dimensions.get("depth",20))
	var camera := Camera3D.new()
	world.add_child(camera)
	var centre := Vector3((width-1)*.5,0,(depth-1)*.5)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(depth,width/1.4)*1.18
	camera.far = 2000
	camera.position = centre+Vector3(.65,.95,1).normalized()*maxf(depth,width)*1.5
	camera.look_at(centre)
	camera.current = true
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var image_name := map_name+"-historic-native.png"
	var image_error := root.get_texture().get_image().save_png(out.path_join(image_name))
	if image_error != OK:failures.append("Native reference image: %d" % image_error)
	var result := {"version":1,"map":map_name,"ground_y":0.5,"cell_size":grid.cube_size+grid.gutter,"width":width,"depth":depth,"structure":structure,"objects":objects,"reference":{"url":public_base+"/"+image_name,"caption":"Actual historical Grid scenes rendered by Godot 4.6. Static capture; camera is an export inspection view."},"shader_material_previews":shader_count,"notes":manifest.notes,"failures":failures}
	var materials: Array = []
	var support: Array = JSON.parse_string(FileAccess.get_file_as_string("res://external-dependencies.json"))
	for item: Dictionary in support:
		if bool(item.get("visual_substitute",false)) and ResourceLoader.has_cached("res://"+str(item.file)):
			materials.append(item.file)
	result["compatibility_materials_used"] = materials
	if not materials.is_empty():result.reference.caption += " Installed substitutes for unversioned rack materials; exact historical palette is unverified."
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("HISTORIC_GRID_EXPORT ",JSON.stringify({"map":map_name,"objects":objects.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)

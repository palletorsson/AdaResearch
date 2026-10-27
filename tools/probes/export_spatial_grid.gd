extends "res://tools/probes/export_void_editor.gd"
## Snapshot the actual configured GridSystem, without changing map authoring.
var complete := false
func find_artifacts(node: Node,items: Array[Node3D]) -> void:
	if node is Node3D and node.has_meta("artifact_lookup_name"):
		items.append(node);return
	for child in node.get_children():find_artifacts(child,items)

func run() -> void:
	var map_name := "Trans_Rotation"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):map_name = arg.trim_prefix("--map=")
	var world := Node3D.new();world.name = "GridComparisonExport";root.add_child(world);current_scene = world
	var grid: Node3D = load("res://commons/grid/grid_system.tscn").instantiate()
	grid.map_name = map_name;grid.bare_world = true;grid.skip_player_spawn = true;grid.prefer_corridor_variant = false
	grid.build_finished.connect(func():complete = true);world.add_child(grid)
	var started := Time.get_ticks_msec()
	while not complete and Time.get_ticks_msec()-started<150000:await process_frame
	if not complete:push_error("Source GridSystem did not complete");quit(1);return
	for i in 30:await process_frame
	cache_soft_body_meshes(grid)
	var sources: Array[Node3D] = [];find_artifacts(grid,sources)
	var items: Array = []
	for source in sources:
		if source.has_method("prepare_editor_preview"):await source.prepare_editor_preview()
	for source in sources:
		var cell: Vector2i = source.get_meta("grid_cell",Vector2i(-1,-1))
		var key := "%s-%d-%d"%[map_name,cell.x,cell.y]
		var model := snapshot(source,key)
		items.append({"id":"%d,%d"%[cell.x,cell.y],"artifact":str(source.get_meta("artifact_lookup_name")),"cell":[cell.x,cell.y],"position":[source.position.x,source.position.y,source.position.z],"rotation":[source.rotation_degrees.x,source.rotation_degrees.y,source.rotation_degrees.z],"scale":[source.scale.x,source.scale.y,source.scale.z],"model":model})
		source.hide()
	var structure := snapshot(grid,map_name+"-structure")
	for source in sources:source.show()
	var result := {"version":1,"map":map_name,"ground_y":0.5,"cell_size":grid.cube_size+grid.gutter,"structure":structure,"objects":items,"failures":failures,"scope":"Actual configured source GridSystem snapshot. Static geometry; interactions remain in Godot."}
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("COMPARISON_EXPORT ",JSON.stringify({"map":map_name,"objects":items.size(),"failures":failures}));quit(0 if failures.is_empty() else 1)

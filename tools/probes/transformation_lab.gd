extends "res://tools/probes/movable_pivot_probe.gd"
## Shared compiled expression, actual ingredients, independent member editing.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(pictures)
	host=Node3D.new();root.add_child(host);current_scene=host
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("dedad3");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.55;world.environment=env;host.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-35,0);sun.light_energy=1.2;host.add_child(sun)
	var building: Node3D=load("res://commons/void/architecture.gd").new();host.add_child(building);await ticks(8)
	artifact=building.content.exhibits["1/variation"].get_node("Artifact");await artifact.prepare_editor_preview();await ticks(4)
	var document: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(artifact.recipe_document));var settings: Dictionary=document.settings
	check("all copies and supports are independently editable",artifact.part_defaults.size()==int(settings.count)+(5 if settings.staging=="table" else 0))
	var source_ok:=true;var bounds:=AABB();var first:=true;var copies: Array=[];var overlap:=0
	for i in int(settings.count):
		var member: Node3D=artifact.get_node("Copy%02d"%(i+1));var source: Node3D=member.get_node("Source")
		if settings.source=="portal":source_ok=source_ok and source.ready_mesh and source.has_node("OrientationCorner") and absf(source.get_meta("outer_size").x-source.get_meta("outer_size").y)<.00001
		else:
			var token: String="timber_plank_2m" if settings.source=="plank" else "do_not_cross_barrier"
			source_ok=source_ok and source.token==token and source.original.scene_file_path==source.source_scene
		var box: AABB=member.transform*artifact._bounds(member)
		for previous in copies:
			if box.intersects(previous):overlap+=1
		copies.append(box);bounds=box if first else bounds.merge(box);first=false
	check("copies use actual catalogue scenes or native square Boolean geometry",source_ok)
	var baseline: Dictionary=artifact.part_defaults["Copy01"].duplicate(true);var pose: Array=baseline.position
	artifact.apply_grid_config({"parts":{"Copy01":{"position":[pose[0]+.2,pose[1],pose[2]],"rotation":[10,17,23]}}})
	check("an individual copy moves and rotates independently",artifact.get_node("Copy01").position.distance_to(Vector3(pose[0]+.2,pose[1],pose[2]))<.0001 and absf(artifact.get_node("Copy01").rotation_degrees.z-23)<.001)
	artifact.apply_grid_config({"parts":{}})
	# Reset restores source defaults through a rebuild, rather than retaining the
	# probe's transient edit in exported defaults or the saved user arrangement.
	artifact.rebuild();await artifact.prepare_editor_preview();await ticks(4)
	var replica: Node3D=load("res://commons/modular/recipe_area.tscn").instantiate();replica.apply_grid_config({"recipe":"transformation_variant","recipe_document":artifact.recipe_document,"only_parts":["Copy01"],"parts":{"Copy01":{"position":[0,0,0],"rotation":[0,35,0]}}});replica.position=Vector3(0,-30,0);host.add_child(replica);await replica.prepare_editor_preview()
	check("copied member retains its frozen recipe and insertion point",replica.get_child_count()==1 and replica.get_node("Copy01").position.is_equal_approx(Vector3.ZERO));replica.queue_free();await ticks(4)
	var full: AABB=artifact._bounds(artifact);var centre: Vector3=full.get_center();var distance: float=maxf(full.size.length()*1.25,3.0)
	# Keep the composition legible; context is the actual trial floor, with remote
	# architectural geometry hidden only for this isolated specimen picture.
	for geometry in building.find_children("*","GeometryInstance3D",true,false):
		if not artifact.is_ancestor_of(geometry):geometry.hide()
	camera=Camera3D.new();camera.fov=45;host.add_child(camera)
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	await shot("native",centre+Vector3(1,.9,1.4).normalized()*distance,centre)
	var failed: Array=checks.filter(func(c):return not c.passed)
	var overhang:=0
	if settings.staging=="table":
		for box in copies:
			if box.position.x< -1.8 or box.end.x>1.8 or box.position.z< -1.2 or box.end.z>1.2:overhang+=1
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"metrics":{"parts":artifact.part_defaults},"findings":{"overlap_candidates":overlap,"table_overhang":overhang,"envelope":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]},"scope":"Actual saved static recipe, authored source geometry, native square Boolean frame, independent member changes/copy and screenshot. AABB overlap/overhang are findings. No joints, hand interaction, route traversal or headset acceptance."},"  "))
	# CSG collision generation can still be queued on the physics server. Allow
	# deferred destruction to complete before ending the isolated render job.
	building.queue_free();await ticks(6);host.queue_free();await ticks(4)
	print("TRANSFORMATION_LAB_DONE ",JSON.stringify(failed));quit(0 if failed.is_empty() else 1)

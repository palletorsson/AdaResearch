extends SceneTree
var checks := 0
var failures: Array[String] = []
var pointer: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print(("PASS " if ok else "FAIL ")+label)
func press(button: Node3D) -> void:
	var area: Node3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer,area,area.global_position)
	XRToolsPointerEvent.released(pointer,area,area.global_position)
func finish(cube: Node) -> void:
	for i in 40: cube.call("_process",0.51)
func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	pointer = Node3D.new()
	world.add_child(pointer)
	var cube = load("res://commons/primitives/animatedcubebuilder/animatedcubebuilder.tscn").instantiate()
	cube.position = Vector3(4,1.4,5)
	cube.rotation_degrees.y = 35
	cube.set_meta("config_discovery","1")
	world.add_child(cube)
	cube.set_process(false)
	var panel: Node3D = cube.get_node("ExperimentPanel")
	await create_timer(0.6).timeout
	check(cube.handle_nodes.size()==8 and cube.edge_lines.size()==12 and cube.triangle_meshes.size()==12,"eight handles, twelve edges, twelve surface patches")
	check(not cube.handle_nodes[0].enabled,"handles unavailable during assembly")
	cube.call("_process",0.51)
	press(panel.get_node("PauseButton"))
	var step: int = cube.animation_step
	cube.call("_process",4.0)
	check(cube.animation_step==step and cube.discovery_paused,"pointer pause freezes assembly advancement")
	press(panel.get_node("PauseButton"))
	finish(cube)
	check(cube.get_current_phase()=="complete" and cube.handle_nodes[0].enabled,"resume completes and enables corner handles")
	for i in 8: check(cube.handle_nodes[i].get_node("VertexNumber").text=="v%d"%i,"vertex number matches source index")
	var old_edges: Array = cube.edges.duplicate(true)
	var old_triangles: Array = cube.triangles.duplicate(true)
	var moved: Vector3 = cube.vertices[6] + Vector3(0.25,0.3,0.15)
	cube.handle_nodes[6].global_position = cube.to_global(moved)
	cube.call("_process",0.1)
	await process_frame
	check(cube.vertices[6].is_equal_approx(moved),"translated rotated handle movement is stored in artifact coordinates")
	check(cube.edges==old_edges and cube.triangles==old_triangles,"deformation preserves connection lists")
	var tri: PackedVector3Array = cube.triangle_meshes[2].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(tri[2].is_equal_approx(moved),"surface mesh follows moved corner")
	var edge: Node3D = cube.edge_lines[5]
	check(edge.position.is_equal_approx((cube.vertices[5]+moved)*0.5),"incident edge follows moved corner")
	press(panel.get_node("DiagonalButton"))
	check(cube._diagonal_lines.size()==6,"diagonals derived from triangle edges exclude twelve cube edges")
	check(cube._diagonal_lines.all(func(line): return line.visible),"six diagonals become visible")
	for i in cube._diagonal_pairs.size():
		var pair: Vector2i = cube._diagonal_pairs[i]
		check(cube._diagonal_lines[i].position.is_equal_approx((cube.vertices[pair.x]+cube.vertices[pair.y])*0.5),"diagonal follows its actual source pair")
	press(panel.get_node("ReplayButton"))
	check(cube.vertices[6].is_equal_approx(moved),"replay retains the deformed coordinates")
	check(not cube.handle_nodes[6].visible and not cube.handle_nodes[6].enabled,"replay hides and disables handles")
	finish(cube)
	check(cube.triangle_meshes[2].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][2].is_equal_approx(moved),"replayed surface retains deformation")
	press(panel.get_node("RestoreButton"))
	check(cube.vertices==cube._initial_vertices and cube.get_current_phase()=="complete","restore returns all eight initial positions without replay")
	check(cube.edges==old_edges and cube.triangles==old_triangles,"restore preserves connection lists")
	panel.update_readout()
	check(panel.text_label.text.contains("8 points | 12 edges") and panel.text_label.text.contains("12 / 12"),"readout counts actual visible layers")
	# Hidden surfaces must also follow edits, otherwise replay brings back stale geometry.
	cube.apply_grid_config({"closure":"scaffold"})
	finish(cube)
	cube.handle_nodes[6].position = moved
	cube.call("_process",0.1)
	await process_frame
	check(not cube.triangle_meshes[2].visible and cube.triangle_meshes[2].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][2].is_equal_approx(moved),"hidden surface data follows scaffold deformation")
	cube.apply_grid_config({"closure":"strata"})
	finish(cube)
	check(cube.triangle_meshes[2].visible,"strata replay restores visible surfaces")
	var bare = load("res://commons/primitives/animatedcubebuilder/animatedcubebuilder.tscn").instantiate()
	world.add_child(bare)
	bare.set_process(false)
	check(not bare.has_node("ExperimentPanel"),"unconfigured artifact retains no instrument")
	await create_timer(0.6).timeout
	bare.queue_free()
	await process_frame
	await process_frame
	panel.update_readout()
	await process_frame
	var bounds: Vector2 = panel.text_label.get_combined_minimum_size()
	check(bounds.x <= panel.surface.viewport.size.x-64,"readout fits case width")
	check(bounds.y <= panel.surface.viewport.size.y-140,"readout stays above controls")
	# Resolve and stamp the current room's actual configured builder placements.
	var museum: Node = load("res://commons/scenes/endless_museum.tscn").instantiate()
	museum.set("_studio",true)
	museum.set("_headless",true)
	var map_row: Dictionary = museum.call("_derive_map_row","Point_Animatedcube")
	var placed := Node3D.new()
	world.add_child(placed)
	var builder_count := 0
	for entry: Dictionary in map_row.artifacts:
		if entry.token != "animatedcubebuilder": continue
		var cell: Array = entry.tile_cell
		check(museum.call("_stamp",placed,"res://commons/primitives/animatedcubebuilder/animatedcubebuilder.tscn",entry.token,{"x":cell[0],"y":cell[1],"top":0.0},0,1,{},false,0.0,float(entry.rotation),entry.get("config",{})),"actual room builder stamps")
		builder_count += 1
	check(builder_count==2,"map retains two builders for comparison")
	var instruments := 0
	for child in placed.get_children():
		if child.has_node("ExperimentPanel"): instruments += 1
	check(instruments==2,"both map configurations activate their instruments")
	await create_timer(0.6).timeout
	placed.queue_free()
	museum.free()
	await process_frame
	# Check the longest control feedback, not just the short replay caption.
	press(panel.get_node("RestoreButton"))
	panel.update_readout()
	await process_frame
	bounds = panel.text_label.get_combined_minimum_size()
	check(bounds.x <= panel.surface.viewport.size.x-64 and bounds.y <= panel.surface.viewport.size.y-140,"restoration feedback fits above buttons")
	cube.handle_nodes[6].position = moved
	cube.call("_process",0.1)
	await process_frame
	panel.update_readout()
	if "--shot" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		world.add_child(camera)
		var aim: Vector3 = cube.global_position + cube.global_basis.x*0.53
		camera.global_position = aim + cube.global_basis.z*2.8 + Vector3.UP*0.45
		camera.look_at(aim)
		camera.current = true
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color(0.10,0.12,0.15)
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color.WHITE
		env.environment.ambient_light_energy = 0.9
		world.add_child(env)
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ada_run/cube_primary/preview.png")
	var output := "res://ada_run/cube_primary/checks.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): output = arg.trim_prefix("--report=")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual pointer-button events, supplied handle positions in a translated rotated scene, assembly and mesh checks; full-room/headset interaction unverified."},"  "))
	print("RESULT ",checks," ",failures)
	quit(0 if failures.is_empty() else 1)

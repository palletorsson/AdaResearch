extends "res://commons/testing/probe_color_recovery.gd"

func run() -> void:
	seed(2701)
	await museum("Chamber_Color")
	var bench: Node3D = current_scene.find_child("ChromaticStudy",true,false)
	check(bench != null,"mounted chromatic encounter is present")
	if bench == null: quit(1); return
	var grid: Node3D = bench.get_parent()
	while not grid.is_in_group("grid_system"): grid = grid.get_parent()
	var player: CharacterBody3D = current_scene.get("_player")
	var head: Camera3D = current_scene.get("_cam")
	player.set_physics_process(false)
	current_scene.get("_feel").set_process(false)
	player.global_position += bench.to_global(Vector3(2,0.6,-2.5))-head.global_position
	var mm: MultiMesh = grid.get("structure_component").get("multimesh")
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for i in mm.instance_count:
		transforms.append(mm.get_instance_transform(i))
		colors.append(mm.get_instance_color(i))
	var bodies := grid.find_children("*","StaticBody3D",true,false)
	var collisions: Dictionary = {}
	for body in bodies: collisions[body.get_instance_id()] = body.global_transform
	for frame in range(30):
		current_scene.call("_cull_artifacts")
		await process_frame
	check(bench.fire_button.global_position.y > 1.0,"fire control stands at reachable height")
	check(not bench.get_parent().enabled,"museum keeps the bracelet unwearable")
	head.look_at(bench.to_global(Vector3(0,0,1.0)))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/chamber_colour_before.png")
	var area: Area3D = bench.fire_button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(head,area,area.global_position)
	XRToolsPointerEvent.released(head,area,area.global_position)
	check(bench.shots==1,"real fire button launches one native chromatic shot")
	bench.fire_button.pressed.emit()
	check(bench.shots==1,"cooldown rejects an immediate second press")
	var target: Node3D = bench.target
	var shot_color: Color = bench.last_projectile.color_primary
	for frame in range(150):
		await physics_frame
		if bench.impacts==1: break
	check(bench.impacts==1,"projectile physically reaches the target")
	await process_frame
	var nearest := INF
	for i in mm.instance_count:
		nearest=minf(nearest,grid.get_node("GridMultiMesh").to_global(mm.get_instance_transform(i).origin).distance_to(target.global_position))
	print("CHAMBER_NEAREST ",nearest," target ",target.global_position," bench ",bench.global_position," hits required ",target.get("_hits_to_destroy"))
	check(target.get("_hit_count")==1,"one contact counts as one target hit")
	check(not target.get("_destroyed"),"three-hit target survives its first contact")
	var tinted := false
	for mesh in target.get("_visual").get_children():
		if mesh is MeshInstance3D and mesh.material_override is StandardMaterial3D:
			tinted = tinted or mesh.material_override.albedo_color.is_equal_approx(shot_color)
	check(tinted,"target receives the shot's stored colour")
	var changed_colors := 0
	var changed_shapes := 0
	for i in mm.instance_count:
		if not colors[i].is_equal_approx(mm.get_instance_color(i)): changed_colors+=1
		if not transforms[i].is_equal_approx(mm.get_instance_transform(i)): changed_shapes+=1
	check(changed_colors>0,"impact recolours nearby rendered grid cubes")
	check(changed_shapes==changed_colors,"the same nearby samples also change visual transform")
	var stationary := true
	for body in bodies:
		if body != target: stationary = stationary and collisions[body.get_instance_id()].is_equal_approx(body.global_transform)
	check(stationary,"grid collision bodies remain in their original transforms")
	await create_timer(0.9).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/chamber_colour_after.png")
	for hit in range(2):
		bench.fire_button.pressed.emit()
		await create_timer(0.5).timeout
	check(target.get("_destroyed"),"three separate shots trigger the target's disappearance")
	check(bench.impacts==3,"three launched shots produce three impacts")
	bench.fire_button.pressed.emit()
	check(bench.shots==3,"bench waits while the target is absent")
	await create_timer(4.5).timeout
	check(not target.get("_destroyed") and target.get("_hit_count")==0,"target returns with a fresh hit count")
	check(not target.get("_col_shape").disabled,"target collision returns")
	check(area.monitoring and area.monitorable,"mounted button area survives the museum disarm pass")
	check(bench.fire_button.get_node("HandPoseArea").monitorable,"hand pose remains discoverable")
	var q := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.32; capsule.height=1.5; q.shape=capsule; q.collision_mask=1; q.exclude=[player.get_rid()]
	q.transform.origin=bench.to_global(Vector3(-1.3,-0.25,-1.8))
	q.motion=Vector3(0,0,4)
	check(current_scene.get_world_3d().direct_space_state.cast_motion(q)[0]>0.99,"side approach reaches the changed floor")
	var report := {"checks":checks,"failures":failures,"changed_grid_samples":changed_colors,"headset_tested":false,"input":"Actual mounted button signals and physical projectile contacts in the museum; no simulated wrist pickup. Grid render transforms compared with unchanged collision bodies."}
	var f := FileAccess.open("res://ada_run/probe_chamber_colour.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	print("CHAMBER_COLOUR ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

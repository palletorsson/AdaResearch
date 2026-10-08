extends "res://commons/testing/probe_color_recovery.gd"
func press(ui:Node3D,id:String,cam:Camera3D) -> void:
	var area:Area3D=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var em:Node3D=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/layer-pattern-control.json"
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","tiling");em.set("start_map","Ribbon_Patterns_01")
	var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"tiling","dollhouse":0,"grid_pack":1}));f.close()
	root.add_child(em);current_scene=em
	var ui:Node3D
	for i in 2400:
		ui=em.find_child("LayerPatternLesson",true,false)
		if ui and ui.ready_for_use:break
		await process_frame
	check(ui!=null and ui.ready_for_use,"paired lesson loads in the actual Ribbon_Patterns_01 museum hall")
	if not ui or not ui.ready_for_use:quit(1);return
	em.set_process(false);em.set_physics_process(false)
	var cam:Camera3D=em.get("_cam");var player:CharacterBody3D=em.get("_player")
	player.set_physics_process(false);em.get("_feel").set_process(false)
	var wardrobe=em.get("_wardrobe");wardrobe.appearance_save_path="";wardrobe.costume.visible=false
	player.global_position+=ui.to_global(Vector3(-1,1.7,7.2))-cam.global_position;cam.look_at(ui.mount.global_position)
	for i in 90:em.call("_cull_artifacts");await process_frame
	check(ui.flat.size()==16 and ui.voxels.size()==64,"the original primary instances supply sixteen and sixty-four cells")
	check(ui.volume.get_children().filter(func(c):return c.get_script() and c.get_script().resource_path=="res://commons/scenes/mapobjects/pick_up_cube.gd").size()==64,"exactly one physical lattice remains after configuration")
	check(ui.values.size()==4 and ui.values[3].size()==4 and ui.values[3][3].size()==4,"four by four by four palette-index storage")
	var source:Array=ui.SOURCE.duplicate(true)
	check(ui.values.all(func(sheet):return sheet==source),"repeat writes the same source into every height layer")
	var positions:Dictionary={}
	for key in ui.voxels:positions[key]=ui.voxels[key].position
	press(ui,"X +",cam);press(ui,"Z +",cam);press(ui,"LAYER +",cam)
	check(ui.x_index==1 and ui.z_index==1 and ui.layer==1,"actual pointer actions select all three indices")
	check(ui.markers[0].position==Vector3(1,0.25,1) and ui.markers[1].position==Vector3(1,1.25,1),"source and volume markers follow corresponding addresses")
	press(ui,"REPEAT / SHIFT",cam)
	check(ui.values[1][1][1]==source[1][2] and ui.values[3][2][3]==source[2][2],"height shifts the sampled source column with wrap")
	check(ui.markers[0].position==Vector3(2,0.25,1) and ui.markers[1].position==Vector3(1,1.25,1),"lookup shift moves the source marker while the selected volume address stays")
	check(ui.SOURCE==source,"changing the volume recipe preserves source values")
	var unmoved=true
	for key in positions:unmoved=unmoved and ui.voxels[key].position==positions[key]
	check(unmoved,"recipe changes colours without moving any cube")
	press(ui,"SLICE / ALL",cam)
	check(ui.voxels.values().filter(func(c):return c.visible).size()==16 and ui.voxels.size()==64,"slice shows sixteen cells without deleting the other forty-eight")
	check(ui.values.size()*ui.values[0].size()*ui.values[0][0].size()==64,"slice leaves all stored values present")
	press(ui,"UNDO",cam);check(not ui.slice_only,"undo restores full visibility")
	press(ui,"UNDO",cam);check(not ui.shifted and ui.values[1]==source,"undo restores repeated layer data")
	for i in 4:press(ui,"LAYER +",cam)
	check(ui.layer==1,"layer index wraps after four steps")
	check(ui.buttons['UNDO'].global_position.y>0.6 and ui.buttons['X +'].global_position.y<1.8,"controls fit a standing reach band")
	check(ui.flat.values().all(func(c):return c.process_mode==Node.PROCESS_MODE_DISABLED),"study source stays fixed instead of bobbing or collecting")
	var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.5
	var q=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()]
	q.transform.origin=ui.to_global(Vector3(-1,0.82,6.7));await physics_frame
	check(ui.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"standing player fits at console approach")
	var legacy:Node3D=load("res://algorithms/arrays/grid_3d_4x4x4.tscn").instantiate();root.add_child(legacy)
	check(legacy.get_children().filter(func(c):return c.name.begins_with("Cube_")).size()==64 and legacy.get_node("Cube_0_0_0").is_processing(),"unconfigured volume retains 64 animated pickup cubes")
	legacy.queue_free()
	var early:Node3D=load("res://algorithms/arrays/grid_3d_4x4x4.tscn").instantiate()
	early.apply_grid_config({"size_x":2,"size_y":3,"size_z":2});root.add_child(early)
	for i in 3:await process_frame
	check(early.get_children().filter(func(c):return c.get_script() and c.get_script().resource_path=="res://commons/scenes/mapobjects/pick_up_cube.gd").size()==12,"configuration before tree entry leaves only the requested 12 cubes")
	early.apply_grid_config({"size_x":3,"size_y":2,"size_z":2})
	check(early.get_node_or_null("Cube_2_1_1")!=null and early.get_node_or_null("Cube_0_2_0")==null,"repeat configuration replaces the old shape without duplicate names")
	early.queue_free();await process_frame
	press(ui,"REPEAT / SHIFT",cam)
	await capture(cam,ui.to_global(Vector3(1,4.5,9.5)),ui.to_global(Vector3(-1,1.4,1.5)),"layer_pattern_all")
	press(ui,"SLICE / ALL",cam)
	await capture(cam,ui.to_global(Vector3(1,4.5,9.5)),ui.to_global(Vector3(-1,1.4,1.5)),"layer_pattern_slice")
	await capture(cam,ui.to_global(Vector3(-1,1.7,6.6)),ui.mount.global_position,"layer_pattern_console")
	f=FileAccess.open("res://ada_run/probe_layer_pattern.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("LAYER_PATTERN ",checks," checks / ",failures.size()," failures");quit(0 if failures.is_empty() else 1)

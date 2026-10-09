extends "res://commons/testing/probe_color_recovery.gd"

func press(ui:Node3D,id:String,cam:Camera3D) -> void:
	var area:Area3D=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position)
	XRToolsPointerEvent.released(cam,area,area.global_position)

func run() -> void:
	await museum("Tutorial_Pattern")
	var ui:Node3D=current_scene.find_child("FixedMotifLesson",true,false)
	check(ui!=null,"primary station loads the fixed-motif comparison")
	if not ui:quit(1);return
	var station:Node3D=ui.station
	var cam:Camera3D=current_scene.get("_cam")
	var player:CharacterBody3D=current_scene.get("_player")
	player.set_physics_process(false);current_scene.get("_feel").set_process(false)
	var wardrobe:Node=current_scene.get("_wardrobe");wardrobe.appearance_save_path="";wardrobe.costume.visible=false
	player.global_position+=ui.to_global(Vector3(0,1.7,3.7))-cam.global_position
	cam.look_at(ui.to_global(Vector3(0,1.2,0)))
	for i in 20:current_scene.call("_cull_artifacts");await process_frame
	check(ui.cells.size()==16 and ui.buttons.size()==30,"sixteen source cells, eight paints and six operations")
	check(ui.cells[0].global_position.y>ui.cells[4].global_position.y,"row zero is at the top of the source")
	check(ui.cells[0].global_position.y<1.8 and ui.buttons.RESET.global_position.y>0.6,"controls occupy a standing reach band")
	check(not station.is_processing() and not station._panel_root.visible,"legacy touch editor cannot paint through the new console")
	var initial:Array=station._grid_data.duplicate(true)
	var left:ShaderMaterial=ui.panels[0].material_override;var right:ShaderMaterial=ui.panels[1].material_override
	check(left!=right and left.get_shader_parameter("wallpaper_group")==0 and right.get_shader_parameter("wallpaper_group")==2,"panels own separate fixed P1 and PM rules")
	check(left.get_shader_parameter("domain_texture")==right.get_shader_parameter("domain_texture"),"both panels read the same source texture")
	check(is_equal_approx(1.6/left.get_shader_parameter("tile_scale"),station.carpet_world_size/station.carpet_repeats),"panels and floor have equal forty-centimetre tile spacing")
	var before:PackedByteArray=station._domain_texture.get_image().get_data()
	press(ui,"PM",cam)
	check(station._grid_data==initial and station._domain_texture.get_image().get_data()==before,"PM changes no source cell or source pixel")
	check(station._carpet_shader_material.get_shader_parameter("wallpaper_group")==2,"PM reaches the floor shader through the pointer control")
	check(left.get_shader_parameter("wallpaper_group")==0 and right.get_shader_parameter("wallpaper_group")==2,"floor selection preserves the two reference rules")
	press(ui,"UNDO",cam)
	check(station._group_index==0 and station._grid_data==initial,"undo restores the prior floor rule and source")
	press(ui,"FLIP X",cam)
	check(station._grid_data!=initial and station._grid_data[0][0]==initial[0][3],"source reflection changes the indexed cells")
	press(ui,"FLIP X",cam)
	check(station._grid_data==initial,"two source reflections restore the motif")
	for i in 4:press(ui,"ROTATE",cam)
	check(station._grid_data==initial,"four source quarter turns restore the motif")
	press(ui,"paint_4",cam);press(ui,"cell_1_0",cam)
	check(station._grid_data[0][1]==4,"actual pointer paints the selected address")
	var pixel:Color=left.get_shader_parameter("domain_texture").get_image().get_pixel(1,0)
	var expected:Color=station.PALETTE[4]
	check(absf(pixel.r-expected.r)<=1.0/255 and absf(pixel.g-expected.g)<=1.0/255 and absf(pixel.b-expected.b)<=1.0/255,"paint reaches the shared panel source within RGBA8 quantisation")
	press(ui,"UNDO",cam);check(station._grid_data==initial,"paint undo restores the cells")
	press(ui,"RESET",cam);check(station._grid_data==ui.SEED and station._group_index==0,"reset returns to the asymmetric source and P1")
	var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.5
	var q=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()]
	q.transform.origin=ui.to_global(Vector3(0,0.82,1.8))
	await physics_frame
	check(station.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"standing body fits in front of the editor")
	var grid:Node3D=station
	while grid and not grid.name.begins_with("SimGrid_"):grid=grid.get_parent()
	var points=[Vector3(15,0,11),Vector3(22,0,11),Vector3(22,0,12)]
	var clear=true
	for i in points.size()-1:
		q.transform.origin=grid.to_global(points[i]);q.transform.origin.y=station.global_position.y+0.82
		q.motion=grid.global_basis*(points[i+1]-points[i]);clear=clear and station.get_world_3d().direct_space_state.cast_motion(q)[0]>0.99
	check(clear,"three-metre doorway and bay approach admit a standing body")
	var legacy:Node3D=load("res://commons/artifacts/pattern_maker_station/pattern_maker_station.tscn").instantiate();root.add_child(legacy)
	check(legacy.fixed_motif_lesson==null and legacy._panel_root.visible,"unconfigured stations retain their original editor")
	legacy.queue_free()
	await process_frame
	await capture(cam,ui.to_global(Vector3(0,2.1,5.6)),ui.to_global(Vector3(0,1.3,0)),"fixed_motif_bay")
	await capture(cam,ui.to_global(Vector3(0,1.7,1.6)),ui.to_global(Vector3(0,1.15,0)),"fixed_motif_console")
	var f=FileAccess.open("res://ada_run/probe_fixed_motif.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("FIXED_MOTIF ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

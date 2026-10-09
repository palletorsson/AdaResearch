extends "res://commons/testing/probe_color_recovery.gd"
func press(ui:Node3D,id:String,cam:Camera3D) -> void:
	var area:Area3D=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	await museum("Symmetry_Seventeen")
	var ui:Node3D=current_scene.find_child("SymmetryCompareLesson",true,false)
	check(ui!=null,"the primary editor loads the comparison lesson")
	if not ui:quit(1);return
	var cam:Camera3D=current_scene.get("_cam")
	var player:CharacterBody3D=current_scene.get("_player")
	player.set_physics_process(false);current_scene.get("_feel").set_process(false)
	var wardrobe=current_scene.get("_wardrobe");wardrobe.appearance_save_path="";wardrobe.costume.visible=false
	player.global_position+=ui.to_global(Vector3(0,1.7,3.5))-cam.global_position
	cam.look_at(ui.to_global(Vector3(0,1.3,0)))
	for i in 20:current_scene.call("_cull_artifacts");await process_frame
	check(ui.buttons.size()==26,"16 addresses, four colours and six actions")
	check(ui.puzzle.process_mode==Node.PROCESS_MODE_DISABLED and not ui.puzzle.visible,"legacy physical source is suspended in this placement")
	var source:Array=ui.puzzle.get_pattern_data()
	var first:PackedByteArray=ui.held.material_override.albedo_texture.get_image().get_data()
	press(ui,"PM",cam)
	check(ui.puzzle.get_pattern_data()==source,"reflection keeps the source array")
	check(ui.puzzle._get_tiled_color(4,0)==source[0][3],"odd reflected block reads reversed source x")
	var pm:PackedByteArray=ui.live.material_override.albedo_texture.get_image().get_data()
	check(pm!=first,"reflection changes the visible field")
	press(ui,"PG",cam)
	check(ui.puzzle._get_tiled_color(4,0)==source[2][3] and ui.puzzle._get_tiled_color(5,2)==source[0][2],"glide combines reversal with two-row wrapped shift")
	check(ui.live.material_override.albedo_texture.get_image().get_data()!=pm,"glide differs from reflection for this source")
	check(ui.held.material_override.albedo_texture.get_image().get_data()==first,"held P1 survives both rule changes")
	press(ui,"HOLD",cam)
	var glide:PackedByteArray=ui.held.material_override.albedo_texture.get_image().get_data()
	press(ui,"paint_3",cam);press(ui,"cell_1_0",cam)
	check(ui.puzzle.get_cell(1,0)==3,"pointer paints a selected source address")
	check(ui.held.material_override.albedo_texture.get_image().get_data()==glide,"held image owns its pixels after painting")
	check(ui.live.material_override.albedo_texture==ui.station._carpet_material.albedo_texture,"live wall and floor share the rendered result")
	press(ui,"UNDO",cam);check(ui.puzzle.get_pattern_data()==source,"undo restores source data")
	press(ui,"UNDO",cam);check(ui.held.material_override.albedo_texture.get_image().get_data()==first,"undo restores previous held sample")
	press(ui,"RESET",cam);check(ui.group_index==0 and ui.puzzle.get_pattern_data()==ui.SEED,"reset restores source and P1")
	check(ui.buttons.RESET.global_position.y>0.6 and ui.cells[0].global_position.y<1.8,"controls are in standing reach range")
	var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.5
	var q=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()]
	q.transform.origin=ui.to_global(Vector3(0,0.82,1.7));await physics_frame
	check(ui.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"standing body fits at the control panel")
	var grid:Node3D=ui
	while grid and not grid.name.begins_with("SimGrid_"):grid=grid.get_parent()
	q.transform.origin=grid.to_global(Vector3(15,0,10));q.transform.origin.y=ui.global_position.y+0.82
	q.motion=grid.global_basis*Vector3(3,0,0)
	check(ui.get_world_3d().direct_space_state.cast_motion(q)[0]>0.99,"three-metre opening connects recovered hall and comparison bay")
	var legacy:Node3D=load("res://commons/primitives/arrays/vr_tile_editor.tscn").instantiate();root.add_child(legacy)
	await process_frame
	check(legacy.symmetry_lesson==null and legacy._puzzle.visible,"unconfigured editors retain their original source workspace")
	legacy.queue_free();await process_frame
	press(ui,"PG",cam)
	await capture(cam,ui.to_global(Vector3(0,2.0,5.1)),ui.to_global(Vector3(0,1.3,-0.5)),"symmetry_compare_bay")
	await capture(cam,ui.to_global(Vector3(0,1.7,2)),ui.to_global(Vector3(0,1.15,0.6)),"symmetry_compare_console")
	var f=FileAccess.open("res://ada_run/probe_symmetry_compare.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("SYMMETRY_COMPARE ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

extends "res://commons/testing/probe_color_recovery.gd"
func press(ui:Node3D,id:String,cam:Camera3D) -> void:
	var area:Area3D=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var em:Node3D=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/fabric-studio-control.json"
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","tiling");em.set("start_map","Ribbon_Patterns_03")
	var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"tiling","dollhouse":0,"grid_pack":1}));f.close()
	root.add_child(em);current_scene=em
	var ui:Node3D
	for i in 2400:
		ui=em.find_child("FabricShaderStudio",true,false)
		if ui and ui.buttons.size()==32:break
		await process_frame
	check(ui!=null and ui.buttons.size()==32,"fabric studio loads in the actual Ribbon_Patterns_03 museum hall")
	if not ui or ui.buttons.size()!=32:quit(1);return
	em.set_process(false);em.set_physics_process(false)
	var cam:Camera3D=em.get("_cam");var player:CharacterBody3D=em.get("_player")
	player.set_physics_process(false);em.get("_feel").set_process(false)
	var wardrobe=em.get("_wardrobe");wardrobe.appearance_save_path="";wardrobe.costume.visible=false
	player.global_position+=ui.to_global(Vector3(0,1.7,4.2))-cam.global_position;cam.look_at(ui.mount.global_position)
	for i in 90:em.call("_cull_artifacts");await process_frame


	ui.save_path="res://ada_run/probe-fabric-recipe.json"
	var w=em.get("_wardrobe");w.appearance_save_path="res://ada_run/probe-fabric-appearance.cfg"
	var original_look:String=w.costume.outfit_id;var original_fabric:Dictionary=w.skirt_fabric.duplicate(true)
	check(ui.Recipe.valid(ui.Recipe.initial()),"default fabric recipe is valid")
	check(ui.cells.size()==16 and ui.buttons.size()==32,"sixteen source cells, four paints and twelve controls")
	var original:Dictionary=ui.recipe.duplicate(true)
	press(ui,"paint_3",cam);press(ui,"cell_1_0",cam)
	check(ui.recipe.cells[0][1]==3,"pointer paints a source address")
	press(ui,"UNDO",cam);check(ui.recipe==original,"paint undo restores the recipe")
	var collision:BoxShape3D=ui.wall.get_node("WallCollision/CollisionShape3D").shape
	var size:Vector3=collision.size;var vertices=ui.wall.mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	for action in ["UV / FABRIC","OFFSET","REPEAT","CUT OUT","FINISH","VERTICES"]:press(ui,action,cam)
	check(ui.wall.material_override.get_shader_parameter("uv_view"),"UV view reaches the wall shader")
	check(ui.recipe.repeats==8 and ui.recipe.offset==0.125,"repeat and phase controls update the recipe")
	check(ui.wall.material_override.get_shader_parameter("cut_out") and ui.wall.material_override.get_shader_parameter("metal_finish"),"mask and finish reach the shader")
	check(is_equal_approx(ui.wall.material_override.get_shader_parameter("amplitude"),0.04),"vertex control is bounded to four centimetres in local space")
	check(collision.size==size and ui.wall.mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX]==vertices,"rendering controls preserve CPU mesh and collision geometry")
	press(ui,"UV / FABRIC",cam);press(ui,"CUT OUT",cam)
	press(ui,"SAVE",cam);var saved:Dictionary=ui.saved_recipe()
	check(saved==ui.recipe,"saved JSON round-trips every source and shader field")
	press(ui,"OFFSET",cam);press(ui,"LOAD",cam);check(ui.recipe==saved,"load restores the wall and preview recipe")
	check(ui.preview.outfit.skirt_fabric==saved,"preview skirt receives the loaded recipe")
	var bodice:Material=ui.preview.outfit.get_node("Bodice").material_override
	press(ui,"LOOK",cam);check(ui.preview.outfit.skirt_fabric==saved,"preview fabric survives a silhouette change")
	press(ui,"WEAR SAVED",cam)
	check(w.skirt_fabric==saved and is_instance_valid(w.costume.drag_outfit) and w.costume.drag_outfit.skirt_fabric==saved,"deliberate wear applies the saved recipe to the player's skirt")
	if not is_instance_valid(w.costume.drag_outfit):quit(1);return
	check(w.costume.drag_outfit.get_node("Skirt").material_override is ShaderMaterial and w.costume.drag_outfit.get_node("Bodice").material_override!=w.costume.drag_outfit.get_node("Skirt").material_override,"only the named skirt receives this fabric")
	var disk=ConfigFile.new();check(disk.load(w.appearance_save_path)==OK and disk.get_value("appearance","skirt_fabric")==saved,"wear persists the recipe with appearance in the isolated test save")
	var fresh=load("res://commons/player/super_drag_outfit.gd").new();root.add_child(fresh);fresh.dress(disk.get_value("appearance","outfit"));fresh.apply_skirt_fabric(disk.get_value("appearance","skirt_fabric"))
	check(fresh.skirt_fabric==saved and fresh.get_node("Skirt").material_override.get_shader_parameter("repeats")==8.0,"saved appearance restores on a fresh outfit")
	fresh.queue_free()
	press(ui,"OFFSET",cam)
	check(w.skirt_fabric==saved and w.costume.drag_outfit.skirt_fabric==saved and ui.recipe!=saved,"unsaved preview edits leave the worn skirt unchanged")
	press(ui,"UNDO",cam)
	press(ui,"UNDO",cam);check(w.skirt_fabric==original_fabric and w.costume.outfit_id==original_look,"wear undo restores prior garment recipe and outfit choice")
	var stage=ui.runway();check(stage!=null and stage.agents.size()==4,"existing runway supplies four performers in this hall")
	press(ui,"RUNWAY SAVED",cam);check(stage.agents.all(func(a):return a.outfit.skirt_fabric==saved),"runway application uses the same saved recipe for all four skirts")
	stage.agents[0].set_look(2);check(stage.agents[0].outfit.skirt_fabric==saved,"performer look changes retain its fabric")
	press(ui,"UNDO",cam);check(stage.agents.all(func(a):return a.outfit.skirt_fabric.is_empty()),"runway undo restores each performer's previous fabric")
	check(not ui.Recipe.valid({"version":1,"cells":[]}),"malformed saved recipes are rejected")
	check(ui.buttons['WEAR SAVED'].global_position.y>0.55 and ui.cells[0].global_position.y<1.9,"controls remain within standing reach band")
	var q=PhysicsRayQueryParameters3D.create(ui.wall.to_global(Vector3(0.8,0,2)),ui.wall.to_global(Vector3(0.8,0,-0.3)),1);q.exclude=[player.get_rid()]
	await physics_frame
	check(not ui.get_world_3d().direct_space_state.intersect_ray(q).is_empty(),"the sample wall retains physical collision")
	ui.recipe=ui.Recipe.initial();ui.refresh()
	await capture(cam,ui.to_global(Vector3(0,2.4,7.5)),ui.to_global(Vector3(0,1.45,0)),"fabric_studio")
	press(ui,"CUT OUT",cam);press(ui,"VERTICES",cam)
	await capture(cam,ui.to_global(Vector3(0,2.4,7.5)),ui.to_global(Vector3(0,1.45,0)),"fabric_cutout")
	await capture(cam,ui.to_global(Vector3(0,1.85,3.9)),ui.mount.global_position,"fabric_console")

	ui.recipe=ui.Recipe.initial();ui.refresh();press(ui,"SAVE",cam);press(ui,"WEAR SAVED",cam)
	w.costume.visible=true
	var mirrors=em.find_children("*","Node3D",true,false).filter(func(n):return n.get_script() and n.get_script().resource_path.ends_with("super_drag_mirror.gd"))
	check(not mirrors.is_empty(),"the room includes its live player mirror")
	if not mirrors.is_empty():
		var mirror=mirrors[0]
		player.global_position+=mirror.to_global(Vector3(0,1.7,2.8))-cam.global_position
		cam.look_at(mirror.to_global(Vector3(0,1.4,0)))
		for i in 90:em.call("_cull_artifacts");await process_frame
		check(mirror.viewport.world_3d==ui.get_world_3d() and mirror.viewer==cam and mirror._wardrobe==w,"mirror shares the live world and resolves the actual wearer")
		check(mirror.viewport.render_target_update_mode!=SubViewport.UPDATE_DISABLED and mirror.reflection.current,"reflection is active at the standing approach")
		await capture(cam,mirror.to_global(Vector3(0,1.7,2.8)),mirror.to_global(Vector3(0,1.4,0)),"fabric_mirror")
	press(ui,"UNDO",cam);w.costume.visible=false
	press(ui,"RUNWAY SAVED",cam)
	player.global_position+=stage.to_global(Vector3(8,1.7,12))-cam.global_position
	var distances:Array=stage.travelled.duplicate()
	for i in 90:em.call("_cull_artifacts");await physics_frame
	check(stage.travelled!=distances,"performers continue walking while wearing the recipe")
	await capture(cam,stage.to_global(Vector3(9,4.2,14)),stage.to_global(Vector3(0,1.1,6)),"fabric_runway")
	press(ui,"UNDO",cam)
	var secondary=em.find_children("*","Node3D",true,false).filter(func(n):return n.has_meta("config_embedded"))
	check(secondary.size()>=3,"all three legacy exhibits receive embedded configuration")
	check(secondary.all(func(n):return n.find_children("*","CanvasLayer",true,false).is_empty() and n.find_children("*","WorldEnvironment",true,false).is_empty()),"embedded exhibits create no screen overlay or competing world environment")
	var lines=secondary.filter(func(n):return n.get_script().resource_path.ends_with("coloredlines.gd"))[0]
	check(lines.line_paths.size()==25 and lines.line_meshes.size()==25,"the bounded line exhibit still builds all twenty-five paths")
	check(lines.line_paths.all(func(path):return path.all(func(point):return point.length()<=3.001)),"line source paths fit their shared three-unit radius")
	var demos=secondary.filter(func(n):return n.get_script().resource_path.ends_with("minimalglitch.gd") or n.get_script().resource_path.ends_with("advancedglitch.gd"))
	check(demos.all(func(n):return n.find_children("*","CSGBox3D",true,false).size()==15),"both embedded glitch exhibits retain their fifteen demo objects")
	var shape_query=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;shape_query.shape=capsule;shape_query.collision_mask=1;shape_query.exclude=[player.get_rid()]
	for approach in [[ui,Vector3(0,0.85,4.5),Vector3(0,0,-1.5)],[mirrors[0],Vector3(0,0.85,4),Vector3(0,0,-1.2)],[stage,Vector3(0,0.85,-1),Vector3(0,0,2.5)]]:
		shape_query.transform=Transform3D(Basis.IDENTITY,approach[0].to_global(approach[1]));shape_query.motion=approach[0].global_basis*approach[2]
		check(ui.get_world_3d().direct_space_state.cast_motion(shape_query)[0]>0.99,"standing capsule has a clear approach to "+approach[0].name)
	f=FileAccess.open("res://ada_run/probe_fabric_studio.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("FABRIC_STUDIO ",checks," checks / ",failures.size()," failures");quit(0 if failures.is_empty() else 1)

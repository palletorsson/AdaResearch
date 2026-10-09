extends "res://doc/book/iterations/2026-09-19-tiling-review/opening/probes/probe_pattern_recipe.gd"

func press(ui:Node3D,id:String,cam:Camera3D) -> void:
	var area:Area3D=ui.controls[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position)
	XRToolsPointerEvent.released(cam,area,area.global_position)

func run() -> void:
	await museum("Pattern_Foundry")
	var model:Node3D
	for node in current_scene.find_children("*","Node3D",true,false):
		if node.get_script() and node.get_script().resource_path.ends_with("/pattern_studio_plate.gd"):model=node;break
	check(model!=null,"existing studio plate found in the actual museum")
	if not model:quit(1);return
	var ui:Node3D=model.studio_ui
	var cam:Camera3D=current_scene.get("_cam")
	var player:CharacterBody3D=current_scene.get("_player")
	player.set_physics_process(false);current_scene.get("_feel").set_process(false)
	var wardrobe:Node=current_scene.get("_wardrobe");wardrobe.appearance_save_path=""
	wardrobe.costume.visible=false
	player.global_position+=model.to_global(Vector3(0,1.65,2.3))-cam.global_position
	cam.look_at(model.to_global(Vector3(0,1.1,0)))
	for frame in range(20):current_scene.call("_cull_artifacts");await process_frame
	ui.save_path="res://doc/book/iterations/2026-09-19-tiling-review/opening/verified-runtime/pattern_studio_test.json"
	check(ui.cell_buttons.size()==4 and model._current_grid_size==2,"native checkerboard starts at two by two")
	check(is_equal_approx(ui.mount.get_node("Face").mesh.size.x,1.32),"workstation has a readable 1.32 metre face")
	var source_height:float=ui.cell_buttons[0].global_position.y
	print("STUDIO POSITION ",model.global_position," SOURCE ",source_height," SAVE ",ui.controls.SAVE.global_position.y)
	check(source_height>1.0 and source_height<1.8 and ui.controls.SAVE.global_position.y>0.6,"source and operations stand in the reachable height band")
	check(not model.is_processing_input(),"walking keyboard input cannot edit this studio")
	var initial:Dictionary=ui.export_package()
	press(ui,"motif_next",cam)
	check(model._current_grid_size==8 and model._grid_data==model.MOTIFS[1].data and ui.cell_buttons.size()==64,"motif selector keeps all sixty-four Greek Key cells")
	check(ui.cell_buttons[0].position.y>ui.cell_buttons[8].position.y,"source row zero is at the top like the web studio")
	var separated:=true
	for i in range(1,8):separated=separated and ui.cell_buttons[i].position.x>ui.cell_buttons[i-1].position.x
	check(separated,"fine-grid hit targets have separate centres")
	var actual_group:=true
	for i in model.GROUPS.size():
		model.wallpaper_group=i
		actual_group=actual_group and model.WallpaperGroups.get_group_name(model._get_wallpaper_enum()).to_upper()==model.GROUPS[i]
	check(actual_group,"all seventeen group labels select their named engine rule")
	model.wallpaper_group=0;ui.refresh()
	var before:Dictionary=ui.export_package()
	press(ui,"group_next",cam)
	check(model.GROUPS[model.wallpaper_group]=="P2" and ui.material.get_shader_parameter("wallpaper_group")==1,"pointer changes the source rule and rendered shader")
	press(ui,"UNDO",cam)
	check(ui.export_package()==before,"undo restores the exact previous source package")
	var shape_before:RID=model._carpet_mesh.mesh.get_rid()
	press(ui,"MIRROR",cam);press(ui,"MIRROR",cam)
	check(model._grid_data==before.domain,"two complete reflections restore the asymmetric motif")
	for i in 4:press(ui,"ROTATE",cam)
	check(model._grid_data==before.domain,"four quarter turns restore every source cell")
	press(ui,"paint_2",cam)
	var area:Area3D=ui.cell_buttons[0].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
	check(model._grid_data[0][0]==2,"actual pointer paints the selected source address")
	check(ui.material.get_shader_parameter("domain_texture").get_image().get_pixel(0,0).is_equal_approx(Color.html(model.palette[2].to_html())),"paint reaches the shared GPU domain texture")
	press(ui,"UNDO",cam)
	check(model._grid_data==before.domain,"paint is reversible")
	press(ui,"WEB NEXT",cam)
	check(ui.pattern_name=="pinwheel_truchet" and model._current_grid_size==2,"web package loads through the workstation control")
	check(ui.material.get_shader_parameter("tile_shape")==6 and is_equal_approx(ui.material.get_shader_parameter("wear_amount"),0.15),"web tile shape and wear reach the Godot shader")
	check(ui.preview.material_override==model._carpet_mesh.material_override and model._carpet_mesh.mesh.get_rid()==shape_before,"preview and floor share output without changing receiving geometry")
	press(ui,"SAVE",cam)
	var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ui.save_path))
	press(ui,"CLEAR",cam);press(ui,"RESTORE",cam)
	check(same_state(ui.export_package(),saved),"local save restores web source palette and finish")
	var invalid:=saved.duplicate(true);invalid.domain[0][0]=-1
	check(not ui.import_package(invalid) and same_state(ui.export_package(),saved),"invalid colour addresses cannot partially replace a design")
	invalid=saved.duplicate(true);invalid.domain_size=64
	check(not ui.import_package(invalid) and same_state(ui.export_package(),saved),"unsupported dense domains are rejected without downsampling")
	invalid=saved.duplicate(true);invalid.tile_shape=2.5
	check(not ui.import_package(invalid),"fractional shape identifiers are rejected")
	press(ui,"palette_next",cam)
	check(model.palette.size()==9 and ui.swatches[8].visible,"a period palette restores available paint controls after a short web palette")
	press(ui,"UNDO",cam)
	check(model.palette.size()==2 and not ui.swatches[8].visible and ui.controls.paint_8.get_node("InteractableAreaButton").collision_layer==0,"undo restores the short palette without invisible active controls")
	var query:=PhysicsShapeQueryParameters3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.5;query.shape=capsule
	query.transform.origin=model.to_global(Vector3(0,0,1.8));query.collision_mask=1;query.exclude=[player.get_rid()]
	var ray:=PhysicsRayQueryParameters3D.create(model.to_global(Vector3(0,3,1.8)),model.to_global(Vector3(0,-4,1.8)),1)
	var floor_hit:=model.get_world_3d().direct_space_state.intersect_ray(ray)
	print("STUDIO FLOOR HEIGHT ",floor_hit.get("position",Vector3.ZERO).y)
	if floor_hit:query.transform.origin.y=floor_hit.position.y+0.77
	await physics_frame
	print("STUDIO APPROACH ",model.get_world_3d().direct_space_state.intersect_shape(query))
	check(model.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"a standing body fits in front of the studio")
	var unobstructed:=true
	for control:Node3D in ui.controls.values():
		if not control.visible:continue
		var front:Vector3=ui.mount.global_basis.z
		var end:Vector3=control.global_position+front*0.03
		var approach:=PhysicsRayQueryParameters3D.create(end+front*0.65,end,1)
		approach.exclude=[player.get_rid()]
		unobstructed=unobstructed and model.get_world_3d().direct_space_state.intersect_ray(approach).is_empty()
	check(unobstructed,"the pedestal and room leave every visible control unobstructed")
	var adapter:Node3D=ui.surface_controls
	adapter.find_registry()
	var study:Node3D=adapter.study
	var rack_clear:=true
	for control:Node3D in adapter.buttons.values():
		var end:Vector3=control.global_position+adapter.panel.global_basis.z*0.03
		var hit_query:=PhysicsRayQueryParameters3D.create(end+adapter.panel.global_basis.z*0.65,end,1)
		hit_query.exclude=[player.get_rid()]
		rack_clear=rack_clear and control.global_position.y>0.7 and model.get_world_3d().direct_space_state.intersect_ray(hit_query).is_empty()
	check(rack_clear,"surface selectors stand above 70 cm and have clear input paths")
	query.transform.origin=model.to_global(Vector3(-1.03,0.77,1.25))
	check(model.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"a standing body fits at the surface selectors")
	check(study!=null,"studio discovers only its own hall receiver registry")
	if study:
		var loom:Node3D=study.loom
		loom.set_process(false)
		var flat_pixels:PackedByteArray=bytes(study.flat)
		var wall_geometry:RID=study.wall.mesh.get_rid()
		var source_before:Dictionary=ui.export_package()
		var loom_before:Dictionary=loom.export_recipe()
		var link_count:int=study.link_history.size()
		adapter.target_index=0;adapter.act("NEXT");adapter.act("PREV")
		check(study.link_history.size()==link_count and ui.export_package()==source_before and loom.export_recipe()==loom_before,"selecting a target changes neither source nor receiver")
		var apply_area:Area3D=adapter.buttons["APPLY LIVE"].get_node("InteractableAreaButton")
		XRToolsPointerEvent.pressed(cam,apply_area,apply_area.global_position);XRToolsPointerEvent.released(cam,apply_area,apply_area.global_position)
		check(study.wall.material_override is ShaderMaterial and study.receivers.WALL.source.get_ref()==ui and study.receivers.WALL.linked,"pointer applies the studio source to the selected wall")
		check(bytes(study.flat)==flat_pixels and study.receivers.FLAT.source==null,"unselected flat keeps its loom image and owner")
		check(study.wall.material_override!=ui.material and study.wall.mesh.get_rid()==wall_geometry,"receiver owns a material while retaining its mesh")
		check(study.wall.material_override.get_shader_parameter("surface_metres").is_equal_approx(Vector2(4,0.75)),"wall mapping uses its physical width and height relative to a 1.2 metre square")
		check(study.wall.material_override.shader.code.contains("cull_disabled"),"shader adapter preserves the sheets' two visible faces")
		ui.choose("group",1)
		check(study.wall.material_override.get_shader_parameter("wallpaper_group")==model._get_wallpaper_enum(),"live wall follows a studio edit")
		var pattern_image:PackedByteArray=study.wall.material_override.get_shader_parameter("domain_texture").get_image().get_data()
		loom.call("_toggle_peg",1,2)
		check(study.wall.material_override.get_shader_parameter("domain_texture").get_image().get_data()==pattern_image and bytes(study.flat)!=flat_pixels,"loom edits cannot overwrite a studio-owned wall")
		adapter.act("HOLD")
		var held_material:ShaderMaterial=study.wall.material_override
		var held_image:PackedByteArray=held_material.get_shader_parameter("domain_texture").get_image().get_data()
		ui.act("CLEAR")
		check(study.wall.material_override==held_material and held_material.get_shader_parameter("domain_texture").get_image().get_data()==held_image,"held wall retains its exact material and source image")
		adapter.act("APPLY LIVE")
		check(study.wall.material_override.get_shader_parameter("domain_texture").get_image().get_data()!=held_image,"reapply catches up to the current studio")
		adapter.act("UNDO LINK")
		check(not study.receivers.WALL.linked and study.receivers.WALL.source.get_ref()==ui and study.wall.material_override.get_shader_parameter("domain_texture").get_image().get_data()==held_image,"undo restores held image and studio ownership together")
		adapter.act("LOOM")
		check(study.wall.material_override is StandardMaterial3D and study.receivers.WALL.source==null and study.receivers.WALL.linked,"explicit LOOM returns control to the current loom")
		adapter.act("UNDO LINK")
		check(study.wall.material_override is ShaderMaterial and not study.receivers.WALL.linked,"undoing return to loom recovers the held studio state")
		adapter.target_index=5;adapter.act("APPLY LIVE")
		check(study.ARCHITECTURE.all(func(id):return study.receivers[id].source.get_ref()==ui and study.receivers[id].linked),"Architecture applies to exactly three registered walls")
		check(study.receivers.FLAT.source==null and study.receivers.CURVE.source==null,"Architecture leaves both specimens with the loom")
		adapter.act("UNDO LINK")
		check(not study.receivers.WALL.linked and study.receivers.WALL.source.get_ref()==ui and study.receivers.NORTH.source==null and study.receivers.EAST.source==null,"group undo recovers mixed sources and held states")
		link_count=study.link_history.size()
		check(not study.apply_source(["WALL","missing"],ui) and study.link_history.size()==link_count,"invalid target sets are rejected atomically")
		adapter.target_index=0;adapter.act("APPLY LIVE");study.detach_source(ui)
		check(not study.receivers.WALL.linked,"departing source freezes its last surface instead of switching owner")
		adapter.target_index=6;adapter.act("LOOM")
		loom.import_recipe(loom_before)
		check(["FLAT","CURVE","WALL","NORTH","EAST"].all(func(id):return study.receivers[id].source==null and study.receivers[id].linked),"all five surfaces can explicitly return to their original source")
		# Capture one live studio wall and leave the other four with the loom.
		ui.act("UNDO");adapter.target_index=0;adapter.act("APPLY LIVE")
		check(adapter.screen.text.contains("STUDIO / LIVE") and study.receivers.WALL.tag.text.contains("STUDIO"),"both panels name the selected receiver's owner")
		study.target_index=study.TARGETS.find("WALL");study.refresh_readout()
		check(study.readout.text.contains("STUDIO"),"loom console names the external owner instead of displaying its own spacing")

	ui.import_package(initial,false);model._current_motif=0;ui.choose("motif",1);ui.status="SOURCE / RULE / SURFACE";ui.refresh()
	var chamber:Node3D=adapter.room
	check(chamber!=null,"curved room is authored for this studio")
	if chamber:
		check(study.receivers.size()==7 and adapter.targets.has("ROOM"),"two room surfaces extend the existing five without renaming that scope")
		adapter.target_index=6
		check(adapter.ids().size()==5 and not "ROOM WALL" in adapter.ids(),"ALL FIVE still means the original five specimens")
		var geometry:Array=chamber.wall.mesh.surface_get_arrays(0)
		var verts:PackedVector3Array=geometry[Mesh.ARRAY_VERTEX]
		var arc:=0.0
		for i in chamber.SEGMENTS:arc+=verts[2*i].distance_to(verts[2*i+2])
		check(absf(arc-chamber.RADIUS*chamber.SWEEP)<0.01 and is_equal_approx(verts[1].y,3.2),"300-degree wall has continuous arc-length mapping and 3.2 metre height")
		check(chamber.find_children("WallSupport_*","StaticBody3D",false,false).size()==80,"curved wall has physical supports matching its segments")
		query.transform.origin=chamber.to_global(Vector3(0,0.82,5.4));query.motion=Vector3(0,0,-3.2)
		check(model.get_world_3d().direct_space_state.cast_motion(query)[0]>0.99,"a body can enter and approach the studio through the wide opening")
		var wall_ray:=PhysicsRayQueryParameters3D.create(chamber.to_global(Vector3(0,1.6,0)),chamber.to_global(Vector3(-6,1.6,0)),1)
		wall_ray.exclude=[player.get_rid()]
		var wall_hit:=model.get_world_3d().direct_space_state.intersect_ray(wall_ray)
		check(not wall_hit.is_empty() and wall_hit.collider.name.begins_with("WallSupport"),"the curved wall stops a physical crossing")
		var grid:Node3D=model
		while grid and not grid.name.begins_with("SimGrid_"):grid=grid.get_parent()
		var route:=[Vector3(26,0.82,30),Vector3(26,0.82,20),Vector3(30,0.82,20),Vector3(30,0.82,15)]
		var route_clear:=true
		for i in range(route.size()-1):
			query.transform.origin=grid.to_global(route[i]);query.transform.origin.y=model.global_position.y+0.82;query.motion=grid.global_basis*(route[i+1]-route[i])
			var fraction:float=model.get_world_3d().direct_space_state.cast_motion(query)[0]
			if fraction<0.99:
				var start:Vector3=query.transform.origin
				query.transform.origin=start+query.motion*minf(1.0,fraction+0.02)
				print("ROOM ROUTE BLOCK ",i," ",fraction," ",model.get_world_3d().direct_space_state.intersect_shape(query))
				query.transform.origin=start
			route_clear=route_clear and fraction>0.99
		check(route_clear,"existing catwalk-side aisle connects to the new room entrance")
		adapter.target_index=adapter.targets.find("ROOM");adapter.act("APPLY LIVE")
		ui.choose("group",1)
		check(study.receivers["ROOM WALL"].source.get_ref()==ui and study.receivers["ROOM FLOOR"].source.get_ref()==ui,"ROOM applies the studio to wall and floor together")
		check(chamber.wall.material_override.get_shader_parameter("surface_metres").is_equal_approx(Vector2(chamber.RADIUS*chamber.SWEEP,3.2)/1.2),"wall repetition uses arc metres instead of projected width")
		adapter.target_index=adapter.targets.find("ROOM FLOOR");adapter.act("HOLD")
		var floor_material:ShaderMaterial=chamber.floor_mesh.material_override
		var floor_group:int=floor_material.get_shader_parameter("wallpaper_group")
		ui.choose("group",1)
		check(chamber.floor_mesh.material_override==floor_material and floor_material.get_shader_parameter("wallpaper_group")==floor_group and chamber.wall.material_override.get_shader_parameter("wallpaper_group")==model._get_wallpaper_enum(),"floor can hold while the surrounding wall follows edits")
		adapter.act("UNDO LINK")
		check(study.receivers["ROOM FLOOR"].linked,"room hold uses the shared reversible receiver protocol")
		adapter.target_index=adapter.targets.find("ROOM");adapter.act("LOOM")
		check(chamber.wall.material_override is StandardMaterial3D and chamber.wall.material_override.albedo_texture.get_width()<650,"loom fallback for the large wall has bounded texture resolution")
		adapter.act("UNDO LINK")
		check(chamber.wall.material_override is ShaderMaterial,"undo restores the studio-driven room")
		model._current_motif=2;ui.choose("motif",1);model._apply_period_palette(3);ui.package_extra["tile_scale"]=2.0;ui.refresh()
		adapter.target_index=adapter.targets.find("ROOM");adapter.act("APPLY LIVE")
		await capture(cam,chamber.to_global(Vector3(0,1.65,2.8)),chamber.to_global(Vector3(-1,1.4,-2.8)),"curved_room_inside")
		await capture(cam,chamber.to_global(Vector3(0,2.1,6.8)),chamber.to_global(Vector3(0,1.45,0)),"curved_room_entrance")
	await capture(cam,model.to_global(Vector3(-0.4,1.9,2.65)),model.to_global(Vector3(-0.4,1.18,0)),"pattern_studio_console")
	await capture(cam,model.to_global(Vector3(2.8,3.3,4.2)),model.to_global(Vector3(0,0.55,-0.4)),"pattern_studio_room")
	var f:=FileAccess.open("res://doc/book/iterations/2026-09-19-tiling-review/opening/verified-runtime/probe_pattern_studio.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "))
	print("PATTERN_STUDIO ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

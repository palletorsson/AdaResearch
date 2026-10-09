extends "res://commons/testing/probe_color_recovery.gd"

func bytes(mesh:MeshInstance3D) -> PackedByteArray:
	return mesh.material_override.albedo_texture.get_image().get_data()

# JSON numbers decode as floats and the parser can shift the final binary digit.
# Allow four double-precision epsilons only for fractional values. Keys, order
# and integer state stay exact; rendered source/history bytes are checked below.
func same_state(a:Variant,b:Variant,path:String="recipe") -> bool:
	if (a is int or a is float) and (b is int or b is float):
		if a is int or b is int:return float(a)==float(b)
		return absf(float(a)-float(b))<=8.881784197001252e-16*maxf(1.0,maxf(absf(a),absf(b)))
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not same_state(a[key],b[key],path+"."+str(key)):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in a.size():
			if not same_state(a[i],b[i],path+"["+str(i)+"]"):return false
		return true
	return typeof(a)==typeof(b) and a==b

func run() -> void:
	await museum("Pattern_Foundry")
	var study:Node3D=current_scene.find_child("RecipeStudy",true,false)
	check(study!=null,"recipe comparison stands in the real museum")
	if study==null:quit(1);return
	var loom:Node3D=study.get_parent()
	study.save_path="res://ada_run/pattern_recipe_test.json"
	loom.set_process(false)
	var wardrobe:Node=current_scene.get("_wardrobe");wardrobe.appearance_save_path=""
	var player:CharacterBody3D=current_scene.get("_player")
	var cam:Camera3D=current_scene.get("_cam")
	player.set_physics_process(false);current_scene.get("_feel").set_process(false)
	player.global_position+=loom.to_global(Vector3(-3.1,1.7,-2.4))-cam.global_position
	cam.look_at(loom.to_global(Vector3(-3.1,1.2,1.1)))
	for frame in range(35):current_scene.call("_cull_artifacts");await process_frame
	loom.set_process(false)
	check(loom.group=="p1","pilot starts with translation")
	check(study.buttons.size()==8 and study.buttons[0].global_position.y>1.0,"eight reachable source and receiver controls")
	var baseline:Dictionary=loom.export_recipe()
	var baseline_pixels:=bytes(study.flat)
	var baseline_carpet:PackedByteArray=loom._carpet_mat.albedo_texture.get_image().get_data()
	check(loom.LoomRecipe.valid(baseline,loom.card_size),"resolved initial state satisfies recipe schema")
	check(not same_state(0.1,0.1000001),"JSON comparison rejects differences beyond parser roundoff")
	check(bytes(study.flat)==bytes(study.curved),"flat and curved surfaces carry identical texture values")
	check(study.flat.material_override!=study.curved.material_override,"specimens own separate material instances")
	var flat_transform:Transform3D=study.flat.transform
	var curved_transform:Transform3D=study.curved.transform
	var flat_mesh:RID=study.flat.mesh.get_rid();var curved_mesh:RID=study.curved.mesh.get_rid()
	var geometry:Array=study.curved.mesh.surface_get_arrays(0)
	var flat_geometry:Array=study.flat.mesh.surface_get_arrays(0)
	check(flat_geometry[Mesh.ARRAY_TEX_UV]==geometry[Mesh.ARRAY_TEX_UV],"bending preserves every UV address and its orientation")
	var vertices:PackedVector3Array=geometry[Mesh.ARRAY_VERTEX]
	var arc:=0.0
	for i in range(48):arc+=vertices[i*2].distance_to(vertices[(i+1)*2])
	check(absf(arc-study.WIDTH)<0.001,"curved arc equals the flat width within tessellation tolerance")
	check(is_equal_approx(vertices[1].y-vertices[0].y,study.HEIGHT),"both specimens have the same surface height")
	var button_area:Area3D=study.buttons[0].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,button_area,button_area.global_position)
	XRToolsPointerEvent.released(cam,button_area,button_area.global_position)
	check(bytes(study.flat)!=baseline_pixels,"real pointer mark changes the repeated specimen")
	check(bytes(study.flat)==bytes(study.curved),"one source edit reaches both linked forms")
	study.buttons[1].pressed.emit()
	var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(study.save_path))
	check(same_state(saved,loom.export_recipe()),"SAVE writes the resolved state as JSON")
	var exported:Dictionary=loom.export_recipe();exported.live.card[0][0]=99
	check(loom.export_recipe().live.card[0][0]!=99,"exported recipe cannot mutate the live source")
	study.buttons[3].pressed.emit()
	var held:=bytes(study.curved)
	study.buttons[0].pressed.emit()
	check(bytes(study.curved)==held and bytes(study.flat)!=held,"held curve keeps its local difference while flat follows")
	study.buttons[3].pressed.emit()
	check(bytes(study.flat)==bytes(study.curved),"relink brings the curve to the current rule")
	study.buttons[2].pressed.emit()
	check(same_state(saved,loom.export_recipe()),"RESTORE recovers card palette history and phase")
	check(bytes(study.flat)==held,"restored source produces the saved specimen")
	var malformed:=saved.duplicate(true);malformed.live.card[0][0]=99
	var before_rejection:Dictionary=loom.export_recipe()
	check(not loom.import_recipe(malformed) and loom.export_recipe()==before_rejection,"invalid colour index is rejected without partial mutation")
	malformed=saved.duplicate(true);malformed.version=2
	check(not loom.import_recipe(malformed),"future recipe versions are rejected")
	loom.call("_apply_preset",1)
	loom.call("_cycle_paint")
	check(bytes(study.flat)!=baseline_pixels,"changing preset exercises a different card palette and group")
	check(loom.import_recipe(baseline),"original state imports after editing")
	check(bytes(study.flat)==baseline_pixels and loom._carpet_mat.albedo_texture.get_image().get_data()==baseline_carpet,"original specimen and history carpet restore exactly")
	var pegs_match:=true
	for y in loom.card_size:
		for x in loom.card_size:
			var ci:int=loom._card[y][x]
			pegs_match=pegs_match and loom._peg_meshes[y][x].visible==(ci>0) and loom._peg_mats[y][x].albedo_color==loom._palette[ci]
	check(pegs_match,"restored physical pegs match the card and palette")
	check(loom._card_root.get_node("PunchBtn").get("pressed_color")==loom._palette[loom._paint_color],"paint indicator shows the restored active colour")
	check(flat_transform==study.flat.transform and curved_transform==study.curved.transform and flat_mesh==study.flat.mesh.get_rid() and curved_mesh==study.curved.mesh.get_rid(),"editing and restoring preserve supporting geometry")
	var neighbour:Node3D=load("res://commons/artifacts/pattern_machine_a/pattern_machine_a.tscn").instantiate()
	neighbour.randomize_on_start=false;current_scene.add_child(neighbour);neighbour.position=Vector3(-100,0,-100);neighbour.set_process(false)
	var untouched:Dictionary=neighbour.export_recipe()
	study.buttons[0].pressed.emit()
	check(neighbour.export_recipe()==untouched,"another loom remains independent")
	# The registered wall receives a larger sampled field, with the same cell
	# spacing as the small sheets. No scene-wide material substitution occurs.
	var wall:MeshInstance3D=study.wall
	var wall_image:Image=wall.material_override.albedo_texture.get_image()
	var flat_image:Image=study.flat.material_override.albedo_texture.get_image()
	check(wall_image.get_size()==Vector2i(480,90),"wall samples sixteen by three card periods at fixed render resolution")
	check(wall_image.get_region(Rect2i(0,0,20,15)).get_data()==flat_image.get_region(Rect2i(0,0,20,15)).get_data(),"wall and sample share colour addresses at equal metre spacing")
	check(["FLAT","CURVE","WALL","NORTH","EAST"].all(func(id):return study.receivers.has(id)) and wall.material_override!=study.flat.material_override,"five explicit independent receivers are registered")
	var wall_transform:Transform3D=wall.transform
	var wall_mesh:RID=wall.mesh.get_rid()
	var hit_query:=PhysicsRayQueryParameters3D.create(wall.to_global(Vector3(0,0,-0.15)),wall.to_global(Vector3(0,0,0.3)),1,[player.get_rid()])
	var wall_hit:Dictionary=current_scene.get_world_3d().direct_space_state.intersect_ray(hit_query)
	print("WALL SUPPORT ",wall.global_position," ",wall_hit)
	check(not wall_hit.is_empty() and wall_hit.position.distance_to(wall.global_position)<0.05,"pattern lies against an existing physical grid wall")
	var wall_body:Node=wall_hit.get("collider")
	var wall_body_transform:Transform3D=wall_body.global_transform if wall_body!=null else Transform3D.IDENTITY
	var target_area:Area3D=study.buttons[4].get_node("InteractableAreaButton")
	var before_selection:Dictionary=loom.export_recipe()
	XRToolsPointerEvent.pressed(cam,target_area,target_area.global_position)
	XRToolsPointerEvent.released(cam,target_area,target_area.global_position)
	check(study.TARGETS[study.target_index]=="WALL" and "WALL / LIVE" in study.readout.text,"pointer selects the wall and names its live state")
	check(study.receivers.WALL.tag.modulate!=study.receivers.FLAT.tag.modulate,"selected wall is identified on its own mounted label")
	check(before_selection==loom.export_recipe(),"selecting a target does not edit the source")
	study.buttons[3].pressed.emit()
	var wall_held:=bytes(wall)
	study.buttons[0].pressed.emit()
	check(bytes(wall)==wall_held and bytes(study.flat)!=flat_image.get_data(),"held wall retains its image while both specimens follow")
	study.buttons[3].pressed.emit()
	check(bytes(wall)!=wall_held,"relink makes the wall catch up")
	study.buttons[5].pressed.emit()
	check(not study.receivers.WALL.linked and bytes(wall)==wall_held,"undo relink restores the wall's held image")
	study.buttons[4].pressed.emit() # flat
	study.buttons[4].pressed.emit() # all three
	check("MIXED" in study.readout.text,"all-five selector reports mixed link state honestly")
	study.buttons[3].pressed.emit() # mixed -> link all
	check(study.receivers.values().all(func(r):return r.linked),"linking the mixed scope brings all five receivers live")
	study.buttons[3].pressed.emit() # all live -> hold all
	var all_held:Array=[bytes(wall),bytes(study.flat),bytes(study.curved)]
	study.buttons[0].pressed.emit()
	check([bytes(wall),bytes(study.flat),bytes(study.curved)]==all_held,"all-five hold excludes the receivers from later source edits")
	study.buttons[5].pressed.emit()
	check(study.receivers.values().all(func(r):return r.linked) and bytes(wall)!=all_held[0],"undo hold restores live links at the current source")
	check(wall.transform==wall_transform and wall.mesh.get_rid()==wall_mesh and wall_body!=null and wall_body.global_transform==wall_body_transform,"receiver controls preserve wall mesh and supporting collision")
	check(neighbour.export_recipe()==untouched,"scope and undo cannot mutate an unregistered neighbouring loom")
	var spacing_source:Dictionary=loom.export_recipe()
	var spacing_carpet:PackedByteArray=loom._carpet_mat.albedo_texture.get_image().get_data()
	var spacing_pixels:=bytes(study.flat)
	var spacing_area:Area3D=study.buttons[6].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,spacing_area,spacing_area.global_position)
	XRToolsPointerEvent.released(cam,spacing_area,spacing_area.global_position)
	check(is_equal_approx(loom.repeat_metres,0.6) and "60 CM" in study.readout.text,"pointer advances repeat size from 30 to 60 centimetres")
	check(loom.export_recipe().live==spacing_source.live and loom.export_recipe().bands==spacing_source.bands and loom._carpet_mat.albedo_texture.get_image().get_data()==spacing_carpet,"spacing preserves motif palette group and historical carpet")
	check(bytes(study.flat)!=spacing_pixels and bytes(study.flat)==bytes(study.curved),"linked specimens enlarge the same unchanged motif")
	var large_image:Image=study.flat.material_override.albedo_texture.get_image()
	check(large_image.get_region(Rect2i(0,0,60,120)).get_data()==large_image.get_region(Rect2i(60,0,60,120)).get_data(),"60 cm repetition covers exactly half the 1.2 metre specimen")
	study.buttons[1].pressed.emit()
	study.buttons[6].pressed.emit()
	check(is_equal_approx(loom.repeat_metres,0.15),"repeat size wraps to 15 centimetres")
	study.buttons[2].pressed.emit()
	check(is_equal_approx(loom.repeat_metres,0.6) and bytes(study.flat)==large_image.get_data(),"saved spacing and resulting image restore together")
	var bad_spacing:Dictionary=loom.export_recipe();bad_spacing.repeat_metres=0
	check(not loom.import_recipe(bad_spacing) and is_equal_approx(loom.repeat_metres,0.6),"invalid saved spacing is rejected before mutation")
	var legacy_spacing:Dictionary=spacing_source.duplicate(true);legacy_spacing.erase("repeat_metres")
	check(loom.import_recipe(legacy_spacing) and is_equal_approx(loom.repeat_metres,0.3),"earlier recipes without spacing restore the original 30 cm")
	while study.TARGETS[study.target_index]!="WALL":study.buttons[4].pressed.emit()
	study.buttons[3].pressed.emit() # hold wall at 30 cm
	var spacing_wall:=bytes(wall)
	study.buttons[6].pressed.emit() # live samples -> 60 cm
	check(bytes(wall)==spacing_wall and "30 CM" in study.receivers.WALL.tag.text and "60 CM" in study.receivers.FLAT.tag.text,"held wall retains its image and spacing label while source spacing changes")
	study.buttons[3].pressed.emit() # relink wall at 60 cm
	study.buttons[5].pressed.emit() # undo back to held 30 cm
	check(bytes(wall)==spacing_wall and "30 CM" in study.receivers.WALL.tag.text,"undo relink restores held spacing with its image")
	check(wall.transform==wall_transform and wall.mesh.get_rid()==wall_mesh and wall_body.global_transform==wall_body_transform and neighbour.export_recipe()==untouched,"repeat sizing leaves geometry collision and neighbouring loom unchanged")
	var architecture_supports:Array=[]
	for id in ["NORTH","EAST"]:
		var surface:MeshInstance3D=study.receivers[id].mesh
		var supported:=true
		for fraction in [-0.45,0.0,0.45]:
			var across:float=fraction*study.WIDTH
			var ray:=PhysicsRayQueryParameters3D.create(surface.to_global(Vector3(across,0,-0.15)),surface.to_global(Vector3(across,0,0.3)),1,[player.get_rid()])
			var hit:Dictionary=current_scene.get_world_3d().direct_space_state.intersect_ray(ray)
			supported=supported and not hit.is_empty() and hit.get("position",Vector3.INF).distance_to(surface.to_global(Vector3(across,0,0)))<0.05
			if not hit.is_empty():architecture_supports.append({"body":hit.collider,"transform":hit.collider.global_transform})
		check(supported,id+" receiver lies against existing grid collision across its width")
	while study.TARGETS[study.target_index]!="ARCHITECTURE":study.buttons[4].pressed.emit()
	check(study.selected_ids()==["WALL","NORTH","EAST"],"Architecture names exactly three walls and excludes specimens")
	study.buttons[3].pressed.emit() # mixed -> all architecture live
	study.buttons[3].pressed.emit() # hold architecture
	var architecture_held:Dictionary={}
	for id in study.ARCHITECTURE:architecture_held[id]=bytes(study.receivers[id].mesh)
	var free_sample:=bytes(study.flat)
	study.buttons[6].pressed.emit()
	check(study.ARCHITECTURE.all(func(id):return bytes(study.receivers[id].mesh)==architecture_held[id]),"held architecture keeps all three wall images through source spacing changes")
	check(bytes(study.flat)!=free_sample and bytes(study.flat)==bytes(study.curved),"specimens remain live while Architecture is held")
	study.buttons[5].pressed.emit()
	check(study.ARCHITECTURE.all(func(id):return study.receivers[id].linked and bytes(study.receivers[id].mesh)!=architecture_held[id]),"undo architecture hold reconnects all three at current spacing")
	while study.TARGETS[study.target_index]!="EAST":study.buttons[4].pressed.emit()
	study.buttons[3].pressed.emit()
	var east_held:=bytes(study.receivers.EAST.mesh)
	while study.TARGETS[study.target_index]!="ARCHITECTURE":study.buttons[4].pressed.emit()
	check("MIXED" in study.readout.text,"Architecture reports an individually held east wall as mixed")
	study.buttons[3].pressed.emit()
	study.buttons[6].pressed.emit()
	study.buttons[5].pressed.emit()
	check(not study.receivers.EAST.linked and bytes(study.receivers.EAST.mesh)==east_held and study.receivers.NORTH.linked and study.receivers.WALL.linked,"undo architecture relink restores its previous mixed membership and east image")
	check(architecture_supports.all(func(r):return r.body.global_transform==r.transform) and neighbour.export_recipe()==untouched,"architecture control preserves its supports and neighbouring loom")
	var offset_source:Dictionary=loom.export_recipe()
	var offset_zero:Image=study.flat.material_override.albedo_texture.get_image()
	var offset_carpet:PackedByteArray=loom._carpet_mat.albedo_texture.get_image().get_data()
	var offset_held:=bytes(study.receivers.EAST.mesh)
	var offset_area:Area3D=study.buttons[7].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,offset_area,offset_area.global_position)
	XRToolsPointerEvent.released(cam,offset_area,offset_area.global_position)
	check(is_equal_approx(loom.offset_metres,0.05) and "U05" in study.readout.text,"pointer advances surface offset five centimetres")
	var offset_five:Image=study.flat.material_override.albedo_texture.get_image()
	check(offset_five.get_region(Rect2i(0,0,115,120)).get_data()==offset_zero.get_region(Rect2i(5,0,115,120)).get_data() and offset_five.get_data()!=offset_zero.get_data(),"five-centimetre sampling offset shifts exactly five pixels without resizing")
	check(loom.export_recipe().live==offset_source.live and loom.export_recipe().bands==offset_source.bands and loom.repeat_metres==offset_source.repeat_metres and loom._carpet_mat.albedo_texture.get_image().get_data()==offset_carpet,"offset preserves motif palette rule spacing and carpet history")
	check(bytes(study.receivers.EAST.mesh)==offset_held and "U00" in study.receivers.EAST.tag.text and "U05" in study.receivers.FLAT.tag.text,"held east wall keeps its earlier offset and image")
	study.buttons[1].pressed.emit()
	study.buttons[7].pressed.emit()
	study.buttons[2].pressed.emit()
	check(is_equal_approx(loom.offset_metres,0.05) and bytes(study.flat)==offset_five.get_data(),"saved offset restores its exact image")
	var invalid_offset:Dictionary=loom.export_recipe();invalid_offset.offset_metres=0.31
	check(not loom.import_recipe(invalid_offset) and is_equal_approx(loom.offset_metres,0.05),"out-of-range offset import is rejected without mutation")
	var legacy_offset:Dictionary=offset_source.duplicate(true);legacy_offset.erase("offset_metres")
	check(loom.import_recipe(legacy_offset) and is_zero_approx(loom.offset_metres) and bytes(study.flat)==offset_zero.get_data(),"older recipes without offset recover zero offset")
	for step in range(6):study.buttons[7].pressed.emit()
	check(is_equal_approx(loom.offset_metres,0.3) and bytes(study.flat)==offset_zero.get_data(),"a full 30 cm p1 period returns the image while retaining a different offset value")
	study.buttons[7].pressed.emit()
	check(is_zero_approx(loom.offset_metres),"offset control wraps from 30 centimetres to zero")
	study.buttons[7].pressed.emit()
	while study.TARGETS[study.target_index]!="EAST":study.buttons[4].pressed.emit()
	study.buttons[3].pressed.emit()
	check(is_equal_approx(study.receivers.EAST.offset_metres,0.05),"relinked east wall accepts the current offset")
	study.buttons[5].pressed.emit()
	check(is_zero_approx(study.receivers.EAST.offset_metres) and bytes(study.receivers.EAST.mesh)==offset_held,"link undo restores a held offset together with its image")
	check(flat_transform==study.flat.transform and curved_transform==study.curved.transform and architecture_supports.all(func(r):return r.body.global_transform==r.transform) and neighbour.export_recipe()==untouched,"offset leaves receiving geometry supports and neighbouring loom unchanged")
	neighbour.queue_free()
	var query:=PhysicsShapeQueryParameters3D.new();var capsule:=CapsuleShape3D.new()
	capsule.radius=0.25;capsule.height=1.5;query.shape=capsule;query.collision_mask=1;query.exclude=[player.get_rid()]
	query.transform.origin=loom.to_global(Vector3(-3.1,0.85,-0.9));query.motion=loom.global_basis*Vector3(0,0,0.4)
	check(current_scene.get_world_3d().direct_space_state.cast_motion(query)[0]>0.99,"standing approach reaches the console")
	query.transform.origin=loom.to_global(Vector3(0.5,0.85,8.5));query.motion=loom.global_basis*Vector3(0,0,-1)
	check(current_scene.get_world_3d().direct_space_state.cast_motion(query)[0]>0.99,"east receiver has a clear metre of standing approach")
	query.transform.origin=loom.to_global(Vector3(1.8,0.85,1));query.motion=loom.global_basis*Vector3(1,0,0)
	check(current_scene.get_world_3d().direct_space_state.cast_motion(query)[0]>0.99,"north receiver has a clear metre of standing approach")
	# Inspection photography only: the probe teleports and pitches the camera,
	# leaving the world-mounted outfit in its view. No outfit preference is saved.
	if is_instance_valid(wardrobe.costume):wardrobe.costume.visible=false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/pattern_recipe_museum.png")
	player.global_position+=loom.to_global(Vector3(-5.2,1.55,-0.4))-cam.global_position
	cam.look_at(wall.global_position)
	for frame in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/pattern_wall_museum.png")
	player.global_position+=loom.to_global(Vector3(1.0,1.65,-0.8))-cam.global_position
	cam.look_at(study.receivers.NORTH.mesh.global_position)
	for frame in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/pattern_architecture_museum.png")
	player.global_position+=loom.to_global(Vector3(0.5,1.65,8.5))-cam.global_position
	cam.look_at(study.receivers.EAST.mesh.global_position)
	for frame in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/pattern_east_museum.png")
	var report:Dictionary={"checks":checks,"failures":failures,"headset_tested":false,"input":"Actual museum and pointer press/release; source recipe restoration; explicit flat/curve/wall scopes; local hold, relink and undo; equal metre sampling; existing wall collision ray; unchanged wall support and independent loom."}
	var f:=FileAccess.open("res://ada_run/probe_pattern_recipe.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "))
	print("PATTERN_RECIPE ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)

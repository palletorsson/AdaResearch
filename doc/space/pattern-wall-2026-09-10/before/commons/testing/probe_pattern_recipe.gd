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
	check(study.buttons.size()==4 and study.buttons[0].global_position.y>1.0,"four reachable specimen controls")
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
	neighbour.queue_free()
	var query:=PhysicsShapeQueryParameters3D.new();var capsule:=CapsuleShape3D.new()
	capsule.radius=0.25;capsule.height=1.5;query.shape=capsule;query.collision_mask=1;query.exclude=[player.get_rid()]
	query.transform.origin=loom.to_global(Vector3(-3.1,0.85,-0.9));query.motion=loom.global_basis*Vector3(0,0,0.4)
	check(current_scene.get_world_3d().direct_space_state.cast_motion(query)[0]>0.99,"standing approach reaches the console")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/pattern_recipe_museum.png")
	var report:Dictionary={"checks":checks,"failures":failures,"headset_tested":false,"input":"Actual museum, supplied pointer press/release and button signals, JSON save/restore, malformed inputs, texture bytes, matching surface dimensions and geometry identity. Other looms unchanged."}
	var f:=FileAccess.open("res://ada_run/probe_pattern_recipe.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "))
	print("PATTERN_RECIPE ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)

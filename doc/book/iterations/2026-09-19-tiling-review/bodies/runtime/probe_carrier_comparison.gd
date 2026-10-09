extends "res://commons/testing/probe_color_recovery.gd"
func press(ui:Node3D,id:String,cam:Camera3D) -> void:
	var area:Area3D=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var em:Node3D=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://doc/book/iterations/2026-09-19-tiling-review/bodies/runtime/carrier-control.json"
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","tiling");em.set("start_map","Ribbon_Patterns_02")
	var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"tiling","dollhouse":0,"grid_pack":1}));f.close()
	root.add_child(em);current_scene=em
	var ui:Node3D
	for i in 2400:
		ui=em.find_child("CarrierComparison",true,false)
		if ui and ui.material!=null:break
		await process_frame
	check(ui!=null and ui.material!=null,"carrier lesson loads in the actual Ribbon_Patterns_02 museum hall")
	if not ui or ui.material==null:quit(1);return
	em.set_process(false);em.set_physics_process(false)
	var cam:Camera3D=em.get("_cam");var player:CharacterBody3D=em.get("_player")
	player.set_physics_process(false);em.get("_feel").set_process(false)
	var wardrobe=em.get("_wardrobe");wardrobe.appearance_save_path="";wardrobe.costume.visible=false
	player.global_position+=ui.to_global(Vector3(0,1.7,4))-cam.global_position;cam.look_at(ui.mount.global_position)
	for i in 90:em.call("_cull_artifacts");await process_frame

	var context:Node3D=em.find_child("ContextComparison",true,false)
	check(context!=null,"context comparison uses the other existing primary")
	if not context:quit(1);return
	check(ui.samples[0].material_override==ui.samples[1].material_override,"plane and curve share one material and source")
	var source:PackedByteArray=ui.material.get_shader_parameter("motif").get_image().get_data()
	var vertices:PackedVector3Array=ui.samples[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var length:float=0
	for i in 64:length+=vertices[(i+1)*2].distance_to(vertices[i*2])
	check(absf(length-4.0)<0.002,"curve arc and flat panel span four metres")
	press(ui,"REPEAT SIZE",cam);check(ui.material.get_shader_parameter("repeats")==8.0,"pointer halves horizontal repeat span to fifty centimetres")
	press(ui,"FLAT / SHADED",cam);check(ui.material.get_shader_parameter("shaded"),"pointer enables directional normal shading")
	var old_light:Vector3=ui.material.get_shader_parameter("light_direction")
	press(ui,"LIGHT SIDE",cam);var new_light:Vector3=ui.material.get_shader_parameter("light_direction")
	check(old_light.x==-new_light.x and old_light.y==new_light.y and old_light.z==new_light.z,"light control changes side without changing elevation or magnitude")
	var normals:PackedVector3Array=ui.samples[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	check(normals[0].dot(old_light.normalized())>normals[0].dot(new_light.normalized()),"curved edge normal responds differently to the two light directions")
	check(is_equal_approx(Vector3.FORWARD.dot(old_light.normalized()),Vector3.FORWARD.dot(new_light.normalized())),"symmetric light reversal leaves frontal plane's cosine factor unchanged")
	press(ui,"GRID",cam);check(ui.material.get_shader_parameter("show_grid"),"grid control reveals repeat boundaries")
	check(ui.material.get_shader_parameter("motif").get_image().get_data()==source,"all carrier controls preserve source pixels")
	check(ui.samples[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==vertices,"shading and repeat controls do not deform the carrier")
	press(ui,"UNDO",cam);check(not ui.grid,"undo restores grid state")
	press(ui,"RESET",cam);check(not ui.shaded and not ui.dense and not ui.right_light,"reset restores initial carrier comparison")
	check(context.samples.all(func(s):return s.material_override.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED) and context.bridge.material_override.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED,"both targets and their connector are actually unshaded in the assembled hall")
	check(ui.samples[0].mesh.size==Vector2(4,2),"assembled plane is four metres wide and two metres high")
	var grey:Color=context.samples[0].material_override.albedo_color
	press(context,"SWAP",cam);press(context,"SURROUNDS",cam);press(context,"CONNECT",cam)
	check(context.samples[0].material_override.albedo_color==grey and context.samples[1].material_override.albedo_color==grey,"surround and connector controls never change either target")
	check(context.backgrounds[0].material_override.albedo_color==context.backgrounds[1].material_override.albedo_color,"equal surrounds remove the background difference")
	check(context.bridge.visible and context.bridge.material_override.albedo_color==grey,"connector uses the same numerical grey")
	press(context,"UNDO",cam);check(not context.bridge.visible,"context undo restores separated view")
	press(context,"RESET",cam);check(not context.neutral and not context.swapped,"context reset restores the initial backgrounds")
	check(ui.buttons.UNDO.global_position.y>0.6 and ui.buttons['LIGHT SIDE'].global_position.y<1.8,"controls fit standing reach band")
	var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.5
	var q=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()]
	q.transform.origin=ui.to_global(Vector3(0,0.82,3));await physics_frame
	check(ui.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"carrier console has clear standing approach")
	await capture(cam,ui.to_global(Vector3(0,2.3,8)),ui.to_global(Vector3(0,1.6,0)),"carrier_flat")
	press(ui,"FLAT / SHADED",cam)
	await capture(cam,ui.to_global(Vector3(0,2.3,8)),ui.to_global(Vector3(0,1.6,0)),"carrier_shaded")
	press(ui,"LIGHT SIDE",cam)
	await capture(cam,ui.to_global(Vector3(0,2.3,8)),ui.to_global(Vector3(0,1.6,0)),"carrier_light_right")
	await capture(cam,ui.to_global(Vector3(0,1.7,3.2)),ui.mount.global_position,"carrier_console")
	player.global_position+=context.to_global(Vector3(0,1.7,6))-cam.global_position
	for i in 20:em.call("_cull_artifacts");await process_frame
	q.transform.origin=context.to_global(Vector3(0,0.82,3));await physics_frame
	check(context.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"context console has clear standing approach")
	var scoped_label=false
	for n in em.find_children("*","Node3D",true,false):
		if n.get_script() and n.get_script().resource_path=="res://algorithms/color/spherecolors/spherecolors.gd" and n.get("label_in_space"):
			scoped_label=not n.explanation_label.no_depth_test and not n.explanation_label.fixed_size
	check(scoped_label,"neighbour label respects depth and distance instead of covering this exhibit")
	# Compact hall: the old +8m view backs into the next sphere exhibit.
	cam.fov=90
	await capture(cam,context.to_global(Vector3(0,2.3,4.5)),context.to_global(Vector3(0,1.6,0)),"carrier_context")
	press(context,"SURROUNDS",cam);press(context,"CONNECT",cam)
	await capture(cam,context.to_global(Vector3(0,2.3,4.5)),context.to_global(Vector3(0,1.6,0)),"carrier_context_equal_connected")
	f=FileAccess.open("res://doc/book/iterations/2026-09-19-tiling-review/bodies/runtime/probe_carrier_comparison.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("CARRIER_COMPARISON ",checks," checks / ",failures.size()," failures");quit(0 if failures.is_empty() else 1)

# Review-local capture path; the original probe is preserved unchanged.
func capture(cam:Camera3D,pos:Vector3,target:Vector3,suffix:String) -> void:
	cam.global_position=pos;cam.look_at(target)
	for i in range(20):await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://doc/book/iterations/2026-09-19-tiling-review/bodies/runtime/"+suffix+".png")

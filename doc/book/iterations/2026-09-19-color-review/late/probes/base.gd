extends SceneTree
var OUT := "res://doc/book/iterations/2026-09-19-color-review/late/before/"
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): OUT=arg.trim_prefix("--out=")
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[color-recovery] ", "PASS " if ok else "FAIL ",message)
func run() -> void:
	var map_name := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): map_name = arg.trim_prefix("--map=")
	if not map_name.is_empty():
		await museum(map_name)
	else:
		await artifacts()
	var f := FileAccess.open("res://ada_run/color_recovery_"+(map_name if not map_name.is_empty() else "artifacts")+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("[color-recovery] ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func artifacts() -> void:
	var world := Node3D.new(); root.add_child(world); current_scene = world
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color("333d48")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE; env.environment.ambient_light_energy = 0.65; world.add_child(env)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-50,-30,0); world.add_child(light)
	var pillar: Node3D = load("res://algorithms/color/pillarcolorcollection/pillarcolorcollection.tscn").instantiate()
	pillar.set_meta("config_layout","spatial_gradient"); world.add_child(pillar)
	var office: Node3D = load("res://algorithms/color/color_mixing/color_constellation_office.tscn").instantiate()
	office.set_meta("config_layout","cubicles"); world.add_child(office); office.position.x = 50
	var atlas: Node3D = load("res://algorithms/color/grabcolor/color_sets_overview.tscn").instantiate()
	atlas.set_meta("config_mount","wall"); world.add_child(atlas); atlas.position.x = 80
	var painting: Node3D = load("res://commons/context/drawingboard/ball_painting_demo_v2.tscn").instantiate()
	painting.set_meta("config_automated","true"); world.add_child(painting); painting.position.x = 100
	for i in range(10): await process_frame
	check(pillar.find_children("Pillar_*","Node3D",false,false).size()==35,"35 pillars sample the enlarged spatial field")
	var samples_match := true
	for p in pillar.find_children("Pillar_*","Node3D",false,false):
		samples_match = samples_match and p.get_meta("sample_color").is_equal_approx(pillar.sample_space(p.position))
	check(samples_match,"pillar colours are evaluated from their positions")
	check(not pillar.sample_space(Vector3.ZERO).is_equal_approx(pillar.sample_space(Vector3(12.8,0,0))),"x changes hue")
	check(not pillar.sample_space(Vector3.ZERO).is_equal_approx(pillar.sample_space(Vector3(0,0,19.2))),"z changes saturation")
	check(pillar.get_node("ContinuousGradient").mesh.size.is_equal_approx(Vector2(12.8,19.2)),"continuous gradient covers the sampling field")
	var panes := office.find_children("*","MeshInstance3D",false,false).filter(func(n): return n.mesh is BoxMesh and is_equal_approx(n.mesh.size.z,0.035))
	check(panes.size()==40,"40 coloured glass partitions")
	check(panes.all(func(n): return is_zero_approx(fposmod(n.rotation_degrees.y,90.0))),"every glass partition meets the orthogonal layout")
	check(panes.all(func(n): return n.get_child(0) is StaticBody3D),"glass partitions have physical collision")
	var desks := 0; var chairs := 0
	for n in office.get_children():
		if n is MeshInstance3D and n.mesh is BoxMesh:
			if n.mesh.size.is_equal_approx(Vector3(1.7,0.065,0.7)): desks += 1
			if n.mesh.size.is_equal_approx(Vector3(0.5,0.09,0.5)): chairs += 1
	check(desks==8 and chairs==8,"eight furnished cubicles at body scale")
	var query := PhysicsShapeQueryParameters3D.new(); var capsule := CapsuleShape3D.new()
	capsule.radius=0.22; capsule.height=1.6; query.shape=capsule
	query.transform.origin=office.to_global(Vector3(0,0.81,-8));query.motion=Vector3(0,0,16)
	check(world.get_world_3d().direct_space_state.cast_motion(query)[0]>0.99,"central office aisle admits a body")
	for row in range(4):
		for side in [-1,1]:
			query.transform.origin=office.to_global(Vector3(0,0.81,-5.4+3.6*row));query.motion=Vector3(side*2.5,0,0)
			check(world.get_world_3d().direct_space_state.cast_motion(query)[0]>0.99,"cubicle entrance %d/%d admits a body" % [row,side])
	check(atlas.has_node("AtlasWall"),"palette sets have an architectural backing wall")
	check(atlas.find_children("PaletteSet_*","Node3D",false,false).size()==12,"twelve palette sets hang on the wall")
	await create_timer(3.0).timeout
	check(painting.automated and painting.strokes>20,"automatic pigment ball paints without a pickup")
	check(painting.surface.brush_layer != null,"automation uses the live drawing surface")
	if "--capture" in OS.get_cmdline_user_args():
		var cam := Camera3D.new(); world.add_child(cam);cam.fov=55
		await capture(cam,Vector3(24,20,-13),Vector3(6.4,1,9.6),"pillars")
		await capture(cam,office.to_global(Vector3(13,11,-15)),office.global_position+Vector3.UP,"office")
		await capture(cam,atlas.to_global(Vector3(0,1.8,8)),atlas.to_global(Vector3(0,1.6,0)),"atlas")
		await capture(cam,painting.to_global(Vector3(0,1.6,6)),painting.to_global(Vector3(0,1.2,-0.5)),"painting")

func museum(map_name: String) -> void:
	var chapter := "tiling" if map_name in ["Pattern_Foundry","Tutorial_Pattern","Array_Patterns","Symmetry_Seventeen"] else "color"
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := OUT+"color-recovery-"+map_name+"-control.json"
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter",chapter);em.set("start_map",map_name)
	var f := FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":chapter,"dollhouse":0,"grid_pack":1}));f.close()
	root.add_child(em);current_scene=em
	await create_timer(1).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var seg:Node3D
	for rec:Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")==map_name:seg=rec.node;break
	check(seg!=null,map_name+" is an active museum hall")
	if seg==null:return
	var gs:Node3D=seg.get_node_or_null("SimGrid_"+map_name)
	check(gs!=null,map_name+" loads the actual recovered grid")
	if gs==null:return
	for i in range(3600):
		if gs.has_meta("stage_grid_ready"):break
		await process_frame
	check(gs.has_meta("stage_grid_ready"),map_name+" finishes building")
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_name+"/map_data.json"))
	check(gs.get("data_component").get_structure_layer_raw()==source.layers.structure,map_name+" runtime structure matches the recovered source")
	check(gs.scale.is_equal_approx(Vector3.ONE),map_name+" retains metre scale")
	check(not seg.has_node("SimulationFrame") and not seg.has_node("BasinFire"),map_name+" has perimeter walls without a fire or glass arena frame")
	var material: ShaderMaterial = gs.get_node("GridMultiMesh").material_override
	var finish: Dictionary = source.get("settings", {}).get("color_overrides", {})
	check(is_equal_approx(float(material.get_shader_parameter("emission_strength")), float(finish.get("emission_strength", 0.0))), map_name+" applies its authored grid finish at runtime")
	var tokens:Array=[]
	for n in gs.find_children("*","Node",true,false):
		if n.has_meta("artifact_lookup_name"):
			var token:=str(n.get_meta("artifact_lookup_name"));tokens.append(token)
			if token=="pillarcolorcollection" and map_name=="Color_Pillar":check(n.get("spatial_gradient")==true,"museum pillar configuration activates the gradient")
			if token=="color_sets_overview" and map_name=="Color_Pillar":check(n.get("wall_mount")==true,"museum palette configuration activates its wall")
			if token=="color_constellation_office" and map_name=="Color_Walls":check(n.get("cubicle_office")==true,"museum office configuration activates the cubicles")
			if token=="ball_painting_demo":check(n.get("automated")==true,"museum painting configuration activates automation")
			if token=="becoming_catalyst" and map_name=="Chamber_Color":
				var mode: Dictionary = n.call("_get_current_mode_def")
				check(mode.get("id", "")=="chromatic","closing chamber selects the chromatic mode, not just unlocks it")
	for row:Array in source.layers.interactables:
		for raw in row:
			var token:=str(raw).split(":")[0].split("#")[0].strip_edges()
			if not token.is_empty() and token!="0":check(token in tokens,map_name+" places "+token)
	if "--capture" in OS.get_cmdline_user_args():
		var cam:=Camera3D.new();em.add_child(cam);cam.fov=62
		var mid:=Vector3(source.map_info.dimensions.width*0.5,0,source.map_info.dimensions.depth*0.5)
		await capture(cam,gs.to_global(mid+Vector3(-15,35,-30)),gs.to_global(mid),map_name)

func capture(cam:Camera3D,pos:Vector3,target:Vector3,suffix:String) -> void:
	cam.global_position=pos;cam.look_at(target)
	for i in range(20):await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ada_run/color_recovery_"+suffix+".png")

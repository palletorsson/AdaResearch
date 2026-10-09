extends SceneTree
var checks := 0
var failures: Array[String] = []
var map_name := "Tutorial_3D"
var grid: Node3D
var artifacts: Dictionary = {}
var OUT := "res://doc/book/iterations/2026-09-19-arrays-review/surfaces/before/"

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[regularity] ","PASS " if ok else "FAIL ",message)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): OUT = arg.trim_prefix("--out=")
		if arg.begins_with("--map="): map_name = arg.trim_prefix("--map=")
	var chapter := "tiling" if map_name in ["Pattern_Disco","Pattern_Foundry"] else "array_tutorial"
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := OUT+map_name+"-control.json"
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter",chapter);em.set("start_map",map_name)
	var file := FileAccess.open(ctl,FileAccess.WRITE)
	file.store_string(JSON.stringify({"first_chapter":chapter,"dollhouse":0,"grid_pack":1}));file.close()
	root.add_child(em);current_scene=em
	await create_timer(1).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var segment: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")==map_name: segment=rec.node;break
	check(segment!=null,"active museum hall "+map_name)
	if segment==null: finish();return
	grid=segment.get_node_or_null("SimGrid_"+map_name)
	check(grid!=null,"loads authored simulation grid")
	if grid==null: finish();return
	for i in 3600:
		if grid.has_meta("stage_grid_ready"): break
		await process_frame
	await create_timer(3).timeout
	check(grid.has_meta("stage_grid_ready"),"grid finished building")
	for n in grid.find_children("*","Node",true,false):
		if n.has_meta("artifact_lookup_name"): artifacts[str(n.get_meta("artifact_lookup_name"))]=n
		if n.has_meta("agent_tier"): artifacts["gridagent"]=n
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_name+"/map_data.json"))
	check(grid.get("data_component").get_structure_layer_raw()==data.layers.structure,"runtime structure equals source")
	for row: Array in data.layers.interactables:
		for raw in row:
			var token:=str(raw).split(":")[0].split("#")[0].strip_edges()
			if token!="" and token!="0": check(artifacts.has(token),"placed "+token)
	match map_name:
		"Array":
			check(artifacts.has("row_3_x") and artifacts.has("grid_2d_4x4"),"one and two indices share the opening hall")
			check(not artifacts.has("grid_3d_4x4x4"),"third index belongs to its own hall")
		"Tutorial_3D": await test_flight()
		"Tutorial_Tiling_Floor","Tutorial_Tiling_Walls": test_tiling()
		"Tutorial_Disco","Pattern_Disco": await test_disco()
		"Pattern_Foundry": test_architecture()
	await inspect_surfaces()
	if "--capture" in OS.get_cmdline_user_args(): await capture_views(data)
	finish()

func test_flight() -> void:
	if not artifacts.has("array_flight_lab"): return
	var n: Node3D=artifacts.array_flight_lab
	check(n.grid.find_children("Cube_*","Node3D",false,false).size()==64,"64 addressable cubes")
	check(n.enclosure.contains_point(n.to_global(Vector3(0,4,0))),"flight inside volume")
	check(not n.enclosure.contains_point(n.to_global(Vector3(0,1,-7))),"walking outside volume")
	check(n.enclosure.flight_velocity(Basis.IDENTITY,Vector2.ZERO,0)==Vector3.ZERO,"neutral input hovers")
	check(n.enclosure.flight_velocity(Basis.IDENTITY,Vector2.ONE,1).length()<=2.401,"diagonal flight stays bounded")
	n.select_axis(1)
	check(n.selected==Vector3i(0,1,0) and is_equal_approx(n.marker.position.y,3.45),"third dimension changes address and marker height")
	var cell: Node=n.grid.get_node_or_null("Cube_0_1_0")
	check(cell!=null,"selected cell exists")
	if cell!=null:
		cell.queue_free();await process_frame;await process_frame
		check(n.values[1][0][0]==0,"collection leaves the indexed slot empty")
	var query:=PhysicsShapeQueryParameters3D.new()
	var capsule:=CapsuleShape3D.new();capsule.radius=.22;capsule.height=1.6;query.shape=capsule
	query.transform.origin=n.to_global(Vector3(0,.9,-7));query.motion=Vector3(0,0,3)
	check(n.get_world_3d().direct_space_state.cast_motion(query)[0]>.99,"ground doorway admits a body")

func test_tiling() -> void:
	if not artifacts.has("tiling_principles"): return
	var n: Node3D=artifacts.tiling_principles
	check(n.surfaces.size()==6,"six separate rule comparisons")
	check(n.walls==(map_name=="Tutorial_Tiling_Walls"),"correct floor or wall configuration")
	var baseline: Array=[]
	for surface in n.surfaces: baseline.append(surface.material_override.albedo_texture.get_image().get_data())
	n.toggle_exception()
	for i in 6:
		check((n.surfaces[i].material_override.albedo_texture.get_image().get_data()!=baseline[i])==(i==5),"exception affects only designated field "+str(i))
	n.turn_motif()
	check(n.surfaces[0].material_override.albedo_texture.get_image().get_data()!=baseline[0],"turn motif changes repeated field")
	var im: Image=n.surfaces[0].material_override.albedo_texture.get_image()
	check(im.get_pixel(0,0).r==im.get_pixel(0,0).g and im.get_pixel(90,160).r==im.get_pixel(90,160).b,"monochrome values")
	n.phase=0;n.exception=false;n.refresh()

func test_disco() -> void:
	if not artifacts.has("disco_controls"): return
	var n: Node3D=artifacts.disco_controls
	check(is_instance_valid(n.floor_node),"controller finds this room's floor")
	if not is_instance_valid(n.floor_node): return
	check(n.floor_node.monochrome==(map_name=="Tutorial_Disco"),"floor applies correct colour scope")
	n.running=false
	var start: int=n.phase
	await create_timer(.7).timeout
	check(n.phase==start,"hold stops pattern clock")
	n.step();check(n.phase==start+1,"single step advances once")
	start=n.phase
	n.cycle_palette()
	check(n.phase==start,"palette leaves phase unchanged")
	n.cycle_pattern();check(n.pattern==1,"pattern changes independently")
	n.pattern=0;n.palette=1 if n.colour else 0;n.phase=0;n.paint()

func test_architecture() -> void:
	if not artifacts.has("pattern_architecture"): return
	var n: Node3D=artifacts.pattern_architecture
	check(n.skins.size()==2,"floor and wall meshes built")
	check(n.sources.size()==4,"all four machines found in this hall")
	for i in 4:
		n.source_index=i;n.refresh()
		check(n.source_texture()!=null,"live output from machine "+str(i))
		if n.source_texture()!=null:
			check(n.skins[0].material_override.albedo_texture==n.source_texture(),"floor receives source "+str(i))
	n.toggle_hold()
	check(n.held,"hold records a state")
	check(n.skins[0].material_override.albedo_texture!=n.source_texture(),"held texture is independent of machine")
	n.reset();check(n.target==0 and n.source_index==0 and not n.held,"reset restores whole room to loom")

func capture_views(data: Dictionary) -> void:
	root.size=Vector2i(1400,900)
	var cam:=Camera3D.new();current_scene.add_child(cam);cam.fov=74
	var w:=float(data.map_info.dimensions.width)
	var d:=float(data.map_info.dimensions.depth)
	var views: Array=[[Vector3(w*.5,2.4,2),Vector3(w*.5,2,d*.6),"entrance"],[Vector3(w*.5+5,5,d*.33),Vector3(w*.5,2,d*.62),"inside"]]
	if map_name=="Pattern_Foundry": views=[[Vector3(9,2.3,3),Vector3(13,2,15),"entrance"],[Vector3(16,5,9),Vector3(7,2,18),"inside"]]
	for view in views:
		cam.global_position=grid.to_global(view[0]);cam.look_at(grid.to_global(view[1]))
		for i in 45: cam.make_current();await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+map_name+"-"+view[2]+".png")

func finish() -> void:
	var file:=FileAccess.open(OUT+map_name+"-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"map":map_name,"checks":checks,"failures":failures},"  "))
	print("[regularity] ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func inspect_surfaces()	-> void:
	var info: Dictionary = {"grid_position":str(grid.global_position),"surfaces":[],"materials":[]}
	if artifacts.has("tiling_principles"):
		var n: Node3D=artifacts.tiling_principles
		info["artifact_position"]=str(n.global_position)
		for surface in n.surfaces:
			var p: Vector3=surface.global_position
			var q:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*2.0,p-Vector3.UP*3.0)
			var hit: Dictionary=n.get_world_3d().direct_space_state.intersect_ray(q)
			info.surfaces.append({"name":surface.name,"position":str(p),"floor_hit":str(hit.get("position","")),"collider":str(hit.get("collider","")),"floor_clearance":p.y-hit.position.y if hit.has("position") else -999})
	for m in grid.find_children("*","MultiMeshInstance3D",true,false):
		var mat: Material=m.material_override
		if mat is ShaderMaterial:
			var item: Dictionary={"node":str(m.get_path()),"shader":mat.shader.resource_path}
			for key in ["modelColor","wireframeColor","emissionColor","emission_strength","width"]:item[key]=str(mat.get_shader_parameter(key))
			info.materials.append(item)
	var file:=FileAccess.open(OUT+map_name+"-surfaces.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(info,"  "))

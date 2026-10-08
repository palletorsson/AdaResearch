extends SceneTree
## Actual museum geometry test; --map=NAME --capture optionally loads artifacts.
var checks := 0
var failures: Array[String] = []
var measurements: Array = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("[wave-platform] FAIL ", message)

func run() -> void:
	var names: Array = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/map_authored.json")).wavefunctions
	var chosen := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): chosen = arg.trim_prefix("--map=")
	if not chosen.is_empty(): names = [chosen]
	for name in names:
		await museum(str(name))
	var report := {"checks":checks,"failures":failures,"measurements":measurements,
		"artifacts_loaded":"--artifacts" in OS.get_cmdline_user_args(),"headset_verified":false}
	var suffix := chosen if not chosen.is_empty() else "active"
	var f := FileAccess.open("res://ada_run/wave_platform_"+suffix+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  ")); f.close()
	print("[wave-platform] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

func museum(map_name: String) -> void:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/wave-platform-probe-control.json"
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused-hand")
	em.set("start_chapter","wavefunctions");em.set("start_map",map_name)
	var layout:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream",{})["bodies"] = 1 if "--artifacts" in OS.get_cmdline_user_args() else 0
	em.set("_layout",layout)
	var f := FileAccess.open(ctl,FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter":"wavefunctions","dollhouse":0,"grid_pack":1}));f.close()
	root.add_child(em);current_scene=em
	await create_timer(1.0).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var player:Node=em.get("_player")
	if player!=null:player.set_process(false);player.set_physics_process(false)
	var seg:Node3D
	for rec:Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map","")==map_name:seg=rec.node;break
	check(seg!=null,map_name+" exists in the active museum")
	if seg==null:
		em.queue_free();await process_frame;return
	for i in range(4):await physics_frame
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_name+"/map_data.json"))
	var structure:Array=source.layers.structure
	var fresh:Dictionary=em.call("_derive_map_row",map_name)
	var heights:Dictionary=seg.get_meta("em_heights",{})
	var solid:StaticBody3D=seg.get_node("Collision")
	var gate:Dictionary=em.get("_gate")
	check(gate.get("in_doorway",false),map_name+" gate uses the outside doorway")
	check(is_equal_approx(float(gate.get("z",-1)),4.5),map_name+" gate stays on boundary row")
	var platforms:=0;var walls:=0
	for z in range(structure.size()):
		for x in range(structure[z].size()):
			var raw:=str(structure[z][x])
			if raw=="2":
				platforms+=1
				check(fresh.tile[z][x]=="1",map_name+" platform parsed as floor %s"%Vector2i(x,z))
				check(is_equal_approx(float(heights.get(Vector2i(x,z),-1)),1.0),map_name+" one metre height %s"%Vector2i(x,z))
				var top:=solid_top(seg,solid,x,z)
				check(is_equal_approx(top,1.0),map_name+" physical platform top %s = %.3f"%[Vector2i(x,z),top])
			elif raw=="w" and (x==0 or x==structure[z].size()-1 or z==0 or z==structure.size()-1):
				walls+=1
				check(fresh.tile[z][x]=="4",map_name+" explicit boundary wall %s"%Vector2i(x,z))
	# Artifact packing records the floor separately from an optional plinth.
	var stamps:Array=[]
	for record:Dictionary in em.get("_edit_records"):
		var child:Node3D=record.get("node")
		if child==null or not is_instance_valid(child) or not seg.is_ancestor_of(child):continue
		var cell:Array=record.tile_cell
		if cell.size()<2:continue
		var expected:float=heights.get(Vector2i(cell[0],cell[1]),0.0)
		var vis:Array=child.get_meta("em_cartridge_vis_p",[])
		stamps.append({"token":record.token,"cell":cell,"position":seg.to_local(child.global_position),"floor":expected,"plinth_h":record.get("plinth_h",0),"support_anchor":vis})
		if expected>0:
			check(not vis.is_empty() and float(vis[1])>=expected-0.01,map_name+" artifact stands above restored deck: "+str(record.token))
	if "--artifacts" in OS.get_cmdline_user_args():check(stamps.size()>0,map_name+" has actual artifact instances")
	measurements.append({"map":map_name,"platforms":platforms,"boundary_walls":walls,"stamps":stamps})
	print("[wave-platform] ",map_name," platforms=",platforms," walls=",walls," failures=",failures.size())
	if "--capture" in OS.get_cmdline_user_args():
		var cam:=Camera3D.new();em.add_child(cam);cam.fov=70
		var target:=Vector3(structure[0].size()*0.5,0,structure.size()*0.45+4)
		cam.global_position=seg.to_global(Vector3(3,2.7,7));cam.look_at(seg.to_global(target))
		for i in range(30):cam.make_current();await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ada_run/wave_platform_"+map_name+".png")
	em.queue_free();await process_frame

func solid_top(seg:Node3D,solid:StaticBody3D,x:int,z:int)->float:
	var query:=PhysicsRayQueryParameters3D.create(seg.to_global(Vector3(x+0.5,2.5,z+4.5)),seg.to_global(Vector3(x+0.5,-0.2,z+4.5)))
	query.hit_from_inside=true
	var ignored:Array[RID]=[]
	for i in range(64):
		query.exclude=ignored
		var hit:Dictionary=seg.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():return -99.0
		if hit.collider==solid:
			var top:float=seg.to_local(hit.position).y
			if top>1.01:
				var owner_id:int=solid.shape_find_owner(hit.shape)
				var shape_node:Node3D=solid.shape_owner_get_owner(owner_id)
				print("[wave-platform] obstruction ",Vector2i(x,z)," tile=",seg.get_meta("em_tile")[z][x]," shape=",shape_node.name," position=",seg.to_local(shape_node.global_position)," size=",shape_node.shape.size if shape_node.shape is BoxShape3D else shape_node.shape)
			return top
		ignored.append(hit.rid)
	return -98.0

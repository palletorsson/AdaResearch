extends SceneTree
## Tests source spawns separately from museum arrivals, then real pickup contact.
var checks: Array = []
var failures: Array = []
var map_name := "Trans_Pre"
var standalone := false
var grid: Node3D
var museum: Node3D

func _initialize() -> void:
	_run.call_deferred()

func check(label: String, ok: bool, value: Variant = null) -> void:
	checks.append({"name":label,"passed":ok,"value":value})
	if not ok: failures.append(label)
	print("[alignment] ", "PASS " if ok else "FAIL ", label, " ",value)

func tick() -> void:
	await physics_frame
	await process_frame

func scripted(suffix: String) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for n in grid.find_children("*", "Node3D", true, false):
		if n.get_script() != null and n.get_script().resource_path.ends_with(suffix): found.append(n)
	return found

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): map_name=arg.trim_prefix("--map=")
		if arg=="--standalone": standalone=true
	if standalone:
		var world:=Node3D.new()
		root.add_child(world)
		current_scene=world
		grid=load("res://commons/grid/grid_system.tscn").instantiate()
		grid.set("map_name",map_name)
		grid.set("bare_world",true)
		grid.set("skip_player_spawn",true)
		var done:=[false]
		grid.connect("build_finished",func(): done[0]=true,CONNECT_ONE_SHOT)
		world.add_child(grid)
		for i in 1800:
			await process_frame
			if done[0]:break
		check("source grid finished",done[0])
		for i in 10: await tick()
		var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_name+"/map_data.json"))
		var cell:=Vector2i(-1,-1)
		for z in source.layers.utilities.size():
			for x in source.layers.utilities[z].size():
				if str(source.layers.utilities[z][x]).split("#")[0]=="s":cell=Vector2i(x,z)
		var spawn:Dictionary=grid.get("spawn_component").call("_get_spawn_data_from_json")
		check("real spawn resolver uses utility not centroid",spawn.source=="utility_spawn",str(spawn))
		check("resolved start equals entrance cell",absf(spawn.position.x-cell.x)<0.01 and absf(spawn.position.z-cell.y)<0.01,str(cell))
		check("faces forward into sequence",is_equal_approx(float(spawn.rotation.y),180.0))
		check("start cell is solid level-one floor",str(source.layers.structure[cell.y][cell.x])=="1")
	else:
		museum=load("res://commons/scenes/endless_museum.tscn").instantiate()
		var prefix:="res://ada_run/_alignment_"+map_name
		var f:=FileAccess.open(prefix+"_control.json",FileAccess.WRITE)
		f.store_string(JSON.stringify({"first_chapter":"transformation","first_map":map_name,"dollhouse":0,"grid_pack":1}))
		f.close()
		museum.set("EM_CONTROL",prefix+"_control.json")
		museum.set("_overrides_path",prefix+"_overrides.json")
		museum.set("_hand_path",prefix+"_hand.json")
		museum.set("start_chapter","transformation")
		museum.set("start_map",map_name)
		root.add_child(museum)
		current_scene=museum
		for i in 1800:
			await process_frame
			grid=museum.find_child("SimGrid_"+map_name,true,false)
			if grid!=null:break
		check("actual museum source grid exists",grid!=null)
		if grid==null:finish();return
		museum.set_process(false)
		for i in 180:await tick()
		var drop:Vector3=museum.call("_drop_point")
		var deck:float=museum.call("_arrival_floor_y",drop.x,drop.z)
		var hit:=grid.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(drop.x,deck+0.3,drop.z),Vector3(drop.x,deck-0.3,drop.z),1))
		check("museum arrival has supporting floor",not hit.is_empty(),{"drop":str(drop),"deck":deck,"hit":str(hit)})
		check("museum suppresses grid spawn",bool(grid.get("skip_player_spawn")))
		if map_name=="Trans_Pre":await pre()
		if map_name=="Trans_Introduction":
			var crabs:=scripted("/head_crab.gd")
			check("crossing lesson has no authored head crab",crabs.is_empty())
		if map_name=="Trans_Translation":await translation()
	finish()

func make_rig(feet:Vector3) -> Dictionary:
	var origin:=XROrigin3D.new()
	origin.name="AlignmentXROrigin"
	origin.position=feet
	var cam:=XRCamera3D.new()
	cam.name="Camera"
	cam.position.y=1.7
	origin.add_child(cam)
	var body:CharacterBody3D=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate()
	body.set("player_calibrate_height",false)
	body.set("eye_forward_offset",0.0)
	origin.add_child(body)
	root.add_child(origin)
	return {"origin":origin,"body":body}

func pre() -> void:
	var cubes:=scripted("/pick_up_cube.gd")
	cubes.sort_custom(func(a,b):return a.global_position.z<b.global_position.z)
	check("eight stages and pickups present",cubes.size()==8)
	if cubes.size()!=8:return
	var first:Node3D=cubes[0]
	check("still cube occupies moved station",absf(grid.to_local(first.global_position).z-3.0)<0.01,str(grid.to_local(first.global_position)))
	var ref:WeakRef=weakref(first)
	var rig:=make_rig(grid.to_global(Vector3(4,0.51,1)))
	for i in 30:await tick()
	check("still cube survives at source entry",ref.get_ref()!=null)
	var entry_z:float=rig.body.global_position.z
	for i in 180:
		await physics_frame
		if rig.body.global_position.z < entry_z+0.99: rig.body.move_player(Vector3(0,0,1))
		else: rig.body.move_player(Vector3.ZERO)
		await process_frame
	check("still cube survives first metre",ref.get_ref()!=null,{"distance":rig.body.global_position.z-entry_z,"body":str(grid.to_local(rig.body.global_position))})
	for i in 90:
		await physics_frame
		rig.body.move_player(Vector3(0,0,1))
		await process_frame
	check("deliberate approach collects it",ref.get_ref()==null)
	rig.origin.queue_free()
	await tick()

func translation() -> void:
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Trans_Translation/map_data.json"))
	var pickups:=scripted("/pick_up_cube.gd")
	check("thirteen pickups instantiated",pickups.size()==13,pickups.size())
	var carriers:=scripted("/transport_cube.gd")
	check("seven transport cubes instantiated",carriers.size()==7,carriers.size())
	var by_cell:={}
	for p in pickups:
		var local:=grid.to_local(p.global_position)
		by_cell[Vector2i(roundi(local.x),roundi(local.z))]=weakref(p)
	for ride in source.translation_course.rides:
		var start:=Vector3(float(ride.start[0]),float(ride.start[1]),float(ride.start[2]))
		var carrier:Node3D
		for c in carriers:
			var local:=grid.to_local(c.initial_position)
			if Vector2(local.x,local.z).distance_to(Vector2(start.x,start.z))<0.1:carrier=c
		check(str(ride.id)+" has carrier",carrier!=null)
		if carrier==null:continue
		for pp in ride.pickups:
			var cell:=Vector2i(pp[0],pp[2])
			check(str(ride.id)+" pickup at declared cell "+str(cell),by_cell.has(cell))
			if by_cell.has(cell):
				var p:Node3D=by_cell[cell].get_ref()
				check("pickup height follows course "+str(cell),p!=null and absf(float(p.original_y)-grid.global_position.y-float(pp[1]))<0.03,p.original_y-grid.global_position.y if p!=null else null)
		# Actual XR body boards and rides through detection volumes; never call collect().
		carrier.set("move_speed",3.0)
		carrier.set("start_delay",0.1)
		carrier.set("return_delay",20.0)
		var rig:=make_rig(carrier.global_position+Vector3.UP*0.51)
		var arrived:=false
		for i in 700:
			await tick()
			if carrier.global_position.distance_to(carrier.target_position)<0.04:
				arrived=true
				break
		for i in 30:await tick()
		check(str(ride.id)+" ride reaches destination",arrived)
		for pp in ride.pickups:
			var cell:=Vector2i(pp[0],pp[2])
			check(str(ride.id)+" rider collects "+str(cell),by_cell.has(cell) and by_cell[cell].get_ref()==null)
		rig.origin.queue_free()
		await tick()
		await tick()

func finish() -> void:
	var path:="res://doc/space/transformation-alignment-2026-09-17/"+map_name+("-source" if standalone else "-museum")+".json"
	var f:=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"map":map_name,"standalone":standalone,"checks":checks,"failures":failures,"headset_tested":false},"  "))
	f.close()
	print("[alignment] ",checks.size()-failures.size(),"/",checks.size()," ",path)
	quit(0 if failures.is_empty() else 1)

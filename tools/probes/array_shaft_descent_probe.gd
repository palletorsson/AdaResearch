extends "res://tools/probes/array_trial_probe.gd"
## Continuous descent with the real desktop and XR movement providers.

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	var body_visible: bool = game.body.visible
	game.body.hide()
	await super.photo(filename,at,target)
	game.body.visible = body_visible

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1);return
	for use_xr in [false,true]:
		await descend(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Continuous native jumps on desktop and synthetic XR; no physical headset test."
	},"\t"))
	print("ARRAY_SHAFT_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func descend(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	var content: Node3D=game.building.content
	var original: Node3D=content.exhibits["1/shaft-volume"].get_node("Artifact")
	var volume: Node3D=original.get_node("ShaftDescent")
	check(tag+"uses the existing 3D array with explicit shaft arrangement",original.get_script().resource_path=="res://algorithms/arrays/grid_3d_4x4x4.gd")
	check(tag+"six by six on each of three layers: 108 addresses and 101 solids",volume.size_x==6 and volume.size_y==3 and volume.size_z==6 and volume.cells.size()==108 and volume.solids.size()==101)
	var open_route := true
	for x in range(1,6):
		open_route = open_route and volume.values[x][0][0]==0 and not volume.solids.has(Vector3i(x,0,0))
	for x in range(4,6):
		open_route = open_route and volume.values[x][1][0]==0 and not volume.solids.has(Vector3i(x,1,0))
	check(tag+"seven empty addresses clear the descending jump route",open_route)
	check(tag+"far corner retains its full three-index address",volume.values[5][2][5]==1 and volume.solids.has(Vector3i(5,2,5)))
	var aligned := true
	var fit := true
	for cell in volume.solids:
		var body: StaticBody3D=volume.solids[cell]
		var collider: CollisionShape3D=body.get_child(0)
		var bounds: Vector3=collider.shape.size
		var top: Vector3=body.global_position+Vector3.UP*bounds.y/2.0
		aligned=aligned and absf(top.y-(-6-cell.y*2.7))<.005
		fit=fit and top.x-bounds.x/2.0>=-12.5 and top.x+bounds.x/2.0<=-7.5 and absf(top.z)+bounds.z/2.0<=3.0
		var mesh: MeshInstance3D=volume.cells[cell].get_node("Cube/CubeBaseMesh")
		var mesh_top: float=(mesh.global_transform*mesh.get_aabb()).end.y
		aligned=aligned and absf(mesh_top-top.y)<.005
	check(tag+"first layer is flush; lower tops at minus 2.7 and 5.4 metres",aligned)
	check(tag+"all landing cubes fit inside free shaft A",fit)
	var hole: Vector3=volume.to_global(volume.cell_top(Vector3i(1,0,0)))
	var ray:=PhysicsRayQueryParameters3D.create(hole+Vector3.UP*.1,hole-Vector3.UP*.15,1)
	check(tag+"empty address has no invisible support",game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
	var score: int=game.trial_session.score
	var museum_score: int=root.get_node("GameManager").player_score
	# Relocate only to the start. Every landing below is reached by normal input.
	var start_at: Vector3=volume.to_global(Vector3(-3.3,.06,-6.4))
	game.place_player(start_at)
	await frames(25)
	var charge: float=game.charge.get_charge()
	var succeeded := true
	for i in volume.route.size():
		var at: Vector3=volume.to_global(volume.cell_top(volume.route[i]))
		var reached: bool=await move_to(at,true,200)
		check(tag+"continuous jump reaches layer %d"%i,reached)
		if not reached:
			succeeded=false
			break
		check(tag+"landing %d remains solid after contact"%i,volume.cells[volume.route[i]].get_node("Cube").hold=="demo" and not volume.cells[volume.route[i]].get_node("Cube").has_been_collected)
		check(tag+"shaft supports remain live while descending %d"%i,volume.is_visible_in_tree() and volume.solids[volume.route[i]].can_process())
		if not xr and i==1:
			await photo("inside-the-array",volume.to_global(Vector3(-3,-1.0,-.6)),volume.to_global(Vector3(.5,-3.3,-4.4)))
	if succeeded:
		var exit_at: Vector3=volume.to_global(Vector3(3.4,-6,-6.4))
		check(tag+"jump out onto the next structural floor",await move_to(exit_at,true,200))
		check(tag+"lower floor becomes the checkpoint",game.checkpoint==2 and game.deaths==0)
		check(tag+"four jumps pay the existing charge rule",charge-game.charge.get_charge()>=20 and charge-game.charge.get_charge()<24)
	check(tag+"supports do not award pickup points",game.trial_session.score==score and root.get_node("GameManager").player_score==museum_score)
	if not xr:
		await photo("shaft-from-above",Vector3(-13.7,-2.7,1.2),Vector3(-9.7,-9,-.2))
		await photo("lower-landing",Vector3(-5.7,-9.8,-.5),Vector3(-10,-9.8,-.7))
		var source: Node3D=load("res://algorithms/arrays/grid_3d_4x4x4.gd").new()
		source.position=Vector3(100,0,100)
		root.add_child(source)
		await frames(2)
		check("museum default remains 64 pickup cubes",source.get_children().filter(func(child):return str(child.name).begins_with("Cube_")).size()==64 and not source.has_node("ShaftDescent"))
		source.queue_free()
	game.die("Retry the 3D array")
	await frames(120)
	check(tag+"retry rebuilds one 3D array on the starting floor",game.checkpoint==1 and not game.recovering and content.exhibits["1/shaft-volume"].get_node("Artifact/ShaftDescent").solids.size()==101)
	game.queue_free()
	await frames(6)
	if xr:
		for tracker_node in [head,left,right]:XRServer.remove_tracker(tracker_node)

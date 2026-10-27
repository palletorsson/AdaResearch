extends "res://tools/probes/void_trial_probe.gd"
## Exercise the actual collections and their construction-grid adapter with both rigs.

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head", XRServer.TRACKER_HEAD, "default", Vector3(0,1.65,0))
		left = tracker("left_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(-.3,1.2,-.4))
		right = tracker("right_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO); right.set_input("primary",Vector2.ZERO)
		right.set_input("grip",0.0); right.set_input("trigger_click",false)
	var scene: PackedScene = load("res://commons/void/trials/array_tutorial/trial.tscn")
	game = scene.instantiate()
	check("trial satisfies staging scene type",is_instance_of(game,load("res://addons/godot-xr-tools/staging/scene_base.gd")))
	game.force_xr = xr
	root.add_child(game); current_scene = game
	if not xr: game.body.scripted_input = true
	await frames(45)
	game.scene_loaded(); game.scene_visible()
	await frames(30)
	game.atmosphere.animate_sky=false; game.atmosphere.set_sky_time(180)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("uses isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1);return
	var museum_score: int = root.get_node("GameManager").player_score
	for use_xr in ([true] if take_photos else [false,true]):
		await visit(use_xr,museum_score)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native physics, desktop and synthetic XR. No physical headset test."},"\t"))
	print("ARRAY_TRIAL_RESULT ", checks.size(), " checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func walk(at: Vector3) -> bool:
	for i in 420:
		var offset: Vector3=at-game.body.global_position
		var facing: Basis=game.camera.global_basis if xr else game.body.global_basis
		var local: Vector3=facing.inverse()*Vector3(offset.x,0,offset.z)
		axes(Vector2(local.x,local.z).normalized() if Vector2(offset.x,offset.z).length()>.08 else Vector2.ZERO)
		await frames(1)
		if game.recovering: axes(Vector2.ZERO);return false
		if Vector2(offset.x,offset.z).length()<.22 and absf(offset.y)<.16 and game.body.is_on_floor():
			axes(Vector2.ZERO);await frames(20);return true
	axes(Vector2.ZERO)
	print("MISSED ",at," ACTUAL ",game.body.global_position)
	return false

func press(button: Node3D) -> void:
	var target: Vector3=button.global_position
	if xr:
		var origin: Node3D=game.get_node("XROrigin3D")
		var at: Vector3=target+Vector3(0,.04,.65)
		right.set_pose("aim",Transform3D(Basis.looking_at(target-at),origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(20)
		right.set_input("trigger_click",true);await frames(6)
		right.set_input("trigger_click",false);await frames(12)
		hand_at(right,game.body.global_position+Vector3(.3,1.2,-.4))
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		game.camera.look_at(target)
		await frames(20)
		print("DESKTOP POINTER active=",game.body.desktop_pointer._active()," target=",game.body.desktop_pointer._last_target," mouse=",Input.mouse_mode)
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
		Input.parse_input_event(event);await frames(6)
		event=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false
		Input.parse_input_event(event);await frames(12)

func photo(filename: String, at: Vector3, target: Vector3) -> void:
	if not take_photos:return
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var origin: Node3D=game.get_node("XROrigin3D");origin.hide()
	root.msaa_3d=Viewport.MSAA_4X
	await photograph(filename,at,target)
	origin.show()

func visit(use_xr: bool, museum_score: int) -> void:
	await start(use_xr)
	var tag: String="XR: " if xr else "Desktop: "
	var content: Node3D=game.building.content
	check(tag+"starts on an isolated floor with two shafts",game.checkpoint==1 and game.building.spec.levels.size()==3 and game.building.spec.shafts.size()==2)
	check(tag+"all three encounters come from editable placements",content.data.floors[1].artifacts.size()==3 and content.data.floors[1].construction.size()==4)
	var row: Node3D=content.exhibits["1/row"].get_node("Artifact")
	var grid: Node3D=content.exhibits["1/grid"].get_node("Artifact")
	var work: Node3D=content.exhibits["1/worksite"].get_node("Artifact")
	check(tag+"original row and grid scripts retained",row.get_script().resource_path=="res://algorithms/arrays/row_3_x.gd" and grid.get_script().resource_path=="res://algorithms/arrays/grid_2d_4x4.gd")
	check(tag+"four and sixteen independent pickup cubes",row._cube_refs.size()==4 and grid._cube_refs.size()==16)
	await photo("01-numbered-row",Vector3(-17.5,-4.3,2.8),Vector3(-17.5,-5,-2.4))
	var neighbour: Node3D=row._cube_refs[3]
	var neighbour_at: Vector3=neighbour.position
	game.place_player(Vector3(-17,-5.94,.4));await frames(12)
	check(tag+"walk into row index two",await walk(Vector3(-17,-6,-2)))
	check(tag+"one collected cube sets slot two to zero without shifting slot three",not row._cube_refs.has(2) and row.array_data[0][2]==0 and row._cube_refs[3]==neighbour and is_equal_approx(neighbour.position.x,neighbour_at.x) and is_equal_approx(neighbour.position.z,neighbour_at.z) and row.array_data[0][3]==1 and row._binary_table.data[0][2]==0)
	check(tag+"nested pickup scores only in trial",game.trial_session.score==1 and root.get_node("GameManager").player_score==museum_score)
	await photo("02-empty-address",Vector3(-17.5,-4.3,2.8),Vector3(-17.5,-5,-2.4))
	# A body overlap at one address isolates the grid's indexing from a route
	# which could legitimately collect several cubes on the way there.
	neighbour=grid._cube_refs["2_1"]
	neighbour_at=neighbour.position
	game.place_player(Vector3(16,-5.94,.5));await frames(30)
	check(tag+"grid [1,2] becomes zero while [2,1] remains",not grid._cube_refs.has("1_2") and grid.grid_data[1][2]==0 and grid.grid_data[2][1]==1 and grid._cube_refs["2_1"]==neighbour and is_equal_approx(neighbour.position.x,neighbour_at.x) and is_equal_approx(neighbour.position.z,neighbour_at.z) and grid._binary_table.data[1][2]==0)
	check(tag+"empty grid address keeps its physical plaque",grid.find_children("*","Label3D",true,false).any(func(n):return n.text=="[1, 2]"))
	check(tag+"both collections leave museum progress alone",game.trial_session.score==2 and root.get_node("GameManager").player_score==museum_score)
	await photo("03-addressed-grid",Vector3(19.2,-3.9,5.5),Vector3(15.6,-5,-.1))
	check(tag+"worksite reuses the original floor writer",work.get_script().get_base_script().resource_path=="res://commons/artifacts/array_floor_writer/array_floor_writer.gd")
	check(tag+"eighty one-metre supports, sixteen mutable ground addresses",work.grid.cube_positions.size()==80 and work.original.size()==16 and not work.running)
	check(tag+"fixed perimeter cannot be consumed or extended",not work.grid.remove_cube_at(0,0,0) and not work.grid.add_cube_at(0,1,0))
	check(tag+"construction uses batched meshes and solid cell collision",not work.grid.batch.find_children("*","MultiMeshInstance3D",true,false).is_empty() and work.grid.batch.find_children("*","CollisionShape3D",true,false).size()==80)
	game.place_player(Vector3(-2,-5.94,7.6));await frames(15)
	check(tag+"original wedge leads onto the one-metre deck",await walk(Vector3(-2,-5,4.4)))
	game.place_player(Vector3(0,-5.94,8.45));await frames(15)
	var writes_before: int=work.writes
	await press(work.copy_button)
	check(tag+"pointer COPY adds one address and collider",work.writes==writes_before+1 and work.grid.cube_positions.size()==81 and work.grid.batch.find_children("*","CollisionShape3D",true,false).size()==81)
	await press(work.consume_button)
	check(tag+"pointer CONSUME removes one address and collider",work.writes==writes_before+2 and work.grid.cube_positions.size()==80 and work.grid.batch.find_children("*","CollisionShape3D",true,false).size()==80)
	await photo("04-addresses-become-support",Vector3(3.4,-2.7,7.6),Vector3(-.8,-5,-.5))
	await press(work.restore_button);await frames(35)
	check(tag+"pointer RESTORE restores the original deck",not work.restoring and work.changed.is_empty() and work.grid.cube_positions.size()==80)
	await press(work.pause_button)
	check(tag+"pointer starts original agent",work.running and work.agent.is_physics_processing())
	writes_before=work.writes
	await frames(600)
	check(tag+"original agent changes the real construction grid",work.writes>writes_before)
	await press(work.pause_button)
	writes_before=work.writes
	await frames(100)
	check(tag+"pause stops writes",not work.running and work.writes==writes_before)
	work.restore_floor();await frames(40)
	# Remove a specific support to verify physical fall and safe pending restore.
	var cell:=Vector3i(3,0,4)
	var cell_world: Vector3=work.grid.parent_node.to_global(Vector3(cell))
	game.place_player(cell_world+Vector3(0,.56,0));await frames(20)
	var health_before: float=game.health.get_health()
	work.grid.remove_cube_at(cell.x,cell.y,cell.z);work.record(cell,"CONSUMED")
	await frames(60)
	print("SUPPORT DROP ",tag,game.body.global_position," charge ",health_before," -> ",game.health.get_health())
	check(tag+"consumed support drops the player onto the fixed slab without a landing charge",game.body.is_on_floor() and absf(game.body.global_position.y+6)<.12 and health_before-game.health.get_health()<.5)
	work.restore_floor();await frames(35)
	check(tag+"restore waits for the occupied cell",work.restoring and not work.grid.has_cube_at(cell.x,cell.y,cell.z))
	game.place_player(Vector3(0,-5.94,8.45));await frames(40)
	check(tag+"step clear completes restore",not work.restoring and work.grid.has_cube_at(cell.x,cell.y,cell.z) and work.grid.cube_positions.size()==80)
	game.place_player(game.spawn_for(2));await frames(15)
	game.place_player(game.spawn_for(1));await frames(15)
	check(tag+"leaving and returning preserves collection state",content.exhibits["1/row"].get_node("Artifact")==row and not row._cube_refs.has(2))
	game.die("Retry array trial");await frames(120)
	check(tag+"retry rebuilds all collections and resets local score",not game.recovering and game.trial_session.score==0 and content.exhibits["1/row"].get_node("Artifact")._cube_refs.size()==4 and content.exhibits["1/grid"].get_node("Artifact")._cube_refs.size()==16 and content.exhibits["1/worksite"].get_node("Artifact").grid.cube_positions.size()==80)
	check(tag+"retry keeps three artifact placements",content.exhibits.size()==3)
	await photo("05-inside-the-trial",Vector3(0,-3.8,8.4),Vector3(0,-4.8,-.4))
	game.queue_free();await frames(6)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)

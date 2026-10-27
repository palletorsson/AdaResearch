extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--receipt="):output=arg.trim_prefix("--receipt=")
	var definitions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/trials/playable.json")).trials
	var checks: Array=[]
	for id in ["spatial_lab_d2eacf90a6","spatial_lab_764639c78c"]:
		var host:=Node3D.new();root.add_child(host);current_scene=host
		var building: Node3D=load("res://commons/void/architecture.gd").new();building.trial_id=id;host.add_child(building)
		var health: Node=load("res://commons/void/health.gd").new();host.add_child(health)
		var player: Node3D=load("res://commons/void/walker.gd").new();player.scripted_input=true;host.add_child(player);player.add_to_group("em_walker")
		var spawn: Array=definitions[id].spawn_points["1"]
		player.global_position=Vector3(spawn[0],float(building.spec.levels[1])+float(spawn[1]),spawn[2])
		for frame in 60:await physics_frame;await process_frame
		var ok: bool=player.is_on_floor() and health.get_health()==100
		checks.append({"trial":id,"passed":ok,"on_floor":player.is_on_floor(),"charge":health.get_health(),"feet":[player.global_position.x,player.global_position.y,player.global_position.z]})
		player.free();host.free();await physics_frame
	var passed: bool=checks.all(func(c):return c.passed)
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Actual registered start positions settle safely with production walker and live electrical bed; headless physics only."},"  "))
	print("WAREHOUSE_SPAWN ",JSON.stringify(checks));quit(0 if passed else 1)

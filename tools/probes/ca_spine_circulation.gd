extends "res://tools/probes/ca_spine_active.gd"
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	await start(false);level = 109;game.place_player(game.spawn_for(level));await frames(90)
	var wall: Node3D = artifact("void_ca_history_wall");var y: float = game.building.spec.levels[level]
	var hit: Dictionary = ray(wall.to_global(Vector3(0,2.5,1)),wall.to_global(Vector3(0,2.5,-1)))
	check("architectural receiver has a real solid face",not hit.is_empty() and wall.is_ancestor_of(hit.collider))
	game.place_player(Vector3(-9.1,y+.06,-4.3));await frames(20)
	check("left circulation reaches behind the wall",await move_to(Vector3(-9.1,y+.06,-8.25),false,300))
	check("rear circulation crosses the room",await move_to(Vector3(9.1,y+.06,-8.25),false,600))
	check("right circulation returns to the working side",await move_to(Vector3(9.1,y+.06,-4.3),false,300))
	wall.position += Vector3(.3,0,.1);wall.rotation.y = PI/2;await frames(3)
	hit = ray(wall.to_global(Vector3(0,2.5,1)),wall.to_global(Vector3(0,2.5,-1)))
	check("moved and rotated receiver carries its solid face",not hit.is_empty() and wall.is_ancestor_of(hit.collider))
	FileAccess.open(out.path_join("circulation.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed},"  "))
	print("CA_BASELINE_RESULT ",checks.size()," circulation checks; failures ",failed);quit(0 if failed.is_empty() else 1)

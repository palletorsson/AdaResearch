extends "res://tools/probes/array_trial_probe.gd"
## Actual shared floor, both player rigs, and collision at each ramp join.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save data",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed: quit(1);return
	for use_xr in [false,true]:
		await start(use_xr)
		var tag := "XR: " if use_xr else "Desktop: "
		var row: Node3D=game.building.content.exhibits["1/row"].get_node("Artifact")
		check(tag+"32 original addressed cubes",row._cube_refs.size()==32)
		check(tag+"row raised onto metre boxes",is_equal_approx(row.global_position.y,-5.0))
		# Sample the actual collision surface, including both sloped approaches.
		for x in [-17.8,-17.0,-16.2,-15.8,0.0,15.8,16.2,17.0,17.8]:
			var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(Vector3(x,-3,-4),Vector3(x,-7,-4),1))
			var rise: float=1.0 if absf(x)<=16.0 else (18.0-absf(x))/2.0
			check(tag+"continuous support at x="+str(x),not hit.is_empty() and absf(hit.position.y-(-6.0+rise))<.025)
		for side in [-1,1]:
			game.place_player(Vector3(side*18.6,-5.94,-4))
			await frames(35)
			check(tag+"walk up end "+str(side),await walk(Vector3(side*15,-5,-4)))
			check(tag+"walk down end "+str(side),await walk(Vector3(side*18.6,-6,-4)))
		if not use_xr:
			await photo("row-on-boxes",Vector3(-20,-1,2),Vector3(-5,-4.5,-4.5))
		game.queue_free()
		await frames(6)
		if use_xr:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":failed.is_empty(),"checks":checks,"failed":failed,
		"scope":"Native collision and walking with desktop and synthetic XR; no physical headset test."
	},"\t"))
	print("ARRAY_ROW_SUPPORT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

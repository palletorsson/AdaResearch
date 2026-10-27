extends "res://tools/probes/transformation_required_route.gd"
## Actual main floor, unchanged movement and transformation mechanisms.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": route_photos=true
	var use_xr := "--xr-only" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(out)
	await start(use_xr)
	await visit_logic_floor(14)
	var tag := "Synthetic XR / " if xr else "Desktop / "
	check(tag+"8 independently editable two-metre walls", game.building.content.data.floors[14].walls.filter(func(w): return str(w.id).begins_with("trans14-route-")).size()==8)
	check(tag+"only the entry ramp remains", not game.building.content.data.floors[14].construction.any(func(c): return str(c.id).begins_with("LeaveRamp")))
	var y: float=game.building.spec.levels[14]
	for c in [[14,0,11.7,0],[6,0,8.5,0],[10,4.2,10,1.5],[10,-4.2,10,-1.5],[-15,0,-12,0],[-4.8,0,-8,0],[-10,-5.15,-10,-3],[-10,5.15,-10,3]]:
		game.place_player(Vector3(c[0],y+.06,c[1]));await frames(15)
		await move_to(Vector3(c[2],y,c[3]),true,100)
		var p: Vector3=game.body.global_position
		var crossed := (p.x<12.35 if c[0]==14 else (p.x>7.65 if c[0]==6 else (absf(p.z)<2.85 if c[0]==10 else (p.x>-13.75 if c[0]==-15 else (p.x<-6.25 if c[0]==-4.8 else absf(p.z)<2.7)))))
		check(tag+"ground jump blocked at "+str(c), not crossed and not game.recovering)
		print("ENCLOSURE_APPROACH ",c," => ",p)
	game.place_player(Vector3(18.5,y+.06,-8.3));await frames(25)
	game.health.reset();metres_start=game.health.metres_travelled
	var okay := await enclosed_traversal(tag)
	check(tag+"continuous ramp-to-next-floor route",okay)
	if route_photos and not xr:
		await visit_logic_floor(14)
		await image("01-entry-and-pit-walls",Vector3(18.8,y+5.4,-8.2),Vector3(5,y+2.6,0))
		await image("02-rotation-and-scale-entry",Vector3(1.8,y+4.8,-5.8),Vector3(-5.5,y+3,0))
		var growth: Node3D=game.building.content.exhibits["14/sequence"].get_node("Artifact/GrowingCube")
		for i in 1800:
			if growth.current_scale>4.999 and growth.pause_timer>4.5:break
			await frames(1)
		await image("03-scale-exit-chamber",Vector3(-13.1,y+4.8,2.1),Vector3(-9.2,y+2.5,0))
	game.queue_free();await frames(20)
	if xr:
		for t in [head,left,right]: XRServer.remove_tracker(t)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"scope":"Native physics: eight ground shortcut attempts; continuous ordinary movement up the ramp, riding the original ferry, crossing the original rotating plank and growing cube, inner-rim landing then the normal six-metre descent. Synthetic XR is not physical-headset acceptance. Does not prove resistance to every possible exploit."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("ENCLOSED_ROUTE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)

func enclosed_traversal(tag: String) -> bool:
	level=14
	var assembly: Node3D=game.building.content.exhibits["14/sequence"].get_node("Artifact")
	var platform: Node3D=game.building.content.roots[14].get_node("Construction/SuspendedPlatform").platform
	var turn: Node3D=assembly.get_node("TurningPlank")
	var growth: Node3D=assembly.get_node("GrowingCube")
	for p in [[16,0,-8.3],[16,1,-6],[16,2,-4],[16,3,0],[14.5,3,0]]:
		if not await walk(p[0],p[1],p[2],tag): return false
	check(tag+"ferry docks at the entrance",await dock(platform,false))
	if not await walk(12.45,3,0,tag): return false
	check(tag+"ferry carries the real player",platform.carried_player==game.body)
	check(tag+"ferry carries the player above both low walls",await dock(platform,true))
	for p in [[6.5,3,0],[3.1,3,0]]:
		if not await walk(p[0],p[1],p[2],tag): return false
	var aligned := false
	for i in 1800:
		await frames(1)
		if is_zero_approx(turn.current_angle) and not turn.is_rotating and turn.pause_timer>4.5:
			aligned=true;break
	check(tag+"turning plank aligns",aligned)
	if not await walk(-4.2,3,0,tag): return false
	if not await walk(-6.8,3,0,tag): return false
	aligned=false
	for i in 1800:
		await frames(1)
		if growth.current_scale>4.999 and growth.pause_timer>4.5:
			aligned=true;break
	check(tag+"growing cube meets the bank",aligned)
	if not await walk(-11.7,3,0,tag): return false
	check(tag+"all three transformations use normal player movement",normal_charge(0) and game.deaths==0)
	check(tag+"jump from the growing cube lands on the enclosed inner rim",await move_to(Vector3(-13.05,-84,1.9),true,220))
	check(tag+"inner rim landing retains normal health rules",normal_charge(1) and game.deaths==0)
	if not await walk(-12.73,0,1.9,tag): return false
	# The full-size cube occupies the shaft. The rim is a safe place to wait
	# until contraction opens the same passage for the ordinary downward step.
	var open := false
	for i in 1800:
		if growth.current_scale<2.8: open=true;break
		await frames(1)
	check(tag+"contraction opens the drop beside the inner rim",open)
	await move_to(Vector3(-11.7,-84,1.9),false,100);await frames(140)
	check(tag+"normal A-shaft drop reaches floor 15",game.checkpoint==15 and not game.recovering and game.deaths==0)
	return game.checkpoint==15 and not game.recovering and game.deaths==0

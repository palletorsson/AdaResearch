extends "res://tools/probes/transformation_required_route.gd"
## Native main-tower input and carried-support checks; synthetic XR is labelled.
var pictures := false
var focused := false
var ride: Node3D
var assembly: Node3D
var y := -84.0
var milestones: Array = []

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":pictures=true
		if arg=="--focused":focused=true
	DirAccess.make_dir_recursive_absolute(out)
	await start("--xr-only" in OS.get_cmdline_user_args());await visit_logic_floor(14)
	y=float(game.building.spec.levels[14])
	assembly=game.building.content.exhibits["14/sequence"].get_node("Artifact")
	ride=assembly.get_node("GrowingCube")
	var field_a: Node3D=assembly.get_node("ShaftFieldA")
	var field_b: Node3D=assembly.get_node("ShaftFieldB")
	var tag := "Synthetic XR / " if xr else "Desktop / "
	check(tag+"route walls are removed",not game.building.content.data.floors[14].walls.any(func(w):return str(w.id).begins_with("trans14-route-")))
	check(tag+"both electrical covers are independently editable",assembly.part_defaults.has("ShaftFieldA") and assembly.part_defaults.has("ShaftFieldB"))
	game.place_player(Vector3(-10,y+.15,2.8));await frames(30)
	check(tag+"live electrical cover physically supports B above the shaft",field_a.enabled and field_b.enabled and game.body.is_on_floor() and absf(game.body.global_position.y-y-.09)<.12 and game.deaths==0)
	game.place_player(Vector3(16,y+.06,-8.3));await frames(20);game.health.reset()
	if focused:
		game.place_player(Vector3(-6.8,y+3.03,0));await frames(20)
	else:
		if not await crossings_approach(tag):await finish();return
	var ready := false
	for i in 1200:
		if ride.phase==ride.Phase.UPPER_WAIT:ready=true;break
		await frames(1)
	check(tag+"cube grows to the bridge and waits for boarding",ready and absf(ride.global_position.y+ride.current_scale*.5-y-3)<.02)
	if pictures and not xr:await photo("01-electrical-covers",Vector3(4,y+5,-7),Vector3(-7,y+1,0))
	if not await walk(-8.1,3,0,tag):await finish();return
	check(tag+"boarding the actual support opens only its shaft cover",ride.carried_player==game.body and not field_a.enabled and field_b.enabled and field_a.cover.collision_layer==0)
	var max_error := 0.0
	var phases: Array = []
	var supported := true
	for i in 2400:
		await frames(1)
		if not ride.phase in phases:phases.append(ride.phase)
		var top: float=ride.global_position.y+ride.motion_y+ride.current_scale*.5
		max_error=maxf(max_error,absf(game.body.global_position.y-top))
		supported=supported and ride.carried_player==game.body and not game.recovering and game.deaths==0
		if ride.phase==ride.Phase.DESCEND and pictures and not xr and not "descent" in milestones:
			milestones.append("descent");await photo("02-shrunk-cube-descent",ride.global_position+Vector3(4,ride.motion_y+3,5),ride.static_body.global_position)
		if ride.phase==ride.Phase.LOWER_WAIT:break
	check(tag+"B stays on the same shrinking and descending support",supported and max_error<.25)
	check(tag+"shrink, 9m descent and expansion all occur",ride.Phase.SHRINK_UPPER in phases and ride.Phase.DESCEND in phases and ride.Phase.GROW_LOWER in phases and ride.phase==ride.Phase.LOWER_WAIT and absf(ride.motion_y+9)<.01)
	check(tag+"expanded cube top meets the next floor",absf(ride.static_body.global_position.y+ride.current_scale*.5-float(game.building.spec.levels[15]))<.02)
	await frames(35)
	check(tag+"source floor stays live and lower contact saves checkpoint 15",game.floor_stream.records[14].mode=="live" and game.checkpoint==15 and game.deaths==0)
	if pictures and not xr:await photo("03-lower-floor-dock",Vector3(-15,y-2,5),Vector3(-10,y-6,0))
	level=15
	var exited := await move_to(Vector3(-13.1,y-6,0),false,540)
	await frames(25)
	check(tag+"B can step onto the real lower slab",exited and game.body.is_on_floor() and game.checkpoint==15 and game.deaths==0)
	var exit_position: Vector3=game.body.global_position
	for i in 2400:
		await frames(1)
		if ride.phase==ride.Phase.UPPER_WAIT and field_a.enabled:break
	check(tag+"empty cube returns and restores the upper electrical cover",ride.phase==ride.Phase.UPPER_WAIT and field_a.enabled and absf(ride.motion_y)<.01)
	check(tag+"reset does not pull B back upstairs",game.body.global_position.distance_to(exit_position)<.25 and game.checkpoint==15 and game.deaths==0)
	print("SCALE_RIDE_DETAILS ",JSON.stringify({"maximum_support_error":max_error,"phases":phases,"health":game.health.get_health(),"position":game.body.global_position,"focus":game.floor_stream.focus,"pinned":game.floor_stream.pinned}))
	await finish()

func crossings_approach(tag: String) -> bool:
	level=14
	var platform: Node3D=game.building.content.roots[14].get_node("Construction/SuspendedPlatform").platform
	for p in [[16,1,-6],[16,2,-4],[16,3,0],[14.5,3,0]]:
		if not await walk(p[0],p[1],p[2],tag):return false
	check(tag+"entry ferry docks",await dock(platform,false))
	if not await walk(12.45,3,0,tag):return false
	check(tag+"entry ferry reaches its bank",await dock(platform,true))
	for p in [[6.5,3,0],[3.1,3,0]]:
		if not await walk(p[0],p[1],p[2],tag):return false
	var turn: Node3D=assembly.get_node("TurningPlank")
	for i in 1800:
		if is_zero_approx(turn.current_angle) and not turn.is_rotating and turn.pause_timer>4.5:break
		await frames(1)
	for p in [[-4.2,3,0],[-6.8,3,0]]:
		if not await walk(p[0],p[1],p[2],tag):return false
	return true

func photo(filename: String,at: Vector3,target: Vector3) -> void:
	var camera := Camera3D.new();camera.fov=65;game.add_child(camera);camera.global_position=at;camera.look_at(target);camera.make_current()
	await frames(2);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename+".png"));camera.queue_free();game.camera.make_current()

func finish() -> void:
	var report := {"passed":failed.is_empty(),"checks":checks,"failed":failed,"focused":focused,"physical_headset":"not tested","scope":"Real main-tower desktop or synthetic tracked-XR motor input. Same-body scale carry, field collision, 9m travel, lower-floor docking/checkpoint, disembarkation, source-floor residency and automatic reset. Focused mode starts at the scale bank and does not establish the preceding route."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	game.queue_free();await frames(15)
	if xr:
		for t in [head,left,right]:XRServer.remove_tracker(t)
	print("SCALE_DESCENT_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)

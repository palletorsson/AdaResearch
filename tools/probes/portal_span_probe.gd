extends "res://tools/probes/void_polyhedra_probe.gd"

var floor_index := 11
var floor_y := -66.0

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_portals(false)
		game._set_enabled(false)
		await photograph("ramp-and-rings.png",Vector3(-20.5,(floor_y+3.0),4.3),Vector3(-7,(floor_y+2.9),.5),78)
		await photograph("inside-the-rings.png",Vector3(-16,(floor_y+2.65),.5),Vector3(31,(floor_y+3.2),.5),80)
		await photograph("ride-across.png",Vector3(5.4,(floor_y+3.1),3.8),Vector3(11,(floor_y+1.5),.5),83)
		await photograph("out-in-the-sky.png",Vector3(34,(floor_y+5.0),7),Vector3(21,(floor_y+2.6),.5),78)
		await cleanup(false)
	else:
		await exercise_span(false)
		await exercise_span(true)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real Godot desktop and synthetic XR physics. Physical headset comfort untested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrive_portals(use_xr: bool) -> void:
	await start(use_xr)
	for i in game.building.content.data.floors.size():
		if game.building.content.data.floors[i].map=="Primitives_Portals":floor_index=i
	floor_y=-6.0*floor_index
	game.checkpoint=floor_index
	game.place_player(Vector3(-18.5,(floor_y+0.06),4.4))
	await frames(60)
	var deadline := Time.get_ticks_msec()+20000
	while not game.building.content.pending.is_empty() and Time.get_ticks_msec()<deadline: await frames(1)
	await frames(10)

func exercise_span(use_xr: bool) -> void:
	await arrive_portals(use_xr)
	var tag := "XR: " if use_xr else "Desktop: "
	var span: Node3D=game.building.content.exhibits[str(floor_index)+"/sky-walk"].get_node("Artifact")
	var ferry: Node3D=span.get_node("MovingPlatform")
	var platform: Node3D=ferry.platform
	var portals: Node3D=span.get_node("RefinementPassage")
	check(tag+"source rings, F33 bridge and transport cube reused",portals.get_script().get_base_script().resource_path.ends_with("combine_portals.gd") and span.get_node("WestSpan1").scene_file_path.ends_with("bridge_path.tscn") and platform.get_script().get_base_script().resource_path.ends_with("transport_cube.gd"))
	check(tag+"twenty increasing rings",portals._portals.size()==20 and portals._portals[19].scale.x>portals._portals[0].scale.x and portals._portals[19].mesh.rings>portals._portals[0].mesh.rings)
	portals.reverse_discovery_order()
	check(tag+"reverse refinement preserves fitting and twenty rings",portals._portals.size()==20 and is_equal_approx(portals._portals[19].scale.x,.84) and portals._portals[0].mesh.rings>portals._portals[19].mesh.rings)
	portals.reverse_discovery_order()
	check(tag+"compact passage replaced; historical artifact retained",not game.building.content.exhibits[str(floor_index)+"/hall"].get_node("Artifact").has_node("RefinementPassage") and game.building.content.exhibits[str(floor_index)+"/hall"].get_node("Artifact").has_node("AchillesAndTortoise"))
	check(tag+"ramp climbs to one metre",await move_to(Vector3(-18.5,(floor_y+1.0),1)))
	for x in [-12,-6,0,6.95]:
		check(tag+"walk through rings to x="+str(x),await move_to(Vector3(x,(floor_y+1.0),.5),false,480))
	# Start at the near dock, then BOARD BY WALKING. No direct carry invocation.
	ferry.rebase(); await frames(2)
	check(tag+"walk onto real shuttle",await move_to(Vector3(8.45,(floor_y+1.0),.5)))
	check(tag+"boarding detects support",platform.carried_player==game.body)
	var rider_start: Vector3=game.body.global_position
	var eye_start: Vector3=game.camera.global_position
	var deck_start: Vector3=platform.global_position
	for step in range(600):
		await frames(1)
		if platform.ride_progress()>.999 and not platform.is_moving: break
	var travel: Vector3=platform.global_position-deck_start
	check(tag+"platform reaches far dock",platform.ride_progress()>.999)
	check(tag+"body carried once without drift",(game.body.global_position-rider_start-travel).length()<.08)
	check(tag+"headset/camera follows body",(game.camera.global_position-eye_start-travel).length()<.08)
	for step in range(900):
		await frames(1)
		if platform.ride_progress()<.001: break
	check(tag+"return trip carries body and camera back",platform.ride_progress()<.001 and (game.body.global_position-rider_start-(platform.global_position-deck_start)).length()<.08 and (game.camera.global_position-eye_start-(platform.global_position-deck_start)).length()<.08)
	for step in range(600):
		await frames(1)
		if platform.ride_progress()>.999 and not platform.is_moving: break
	check(tag+"walk off onto far dock",await move_to(Vector3(13.1,(floor_y+1.0),.5)))
	check(tag+"stepping off releases passenger",not is_instance_valid(platform.carried_player))
	for x in [18,23,26,31]:
		check(tag+"continue into sky to x="+str(x),await move_to(Vector3(x,(floor_y+1.0),.5),false,480))
	check(tag+"outside tower remains alive on real deck",game.deaths==0 and game.checkpoint==floor_index and is_equal_approx(game.health.get_health(),100))
	check(tag+"jump on outside deck",await move_to(Vector3(30.7,(floor_y+1.0),.5),true))
	# Space under/alongside the platform must not attach a rider.
	game.place_player(Vector3(platform.global_position.x,(floor_y+-2.1),.5)); await frames(1)
	check(tag+"below platform is not boarding",not platform._supports_body(game.body))
	game.place_player(Vector3(6.5,(floor_y+1.06),.5));await frames(15)
	ferry.rebase();await frames(2)
	var gap := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(11,(floor_y+2.0),.5),Vector3(11,(floor_y+0.0),.5),1))
	check(tag+"shaft gap has no invisible bridge",gap.is_empty())
	check(tag+"board again",await move_to(Vector3(8.45,(floor_y+1.0),.5)))
	press_jump();await frames(8);release_jump()
	check(tag+"jump detaches from shuttle",not is_instance_valid(platform.carried_player))
	game.place_player(Vector3(31,(floor_y+1.06),.5));await frames(20)
	var before := int(game.deaths)
	game.place_player(Vector3(31,(floor_y+1.0),4.5));await frames(2)
	check(tag+"outside supported route still kills",game.deaths==before+1 and game.recovering)
	await wait_for_recovery(before)
	check(tag+"death returns to Portals floor",game.checkpoint==floor_index and not game.recovering)
	# A copied moving part retains local travel after a quarter-turn in the editor.
	var copy: Node3D=load("res://commons/void/portal_span.tscn").instantiate()
	game.add_child(copy);copy.position=Vector3(0,(floor_y+0.0),5)
	copy.apply_grid_config({"only_parts":["MovingPlatform"],"parts":{"MovingPlatform":{"position":[1,0,0],"rotation":[0,90,0]}}})
	var mover: Node3D=copy.get_node("MovingPlatform/Transport")
	check(tag+"copy isolates moving part and rotates travel",copy.get_child_count()==1 and mover.target_position.is_equal_approx(Vector3(1,(floor_y+0.5),2)) and mover.initial_position.is_equal_approx(Vector3(1,(floor_y+0.5),5)))
	copy.queue_free()
	await cleanup(use_xr)

extends "res://tools/probes/void_lines_light_probe.gd"

var mode_name := ""

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	var modes := [true] if "--capture" in OS.get_cmdline_user_args() else [false,true]
	for mode in modes: await restored_encounters(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot. Captures use synthetic XR; the headless run covers both desktop and synthetic XR. Real grip/release, physics overlaps, tool-hit contracts and floor-aware recording. Not a physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func grab(body: Node3D, offset := Vector3.ZERO) -> void:
	if xr:
		var grip_at := body.global_position+offset
		hand_at(right,grip_at);await frames(2)
		# A specified surface contact needs the palm, rather than aim, origin.
		# Point handles otherwise keep their existing aim-relative grab offset.
		if offset != Vector3.ZERO:
			hand_at(right,grip_at+(grip_at-game.pickups[1].global_position))
		await frames(12)
		right.set_input("grip",1.0)
	else: game.body.desktop_pointer._grab_held(body)
	await frames(12)
	check(mode_name+"pickup "+body.name,body.is_picked_up())

func carry(where: Vector3) -> void:
	if xr: hand_at(right,where)
	else:
		game.camera.global_position=where+Vector3(0,0,1.5)
		game.camera.global_basis=Basis.IDENTITY
		game.body.desktop_pointer._hold_distance=1.5
	await frames(16)

func release() -> void:
	if xr: right.set_input("grip",0.0)
	else: game.body.desktop_pointer._drop_held()
	await frames(12)

func picture(file: String, at: Vector3, towards: Vector3, fov:=75.0) -> void:
	if xr and "--capture" in OS.get_cmdline_user_args(): await photograph(file,at,towards,fov)

func restored_encounters(use_xr: bool) -> void:
	await start(use_xr)
	mode_name="XR: " if xr else "Desktop: "
	game.checkpoint=3;game.place_player(Vector3(0,-17.94,6.9));await frames(50)
	var content: Node3D=game.building.content
	var deadline:=Time.get_ticks_msec()+20000
	while not content.pending.is_empty() and Time.get_ticks_msec()<deadline: await frames(2)
	check(mode_name+"floor finishes loading",content.pending.is_empty())
	var setting: Node3D=content.exhibits["3/setting_out"].get_node("Artifact")
	var gate: Node3D=setting.get_node("MeasurementRoom")
	var field: Node3D=setting.get_node("PairingPoints")
	var assembly: Node3D=content.exhibits["3/assembly"].get_node("Artifact")
	var direction: Node3D=content.exhibits["3/directions"].get_node("Artifact")
	var health: Node=get_first_node_in_group("void_health")
	check(mode_name+"twelve original pairing points remain",field.points.size()==12)
	game.place_player(field.global_position+Vector3(0,.06,2));await frames(15)
	check(mode_name+"three authored pairings begin connected",field.manager._connections.size()==3)
	var a:Node3D=field.points[2];var b:Node3D=field.points[3]
	await grab(b);await carry(a.global_position+Vector3(.18,0,0));await release()
	check(mode_name+"release near a point creates a connection",field.manager._connections.size()==4)
	await grab(b);await carry(a.global_position+Vector3(1.5,.6,.4));await release()
	check(mode_name+"connection survives separating the endpoints",field.manager._connections.size()==4 and b.global_position.distance_to(a.global_position)>1.5)
	check(mode_name+"free joining does not solve the separate gate",not gate.unlocked)
	await picture("joining-points.png",field.global_position+Vector3(0,1.65,2.1),field.global_position+Vector3(0,1.1,0),88)
	game.place_player(Vector3(0,-17.94,5.6));await frames(12)
	await grab(gate.point_b);await carry(gate.point_a.global_position+Vector3(.18,0,0));await frames(25)
	check(mode_name+"gate opens only through its own two points",gate.unlocked)
	await carry(gate.point_a.global_position+Vector3(1.2,0,0));await release();await frames(75)
	check(mode_name+"door rises and leaves the opening",gate.gate.position.y>2.75 and gate.line.current_line.visible)
	await picture("gate-and-line.png",Vector3(2,-16.35,7.5),Vector3(0,-16.7,3.7))
	var box:Node3D=gate # The entrance and black-box study now share one pair.
	game.place_player(box.global_position+Vector3(0,.06,-1));await frames(12)
	await grab(box.point_b)
	var p:Vector3=box.point_a.global_position
	await carry(p+Vector3(1,0,0));await create_timer(0.0).timeout
	check(mode_name+"black room measures one metre",box.measure_readout.text=="1.00 m")
	await carry(p+Vector3(0,1,0));await release();await create_timer(0.0).timeout
	check(mode_name+"changing direction can preserve length",box.measure_readout.text=="1.00 m")
	await picture("measuring-segment.png",box.global_position+Vector3(-.8,1.65,-1.3),box.global_position+Vector3(0,1.6,1.4),86)
	var plan:Node3D=setting.get_node("FloorPlanTable")
	var ruler:Node3D=setting.get_node("FullSizeRuler")
	check(mode_name+"1:10 plan and 1:1 ruler retain their units",is_equal_approx(plan.measured_length,20) and is_equal_approx(ruler.measured_length,2))
	await picture("rulers.png",Vector3(3.5,-14.8,-.8),Vector3(-.3,-17,-4.2),78)
	var all_bound:=true
	for item in content.data.floors[3].artifacts:
		if item.artifact in ["anamorphic_cross","health_cross"]:
			var artifact:Node3D=content.exhibits["3/"+item.id].get_node("Artifact")
			all_bound=all_bound and artifact.health_provider==health
	check(mode_name+"every imported X and plus uses Void health",all_bound)
	var danger:Node3D=content.exhibits["3/museum-point_lines-31-12"].get_node("Artifact")
	health.set_health(80)
	game.place_player(danger.global_position+Vector3(0,.06,0));await frames(45)
	check(mode_name+"entering original X actually lowers Void health",health.get_health()<80 and health.get_health()>0)
	game.place_player(Vector3(-15,-17.94,-5));await frames(8)
	var after_damage:float=health.get_health();await frames(50)
	check(mode_name+"leaving the X stops its damage",is_equal_approx(after_damage,health.get_health()))
	var plus:Node3D=content.exhibits["3/museum-point_lines-34-12"].get_node("Artifact")
	game.place_player(plus.global_position+Vector3(0,.06,0));await frames(20)
	check(mode_name+"entering original plus restores the same health",plus.is_spent() and health.get_health()>after_damage)
	var primary:Node3D=content.exhibits["3/museum-point_lines-37-2"].get_node("Artifact")
	game.place_player(Vector3(-16.5,-17.94,4.8));await frames(20);primary.clear_trail()
	var walked:bool=await move_to(Vector3(-15.2,-18,4.8))
	walked=walked and await move_to(Vector3(-15.2,-18,5.6))
	check(mode_name+"walking creates a sampled detour on Lines",walked and primary._trail_points.size()>10)
	var on_floor:=true
	for sample in primary._trail_points:
		on_floor=on_floor and absf(primary.to_global(sample).y-(-18+primary.position.y+.05))<.1
	check(mode_name+"recorded trace stays just above this floor",on_floor)
	check(mode_name+"only one recorder draws the walk",primary.active_last_frame and not direction.trace.active_last_frame and direction.trace._trail_points.is_empty())
	await picture("walk-and-trace.png",Vector3(-16.8,-15.8,6.3),Vector3(-15.7,-17.9,4.8),82)
	game.place_player(Vector3(14,-17.94,4.2));await frames(12)
	var rod:Node3D=assembly.get_node("DepthGridHorizontal1")
	var original:=rod.global_position
	# Grip between crossings, away from the neighboring vertical line.
	await grab(rod,Vector3(-.3,0,0));await carry(original+Vector3(-.3,0,.65));await release()
	check(mode_name+"six separate grid lines can open into depth",assembly.get_node("DepthGridVertical2")!=null and rod.global_position.distance_to(original)>.5)
	await picture("grid-into-depth.png",Vector3(14.1,-16.3,4.65),Vector3(14.1,-16.65,2.7),76)
	var router:Script=load("res://commons/interactables/artifact_reactions/router.gd")
	var reaction:Node=router.receiver(rod)
	check(mode_name+"movable rods have the original break/rebuild contract",reaction!=null and reaction.rebuild_seconds==8)
	check(mode_name+"fixed bridge and edge guards are never break targets",router.receiver(assembly.get_node("BridgeBoard"))==null and router.receiver(assembly.get_node("EdgeRail"))==null)
	var laser_holder:Node3D=content.exhibits["3/museum-point_lines-57-24"].get_node("Artifact")
	var laser:Node3D=laser_holder.get_node("LaserMeasure")
	check(mode_name+"museum laser burns; survey laser only measures",laser.burns and not setting.get_node("SurveyLaser/LaserMeasure").burns)
	# Exercise the actual laser's dwell callback with a delivered target hit.
	laser._burn(rod,laser.burn_seconds+.1)
	check(mode_name+"an unwielded laser does not destroy the study",not reaction.is_destroyed)
	await grab(laser_holder)
	laser._burn(rod,laser.burn_seconds+.1);await frames(3)
	check(mode_name+"held laser dwell breaks only the selected line",reaction.is_destroyed and not rod.visible and assembly.get_node("DepthGridVertical1").visible)
	await release();await frames(520)
	check(mode_name+"the line rebuilds and remains pickable",not reaction.is_destroyed and rod.visible and rod.enabled)
	var stick:Node3D=assembly.get_node("Hand_light")
	await grab(stick);await carry(Vector3(16.5,-16.7,.7))
	check(mode_name+"carried light stick still illuminates the tunnel",stick.get_node("InteractionLight").visible)
	await picture("light-stick-tunnel.png",Vector3(16.5,-16.35,-1.25),Vector3(16.5,-16.6,3.6),78)
	await release()
	game.place_player(game.spawn_for(2));await frames(30)
	check(mode_name+"leaving Lines stops and clears its local recorder",not primary.active_last_frame and primary._trail_points.is_empty())
	game.queue_free();await frames(8)
	if xr:
		for item in [head,left,right]: XRServer.remove_tracker(item)

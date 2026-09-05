extends SceneTree

## THE COMPOSED RIDES (2026-09-05, Palle: "add translate plus rotation in
## translation, and translation plus scale up and down the space like when we
## take the scale pill but a lot less"). A transport cube's cell may carry a
## #tail: #rot:<deg> turns the cube and its rider over the travel, #scale:<f>
## scales the SPACE to f at the far end (VR: XRServer.world_scale; desktop and
## the museum walker: the eye's height). Both follow the travel out and back.
##
##   1  the registry's parse keeps the head's grammar and reads the tail
##   2  a desktop-shaped rider on tc:4:z#rot:90#scale:1.3: at mid-ride the cube
##      and the rider have turned by the progress's share of 90 degrees, the
##      rider stands where the rotated offset says, and the eye is at 1.6 / f;
##      at the far end 90 degrees and 1.6 / 1.3; back at the start, unwound
##   3  a plain tc:4:z turns nothing and scales nothing (the negative)
##   4  a rider who steps off mid-ride is put back to size at once
##   5  a VR-shaped rider (under an XROrigin3D): the origin turns, and
##      XRServer.world_scale carries the space's scale, restored at the end
##
## Run:  godot --path . --xr-mode off --no-window --script res://commons/testing/probe_transport_ride_compose.gd

const EYE := 1.6
var _fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("  FAIL ", what)


func _cube(token: String, at: Vector3) -> Node3D:
	var n: Node3D = (load(UtilityRegistry.get_utility_scene_path("tc")) as PackedScene).instantiate() as Node3D
	var parsed: Dictionary = UtilityRegistry.parse_utility_cell(token)
	UtilityRegistry.apply_params(n, "tc", parsed["parameters"], {"cube_size": 1.0, "gutter": 0.0, "config": parsed["config"]})
	n.set("start_delay", 0.0)
	n.set("return_delay", 0.25)
	n.set("move_speed", 4.0)
	n.position = at
	return n


## a desktop-shaped rider: a body named Player with a Head (the eye's height) and a camera
func _rider(name: String) -> CharacterBody3D:
	var r := CharacterBody3D.new()
	r.name = name
	# a node whose name is taken by one still being freed is renamed by Godot to
	# something without "Player" in it - the group is how the cube knows a rider
	r.add_to_group("player_body")
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, EYE, 0)
	r.add_child(head)
	var cam := Camera3D.new()
	head.add_child(cam)
	return r


func _yaw_deg(n: Node3D) -> float:
	return rad_to_deg(n.rotation.y)


func _wrap(deg: float) -> float:
	return fposmod(deg + 180.0, 360.0) - 180.0


func _run() -> void:
	print("[probe_transport_ride_compose]")

	# 1. the parse
	var p1: Dictionary = UtilityRegistry.parse_utility_cell("tc:3:z#rot:90#scale:1.3")
	_check(String(p1["type"]) == "tc" and (p1["parameters"] as Array) == ["3", "z"] and String(p1["config"]["rot"]) == "90" and String(p1["config"]["scale"]) == "1.3",
		"1  tc:3:z#rot:90#scale:1.3 parses to head ['3','z'] and tail {rot, scale}")
	var t1: Dictionary = UtilityRegistry.transport_params(p1["parameters"], p1["config"])
	_check(absf(float(t1["rot"]) - 90.0) < 1e-6 and absf(float(t1["scale"]) - 1.3) < 1e-6 and (t1["direction"] as Vector3).is_equal_approx(Vector3(0, 0, 1)) and absf(float(t1["distance"]) - 3.0) < 1e-6,
		"1  transport_params keeps the head's rule and reads rot 90, scale 1.3")
	var p2: Dictionary = UtilityRegistry.parse_utility_cell("tc:3:z")
	var t2: Dictionary = UtilityRegistry.transport_params(p2["parameters"], p2["config"])
	_check((p2["config"] as Dictionary).is_empty() and is_zero_approx(float(t2["rot"])) and is_equal_approx(float(t2["scale"]), 1.0),
		"1  a cell without a tail composes nothing")
	var p3: Dictionary = UtilityRegistry.parse_utility_cell("tc:2:x#rot#scale")
	var t3: Dictionary = UtilityRegistry.transport_params(p3["parameters"], p3["config"])
	_check(absf(float(t3["rot"]) - 90.0) < 1e-6 and absf(float(t3["scale"]) - 1.3) < 1e-6, "1  bare #rot and #scale mean 90 degrees and x1.3")
	var p4: Dictionary = UtilityRegistry.parse_utility_cell("sc:3:-0.5:1:0#lift:0.4")
	_check((p4["parameters"] as Array).size() == 4 and String(p4["config"]["lift"]) == "0.4", "1  the museum's #lift rides the same tail (sc keeps its four parameters)")

	# 2. the desktop-shaped rider on the composed ride
	var cube := _cube("tc:4:z#rot:90#scale:1.3", Vector3(10, 0, 10))
	var rider := _rider("Player")
	root.add_child(cube)
	root.add_child(rider)
	var off0 := Vector3(0.3, 1.0, 0.2)
	rider.global_position = cube.global_position + off0
	var head: Node3D = rider.get_node("Head")
	await process_frame
	await process_frame
	cube.call("_on_detection_area_body_entered", rider)
	var mid_checked := false
	var far_checked := false
	var frames := 0
	while frames < 900:
		await process_frame
		frames += 1
		var prog: float = float(cube.call("ride_progress"))
		if not mid_checked and prog > 0.35 and prog < 0.75 and bool(cube.get("is_moving")) and not bool(cube.get("is_returning")):
			mid_checked = true
			var want_yaw: float = 90.0 * prog
			var f: float = lerpf(1.0, 1.3, prog)
			_check(absf(_yaw_deg(cube) - want_yaw) < 1.5, "2  mid-ride (progress %.2f): the cube has turned %.1f of %.1f degrees" % [prog, _yaw_deg(cube), want_yaw])
			_check(absf(_wrap(_yaw_deg(rider)) - want_yaw) < 1.5, "2  the rider has turned with it (%.1f degrees)" % _yaw_deg(rider))
			var want_off: Vector3 = off0.rotated(Vector3.UP, deg_to_rad(want_yaw))
			var got_off: Vector3 = rider.global_position - cube.global_position
			_check(got_off.is_equal_approx(want_off) or got_off.distance_to(want_off) < 0.05, "2  the rider stands where the turned offset says (%s vs %s)" % [str(got_off), str(want_off)])
			_check(absf(head.position.y - EYE / f) < 0.02, "2  the eye is at %.3f = 1.6 / %.3f: the space is x%.2f" % [head.position.y, f, f])
		if not far_checked and not bool(cube.get("is_moving")) and cube.global_position.distance_to(cube.get("target_position")) < 0.01:
			far_checked = true
			_check(absf(_yaw_deg(cube) - 90.0) < 0.5 and absf(_wrap(_yaw_deg(rider)) - 90.0) < 0.5, "2  at the far end: cube %.1f, rider %.1f degrees" % [_yaw_deg(cube), _yaw_deg(rider)])
			_check(absf(head.position.y - EYE / 1.3) < 0.01, "2  and the eye at %.3f = 1.6 / 1.3" % head.position.y)
		if far_checked and not bool(cube.get("is_moving")) and cube.global_position.distance_to(cube.get("initial_position")) < 0.01:
			break
	_check(mid_checked and far_checked, "2  the ride was observed mid-way and at the far end (%d frames)" % frames)
	_check(absf(_yaw_deg(cube)) < 0.5 and absf(_wrap(_yaw_deg(rider))) < 0.5, "2  back at the start, unwound: cube %.2f, rider %.2f degrees" % [_yaw_deg(cube), _yaw_deg(rider)])
	_check(absf(head.position.y - EYE) < 0.01, "2  and the eye back at %.2f" % head.position.y)
	cube.queue_free()
	rider.queue_free()

	# 3. the negative: a plain ride
	var plain := _cube("tc:4:z", Vector3(20, 0, 10))
	var r2 := _rider("Player3")
	root.add_child(plain)
	root.add_child(r2)
	r2.global_position = plain.global_position + off0
	var h2: Node3D = r2.get_node("Head")
	await process_frame
	await process_frame
	plain.call("_on_detection_area_body_entered", r2)
	print("     plain ride after the call: moving %s, waiting %s, initial %s, at %s, carried %s, rider name %s" % [
		str(plain.get("is_moving")), str(plain.get("waiting_to_start")), str(plain.get("initial_position")), str(plain.global_position),
		str(plain.get("carried_player")), r2.name])
	var seen := false
	var max_prog := 0.0
	for i in range(300):
		await process_frame
		var prog: float = float(plain.call("ride_progress"))
		max_prog = maxf(max_prog, prog)
		if prog > 0.4 and prog < 0.7:
			seen = true
			break
	print("     plain ride: seen mid %s, max progress %.2f, moving %s, cube yaw %.4f, rider yaw %.4f, eye %.4f" % [
		str(seen), max_prog, str(plain.get("is_moving")), _yaw_deg(plain), _yaw_deg(r2), h2.position.y])
	_check(seen and absf(_yaw_deg(plain)) < 1e-4 and absf(_yaw_deg(r2)) < 1e-4 and absf(h2.position.y - EYE) < 1e-6, "3  a plain tc:4:z turns nothing and scales nothing mid-ride")
	plain.queue_free()
	r2.queue_free()

	# 4. stepping off mid-ride
	var c3 := _cube("tc:4:z#scale:1.3", Vector3(30, 0, 10))
	var r3 := _rider("Player4")
	root.add_child(c3)
	root.add_child(r3)
	r3.global_position = c3.global_position + off0
	var h3: Node3D = r3.get_node("Head")
	await process_frame
	c3.call("_on_detection_area_body_entered", r3)
	var scaled := false
	for i in range(300):
		await process_frame
		var prog: float = float(c3.call("ride_progress"))
		if prog > 0.4:
			scaled = absf(h3.position.y - EYE) > 0.05
			break
	c3.call("_on_detection_area_body_exited", r3)
	_check(scaled and absf(h3.position.y - EYE) < 1e-6, "4  mid-ride the eye had moved; stepping off put it back to %.2f at once" % h3.position.y)
	c3.queue_free()
	r3.queue_free()

	# 5. the VR-shaped rider: the origin turns, world_scale carries the space
	var base_ws: float = XRServer.world_scale
	var origin := XROrigin3D.new()
	var body := CharacterBody3D.new()
	body.name = "PlayerBody"
	origin.add_child(body)
	var c5 := _cube("tc:4:z#rot:90#scale:1.3", Vector3(40, 0, 10))
	root.add_child(c5)
	root.add_child(origin)
	origin.global_position = c5.global_position + Vector3(0.2, 1.0, 0.1)
	await process_frame
	c5.call("_on_detection_area_body_entered", body)
	var vr_mid := false
	var vr_end := false
	for i in range(900):
		await process_frame
		var prog: float = float(c5.call("ride_progress"))
		if not vr_mid and prog > 0.35 and prog < 0.75 and not bool(c5.get("is_returning")):
			vr_mid = true
			var f: float = lerpf(1.0, 1.3, prog)
			_check(absf(XRServer.world_scale - base_ws / f) < 0.01, "5  mid-ride world_scale %.3f = %.2f / %.3f (the space x%.2f)" % [XRServer.world_scale, base_ws, f, f])
			_check(absf(_wrap(_yaw_deg(origin)) - 90.0 * prog) < 1.5, "5  the origin has turned %.1f degrees with the cube" % _yaw_deg(origin))
		if vr_mid and not bool(c5.get("is_moving")) and c5.global_position.distance_to(c5.get("initial_position")) < 0.01:
			vr_end = true
			break
	_check(vr_mid and vr_end and absf(XRServer.world_scale - base_ws) < 1e-6, "5  back at the start world_scale is %.3f again" % XRServer.world_scale)
	c5.queue_free()
	origin.queue_free()
	XRServer.world_scale = base_ws

	print("[probe_transport_ride_compose] %s (%d failures)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	quit(0 if _fails == 0 else 1)

extends SceneTree
## DOES THE MOTION BITE, AND IS IT OFF UNTIL A MAP ASKS? (2026-09-06, Palle:
## "one pick up cube up down oscillation one cube rotate, one cube scale
## oscillation, then combine them, result this is how we a mario pick up cube")
##
## pick_up_cube has always composed two transformations forever - rotate_y is a
## rotation, the sine on y a translation - and gained the third today. The whole
## change is worthless if it is not measurable and dangerous if it is not off by
## default: 186 placements across 64 maps carry no config at all.
##
## Six cubes, each given the config a map cell would give it, watched for half a
## second, and asked what actually moved.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_pickup_motion.gd

const SCENE := "res://commons/scenes/mapobjects/pick_up_cube.tscn"

var _fails: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _watch(label: String, cfg: Dictionary) -> Dictionary:
	var node: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	for k in cfg:
		node.set_meta("config_%s" % k, cfg[k])
	node.position = Vector3(0, 0, 0)
	get_root().add_child(node)
	await create_timer(0.05).timeout
	var mesh: MeshInstance3D = node.find_child("CubeBaseMesh", true, false) as MeshInstance3D
	var y0: float = node.global_position.y
	var yaw0: float = node.rotation.y
	var s0: float = mesh.scale.x if mesh != null else 1.0
	var y_lo := y0
	var y_hi := y0
	var s_lo := s0
	var s_hi := s0
	for _i in range(30):
		await create_timer(1.0 / 60.0).timeout
		y_lo = minf(y_lo, node.global_position.y)
		y_hi = maxf(y_hi, node.global_position.y)
		if mesh != null:
			s_lo = minf(s_lo, mesh.scale.x)
			s_hi = maxf(s_hi, mesh.scale.x)
	var out := {"bob": y_hi - y_lo, "turn": absf(node.rotation.y - yaw0), "swell": s_hi - s_lo}
	node.queue_free()
	return out


func _say(label: String, got: Dictionary, want_bob: bool, want_turn: bool, want_swell: bool) -> void:
	var ok: bool = (float(got["bob"]) > 0.02) == want_bob \
		and (float(got["turn"]) > 0.02) == want_turn \
		and (float(got["swell"]) > 0.02) == want_swell
	if not ok:
		_fails += 1
	print("  %-34s bob %.3f m  turn %.3f rad  swell %.3f   %s" % [
		label, got["bob"], got["turn"], got["swell"], "ok" if ok else "FAIL"])


func _run() -> void:
	print("THE PICK-UP CUBE'S THREE MOTIONS — what moves, measured over half a second\n")
	# the shipped default: two of the three, and no third
	_say("no config (186 placements)", await _watch("idle", {}), true, true, false)
	_say("#motion:slide", await _watch("slide", {"motion": "slide"}), true, false, false)
	_say("#motion:turn", await _watch("turn", {"motion": "turn"}), false, true, false)
	_say("#motion:swell", await _watch("swell", {"motion": "swell"}), false, false, true)
	_say("#motion:all", await _watch("all", {"motion": "all"}), true, true, true)
	_say("#motion:still", await _watch("still", {"motion": "still"}), false, false, false)
	# a demonstration keeps its place
	var demo: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	demo.set_meta("config_hold", "demo")
	get_root().add_child(demo)
	await create_timer(0.1).timeout
	var area: Area3D = demo.get_node_or_null("DetectionArea") as Area3D
	var armed: bool = area != null and area.monitoring
	if demo.has_method("collect"):
		demo.call("collect")
	await create_timer(0.1).timeout
	var kept: bool = is_instance_valid(demo) and not bool(demo.get("has_been_collected"))
	if armed or not kept:
		_fails += 1
	print("  %-34s detection armed %s, survived collect() %s   %s" % [
		"#hold:demo", str(armed), str(kept), "FAIL" if (armed or not kept) else "ok"])
	print("\n%s" % ("ALL OK" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)

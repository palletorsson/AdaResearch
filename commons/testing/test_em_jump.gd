extends SceneTree
## Jump + double jump on the desktop walker: SPACE lifts, a second SPACE in
## the air lifts again, a third does nothing, and the walker LANDS on y = 0
## exactly (never below, never hovering).
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_jump.gd
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var fails: Array[String] = []
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var m: Node3D = ps.instantiate() as Node3D
	m.set("_plan_path", "")
	m.set("_em_segments_cap", 1) if m.get("_em_segments_cap") != null else null
	get_root().add_child(m)
	await create_timer(0.6).timeout
	var pl: CharacterBody3D = m.get("_player")
	if pl == null:
		print("EM JUMP: SKIP — no desktop walker (VR?)"); quit(0); return
	var y0: float = pl.position.y
	# first jump
	m.set("_jump_pressed", true)
	var peak := 0.0
	for i in range(20):
		await physics_frame
		peak = maxf(peak, pl.position.y)
	if peak < 0.5:
		fails.append("first jump peaked at %.2f m (< 0.5)" % peak)
	# second jump mid-air
	m.set("_jump_pressed", true)
	var peak2 := peak
	for i in range(25):
		await physics_frame
		peak2 = maxf(peak2, pl.position.y)
	if peak2 <= peak + 0.2:
		fails.append("double jump did not lift again (peak %.2f -> %.2f)" % [peak, peak2])
	# third press in the air must be ignored
	var before3: float = pl.position.y
	m.set("_jump_pressed", true)
	await physics_frame
	await physics_frame
	if float(m.get("_jumps_left")) > 0:
		fails.append("a third jump was allowed in the air")
	# land
	for i in range(120):
		await physics_frame
		if pl.position.y <= 0.0 and float(m.get("_vy")) == 0.0:
			break
	if absf(pl.position.y - y0) > 0.001:
		fails.append("did not land on the deck: y %.3f" % pl.position.y)
	if int(m.get("_jumps_left")) != 2:
		fails.append("jumps not restored on landing (%d)" % int(m.get("_jumps_left")))
	get_root().remove_child(m); m.queue_free()
	if fails.is_empty():
		print("EM JUMP: PASS — jump %.2f m, double %.2f m, third ignored, landed on 0" % [peak, peak2])
	else:
		print("EM JUMP: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)

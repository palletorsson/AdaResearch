extends SceneTree
## THE SPIDER, DEPLOYED (2026-08-26, Palle: "all black spider 3 look good! use
## that as a start and deploy it in to the game"). Asserts the four things that
## make it deployed rather than merely written:
##   1. the shipped DEFAULTS are variant 3 — graphite body, brass joints
##   2. a map token resolves and the artifact builds, walking
##   3. #k:v config reaches it (scale, accent)
##   4. the gestation's SIXTH rung yields it where the walk has learned forces
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var fails: Array = []; var notes: Array = []
	var st := Node3D.new(); get_root().add_child(st)
	var w := CharacterBody3D.new(); w.name = "Walker"; w.add_to_group("em_walker")
	st.add_child(w); w.global_position = Vector3(0, 0, -6)

	# 1 + 2. the artifact, at its shipped defaults
	var c: Node3D = (load("res://commons/hazards/head_crab/head_crab.tscn") as PackedScene).instantiate() as Node3D
	st.add_child(c)
	await create_timer(1.2).timeout
	if absf(float(c.get("crab_scale")) - 0.15) > 0.001 or absf(float(c.get("ride_local")) + 1.2) > 0.001:
		fails.append("defaults are not variant 3 (scale %s ride %s)" % [str(c.get("crab_scale")), str(c.get("ride_local"))])
	else:
		notes.append("ships as variant 3: scale 0.15, ride -1.20, stance 1.25")
	if not bool(c.get("finish_on")):
		fails.append("the manufactured finish is off by default")
	else:
		var fa: Color = c.get("finish_accent")
		notes.append("finish on: graphite body, brass joints (%.2f %.2f %.2f)" % [fa.r, fa.g, fa.b])
	var feet: Array = c.get("_feet")
	var nulls := 0
	for f in feet:
		if f == null or not is_instance_valid(f): nulls += 1
	if nulls > 0:
		fails.append("%d foot target(s) null" % nulls)
	var p0: Vector3 = c.global_position
	var b0: Array = []
	for f in feet: b0.append((f as Node3D).global_position)
	await create_timer(2.0).timeout
	var moved := 0
	for i in range(feet.size()):
		if (feet[i] as Node3D).global_position.distance_to(b0[i]) > 0.01: moved += 1
	var travelled: float = c.global_position.distance_to(p0)
	if moved < 2 or travelled < 0.2:
		fails.append("it did not walk (%d feet moved, %.2f m)" % [moved, travelled])
	else:
		notes.append("it walks: %d of 4 feet stepped, %.2f m travelled" % [moved, travelled])

	# 3. a map token can tune it
	var c2: Node3D = (load("res://commons/hazards/head_crab/head_crab.tscn") as PackedScene).instantiate() as Node3D
	c2.call("apply_grid_config", {"scale": "0.11", "accent": "#7fd8cf", "speed": "1.4"})
	st.add_child(c2); c2.global_position = Vector3(4, 0, 0)
	await create_timer(0.6).timeout
	if absf(float(c2.get("crab_scale")) - 0.11) > 0.001:
		fails.append("#scale did not reach it")
	elif absf(float(c2.get("chase_speed")) - 1.4) > 0.001:
		fails.append("#speed did not reach it")
	else:
		notes.append("map tokens tune it (#scale #speed #accent)")

	# 4. the sixth rung of the gestation
	var host := Node3D.new(); host.set_meta("em_pearl", "vfm 08 arena")
	st.add_child(host); host.position = Vector3(-6, 0, 0)
	var egg: Node3D = (load("res://commons/artifacts/dark_sphere/dark_sphere.tscn") as PackedScene).instantiate() as Node3D
	host.add_child(egg)
	await create_timer(0.8).timeout
	if String(egg.call("_gest_stage")) != "spider":
		fails.append("a forces place derived as '%s', not spider" % String(egg.call("_gest_stage")))
	egg.call("hit_by_catalyst_mode", Color(0.72, 0.56, 0.28), "transformation")
	await create_timer(0.9).timeout
	var yielded: Node = host.find_child("YieldSpider", true, false)
	if yielded == null:
		fails.append("the forces egg yielded no spider")
	else:
		notes.append("the sixth rung yields the spider — the ladder reaches its end")

	var r := "HEAD CRAB DEPLOY PROBE\n"
	for n in notes: r += "  ok   %s\n" % n
	for f2 in fails: r += "  FAIL %s\n" % f2
	r += "%d fail(s)\n" % fails.size()
	var fh := FileAccess.open("res://ada_run/head_crab_deploy.txt", FileAccess.WRITE)
	fh.store_string(r); fh.close(); print(r)
	quit(1 if not fails.is_empty() else 0)

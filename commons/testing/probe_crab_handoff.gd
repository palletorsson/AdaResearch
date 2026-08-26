extends SceneTree
## THE HANDOFF, TESTED BEFORE ANY POSTURE IS JUDGED. Two design agents found
## that head_crab addressed the rig's scriptless ROOT rather than its Body, so
## the feet were null, the csg params were dropped in silence and the rig kept
## walking on its own metre-scale defaults. Assert all three are closed.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var fails: Array = []; var notes: Array = []
	var st := Node3D.new(); get_root().add_child(st)
	var c: Node3D = (load("res://commons/hazards/head_crab/head_crab.tscn") as PackedScene).instantiate() as Node3D
	c.set("csg_params", {"leg_shaft_radius": 0.055, "creature_atom_count": 9})
	st.add_child(c)
	await create_timer(1.0).timeout
	var feet: Array = c.get("_feet")
	var nulls := 0
	for f in feet:
		if f == null or not is_instance_valid(f): nulls += 1
	if feet.size() != 4 or nulls > 0:
		fails.append("%d of %d foot targets are null — the gait drives nothing" % [nulls, feet.size()])
	else:
		notes.append("all four foot targets resolved")
	var body: Node = c.get("_body")
	if body == null:
		fails.append("no Body node found")
	else:
		if body.is_processing():
			fails.append("the rig's own _process is STILL running — two gaits fight")
		else:
			notes.append("the rig's own gait is stopped (%s)" % str(body.name))
		if absf(float(body.get("leg_shaft_radius")) - 0.055) > 0.0001:
			fails.append("csg params did not reach the body (leg_shaft_radius %s)" % str(body.get("leg_shaft_radius")))
		else:
			notes.append("csg params reach the body that reads them")
	# and the feet MOVE when the gait says step
	var before: Array = []
	for f in feet: before.append((f as Node3D).global_position)
	await create_timer(1.6).timeout
	var moved := 0
	for i in range(feet.size()):
		if (feet[i] as Node3D).global_position.distance_to(before[i]) > 0.01: moved += 1
	if moved == 0:
		fails.append("no foot target moved in 1.6 s — the gait is inert")
	else:
		notes.append("%d of 4 foot targets moved — the gait drives them" % moved)
	var r := "CRAB HANDOFF PROBE\n"
	for n in notes: r += "  ok   %s\n" % n
	for f2 in fails: r += "  FAIL %s\n" % f2
	r += "%d fail(s)\n" % fails.size()
	var fh := FileAccess.open("res://ada_run/crab_handoff.txt", FileAccess.WRITE)
	fh.store_string(r); fh.close(); print(r)
	quit(1 if not fails.is_empty() else 0)

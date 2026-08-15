extends SceneTree
## Rung 3 assembler gate: a negotiated bridge court preserves one continuous
## route while exposing exactly the three-metre apron around the precinct.
##
##   godot --headless --path . --xr-mode off --script \
##     res://commons/testing/test_em_bridge_courts.gd


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_plan_path", "")
	get_root().add_child(inst)
	await create_timer(0.4).timeout

	var seg := Node3D.new()
	seg.name = "BridgeCourtProbe"
	inst.add_child(seg)
	var solid := StaticBody3D.new()
	seg.add_child(solid)
	var walk: Dictionary = inst.get("_walk_cells")
	walk.clear()
	var depth: int = int(inst.call("_build_courtyard", seg, solid,
		15, 8, 0, [{
			"token": "bridge_probe", "scene": "", "court": [24, 24],
			"rotation": 0.0, "venue": "courtyard", "access": "bridge",
		}], Color(0.8, 0.8, 0.8), null))

	if depth != 24:
		fails.append("bridge court returned depth %d, expected 24" % depth)
	# The protected route is three walkable cells wide and continuous end to end.
	for z in range(12, 36):
		for x in range(1, 4):
			if not walk.has(Vector2i(x, z)):
				fails.append("bridge route missing [%d,%d]" % [x, z])
				break
	# The court opens from the bridge only at its four-metre midspan gate.
	if walk.has(Vector2i(4, 14)):
		fails.append("court advertised through the divider rail away from its gate")
	if not walk.has(Vector2i(4, 24)):
		fails.append("court gate does not connect the bridge to the apron")
	# body = court minus the negotiated three-metre apron. Its central footprint
	# is deliberately not a walk claim; the surrounding ring is.
	if walk.has(Vector2i(16, 24)):
		fails.append("precinct core was advertised as walkable floor")
	for cell in [Vector2i(6, 24), Vector2i(25, 24),
			Vector2i(16, 14), Vector2i(16, 33)]:
		if not walk.has(cell):
			fails.append("three-metre court apron missing %s" % str(cell))
	# No negotiated bridge means the original courtyard topology is untouched.
	walk.clear()
	var seg2 := Node3D.new()
	inst.add_child(seg2)
	var solid2 := StaticBody3D.new()
	seg2.add_child(solid2)
	var old_depth: int = int(inst.call("_build_courtyard", seg2, solid2,
		15, 8, 0, [{
			"token": "centred_probe", "scene": "", "court": [24, 9],
			"rotation": 0.0, "venue": "courtyard", "access": "",
		}], Color(0.8, 0.8, 0.8), null))
	if old_depth != 9:
		fails.append("original courtyard depth changed")
	if walk.has(Vector2i(16, 12)):
		fails.append("original court widened beyond the 15-cell corridor")

	get_root().remove_child(inst)
	inst.queue_free()
	if fails.is_empty():
		print("EM BRIDGE COURTS: PASS — protected route, four-metre gate, three-metre apron, original court unchanged")
	else:
		print("EM BRIDGE COURTS: FAIL %d" % fails.size())
		for f in fails:
			print("  - " + f)
	quit(0 if fails.is_empty() else 1)

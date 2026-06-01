extends SceneTree

## Reproduce the REAL GridSystem sequence exactly (per lab_room._ready
## comment): set config meta BEFORE add_child, AND call apply_grid_config()
## deferred AFTER _ready. That double-builds the room — _ready builds the
## door+scanner once, then apply_grid_config clears + rebuilds them. If the
## rebuilt scanner auto-connects to the OLD (dying) door sensor, the grant
## fires into a freed node and the door never opens. This is the in-game
## "scanner works but door won't open" path that the other tests miss.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/test_lab_realgrid.gd

const LAB_ROOM := "res://commons/artifacts/lab_room/lab_room.tscn"
const LAB_JSON := "res://commons/labs/point_one.lab.json"
const HAND := "res://addons/godot-xr-tools/hands/scenes/collision/collision_hand.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _phys(n: int) -> void:
	for i in range(n):
		await physics_frame


func _find_by_signal(node: Node, sig: String) -> Node:
	if node.has_signal(sig):
		return node
	for c in node.get_children():
		var f := _find_by_signal(c, sig)
		if f != null:
			return f
	return null


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	# 1. meta BEFORE add_child (grid injects config first) → _ready builds.
	var lab: Node3D = load(LAB_ROOM).instantiate()
	lab.set_meta("config_mounted_lab_json", LAB_JSON)
	world.add_child(lab)
	# 2. apply_grid_config deferred AFTER _ready (grid's second pass) → the
	#    clear+rebuild that creates the stale-door race.
	lab.call_deferred("apply_grid_config", {"mounted_lab_json": LAB_JSON})

	await _phys(160)

	var doors: Array = get_nodes_in_group("lab_door_sensors")
	print("[real] doors in group=%d (expect exactly 1; >1 = stale leak)" % doors.size())
	var scanner: Node = _find_by_signal(lab, "palm_scanned")
	if scanner == null or doors.is_empty():
		print("[real] RESULT: FAIL — scanner=%s doors=%d" % [scanner != null, doors.size()])
		quit(1); return

	# The scanner must be wired to a LIVE door that is still in the tree.
	var live_door: Node = null
	for d in doors:
		if is_instance_valid(d) and scanner.palm_scanned.is_connected(Callable(d, "_open_door")):
			live_door = d
	print("[real] scanner wired to a live door=%s" % (live_door != null))
	if live_door == null:
		print("[real] RESULT: FAIL — scanner wired to no live door (stale-node race)")
		quit(1); return

	# Drive the real hand onto the plate; the door must physically open.
	var area: Area3D = scanner.find_child("ScanArea", true, false)
	var cs: CollisionShape3D = null
	for c in area.get_children():
		if c is CollisionShape3D: cs = c; break
	var target: Vector3 = cs.global_position if cs else area.global_position
	var hand: Node3D = load(HAND).instantiate()
	world.add_child(hand)
	hand.set_physics_process(false); hand.set_process(false)
	if "sync_to_physics" in hand: hand.sync_to_physics = false
	hand.global_position = target
	await _phys(80)

	var panel: Node3D = live_door.get("left_panel")
	var opened: bool = bool(live_door.get("_open"))
	var moved: bool = panel != null and absf(panel.position.x) > 0.5
	print("[real] hand on plate -> open=%s panel_x=%s" %
		[opened, (panel.position.x if panel else "n/a")])
	var ok: bool = opened and moved
	print("[real] RESULT: %s" % ("PASS — door opens on the real grid path" if ok else "FAIL — door did NOT open (matches in-game)"))
	quit(0 if ok else 1)

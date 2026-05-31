extends SceneTree

## Replicates the REAL map load path (GridSystem): add the lab_room to the
## tree FIRST (so _ready runs with no config), THEN call apply_grid_config()
## — as opposed to test_lab_door_chain.gd which set the meta before add_child.
## This is the only path the in-game Point One scanner actually goes through,
## so if the scanner is dead in VR but fine in the other test, the bug is here.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/test_lab_gridpath.gd

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
		var found := _find_by_signal(c, sig)
		if found != null:
			return found
	return null


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	# --- GridSystem path: instantiate, ADD FIRST (so _ready runs with no
	# config and builds a default/empty lab), THEN apply_grid_config. ---
	var lab: Node3D = load(LAB_ROOM).instantiate()
	world.add_child(lab)
	await _phys(5)
	print("[grid] after bare _ready: props? scanner=%s" %
		[_find_by_signal(lab, "palm_scanned") != null])
	lab.apply_grid_config({"mounted_lab_json": LAB_JSON})

	await _phys(160)

	var doors: Array = get_nodes_in_group("lab_door_sensors")
	var scanner: Node = _find_by_signal(lab, "palm_scanned")
	print("[grid] doors=%d  scanner=%s  scan_active=%s" %
		[doors.size(), scanner != null,
		 scanner.get("scan_active") if scanner else "n/a"])

	if scanner == null:
		print("[grid] RESULT: FAIL — scanner never instantiated via grid path")
		quit(1)
		return

	var area: Area3D = scanner.find_child("ScanArea", true, false)
	print("[grid] ScanArea present: %s" % (area != null))
	if area == null:
		print("[grid] RESULT: FAIL — ScanArea missing on grid path (the VR bug)")
		quit(1)
		return

	if doors.is_empty():
		print("[grid] RESULT: FAIL — no door sensor to open")
		quit(1)
		return

	var door: Node = doors[0]
	var wired: bool = scanner.palm_scanned.is_connected(Callable(door, "_open_door"))

	var box_cs: CollisionShape3D = null
	for c in area.get_children():
		if c is CollisionShape3D:
			box_cs = c
			break
	var target: Vector3 = box_cs.global_position if box_cs != null else area.global_position

	var hand: Node3D = load(HAND).instantiate()
	world.add_child(hand)
	hand.set_physics_process(false)
	hand.set_process(false)
	if "sync_to_physics" in hand:
		hand.sync_to_physics = false
	hand.global_position = target
	await _phys(80)   # allow the ~0.8s scan dwell to complete before grant

	var opened: bool = bool(door.get("_open"))
	print("[grid] wired=%s  hand-on-plate door-open=%s" % [wired, opened])
	var ok: bool = wired and opened
	print("[grid] RESULT: %s" %
		("PASS — grid path works" if ok else "FAIL — grid path broken (matches VR)"))
	quit(0 if ok else 1)

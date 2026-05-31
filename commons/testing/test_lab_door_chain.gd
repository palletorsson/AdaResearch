extends SceneTree

## End-to-end: build the REAL Point One lab (lab_room artifact + its
## mounted_lab_json), then check the whole palm-scanner -> door chain that
## a VR player depends on:
##   1. Did the lab build a LabDoorSensor (group "lab_door_sensors")?
##   2. Did the palm_scanner instantiate, and is it scan_active?
##   3. Did the scanner auto-wire palm_scanned -> door._open_door?
##   4. Does the real collision hand, placed on the scan plate, open it?
##
## NOTE: this script IS the SceneTree, so call group/frame helpers on self
## (no get_tree()).
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/test_lab_door_chain.gd

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

	# Build the lab exactly as the map does: lab_room artifact configured
	# with mounted_lab_json. Set the meta BEFORE add_child so the artifact's
	# _ready() reads it and builds the room + door + loads props in one pass.
	var lab: Node3D = load(LAB_ROOM).instantiate()
	lab.set_meta("config_mounted_lab_json", LAB_JSON)
	world.add_child(lab)

	# Generous settle — lab_loader instantiates props (deferred), colliders,
	# the scanner's deferred auto-connect (which now retries for the door).
	await _phys(140)

	var doors: Array = get_nodes_in_group("lab_door_sensors")
	print("[chain] 1. lab_door_sensors in group: %d" % doors.size())

	var scanner: Node = _find_by_signal(lab, "palm_scanned")
	print("[chain] 2. palm_scanner found: %s   scan_active=%s" %
		[scanner != null, scanner.get("scan_active") if scanner else "n/a"])

	if scanner == null or doors.is_empty():
		print("[chain] CHAIN BROKEN before wiring (door=%d scanner=%s)" %
			[doors.size(), scanner != null])
		quit(1)
		return

	var door: Node = doors[0]
	var wired: bool = scanner.palm_scanned.is_connected(Callable(door, "_open_door"))
	print("[chain] 3. scanner.palm_scanned -> door._open_door wired: %s" % wired)

	var area: Area3D = scanner.find_child("ScanArea", true, false)
	if area == null:
		print("[chain] 4. NO ScanArea on scanner — detection volume missing!")
		quit(1)
		return
	print("[chain] 4. ScanArea mask=%d  world-pos=%s" %
		[area.collision_mask, area.global_position])

	# 5. Drop the real collision hand on the scan plate (frozen so our
	#    placement is authoritative, as the tracked controller would be).
	# The detection box is offset in FRONT of the plate, and the lab mounts
	# the scanner rotated 180°, so the Area node's origin is not the box
	# centre — aim at the CollisionShape's world centre (where a VR player's
	# hand actually meets the glowing plate).
	var box_cs: CollisionShape3D = null
	for c in area.get_children():
		if c is CollisionShape3D:
			box_cs = c
			break
	var target_pos: Vector3 = box_cs.global_position if box_cs != null else area.global_position
	print("[chain] 4b. scan-box centre world-pos=%s" % target_pos)

	var hand: Node3D = load(HAND).instantiate()
	world.add_child(hand)
	hand.set_physics_process(false)
	hand.set_process(false)
	# AnimatableBody3D syncs its physics-server transform inside
	# _physics_process; with that frozen we must turn off sync_to_physics so
	# a direct global_position teleport actually reaches the physics server
	# (in real VR _physics_process is on and the controller does this).
	if "sync_to_physics" in hand:
		hand.sync_to_physics = false
	hand.global_position = target_pos
	await _phys(80)   # allow the ~0.8s scan dwell to complete before grant

	var opened: bool = bool(door.get("_open"))
	print("[chain] 5. hand on plate -> door open: %s   (scanner _scanning=%s)" %
		[opened, scanner.get("_scanning")])

	var ok: bool = wired and opened
	print("\n[chain] RESULT: %s" %
		("PASS — full VR chain works in the real lab" if ok else "FAIL — see step above"))
	quit(0 if ok else 1)

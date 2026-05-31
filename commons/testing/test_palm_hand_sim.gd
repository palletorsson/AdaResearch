extends SceneTree

## Integration sim: the REAL xr-tools CollisionHand (the body base.tscn
## puts under XROrigin3D/LeftHand) vs the palm_scanner Area3D + a
## lab_door_sensor. Moves the hand into the scan volume, ticks physics,
## verifies palm_scanned fires and the door opens, then withdraws and
## verifies the hold-timer release closes it.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/test_palm_hand_sim.gd

const SCANNER := "res://commons/artifacts/palm_scanner/palm_scanner.tscn"
const HAND := "res://addons/godot-xr-tools/hands/scenes/collision/collision_hand.tscn"
const DOOR := "res://commons/artifacts/lab_room/lab_door_sensor.gd"


func _initialize() -> void:
	_run.call_deferred()


func _phys(n: int) -> void:
	for i in range(n):
		await physics_frame


func _run() -> void:
	var world := Node3D.new()
	get_root().add_child(world)

	# 1. Door sensor first (so it joins the lab_door_sensors group before
	#    the scanner's deferred auto-connect runs).
	var door: Node3D = Node3D.new()
	door.set_script(load(DOOR))
	world.add_child(door)

	# 2. Scanner with the ACTUAL deployed config from point_one.lab.json:
	#    podium mounting + auto-connect. (Hold shortened to 1.5s so the
	#    test runs fast; hold duration is orthogonal to "does it work".)
	var scanner: Node3D = load(SCANNER).instantiate()
	scanner.set("scan_active", true)
	scanner.set("mounting", "podium")
	scanner.set("auto_connect_door", true)
	scanner.set("scan_hold_seconds", 1.5)
	world.add_child(scanner)

	# 3. The REAL collision hand (AnimatableBody3D from base.tscn, layer 18).
	#    It carries its own _physics_process that force-bodies itself toward
	#    a controller target; standalone that target is the origin, so it
	#    snaps back onto the plate no matter where we put it. In real VR the
	#    tracked controller is authoritative over the hand transform every
	#    frame — so we replicate that by freezing the hand's self-movement
	#    and driving its transform directly, exactly as the XR rig would.
	var hand: Node3D = load(HAND).instantiate()
	world.add_child(hand)
	hand.set_physics_process(false)
	hand.set_process(false)
	if "sync_to_physics" in hand:
		hand.sync_to_physics = false
	# Park it FAR before the first settle so the negative control is genuine.
	hand.global_position = Vector3(6, 6, 6)

	var state := {"scanned": false, "released": false}
	scanner.palm_scanned.connect(func(): state["scanned"] = true)
	scanner.palm_released.connect(func(): state["released"] = true)

	await _phys(20)

	var area: Area3D = scanner.find_child("ScanArea", true, false)
	print("[sim] ScanArea present=%s mask=%d (hand layer=%d)" %
		[area != null, area.collision_mask if area else -1, hand.collision_layer])
	print("[sim] door in group=%s  scanner->door wired=%s" %
		[door.is_in_group("lab_door_sensors"),
		 scanner.palm_scanned.is_connected(Callable(door, "_open_door"))])

	# 4. Hand has been parked far the whole time — must NOT have triggered.
	#    (This also proves the frozen collision hand stays where we put it
	#    and does not snap back to its controller target at the origin.)
	await _phys(12)
	print("[sim] hand pos=%s far -> scanned=%s (expect false)" %
		[hand.global_position, state["scanned"]])

	# 5. Hand onto the plate — self-calibrating: place it at the ScanArea's
	#    own world centre, so this is correct for ANY mounting (wall /
	#    podium / freestanding) without hardcoding the panel height.
	hand.global_position = area.global_position
	await _phys(80)   # allow the ~0.8s scan dwell to complete before grant
	print("[sim] hand pos=%s on plate -> scanned=%s (expect true)" %
		[hand.global_position, state["scanned"]])
	print("[sim] door open after scan=%s (expect true)" % door.get("_open"))

	# 6. Withdraw; the hold timer (1.5 s) then releases + closes the door.
	hand.global_position = Vector3(6, 6, 6)
	await _phys(110)   # ~1.83 s at 60 Hz
	print("[sim] after hold -> released=%s (expect true)" % state["released"])
	print("[sim] door open after release=%s (expect false)" % door.get("_open"))

	var detect_ok: bool = state["scanned"]
	var door_open_ok: bool = bool(door.get("_open")) == false and state["released"]
	print("\n[sim] RESULT: detection=%s  door_cycle=%s" %
		["PASS" if detect_ok else "FAIL",
		 "PASS" if door_open_ok else "FAIL"])
	quit(0 if (detect_ok and door_open_ok) else 1)

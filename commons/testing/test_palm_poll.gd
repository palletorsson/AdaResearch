extends SceneTree

## Validate the VR controller-proximity fallback: an XRController3D with NO
## collision body (so the Area3D CANNOT catch it) placed at the scan box
## must still fire palm_scanned via the poll path. This proves detection
## works regardless of the player hand's collision layer.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/test_palm_poll.gd

const SCANNER := "res://commons/artifacts/palm_scanner/palm_scanner.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _phys(n: int) -> void:
	for i in range(n):
		await physics_frame


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var scanner: Node3D = load(SCANNER).instantiate()
	scanner.set("scan_active", true)
	scanner.set("mounting", "podium")
	scanner.set("auto_connect_door", false)
	world.add_child(scanner)

	var fired := {"v": false}
	scanner.palm_scanned.connect(func(): fired["v"] = true)

	await _phys(40)

	var area: Area3D = scanner.find_child("ScanArea", true, false)
	if area == null:
		print("[poll] FAIL: no ScanArea")
		quit(1)
		return
	var cs: CollisionShape3D = null
	for c in area.get_children():
		if c is CollisionShape3D:
			cs = c
			break
	var target: Vector3 = cs.global_position if cs != null else area.global_position

	# An XRController3D with NO collision shape — the Area3D physically
	# cannot detect it, so only the poll fallback can.
	var ctrl := XRController3D.new()
	world.add_child(ctrl)

	# Park it far first — must NOT fire.
	ctrl.global_position = Vector3(9, 9, 9)
	await _phys(30)
	print("[poll] controller far -> scanned=%s (expect false)" % fired["v"])

	# Move it onto the plate — poll must fire (then the dwell grants access).
	ctrl.global_position = target
	await _phys(90)
	print("[poll] controller at box -> scanned=%s (expect true)" % fired["v"])

	print("[poll] RESULT: %s" % ("PASS" if fired["v"] else "FAIL"))
	quit(0 if fired["v"] else 1)

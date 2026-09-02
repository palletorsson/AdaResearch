extends SceneTree

## Is the pink gun held like a pistol, pointing forward? (2026-08-29, Palle:
## "can we have the gun point forward and be held with a natural grip like in
## godot-xr-tools")
##
## No headset here, so this checks the ARITHMETIC XR Tools will do. A hand grab
## point's transform is the controller's AIM frame relative to the object; the
## hand mesh's palm centre sits at (±0.02, -0.05, 0.10) in that frame
## (XRToolsGrabPointHand.get_palm_transform, "our hands have always been
## positioned based on our aim"). So, for each hand, this asserts:
##
##   the palm centre lands on the grip capsule (within 2 cm)
##   held (object = hand * grab_point^-1), the barrel (-Z) is the hand's -Z, i.e.
##     forward, within 3 degrees
##   the pose is the addon's Pistol pose, the point is PRIMARY, and the stick's
##     two Grip points are disabled so no other grab wins
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_pink_gun_grip.gd

const GUN := "res://commons/artifacts/pink_gun/pink_gun.tscn"
const GRIP_CENTRE := Vector3(0.0, -0.055, 0.02)   # pink_gun.gd: the capsule grip
const REPORT := "res://ada_run/pink_gun_grip_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var g: Node3D = (load(GUN) as PackedScene).instantiate() as Node3D
	get_root().add_child(g)
	await create_timer(0.3).timeout
	for side in ["Left", "Right"]:
		var gp: Node3D = g.get_node_or_null("GrabPointHand" + side) as Node3D
		_check(gp != null, "%s grab point: %s" % [side, "present" if gp != null else "MISSING"], "no grab point")
		if gp == null:
			continue
		var palm_off := Vector3(-0.02 if side == "Left" else 0.02, -0.05, 0.10)
		var palm: Vector3 = gp.transform * palm_off
		var d: float = palm.distance_to(GRIP_CENTRE)
		_check(d < 0.02, "%s palm centre %s is %.3f m from the grip" % [side, str(palm), d], "the hand is not on the grip")
		# held: the object takes hand * inverse(grab point); forward is the hand's -Z
		var hand := Transform3D.IDENTITY
		var held: Transform3D = hand * gp.transform.affine_inverse()
		var barrel: Vector3 = (held.basis * Vector3(0, 0, -1)).normalized()
		var deg: float = rad_to_deg(acos(clampf(barrel.dot(Vector3(0, 0, -1)), -1.0, 1.0)))
		_check(deg < 3.0, "%s barrel points %s, %.1f deg off the hand's forward" % [side, str(barrel), deg], "the gun does not point forward")
		var pose: Variant = gp.get("hand_pose")
		var open_path: String = ""
		if pose != null and pose.get("open_pose") != null:
			open_path = String((pose.get("open_pose") as Resource).resource_path)
		_check(open_path.ends_with("Pistol.res"), "%s pose: %s" % [side, open_path.get_file()], "not the Pistol pose")
		_check(int(gp.get("mode")) == 1, "%s mode %d (1 = PRIMARY)" % [side, int(gp.get("mode"))], "not a primary grab")
		var grip_pt: Node = g.get_node_or_null("GrabPointGrip" + side)
		_check(grip_pt != null and not bool(grip_pt.get("enabled")), "%s stick grip point disabled: %s" % [side, str(grip_pt != null and not bool(grip_pt.get("enabled")))], "the wand grip still competes")
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)

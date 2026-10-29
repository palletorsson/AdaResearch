extends Node3D
## The tape WORN, not held (Palle, 2026-10-29: "a small version of the tape over the hand rather than holding
## the tape, then I can use the tape without holding it"), and the LEG rule ("do not add lines if we have not
## moved the raycast point more than 30 cm"). A fake rig (a tracker with a pose, as probe_inventory_vr_hand.gd),
## the inventory's hand wearing its tape item on the controller, two floor slabs with a 1 m gap between them:
## (A) the bangle is under the controller at 0.4, inert, and lays FULL-width tape, not 0.4 of it;
## (B) trigger held, the hand moved 20 cm: no point; moved 40 cm from the start: one leg;
## (C) the aim crosses the gap: the next point starts a fresh patch (break_before), nothing bridges the air;
## (D) trigger let go 10 cm on: a stroke of 5 points, 4 legs, 0.9 m paid, 7.5 cm wide, and it is PRINTED;
## (E) grip: the stroke is gone and the roll refilled;
## (F) tap, move a metre, tap: a straight strip (the two-click way still works);
## (G) another item chosen: the bangle is put away, and back on when the tape is chosen again.
## Writes ada_run/inventory/{tape_worn.png, tape_worn.json}.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_tape_worn.tscn

const HandLib = preload("res://commons/player/inventory_hand.gd")
const Strip = preload("res://commons/artifacts/tape_roll/strip.gd")

var _tracker: XRControllerTracker
var _ctrl: XRController3D

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/inventory");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 30, 0);sun.light_energy = 1.1;add_child(sun)
	# two slabs with a gap: x in [-5, 1] and [2, 8]
	_slab(Vector3(-2, 0, 0), 6.0);_slab(Vector3(5, 0, 0), 6.0)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(1.2, 1.9, 2.6)).looking_at(Vector3(1.6, 0.35, -0.9));cam.fov = 60;add_child(cam);cam.current = true
	# the rig: the bracelet's hand, aiming 45 degrees down so the aim point is one metre ahead on the floor
	_tracker = XRControllerTracker.new();_tracker.name = &"right_hand";_tracker.type = XRServer.TRACKER_CONTROLLER;_tracker.hand = XRPositionalTracker.TRACKER_HAND_RIGHT
	_hand_at(0.0);XRServer.add_tracker(_tracker)
	var origin := XROrigin3D.new();origin.name = "XROrigin3D";origin.current = true;add_child(origin)
	var xcam := XRCamera3D.new();xcam.position = Vector3(0, 1.65, 0);origin.add_child(xcam)
	_ctrl = XRController3D.new();_ctrl.name = "RightHand";_ctrl.tracker = &"right_hand";_ctrl.pose = &"aim";origin.add_child(_ctrl)
	var report := {"checks": []}
	# the inventory's hand, holding the tape
	var hand: Node = HandLib.new();add_child(hand);hand.set_current("tape")
	var roll: Node3D = hand.sync_worn(_ctrl)
	await get_tree().physics_frame;await get_tree().physics_frame
	var worn_ok: bool = roll != null and roll.get_parent() == _ctrl and is_equal_approx(roll.scale.x, .4) and roll.get("enabled") == false and roll.collision_layer == 0
	var width: float = roll.preview.tape_width if roll != null else 0.0
	_check(report, "A worn: the bangle is under the controller at 0.4, not grabbable, no collision; its tape is the full 7.5 cm", worn_ok and is_equal_approx(width, .075) and roll.leg > .29 and hand.worn_node() == roll, {"parent": str(roll.get_parent().name) if roll else "", "scale": roll.scale.x if roll else 0, "width": width, "leg": roll.leg if roll else 0, "enabled": roll.get("enabled") if roll else null, "layer": roll.collision_layer if roll else -1, "worn_node": hand.worn_node() == roll})
	# B - the trigger held, the hand moved: 20 cm is no leg, 40 cm is one
	roll.fire_worn()
	await _ticks(0.35)
	_hand_at(0.2);await _ticks(0.5)
	var after_20: int = roll.drag_points.size()
	_hand_at(0.4);await _ticks(0.5)
	var after_40: int = roll.drag_points.size()
	var leg_len: float = Strip.resolve(roll.drag_points[0]).position.distance_to(Strip.resolve(roll.drag_points[-1]).position) if after_40 == 2 else 0.0
	_check(report, "B legs: 20 cm on is no point, 40 cm on is one leg of 0.4 m", roll.pressed and after_20 == 1 and after_40 == 2 and absf(leg_len - .4) < .02, {"after_20": after_20, "after_40": after_40, "leg": leg_len})
	# C - across the gap: the aim misses, then lands on the far slab: a fresh patch
	_hand_at(1.5);await _ticks(0.5)
	var over_gap: int = roll.drag_points.size()
	_hand_at(2.5);await _ticks(0.5)
	var landed: int = roll.drag_points.size()
	var broke: bool = landed == 3 and bool(roll.drag_points[2].get("break_before", false))
	_hand_at(2.9);await _ticks(0.5)
	var joined: bool = roll.drag_points.size() == 4 and not bool(roll.drag_points[3].get("break_before", false))
	_check(report, "C gap: over the air no point; on the far slab a point that starts a fresh patch; 40 cm on, a joined leg", over_gap == 2 and roll.drag_gap == false and broke and joined, {"over_gap": over_gap, "landed": landed, "broke": broke, "joined": joined})
	# D - let go 10 cm on: the stroke is committed, printed
	_hand_at(3.0);await _ticks(0.1)
	roll.release_worn()
	await get_tree().physics_frame;await get_tree().physics_frame
	var strip: Node3D = roll.segments[-1] if not roll.segments.is_empty() else null
	var paid: float = strip.paid_length if strip else 0.0
	var printed: String = str(strip.get("printed")) if strip else ""
	_check(report, "D stroke: 5 points, 0.9 m paid (the gap leg is free), 7.5 cm wide, printed, and 0.9 m off the roll", strip != null and strip.anchors.size() == 5 and absf(paid - .9) < .03 and is_equal_approx(strip.tape_width, .075) and printed != "" and absf(roll.remaining - 29.1) < .03, {"points": strip.anchors.size() if strip else 0, "paid": paid, "width": strip.tape_width if strip else 0, "printed": printed, "remaining": roll.remaining})
	# the picture: the stroke across the gap, the bangle on the hand, the aim line (before the undo takes the stroke)
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("tape_worn.png"))
	# E - grip: undone and refilled
	var gone: Node3D = roll.undo_last()
	await get_tree().process_frame
	_check(report, "E undo: the stroke is gone, the roll back at 30 m", gone == strip and not is_instance_valid(strip) and is_equal_approx(roll.remaining, 30.0) and roll.segments.is_empty(), {"remaining": roll.remaining})
	# F - tap, move, tap: a straight strip
	_hand_at(4.0);await _ticks(0.1)
	roll.fire_worn();await get_tree().physics_frame;roll.release_worn()
	await _ticks(0.1)
	var start_kept: bool = not roll.start_anchor.is_empty() and roll.segments.is_empty()
	_hand_at(5.0);await _ticks(0.3)
	roll.fire_worn();await get_tree().physics_frame;roll.release_worn()
	await get_tree().physics_frame
	var straight: Node3D = roll.segments[-1] if not roll.segments.is_empty() else null
	_check(report, "F tap, tap: the first tap keeps its start, the second lays a straight 1 m strip", start_kept and straight != null and straight.anchors.size() == 2 and absf(straight.paid_length - 1.0) < .03 and roll.start_anchor.is_empty(), {"start_kept": start_kept, "paid": straight.paid_length if straight else 0})
	# G - another item: put away; the tape again: back
	hand.set_current("point");hand.sync_worn(_ctrl)
	var away: bool = not roll.visible and not roll.worn_active and hand.worn_node() == null
	hand.set_current("tape");var again: Node3D = hand.sync_worn(_ctrl)
	_check(report, "G put away: the ball chosen hides the bangle; the tape chosen brings the same one back", away and again == roll and roll.visible and roll.worn_active, {"away": away, "same": again == roll})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("tape_worn.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_tape_worn] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _slab(at: Vector3, wide: float) -> void:
	var b := StaticBody3D.new();b.collision_layer = 1;add_child(b);b.global_position = at
	var cs := CollisionShape3D.new();var box := BoxShape3D.new();box.size = Vector3(wide, .1, 10);cs.shape = box;cs.position.y = -.05;b.add_child(cs)
	var m := MeshInstance3D.new();var bm := BoxMesh.new();bm.size = box.size;m.mesh = bm;m.position.y = -.05
	var mat := StandardMaterial3D.new();mat.albedo_color = Color("8f8a84");m.material_override = mat;b.add_child(m)

## The hand a metre up at x, aiming 45 degrees down along -Z: its aim lands on the floor at (x, 0, -1).
func _hand_at(x: float) -> void:
	_tracker.set_pose(&"aim", Transform3D(Basis(Vector3.RIGHT, -PI / 4), Vector3(x, 1.0, 0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func _ticks(seconds: float) -> void:
	var n := int(ceil(seconds * Engine.physics_ticks_per_second))
	for i in n:
		await get_tree().physics_frame

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_tape_worn] %s  %s" % ["ok  " if ok else "FAIL", what])

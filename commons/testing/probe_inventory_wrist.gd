extends Node3D
## The inventory on the PLAIN HAND: the real museum rig (commons/player/museum_rig.tscn, the one the museum and
## the Void both drive) on fake trackers with poses, no bracelet anywhere. (A) the rig carries InventoryWrist,
## enabled from em_layout, with the ITEMS panel on the left wrist hidden; (B) the left palm turned up shows the
## panel, ITEMS alone, listing the items; turned down hides it; (C) the tape chosen is worn on the RIGHT hand;
## (D) the right trigger held and moved lays a stroke from that hand; (E) the right pointer on a target: the
## trigger lays nothing; (F) the ball chosen, the trigger makes one in the right hand's own FunctionPickup;
## (G) palm up + grip takes it back, palm down + grip does nothing (the Void's grab). Writes
## ada_run/inventory/{wrist.png, wrist.json}.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_inventory_wrist.tscn

const Rig = preload("res://commons/player/museum_rig.tscn")
const Strip = preload("res://commons/artifacts/tape_roll/strip.gd")

var _left: XRControllerTracker
var _right: XRControllerTracker

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/inventory");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .75;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(12, .1, 12);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = fb.size;fm.mesh = fbm;fm.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(1.0, 1.7, 1.6)).looking_at(Vector3(0.3, 0.6, -0.8));cam.fov = 60;add_child(cam)
	# the trackers, then the rig itself
	_left = XRControllerTracker.new();_left.name = &"left_hand";_left.type = XRServer.TRACKER_CONTROLLER;_left.hand = XRPositionalTracker.TRACKER_HAND_LEFT
	_right = XRControllerTracker.new();_right.name = &"right_hand";_right.type = XRServer.TRACKER_CONTROLLER;_right.hand = XRPositionalTracker.TRACKER_HAND_RIGHT
	_palm(0.0);_hand(0.3, 0.0);XRServer.add_tracker(_left);XRServer.add_tracker(_right)
	var rig: XROrigin3D = Rig.instantiate();add_child(rig);rig.current = true
	cam.current = true
	for i in 20:
		await get_tree().process_frame
	var report := {"checks": []}
	var wrist: Node = rig.get_node_or_null("InventoryWrist")
	var panel: Node3D = wrist.panel if wrist != null else null
	_check(report, "A rig: InventoryWrist on the museum rig, enabled, its panel on the left wrist and hidden", wrist != null and wrist.enabled and panel != null and panel.get_parent() == rig.get_node("LeftHand") and not panel.visible and wrist.ui != null, {"wrist": wrist != null, "ui": wrist.ui != null if wrist else false})
	# B - the left palm up shows ITEMS; down hides it
	_palm(1.0)
	for i in 4:
		await get_tree().process_frame
	var shown: bool = wrist.showing and panel.visible
	var tabs: Array = wrist.ui.get("_tab_buttons");var tab_row_hidden: bool = not (tabs[0] as Control).get_parent().visible
	var items_tab: bool = int(wrist.ui.get("_active_tab")) == 4
	var listed: int = (wrist.ui.get("_item_buttons") as Dictionary).size()
	_palm(0.0)
	for i in 4:
		await get_tree().process_frame
	_check(report, "B palm: up shows the panel on ITEMS alone with the items listed; down hides it", shown and tab_row_hidden and items_tab and listed >= 4 and not wrist.showing and not panel.visible, {"shown": shown, "tab_row_hidden": tab_row_hidden, "items_tab": items_tab, "listed": listed, "hidden_again": not panel.visible})
	# C - the tape, chosen on the panel: worn on the right hand
	wrist.ui.item_selected.emit("tape")
	for i in 3:
		await get_tree().process_frame
	var roll: Node3D = wrist.hand.worn_node()
	_check(report, "C tape: chosen on the panel, the roll is worn on the RIGHT controller", roll != null and roll.get_parent() == rig.get_node("RightHand") and roll.worn_active, {"worn": roll != null, "parent": str(roll.get_parent().name) if roll else ""})
	# D - the right trigger held and moved: a stroke from that hand (hand at 1 m, aiming 45 degrees down)
	_hand(0.3, 0.0);await _ticks(0.3)
	wrist._on_right_pressed("trigger_click");await _ticks(0.3)
	_hand(0.7, 0.0);await _ticks(0.5)
	_hand(1.1, 0.0);await _ticks(0.5)
	wrist._on_right_released("trigger_click")
	await get_tree().physics_frame;await get_tree().physics_frame
	var strip: Node3D = roll.segments[-1] if not roll.segments.is_empty() else null
	_check(report, "D stroke: trigger held, the hand moved 80 cm: a strip of 3 points, 0.8 m, from the right hand", strip != null and strip.anchors.size() == 3 and absf(strip.paid_length - .8) < .03, {"points": strip.anchors.size() if strip else 0, "paid": strip.paid_length if strip else 0, "current": wrist.hand.current, "worn_active": roll.worn_active, "started": not roll.start_anchor.is_empty()})
	# E - the right pointer on a target: the trigger is the switch's
	var pointer: Node = wrist._right_pointer();pointer.set("target", floor_b)
	var before: int = roll.segments.size()
	wrist._on_right_pressed("trigger_click");await _ticks(0.2);wrist._on_right_released("trigger_click")
	await get_tree().physics_frame
	var no_start: bool = roll.start_anchor.is_empty() and roll.segments.size() == before
	pointer.set("target", null)
	_check(report, "E pointing: with the pointer on a target the trigger lays nothing", no_start, {"segments": roll.segments.size(), "started": not roll.start_anchor.is_empty()})
	# F - the ball: made in the right hand's own pickup
	wrist.ui.item_selected.emit("point")
	for i in 3:
		await get_tree().process_frame
	var put_away: bool = not roll.visible and wrist.hand.worn_node() == null
	wrist._on_right_pressed("trigger_click")
	for i in 4:
		await get_tree().physics_frame
	var pk: Node = XRToolsFunctionPickup.find_instance(rig.get_node("RightHand"))
	var held: Node = pk.get("picked_up_object") if pk else null
	_check(report, "F ball: the tape put away; trigger makes a ball held by the right hand's FunctionPickup", put_away and held != null and held.has_method("hub"), {"put_away": put_away, "held": str(held.name) if held else ""})
	# G - grip: nothing with the palm down (the Void's grab); with the panel up, the ball taken back
	wrist._on_right_pressed("grip_click")
	await get_tree().process_frame
	var still: bool = is_instance_valid(held) and wrist.hand.placed.size() == 1
	_palm(1.0)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("wrist.png"))
	wrist._on_right_pressed("grip_click")
	await get_tree().process_frame;await get_tree().process_frame
	_check(report, "G grip: palm down, grip leaves the ball (the Void's grab); palm up, grip takes it back", still and wrist.hand.placed.is_empty() and not is_instance_valid(held), {"still": still, "placed": wrist.hand.placed.size()})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("wrist.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_inventory_wrist] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

## The left hand at the chest; `up` 1 turns its palm up (+X to UP), 0 leaves it facing in.
func _palm(up: float) -> void:
	var b := Basis(Vector3.FORWARD, -PI / 2 * up)   # a roll about -Z turns +X toward +Y
	_left.set_pose(&"aim", Transform3D(b, Vector3(-0.25, 1.1, -0.2)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

## The right hand a metre up at x, aiming 45 degrees down along -Z: its aim lands on the floor at (x, 0, -1).
func _hand(x: float, z: float) -> void:
	_right.set_pose(&"aim", Transform3D(Basis(Vector3.RIGHT, -PI / 4), Vector3(x, 1.0, z)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func _ticks(seconds: float) -> void:
	for i in int(ceil(seconds * Engine.physics_ticks_per_second)):
		await get_tree().physics_frame

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_inventory_wrist] %s  %s" % ["ok  " if ok else "FAIL", what])

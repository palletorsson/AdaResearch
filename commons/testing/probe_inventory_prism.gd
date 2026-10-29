extends Node3D
## THE INVENTORY PRISM on the real museum rig (commons/player/museum_rig.tscn - the museum's and the Void's),
## fake trackers with poses, no bracelet. (A) the rig carries InventoryPrism, four faces bound, hidden; (B) the
## left palm up shows it upright over the left hand with face 0 (HAND) turned to the eye; (C) the ▶ ear turns
## it: face 1 active and now the one facing the eye; (D) the HAND face's Tape card: the roll worn on the RIGHT
## hand, the tip ring at the tape's width; (E) the TAPE face's hazard swatch: the worn roll wears the design
## (live apply_config); (F) the right trigger held and moved lays a stroke, and the PLACED face lists it;
## (G) TAKE BACK LAST takes the strip back; (H) the Ball card, trigger: a ball in the right pickup; grip with
## the prism up takes it back; palm down hides the prism; (I) toggle() - the Void's left X - pins it up and down. Writes ada_run/inventory/{prism.png, prism.json}.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_inventory_prism.tscn

const Rig = preload("res://commons/player/museum_rig.tscn")

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
	# the eye: where a head would be, behind and above the hands, looking at the left hand
	# the eye, off to the left front so the rig's own body does not stand in the picture: the prism turns to it
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(-1.1, 1.45, 0.5)).looking_at(Vector3(-0.2, 1.1, -0.3));cam.fov = 60;add_child(cam)
	_left = XRControllerTracker.new();_left.name = &"left_hand";_left.type = XRServer.TRACKER_CONTROLLER;_left.hand = XRPositionalTracker.TRACKER_HAND_LEFT
	_right = XRControllerTracker.new();_right.name = &"right_hand";_right.type = XRServer.TRACKER_CONTROLLER;_right.hand = XRPositionalTracker.TRACKER_HAND_RIGHT
	_palm(0.0);_hand(0.3);XRServer.add_tracker(_left);XRServer.add_tracker(_right)
	var rig: XROrigin3D = Rig.instantiate();add_child(rig);rig.current = true
	cam.current = true
	for i in 25:
		await get_tree().process_frame
	var report := {"checks": []}
	var p: Node = rig.get_node_or_null("InventoryPrism")
	var bound: int = 0
	for ui in (p.uis if p else []):
		if ui != null:bound += 1
	_check(report, "A rig: InventoryPrism on the museum rig, enabled, four faces bound, hidden until the palm turns", p != null and p.enabled and bound == 4 and not p.showing and not p.prism.visible, {"prism": p != null, "bound": bound})
	# B - palm up: shown, upright, face 0 toward the eye
	_palm(1.0)
	for i in 30:
		await get_tree().process_frame
	var eye: Vector3 = cam.global_position
	var f0: Node3D = p.faces[0];var n0: Vector3 = f0.global_basis.z;var to_eye: Vector3 = (eye - f0.global_position);to_eye.y = 0;to_eye = to_eye.normalized()
	var upright: bool = p.prism.global_basis.y.dot(Vector3.UP) > .99
	var over_hand: bool = (p.prism.global_position - rig.get_node("LeftHand").global_position).y > .1
	_check(report, "B palm up: shown, upright over the left hand, the HAND face turned to the eye", p.showing and p.prism.visible and upright and over_hand and n0.dot(to_eye) > .95, {"upright": upright, "over_hand": over_hand, "facing": n0.dot(to_eye)})
	# C - the ▶ ear turns it
	(p.uis[0].buttons["ear+1"] as Button).pressed.emit()
	for i in 30:
		await get_tree().process_frame
	var f1: Node3D = p.faces[1];var n1: Vector3 = f1.global_basis.z;var to_eye1: Vector3 = eye - f1.global_position;to_eye1.y = 0;to_eye1 = to_eye1.normalized()
	_check(report, "C turn: ▶ makes face 1 (KNOBS) active, and it now faces the eye", p.active == 1 and n1.dot(to_eye1) > .95, {"active": p.active, "facing": n1.dot(to_eye1)})
	# D - the HAND face's Tape card: worn on the right hand, the ring at its width
	(p.uis[0].buttons["item:tape"] as Button).pressed.emit()
	for i in 4:
		await get_tree().process_frame
	var roll: Node3D = p.hand.worn_node()
	var ring_r: float = (p.ring.mesh as TorusMesh).outer_radius
	_check(report, "D tape: the card worn on the RIGHT hand; the tip ring the tape's half width", roll != null and roll.get_parent() == rig.get_node("RightHand") and p.ring.visible and absf(ring_r - .0375) < .001, {"worn": roll != null, "ring": p.ring.visible, "ring_r": ring_r})
	# E - the TAPE face's hazard design: the worn roll wears it
	(p.uis[2].buttons["design:hazard"] as Button).pressed.emit()
	for i in 3:
		await get_tree().process_frame
	_check(report, "E design: the hazard swatch dresses the worn roll (tape == hazard, design loaded)", roll.tape == "hazard" and not roll.design.is_empty() and str(roll.design.get("pattern", "")) == "diagonal", {"tape": roll.tape, "pattern": roll.design.get("pattern", "")})
	# F - a stroke from the right trigger; PLACED lists it
	_hand(0.3);await _ticks(0.3)
	p._on_right_pressed("trigger_click");await _ticks(0.3)
	_hand(0.7);await _ticks(0.5)
	_hand(1.1);await _ticks(0.5)
	p._on_right_released("trigger_click")
	await get_tree().physics_frame;await get_tree().physics_frame
	var strip: Node3D = roll.segments[-1] if not roll.segments.is_empty() else null
	var rows: Array = p.placed_rows()
	_check(report, "F stroke: trigger held, hand moved 80 cm: a 3-point 0.8 m strip; the PLACED face lists it", strip != null and strip.anchors.size() == 3 and absf(strip.paid_length - .8) < .03 and rows.size() == 1 and str(rows[0]).begins_with("tape"), {"points": strip.anchors.size() if strip else 0, "rows": rows})
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("prism.png"))
	# G - TAKE BACK LAST on the PLACED face
	(p.uis[3].buttons["take_back"] as Button).pressed.emit()
	await get_tree().process_frame;await get_tree().process_frame
	_check(report, "G take back: the strip is gone, the roll refilled, PLACED empty", not is_instance_valid(strip) and is_equal_approx(roll.remaining, 30.0) and p.placed_rows().is_empty(), {"rows": p.placed_rows(), "remaining": roll.remaining})
	# H - the ball: made into the right pickup; grip with the prism up takes it back; palm down hides
	(p.uis[0].buttons["item:point"] as Button).pressed.emit()
	for i in 3:
		await get_tree().process_frame
	p._on_right_pressed("trigger_click")
	for i in 4:
		await get_tree().physics_frame
	var pk: Node = XRToolsFunctionPickup.find_instance(rig.get_node("RightHand"))
	var held: Node = pk.get("picked_up_object") if pk else null
	var made: bool = held != null and held.has_method("hub") and not roll.visible
	# the MINIATURE: the chosen ball as a small copy over the right hand, inert, 7 cm for its 17 cm
	var mini: Node3D = p.hand.mini_node()
	var mini_ok: bool = mini != null and mini.get_parent() == rig.get_node("RightHand") and mini.has_method("hub") and absf(mini.scale.x - .07 / .17) < .01 and mini.collision_layer == 0 and not mini.is_in_group("playground_balls") and mini != held
	p._on_right_pressed("grip_click")
	await get_tree().process_frame;await get_tree().process_frame
	var taken: bool = not is_instance_valid(held) and p.hand.placed.is_empty()
	_palm(0.0)
	for i in 4:
		await get_tree().process_frame
	_check(report, "H ball: the card + trigger makes a ball in the right pickup (tape put away); grip takes it back; palm down hides the prism", made and taken and not p.showing and not p.prism.visible and not p.ring.visible, {"made": made, "taken": taken, "showing": p.showing})
	_check(report, "J miniature: the chosen ball shown as a 7 cm inert copy over the right hand, out of the support graph, not the made one", mini_ok, {"mini": mini != null, "scale": mini.scale.x if mini else 0, "layer": mini.collision_layer if mini else -1, "in_group": mini.is_in_group("playground_balls") if mini else null})
	# I - the Void's left X: toggle() pins it up whatever the palm; again, down
	p.toggle()
	for i in 4:
		await get_tree().process_frame
	var pinned_up: bool = p.showing and p.prism.visible
	p.toggle()
	for i in 4:
		await get_tree().process_frame
	_check(report, "I toggle: X pins the prism up with the palm down; X again takes it down", pinned_up and not p.showing and not p.prism.visible, {"pinned_up": pinned_up, "showing": p.showing})
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("prism.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_inventory_prism] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

## The left hand before the chest; `up` 1 rolls its palm up (+X to UP).
func _palm(up: float) -> void:
	_left.set_pose(&"aim", Transform3D(Basis(Vector3.FORWARD, -PI / 2 * up), Vector3(-0.25, 1.05, -0.25)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

## The right hand a metre up at x, aiming 45 degrees down along -Z: its aim lands on the floor at (x, 0, -1).
func _hand(x: float) -> void:
	_right.set_pose(&"aim", Transform3D(Basis(Vector3.RIGHT, -PI / 4), Vector3(x, 1.0, 0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func _ticks(seconds: float) -> void:
	for i in int(ceil(seconds * Engine.physics_ticks_per_second)):
		await get_tree().physics_frame

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_inventory_prism] %s  %s" % ["ok  " if ok else "FAIL", what])

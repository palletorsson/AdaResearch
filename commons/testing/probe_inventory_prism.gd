extends Node3D
## THE INVENTORY PRISM on the real museum rig (commons/player/museum_rig.tscn - the museum's and the Void's),
## fake trackers with poses, no bracelet. (A) the rig carries InventoryPrism, four faces bound, hidden; (B) the
## left palm up shows it: a drum on the left controller's forward axis, the HAND face on top, its up along the
## controller (Open Brush's wand palette); (C) the ▶ ear rolls it a quarter: face 1 active and on top; (D) the HAND face's Tape card: the roll worn on the RIGHT
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
	var lh: Node3D = rig.get_node("LeftHand")
	var f0: Node3D = p.faces[0]
	var on_top: float = f0.global_basis.z.dot(lh.global_basis.y)          # the HAND face's normal is the controller's up
	var along: float = f0.global_basis.y.dot(-lh.global_basis.z)           # its top runs along the controller's forward
	var ahead: float = (p.prism.global_position - lh.global_position).dot(-lh.global_basis.z)
	_check(report, "B palm up: shown, a drum on the left controller 12 cm ahead, the HAND face on top with its up along the controller (Open Brush)", p.showing and p.prism.visible and p.prism.get_parent() == lh and on_top > .98 and along > .98 and absf(ahead - .12) < .01, {"on_top": on_top, "along": along, "ahead": ahead})
	# C - the ▶ ear turns it
	(p.uis[0].buttons["ear+1"] as Button).pressed.emit()
	for i in 30:
		await get_tree().process_frame
	var f1: Node3D = p.faces[1];var on_top1: float = f1.global_basis.z.dot(lh.global_basis.y)
	_check(report, "C turn: ▶ rolls the drum a quarter: face 1 (KNOBS) active and now on top", p.active == 1 and on_top1 > .98, {"active": p.active, "on_top": on_top1})
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
	_check(report, "G take back: the strip is gone, the roll refilled to its length, PLACED empty", not is_instance_valid(strip) and is_equal_approx(roll.remaining, roll.roll_length) and p.placed_rows().is_empty(), {"rows": p.placed_rows(), "remaining": roll.remaining})
	# H - the ball: made into the right pickup; grip with the prism up takes it back; palm down hides
	(p.uis[0].buttons["item:point"] as Button).pressed.emit()
	for i in 3:
		await get_tree().process_frame
	_hand(0.3)   # aiming at the floor a metre ahead: Garry's Mod placement, the ball appears there and takes its grid point
	await _ticks(0.2)
	p._on_right_pressed("trigger_click")
	for i in 6:
		await get_tree().physics_frame
	var held: Node = p.hand.placed[-1] if not p.hand.placed.is_empty() else null
	var made: bool = held != null and held.has_method("hub") and not roll.visible and held.on_grid and is_equal_approx(held.global_position.y, held.hub()) and not held.is_picked_up()
	# the MINIATURE: the chosen ball as a small copy over the right hand, inert, 10 cm for its 17 cm
	var mini: Node3D = p.hand.mini_node()
	var mini_ok: bool = mini != null and mini.get_parent() == rig.get_node("RightHand") and mini.has_method("hub") and absf(mini.scale.x - .10 / .17) < .01 and mini.collision_layer == 0 and not mini.is_in_group("playground_balls") and mini != held
	# K - the clock wants a wall: pointed at the floor it refuses with a notice; the HAND face flicks pages
	(p.uis[0].buttons["item:clock"] as Button).pressed.emit()
	for i in 3:
		await get_tree().process_frame
	var before: int = p.hand.placed.size()
	p._on_right_pressed("trigger_click")
	await get_tree().physics_frame
	var refused: bool = p.hand.placed.size() == before and p.hand.notice.find("needs a wall") >= 0
	var pages_ok: bool = p.uis[0].buttons.has("page:+")
	p.flick(1, 3);var flicked: bool = p.hand_page == 1
	_check(report, "K prefabs: the clock pointed at the floor is refused with 'needs a wall'; the HAND face has pages and flicks", refused and pages_ok and flicked, {"refused": refused, "notice": p.hand.notice, "pages": pages_ok, "page": p.hand_page})
	p._on_right_pressed("grip_click")
	await get_tree().process_frame;await get_tree().process_frame
	var taken: bool = not is_instance_valid(held) and p.hand.placed.is_empty()
	_palm(0.0)
	for i in 4:
		await get_tree().process_frame
	_check(report, "H ball: the card + trigger puts a ball where the hand points, on its grid point (tape put away); grip takes it back; palm down hides the prism", made and taken and not p.showing and not p.prism.visible and not p.ring.visible, {"made": made, "taken": taken, "showing": p.showing, "placed_at": held.global_position if is_instance_valid(held) else null})
	_check(report, "J miniature: the chosen ball shown as a 10 cm inert copy over the right hand, out of the support graph, not the made one", mini_ok, {"mini": mini != null, "scale": mini.scale.x if mini else 0, "layer": mini.collision_layer if mini else -1, "in_group": mini.is_in_group("playground_balls") if mini else null})
	# L - the budget: with draws cut to 3 a crate (48 draws) is refused with BUDGET FULL; the budget restored, it is made
	p.hand.budget_override = {"draws": 3}
	p.choose("crate")
	for i in 3:
		await get_tree().process_frame
	_hand(0.3);await _ticks(0.2)
	var before_l: int = p.hand.placed.size()
	p._on_right_pressed("trigger_click");await get_tree().physics_frame
	var refused_l: bool = p.hand.placed.size() == before_l and p.hand.notice.begins_with("BUDGET FULL");var notice_l: String = p.hand.notice
	p.hand.budget_override = {}
	p._on_right_pressed("trigger_click")
	for i in 6:
		await get_tree().physics_frame
	var crate_made: bool = p.hand.placed.size() == before_l + 1
	var crate_node: Node = p.hand.placed[-1] if crate_made else null
	var merged: bool = crate_node != null and crate_node.find_child("Merged", true, false) != null
	var kids: Array = []
	if crate_node != null:
		for ch in crate_node.get_children():kids.append(str(ch.name) + ":" + ch.get_class())
		var w: Variant = crate_node.get("work")
		if w is Node:
			for ch in (w as Node).get_children():kids.append("work/" + str(ch.name) + ":" + ch.get_class())
	_check(report, "L budget: draws cut to 3, the crate is refused with BUDGET FULL; restored, it is made - as ONE merged mesh", refused_l and crate_made and merged, {"refused": refused_l, "notice_after_refusal": notice_l, "made": crate_made, "merged": merged, "kids": kids})
	# N - copies: a second crate with the same config is an instance: one multimesh with two instances, its own meshes on layer 0
	_hand(1.5);await _ticks(0.2)
	p._on_right_pressed("trigger_click")
	for i in 6:
		await get_tree().physics_frame
	var key: String = p.hand.instance_key("crate")
	var inst: Node = p.hand.instancer();var two: bool = inst.count(key) == 2
	var second: Node = p.hand.placed[-1]
	var hidden := true
	for m in second.find_children("*", "MeshInstance3D", true, false):
		if (m as MeshInstance3D).layers != 0:hidden = false
	var spent_now: Dictionary = p.hand.spent()
	var one_crate: int = int(p.hand.Items.cost_of("crate").draws)
	_check(report, "N copies: the second crate is an instance of the first - 2 in one multimesh, its meshes on layer 0, and it pays no draws", two and hidden and spent_now.draws == one_crate, {"count": inst.count(key), "groups": inst.groups(), "hidden": hidden, "spent": spent_now, "one_crate": one_crate})
	# M - the rubber: pointed at the second crate, the trigger takes it back; at the floor, nothing and a notice
	p.choose("rubber")
	for i in 3:
		await get_tree().process_frame
	var mini_r: Node3D = p.hand.mini_node();var rubber_worn: bool = mini_r != null and mini_r.name == "Mini_rubber"
	var target: Vector3 = (second as Node3D).global_position + Vector3(0, .3, 0)
	_right.set_pose(&"aim", rig.global_transform.affine_inverse() * Transform3D(Basis(), target + Vector3(0, 1.0, 0.8)).looking_at(target, Vector3.UP), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await _ticks(0.2)
	var before_m: int = p.hand.placed.size()
	p._on_right_pressed("trigger_click")
	await get_tree().process_frame;await get_tree().process_frame
	var erased: bool = p.hand.placed.size() == before_m - 1 and not is_instance_valid(second) and inst.count(key) == 1
	_hand(3.0);await _ticks(0.2)
	p._on_right_pressed("trigger_click");await get_tree().process_frame
	var refused_m: bool = p.hand.placed.size() == before_m - 1 and p.hand.notice.begins_with("not yours")
	_check(report, "M rubber: worn as a miniature; the trigger on the second crate takes it back (one instance left); on the floor, 'not yours'", rubber_worn and erased and refused_m, {"worn": rubber_worn, "erased": erased, "refused": refused_m, "notice": p.hand.notice})
	# P - the ghost: the crate chosen, the hand at the floor: a translucent crate stands on the metre point with the
	# aim line; the clock chosen there is a red ghost (refused); grip on the pointed crate takes it back
	_palm(1.0)   # the ghost and the grip need the palette up
	p.choose("crate")
	for i in 6:
		await get_tree().process_frame
	_hand(0.7);await _ticks(0.2)
	for i in 3:
		await get_tree().process_frame
	var g: Node3D = p.ghost
	var ghost_there: bool = g != null and g.visible and absf(g.global_position.x - 1.0) < .01 and absf(g.global_position.z + 1.0) < .01 and p.ghost_ok and p.aim_line != null and p.aim_line.visible
	p.choose("clock")
	for i in 3:
		await get_tree().process_frame
	var red: bool = p.ghost != null and p.ghost.visible and not p.ghost_ok
	p.choose("crate")
	for i in 3:
		await get_tree().process_frame
	p._on_right_pressed("trigger_click")
	for i in 4:
		await get_tree().physics_frame
	var crate2: Node = p.hand.placed[-1] if not p.hand.placed.is_empty() else null
	var tgt: Vector3 = (crate2 as Node3D).global_position + Vector3(0, .5, 0)
	_right.set_pose(&"aim", rig.global_transform.affine_inverse() * Transform3D(Basis(), tgt + Vector3(0, 1.0, 1.0)).looking_at(tgt, Vector3.UP), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await _ticks(0.2)
	var pointed: bool = p.hand.pointed_own(rig.get_node("RightHand"), 8.0, p._panel_rids()) == crate2
	p._on_right_pressed("grip_click")
	await get_tree().process_frame;await get_tree().process_frame
	var gone2: bool = not is_instance_valid(crate2) and not p.hand.placed.has(crate2)
	_check(report, "P ghost: the crate's ghost stands on the metre point with the aim line; the clock's ghost there is red; grip on the pointed crate takes it back", ghost_there and red and pointed and gone2, {"ghost_there": ghost_there, "red": red, "pointed": pointed, "gone": gone2})
	# Q - the grab hint: a ball 1.5 m ahead of the right hand is what it would grab at range: a line and a ring to it
	p.choose("point")
	for i in 3:
		await get_tree().process_frame
	_hand(0.3);await _ticks(0.2)
	p._on_right_pressed("trigger_click")
	for i in 4:
		await get_tree().physics_frame
	var ball2: Node3D = p.hand.placed[-1]
	for i in 10:
		await get_tree().physics_frame   # the ball settles onto its grid point first; then the hand is aimed at where it IS
	var ball_at: Vector3 = ball2.global_position
	# a pose is in the ORIGIN's space, and the player body may have moved the origin: the aim is converted
	_right.set_pose(&"aim", rig.global_transform.affine_inverse() * Transform3D(Basis(), ball_at + Vector3(0, .45, 1.1)).looking_at(ball_at, Vector3.UP), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	for i in 30:
		await get_tree().physics_frame
	var hint: Node = rig.get_node_or_null("GrabHint")
	var tgt2: Node3D = hint.target_of(rig.get_node("RightHand")) if hint else null
	var line_on: bool = hint != null and hint.showing_for(rig.get_node("RightHand"))
	var pk2: Node = XRToolsFunctionPickup.find_instance(rig.get_node("RightHand"))
	var rh: Node3D = rig.get_node("RightHand");var fwd2: Vector3 = -rh.global_basis.z;var names2: Array = []
	for c in (pk2.get("_object_in_ranged_area") as Array):
		if is_instance_valid(c):names2.append("%s dp=%.3f can=%s" % [c.name, fwd2.dot(((c as Node3D).global_position - rh.global_position).normalized()), str(c.can_pick_up(pk2)) if c.has_method("can_pick_up") else "?"])
	var diag := {"in_area": names2, "angle": pk2.get("ranged_angle"), "closest": str(pk2.get("closest_object")), "in_ranged": (pk2.get("_object_in_ranged_area") as Array).size(), "in_grab": (pk2.get("_object_in_grab_area") as Array).size(), "range_mask": pk2.get("ranged_collision_mask"), "ball_layer": ball2.collision_layer, "ranged_enable": pk2.get("ranged_enable"), "dist": (ball2.global_position - rig.get_node("RightHand").global_position).length(), "ball_frozen": ball2.freeze}
	_check(report, "Q grab hint: the ball 1.6 m off is the right hand's ranged target - the line and the ring show it", hint != null and tgt2 == ball2 and line_on, {"hint": hint != null, "target": str(tgt2.name) if tgt2 else "", "line": line_on, "diag": diag})
	p.take_all_back();_palm(0.0)
	for i in 4:
		await get_tree().process_frame
	# O - the metre grid: the wedge, turned east by its knob, stands on the nearest metre point of the floor
	p.choose("wedge");p.set_knob("_yaw", "90")
	for i in 3:
		await get_tree().process_frame
	_hand(0.7);await _ticks(0.2)   # the aim lands at (0.7, 0, -1): the metre point is (1, 0, -1)
	p._on_right_pressed("trigger_click")
	var wedge: Node3D = p.hand.placed[-1] if not p.hand.placed.is_empty() else null
	var at0: Vector3 = wedge.global_position if wedge else Vector3.INF
	await get_tree().physics_frame
	var at1: Vector3 = wedge.global_position if wedge else Vector3.INF
	for i in 3:
		await get_tree().physics_frame
	var at: Vector3 = wedge.global_position if wedge else Vector3.INF
	var stood: bool = wedge != null and str(wedge.get("how")) == "floor" and bool(wedge.get("freeze"))   # a path brick: walked on, so frozen on the floor
	var east: bool = wedge != null and (-wedge.global_basis.z).dot(Vector3.RIGHT) > .98   # the knob turns clockwise from above: its north (-Z) now points east (+X)
	var sized: bool = wedge != null and is_equal_approx(float(wedge.get("work").get("size")), 2.0) and is_equal_approx(float(wedge.get("work").get("height")), 1.0)
	_check(report, "O grid: the wedge stands frozen on the floor at the metre point (1, _, -1), turned east by its knob, 2 m base and 1 m rise", wedge != null and stood and absf(at.x - 1.0) < .02 and absf(at.z + 1.0) < .02 and at.y > -.01 and at.y < .1 and east and sized, {"at": at, "at0": at0, "at1": at1, "stood": stood, "east": east, "sized": sized})
	p.take_all_back()
	# R - THE BASE RULE: a crate on its metre point; a cardboard box pointed at the crate's top is placed above it and
	# FALLS onto it - things stack (Palle: "grid snap above itself and then fall down")
	p.choose("crate")
	for i in 3:
		await get_tree().process_frame
	_hand(0.7);await _ticks(0.2)
	p._on_right_pressed("trigger_click")
	for i in 40:
		await get_tree().physics_frame
	var crate_r: Node3D = p.hand.placed[-1]
	p.choose("cardboard")
	for i in 3:
		await get_tree().process_frame
	var top: Vector3 = Vector3(1.0, 1.0, -1.0)
	_right.set_pose(&"aim", rig.global_transform.affine_inverse() * Transform3D(Basis(), top + Vector3(0.3, 1.2, 0.9)).looking_at(top, Vector3.UP), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await _ticks(0.3)
	var at_r: Dictionary = p.hand.placement_at(rig.get_node("RightHand"), 8.0, p._panel_rids())
	p._on_right_pressed("trigger_click")
	for i in 90:
		await get_tree().physics_frame
	var box_r: Node3D = p.hand.placed[-1]
	var stacked: bool = box_r != crate_r and absf(box_r.global_position.x - 1.0) < .05 and absf(box_r.global_position.z + 1.0) < .05 and box_r.global_position.y > .9 and box_r.global_position.y < 1.2 and str(box_r.get("how")) in ["fall", "block"]
	_check(report, "R stack: the box aimed at the crate's top is put above it and falls onto it - resting on the crate at y about 1", stacked, {"hit": at_r.hit.get("position", null) if at_r.hit is Dictionary else null, "put_at": at_r.xform.origin, "box": box_r.global_position, "how": box_r.get("how"), "crate": crate_r.global_position})
	# W - THE SAND-BLOCK RULE: at rest, square, the fallen box takes its metre point and freezes - a block; the crate under it too
	for i in 60:
		await get_tree().physics_frame
	var block_w: bool = str(box_r.get("how")) == "block" and bool(box_r.get("freeze")) and absf(box_r.global_position.x - 1.0) < .001 and absf(box_r.global_position.z + 1.0) < .001 and absf(box_r.global_basis.y.dot(Vector3.UP) - 1.0) < .001
	var crate_w: bool = str(crate_r.get("how")) == "block" and bool(crate_r.get("freeze"))
	_check(report, "W sand block: resting square, the box is frozen on its metre point as a block; so is the crate it fell onto", block_w and crate_w, {"box_how": box_r.get("how"), "box_frozen": box_r.get("freeze"), "box": box_r.global_position, "crate_how": crate_r.get("how"), "box_sleeping": box_r.get("sleeping"), "box_sleeps": box_r.get("sleeps"), "box_note": box_r.get("sleep_note"), "crate_sleeps": crate_r.get("sleeps"), "box_up": box_r.global_basis.y, "tps": Engine.physics_ticks_per_second})
	# S - no gravity: the health plus is frozen where it is placed
	p.choose("health")
	for i in 3:
		await get_tree().process_frame
	_hand(2.3);await _ticks(0.2)
	p._on_right_pressed("trigger_click")
	for i in 30:
		await get_tree().physics_frame
	var cross: Node3D = p.hand.placed[-1]
	var stays: bool = bool(cross.get("freeze")) and str(cross.get("how")) in ["floor", "stay"] and cross.global_position.y > -.01
	_check(report, "S no gravity: the health plus is frozen where it is placed", stays, {"how": cross.get("how"), "frozen": cross.get("freeze"), "at": cross.global_position})
	# T2 - the rod with no ball near: its end on a metre point, lying along the grid
	p.choose("rod")
	for i in 3:
		await get_tree().process_frame
	_hand(3.6);await _ticks(0.2)
	p._on_right_pressed("trigger_click")
	for i in 30:
		await get_tree().physics_frame
	var rod_t: Node3D = p.hand.placed[-1]
	var e0: Vector3 = rod_t.end_global(0) if rod_t.has_method("end_global") else Vector3.INF
	var ax: Vector3 = rod_t.global_basis.x.normalized()
	var on_point: bool = absf(e0.x - roundf(e0.x)) < .03 and absf(e0.z - roundf(e0.z)) < .03
	var along_axis: bool = absf(ax.x) > .98 or absf(ax.z) > .98
	_check(report, "T2 rod on the grid: no ball near, its end sits on a metre point and it lies along a grid axis", on_point and along_axis, {"end0": e0, "axis": ax})
	p.take_all_back()
	# U - FREE HANGING: the crate pointed at nothing (the wand level, 8 m of air) hangs 2 m along it, on a metre point in the
	# air, frozen - a floating platform; the ghost stood there first
	_palm(1.0);p.choose("crate")
	for i in 3:
		await get_tree().process_frame
	_hand_level(0.6);await _ticks(0.3)
	var at_u: Dictionary = p.hand.placement_at(rig.get_node("RightHand"), 8.0, p._panel_rids())
	var ghost_air: bool = p.ghost != null and p.ghost.visible and p.ghost.global_position.distance_to(Vector3(1, 1, -2)) < .05
	p._on_right_pressed("trigger_click")
	for i in 40:
		await get_tree().physics_frame
	var hung: Node3D = p.hand.placed[-1]
	var hung_ok: bool = bool(at_u.get("hang", false)) and bool(hung.get("freeze")) and hung.global_position.distance_to(Vector3(1, 1, -2)) < .01 and str(hung.get("how")) == "pinned"
	_check(report, "U hang: pointed at nothing, the crate hangs frozen on the metre point (1, 1, -2) 2 m along the wand; the ghost stood there first", hung_ok and ghost_air, {"hang": at_u.get("hang"), "ok": at_u.ok, "at": hung.global_position, "how": hung.get("how"), "frozen": hung.get("freeze"), "ghost_air": ghost_air})
	# V - THE PIN: the trigger on the hung crate releases it - it falls, lands square and becomes a block; the trigger on the
	# block releases it again (frozen is frozen, whoever froze it); the ball is refused - it keeps its own rule
	p.choose("pin")
	for i in 3:
		await get_tree().process_frame
	_right.set_pose(&"aim", rig.global_transform.affine_inverse() * Transform3D(Basis(), Vector3(1.0, 1.5, 0.0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await _ticks(0.3)
	var pin_mini: bool = p.hand.mini_node() != null and str(p.hand.mini_node().name) == "Mini_pin"
	p._on_right_pressed("trigger_click")
	var released: bool = not bool(hung.get("freeze")) and str(hung.get("how")) == "fall"
	for i in 120:
		await get_tree().physics_frame
	var landed: bool = hung.global_position.y < .05 and str(hung.get("how")) == "block" and bool(hung.get("freeze")) and absf(hung.global_position.x - 1.0) < .001 and absf(hung.global_position.z + 2.0) < .001
	_right.set_pose(&"aim", rig.global_transform.affine_inverse() * Transform3D(Basis(), Vector3(1.0, 0.5, 0.0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await _ticks(0.3)
	var did_v: String = p.hand.pin_at(rig.get_node("RightHand"), 8.0, p._panel_rids())
	var released2: bool = did_v == "released" and not bool(hung.get("freeze"))
	p.choose("point")
	for i in 3:
		await get_tree().process_frame
	_hand(3.0);await _ticks(0.2)
	p._on_right_pressed("trigger_click")
	for i in 45:   # the ball's own rule moves it onto its grid point a few frames after it is made: aim at where it ENDS
		await get_tree().physics_frame
	var ball_v: Node3D = p.hand.placed[-1]
	p.choose("pin")
	for i in 3:
		await get_tree().process_frame
	# straight down from half a metre above the ball (Basis(RIGHT, -PI/2) turns the wand's -Z to DOWN, as _hand's -PI/4 turns it 45
	# degrees); a pose is in the ORIGIN's space and the player body has moved the origin by now, so it goes through its inverse
	_right.set_pose(&"aim", rig.global_transform.affine_inverse() * Transform3D(Basis(Vector3.RIGHT, -PI / 2), ball_v.global_position + Vector3(0, 0.5, 0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await _ticks(0.3)
	var did_ball: String = p.hand.pin_at(rig.get_node("RightHand"), 8.0, p._panel_rids())
	var ball_refused: bool = did_ball == "" and p.hand.notice.ends_with("keeps its own rule")
	_check(report, "V pin: worn as a miniature; on the hung crate it releases it - it falls and lands as a block; on the block it releases again; on the ball, refused (its own rule)", pin_mini and released and landed and released2 and ball_refused, {"mini": pin_mini, "released": released, "landed": landed, "at": hung.global_position, "how": hung.get("how"), "released2": did_v, "ball": did_ball, "notice": p.hand.notice, "sleeping": hung.get("sleeping"), "sleeps": hung.get("sleeps"), "note": hung.get("sleep_note"), "frozen": hung.get("freeze"), "ball_name": ball_v.name, "ball_at": ball_v.global_position, "ball_layer": ball_v.get("collision_layer"), "placed": p.hand.placed.size(), "ray_hit": _ray_name(rig.get_node("RightHand")), "ctrl": rig.get_node("RightHand").global_transform})
	p.take_all_back()
	# X - THE BENCH'S FIRST STAGE (Point One, workbench.json "contact"): no grid - a ball stands where it is let go; the
	# next, let go beside it, snaps against it hub to hub out of the socket that faces it; one dropped onto it sits on
	# top, held by contact (the support graph through touching balls)
	p.hand.stage_override = {"name": "point", "snap": "contact", "grid": 1.0, "grid_y": 1.0}
	p.choose("point")
	for i in 3:
		await get_tree().process_frame
	_hand(3.3);await _ticks(0.2)
	var aim_x: Vector3 = p.hand.placement_at(rig.get_node("RightHand"), 8.0, p._panel_rids()).hit.get("position", Vector3.INF)   # where the wand points (the origin has drifted by now)
	p._on_right_pressed("trigger_click")
	for i in 20:
		await get_tree().physics_frame
	var b1: Node3D = p.hand.placed[-1];var hub_x: float = b1.hub()
	var free_x: bool = absf(b1.global_position.x - aim_x.x) < .02 and absf(b1.global_position.z - aim_x.z) < .02 and is_equal_approx(b1.global_position.y, hub_x) and bool(b1.get("freeze"))
	_hand(3.55);await _ticks(0.2)   # beside it, 25 cm on: within reach, the +X socket faces it
	p._on_right_pressed("trigger_click")
	for i in 20:
		await get_tree().physics_frame
	var b2: Node3D = p.hand.placed[-1]
	var beside: bool = b2 != b1 and absf(b2.global_position.distance_to(b1.global_position) - 2 * hub_x) < .002 and b2.global_position.is_equal_approx(b1.global_position + Vector3.RIGHT * 2 * hub_x) and bool(b2.get("freeze")) and bool(b2.get("supported"))
	# onto the first: the wand straight down over it (through the origin's inverse: the player body has moved the rig)
	_right.set_pose(&"aim", rig.global_transform.affine_inverse() * Transform3D(Basis(Vector3.RIGHT, -PI / 2), b1.global_position + Vector3(0, 0.6, 0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await _ticks(0.3)
	p._on_right_pressed("trigger_click")
	for i in 20:
		await get_tree().physics_frame
	var b3: Node3D = p.hand.placed[-1]
	var stacked_x: bool = b3 != b2 and b3.global_position.is_equal_approx(b1.global_position + Vector3.UP * 2 * hub_x) and bool(b3.get("freeze")) and bool(b3.get("supported"))
	_check(report, "X contact: at the bench's first stage a ball stands where it is let go (under the wand, off any grid), the next snaps against it hub to hub, a third dropped on it sits on top, held by touch", free_x and beside and stacked_x, {"b1": b1.global_position, "b2": b2.global_position, "b3": b3.global_position, "hub": hub_x, "free": free_x, "beside": beside, "on_top": stacked_x, "cfg": p.hand.config_for("point")})
	p.take_all_back()
	# Y - A TALL GRID (vertical 2, horizontal 1): the hang snaps to (1, 2, -2); a ball's grid point rises in twos
	p.hand.stage_override = {"name": "tall", "snap": "grid", "grid": 1.0, "grid_y": 2.0}
	p.choose("crate")
	for i in 3:
		await get_tree().process_frame
	_right.set_pose(&"aim", rig.global_transform.affine_inverse() * Transform3D(Basis(), Vector3(0.6, 1.4, 0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await _ticks(0.3)   # the hang point (0.6, 1.4, -2): x to 1, y to the nearest 2 m - 2, z -2
	p._on_right_pressed("trigger_click")
	for i in 10:
		await get_tree().physics_frame
	var tall: Node3D = p.hand.placed[-1]
	var ball_cfg: Dictionary = p.hand.config_for("point")
	var tall_ok: bool = tall.global_position.is_equal_approx(Vector3(1, 2, -2)) and bool(tall.get("freeze")) and is_equal_approx(float(ball_cfg.get("grid_y", 0)), 2.0) and is_equal_approx(float(ball_cfg.get("grid", 0)), 1.0)
	_check(report, "Y tall grid: with vertical pitch 2 the hung crate snaps to (1, 2, -2); the ball's config carries grid 1, grid_y 2", tall_ok, {"at": tall.global_position, "cfg": ball_cfg})
	p.take_all_back()
	# Z - outside the Void the bench is the default stage: the metre grid, balls onto the grid (as H showed)
	p.hand.stage_override = {}
	var st_z: Dictionary = p.hand.stage();var cfg_z: Dictionary = p.hand.config_for("point")
	_check(report, "Z default: no Void here - the stage is 'metre', snap grid, pitch 1 x 1; the ball's config says so", str(st_z.get("name", "")) == "metre" and str(cfg_z.get("snap_to", "")) == "grid" and is_equal_approx(float(cfg_z.get("grid", 0)), 1.0), {"stage": st_z, "cfg": cfg_z})
	_palm(0.0)
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

## The right hand a metre up at x, aiming level along -Z: 8 m of air, nothing hit; the hang point is (x, 1, -2).
func _hand_level(x: float) -> void:
	_right.set_pose(&"aim", Transform3D(Basis(), Vector3(x, 1.0, 0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func _ray_name(ctrl: Node3D) -> String:
	var q := PhysicsRayQueryParameters3D.create(ctrl.global_position, ctrl.global_position - ctrl.global_basis.z * 8.0, 0xFFFFFFFF & ~((1 << 17) | (1 << 19)))
	var h := get_world_3d().direct_space_state.intersect_ray(q)
	return "%s at %s" % [str(h.collider.name) if not h.is_empty() else "-", str(h.get("position", "-"))]

func _ticks(seconds: float) -> void:
	for i in int(ceil(seconds * Engine.physics_ticks_per_second)):
		await get_tree().physics_frame

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_inventory_prism] %s  %s" % ["ok  " if ok else "FAIL", what])

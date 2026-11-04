extends "res://tools/probes/void_game_probe.gd"
## THE INVENTORY INTERFACE IN THE TOWER (Palle, 2026-11-04): on floor 09 the fire extinguisher stands on its plinth;
## picked up by the desktop hand it is COLLECTED - on the belt, in the hand as a miniature, the example back on its
## plinth - and then the hand places, drags (moves), stacks and takes back copies without holding anything. Run on
## the desktop walker with its DesktopInventory; the aim is a probe node standing in for the crosshair.
## Run: python tools/test_inventory_collect.py
const FLOOR := 9
const Items = preload("res://commons/player/inventory_items.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	Items.collected_path = out.path_join("collected.json")   # a fresh belt, not the person's
	var HandLib = load("res://commons/player/inventory_hand.gd")
	HandLib.keep_default = out.path_join("placed.json")       # and a fresh building site
	if FileAccess.file_exists(HandLib.keep_default): DirAccess.remove_absolute(HandLib.keep_default)
	if FileAccess.file_exists(Items.collected_path): DirAccess.remove_absolute(Items.collected_path)
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = FLOOR
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(150)
	var level: float = float(game.building.spec.levels[FLOOR])
	var ex: Dictionary = game.building.content.exhibits
	var plinth_mount: Node3D = ex.get("%d/association-fire-extinguisher-plinth" % FLOOR)
	var plinth: Node = plinth_mount.get_node_or_null("Artifact") if plinth_mount else null
	var desk: Node = game.get_node_or_null("DesktopInventory")
	check("the extinguisher's plinth stands on floor 09 with a collider, and the desktop has its inventory", plinth != null and not plinth.find_children("*", "StaticBody3D", true, false).is_empty() and desk != null)
	if plinth == null or desk == null: return finish()
	var example: RigidBody3D = plinth.example
	var top: float = level + float(plinth.top)
	# measured on the BUILT plinth, not its variable: a plinth built at its default height buried the example once
	var solid_top := -INF
	for sh in plinth.find_children("*", "CollisionShape3D", true, false):
		solid_top = maxf(solid_top, (sh as Node3D).global_position.y + ((sh as CollisionShape3D).shape as BoxShape3D).size.y * .5)
	var over: float = (example.global_position.y - solid_top) if example else -1.0
	check("the example stands on the built plinth, its base %.3f m over the solid (the cap face is 2 cm over it), the cap at %.2f m" % [over, top - level], example != null and over >= 0.0 and over < .04)
	var hand: Node = desk.hand
	check("before it is picked up the extinguisher is locked and the belt is the empty hand only", not Items.unlocked(Items.item("extinguisher"), null, game) and hand.belt() == [""])
	if DisplayServer.get_name() != "headless": await _shot("plinth.png", example.global_position + Vector3(-.9, .45, 1.3), example.global_position + Vector3(0, -.25, 0))

	# PICK IT UP with the desktop hand, standing in front of it
	var home: Vector3 = example.global_position
	game.place_player(Vector3(home.x - 0.1, level + 0.06, home.z + 0.55)); await frames(20)
	var dp: Node = game.body.desktop_pointer
	dp.cam.look_at(home)
	dp._grab_held(example)
	var by := "desktop hand"
	if not example.is_picked_up() and not Items.is_collected("extinguisher"):
		example.pick_up(dp.grip);by = "pick_up(grip)"
	await frames(30)
	var mini: Node3D = hand.mini_node()
	check("picked up by the desktop hand's own grab (%s): COLLECTED - on the belt, in the hand, its miniature at the view's lower right" % by, by == "desktop hand" and Items.is_collected("extinguisher") and hand.belt() == ["", "extinguisher"] and hand.current == "extinguisher" and mini != null and mini.is_visible_in_tree())
	check("the example is back home on its plinth, at rest, the hand empty again (%.3f m from home, frozen %s, held %s, desktop holds %s)" % [example.global_position.distance_to(home), example.freeze, example.is_picked_up(), str(dp._held)], example.global_position.distance_to(home) < .02 and example.freeze and not example.is_picked_up())
	check("the collected list is written to disk", FileAccess.file_exists(Items.collected_path) and FileAccess.get_file_as_string(Items.collected_path).contains("extinguisher"))

	# SEE: a second example (the oil drum, on its own plinth) - the belt shows three, the drum lit and named, then fades
	var drum_m: Node3D = ex.get("%d/association-oil-drum-plinth" % FLOOR)
	var drum: RigidBody3D = drum_m.get_node("Artifact").example if drum_m else null
	if drum != null:
		game.place_player(Vector3(drum.global_position.x - 0.1, level + 0.06, drum.global_position.z + 0.75)); await frames(20)
		dp.cam.look_at(drum.global_position + Vector3(0, .3, 0)); dp._grab_held(drum)
		if not Items.is_collected("oildrum"): drum.pick_up(dp.grip)
		await frames(10)
	var belt: Node3D = desk.belt
	var w: Dictionary = belt.window() if belt else {}
	var row: Node = belt.get_node_or_null("Row") if belt else null
	var lit: Node = row.get_node_or_null("Slot_%d" % int(w.get("current", -1))) if row else null
	var named: String = str(row.get_node("Name").text) if row and row.has_node("Name") else ""
	if DisplayServer.get_name() != "headless":
		game.camera.make_current(); game.status.hide(); game.notice_time = 0
		if game.desktop_help != null: game.desktop_help.hide()
		await frames(6); await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("belt.png"))
	check("see: after the second pick-up the belt shows %s - the empty hand, the extinguisher, the oil drum lit and named (\"%s\")" % [str(w.get("ids", [])), named], belt != null and belt.showing() and w.get("ids", []) == ["", "extinguisher", "oildrum"] and int(w.current) == 2 and lit != null and lit.find_children("*", "MeshInstance3D", true, false).size() > 1 and named == "OIL DRUM")
	await create_timer(belt.SHOW_FOR + 0.3).timeout
	check("the belt fades after its moment (%.1f s)" % belt.SHOW_FOR, not belt.showing() and not belt.visible)
	hand.set_current("extinguisher")

	# PLACE where the aim points: a probe node stands in for the crosshair
	var aimer := Node3D.new(); game.add_child(aimer)
	desk.wand.setup(hand, aimer, desk._body_rids)
	var a := Vector3(-4.0, level, 4.5)
	_aim(aimer, a)
	await frames(4)
	var ghost_up: bool = desk.wand.ghost != null and desk.wand.ghost.visible and desk.wand.ghost_ok
	var did: String = desk.wand.press(); await frames(60)
	var first: Node3D = hand.placed.back() if not hand.placed.is_empty() else null
	var a_y: float = first.global_position.y if first else 0.0
	check("place: the ghost stands at the aim, the press places one there (%s, %d placed, %.2f m off)" % [did, hand.placed.size(), _flat(first, a)], ghost_up and did == "placed" and hand.placed.size() == 1 and _flat(first, a) < .3)

	# MOVE: the press held on it lifts it, it follows the aim, the release sets it down - the same thing, elsewhere
	_aim(aimer, _centre(first))
	did = desk.wand.press()
	desk.wand.update(true, 0.35)
	var lifted: bool = hand.lifted == first
	var b := Vector3(-4.0, level, 2.5)
	_aim(aimer, b); for i in 5: desk.wand.update(true, 0.016); await frames(1)
	var followed: bool = _flat(first, b) < .35
	var down: String = desk.wand.release()
	await frames(60)
	var stands: float = first.global_position.y - a_y
	check("move: a press held on it lifts it (%s), it follows the aim (%s), the release sets it down there (%s, %.2f m off, at the height it first stood %+.3f m, still one)" % [did, followed, down, _flat(first, b), stands], did == "pending" and lifted and followed and down == "set_down" and hand.placed.size() == 1 and _flat(first, b) < .3 and absf(stands) < .05 and hand.lifted == null)

	# STACK: a TAP on it is not a move - it places another (the negative of the move)
	_aim(aimer, _centre(first))
	did = desk.wand.press(); desk.wand.update(true, 0.05)
	var tap: String = desk.wand.release(); await frames(60)
	check("a tap on a placed thing places one more instead of moving it (%s then %s, %d placed, the first unmoved)" % [did, tap, hand.placed.size()], did == "pending" and tap == "placed" and hand.placed.size() == 2 and _flat(first, b) < .3)
	if DisplayServer.get_name() != "headless": await _shot("placed.png", b + Vector3(-1.6, 1.4, 2.0), b + Vector3(0, .3, 0))

	# TURN: Q three times through the desktop's own key handler turns the ghost 45 degrees; a grid thing takes only quarter turns
	var spot := Vector3(-4.0, level, 0.5)
	_aim(aimer, spot)
	var y0: float = hand.placement_at(aimer, 8.0, []).xform.basis.get_euler().y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for i in 3:
		var key := InputEventKey.new(); key.keycode = KEY_Q; key.pressed = true; desk._unhandled_input(key)
		var up := InputEventKey.new(); up.keycode = KEY_Q; up.pressed = false; desk._unhandled_input(up)
	var y1: float = hand.placement_at(aimer, 8.0, []).xform.basis.get_euler().y
	var turned := rad_to_deg(angle_difference(y0, y1))
	desk.wand.update(true, 0.016)
	var ghost_turn := rad_to_deg(angle_difference(y0, desk.wand.ghost.global_basis.get_euler().y)) if desk.wand.ghost else 0.0
	var grid_turn := rad_to_deg(angle_difference(hand.placement_at(aimer, 8.0, [], "cardboard").xform.basis.get_euler().y, 0.0))
	did = desk.wand.press()
	var turned_one: Node3D = hand.placed.back()
	var kept := rad_to_deg(angle_difference(y0, turned_one.global_basis.get_euler().y)) if turned_one else 0.0   # as placed, before physics
	await frames(60)
	var still_up: float = turned_one.global_basis.y.normalized().dot(Vector3.UP) if turned_one else 0.0
	# a second on: still turned and standing (its physics state once kept the yaw it entered the tree with, and a drop
	# from half its height tipped it - both measured 2026-11-04)
	var later := rad_to_deg(angle_difference(y0, turned_one.global_basis.get_euler().y)) if turned_one else 0.0
	check("turn: Q x3 turns the placement %.0f deg (the ghost %.0f), a grid thing a quarter-turn multiple (%.0f), and the one placed is placed turned (%.0f) and a second later still turned (%.0f) and standing (up %.2f)" % [turned, ghost_turn, grid_turn, kept, later, still_up], absf(absf(turned) - 45.0) < 1.0 and absf(ghost_turn - turned) < 1.0 and is_zero_approx(fposmod(grid_turn + 0.5, 90.0) - 0.5) and absf(kept - turned) < 3.0 and absf(later - turned) < 3.0 and still_up > .98)
	hand.yaw_offset = 0.0

	# TAKE BACK with the grip
	_aim(aimer, _centre(first))
	var before_grip: int = hand.placed.size()
	var took: bool = desk.wand.grip(); await frames(4)
	check("take back: the grip on it removes it (%s, %d left of %d)" % [took, hand.placed.size(), before_grip], took and hand.placed.size() == before_grip - 1)

	# ROLL: a rubber ball carries its own sphere and rolls; the cardboard box (its box) slides and stops - the same push
	hand.collect("rubberball")
	var ball: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(-3.0, level + .12, 3.5)))
	hand.set_current("cardboard")
	var box: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(-3.0, level + .26, 1.5)))
	await frames(40)
	var ball_shape: bool = ball != null and ball.find_children("*", "CollisionShape3D", false, false).any(func(c): return c.shape is SphereShape3D)
	var p_ball: Vector3 = ball.global_position; var p_box: Vector3 = box.global_position
	var b_ball: Basis = ball.global_basis
	(ball as RigidBody3D).linear_velocity = Vector3(1.5, 0, 0); (box as RigidBody3D).linear_velocity = Vector3(1.5, 0, 0)
	await create_timer(0.15).timeout
	var w_ball: float = (ball as RigidBody3D).angular_velocity.length(); var w_box: float = (box as RigidBody3D).angular_velocity.length()
	await create_timer(0.45).timeout
	var d_ball: float = Vector2(ball.global_position.x - p_ball.x, ball.global_position.z - p_ball.z).length()
	var d_box: float = Vector2(box.global_position.x - p_box.x, box.global_position.z - p_box.z).length()
	# spin measured as a speed mid-roll: an angle wraps at a full turn (a 0.69 m roll read 62 degrees)
	check("roll: the rubber ball carries its own sphere and rolls %.2f m (spinning %.1f rad/s); the box, pushed the same, slides %.2f m (%.1f rad/s) and stops" % [d_ball, w_ball, d_box, w_box], ball_shape and d_ball > 1.5 * d_box and d_ball > .4 and w_ball > 5.0 and w_box < 1.0)

	# KEEP WHAT YOU BUILD: the placed things are written; a "restart" (a fresh hand, the old things gone) stands them again.
	# One of them hangs pinned in the air: frozen when kept, it must come back frozen and not wake into a fall.
	hand.set_current("crate")
	var hung: Node3D = hand.spawn_at(Transform3D(Basis(), Vector3(-1.0, level + 2.5, 4.0)))
	hand.pin_node(hung)
	await create_timer(hand.KEEP_EVERY + 0.5).timeout
	var keep: String = hand.keep_path
	var rows: Array = hand.kept_rows()
	var on_disk: Variant = JSON.parse_string(FileAccess.get_file_as_string(keep)) if FileAccess.file_exists(keep) else null
	var written: bool = on_disk is Dictionary and (on_disk.placed as Array).size() == rows.size() and rows.size() >= 3
	check("keep: in the main tower the desktop hand keeps (%s); the file holds the %d placed things" % [keep.get_file(), rows.size()], keep == HandLib.keep_default and written)
	# compared with the FILE, which is what a restart reads (written at the hand's last tick - a ball may still roll after)
	var was: Dictionary = {}
	for r in (on_disk.placed if on_disk is Dictionary else []): was[JSON.stringify(r.at)] = r
	rows = on_disk.placed if on_disk is Dictionary else rows
	hand.keep_path = ""
	for n in hand.placed.duplicate():
		if is_instance_valid(n): n.queue_free()
	hand.placed.clear()
	await frames(4)
	var again: Node = HandLib.new(); again.name = "AfterRestart"; game.add_child(again)
	again.keep_path = keep
	var back_n: int = again.restore_kept()
	var worst := 0.0; var turned_off := 0.0; var all_frozen := true
	for n in again.placed:
		var best := INF; var bb := Basis()
		for k in was:
			var at: Array = was[k].at
			var d: float = n.global_position.distance_to(Vector3(at[0], at[1], at[2]))
			if d < best: best = d; var bv: Array = was[k].basis; bb = Basis(Vector3(bv[0], bv[1], bv[2]), Vector3(bv[3], bv[4], bv[5]), Vector3(bv[6], bv[7], bv[8]))
		worst = maxf(worst, best)
		turned_off = maxf(turned_off, rad_to_deg(bb.get_rotation_quaternion().angle_to(n.global_basis.orthonormalized().get_rotation_quaternion())))
		all_frozen = all_frozen and bool(n.get("freeze"))
	check("restart: %d of %d stood again where they were (worst %.3f m, %.1f deg), all frozen at first" % [back_n, rows.size(), worst, turned_off], back_n == rows.size() and worst < .01 and turned_off < 1.0 and all_frozen)
	await create_timer(again.KEEP_EVERY + 0.5).timeout
	var woke := 0; var to_wake := 0; var drift := 0.0
	for r in rows:
		if not bool(r.frozen): to_wake += 1
	for n in again.placed:
		if not bool(n.get("freeze")): woke += 1
		var at0: Variant = null
		for k in was:
			var at: Array = was[k].at
			if at0 == null or n.global_position.distance_to(Vector3(at[0], at[1], at[2])) < n.global_position.distance_to(at0): at0 = Vector3(at[0], at[1], at[2])
		drift = maxf(drift, n.global_position.distance_to(at0))
	var still_frozen := 0; var were_frozen := 0
	for r in rows:
		if bool(r.frozen): were_frozen += 1
	for n in again.placed:
		if bool(n.get("freeze")) and not n.has_meta("inv_wake"): still_frozen += 1
	check("the ones with gravity woke on their floor (%d of %d), the frozen stayed frozen in the air (%d of %d), nothing moved off (%.3f m)" % [woke, to_wake, still_frozen, were_frozen, drift], woke == to_wake and were_frozen >= 1 and still_frozen == were_frozen and drift < .05)
	var gone: Node3D = again.remove_last(); var took_one: bool = gone != null   # read now: it is freed in a frame
	await frames(2)
	again.save_kept()
	var after: Variant = JSON.parse_string(FileAccess.get_file_as_string(keep))
	var nobody: Node = HandLib.new(); game.add_child(nobody)
	check("taken back, it leaves the file (%d rows); a hand that keeps nothing writes nothing (%s)" % [(after.placed as Array).size() if after is Dictionary else -1, nobody.save_kept()], after is Dictionary and (after.placed as Array).size() == rows.size() - 1 and took_one and not nobody.save_kept())
	again.keep_path = ""

	# THE FLOOR'S SLEEP: a box set on a work of floor 09 (its collider is the floor's content, not the slab). Walking away to
	# floor 05 puts floor 09 to sleep and REMOVES that collider: the box must stay where it is, frozen; back on 09, a body.
	var space := game.get_world_3d().direct_space_state
	var work_top := {}
	for gx in range(-16, 17, 2):
		for gz in range(-6, 7, 2):
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(gx, level + 3.0, gz), Vector3(gx, level - .5, gz)))
			if hit.is_empty() or hit.normal.y < .95 or hit.position.y < level + .15 or hit.position.y > level + 1.2: continue
			if not str(hit.collider.get_path()).contains("/Content%d/" % FLOOR): continue
			work_top = hit; break
		if not work_top.is_empty(): break
	var sleeper: Node3D = null
	if not work_top.is_empty():
		hand.set_current("cardboard")
		sleeper = hand.spawn_at(Transform3D(Basis(), work_top.position + Vector3(0, .3, 0)))
		await frames(60)
	var y_rest: float = sleeper.global_position.y if sleeper else 0.0
	game.place_player(game.spawn_for(5)); await create_timer(1.2).timeout
	var down_q := PhysicsRayQueryParameters3D.create(Vector3(work_top.position.x, level + 3.0, work_top.position.z), Vector3(work_top.position.x, level - .5, work_top.position.z)) if not work_top.is_empty() else null
	if down_q != null and sleeper != null: down_q.exclude = [(sleeper as RigidBody3D).get_rid()]   # past the box, to the work
	var probe_down: Dictionary = space.intersect_ray(down_q) if down_q != null else {}
	var support_gone: bool = not work_top.is_empty() and (probe_down.is_empty() or probe_down.position.y < work_top.position.y - .05)
	var held_still: bool = sleeper != null and absf(sleeper.global_position.y - y_rest) < .02 and sleeper.freeze and sleeper.has_meta("inv_slept")
	var rec: Variant = game.floor_stream.records.get(FLOOR) if game.floor_stream else null
	check("sleep: floor 09 asleep (%s), the work under the box loses its collider (%s), the box stays frozen where it stood (%+.3f m)" % [str(rec.mode) if rec else "?", support_gone, (sleeper.global_position.y - y_rest) if sleeper else 0.0], sleeper != null and rec != null and str(rec.mode) == "sleep" and support_gone and held_still)
	game.place_player(Vector3(-4.0, level + 0.06, -4.0)); await create_timer(1.5).timeout
	var woke_up: bool = sleeper != null and not sleeper.freeze and not sleeper.has_meta("inv_slept") and absf(sleeper.global_position.y - y_rest) < .03
	check("wake: back on floor 09 the box is a body again, still on its work (%+.3f m)" % ((sleeper.global_position.y - y_rest) if sleeper else 0.0), woke_up)

	# THE BELT: one step to the empty hand (no ghost, the hand free), one step back
	hand.set_current("rubberball")   # the last on the belt now: empty hand, extinguisher, oil drum, rubber ball
	var to_empty: String = hand.cycle(1); desk.wand.update(true, 0.016)
	var free: bool = to_empty == "" and not desk.wand.placing() and (desk.wand.ghost == null or not desk.wand.ghost.visible) and hand.mini_node() == null
	var back: String = hand.cycle(1)
	check("the belt: from the rubber ball (the last) a step gives the empty hand (nothing shown, the hand free), the next the extinguisher", free and back == "extinguisher")
	# NEGATIVE: an example not picked up stays locked
	hand.set_current("tincan")
	check("an item whose example was not picked up stays locked (tin can refused: hand holds %s)" % hand.current, hand.current == "extinguisher" and not Items.unlocked(Items.item("tincan"), null, game))
	finish()

func _aim(aimer: Node3D, at: Vector3) -> void:
	aimer.global_position = at + Vector3(0.05, 1.6, 0.05)   # from above: nothing of the hall between the aim and the floor
	aimer.look_at(at)

## A placed thing's middle: its first collision shape (the carrier's box sits on the work's centre, not its base).
func _centre(n: Node3D) -> Vector3:
	var shapes := n.find_children("*", "CollisionShape3D", false, false)
	return (shapes[0] as Node3D).global_position if not shapes.is_empty() else n.global_position + Vector3(0, .3, 0)

func _flat(n: Node3D, p: Vector3) -> float:
	return Vector2(n.global_position.x - p.x, n.global_position.z - p.z).length() if is_instance_valid(n) else 99.0

func _shot(name: String, from: Vector3, at: Vector3) -> void:
	var camera := Camera3D.new(); game.add_child(camera); camera.fov = 55; camera.environment = game.atmosphere.environment
	camera.global_position = from; camera.look_at(at); camera.make_current()
	game.status.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name))
	camera.queue_free(); game.camera.make_current()

func finish() -> void:
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[inventory_collect] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)

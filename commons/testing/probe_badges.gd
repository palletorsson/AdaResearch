extends Node3D
## THE BADGE COINS, PROVED WITH NUMBERS (2026-11-17). A bench (a slab high over the tower) and the real Trans_Pre floor.
##   path     the coin path loads (a fixture until tools/badge_coins.ts writes commons/data/badges/path.json)
##   keep     a collect is kept in a file (ada_run/badges/, never the game's user://) and survives a reload, in the
##            order collected (newest last: last_collected()), and every new collect calls the group badge_listeners
##   can      a verb is locked until its coin is collected
##   pick     the wand's hold on a placed thing does not lift it without PICK (a tap still places onto it); with it, lifts
##   rotate   the turn is not applied without ROTATE; with it, it is
##   G        pushes / pulls a placed thing 5 cm on the view's world axis; a lifted one takes it as an offset
##   Z        10 % bigger (the visual AND the collider), within 0.5x..2x; the kept row (placed.json) carries it and a
##            restore stands it at that size; a clock keeps its item scale (0.48) under it
##   VR       the right stick is taken (MovementDirect/MovementTurn disabled) only while something is lifted and a stick
##            verb is collected, and given back exactly
##   floor    on Trans_Pre the layer stands the four coins where still/rise/turn/swell stood and those works are not
##            stood; with an empty path (the negative control) the works stand and no coin does
##   walk     a player body walking into a coin collects it (notice, collation shown); a world body does not; a collected
##            coin is never stood again
##   view     the collation lists every coin and counts the collected ones; it is a Control a board can host as a tab
## Pictures: the four coins on Trans_Pre, close-ups, the collation with two collected (in view, and as a board tab).
## Run (a window, it renders):
##   python tools/godot_watchdog.py --expect=ada_run/badges/run --grace=120 --stall=40 -- <godot> --path <ABS repo>
##       --xr-mode off --resolution 1280x800 res://commons/testing/probe_badges.tscn -- --badges-path=<fixture path.json>
##       [--out=res://ada_run/badges/run] [--break=pick]   (--break=pick grants PICK early: that check must FAIL)

const Badges := preload("res://commons/player/badges.gd")
const Verbs := preload("res://commons/player/badge_verbs.gd")
const CoinLib := preload("res://commons/void/badge_coin.gd")
const HandLib := preload("res://commons/player/inventory_hand.gd")
const WandLib := preload("res://commons/player/inventory_wand.gd")
const Collision := preload("res://commons/player/inventory_collision.gd")
const Source := preload("res://commons/void/room_source.gd")
const REAL_PATH := "res://commons/data/badges/path.json"
const BENCH_Y := 300.0

var out := "res://ada_run/badges/run"
var path_arg := ""
var breaks := ""
var report := {"checks": [], "observations": {}, "shots": []}
var verbs: Node
var hand: Node
var wand: Node3D
var eye: Camera3D
var shot_cam: Camera3D
var user_badges_before := false

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):out = a.trim_prefix("--out=")
		elif a.begins_with("--badges-path="):path_arg = a.trim_prefix("--badges-path=")
		elif a.begins_with("--break="):breaks = a.trim_prefix("--break=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	_run.call_deferred()

func _run() -> void:
	get_window().size = Vector2i(1280, 800)
	Badges.path_file = path_arg if path_arg != "" else REAL_PATH
	Badges.collected_file = out.path_join("collected.json")   # ada_run, never the game's user://badges
	Badges.grant_all = false
	user_badges_before = DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://badges"))
	report.observations["path_file"] = Badges.path_file
	report.observations["collected_file"] = ProjectSettings.globalize_path(Badges.collected_file)
	print("[probe_badges] args=%s path=%s collected=%s" % [OS.get_cmdline_user_args(), Badges.path_file, report.observations.collected_file])
	# isolation BEFORE any write: a probe must never write the game's user://badges
	if not report.observations.collected_file.begins_with(ProjectSettings.globalize_path("res://ada_run")):
		_check("isolation: the collected file is under ada_run (never the game's user://)", false, {"collected_file": report.observations.collected_file});_finish();return
	Badges.reread();Badges.forget_all()
	_environment()
	verbs = Verbs.new();verbs.name = "ProbeVerbs";add_child(verbs)
	await _path_and_keep()
	if "--only=path" in OS.get_cmdline_user_args():_finish();return
	await _bench()
	await _tower()
	_real_path()
	_finish()

# -- PATH, KEEP, CAN ---------------------------------------------------------------------------------------------------

func _path_and_keep() -> void:
	var list := Badges.coins()
	var ordered := true
	for i in range(1, list.size()):ordered = ordered and float(list[i].n) > float(list[i - 1].n)
	var faces := list.all(func(c):return Badges.texture(str(c.id), "face") != null and Badges.texture(str(c.id), "back") != null)
	_check("path: the coin path loads, in number order, every face and back SVG draws", list.size() >= 1 and ordered and faces and Badges.data().get("verbs") is Dictionary,
		{"count": list.size(), "ids": list.map(func(c):return c.id), "face_px": Badges.texture(str(list[0].id)).get_width() if not list.is_empty() and Badges.texture(str(list[0].id)) != null else 0})
	var was := Badges.can("pick")
	Badges.collect("pick")
	var now := Badges.can("pick")
	var other := Badges.can("rotate")
	_check("can: pick is locked, then given by its coin; rotate stays locked", not was and now and not other, {"before": was, "after": now, "rotate": other})
	var abs_path := ProjectSettings.globalize_path(Badges.collected_file)
	var text := FileAccess.get_file_as_string(abs_path)
	Badges.reread()   # forget what is in memory: only the file remains
	_check("keep: the collect is in the file and survives a reload", text.contains("\"pick\"") and Badges.has("pick") and not FileAccess.file_exists(abs_path + ".tmp"), {"file": abs_path, "text": text.strip_edges()})
	Badges.forget_all()
	_check("keep: forgetting writes the file empty again", not Badges.has("pick") and not FileAccess.get_file_as_string(abs_path).contains("\"pick\""), {})
	# the order of collecting (newest last) and the listeners' hook (the t-shirt wears the last badge)
	var listener := Node.new();listener.name = "ProbeListener"
	listener.set_script(_script("extends Node
var heard: Array = []
func badge_collected(id: String) -> void:
	heard.append(id)
"))
	listener.add_to_group("badge_listeners");add_child(listener)
	Badges.collect("translate");Badges.collect("pick");Badges.collect("translate")   # the second translate is not new
	Badges.reread()
	var order := Badges.collect_order()
	_check("order: collected.json keeps the order of collecting, newest last, through a reload; last_collected() is the newest", order == ["translate", "pick"] and str(Badges.last_collected().get("id", "")) == "pick", {"order": order, "last": Badges.last_collected().get("id", null)})
	_check("listeners: every NEW collect calls badge_collected(id) on the group badge_listeners (a repeat does not)", listener.heard == ["translate", "pick"], {"heard": listener.heard})
	listener.queue_free()
	Badges.forget_all()
	await get_tree().process_frame

# -- THE BENCH: THE VERBS ON PLACED THINGS ------------------------------------------------------------------------------

func _bench() -> void:
	var bench := Node3D.new();bench.name = "Bench";bench.position = Vector3(0, BENCH_Y, 0);add_child(bench)
	_slab(bench, "Floor", Vector3(12, .1, 12), Vector3(0, -.05, 0), Color("8f8a84"))
	hand = HandLib.new();hand.name = "InventoryHand";add_child(hand);hand.add_to_group("inventory_hands")   # as the desktop's and the prism's hands are
	eye = Camera3D.new();eye.name = "Eye";bench.add_child(eye);eye.position = Vector3(0, 1.2, 0)
	wand = WandLib.new();wand.name = "Wand";add_child(wand);wand.setup(hand, eye)
	var stub := _stub(hand, wand, eye)
	for i in 4:await get_tree().physics_frame
	var box: Node3D = hand.spawn_at(Transform3D(Basis(), bench.to_global(Vector3(0, .6, -2))), "woodenbox")
	if box == null:
		_check("bench: a wooden box can be placed (precondition)", false, {});return
	await _put(box, bench.to_global(Vector3(0, .6, -2)))
	_aim(eye, box)
	await _frames(3)
	report.observations["pointed_is_box"] = hand.pointed_own(eye, 8.0, []) == box
	# PICK, locked
	Badges.forget_all();Verbs._said.clear()
	if breaks == "pick":Badges.collect("pick")   # sabotage: the next check must fail
	var pressed: String = wand.press()
	wand.update(true, .35)
	var lifted_locked: bool = is_instance_valid(hand.lifted)
	var after_hold: String = wand.release()
	_check("pick locked: the trigger held on a placed thing does not lift it, and the notice names its coin", pressed == "pending" and not lifted_locked and after_hold == "" and Verbs.last_said.contains("PICK IS LOCKED"),
		{"press": pressed, "lifted": lifted_locked, "release": after_hold, "notice": Verbs.last_said})
	if lifted_locked:wand.release()
	# a tap still places onto it
	hand.current = "woodenbox"
	var count0: int = hand.placed.size()
	var tap_press: String = wand.press()
	var tap: String = wand.release()
	var count1: int = hand.placed.size()
	_check("pick locked: a TAP on a placed thing still places onto it", tap_press == "pending" and tap == "placed" and count1 == count0 + 1, {"press": tap_press, "release": tap, "placed": [count0, count1]})
	if count1 > count0:hand.remove_last()
	hand.current = ""
	await _frames(2)
	# PICK, collected
	Badges.collect("pick")
	pressed = wand.press()
	wand.update(true, .35)
	var lifted_now: bool = hand.lifted == box
	_check("pick: with its coin the held trigger lifts the placed thing", pressed == "pending" and lifted_now, {"press": pressed, "lifted": lifted_now})
	# TRANSLATE on the lifted thing: an offset to where the wand puts it
	Badges.collect("translate")
	var at1: Dictionary = hand.lifted_placement(eye, 8.0, [])
	var did_lifted: String = verbs.desktop_key(stub, KEY_G, false)
	var at2: Dictionary = hand.lifted_placement(eye, 8.0, [])
	var nudge: Vector3 = (at2.xform.origin - at1.xform.origin) if at1.ok and at2.ok else Vector3.INF
	_check("translate on a lifted thing: G moves where it will be set down 5 cm along -Z", did_lifted == "lifted" and nudge.is_equal_approx(Vector3(0, 0, -.05)), {"did": did_lifted, "offset": _v(nudge)})
	wand.release()
	await _frames(3)
	_check("translate on a lifted thing: the offset is forgotten once it is set down", not is_instance_valid(hand.lifted) and not box.has_meta("badge_nudge"), {"lifted": is_instance_valid(hand.lifted), "meta": box.has_meta("badge_nudge")})
	Badges.forget_all()
	await _put(box, bench.to_global(Vector3(0, .6, -2)))
	_aim(eye, box)
	await _frames(2)
	# ROTATE
	var floor_eye := Camera3D.new();floor_eye.name = "FloorEye";bench.add_child(floor_eye)
	floor_eye.position = Vector3(3, 1.2, 0);floor_eye.look_at(bench.to_global(Vector3(3, 0, -2.5)))
	hand.current = "crate"
	var turn_off := _turn_of(floor_eye)
	Verbs._said.clear()
	var gate: bool = Verbs.locked("rotate")
	var gate_said: String = Verbs.last_said
	Badges.collect("rotate")
	var turn_on := _turn_of(floor_eye)
	hand.yaw_offset = 0.0;hand.current = ""
	_check("rotate locked: a 90 degree turn asked for is not applied", turn_off.ok and absf(turn_off.diff) < .01, turn_off)
	_check("rotate locked: the gate Q/E and the wrist twist call says so", gate and gate_said.contains("ROTATE IS LOCKED"), {"notice": gate_said})
	_check("rotate: with its coin the turn is applied (90 degrees)", turn_on.ok and absf(absf(turn_on.diff) - PI / 2) < .01, turn_on)
	# TRANSLATE on a placed thing
	Verbs._said.clear()
	var p0 := box.global_position
	var g_locked: String = verbs.desktop_key(stub, KEY_G, false)
	_check("translate locked: G does not move it and says where its coin is", g_locked == "locked" and box.global_position.is_equal_approx(p0) and Verbs.last_said.contains("TRANSLATE IS LOCKED"), {"did": g_locked, "notice": Verbs.last_said})
	Badges.collect("translate")
	var g: String = verbs.desktop_key(stub, KEY_G, false)
	var moved := box.global_position - p0
	var g_said: String = Verbs.last_said
	var sg: String = verbs.desktop_key(stub, KEY_G, true)
	var back := box.global_position - p0
	_check("translate: G pushes the pointed placed thing 5 cm along the view's world axis (-Z), Shift+G pulls it back", g == "moved" and moved.is_equal_approx(Vector3(0, 0, -.05)) and sg == "moved" and back.length() < .0005,
		{"push": _v(moved), "after_pull": _v(back), "notice": g_said})
	# a resting body pushed settles where it was pushed
	var loose: Node3D = hand.spawn_at(Transform3D(Basis(), bench.to_global(Vector3(-2.2, .7, -2))), "cardboard")   # not the wooden box: its work carries a collider the carrier keeps pushing itself off (it drifts ~5 m/s, measured)
	if loose != null:
		if loose.has_method("settle"):loose.settle()
		var fall: Array = []
		for i in 90:
			await get_tree().physics_frame
			if i % 10 == 0:fall.append([i, _v(loose.global_position - bench.global_position), _v((loose as RigidBody3D).linear_velocity)])
		report.observations["loose_fall"] = fall
		var rest := loose.global_position
		var how_before := str(loose.get("how"))
		_aim(eye, loose);await _frames(2)
		var ax := Verbs.axis(eye)
		var track: Array = [_v(loose.global_position)]
		var lg: String = verbs.desktop_key(stub, KEY_G, false)
		track.append(_v(loose.global_position))
		for i in 60:
			await get_tree().physics_frame
			if i % 15 == 14:track.append(_v(loose.global_position))
		var shift := loose.global_position - rest
		report.observations["loose_push"] = {"did": lg, "axis": _v(ax), "shift": _v(shift), "how": [how_before, str(loose.get("how"))], "track": track}
		# the cardboard box is a grid thing: at rest the sand-block rule made it a block on its metre point, so a push
		# steps one bench pitch (a 5 cm push would be pulled straight back to the same point by that rule)
		var pitch := 1.0
		var pv: Variant = loose.get("pitch")
		if pv is Vector2:
			var pv2: Vector2 = pv
			pitch = pv2.x
		var step := pitch if how_before == "block" else .05
		_check("translate: a grid block at rest is pushed one bench pitch along the view's axis and is a block again there (its rule)", lg == "moved" and (shift - ax * step).length() < .015 and str(loose.get("how")) == ("block" if how_before == "block" else str(loose.get("how"))), {"did": lg, "axis": _v(ax), "how_before": how_before, "step": step, "shift": _v(shift)})
		_aim(eye, box);await _frames(2)
	# SCALE
	var vis0 := Collision.mesh_bounds(box, box).size
	var col0 := _collider_size(box)
	var low0 := _low(box)
	Verbs._said.clear()
	var z_locked: String = verbs.desktop_key(stub, KEY_Z, false)
	_check("scale locked: Z does not change it and says where its coin is", z_locked == "locked" and Collision.mesh_bounds(box, box).size.is_equal_approx(vis0) and Verbs.last_said.contains("SCALE IS LOCKED"), {"did": z_locked, "notice": Verbs.last_said})
	Badges.collect("scale")
	var z: String = verbs.desktop_key(stub, KEY_Z, false)
	await get_tree().physics_frame
	var vis1 := Collision.mesh_bounds(box, box).size
	var col1 := _collider_size(box)
	var rv := vis1.x / vis0.x;var rc := col1.x / col0.x
	_check("scale: Z makes the pointed placed thing 10 % bigger - its visual AND its collider - standing where it stood", z == "scaled" and absf(rv - 1.1) < .002 and absf(rc - 1.1) < .002 and absf(vis1.y / vis0.y - 1.1) < .002 and absf(_low(box) - low0) < .002 and is_equal_approx(float(box.get_meta("inv_scale", 0.0)), 1.1),
		{"did": z, "visual": [_v(vis0), _v(vis1)], "collider": [_v(col0), _v(col1)], "bottom": [snappedf(low0, .0001), snappedf(_low(box), .0001)], "inv_scale": box.get_meta("inv_scale", null)})
	# the copies' multimesh draws it at that size too
	await _frames(2)   # physics_frame fires BEFORE _physics_process: the instancer follows a frame later
	var inst := _instance_scale(box)
	_check("scale: the inventory's shared multimesh draws the copy at the new size", inst > 0.0 and absf(inst - 1.1) < .002, {"instance_scale": snappedf(inst, .0001)})
	verbs.desktop_key(stub, KEY_Z, true)
	await get_tree().physics_frame
	var r1 := Collision.mesh_bounds(box, box).size.x / vis0.x
	var meta_after_shift := box.has_meta("inv_scale")
	_check("scale: Shift+Z makes it 10 % smaller - here back to the size it was made at", absf(r1 - 1.0) < .002 and not meta_after_shift, {"after_shift_z": snappedf(r1, .0001), "meta_left": meta_after_shift})
	var dids: Array = []
	for i in 12:dids.append(verbs.desktop_key(stub, KEY_Z, false))
	var top := float(box.get_meta("inv_scale", 1.0))
	var big := Collision.mesh_bounds(box, box).size.x / vis0.x
	for i in 18:dids.append(verbs.desktop_key(stub, KEY_Z, true))
	var bottom_scale := float(box.get_meta("inv_scale", 1.0))
	_check("scale: never past 2x, nor under 0.5x, the size it was made at", is_equal_approx(top, 2.0) and absf(big - 2.0) < .003 and is_equal_approx(bottom_scale, .5) and dids[-1] == "limit", {"top": top, "visual_ratio": snappedf(big, .0001), "bottom": bottom_scale, "last": dids[-1]})
	Verbs.apply_scale(box, 1.1)
	await get_tree().physics_frame
	# the clock: its own item scale (0.48) under the factor
	var clock: Node3D = hand.spawn_at(Transform3D(Basis(), bench.to_global(Vector3(2, 1.5, -3))), "clock")
	if clock != null:
		hand.pin_node(clock)
		var c0 := Collision.mesh_bounds(clock, clock).size
		Verbs.apply_scale(clock, 1.1)
		await get_tree().physics_frame
		var c1 := Collision.mesh_bounds(clock, clock).size
		var ws: float = (clock.get("work") as Node3D).scale.x
		_check("scale: an item with its own scale (the clock, 0.48) is scaled from that size", absf(ws - .48 * 1.1) < .0005 and absf(c1.x / c0.x - 1.1) < .002, {"work_scale": snappedf(ws, .0001), "ratio": snappedf(c1.x / c0.x, .0001)})
	# KEPT: placed.json carries the size, and a restore stands it at that size
	hand.keep_path = out.path_join("placed.json")
	hand.save_kept(true)
	var kept: Variant = JSON.parse_string(FileAccess.get_file_as_string(hand.keep_path))
	var row_scale := -1.0
	if kept is Dictionary:
		for row in kept.placed:
			if str(row.item) == "woodenbox" and row.has("scale"):row_scale = float(row.scale)
	_check("kept: the placed.json row of the scaled thing carries its size", is_equal_approx(row_scale, 1.1), {"file": ProjectSettings.globalize_path(hand.keep_path), "scale": row_scale})
	var again: Node = HandLib.new();again.name = "RestoredHand";add_child(again)
	again.keep_path = hand.keep_path
	var made: int = again.restore_kept()
	await get_tree().physics_frame
	var restored: Node3D = null
	for n in again.placed:
		if str(n.get_meta("inv_item", "")) == "woodenbox" and n.has_meta("inv_scale"):restored = n
	var rs := Collision.mesh_bounds(restored, restored).size.x / vis0.x if restored != null else 0.0
	_check("kept: a restart stands it again at that size (visual and collider)", restored != null and absf(rs - 1.1) < .002 and absf(_collider_size(restored).x / col0.x - 1.1) < .002, {"made": made, "ratio": snappedf(rs, .0001)})
	again.keep_path = ""
	while again.remove_last() != null:pass
	hand.keep_path = ""
	# VR: the right stick is the verbs' only while something is lifted
	await _vr_stick(box, bench)
	hand.yaw_offset = 0.0

func _turn_of(cam: Camera3D) -> Dictionary:
	hand.yaw_offset = 0.0
	var a0: Dictionary = hand.placement_at(cam, 8.0, [])
	hand.yaw_offset = 90.0
	var a90: Dictionary = hand.placement_at(cam, 8.0, [])
	var d := angle_difference(Basis(a0.xform.basis).get_euler().y, Basis(a90.xform.basis).get_euler().y) if a0.ok and a90.ok else INF
	return {"ok": a0.ok and a90.ok, "diff": d, "reason": [a0.reason, a90.reason]}

func _vr_stick(box: Node3D, bench: Node3D) -> void:
	var right := XRController3D.new();right.name = "FakeRight";bench.add_child(right)
	right.position = eye.position;right.transform.basis = eye.transform.basis
	var shell := Node3D.new();shell.name = "XRToolsCollisionHand";right.add_child(shell)
	var provider_src := _script("extends Node\nvar enabled := true\n")
	var direct := Node.new();direct.set_script(provider_src);direct.name = "MovementDirect";shell.add_child(direct)
	var turn := Node.new();turn.set_script(provider_src);turn.name = "MovementTurn";shell.add_child(turn)
	var prism := Node.new();prism.set_script(_script("extends Node\nvar hand\nvar right\nvar left\nvar showing := false\n"));prism.name = "FakePrism";add_child(prism)
	prism.hand = hand;prism.right = right
	verbs.prism = prism
	await _frames(3)
	var idle: bool = direct.enabled and turn.enabled and not verbs.taken()
	Badges.forget_all();Badges.collect("pick")   # pick only: lifting is possible, no stick verb
	wand.press();wand.update(true, .35)
	await _frames(3)
	var lifted_a: bool = is_instance_valid(hand.lifted)
	var untouched: bool = direct.enabled and turn.enabled and not verbs.taken()
	wand.release();await _frames(2)
	Badges.collect("translate");Badges.collect("scale")
	await _put(box, box.global_position)
	wand.press();wand.update(true, .35)
	await _frames(3)
	var lifted_b: bool = is_instance_valid(hand.lifted)
	var taken: bool = not direct.enabled and not turn.enabled and verbs.taken()
	wand.release();await _frames(3)
	var given: bool = direct.enabled and turn.enabled and not verbs.taken()
	_check("VR stick: walking and turning are left alone with nothing lifted, and while lifting without a stick verb", idle and lifted_a and untouched, {"idle": idle, "lifted": lifted_a, "untouched": untouched})
	_check("VR stick: lifted with translate/scale collected, the right stick's walk and turn are taken, and given back when set down", lifted_b and taken and given, {"lifted": lifted_b, "taken": taken, "given_back": given})
	verbs.prism = null
	prism.queue_free();right.queue_free()

# -- THE TOWER: TRANS_PRE ----------------------------------------------------------------------------------------------

func _tower() -> void:
	Source.use_main_tower = true
	Badges.forget_all()
	var fixture := Badges.path_file
	Badges.path_file = fixture.get_base_dir().path_join("empty_path.json") if FileAccess.file_exists(fixture.get_base_dir().path_join("empty_path.json")) else "res://ada_run/badges/__none__.json"
	Badges.reread()
	_progress("building the tower")
	var building: Node3D = load("res://commons/void/architecture.gd").new();building.name = "Building";building.stream_content = true;add_child(building)
	await _frames(2)
	var content: Node3D = building.content
	var idx := -1
	for i in content.data.floors.size():
		if str(content.data.floors[i].map) == "Trans_Pre":idx = i
	var works := ["still", "rise", "turn", "swell"]
	content.load_floor(idx)
	await _frames(6)
	var root: Node3D = content.roots[idx]
	var stood_ctrl: Array = works.filter(func(w):return content.exhibits.has("%d/%s" % [idx, w]))
	_check("floor (negative control): with no coin on the path the works still/rise/turn/swell stand and no coin does", stood_ctrl.size() == 4 and root.get_node_or_null("BadgeCoins") == null, {"floor": idx, "stood": stood_ctrl})
	content.reset_floor(idx)
	Badges.path_file = fixture;Badges.reread()
	content.load_floor(idx)
	await _frames(6)
	root = content.roots[idx]
	var holder := root.get_node_or_null("BadgeCoins")
	var stood: Array = works.filter(func(w):return content.exhibits.has("%d/%s" % [idx, w]))
	var coins: Array = holder.get_children() if holder != null else []
	var expect: Array = Badges.coins_on(idx, "Trans_Pre")
	var placed_right := true
	var rows: Array = []
	var rooms: Dictionary = content.data.floors[idx]
	for c in coins:
		var coin := Badges.coin(str(c.get("coin_id")))
		var want := Vector3.INF
		var facing := float(coin.get("facing", 0.0))
		if str(coin.get("replaces", "")) != "":
			for a in rooms.artifacts:
				if str(a.id) == str(coin.replaces):want = Vector3(float(a.position[0]), float(a.height), float(a.position[1]));facing = float(a.get("facing", 0))
		elif coin.get("stand") is Array:
			want = Vector3(float(coin.stand[0]), float(coin.get("y", 0.0)) + 1.1, float(coin.stand[1]))
		placed_right = placed_right and c.position.is_equal_approx(want) and is_equal_approx(c.rotation_degrees.y, facing)
		rows.append({"coin": c.name, "id": coin.get("id"), "replaces": coin.get("replaces", ""), "stop": coin.get("stop", ""), "at": _v(c.position), "want": _v(want)})
	var replacing: Array = expect.filter(func(c):return str(c.get("replaces", "")) in works)
	_check("floor: on Trans_Pre the layer stands this floor's coins - the four badge coins where still/rise/turn/swell stood (position, height, facing), any stop coin over its stand", coins.size() == expect.size() and replacing.size() == 4 and placed_right, {"coins": rows})
	_check("floor: the works still/rise/turn/swell are not stood; the floor's other works are (translation-marker, tape-still)", stood.is_empty() and content.exhibits.has("%d/translation-marker" % idx) and content.exhibits.has("%d/tape-still" % idx), {"stood": stood})
	var shown: Array[int] = [idx];building.show_floor_window(shown)
	var L := root.global_position
	# THE PICTURES: the coins on Trans_Pre
	await _frames(20)
	await _shot("trans_pre_coins_west", L + Vector3(-3.5, 2.9, 3.2), L + Vector3(-3.5, 2.45, 0.5), 62)
	await _shot("trans_pre_coins_east", L + Vector3(3.5, 2.9, 3.2), L + Vector3(3.5, 2.45, 0.5), 62)
	for c in coins:
		var at: Vector3 = (c.get("visual") as Node3D).global_position
		await _shot("coin_%s_%s" % [str(c.name).trim_prefix("Coin_"), str(c.get("coin_id"))], at + Vector3(0, .04, .5), at, 40)
	# THE WALK: a player body into PICK and TRANSLATE, a world body through ROTATE
	var walker := _body("ProbeWalkerPlayer", 1 << 19, true)
	var c1 := _coin_node(holder, "pick");var c2 := _coin_node(holder, "translate");var c3 := _coin_node(holder, "rotate")
	if c1 == null or c2 == null or c3 == null:
		_check("walk: the pick, translate and rotate coins stand on Trans_Pre (precondition)", false, {});return
	await _walk(walker, (c1.get("visual") as Node3D).global_position)
	await _frames(30)
	var got1 := Badges.has("pick")
	var view: Node = get_tree().get_first_node_in_group("badge_views")
	var shown_after: bool = view != null and view.visible
	_check("walk: a player body walking into the PICK coin collects it; it is gone; the collation shows", got1 and not is_instance_valid(c1) and shown_after, {"collected": got1, "freed": not is_instance_valid(c1), "view_shown": shown_after})
	await _walk(walker, (c2.get("visual") as Node3D).global_position)
	await _frames(30)
	var said2: String = CoinLib.last_notice
	var want2 := "COIN %s / TRANSLATE\nmove a thing you placed a little - G pushes, Shift+G pulls" % str(Badges.coin("translate").get("label", ""))
	_check("walk: the TRANSLATE coin's notice says what it gives, in the desktop's words", Badges.has("translate") and said2 == want2, {"notice": said2, "want": want2})
	var crate := _body("Crate", 1, false)
	await _walk(crate, (c3.get("visual") as Node3D).global_position)
	await _frames(10)
	_check("walk: a world body (layer 1, not the player) through the ROTATE coin does not collect it", is_instance_valid(c3) and not Badges.has("rotate"), {"standing": is_instance_valid(c3)})
	walker.queue_free();crate.queue_free()
	content.reset_floor(idx);content.load_floor(idx);await _frames(4)
	var again: Node = (content.roots[idx] as Node).get_node_or_null("BadgeCoins")
	var left: Array = again.get_children().map(func(n):return str(n.get("coin_id"))) if again != null else []
	var want_left: Array = expect.filter(func(c):return not str(c.id) in ["pick", "translate"]).map(func(c):return str(c.id))
	_check("walk: a collected coin is never stood again (the floor rebuilt: the uncollected ones stand)", left == want_left and not left.has("pick") and not left.has("translate"), {"standing": left, "want": want_left})
	# THE COLLATION with two collected
	var panel: Control = view.get("panel") if view != null else null
	if panel != null:panel.refresh()
	var slots: Array = panel.get("slots") if panel != null else []
	var labels: Array = slots.map(func(r):return str(r.label))
	var gots: Array = slots.map(func(r):return bool(r.got))
	var head: String = panel.heading() if panel != null else ""
	var want_labels: Array = Badges.coins().map(func(c):return str(c.get("label", "")))
	var want_got: Array = Badges.coins().map(func(c):return str(c.id) in ["pick", "translate"])
	_check("view: the collation lists every coin in number order and counts the collected ones", slots.size() == Badges.count() and labels == want_labels and gots == want_got and head == "BADGES  2 / %d" % Badges.count(),
		{"labels": labels.slice(0, 12), "got_count": gots.count(true), "heading": head})
	shot_cam.make_current();shot_cam.global_position = L + Vector3(-1.5, 3.0, 6.5);shot_cam.look_at(L + Vector3(0, 2.2, 0.5))
	view.show_for(12.0)
	await _frames(4)
	var overlay_ok: bool = view.get("mode") == "desktop" and (view.get("overlay") as CanvasLayer).visible and (view.get("panel") as Control).get_parent() == view.get("overlay")
	_check("view (desktop): shown as a 2D overlay over the 3D frame", overlay_ok, {"mode": view.get("mode")})
	await _shot("collation_desktop_two_collected", shot_cam.global_position, L + Vector3(0, 2.2, 0.5), 60)
	# VR: the same panel drawn onto a quad in the view (no 2D overlay in a headset)
	view.set("holder_override", shot_cam);view.set("force_mode", "vr");view.show_for(12.0)
	await _frames(4)
	var vq: MeshInstance3D = view.get("quad");var vvp: SubViewport = view.get("viewport")
	var vr_ok: bool = view.get("mode") == "vr" and vq.visible and not (view.get("overlay") as CanvasLayer).visible and (view.get("panel") as Control).get_parent() == vvp and vvp.size.x >= 520 and view.get_parent() == shot_cam
	_check("view (VR): the panel is drawn onto a quad hanging in the view, no 2D overlay", vr_ok, {"viewport": [vvp.size.x, vvp.size.y], "quad": [snappedf((vq.mesh as QuadMesh).size.x, .001), snappedf((vq.mesh as QuadMesh).size.y, .001)]})
	await _shot("collation_vr_quad_two_collected", shot_cam.global_position, L + Vector3(0, 2.2, 0.5), 60)
	view.set("force_mode", "desktop");view.set("holder_override", null)
	# the same panel hosted as a TAB of a 2D board (the coming select board)
	view.set("_left", 0.0);await _frames(2)
	var layer := CanvasLayer.new();layer.name = "BoardStandIn";add_child(layer)
	var tabs := TabContainer.new();tabs.position = Vector2(60, 60);tabs.size = Vector2(1160, 520);layer.add_child(tabs)
	var hand_tab := Label.new();hand_tab.name = "HAND";hand_tab.text = "(the board's other tabs)";tabs.add_child(hand_tab)
	var tab: Control = load("res://commons/player/badges_panel.tscn").instantiate();tab.name = "BADGES";tabs.add_child(tab)
	tabs.current_tab = 1
	await _frames(3)
	var tab_slots: Array = tab.get("slots")
	_check("view: the collation is a self-contained Control a board can host as a tab (it sizes itself, same coins)", tab.custom_minimum_size.x >= 520.0 and tab_slots.size() == Badges.count() and tab.heading() == "BADGES  2 / %d" % Badges.count(), {"min_size": [tab.custom_minimum_size.x, tab.custom_minimum_size.y]})
	await _shot("collation_as_board_tab", shot_cam.global_position, L + Vector3(0, 2.2, 0.5), 60)
	layer.queue_free()

func _real_path() -> void:
	if not FileAccess.file_exists(REAL_PATH):
		report.observations["real_path"] = "absent: %s does not exist yet (tools/badge_coins.ts has not written it)" % REAL_PATH
		return
	Badges.path_file = REAL_PATH;Badges.reread()
	var list := Badges.coins()
	var faces := list.all(func(c):return Badges.texture(str(c.id), "face") != null)
	var on := Badges.coins_on(-1, "Trans_Pre")
	_check("real path.json: it loads, every face draws, the four Trans_Pre coins replace still/rise/turn/swell", list.size() > 0 and faces and Badges.replaced(-1, "Trans_Pre").size() == 4, {"count": list.size(), "trans_pre": on.map(func(c):return [c.get("label"), c.id, c.get("replaces")])})

# -- HELPERS -----------------------------------------------------------------------------------------------------------

func _environment() -> void:
	var env := WorldEnvironment.new();var e := Environment.new()
	e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("e0dad0");e.ambient_light_energy = .7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-38, -25, 0);sun.light_energy = 1.0;add_child(sun)
	shot_cam = Camera3D.new();shot_cam.name = "ShotCam";add_child(shot_cam)

func _stub(p_hand: Node, p_wand: Node, cam: Camera3D) -> Node:
	var s := Node.new();s.set_script(_script("extends Node\nvar hand\nvar wand\nvar camera\n"));s.name = "DesktopInventoryStub";add_child(s)
	s.hand = p_hand;s.wand = p_wand;s.camera = cam
	return s

func _script(src: String) -> GDScript:
	var s := GDScript.new();s.source_code = src;s.reload()
	return s

func _put(n: Node3D, at: Vector3) -> void:
	n.global_transform = Transform3D(Basis(), at)
	if n is RigidBody3D:PhysicsServer3D.body_set_state((n as RigidBody3D).get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, n.global_transform)
	hand.pin_node(n)
	await _frames(2)

func _aim(cam: Camera3D, n: Node3D) -> void:
	var b := n.global_transform * Collision.mesh_bounds(n, n)
	cam.look_at(b.get_center())

func _frames(k: int) -> void:
	for i in k:
		await get_tree().physics_frame;await get_tree().process_frame

func _coin_node(holder: Node, id: String) -> Node3D:
	for c in holder.get_children():
		if str(c.get("coin_id")) == id:return c
	return null

func _collider_size(n: Node3D) -> Vector3:
	var box := AABB();var found := false
	for c in n.get_children():
		if c is CollisionShape3D and c.shape != null and not c.is_queued_for_deletion():
			var b: AABB = c.transform * c.shape.get_debug_mesh().get_aabb()
			box = box.merge(b) if found else b;found = true
	return box.size

func _low(n: Node3D) -> float:
	return (n.global_transform * Collision.mesh_bounds(n, n)).position.y

func _instance_scale(n: Node3D) -> float:
	var art: Node3D = n.get("work")
	var inst: Node = hand.instancer()
	for mmi in inst.get_children():
		if not mmi is MultiMeshInstance3D:continue
		var mm: MultiMesh = mmi.multimesh
		for i in mm.instance_count:
			var t := mm.get_instance_transform(i)
			if t.origin.is_equal_approx(art.global_position):return t.basis.get_scale().x
	return -1.0

func _body(body_name: String, layer: int, player: bool) -> Node3D:
	var b: Node3D
	if player:
		var cb := CharacterBody3D.new();cb.collision_layer = layer;cb.collision_mask = 1;b = cb
		cb.add_to_group("player_body")
		var shape := CollisionShape3D.new();var cap := CapsuleShape3D.new();cap.radius = .3;cap.height = 1.7;shape.shape = cap;cb.add_child(shape)
	else:
		var rb := RigidBody3D.new();rb.collision_layer = layer;rb.collision_mask = 0;rb.freeze = true;rb.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;b = rb
		var shape := CollisionShape3D.new();var box := BoxShape3D.new();box.size = Vector3(.6, .6, .6);shape.shape = box;rb.add_child(shape)
	b.name = body_name
	add_child(b)
	return b

## The body walks from 2 m in front of the coin (+Z) to 1 m behind it, its middle 0.5 m under the coin's centre.
func _walk(b: Node3D, coin_at: Vector3) -> void:
	var from := coin_at + Vector3(0, -.5, 2.0)
	b.global_position = from
	await _frames(2)
	for i in 50:
		b.global_position = from + Vector3(0, 0, -3.0 * float(i + 1) / 50.0)
		await get_tree().physics_frame

func _shot(id: String, at: Vector3, look: Vector3, fov: float) -> void:
	shot_cam.fov = fov;shot_cam.make_current();shot_cam.global_position = at;shot_cam.look_at(look)
	await _frames(4);await RenderingServer.frame_post_draw
	var file := ProjectSettings.globalize_path(out.path_join(id + ".png"))
	get_viewport().get_texture().get_image().save_png(file)
	report.shots.append(file)
	_progress("shot " + id)

func _slab(parent: Node3D, what: String, size: Vector3, at: Vector3, colour: Color) -> void:
	var body := StaticBody3D.new();body.name = what;body.collision_layer = 1;body.position = at;parent.add_child(body)
	var shape := CollisionShape3D.new();var bs := BoxShape3D.new();bs.size = size;shape.shape = bs;body.add_child(shape)
	var m := MeshInstance3D.new();var bm := BoxMesh.new();bm.size = size;m.mesh = bm
	var mat := StandardMaterial3D.new();mat.albedo_color = colour;m.material_override = mat;body.add_child(m)

func _check(what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_badges] %s  %s" % ["ok  " if ok else "FAIL", what])
	_progress(what)

func _progress(what: String) -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path(out.path_join("progress.json")), FileAccess.WRITE)
	if f != null:f.store_string(JSON.stringify({"last": what, "checks": report.checks.size(), "at": Time.get_ticks_msec()}));f.close()

func _finish() -> void:
	var user_now := DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://badges"))
	_check("isolation: the game's user://badges was not written by this probe", user_badges_before or not user_now, {"before": user_badges_before, "after": user_now})
	var passed: int = report.checks.filter(func(c):return c.ok).size()
	report["passed"] = passed;report["of"] = report.checks.size();report["break"] = breaks
	var f := FileAccess.open(ProjectSettings.globalize_path(out.path_join("report.json")), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "));f.close()
	print("[probe_badges] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _v(v: Vector3) -> Array:
	return [snappedf(v.x, .0001), snappedf(v.y, .0001), snappedf(v.z, .0001)] if v.is_finite() else ["inf"]

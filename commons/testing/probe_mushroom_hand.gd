extends SceneTree
## THE TRIGGER, WIRED (2026-08-27, Palle: "yes wire the trigger, refill on
## entering a map, how do I shot in vr and in desktop?").
##
## Six claims, none of which a compile can make:
##   the hand starts with five
##   firing spends one and puts a mushroom in the air
##   the sixth shot fails rather than firing a mushroom that does not exist
##   entering a map refills it
##   dying refills it too (reset_level_state)
##   the DESKTOP key actually reaches the autoload — the half most likely to be
##     silently wrong, because F could be eaten by any handler between the OS
##     and an autoload's _unhandled_input
const TXT := "res://ada_run/mushroom_hand.txt"

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _run() -> void:
	var gm: Node = get_root().get_node_or_null("GameManager")
	var hand: Node = get_root().get_node_or_null("MushroomHand")
	var fails: Array = []
	if gm == null: fails.append("no /root/GameManager")
	if hand == null: fails.append("no /root/MushroomHand — the autoload is not registered")
	if not fails.is_empty():
		for f in fails: _say("FAIL %s" % f)
		var fh0 := FileAccess.open(TXT, FileAccess.WRITE)
		fh0.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh0.close()
		quit(1); return

	# a world with a floor, and an eye to throw from
	var st := Node3D.new(); get_root().add_child(st)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(80, 1.0, 80); cs.shape = bx; cs.position = Vector3(0, -0.5, 0)
	fb.add_child(cs); st.add_child(fb)
	var cam := Camera3D.new(); st.add_child(cam)
	cam.global_position = Vector3(0, 1.6, 4.0)
	cam.look_at(Vector3(0, 0.6, 0), Vector3.UP)
	cam.current = true
	# current_scene is what the hand parents a thrown mushroom to
	current_scene = st        # in a SceneTree script, self IS the tree
	await process_frame

	_say("THE HAND")
	_say("  starts with %d of %d" % [int(gm.get("mushrooms")), int(gm.get("max_mushrooms"))])
	if int(gm.get("mushrooms")) != 5:
		fails.append("does not start with five")

	# ── fire five, one at a time, past the cooldown ───────────────────────
	var thrown := 0
	for i in range(5):
		hand.set("_cool", 0.0)
		if bool(hand.call("fire_from_view")):
			thrown += 1
		await create_timer(0.08).timeout
	_say("  fired five: %d went, %d left" % [thrown, int(gm.get("mushrooms"))])
	if thrown != 5 or int(gm.get("mushrooms")) != 0:
		fails.append("five shots did not empty the hand")

	# ── the sixth must fail ───────────────────────────────────────────────
	hand.set("_cool", 0.0)
	var sixth: bool = bool(hand.call("fire_from_view"))
	_say("  the sixth shot: %s" % ("FIRED — the hand is lying" if sixth else "refused, the hand is empty"))
	if sixth:
		fails.append("fired a sixth mushroom out of an empty hand")

	# ── the cooldown ──────────────────────────────────────────────────────
	gm.call("refill_mushrooms")
	hand.set("_cool", 0.0)
	var a: bool = bool(hand.call("fire_from_view"))
	var b: bool = bool(hand.call("fire_from_view"))     # immediately after
	_say("  cooldown: first %s, immediate second %s" % [str(a), str(b)])
	if not a or b:
		fails.append("the cooldown does not gate")

	# ── they are in the air and then on the floor as bait ─────────────────
	await create_timer(2.5).timeout
	var bait := get_nodes_in_group("spider_bait")
	_say("  %d mushroom(s) landed and joined spider_bait" % bait.size())
	var lows := 0
	for m in bait:
		if absf((m as Node3D).global_position.y) < 0.06: lows += 1
	_say("  %d of them are resting on the floor" % lows)
	if bait.size() < 4:
		fails.append("only %d of the thrown mushrooms became bait" % bait.size())

	# ── entering a map refills ────────────────────────────────────────────
	gm.set("mushrooms", 1)
	gm.call("set_current_map", "Probe_Room_A")
	_say("  after walking into a map: %d of %d" % [int(gm.get("mushrooms")), int(gm.get("max_mushrooms"))])
	if int(gm.get("mushrooms")) != 5:
		fails.append("entering a map did not refill")

	# ── dying refills too ─────────────────────────────────────────────────
	gm.set("mushrooms", 2)
	gm.call("reset_level_state")
	_say("  after a death: %d of %d" % [int(gm.get("mushrooms")), int(gm.get("max_mushrooms"))])
	if int(gm.get("mushrooms")) != 5:
		fails.append("reset_level_state did not refill")

	# ── THE DESKTOP KEY, actually pressed ─────────────────────────────────
	var before: int = int(gm.get("mushrooms"))
	hand.set("_cool", 0.0)
	var ev := InputEventKey.new()
	ev.keycode = KEY_F
	ev.physical_keycode = KEY_F
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	await process_frame
	var after: int = int(gm.get("mushrooms"))
	_say("  pressing F: %d -> %d" % [before, after])
	if after != before - 1:
		fails.append("the F key never reached the hand")

	_say("")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("five, spent, refilled, and F throws one" if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() else 1)

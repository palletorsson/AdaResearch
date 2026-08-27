extends SceneTree
## THE HAND, AND WHY THE MUSHROOM LANDED ON THE WALL (2026-08-27, Palle: "In VR
## if I have a mushroom let me hold one in the hand and a number how many. Now
## it seems that I am throwing backwards and the mushroom ends up on the wall").
##
## Three claims:
##   a controller gets a mushroom at the muzzle and a number beside it, and the
##     number follows the count without anything polling it
##   nothing lands in the first half metre — that is the player's own arm, their
##     controller and whatever they are standing against
##   a wall at throwing distance still stops it
##
## The fourth thing, the delta cap, cannot be provoked here: it needs a frame
## hitch. It is the reason the muzzle exists as well — belt and braces on the
## same failure, which is a mushroom planting where it was born.
const M := "res://commons/artifacts/spore_mushroom/spore_mushroom.tscn"
const TXT := "res://ada_run/vr_hand.txt"

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _wall(st: Node3D, centre: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = size; cs.shape = bx; cs.position = centre
	b.add_child(cs); st.add_child(b)

func _run() -> void:
	var gm: Node = get_root().get_node_or_null("GameManager")
	var hand: Node = get_root().get_node_or_null("MushroomHand")
	var fails: Array = []
	if gm == null or hand == null:
		_say("FAIL no GameManager or no MushroomHand"); quit(1); return

	var st := Node3D.new(); get_root().add_child(st)
	current_scene = st
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(60, 1.0, 60); cs.shape = bx; cs.position = Vector3(0, -0.5, 0)
	fb.add_child(cs); st.add_child(fb)
	gm.call("refill_mushrooms")

	# ── the hand ──────────────────────────────────────────────────────────
	var controller := Node3D.new()
	controller.name = "RightHand"
	st.add_child(controller)
	controller.global_position = Vector3(0, 1.4, 0)
	hand.call("_build_vr_hand", controller)
	await process_frame
	var holder: Node3D = controller.get_node_or_null("MushroomInHand")
	_say("THE HAND")
	_say("  holder: %s" % ("yes" if holder != null else "NO"))
	if holder == null:
		fails.append("no mushroom holder was built on the controller")
	else:
		var held: Node3D = holder.get_node_or_null("Held")
		var lab: Label3D = holder.get_node_or_null("Count")
		_say("  a mushroom in it: %s   a number beside it: %s"
			% [("yes" if held != null else "NO"), ("'" + lab.text + "'" if lab != null else "NO")])
		_say("  it sits %.2f m along the throwing axis" % holder.position.length())
		if held == null: fails.append("nothing held")
		if lab == null:
			fails.append("no count")
		else:
			if lab.text != str(int(gm.get("mushrooms"))):
				fails.append("the number does not match the count")
			# spend one: the number must follow with nothing polling it
			gm.call("spend_mushroom")
			await process_frame
			_say("  after spending one the number reads '%s' (count %d)" % [lab.text, int(gm.get("mushrooms"))])
			if lab.text != str(int(gm.get("mushrooms"))):
				fails.append("the number did not follow the count")
			# and an empty hand holds nothing
			gm.set("mushrooms", 0)
			gm.call("spend_mushroom")
			gm.emit_signal("mushrooms_updated", 0, 5)
			await process_frame
			if held != null and held.visible:
				fails.append("an empty hand is still holding a mushroom")
			else:
				_say("  an empty hand holds nothing, and reads '%s'" % lab.text)
	gm.call("refill_mushrooms")
	_say("")

	# ── the muzzle: a wall right in front of the hand ─────────────────────
	_wall(st, Vector3(0, 1.4, -0.30), Vector3(4, 2.4, 0.1))
	var ps: PackedScene = load(M) as PackedScene
	var near: Node3D = ps.instantiate() as Node3D
	st.add_child(near)
	near.call("launch", Vector3(0, 1.4, 0), Vector3(0, 0, -1), 6.4, 0.5)
	await create_timer(1.6).timeout
	_say("THE MUZZLE — a wall 0.30 m in front of the hand")
	_say("  it came to rest at %s" % str(near.global_position))
	var stuck_on_it: bool = near.global_position.z > -0.45 and near.global_position.y > 0.8
	_say("  planted on that wall: %s" % str(stuck_on_it))
	if stuck_on_it:
		fails.append("it planted inside the first half metre — the muzzle guard is not holding")

	# ── but a wall at throwing distance still stops it ────────────────────
	_wall(st, Vector3(20, 1.4, -3.0), Vector3(6, 3.0, 0.2))
	var far: Node3D = ps.instantiate() as Node3D
	st.add_child(far)
	far.call("launch", Vector3(20, 1.4, 0), Vector3(0, 0, -1), 6.4, 0.5)
	await create_timer(1.6).timeout
	_say("")
	_say("THE WALL AT THROWING DISTANCE — 3 m away")
	_say("  it came to rest at %s" % str(far.global_position))
	var hit_wall: bool = far.global_position.z < -2.5 and far.global_position.y > 0.5
	_say("  stopped by it: %s" % str(hit_wall))
	if not hit_wall:
		fails.append("a wall 3 m away did not stop it — the muzzle is swallowing real hits")

	_say("")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("a mushroom and a number in the hand, and nothing lands at the muzzle"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() else 1)

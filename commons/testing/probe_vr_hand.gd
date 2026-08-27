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
			if lab.visible:
				fails.append("an empty hand is showing a zero")
			if not held.visible and not lab.visible:
				_say("  an empty hand shows nothing at all — no mushroom, no zero")
			# and the held one must never become bait in the visitor's hand
			if held != null and held.is_in_group("spider_bait"):
				fails.append("the mushroom in the hand joined spider_bait")
			else:
				_say("  the held mushroom is not bait")
	gm.call("refill_mushrooms")
	_say("")

	# ── THE AIM: a hand pointing the WRONG WAY must still throw forward ───
	var cam := Camera3D.new()
	st.add_child(cam)
	cam.global_position = Vector3(0, 1.6, 0)
	cam.look_at(Vector3(0, 1.6, -10), Vector3.UP)      # the visitor looks down -Z
	cam.current = true
	# and the controller points the opposite way, which is the reported fault
	controller.rotation = Vector3(0, PI, 0)
	await process_frame
	var aim_head: Vector3 = hand.call("_aim_of", controller)
	hand.set("vr_aim", "hand")
	var aim_hand: Vector3 = hand.call("_aim_of", controller)
	hand.set("vr_aim", "head")
	_say("THE AIM, with the controller turned to face BEHIND the visitor")
	_say("  vr_aim head: %s" % str(aim_head.snapped(Vector3.ONE * 0.01)))
	_say("  vr_aim hand: %s   (this is the one that threw at the wall)" % str(aim_hand.snapped(Vector3.ONE * 0.01)))
	var fwd := -cam.global_transform.basis.z
	if aim_head.dot(fwd) < 0.95:
		fails.append("the head aim does not follow the camera")
	if aim_hand.dot(fwd) > -0.5:
		fails.append("the probe did not actually reverse the controller — it proves nothing")
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

	# ── WALK OVER ONE AND IT IS YOURS ─────────────────────────────────────
	gm.set("mushrooms", 2)
	gm.emit_signal("mushrooms_updated", 2, 5)
	var lying: Node3D = ps.instantiate() as Node3D
	st.add_child(lying)
	lying.global_position = Vector3(-8, 0, 0)
	await create_timer(0.4).timeout
	_say("")
	_say("WALKING OVER ONE")
	_say("  a mushroom placed by a map, not thrown: bait after settling: %s"
		% str(lying.is_in_group("spider_bait")))
	if not lying.is_in_group("spider_bait"):
		fails.append("a placed mushroom never settled — it is scenery")
	var walker := Node3D.new()
	walker.add_to_group("player")
	st.add_child(walker)
	walker.global_position = Vector3(-40, 0.5, 0)      # nowhere near it yet
	await create_timer(1.6).timeout
	var before_pick: int = int(gm.get("mushrooms"))
	walker.global_position = Vector3(-8, 0.5, 0)       # stand on it
	await create_timer(0.8).timeout
	var after_pick: int = int(gm.get("mushrooms"))
	_say("  count %d -> %d, and the mushroom is %s"
		% [before_pick, after_pick, ("gone" if not is_instance_valid(lying) else "still there")])
	if after_pick != before_pick + 1:
		fails.append("walking over it did not pick it up")
	# a full hand must walk straight over one
	gm.call("refill_mushrooms")
	var spare: Node3D = ps.instantiate() as Node3D
	st.add_child(spare)
	spare.global_position = Vector3(-8, 0, 3)
	await create_timer(1.8).timeout
	var full_before: int = int(gm.get("mushrooms"))
	walker.global_position = Vector3(-8, 0.5, 3)
	await create_timer(0.8).timeout
	_say("  with a full hand: %d -> %d, mushroom %s"
		% [full_before, int(gm.get("mushrooms")), ("taken" if not is_instance_valid(spare) else "left where it lies")])
	if not is_instance_valid(spare):
		fails.append("a full hand still picked one up")

	_say("")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("a mushroom and a number in the hand, and nothing lands at the muzzle"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() else 1)

extends SceneTree

## GATE — health_cross's TAKE and DECLINE paths.
##
## This probe used to only PRINT, which is why the enemy bug shipped: every stage
## was green while a head crab was eating the medkit. It now EXITS NON-ZERO on any
## failed case, so it can be run before a commit and believed.
##
##   A  whole visitor        (health == max)     -> declines "not low enough", NOT spent
##   B  hurt visitor         (health == 50)      -> +34, spent
##   D  re-entry while spent                     -> nothing
##   C  enemy body           (group "enemy" only, layer 1, player hurt)
##                                               -> must NOT spend the cross
##   E  lightly hurt visitor (health == 85)      -> declines, NOT spent  [threshold]
##   F  properly hurt        (health == 74)      -> takes, delivered 26  [threshold]
##   G  hurt WHILE STANDING on the pad           -> the 0.5 s re-scan takes it
##
## C is the negative test for the visitor-only acceptance test. E is the negative
## test for take_below: without it a silently-ignored threshold passes every other
## case. G covers the re-scan, which no entry-event test can see.

const CROSS := "res://commons/artifacts/health_cross/health_cross.tscn"

var _declines: Array = []
var _takens: Array = []
var _fails: Array = []


func _initialize() -> void:
	await _run()
	if _fails.is_empty():
		print("[probe] PASS — all cases green")
		quit(0)
	else:
		print("[probe] FAIL — %d case(s):" % _fails.size())
		for f in _fails:
			print("[probe]   %s" % f)
		quit(1)


func _check(tag: String, ok: bool, detail: String) -> void:
	print("[probe] %s %s  %s" % [tag, ("ok  " if ok else "FAIL"), detail])
	if not ok:
		_fails.append("%s — %s" % [tag, detail])


func _mk_body(nm: String, groups: Array) -> CharacterBody3D:
	# the museum's own recipe: layer 1 by DEFAULT (never assigned), capsule
	# r0.32 h1.5 seated so the feet are the origin.
	var b := CharacterBody3D.new()
	b.name = nm
	for g in groups:
		b.add_to_group(String(g))
	var c := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.5
	c.shape = cap
	c.position = Vector3(0, 0.75, 0)
	b.add_child(c)
	return b


func _step(n: int = 6) -> void:
	for i in n:
		await physics_frame


func _visible_of(cross: Node) -> bool:
	var c: Node = cross.get_node_or_null("Cross")
	return bool(c.get("visible")) if c != null else false


func _run() -> void:
	var root := get_root()
	var gm: Node = null
	for i in 20:
		await process_frame
		gm = root.get_node_or_null("GameManager")
		if gm != null:
			break
	if gm == null:
		_check("boot", false, "no GameManager autoload")
		return
	var maxh: float = float(gm.get("max_player_health"))
	print("[probe] max_player_health = %.1f" % maxh)

	var scn: PackedScene = load(CROSS)
	if scn == null:
		_check("boot", false, "cross scene did not load")
		return

	# ---------------------------------------------------------------- CASE A
	var cross_a: Node3D = scn.instantiate()
	root.add_child(cross_a)
	await _step(2)
	cross_a.connect("declined", _on_declined.bind("A"))
	cross_a.connect("taken", _on_taken.bind("A"))
	var pad: Node = cross_a.get_node_or_null("Pad")
	_check("pad", pad != null and int(pad.get("collision_mask")) == 524289,
		"mask=%d (want 524289 = layer 1 | layer 20)" % (
			int(pad.get("collision_mask")) if pad != null else -1))

	gm.call("set_health", maxh)
	var v := _mk_body("Walker", ["em_walker"])
	v.position = Vector3(0, 0, 4)
	root.add_child(v)
	await _step(3)
	v.position = Vector3(0, 0, 0)
	await _step(8)
	_check("A", float(gm.get("player_health")) == maxh
			and not bool(cross_a.call("is_spent"))
			and _visible_of(cross_a)
			and _declines.size() == 1 and String(_declines[0]).ends_with("not low enough"),
		"whole visitor: health %.1f, spent=%s, visible=%s, declines=%s" % [
			float(gm.get("player_health")), str(cross_a.call("is_spent")),
			str(_visible_of(cross_a)), str(_declines)])

	# ---------------------------------------------------------------- CASE E
	_declines.clear()
	_takens.clear()
	gm.call("set_health", 85.0)                      # hurt, but not below 75
	v.position = Vector3(0, 0, 4)
	await _step(4)
	v.position = Vector3(0, 0, 0)
	await _step(8)
	_check("E", is_equal_approx(float(gm.get("player_health")), 85.0)
			and not bool(cross_a.call("is_spent"))
			and _visible_of(cross_a) and _takens.is_empty(),
		"85 of 100 is not low: health %.1f, spent=%s, declines=%s, takens=%s" % [
			float(gm.get("player_health")), str(cross_a.call("is_spent")),
			str(_declines), str(_takens)])

	# ---------------------------------------------------------------- CASE F
	_declines.clear()
	_takens.clear()
	gm.call("set_health", 74.0)                      # below 75 — qualifies
	v.position = Vector3(0, 0, 4)
	await _step(4)
	v.position = Vector3(0, 0, 0)
	await _step(8)
	_check("F", is_equal_approx(float(gm.get("player_health")), maxh)
			and bool(cross_a.call("is_spent")) and _takens.size() == 1,
		"74 of 100 is low: health -> %.1f (want %.1f), spent=%s, takens=%s" % [
			float(gm.get("player_health")), maxh,
			str(cross_a.call("is_spent")), str(_takens)])

	# ---------------------------------------------------------------- CASE D
	_declines.clear()
	_takens.clear()
	gm.call("set_health", 40.0)
	v.position = Vector3(0, 0, 4)
	await _step(4)
	v.position = Vector3(0, 0, 0)
	await _step(8)
	_check("D", is_equal_approx(float(gm.get("player_health")), 40.0) and _takens.is_empty(),
		"re-entry while spent: health %.1f (want 40.0), takens=%s" % [
			float(gm.get("player_health")), str(_takens)])

	v.queue_free()
	cross_a.queue_free()
	await _step(3)

	# ---------------------------------------------------------------- CASE B
	# a fresh cross, a properly hurt visitor: the ordinary success path.
	_declines.clear()
	_takens.clear()
	var cross_b: Node3D = scn.instantiate()
	cross_b.position = Vector3(40, 0, 0)
	root.add_child(cross_b)
	await _step(2)
	cross_b.connect("declined", _on_declined.bind("B"))
	cross_b.connect("taken", _on_taken.bind("B"))
	gm.call("set_health", 50.0)
	var v_b := _mk_body("Walker2", ["em_walker"])
	v_b.position = Vector3(40, 0, 4)
	root.add_child(v_b)
	await _step(3)
	v_b.position = Vector3(40, 0, 0)
	await _step(8)
	_check("B", is_equal_approx(float(gm.get("player_health")), 84.0)
			and bool(cross_b.call("is_spent")),
		"hurt visitor 50 -> %.1f (want 84.0), spent=%s" % [
			float(gm.get("player_health")), str(cross_b.call("is_spent"))])
	v_b.queue_free()
	cross_b.queue_free()
	await _step(3)

	# ---------------------------------------------------------------- CASE C
	# A FRESH cross, and an ENEMY body: group "enemy" only, layer 1 by default,
	# exactly what hazard_creature_base gives every creature in the corpus.
	_declines.clear()
	_takens.clear()
	var cross_c: Node3D = scn.instantiate()
	cross_c.position = Vector3(20, 0, 0)
	root.add_child(cross_c)
	await _step(2)
	cross_c.connect("declined", _on_declined.bind("C"))
	cross_c.connect("taken", _on_taken.bind("C"))
	gm.call("set_health", 50.0)
	var foe := _mk_body("HeadCrab", ["enemy"])       # NOT any visitor group
	foe.position = Vector3(20, 0, 4)
	root.add_child(foe)
	await _step(3)
	foe.position = Vector3(20, 0, 0)
	await _step(10)
	_check("C", is_equal_approx(float(gm.get("player_health")), 50.0)
			and not bool(cross_c.call("is_spent"))
			and _visible_of(cross_c) and _takens.is_empty(),
		"ENEMY on the pad: health %.1f (want 50.0), spent=%s, visible=%s, takens=%s" % [
			float(gm.get("player_health")), str(cross_c.call("is_spent")),
			str(_visible_of(cross_c)), str(_takens)])
	foe.queue_free()
	cross_c.queue_free()
	await _step(3)

	# ---------------------------------------------------------------- CASE G
	# Hurt WHILE STANDING on the pad. body_entered has already fired and been
	# refused, so only the re-scan can catch this.
	_declines.clear()
	_takens.clear()
	var cross_g: Node3D = scn.instantiate()
	cross_g.position = Vector3(60, 0, 0)
	root.add_child(cross_g)
	await _step(2)
	cross_g.connect("taken", _on_taken.bind("G"))
	gm.call("set_health", 90.0)                      # not low — refused on entry
	var v_g := _mk_body("Walker3", ["em_walker"])
	v_g.position = Vector3(60, 0, 4)
	root.add_child(v_g)
	await _step(3)
	v_g.position = Vector3(60, 0, 0)                 # step on, get refused
	await _step(8)
	var stood_refused: bool = not bool(cross_g.call("is_spent"))
	gm.call("set_health", 47.0)                      # bitten, without moving
	for i in 90:                                     # > SCAN_S at ~7 ms a frame
		await physics_frame
	_check("G", stood_refused and bool(cross_g.call("is_spent"))
			and float(gm.get("player_health")) > 47.0,
		"bitten while standing: refused-on-entry=%s, then health 47 -> %.1f, spent=%s" % [
			str(stood_refused), float(gm.get("player_health")),
			str(cross_g.call("is_spent"))])
	v_g.queue_free()
	cross_g.queue_free()
	await _step(2)


func _on_declined(why: String, tag: String) -> void:
	_declines.append("%s:%s" % [tag, why])


func _on_taken(amount: float, tag: String) -> void:
	_takens.append("%s:%.1f" % [tag, amount])

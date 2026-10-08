extends SceneTree

## GATE — plan_vitrine's arm / disarm path.
##
## The glass is verifiable from a screenshot. The thing that actually matters is
## not: a pen appears in each hand on entry and is taken back on exit. This probe
## drives that path headless and EXITS NON-ZERO on any failed case.
##
## A headless tree can hold XRController3D NODES but has no live tracker to make
## either of them active, so the artifact's `force_arm` meta skips both the
## OpenXR test and the get_is_active test. Everything after that — the tracker
## lookup, the claim, the build, the mount, the reparent home, the teardown — is
## the real code path.
##
##   A  visitor walks in            -> a pen parented to each controller
##   B  the pens are the right two  -> left runs draw_dot, right runs the time-domain subclass
##   C  the pens actually record    -> both resolve a nib and are processing
##   D  visitor walks out           -> both pens back under the artifact, controllers clean
##   E  visitor walks in AGAIN      -> re-mounted, and NOT duplicated
##   F  a second vitrine tries      -> it yields; the first keeps the hands
##   G  the artifact is freed       -> nothing left parented to either controller

const VITRINE := "res://commons/artifacts/plan_vitrine/plan_vitrine.tscn"

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


func _step(n: int = 8) -> void:
	for i in n:
		await physics_frame


## A rig with the shape the artifact looks for: an XROrigin3D with two
## XRController3D children carrying the real tracker names.
func _mk_rig(root: Node) -> Array:
	var origin := XROrigin3D.new()
	origin.name = "TestOrigin"
	origin.current = true
	root.add_child(origin)
	var made: Array = []
	for t in [&"left_hand", &"right_hand"]:
		var c := XRController3D.new()
		c.name = "Ctrl_" + String(t)
		c.tracker = t
		origin.add_child(c)
		made.append(c)
	return [origin, made[0], made[1]]


func _mk_visitor(nm: String) -> CharacterBody3D:
	var b := CharacterBody3D.new()
	b.name = nm
	b.add_to_group("player_body")
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.6
	col.shape = cap
	col.position = Vector3(0, 0.8, 0)
	b.add_child(col)
	return b


func _pen_on(ctrl: Node, nm: String) -> Node:
	return ctrl.get_node_or_null(nm)


func _run() -> void:
	var root := get_root()
	for i in 12:
		await process_frame

	var scn: PackedScene = load(VITRINE)
	if scn == null:
		_check("boot", false, "vitrine scene did not load")
		return

	var rig := _mk_rig(root)
	var left: Node = rig[1]
	var right: Node = rig[2]

	var v: Node3D = scn.instantiate()
	v.position = Vector3.ZERO
	v.set_meta("force_arm", true)
	root.add_child(v)
	await _step(3)

	var sensor: Node = v.get_node_or_null("Inside")
	_check("sensor", sensor != null and int(sensor.get("collision_mask")) == 524289,
		"Inside area mask=%d (want 524289)" % (
			int(sensor.get("collision_mask")) if sensor != null else -1))
	# THE GLASS MUST NOT BLOCK. Two colliders are legitimate and expected: the
	# sensing Area3D, and simulation_grid's own PlanFloor static body, which is
	# the deck the visitor stands on. Anything else means a pane grew a collider.
	# (The first version of this check just counted to 1 and failed on the floor —
	# the assertion was wrong, not the artifact.)
	var stray := _stray_colliders(v)
	_check("glass_free", stray.is_empty(),
		"colliders that are neither the sensor nor the plan's floor: %s (want none)" % str(stray))

	# ---------------------------------------------------------------- CASE A
	var body := _mk_visitor("Player")
	body.position = Vector3(0, 0, 12)          # far outside
	root.add_child(body)
	await _step(4)
	body.position = Vector3(0, 0, 0)           # step inside
	await _step(20)                            # poll is 0.1 s

	var pl: Node = _pen_on(left, "PlanPen_L")
	var pr: Node = _pen_on(right, "PlanPen_R")
	_check("A", pl != null and pr != null,
		"entered: left pen=%s right pen=%s armed=%s" % [
			str(pl != null), str(pr != null), str(v.call("is_armed"))])
	if pl == null or pr == null:
		return

	# ---------------------------------------------------------------- CASE B
	var l_tape: bool = pl.has_method("_set_time_origin")
	var r_tape: bool = pr.has_method("_set_time_origin")
	_check("B", (not l_tape) and r_tape,
		"left is the free pen (%s), right is the time-domain pen (%s)" % [
			str(not l_tape), str(r_tape)])

	# ---------------------------------------------------------------- CASE C
	var l_nib: Node = pl.get_node_or_null("GrabPoint")
	var r_nib: Node = pr.get_node_or_null("GrabPoint")
	var l_proc: bool = pl.is_processing()
	_check("C", l_nib != null and r_nib != null and l_proc
			and not l_nib.has_method("is_picked_up"),
		"nibs resolve (L=%s R=%s), left processing=%s, nib has no is_picked_up=%s" % [
			str(l_nib != null), str(r_nib != null), str(l_proc),
			str(not l_nib.has_method("is_picked_up"))])

	# ---------------------------------------------------------------- CASE D
	body.position = Vector3(0, 0, 12)          # walk out
	await _step(20)
	_check("D", _pen_on(left, "PlanPen_L") == null and _pen_on(right, "PlanPen_R") == null
			and not bool(v.call("is_armed")),
		"exited: controllers clean=%s/%s armed=%s" % [
			str(_pen_on(left, "PlanPen_L") == null),
			str(_pen_on(right, "PlanPen_R") == null), str(v.call("is_armed"))])

	# ---------------------------------------------------------------- CASE E
	body.position = Vector3(0, 0, 0)           # back in
	await _step(20)
	var l_kids := 0
	for c in left.get_children():
		if String(c.name).begins_with("PlanPen"):
			l_kids += 1
	_check("E", _pen_on(left, "PlanPen_L") != null and l_kids == 1,
		"re-entered: mounted=%s, pens on the left controller=%d (want exactly 1, no double-add)" % [
			str(_pen_on(left, "PlanPen_L") != null), l_kids])

	# ---------------------------------------------------------------- CASE F
	var v2: Node3D = scn.instantiate()
	v2.position = Vector3(0, 0, 0)
	v2.set_meta("force_arm", true)
	root.add_child(v2)
	await _step(20)
	var still_first: bool = _pen_on(left, "PlanPen_L") != null and bool(v.call("is_armed"))
	_check("F", still_first and not bool(v2.call("is_armed")),
		"second vitrine yields: first still armed=%s, second armed=%s" % [
			str(still_first), str(v2.call("is_armed"))])
	v2.queue_free()
	await _step(3)

	# ---------------------------------------------------------------- CASE G
	v.queue_free()
	await _step(8)
	var leftover := 0
	for ctrl in [left, right]:
		for c in ctrl.get_children():
			if String(c.name).begins_with("PlanPen"):
				leftover += 1
	_check("G", leftover == 0,
		"after the vitrine is freed, pens still parented to a controller = %d (want 0)" % leftover)


## Any collider that could stop a body walking in, EXCLUDING the two that belong
## here: the sensing Area3D, and the wrapped plan's floor. Returns their names.
func _stray_colliders(root: Node) -> Array:
	var stray: Array = []
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var cur: Node = pending.pop_back()
		if cur.name == "Plan":
			continue                          # the deck is meant to be solid
		if cur is CollisionObject3D and cur.name != "Inside":
			stray.append(String(cur.name))
		for c in cur.get_children():
			pending.append(c)
	return stray

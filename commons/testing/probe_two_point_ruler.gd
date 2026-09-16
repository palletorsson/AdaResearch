extends SceneTree
## CAN A VISITOR TAKE A READING, AND IS THE READING TRUE?
##
## Rewritten 2026-09-08 against doc/book/handoffs/claude-two-point-ruler.md.
##
## THE OLD PROBE COULD NOT FAIL. It asserted
##
##     if abs(r - 0.5) > 0.001: FAIL "the reading is not honest"
##
## against a measure() whose body was `var reading: float = unit_m` — a constant
## compared to the constant it was initialised from. It also called measure()
## directly, so it proved nothing about a visitor being able to reach it, and it
## waited `for i in 40: await process_frame`, which the brief rules out as
## evidence of elapsed animation time.
##
## This one drives _rule.action() — the SAME entry point both lanes call
## (function_pickup.gd:496 in VR, DesktopInteractionPointer.gd:315 on desktop) —
## and waits on wall-clock time.
##
## WHAT IT CANNOT PROVE, stated so no one reads more into a pass than is there:
## the VR controller binding needs a live XRController3D on a rig and is NOT
## exercised here. A pass means the artifact answers the action; it does not mean
## a headset works. Physical acceptance stays separate, as the brief says.
##
##   godot --headless --xr-mode off --path . \
##     --script res://commons/testing/probe_two_point_ruler.gd

const RULER := "res://commons/artifacts/two_point_ruler/two_point_ruler.tscn"
const SETTLE_MS := 700     # the witness tween is 0.35 s; give it double


var _fails := 0


func _fail(msg: String) -> void:
	_fails += 1
	print("   FAIL %s" % msg)


func _ok(label: String, cond: bool, detail: String = "") -> void:
	print("   %s %s%s" % ["ok  " if cond else "FAIL", label, ("  " + detail) if detail != "" else ""])
	if not cond:
		_fails += 1


## Wall clock, not frames. A headless frame is not a unit of time, and the brief
## forbids counting them as one.
func _settle(ms: int = SETTLE_MS) -> void:
	await create_timer(float(ms) / 1000.0).timeout


func _spawn(at: Vector3 = Vector3.ZERO, rot_deg: float = 0.0, sc: float = 1.0) -> Node3D:
	var packed := load(RULER) as PackedScene
	if packed == null:
		return null
	var a := packed.instantiate() as Node3D
	a.position = at
	a.rotation_degrees = Vector3(0, rot_deg, 0)
	a.scale = Vector3(sc, sc, sc)
	get_root().add_child(a)
	return a


## Put the rule's tip on the subject, or deliberately far from it.
func _place_tip(a: Node3D, on_subject: bool) -> void:
	var rule := a.get_node_or_null("Rule") as Node3D
	var subj := a.get_node_or_null("Subject") as Node3D
	if rule == null or subj == null:
		return
	var tip := rule.get_node_or_null("Tip") as Node3D
	# move the RULE so that its Tip lands where we want it
	var want: Vector3 = subj.global_position
	if not on_subject:
		want += Vector3(0, 40, 0)      # unambiguously nowhere near it
	var offset: Vector3 = tip.global_position - rule.global_position if tip != null else Vector3.ZERO
	rule.global_position = want - offset


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("TWO-POINT RULER — can a visitor take a reading, and is it true?")
	print("")

	# ── 1. the packed scene, as a map would instantiate it ────────────────
	print("1  the scene a map places")
	var a := _spawn()
	if a == null:
		print("   FAIL the scene did not load"); quit(1); return
	await _settle(300)
	var rule := a.get_node_or_null("Rule")
	_ok("the ruler builds a Subject", a.get_node_or_null("Subject") != null)
	_ok("the ruler builds a Witness", a.get_node_or_null("Witness") != null)
	_ok("there is a Rule to pick up", rule != null)
	if rule == null:
		print("\nPROBE FAILED — nothing to hold, so nothing below can be tested")
		quit(1); return
	_ok("the Rule is a pickable (has action_pressed)", rule.has_signal("action_pressed"))
	_ok("the Rule sits on the grab layer 3", int(rule.get("collision_layer")) & 4 != 0,
		"collision_layer=%d — VR masks 327684, desktop 393220; layer 3 is the overlap"
			% int(rule.get("collision_layer")))
	_ok("action_pressed is ALREADY connected",
		rule.get_signal_connection_list("action_pressed").size() > 0,
		"DesktopInteractionPointer._fires refuses to call action() without a listener")

	# ── 2. a reading taken in mid-air is refused ──────────────────────────
	print("2  activation away from the subject")
	var s_before: float = a.subject_scale()
	var w_before: float = a.witness_scale()
	var r_before: float = a.reading()
	_place_tip(a, false)
	await _settle(120)
	rule.call("action")
	await _settle()
	_ok("the witness did not move", absf(a.witness_scale() - w_before) < 0.001)
	_ok("no reading was recorded", absf(a.reading() - r_before) < 0.0001)
	_ok("still armed for a real reading", bool(a.armed()))

	# ── 3. one press on the subject is one reading ────────────────────────
	print("3  one deliberate reading")
	_place_tip(a, true)
	await _settle(120)
	_ok("the tip is on the subject", bool(a.tip_on_subject()))
	rule.call("action")
	await _settle()
	var r1: float = a.reading()
	var w1: float = a.witness_scale()
	_ok("a reading was taken", r1 > 0.0, "%.3f m" % r1)
	_ok("the witness moved", absf(w1 - w_before) > 0.01, "%.3f -> %.3f" % [w_before, w1])
	_ok("THE SUBJECT IS UNCHANGED", absf(a.subject_scale() - s_before) < 0.001,
		"measuring must not alter what it measures")

	# ── 4. the reading is TRUE of the subject ─────────────────────────────
	print("4  is the number true?")
	var truth: float = a.call("_subject_width_m")
	_ok("the readout matches the subject's built width", absf(r1 - truth) < 0.001,
		"read %.3f, subject measures %.3f" % [r1, truth])

	# ── 5. holding the input does not keep reading ────────────────────────
	print("5  a held input")
	for i in 8:
		rule.call("action")
	await _settle()
	_ok("eight more presses without leaving changed nothing",
		absf(a.witness_scale() - w1) < 0.001, "%.3f still" % a.witness_scale())
	_ok("still disarmed while the tip rests on the subject", not bool(a.armed()))

	# ── 6. leave and come back, and it reads again ────────────────────────
	print("6  a second deliberate reading")
	_place_tip(a, false)
	await _settle(200)
	_ok("re-armed by leaving", bool(a.armed()))
	_place_tip(a, true)
	await _settle(120)
	rule.call("action")
	await _settle()
	_ok("the witness moved again", absf(a.witness_scale() - w1) > 0.01,
		"%.3f -> %.3f" % [w1, a.witness_scale()])
	_ok("and the subject STILL has not moved", absf(a.subject_scale() - s_before) < 0.001)

	# ── 7. bounds, under rapid alternating input ──────────────────────────
	print("7  bounds under repeated readings")
	for i in 30:
		_place_tip(a, false)
		await _settle(30)
		_place_tip(a, true)
		await _settle(30)
		rule.call("action")
	await _settle()
	var wlo: float = a.witness_scale()
	_ok("the witness is still present", wlo >= 0.179, "%.3f (floor is 0.18)" % wlo)
	_ok("and still a real object", wlo <= 2.401)
	_ok("the subject survived all of it", absf(a.subject_scale() - s_before) < 0.001)

	# ── 8. two instances do not touch each other ──────────────────────────
	print("8  isolation between two instances")
	var b := _spawn(Vector3(30, 0, 0))
	await _settle(300)
	var b_rule := b.get_node_or_null("Rule")
	var b_w0: float = b.witness_scale()
	_place_tip(a, false); await _settle(60); _place_tip(a, true); await _settle(60)
	rule.call("action")
	await _settle()
	_ok("reading A left B's witness alone", absf(b.witness_scale() - b_w0) < 0.001)
	if b_rule != null:
		_place_tip(b, true)
		await _settle(120)
		b_rule.call("action")
		await _settle()
		_ok("B can be read on its own", absf(b.witness_scale() - b_w0) > 0.01)

	# ── 9. translated, rotated, and scaled ────────────────────────────────
	print("9  a placed instance — translated, rotated, scaled")
	var c := _spawn(Vector3(-25, 0, 12), 37.0, 1.0)
	await _settle(300)
	var c_rule := c.get_node_or_null("Rule")
	_place_tip(c, true)
	await _settle(120)
	_ok("the zone still finds the subject when rotated 37 deg", bool(c.tip_on_subject()),
		"the test is point-in-box in the subject's own frame, so rotation is free")
	if c_rule != null:
		c_rule.call("action")
		await _settle()
		_ok("a rotated instance reads", c.reading() > 0.0, "%.3f m" % c.reading())

	var d := _spawn(Vector3(60, 0, 0), 0.0, 2.0)
	await _settle(300)
	var d_truth: float = d.call("_subject_width_m")
	var d_rule := d.get_node_or_null("Rule")
	_place_tip(d, true)
	await _settle(120)
	if d_rule != null:
		d_rule.call("action")
		await _settle()
		_ok("AT SCALE 2 THE READING TRACKS THE GEOMETRY", absf(d.reading() - d_truth) < 0.002,
			"read %.3f, subject measures %.3f — the old constant would have said 0.500"
				% [d.reading(), d_truth])

	print("")
	print("NOT TESTED HERE: the VR controller binding. This drives pickable.action(),")
	print("which is what function_pickup.gd:496 calls, but no XRController3D was")
	print("involved. Headset acceptance is separate.")
	print("")
	print("PROBE OK" if _fails == 0 else "PROBE FAILED (%d)" % _fails)
	quit(_fails)

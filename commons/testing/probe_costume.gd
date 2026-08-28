extends SceneTree
## THE COSTUME, MEASURED (2026-08-27, Palle: "can the vr player get a super queer
## costume that used inverse kinematics ... and attach beautiful thing to it as
## we go along the sequences").
##
## The claim worth testing is not "does a costume appear". It is that the extra
## limbs are SOLVED rather than carried — a stick parented to a coat passes every
## screenshot and fails the only question that matters, which is whether the tip
## belongs to the ROOM or to the body. So the walk here is deliberate:
##
##   still  — the tips must barely move in the room, though the body breathes
##   walk   — they must LAG (a carried limb has zero lag, by definition), must
##            each let go and re-plant at least once, and must never break the
##            one FABRIK invariant: a segment is its own length, always
##   still  — and they must come back to rest
##
## Then the accretion: twenty-two trophies must all build, all hang, and none may
## quietly replace another (eight slots, twenty-two things).
const COSTUME := "res://commons/player/queer_costume.gd"
const WARDROBE := "res://commons/player/costume_wardrobe.gd"
const TROPHIES := "res://commons/player/costume_trophies.gd"
const TXT := "res://ada_run/costume.txt"

## A STUB PROGRESSION. is_sequence_completed() is true only when every map of a
## sequence is finished, and the live save has one finished map — so on the real
## manager the restore path reports 0 and proves nothing. The alternative is
## writing completions into Palle's save to watch the restore work, which is
## exactly the shoes a probe must not put on. So the wardrobe takes a
## manager_path, and this stands in.
class StubProgression extends Node:
	signal sequence_completed(sequence_name: String)
	var done: Array = []
	func is_sequence_completed(s: String) -> bool:
		return s in done


var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

var fails: Array = []
func _fail(s: String) -> void: fails.append(s)


func _rig(st: Node3D) -> Node3D:
	# a three-point rig with nothing in it but the three points, which is all a
	# headset ever gives you
	var origin := XROrigin3D.new()
	origin.name = "XROrigin3D"
	st.add_child(origin)
	var cam := XRCamera3D.new()
	cam.name = "XRCamera3D"
	cam.position = Vector3(0, 1.65, 0)
	origin.add_child(cam)
	for hand_name in ["LeftHand", "RightHand"]:
		var h := Node3D.new()
		h.name = hand_name
		h.position = Vector3(-0.25 if hand_name == "LeftHand" else 0.25, 1.25, -0.28)
		origin.add_child(h)
	return origin


func _run() -> void:
	var st := Node3D.new()
	get_root().add_child(st)
	current_scene = st
	var origin: Node3D = _rig(st)
	var cam: Node3D = origin.get_node("XRCamera3D")

	var c: Node3D = (load(COSTUME) as GDScript).new() as Node3D
	c.name = "QueerCostume"
	origin.add_child(c)
	c.call("attach_to", origin)
	await create_timer(0.4).timeout

	# ── A. what got built ────────────────────────────────────────────────────
	_say("WHAT IS ON THE BODY")
	var limbs: int = int(c.get("limb_count"))
	var steps0: Array = c.call("limb_steps")
	_say("  extra limbs %d, slots %d" % [steps0.size(), (c.call("slot_names") as Array).size()])
	if steps0.size() != limbs:
		_fail("asked for %d extra limbs, built %d" % [limbs, steps0.size()])
	if (c.call("slot_names") as Array).size() != 8:
		_fail("expected 8 slots")

	# ── B. still: the tips belong to the room ────────────────────────────────
	await create_timer(1.2).timeout          # let the first plant settle
	var rest: Array = []
	for i in range(limbs):
		rest.append(c.call("tip_of", i))
	var drift := 0.0
	var t := 0.0
	while t < 1.5:
		await create_timer(0.05).timeout
		t += 0.05
		for i in range(limbs):
			drift = maxf(drift, (rest[i] as Vector3).distance_to(c.call("tip_of", i)))
	_say("")
	_say("STANDING STILL")
	_say("  the furthest any tip moved in 1.5 s: %.4f m" % drift)
	if drift > 0.02:
		_fail("the tips wander while the body is still (%.3f m)" % drift)

	# ── C. walking: they must lag, plant, and hold their lengths ─────────────
	_say("")
	_say("WALKING THREE METRES")
	var before: Array = c.call("limb_steps")
	var lag := 0.0
	var worst_seg := 0.0
	var seg_want: float = float(c.get("limb_length"))
	var reachable: float = seg_want * float(c.get("limb_segments"))
	var over_reach := 0.0
	var keep: float = reachable * float(c.get("limb_bend_keep"))
	var over_keep := 0.0
	t = 0.0
	while t < 3.0:
		await create_timer(0.033).timeout
		t += 0.033
		cam.position = Vector3(0, 1.65, -t)           # walk forward
		for i in range(limbs):
			var tip: Vector3 = c.call("tip_of", i)
			var root: Vector3 = c.call("limb_root", i)
			lag = maxf(lag, tip.distance_to(root))
			over_reach = maxf(over_reach, tip.distance_to(root) - reachable)
			over_keep = maxf(over_keep, tip.distance_to(root) - keep)
			var chain: Array = c.call("chain_of", i)
			for s in range(chain.size() - 1):
				worst_seg = maxf(worst_seg,
					absf((chain[s] as Vector3).distance_to(chain[s + 1]) - seg_want))
	var after: Array = c.call("limb_steps")
	var planted := 0
	for i in range(limbs):
		if int(after[i]) > int(before[i]):
			planted += 1
	_say("  each limb re-planted: %s" % str(after))
	_say("  limbs that let go and re-planted while walking: %d of %d" % [planted, limbs])
	_say("  furthest a tip trailed behind its own root: %.3f m (it can reach %.2f m)"
		% [lag, reachable])
	_say("  worst segment-length error: %.5f m (a segment is %.2f m)" % [worst_seg, seg_want])
	# AND WHAT WAS ACTUALLY DRAWN. The chain being right proves nothing about the
	# picture — this probe passed a build whose every segment rendered at a full
	# metre, because Node3D.basis carries scale and overwrote it.
	var drawn_err: float = float(c.call("drawn_error"))
	_say("  worst disagreement between the solved chain and the drawn rod: %.5f m" % drawn_err)
	_say("  it is held to %.2f m of its %.2f m reach, so it keeps a bend — worst overshoot %.4f m"
		% [keep, reachable, maxf(0.0, over_keep)])
	if planted < limbs:
		_fail("%d limb(s) never re-planted — they are being carried, not solved" % (limbs - planted))
	if lag < 0.15:
		_fail("the tips never trailed (%.3f m) — that is a stick taped to a coat" % lag)
	if over_reach > 0.001:
		_fail("a tip was %.3f m beyond what the chain can reach" % over_reach)
	if worst_seg > 0.001:
		_fail("a segment changed length by %.4f m — FABRIK is not holding" % worst_seg)
	if drawn_err > 0.005:
		_fail("a rod was drawn %.3f m off its own chain — the model is right and the view is not"
			% drawn_err)
	if over_keep > 0.001:
		_fail("a tip went %.3f m past the bend limit — the chain straightened out" % over_keep)

	# ── and back to rest ─────────────────────────────────────────────────────
	await create_timer(1.4).timeout
	var rest2: Array = []
	for i in range(limbs):
		rest2.append(c.call("tip_of", i))
	var settle := 0.0
	t = 0.0
	while t < 1.0:
		await create_timer(0.05).timeout
		t += 0.05
		for i in range(limbs):
			settle = maxf(settle, (rest2[i] as Vector3).distance_to(c.call("tip_of", i)))
	_say("  after stopping, the furthest a tip moved in 1 s: %.4f m" % settle)
	if settle > 0.02:
		_fail("they never settle after a walk (%.3f m)" % settle)

	# the torso must have followed the head, not stayed at the spawn
	var torso: Node3D = c.get_node_or_null("ComposedTorso")
	var under_head: float = torso.global_position.distance_to(
		cam.global_position + Vector3(0, -0.15, 0))
	_say("  the composed torso sits %.3f m from where the neck should be" % under_head)
	if under_head > 0.05:
		_fail("the torso did not follow the head (%.3f m off)" % under_head)

	# ── D. the garment grows, and never shrinks ──────────────────────────────
	_say("")
	_say("THE GARMENT")
	_say("  tiers at stage 0: %d" % int(c.call("garment_tiers")))
	if int(c.call("garment_tiers")) != 0:
		_fail("an unwalked garment is not bare")
	for _i in range(5):
		c.call("grow")
	await create_timer(0.2).timeout
	_say("  after five sequences: stage %d, tiers %d"
		% [int(c.get("stage")), int(c.call("garment_tiers"))])
	if int(c.get("stage")) != 5 or int(c.call("garment_tiers")) != 5:
		_fail("five sequences did not make five tiers")
	c.call("grow", 2)                                  # asking it to shrink
	if int(c.get("stage")) != 5:
		_fail("the garment went BACKWARDS to stage %d — a record cannot shrink" % int(c.get("stage")))
	_say("  asked to drop to stage 2 it stayed at %d" % int(c.get("stage")))

	# ── E. every trophy builds, and none replaces another ────────────────────
	_say("")
	_say("TWENTY-TWO TROPHIES")
	var T: GDScript = load(TROPHIES) as GDScript
	var seqs: Array = T.known()
	var empty: Array = []
	var missing: Array = []
	for seq in seqs:
		var n: Node3D = T.make(seq)
		if n == null:
			missing.append(seq)
			continue
		if n.get_child_count() == 0:
			empty.append(seq)
		if not c.call("pin", n, T.slot_for(seq)):
			_fail("%s could not be hung at %s" % [seq, T.slot_for(seq)])
	_say("  designed for %d sequences, %d failed to build, %d built nothing"
		% [seqs.size(), missing.size(), empty.size()])
	for m in missing: _say("      no design: %s" % m)
	for e in empty: _say("      built empty: %s" % e)
	if not missing.is_empty(): _fail("%d sequence(s) have no trophy" % missing.size())
	if not empty.is_empty(): _fail("%d trophy(ies) built no geometry" % empty.size())
	var hung: int = int(c.call("pinned_count"))
	_say("  hung on the body: %d" % hung)
	for slot in (c.call("slot_names") as Array):
		var k: int = int(c.call("pinned_in", slot))
		if k > 0:
			_say("      %-16s %d" % [slot, k])
	if hung != seqs.size():
		_fail("hung %d of %d — something replaced something else" % [hung, seqs.size()])

	# ── F. the wardrobe: does a finished sequence actually reach the body? ───
	_say("")
	_say("THE DOOR — a finished sequence reaching the costume")
	var w: Node = (load(WARDROBE) as GDScript).new()
	w.name = "CostumeWardrobe"
	origin.add_child(w)
	await create_timer(0.6).timeout
	var w_costume = w.get("costume")
	if w_costume == null:
		_fail("the wardrobe built no costume")
	else:
		var restored: int = (w.call("worn") as Array).size()
		_say("  the wardrobe restored %d already-completed sequence(s) on its own" % restored)
		var mgr: Node = get_root().get_node_or_null("MapProgressionManager")
		if mgr == null:
			_say("  MapProgressionManager is absent — cannot test the live signal")
			_fail("MapProgressionManager was not there to connect to")
		else:
			var before_stage: int = int(w_costume.get("stage"))
			mgr.emit_signal("sequence_completed", "lsystems")
			await create_timer(0.2).timeout
			var after_stage: int = int(w_costume.get("stage"))
			_say("  emitted sequence_completed('lsystems'): stage %d -> %d, wearing %d"
				% [before_stage, after_stage, (w.call("worn") as Array).size()])
			if after_stage <= before_stage:
				_fail("a finished sequence did not grow the costume")
			# and a second emit must change nothing
			mgr.emit_signal("sequence_completed", "lsystems")
			await create_timer(0.2).timeout
			if int(w_costume.get("stage")) != after_stage:
				_fail("the same sequence was counted twice")
			_say("  a repeat of the same sequence changed nothing: stage %d"
				% int(w_costume.get("stage")))

	# ── G. the restore: put the headset on with three sequences already done ─
	_say("")
	_say("PUTTING IT ON AFTER A MONTH AWAY")
	var stub := StubProgression.new()
	stub.name = "StubProgression"
	stub.done = ["primitives", "forces", "fractals"]
	st.add_child(stub)
	var w2: Node = (load(WARDROBE) as GDScript).new()
	w2.name = "RestoredWardrobe"
	w2.set("manager_path", NodePath("../../StubProgression"))
	origin.add_child(w2)
	await create_timer(0.6).timeout
	var c2 = w2.get("costume")
	if c2 == null:
		_fail("the restoring wardrobe built no costume")
	else:
		var worn: Array = w2.call("worn")
		_say("  three sequences were already finished; it came back wearing %d: %s"
			% [worn.size(), str(worn)])
		_say("  stage %d, tiers %d, trophies %d"
			% [int(c2.get("stage")), int(c2.call("garment_tiers")), int(c2.call("pinned_count"))])
		if worn.size() != 3:
			_fail("restored %d of 3 finished sequences" % worn.size())
		if int(c2.get("stage")) != 3 or int(c2.call("pinned_count")) != 3:
			_fail("the restore did not dress the body (stage %d, %d trophies)"
				% [int(c2.get("stage")), int(c2.call("pinned_count"))])
		# and a sequence that is NOT finished must not be worn
		if "lsystems" in worn:
			_fail("it wore a sequence that was never finished")

	# ── H. the whole door, as the game opens it ─────────────────────────────
	# PlayerCustomization is what actually runs in base.tscn, so the last thing
	# to test is the real path: mount it and let it activate what it activates.
	_say("")
	_say("AS THE GAME ACTUALLY OPENS IT")
	var origin2 := XROrigin3D.new()
	origin2.name = "XROrigin3D2"
	st.add_child(origin2)
	var cam2 := XRCamera3D.new()
	cam2.name = "XRCamera3D"
	cam2.position = Vector3(0, 1.65, 0)
	origin2.add_child(cam2)
	for hn in ["LeftHand", "RightHand"]:
		var hh := Node3D.new()
		hh.name = hn
		hh.position = Vector3(-0.25 if hn == "LeftHand" else 0.25, 1.25, -0.28)
		origin2.add_child(hh)
	var pc: Node = (load("res://commons/player/PlayerCustomization.gd") as GDScript).new()
	pc.name = "PlayerCustomization"
	origin2.add_child(pc)
	await create_timer(0.8).timeout
	_say("  unlocked: %s" % str(pc.call("get_unlocked_features")))
	for feat in ["costume", "body_arms"]:
		var live: bool = bool(pc.call("is_active", feat))
		var node = pc.get("_active_features").get(feat)
		# WHERE THE GEOMETRY ACTUALLY IS. The wardrobe is a bare Node that hangs the
		# costume on the ORIGIN, so counting the wardrobe's own children measures
		# nothing and reports zero — the third time this session a probe has looked
		# at the wrong node and called a working thing broken.
		var built: Node = node as Node
		if feat == "costume" and built != null:
			built = built.get("costume") as Node
		var kids: int = built.get_child_count() if built != null else -1
		_say("  %-10s active %-5s  built %s"
			% [feat, str(live), ("%d child node(s)" % kids) if kids >= 0 else "nothing"])
		if not live:
			_fail("PlayerCustomization did not activate '%s'" % feat)
		elif kids <= 0:
			_fail("'%s' activated but built nothing" % feat)

	_say("")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("the limbs are solved, the garment only grows, and the walk reaches the body"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	if fh != null:
		fh.store_string("\n".join(PackedStringArray(_l)) + "\n")
		fh.close()
	quit(0 if fails.is_empty() else 1)

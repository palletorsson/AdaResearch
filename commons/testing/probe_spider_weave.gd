extends SceneTree
## DOES IT WEAVE, AND WHAT IS A LEG (2026-08-26).
##
## The first census walked in a straight line and the four foot traces crossed
## ZERO times. That is a fact about a straight line, not about the animal — so
## this one gives it something to turn around, and asks three questions the
## straight walk could not:
##   does a foot trace cross ANOTHER foot's trace when the body turns?
##   does a foot trace cross the BODY's own path — a foot swinging across the
##     midline is what braids a gait, and it is invisible from behind?
##   does a foot's trace cross ITSELF?
## And it opens the leg: the census found Skeleton3D + FABRIK3D + 6 bones per
## leg, so the leg is not a rigid hierarchy of parents, it is a chain of
## fixed-length lines whose points are solved backwards from the foot.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const TXT := "res://ada_run/spider_weave.txt"
const HZ := 0.05
const SECONDS := 14.0

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _cross(a: Array, b: Array, same: bool) -> int:
	var n := 0
	for i in range(1, a.size()):
		for j in range(1, b.size()):
			if same and absi(i - j) < 3: continue
			if (a[i] as Vector2).distance_to(a[i - 1] as Vector2) < 0.001: continue
			if (b[j] as Vector2).distance_to(b[j - 1] as Vector2) < 0.001: continue
			if Geometry2D.segment_intersects_segment(a[i - 1], a[i], b[j - 1], b[j]) != null: n += 1
	return n

func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(200, 0.4, 200); cs.shape = bx; cs.position = Vector3(0, -0.2, 0)
	fb.add_child(cs); st.add_child(fb)
	var w := CharacterBody3D.new(); w.name = "Walker"; w.add_to_group("em_walker")
	st.add_child(w)
	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(c); c.global_position = Vector3.ZERO
	await create_timer(1.4).timeout

	# ── THE LEG, OPENED ────────────────────────────────────────────────────
	var body: Node = c.get("_body")
	var sk: Skeleton3D = null
	var fab: Node = null
	var stack: Array = [c]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if sk == null and n is Skeleton3D: sk = n as Skeleton3D
		if fab == null and n.get_class() == "FABRIK3D": fab = n
		for ch in n.get_children(): stack.append(ch)
	_say("THE LEG, OPENED")
	if sk != null:
		_say("  skeleton: %s   bones: %d" % [sk.name, sk.get_bone_count()])
		var tot := 0.0
		for b in range(sk.get_bone_count()):
			var r: Transform3D = sk.get_bone_rest(b)
			var seg: float = r.origin.length()
			tot += seg
			_say("    bone %d  %-16s rest offset %.4f  parent %d" % [b, sk.get_bone_name(b), seg, sk.get_bone_parent(b)])
		_say("  chain length in rig units: %.3f   at crab_scale %.3f = %.3f m" % [tot, float(c.get("crab_scale")), tot * float(c.get("crab_scale"))])
	else:
		_say("  no Skeleton3D found")
	if fab != null:
		_say("  solver: %s" % fab.get_class())
		for pn in ["target_node", "target", "root_bone", "tip_bone", "iterations", "chain_length"]:
			var v: Variant = fab.get(pn)
			if v != null: _say("    %s = %s" % [pn, str(v)])
	else:
		_say("  no FABRIK node found")
	_say("")

	# ── FOURTEEN SECONDS, WITH A TARGET THAT ORBITS ────────────────────────
	var feet: Array = c.get("_feet")
	var tr: Array = [[], [], [], []]
	var bt: Array = []
	var t := 0.0
	while t < SECONDS:
		await create_timer(HZ).timeout
		t += HZ
		# the visitor circles at 7 m, so the spider is always turning
		var a := t * 0.55
		w.global_position = Vector3(cos(a) * 7.0, 0.0, sin(a) * 7.0)
		for i in range(min(4, feet.size())):
			var f = feet[i]
			if f != null and is_instance_valid(f):
				var gp: Vector3 = (f as Node3D).global_position
				tr[i].append(Vector2(gp.x, gp.z))
		bt.append(Vector2(c.global_position.x, c.global_position.z))

	var pair := 0
	_say("FOURTEEN SECONDS AROUND A CIRCLING VISITOR (%d samples)" % bt.size())
	_say("  foot trace vs foot trace:")
	for a2 in range(4):
		for b2 in range(a2 + 1, 4):
			var n := _cross(tr[a2], tr[b2], false)
			pair += n
			_say("    %d x %d : %d" % [a2, b2, n])
	var midline := 0
	_say("  foot trace vs the BODY's own path (a foot crossing the midline):")
	for i2 in range(4):
		var n2 := _cross(tr[i2], bt, false)
		midline += n2
		_say("    foot %d x body : %d" % [i2, n2])
	var selfx := 0
	_say("  foot trace vs itself:")
	for i3 in range(4):
		var n3 := _cross(tr[i3], tr[i3], true)
		selfx += n3
		_say("    foot %d : %d" % [i3, n3])
	_say("")
	_say("  TOTALS  pair %d   midline %d   self %d" % [pair, midline, selfx])
	var verdict := "no braid: the feet stay on their own side and never cross the body's path"
	if midline > 0 and pair > 0: verdict = "A BRAID: feet cross each other AND the midline"
	elif midline > 0: verdict = "half a braid: feet cross the body's own path but not each other"
	elif pair > 0: verdict = "feet cross each other, but never the midline"
	_say("  reading: %s" % verdict)
	var f2 := FileAccess.open(TXT, FileAccess.WRITE)
	f2.store_string("\n".join(PackedStringArray(_l)) + "\n"); f2.close()
	quit(0)

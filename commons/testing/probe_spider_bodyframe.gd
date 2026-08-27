extends SceneTree
## THE BRAID QUESTION, ASKED PROPERLY (2026-08-26).
##
## Two measurements have now disagreed with each other for a stupid reason.
## Walking straight, the four foot traces crossed ZERO times. Circling, they
## crossed 7 times and each foot crossed ITSELF 60-odd times — but a spider
## walking a circle comes back over its own ground, so those crossings are a
## fact about the LOOP, not about the gait. Both readings are worthless.
##
## A gait braids when a foot swings across the body's own midline. That is only
## visible in the BODY'S FRAME: transform every foot position by the body's
## inverse transform, and ask whether the local x of a foot ever changes sign,
## and whether two feet ever occupy the same local ground. The floor's opinion
## does not enter into it.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const TXT := "res://ada_run/spider_bodyframe.txt"
const HZ := 0.04
const SECONDS := 16.0

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(300, 0.4, 300); cs.shape = bx; cs.position = Vector3(0, -0.2, 0)
	fb.add_child(cs); st.add_child(fb)
	var w := CharacterBody3D.new(); w.name = "Walker"; w.add_to_group("em_walker")
	st.add_child(w)
	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(c); c.global_position = Vector3.ZERO
	await create_timer(1.4).timeout
	var feet: Array = c.get("_feet")
	var scale_f: float = float(c.get("crab_scale"))

	# local traces, and the reach envelope
	var loc: Array = [[], [], [], []]
	var reach_min := [99.0, 99.0, 99.0, 99.0]
	var reach_max := [0.0, 0.0, 0.0, 0.0]
	var lift_max := 0.0
	var t := 0.0
	while t < SECONDS:
		await create_timer(HZ).timeout
		t += HZ
		# a wandering target: straight for a while, then a hard turn, then straight
		var a := t * 0.42
		w.global_position = Vector3(cos(a) * 9.0, 0.0, sin(a * 1.7) * 9.0)
		var inv: Transform3D = c.global_transform.affine_inverse()
		for i in range(min(4, feet.size())):
			var f = feet[i]
			if f == null or not is_instance_valid(f): continue
			var lp: Vector3 = inv * (f as Node3D).global_position
			loc[i].append(Vector2(lp.x, lp.z))
			var d := Vector2(lp.x, lp.z).length()
			reach_min[i] = minf(reach_min[i], d)
			reach_max[i] = maxf(reach_max[i], d)
			lift_max = maxf(lift_max, (f as Node3D).global_position.y)

	_say("THE SPIDER IN ITS OWN FRAME — %d samples at %d Hz" % [loc[0].size(), int(1.0 / HZ)])
	_say("")
	_say("foot reach from the body centre, in metres (world scale, crab_scale %.3f):" % scale_f)
	for i in range(4):
		_say("  foot %d   nearest %.3f   furthest %.3f   swing %.3f" % [i, reach_min[i], reach_max[i], reach_max[i] - reach_min[i]])
	_say("  highest a foot was lifted: %.3f m" % lift_max)
	_say("")
	# does a foot cross the midline? local x sign changes
	_say("midline crossings — how often each foot's local x changes sign:")
	var mid_total := 0
	for i in range(4):
		var n := 0
		var xs: Array = loc[i]
		for j in range(1, xs.size()):
			var a1: float = (xs[j - 1] as Vector2).x
			var b1: float = (xs[j] as Vector2).x
			if (a1 < 0.0 and b1 > 0.0) or (a1 > 0.0 and b1 < 0.0): n += 1
		mid_total += n
		var lo := 99.0; var hi := -99.0
		for p in xs:
			lo = minf(lo, (p as Vector2).x); hi = maxf(hi, (p as Vector2).x)
		_say("  foot %d : %d crossing(s)   local x from %+.3f to %+.3f" % [i, n, lo, hi])
	_say("")
	# do two feet ever stand on the same local ground?
	_say("shared ground — do two feet ever come within 0.05 m of each other in the body frame:")
	var shared := 0
	for a2 in range(4):
		for b2 in range(a2 + 1, 4):
			var n2 := 0
			for j in range(loc[a2].size()):
				if j >= loc[b2].size(): break
				if (loc[a2][j] as Vector2).distance_to(loc[b2][j] as Vector2) < 0.05: n2 += 1
			shared += n2
			_say("  %d and %d : %d sample(s)" % [a2, b2, n2])
	_say("")
	var verdict := "NO BRAID. Each foot keeps to its own quadrant: the local x never changes sign, "
	verdict += "so no leg ever swings across the body. Four independent traces, held apart by the stance."
	if mid_total > 0:
		verdict = "BRAIDED: %d midline crossing(s) — legs do swing across the body's own axis." % mid_total
	_say("VERDICT: " + verdict)
	if shared > 0 and mid_total == 0:
		_say("  (but %d samples of shared ground — feet meet without crossing)" % shared)
	var f2 := FileAccess.open(TXT, FileAccess.WRITE)
	f2.store_string("\n".join(PackedStringArray(_l)) + "\n"); f2.close()
	quit(0)

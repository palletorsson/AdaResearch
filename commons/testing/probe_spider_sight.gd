extends SceneTree
## WHAT IT CAN SEE, AND WHAT IT GIVES UP ON (2026-08-27, Palle: "The spider
## should not be able to see through the wall, they are colliders, not the
## spider trying to get to a mushroom that is on the other side of the wall but
## the collider blocks the spider and the spider is stuck in a loop. Also the
## player is equally interesting for the spider, the nearest food object").
##
## Three trials, each one a claim:
##
##   A  A mushroom behind a wall and a visitor in the open, with the MUSHROOM
##      NEARER. It must go for the visitor, because the mushroom is not visible
##      and therefore is not food. This is the loop Palle watched, inverted into
##      a test: the old rule would have sent it into the wall.
##
##   B  A mushroom in the open, nearer than the visitor. It must go for the
##      mushroom — no ranking, just distance, so the nearer thing wins whichever
##      kind it is.
##
##   C  A mushroom it can SEE but cannot REACH: a box with a slit at eye height.
##      Line of sight lets it set off; nothing lets it arrive. It must give up
##      and stop grinding.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const MUSH := "res://commons/artifacts/spore_mushroom/spore_mushroom.tscn"
const TXT := "res://ada_run/spider_sight.txt"

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _wall(st: Node3D, centre: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = size; cs.shape = bx; cs.position = centre
	b.add_child(cs); st.add_child(b)

func _floor(st: Node3D) -> void:
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(120, 1.0, 120); cs.shape = bx; cs.position = Vector3(0, -0.5, 0)
	fb.add_child(cs); st.add_child(fb)

func _run() -> void:
	var ps: PackedScene = load(MUSH) as PackedScene
	var fails: Array = []

	# ── A: a mushroom behind a wall, a visitor in the open ────────────────
	var a := Node3D.new(); get_root().add_child(a); current_scene = a
	_floor(a)
	_wall(a, Vector3(0, 0.9, -2.0), Vector3(9.0, 1.8, 0.35))
	var pa := Node3D.new(); pa.add_to_group("player")
	pa.set_script(preload("res://commons/testing/probe_crab_bite_dummy.gd"))
	a.add_child(pa); pa.global_position = Vector3(6.5, 0.5, 0.6)
	var ma: Node3D = ps.instantiate() as Node3D
	a.add_child(ma); ma.global_position = Vector3(0, 0, -3.4)     # behind the wall
	var ca: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	a.add_child(ca); ca.global_position = Vector3(0, 0, 0.6)
	ca.set("detect_m", 26.0)
	await create_timer(1.6).timeout
	_say("A — A MUSHROOM BEHIND A WALL")
	_say("  mushroom %.2f m away (through a wall), visitor %.2f m away (in the open)"
		% [ca.global_position.distance_to(ma.global_position),
		   ca.global_position.distance_to(pa.global_position)])
	_say("  can it see the mushroom: %s" % str(ca.call("_sees", ma.global_position)))
	_say("  can it see the visitor:  %s" % str(ca.call("_sees", pa.global_position)))
	if bool(ca.call("_sees", ma.global_position)):
		fails.append("A: it can see a mushroom through a wall")
	var t := 0.0
	var went_at_wall := false
	while t < 16.0:
		await create_timer(0.05).timeout
		t += 0.05
		if ca.global_position.z < -1.3:
			went_at_wall = true
		if int(pa.get("hits")) > 0:
			break
	_say("  it walked into the wall: %s" % str(went_at_wall))
	_say("  it reached the visitor: %s (%.2f s)" % [str(int(pa.get("hits")) > 0), t])
	if went_at_wall: fails.append("A: it set off toward the hidden mushroom")
	if int(pa.get("hits")) == 0: fails.append("A: it never went for the visitor")
	a.queue_free(); await process_frame

	# ── B: a mushroom in the open, nearer than the visitor ────────────────
	var b := Node3D.new(); get_root().add_child(b); current_scene = b
	_floor(b)
	var pb := Node3D.new(); pb.add_to_group("player")
	pb.set_script(preload("res://commons/testing/probe_crab_bite_dummy.gd"))
	b.add_child(pb); pb.global_position = Vector3(9.0, 0.5, 0)
	var mb: Node3D = ps.instantiate() as Node3D
	b.add_child(mb); mb.global_position = Vector3(-2.6, 0, 0)
	var cb: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	b.add_child(cb); cb.global_position = Vector3(0, 0, 0)
	cb.set("detect_m", 26.0)
	await create_timer(1.6).timeout
	_say("")
	_say("B — BOTH IN THE OPEN, THE MUSHROOM NEARER")
	_say("  mushroom %.2f m, visitor %.2f m" % [2.6, 9.0])
	var t2 := 0.0
	while t2 < 16.0 and int(cb.get("_degree")) < 1 and int(pb.get("hits")) == 0:
		await create_timer(0.05).timeout
		t2 += 0.05
	_say("  it ate the mushroom: %s   it bit the visitor: %s"
		% [str(int(cb.get("_degree")) > 0), str(int(pb.get("hits")) > 0)])
	if int(cb.get("_degree")) == 0: fails.append("B: it did not take the nearer mushroom")
	if int(pb.get("hits")) > 0: fails.append("B: it went for the visitor past a nearer mushroom")
	b.queue_free(); await process_frame

	# ── C: visible, unreachable ───────────────────────────────────────────
	var c := Node3D.new(); get_root().add_child(c); current_scene = c
	_floor(c)
	# a box round the mushroom, open only in a band at eye height
	var cx := -4.0
	# THE SLIT MUST STRADDLE THE EYE. The first version put the gap at y 0.20 to
	# 0.40 with the eye at exactly 0.20 — right on the lip, so the box was sealed
	# and the animal never even set off. A test that blocks the thing it means to
	# measure reports a pass for the wrong reason; this one reports nothing at
	# all, which is better but still useless.
	for sgn in [-1.0, 1.0]:
		_wall(c, Vector3(cx + sgn * 0.9, 0.06, 0.0), Vector3(0.2, 0.12, 2.0))   # below the eye
		_wall(c, Vector3(cx + sgn * 0.9, 1.15, 0.0), Vector3(0.2, 1.50, 2.0))   # above it
		_wall(c, Vector3(cx, 0.06, sgn * 0.9), Vector3(2.0, 0.12, 0.2))
		_wall(c, Vector3(cx, 1.15, sgn * 0.9), Vector3(2.0, 1.50, 0.2))
	var mc: Node3D = ps.instantiate() as Node3D
	c.add_child(mc); mc.global_position = Vector3(cx, 0, 0)
	var cc: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	c.add_child(cc); cc.global_position = Vector3(0.6, 0, 0)
	cc.set("detect_m", 26.0)
	await create_timer(1.6).timeout
	_say("")
	_say("C — VISIBLE THROUGH A SLIT, UNREACHABLE")
	var seen: bool = bool(cc.call("_sees", mc.global_position))
	_say("  can it see it: %s" % str(seen))
	if not seen:
		fails.append("C: the box sealed the sightline — the trial measures nothing")
	var gave_up := false
	var t3 := 0.0
	while t3 < 20.0:
		await create_timer(0.05).timeout
		t3 += 0.05
		var ig: Dictionary = cc.get("_ignore")
		if not ig.is_empty():
			gave_up = true
			break
	_say("  it gave up after %.2f s: %s" % [t3, str(gave_up)])
	if not gave_up:
		fails.append("C: it never gave up — this is the loop")

	_say("")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("it sees no walls through, takes the nearest food of either kind, and gives up on what it cannot reach"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() else 1)

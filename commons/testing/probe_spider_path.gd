extends SceneTree
## NOT STUCK AT A WALL (2026-08-27, Palle: "the collider blocks the spider and
## the spider is stuck in a loop").
##
## A U-shaped pocket with the visitor beyond its CLOSED side. Since the animal
## cannot see through a collider, that visitor is not food and not a target —
## so the only thing worth measuring here is the failure Palle reported: an
## animal pressed against a wall because something it wants is on the far side.
##
## It must not grind, and it must never be inside the wall.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const TXT := "res://ada_run/spider_path.txt"

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _wall(st: Node3D, centre: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = size; cs.shape = bx; cs.position = centre
	b.add_child(cs); st.add_child(b)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new()
	bm.size = size; mi.mesh = bm; mi.position = centre
	st.add_child(mi)

func _run() -> void:
	# WHAT THIS PROBE NOW ASKS (rewritten 2026-08-27). It used to stand the
	# spider in a U with the visitor beyond the closed side and check that A*
	# got it out. Line of sight made that premise false: a visitor behind a wall
	# is not a target at all, so the animal correctly stays put, and the trial
	# started passing by ACCIDENT — it wandered out on patrol and bit them at
	# 12.85 s while reporting it had never left the pocket.
	#
	# The claim worth keeping is Palle's actual complaint: "the collider blocks
	# the spider and the spider is stuck in a loop". So: put food it cannot see
	# beyond the wall, and measure whether it spends its life pressed against
	# that wall. It must not.
	_say("A U-SHAPED POCKET, WITH FOOD IT CANNOT SEE BEYOND THE BACK WALL")
	var st := Node3D.new(); get_root().add_child(st)
	current_scene = st
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(60, 1.0, 60); cs.shape = bx; cs.position = Vector3(0, -0.5, 0)
	fb.add_child(cs); st.add_child(fb)
	_wall(st, Vector3(-1.5, 0.7, 0.0), Vector3(0.4, 1.4, 4.4))
	_wall(st, Vector3(0.0, 0.7, 2.2), Vector3(3.4, 1.4, 0.4))
	_wall(st, Vector3(0.0, 0.7, -2.2), Vector3(3.4, 1.4, 0.4))

	var player := Node3D.new()
	player.name = "PlayerBody"
	player.add_to_group("player")
	player.set_script(preload("res://commons/testing/probe_crab_bite_dummy.gd"))
	st.add_child(player); player.global_position = Vector3(-4.6, 0.5, 0.0)

	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(c); c.global_position = Vector3(0.2, 0.0, 0.0)
	c.set("detect_m", 22.0)
	await create_timer(1.5).timeout
	_say("  can it see the visitor through the back wall: %s"
		% str(c.call("_sees", player.global_position)))
	if bool(c.call("_sees", player.global_position)):
		_say("  FAIL it can see through the back wall")

	var where: Array = []
	var grinding := 0
	var inside := 0
	var samples := 0
	var t := 0.0
	while t < 26.0:
		await create_timer(0.05).timeout
		t += 0.05
		samples += 1
		var p: Vector3 = c.global_position
		# pressed against the back wall, which is the loop
		if p.x < -0.85 and absf(p.z) < 2.2:
			grinding += 1
		# THE WALL'S ACTUAL EXTENT, not a padded band. -1.72..-1.28 was 2 cm
		# wider than the wall on each side, so a body resting AGAINST the face
		# counted as being inside it — which is how a correct animal produced
		# seven "inside the wall" samples in one run of six.
		if p.x > -1.70 and p.x < -1.30 and absf(p.z) < 2.20:
			inside += 1
			if where.size() < 6:
				where.append(Vector2(p.x, p.z))

	var pct: float = 100.0 * float(grinding) / float(maxi(1, samples))
	_say("")
	_say("  samples %d" % samples)
	_say("  pressed against the back wall on %d of them (%.1f%%)" % [grinding, pct])
	_say("  inside the back wall on %d" % inside)
	for wv in where:
		var w2: Vector2 = wv
		_say("      at x %.3f z %.3f   (wall x -1.70..-1.30, arms at z +/-2.2)" % [w2.x, w2.y])
	_say("  it ended at %s" % str(c.global_position))

	var fails: Array = []
	if inside > 0:
		fails.append("it got inside the wall on %d samples" % inside)
	if pct > 45.0:
		fails.append("it spent %.1f%% of its life against the wall — that is the loop" % pct)
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("it does not grind at a wall with food it cannot see behind it"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() else 1)

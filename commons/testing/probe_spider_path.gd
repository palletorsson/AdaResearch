extends SceneTree
## OUT OF A ROOM, NOT JUST ROUND A CORNER (2026-08-27, Palle: "yes make it path").
##
## Whiskers get an animal round an obstacle. They do not get it out of a pocket:
## a U-shaped alcove holds a whisker-steered body until it happens to wander
## out, because every local reading says "turn a bit" and none of them says
## "the way out is behind you".
##
## So: build a U, stand the spider INSIDE it, and put the visitor beyond the
## CLOSED side. The straight line to the visitor is a wall. The only way there
## is out of the mouth, along the outside, and back — which no local rule finds.
##
## Two runs, one instrument: path_on true, then false. The second is the
## negative test — if the animal escapes either way, the U is not a trap and
## the probe proves nothing.
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

## one run; returns [reached, seconds, max_path_len]
func _trial(with_path: bool) -> Array:
	var st := Node3D.new(); get_root().add_child(st)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(60, 1.0, 60); cs.shape = bx; cs.position = Vector3(0, -0.5, 0)
	fb.add_child(cs); st.add_child(fb)

	# THE U: closed on -x, arms running out to +x, mouth at +x
	_wall(st, Vector3(-1.5, 0.7, 0.0), Vector3(0.4, 1.4, 4.4))     # back
	_wall(st, Vector3(0.0, 0.7, 2.2), Vector3(3.4, 1.4, 0.4))      # north arm
	_wall(st, Vector3(0.0, 0.7, -2.2), Vector3(3.4, 1.4, 0.4))     # south arm

	var player := Node3D.new()
	player.name = "PlayerBody"
	player.add_to_group("player")
	player.set_script(preload("res://commons/testing/probe_crab_bite_dummy.gd"))
	st.add_child(player); player.global_position = Vector3(-4.6, 0.5, 0.0)

	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(c); c.global_position = Vector3(0.2, 0.0, 0.0)
	c.set("detect_m", 22.0)
	c.set("path_on", with_path)
	await create_timer(1.5).timeout

	var reached := false
	var t := 0.0
	var longest := 0
	var got_out := false
	while t < 40.0:
		await create_timer(0.05).timeout
		t += 0.05
		var pth: Array = c.get("_path")
		longest = maxi(longest, pth.size())
		if not got_out and c.global_position.x > 1.8:
			got_out = true
		if int(player.get("hits")) > 0:
			reached = true
			break
	st.queue_free()
	await process_frame
	return [reached, t, longest, got_out]

func _run() -> void:
	_say("A U-SHAPED TRAP — the visitor is beyond the closed side")
	_say("  back wall at x -1.5, arms at z +/-2.2 running to x +1.7, mouth at +x")
	_say("  spider starts INSIDE at (0.2, 0, 0); visitor at (-4.6, 0.5, 0)")
	_say("")

	var on: Array = await _trial(true)
	_say("PATHING ON")
	_say("  left the pocket: %s" % str(on[3]))
	_say("  longest path it held: %d waypoint(s)" % int(on[2]))
	_say("  reached the visitor: %s%s" % [str(on[0]), ("  in %.2f s" % float(on[1])) if on[0] else " (gave up at 40 s)"])
	_say("")

	var off: Array = await _trial(false)
	_say("PATHING OFF — the negative test, whiskers alone")
	_say("  left the pocket: %s" % str(off[3]))
	_say("  reached the visitor: %s%s" % [str(off[0]), ("  in %.2f s" % float(off[1])) if off[0] else " (gave up at 40 s)"])
	_say("")

	var fails: Array = []
	if not on[0]:
		fails.append("with pathing on it never reached the visitor")
	if int(on[2]) < 3:
		fails.append("it never held a path longer than %d waypoints — A* is not running" % int(on[2]))
	if off[0] and float(off[1]) < float(on[1]):
		fails.append("whiskers alone were FASTER — the U is not a trap and this proves nothing")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("it paths out of a pocket that whiskers cannot leave"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() else 1)

extends SceneTree
## AROUND, NOT THROUGH — AND NO JUMPING (2026-08-27, Palle: "spider most walk
## around colliders and can not jump (at least not the first spider)").
##
## A wall stands between the spider and the visitor, with a gap to one side. The
## two questions are whether it ever ends up INSIDE the wall, and whether it
## finds its way to the other side. Both are measured on the animal's own
## position, sampled every 40 ms, rather than judged from a picture.
##
## The jump is measured at the same time: every sample records the body's height
## above its own floor, and the lunge — which used to arc — must never lift it.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const TXT := "res://ada_run/spider_way_round.txt"

## the wall: a slab from x=-6 to x=+1.2, leaving a gap on the +x side
const WALL_MIN := Vector3(-6.0, 0.0, -0.6)
const WALL_MAX := Vector3(1.2, 1.4, 0.6)

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _inside(p: Vector3) -> bool:
	return p.x > WALL_MIN.x and p.x < WALL_MAX.x and p.z > WALL_MIN.z and p.z < WALL_MAX.z

func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(60, 1.0, 60); cs.shape = bx; cs.position = Vector3(0, -0.5, 0)
	fb.add_child(cs); st.add_child(fb)

	# THE WALL, on layer 1 like every grid cube
	var wall := StaticBody3D.new()
	var wcs := CollisionShape3D.new(); var wbx := BoxShape3D.new()
	var size: Vector3 = WALL_MAX - WALL_MIN
	wbx.size = size
	wcs.shape = wbx
	wcs.position = (WALL_MIN + WALL_MAX) * 0.5
	wall.add_child(wcs); st.add_child(wall)
	var wm := MeshInstance3D.new(); var wbm := BoxMesh.new()
	wbm.size = size; wm.mesh = wbm; wm.position = (WALL_MIN + WALL_MAX) * 0.5
	st.add_child(wm)

	# the visitor beyond it
	var player := Node3D.new()
	player.name = "PlayerBody"
	player.add_to_group("player")
	player.set_script(preload("res://commons/testing/probe_crab_bite_dummy.gd"))
	st.add_child(player); player.global_position = Vector3(-2.0, 0.5, 4.0)

	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(c); c.global_position = Vector3(-2.0, 0.0, -4.0)
	c.set("detect_m", 20.0)
	await create_timer(1.4).timeout

	_say("A WALL BETWEEN THEM")
	_say("  wall spans x %.1f..%.1f at z %.1f..%.1f — the gap is on the +x side"
		% [WALL_MIN.x, WALL_MAX.x, WALL_MIN.z, WALL_MAX.z])
	_say("  spider at %s, visitor at %s" % [str(c.global_position), str(player.global_position)])
	_say("  lunge_rise = %.2f" % float(c.get("lunge_rise")))
	_say("")

	var inside := 0
	var crossed := false
	var lift_max := 0.0
	var t := 0.0
	var samples := 0
	while t < 30.0:
		await create_timer(0.04).timeout
		t += 0.04
		samples += 1
		var p: Vector3 = c.global_position
		if _inside(p):
			inside += 1
		var lift: float = p.y - (float(c.get("_floor_y")) + float(c.get("_ride")))
		lift_max = maxf(lift_max, lift)
		if not crossed and p.z > WALL_MAX.z:
			crossed = true
			_say("  %5.2f s  it got to the far side at %s" % [t, str(p)])
		if int(player.get("hits")) > 0:
			_say("  %5.2f s  it reached the visitor" % t)
			break

	_say("")
	_say("  samples %d" % samples)
	_say("  inside the wall on %d of them (%.1f%%)" % [inside, 100.0 * float(inside) / float(maxi(1, samples))])
	_say("  highest it ever rose above its own ride height: %.4f m" % lift_max)
	_say("  reached the far side: %s" % str(crossed))
	_say("  bit the visitor: %s" % str(int(player.get("hits")) > 0))

	var fails: Array = []
	if inside > 0:
		fails.append("it was inside the wall on %d samples" % inside)
	if lift_max > 0.01:
		fails.append("it left the ground by %.3f m — it jumped" % lift_max)
	if not crossed:
		fails.append("it never found the way round")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("it went around, and it never left the floor" if fails.is_empty()
		else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() else 1)

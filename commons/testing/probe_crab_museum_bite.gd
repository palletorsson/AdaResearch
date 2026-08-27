extends SceneTree
## THE CRAB BITES IN THE MUSEUM (2026-08-27).
##
## The grid lane takes health and reloads. The museum lane cannot: damage there
## routes to a spawn point that a 4.8 km building does not have. So the animal
## calls the museum instead, and the museum decides — two flashes and a shove,
## then its own death back to the save point.
##
## The stand-in museum is a node with walker_bitten and an em_walker child,
## which is exactly the shape endless_museum presents.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const TXT := "res://ada_run/crab_museum_bite.txt"

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(60, 1.0, 60); cs.shape = bx; cs.position = Vector3.ZERO
	fb.add_child(cs); st.add_child(fb)

	var museum := Node3D.new()
	museum.name = "MockMuseum"
	museum.set_script(preload("res://commons/testing/probe_museum_dummy.gd"))
	st.add_child(museum)

	var walker := CharacterBody3D.new()
	walker.name = "Walker"
	walker.add_to_group("em_walker")
	museum.add_child(walker)
	walker.global_position = Vector3(0, 0.5, 0)
	museum.set("walker", walker)

	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(c)
	c.global_position = Vector3(0, 0.5, -7.0)
	c.set("detect_m", 14.0)
	await create_timer(1.4).timeout

	_say("THE MUSEUM LANE")
	_say("  a walker in group em_walker, under a node that answers walker_bitten")
	_say("")
	var t := 0.0
	var last := 0
	var killed_at := -1.0
	while t < 26.0:
		await create_timer(0.05).timeout
		t += 0.05
		var n: int = int(museum.get("bites"))
		if n > last:
			last = n
			_say("  %5.2f s  bite %d — museum flashed and shoved" % [t, n])
		if bool(museum.get("killed")) and killed_at < 0.0:
			killed_at = t
			_say("  %5.2f s  MUSEUM DEATH, kind '%s'" % [t, String(museum.get("kind"))])
			break

	_say("")
	var ok: bool = killed_at > 0.0 and int(museum.get("bites")) >= 3
	_say("  bites %d, lethal call %s" % [int(museum.get("bites")), "yes" if killed_at > 0.0 else "NO"])
	_say("VERDICT: %s" % ("the museum takes the bite and owns the death" if ok else "INCOMPLETE"))
	var f := FileAccess.open(TXT, FileAccess.WRITE)
	f.store_string("\n".join(PackedStringArray(_l)) + "\n"); f.close()
	quit(0 if ok else 1)

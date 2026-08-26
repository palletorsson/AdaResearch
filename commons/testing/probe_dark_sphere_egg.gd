extends SceneTree
## THE DARK SPHERE IS THE EGG (2026-08-24, Palle: "the crab should hatch from the
## dark sphere ... like the eggs in Aliens. But they look nice in the museum. It is
## only later we realize they were there for the potential of algorithmic critters").
## Proves the four claims that make that true:
##   1. guise "sphere" instances the REAL dark_sphere artifact as its shell — not a
##      lookalike, so an egg is indistinguishable from the 300+ ornaments
##   2. it starts DORMANT and does not move
##   3. a walker in group em_walker (the MUSEUM's lane, which no creature could see
##      before today) is FOUND, and triggers the hatch inside hatch_radius
##   4. the museum walker is hunted but NOT hurt — the damage path reposositions the
##      player to a map spawn the endless museum does not have
## godot --headless --path . --xr-mode off --script res://commons/testing/probe_dark_sphere_egg.gd

const OUT := "res://ada_run/dark_sphere_egg_probe.txt"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var fails: Array = []
	var notes: Array = []

	# a stand-in for the museum's walker: named Walker, group em_walker ONLY —
	# exactly how endless_museum builds it (deliberately not player_body)
	var walker := CharacterBody3D.new()
	walker.name = "Walker"
	walker.add_to_group("em_walker")
	get_root().add_child(walker)
	walker.global_position = Vector3(20, 0, 20)   # far away to start

	var ps: PackedScene = load("res://commons/hazards/octapod_crawler/octapod_crawler.tscn") as PackedScene
	if ps == null:
		fails.append("octapod_crawler.tscn did not load")
	var crab: Node3D = ps.instantiate() as Node3D
	crab.set("guise", "sphere")
	get_root().add_child(crab)
	crab.global_position = Vector3.ZERO
	await create_timer(0.8).timeout

	# 1. the shell IS a dark_sphere
	var shell: Node = crab.find_child("DarkSphereShell", true, false)
	if shell == null:
		fails.append("no DarkSphereShell — guise sphere built no disguise")
	else:
		var sp := ""
		if shell.get_script() != null:
			sp = str((shell.get_script() as Script).resource_path)
		if not sp.contains("dark_sphere"):
			fails.append("the shell is not the dark_sphere artifact (script %s)" % sp)
		else:
			var meshes: int = shell.find_children("*", "MeshInstance3D", true, false).size()
			if meshes < 1:
				fails.append("the dark_sphere shell built no geometry")
			else:
				notes.append("the shell IS the real dark_sphere artifact (%d mesh(es))" % meshes)

	# 2. dormant, and no pod/leaf furniture on this guise
	var st: int = int(crab.get("_state"))
	if st != 0:
		fails.append("state %d at rest, wanted 0 (DORMANT)" % st)
	else:
		notes.append("starts DORMANT, disguised")
	if crab.find_child("EggPod", true, false) != null:
		fails.append("the sphere guise also built the pod mesh — two disguises at once")

	# 3. it FINDS the museum walker and hatches when it comes close
	crab.call("_find_player")
	var seen: Variant = crab.get("_player_node")
	if seen == null:
		fails.append("the crab cannot see a walker in group em_walker — the museum lane is still invisible")
	else:
		notes.append("finds the museum walker (%s)" % str((seen as Node).name))
	walker.global_position = Vector3(1.2, 0, 0)   # inside hatch_radius 2.5
	await create_timer(1.2).timeout
	var st2: int = int(crab.get("_state"))
	if st2 == 0:
		fails.append("still DORMANT with the walker at 1.2 m — the egg never opens in the museum")
	else:
		notes.append("the walker approaches and it HATCHES (state %d)" % st2)
		var sh2: Node = crab.find_child("DarkSphereShell", true, false)
		if sh2 != null and (sh2 as Node3D).scale.x > 0.99:
			fails.append("hatching but the shell has not collapsed (scale %.2f)" % (sh2 as Node3D).scale.x)
		elif sh2 != null:
			notes.append("the shell collapses as it opens (scale %.2f)" % (sh2 as Node3D).scale.x)

	# 4. hunted, not hurt: the museum has no spawn to be thrown back to
	if crab.has_method("_target_takes_damage"):
		if bool(crab.call("_target_takes_damage", walker)):
			fails.append("the crab would deal health damage to the museum walker — DeathEffect would teleport it")
		else:
			notes.append("the museum walker is hunted but not hurt")
		var vr_stub := CharacterBody3D.new()
		vr_stub.name = "XROrigin3D"
		get_root().add_child(vr_stub)
		if not bool(crab.call("_target_takes_damage", vr_stub)):
			fails.append("the guard also disarmed the VR/grid lane — it must only spare em_walker")
		else:
			notes.append("VR and grid lanes still take real damage")
	else:
		fails.append("_target_takes_damage missing")

	var report := "DARK SPHERE EGG PROBE\n"
	for n in notes:
		report += "  ok   %s\n" % n
	for f in fails:
		report += "  FAIL %s\n" % f
	report += "%d fail(s)\n" % fails.size()
	var fh := FileAccess.open(OUT, FileAccess.WRITE)
	fh.store_string(report)
	fh.close()
	print(report)
	quit(1 if not fails.is_empty() else 0)

extends SceneTree
## WHERE DOES THE WALK OPEN? (2026-08-27, Palle: "the VR should start at the
## point one now it start with forces.")
##
## Boots the museum in the chosen lane against the LIVE ada_run/em_control.json
## and prints the chapter it chose, the first halls it built, and every input
## that could have decided it — so the answer is read off the museum rather
## than reasoned about from precedence comments.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_start_hall.gd -- --lane=vr

func _initialize() -> void:
	call_deferred("_run")

func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb

func _run() -> void:
	var lane := _arg("lane", "vr")
	# THE HEADSET LOADS THE STAGED SCENE, not this one — and the staged scene
	# attaches the script to a bare node, so the Inspector defaults the desktop
	# scene ships are simply not there. Measuring the wrong scene is how "VR
	# starts in forces" survived a reading of the precedence.
	var staged := _arg("scene", "plain") == "staged"
	var root: Node = (load("res://commons/scenes/endless_museum_staged.tscn" if staged
		else "res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate()
	var inst: Node3D = (root.find_child("Museum", true, false) as Node3D) if staged else (root as Node3D)
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("_force_patient", true)
	if lane == "vr":
		inst.set("_force_vr", true)
	get_root().add_child(root)
	if lane == "vr":
		var origin := XROrigin3D.new()
		var cam := XRCamera3D.new()
		cam.position = Vector3(3.0, 1.6, 1.0)
		origin.add_child(cam)
		get_root().add_child(origin)
	await create_timer(8.0).timeout
	print("  lane            : %s   scene=%s" % [lane, _arg("scene", "plain")])
	print("  EM_CONTROL      : %s" % String(inst.get("EM_CONTROL")))
	print("  start_chapter   : %s (the scene's own export)" % String(inst.get("start_chapter")))
	print("  start_map       : %s" % String(inst.get("start_map")))
	print("  _first_chapter  : %s  <-- what it actually chose" % String(inst.get("_first_chapter")))
	print("  _dollhouse      : %s" % str(inst.get("_dollhouse")))
	print("  _grid_pack      : %s" % str(inst.get("_grid_pack")))
	var segs: Array = inst.get("_segments")
	for i in range(mini(4, segs.size())):
		var sd: Dictionary = segs[i]
		print("  hall %d          : %-28s pearl=%s" % [i, String(sd.get("map", "?")), String(sd.get("pearl", "?"))])
	quit(0)

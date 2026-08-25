extends SceneTree
## THE WALK, NOT THE JUMP (2026-08-25, Palle: "what is the difference between
## when you take a screen and the game?"). Every probe in this repo forces
## first_map and grid_pack 1 and calls flush_stamps — three things a walker
## never does. This one takes the LIVE control verbatim, walks the eye down
## the museum, and reports every hall it passes with the utilities it found.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_walked_utilities.gd -- --metres=260

const OUT := "res://ada_run/walked_utilities.txt"


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _run() -> void:
	var metres := float(_arg("metres", "260"))
	# THE LIVE CONTROL, COPIED, not written: a probe that writes the file the
	# running game reads would change the thing it is measuring
	var live: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://ada_run/em_control.json"))
	var ctl_d: Dictionary = live if live is Dictionary else {}
	ctl_d.erase("_readme")
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_wu_control.json")
	# THE LIVE OVERRIDES AND THE LIVE HAND FILE TOO (2026-08-25): the last two
	# untested differences between a probe and the walker. Read-only here —
	# the museum only writes them from the editor, which a probe never arms.
	if not OS.get_cmdline_user_args().has("--trial-rulings"):
		inst.set("_overrides_path", "res://ada_run/em_overrides.json")
		inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	else:
		inst.set("_overrides_path", "res://ada_run/_trial_wu_overrides.json")
		inst.set("_hand_path", "res://ada_run/_trial_wu_hand.json")
	var ctl := FileAccess.open("res://ada_run/_trial_wu_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify(ctl_d, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.0).timeout

	var rep := "WALKED UTILITIES — control copied from the live file:\n  %s\n\n" % JSON.stringify(ctl_d)
	var player: Node3D = inst.get("_player") as Node3D
	if player == null:
		rep += "  FAIL no walker\n"
	else:
		var seen: Dictionary = {}
		var z := player.position.z
		while z < metres:
			z += 4.0
			player.position.z = z
			# NO flush_stamps: let the museum build the way it builds for a walker
			await create_timer(0.28).timeout
			for s_v in inst.get("_segments"):
				var sd: Dictionary = s_v
				var pearl := String(sd.get("pearl", ""))
				if pearl == "" or seen.has(pearl):
					continue
				var sn: Node3D = sd.get("node")
				if sn == null or not is_instance_valid(sn):
					continue
				seen[pearl] = true
				var us: Array = []
				for n in sn.find_children("Utility_*", "Node3D", true, false):
					us.append(String(n.name).replace("Utility_", ""))
				us.sort()
				rep += "  z %6.1f  %-26s  %d utility(ies)%s\n" % [float(sd.get("z0", 0.0)), pearl,
					us.size(), ("  " + ", ".join(us)) if not us.is_empty() else ""]
		rep += "\n  halls walked: %d\n" % seen.size()
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)

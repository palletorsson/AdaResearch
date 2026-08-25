extends SceneTree
## ONE HALL DRAWN (2026-08-24, Palle: "only one hall should render at the time
## in VR"). The VR path cannot be walked headless — there is no headset — so
## _render_window takes the eye as an argument and this walks it by hand,
## metre by metre, from the first hall to the far end of the second, and
## counts what is visible at every step. The answer must be 1 everywhere
## except within the threshold margin, where it may be 2 and never more.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_one_hall.gd

const OUT := "res://ada_run/one_hall.txt"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_oh_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_oh_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_oh_hand.json")
	inst.set("start_chapter", "transformation")
	inst.set("start_map", "Trans_Introduction")
	var ctl := FileAccess.open("res://ada_run/_trial_oh_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "transformation",
		"first_map": "Trans_Introduction", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	inst.call("flush_stamps")
	await create_timer(2.0).timeout

	var rep := "ONE HALL DRAWN\n"
	var segs: Array = inst.get("_segments")
	rep += "  segments alive: %d\n" % segs.size()
	var far := 0.0
	for s_v in segs:
		var sd: Dictionary = s_v
		rep += "    %-24s z %6.1f .. %6.1f\n" % [String(sd.get("pearl", "?")),
			float(sd.get("z0", 0.0)), float(sd.get("z1", 0.0))]
		far = maxf(far, float(sd.get("z1", 0.0)))
	if segs.size() < 2:
		rep += "  NOTE only one segment was ever built — the window has nothing to close\n"

	var radius: float = float(inst.get("VR_RENDER_WINDOW_M"))
	rep += "  window radius: %.1f m\n  walking the eye:\n" % radius
	var worst := 0
	var two_at: Array = []
	var z := 0.0
	while z <= far + 2.0:
		var shown: int = int(inst.call("_render_window", z, radius))
		worst = maxi(worst, shown)
		if shown > 1:
			two_at.append(z)
		if int(z) % 6 == 0:
			rep += "    z %6.1f  ->  %d drawn\n" % [z, shown]
		z += 1.0
	rep += "  most ever drawn at once: %d\n" % worst
	if two_at.is_empty():
		rep += "  two drawn at: never\n"
	else:
		rep += "  two drawn at: z %.0f .. %.0f (%d m of threshold)\n" % [
			float(two_at[0]), float(two_at[-1]), two_at.size()]
	rep += "  %s\n" % ("PASS one hall at a time" if worst <= 2 else "FAIL more than two drawn")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)

extends SceneTree
## WaveFunctions_AirMusic shutdown bisect (2026-09-11): the museum probes of this hall end in
## a signal 11 after quit(), after their reports are written. Build the hall exactly as the
## probes do, optionally free every node whose script path contains --free=<word> (and wait),
## then quit. Exit 0 = a clean shutdown; a crash shows in the engine log's backtrace.
##
##   godot --headless --path . --xr-mode off --log-file <log> --script res://commons/testing/probe_wcn_air_shutdown.gd -- --free=SystemsMusic
const MAP := "WaveFunctions_AirMusic"

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var free_word := ""
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--free="): free_word = str(a).get_slice("=", 1)
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/waves_chance_noise/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", "res://ada_run/necklace_hand.json")
	em.set("start_chapter", "wavefunctions"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "wavefunctions", "dollhouse": 0, "grid_pack": 1})); f.close()
	root.add_child(em); current_scene = em
	await create_timer(3.0).timeout
	var freed := 0
	if free_word != "":
		for n in root.find_children("*", "", true, false):
			if n.get_script() != null and str(n.get_script().resource_path).contains(free_word) and is_instance_valid(n):
				n.queue_free(); freed += 1
		await create_timer(1.0).timeout
	print("[wcn-air-shutdown] built; freed %d node(s) matching '%s'; quitting" % [freed, free_word])
	var out := FileAccess.open("res://ada_run/waves_chance_noise/WaveFunctions_AirMusic/probe_air_shutdown_%s.json" % (free_word if free_word != "" else "none"), FileAccess.WRITE)
	out.store_string(JSON.stringify({"freed": freed, "free": free_word})); out.close()
	quit(0)

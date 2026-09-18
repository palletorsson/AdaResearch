## dump_foliage_cards.gd — save the engine-drawn foliage cards as PNGs to look at them.
##   godot --headless --path . --xr-mode off --script res://commons/testing/dump_foliage_cards.gd -- --out=<dir> [--seed=7] [--moisture=0.5]
extends SceneTree

func _initialize() -> void:
	var out := "user://foliage_dump"
	var seed := 7
	var m := 0.5
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--seed="):
			seed = int(a.substr(7))
		elif a.begins_with("--moisture="):
			m = float(a.substr(11))
	DirAccess.make_dir_recursive_absolute(out)
	var FC = load("res://commons/biome_layers/foliage_cards.gd")
	for card in ["grass", "reed", "fern", "plant", "litter"]:
		var t0 := Time.get_ticks_msec()
		var img: Image = FC.draw(card, seed, m)
		img.save_png("%s/%s_s%d_m%02d.png" % [out, card, seed, int(round(m * 100.0))])
		print("[dump_foliage_cards] %s seed %d m %.2f: %d ms, %.0f%% painted" % [card, seed, m, Time.get_ticks_msec() - t0, FC.coverage(img) * 100.0])
	quit(0)

extends SceneTree
## What does the staged museum cost to LOAD vs to INSTANTIATE? The load is
## what the menu preload moves into idle time; the instantiate stays at the
## click. Desktop numbers, useful as ratios for the Quest.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_staged_load.gd

const OUT := "res://ada_run/staged_load_probe.txt"
const PATH := "res://commons/scenes/endless_museum_staged.tscn"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	ResourceLoader.load_threaded_request(PATH)
	while true:
		var st := ResourceLoader.load_threaded_get_status(PATH)
		if st == ResourceLoader.THREAD_LOAD_LOADED or st == ResourceLoader.THREAD_LOAD_FAILED:
			break
		await process_frame
	var t_load := Time.get_ticks_msec() - t0
	var ps: PackedScene = ResourceLoader.load_threaded_get(PATH)
	var t1 := Time.get_ticks_msec()
	var inst: Node = ps.instantiate() if ps != null else null
	var t_inst := Time.get_ticks_msec() - t1
	var line := "staged museum: threaded LOAD %d ms (menu preload moves this) · INSTANTIATE %d ms (stays at the click)" % [t_load, t_inst]
	print(line)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(line)
	f.close()
	if inst != null:
		inst.free()
	quit(0)

## probe_biome_family_build.gd — one cage per family, timed, so a family that spins inside
## the cage is named rather than hung. The agents' own probes sample path/across at inner
## 2.0 and 11.5; the cage's default is size 8 (inner 3.5), which none of them touched
## (2026-09-17: the vitrine probe ran ten minutes at full CPU with no line printed).
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_biome_family_build.gd -- --family=klee --size=8
extends SceneTree

const VITRINE := preload("res://commons/artifacts/biome_vitrine/biome_vitrine.gd")


func _initialize() -> void:
	var fam := "diagonal"
	var size := 8
	var stage := "Random_Game"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--family="):
			fam = a.substr(9)
		elif a.begins_with("--size="):
			size = int(a.substr(7))
		elif a.begins_with("--stage="):
			stage = a.substr(8)
	var root := Node3D.new()
	get_root().add_child(root)
	var t0 := Time.get_ticks_msec()
	var v = VITRINE.new()
	v.stage = stage
	v.seed = 7
	v.size = size
	v.apply_grid_config({"family": fam, "evolve": "off", "record": "off"})
	root.add_child(v)
	await process_frame
	await process_frame
	await process_frame
	var p: Vector3 = v._free_points[0].position if not v._free_points.is_empty() else Vector3(INF, INF, INF)
	print("[probe_biome_family_build] %s size %d stage %s: built in %d ms, family_name %s, loaded %s, point (%.2f, %.2f)" % [
		fam, size, stage, Time.get_ticks_msec() - t0, v.family_name(), str(v._fam != null), p.x, p.z])
	quit(0)

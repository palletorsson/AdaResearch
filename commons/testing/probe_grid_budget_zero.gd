extends SceneTree
## THE NEGATIVE TEST, AND THE POSITIVE ONE (2026-08-26). place_budget_ms
## defaults to 0 and must mean exactly what it meant before it existed: every
## artifact lands on ONE frame. Above 0 they must land over several. Both are
## measured the same way - count artifacts per frame after the grid is added -
## because GridSystem._ready already awaits a frame before it loads, so
## "synchronous with add_child" was never the contract to test.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_grid_budget_zero.gd

const OUT := "res://ada_run/grid_budget_zero.txt"


func _initialize() -> void:
	call_deferred("_run")


func _count(n: Node) -> int:
	var c := 0
	for x in n.find_children("*", "Node3D", true, false):
		if x.has_meta("artifact_lookup_name"):
			c += 1
	return c


func _watch(budget: float) -> Dictionary:
	var gs: Node3D = (load("res://commons/grid/grid_system.tscn") as PackedScene).instantiate() as Node3D
	gs.set("map_name", "Trans_Translation")
	gs.set("bare_world", true)
	gs.set("skip_player_spawn", true)
	gs.set("interactable_place_budget_ms", budget)
	get_root().add_child(gs)
	var per_frame: Array = []
	var last := 0
	var worst := 0
	for f in range(240):
		var t0 := Time.get_ticks_usec()
		await process_frame
		var ms := int((Time.get_ticks_usec() - t0) / 1000)
		var n := _count(gs)
		if n != last:
			per_frame.append({"frame": f, "added": n - last, "ms": ms})
			last = n
			worst = maxi(worst, ms)
		if last >= 13 and f > 20:
			break
	gs.queue_free()
	await process_frame
	return {"total": last, "frames": per_frame.size(), "worst_ms": worst, "rows": per_frame}


func _run() -> void:
	var rep := "GRID BUDGET — where the artifacts land\n\n"
	for b in [0.0, 8.0]:
		var r: Dictionary = await _watch(b)
		rep += "  place_budget_ms = %.0f\n" % b
		rep += "    %d artifact(s), arriving over %d frame(s), worst frame %d ms\n" % [
			r["total"], r["frames"], r["worst_ms"]]
		for row_v in (r["rows"] as Array):
			var row: Dictionary = row_v
			rep += "      frame %3d  +%d  (%d ms)\n" % [row["frame"], row["added"], row["ms"]]
		rep += "\n"
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)

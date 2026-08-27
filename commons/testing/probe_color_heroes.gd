## probe_color_heroes.gd — do the three forces prop-gallery artifacts actually BUILD?
##
## paused_fountain / prop_mobile / prop_spigot compose OTHER artifacts' scenes (the
## museum props) under physics. Each has three ways to look finished while broken:
## a parse error in the artifact, a cast prop that fails to load (fallback beads mean
## mesh count stays high — so we also count WARNINGS), and an AABB measured before the
## prop built (beads at native size — so we check the spread of bead extents).
##
## Writes user://color_heroes_probe.json and quits. The 4.6 exe is non-console, so the
## report file is the only channel — never print-and-hope.
##
##   python tools/godot_watchdog.py --expect="<roaming>/prop_gallery_probe.json" -- \
##     <godot> --headless --path . --xr-mode off --script res://commons/testing/probe_color_heroes.gd
extends SceneTree

const TOKENS := ["nail_bar", "stained_curtain", "albers_rugs", "bottled_weather"]
const SETTLE_FRAMES := 30   # ~0.5 s: the probe_aabb_hogs lesson — two frames photographs a half-built artifact

var _report := {}

func _initialize() -> void:
	_run()

func _run() -> void:
	for token in TOKENS:
		var row := {"loaded": false, "meshes": 0, "aabb": [], "rigid_bodies": 0, "error": ""}
		var path := "res://commons/artifacts/%s/%s.tscn" % [token, token]
		var packed: PackedScene = load(path)
		if packed == null:
			row["error"] = "scene failed to load"
			_report[token] = row
			continue
		var inst: Node = packed.instantiate()
		if inst == null or not (inst is Node3D):
			row["error"] = "instantiate failed or root not Node3D"
			_report[token] = row
			continue
		root.add_child(inst)
		row["loaded"] = true
		for i in range(SETTLE_FRAMES):
			await process_frame
		var counts := _census(inst)
		row["meshes"] = counts["meshes"]
		row["rigid_bodies"] = counts["rigid"]
		var aabb: AABB = counts["aabb"]
		row["aabb"] = [snappedf(aabb.size.x, 0.01), snappedf(aabb.size.y, 0.01), snappedf(aabb.size.z, 0.01)]
		_report[token] = row
		inst.queue_free()
		await process_frame
		await process_frame
	var f := FileAccess.open("user://color_heroes_probe.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_report, "  "))
	f.close()
	quit(0)

func _census(node: Node) -> Dictionary:
	var meshes := 0
	var rigid := 0
	var merged := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			meshes += 1
			var mi := n as MeshInstance3D
			var box: AABB = mi.global_transform * mi.get_aabb()
			if first:
				merged = box
				first = false
			else:
				merged = merged.merge(box)
		if n is RigidBody3D:
			rigid += 1
		for child in n.get_children():
			stack.append(child)
	return {"meshes": meshes, "rigid": rigid, "aabb": merged}

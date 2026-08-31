## probe_wave_heroes.gd — do the six wavefunctions category heroes actually BUILD?
##
## shadow_carousel / bleacher_wave / epicycle_desk / aria_glass / groove_lens /
## unreliable_clock. Each is procedural in _ready(); the ways to look finished while
## broken: a parse error (script silently detaches, 0 meshes), a Variant `:=` that
## fails to compile, an AABB measured before TextScreen settles. Mesh count and the
## merged AABB are the detectors; the double-pendulum trace in unreliable_clock also
## proves the integrator ran (beads push the mesh count past the case's ~20).
##
## Writes user://wave_heroes_probe.json and quits. The 4.6 exe is non-console, so the
## report file is the only channel — never print-and-hope.
##
##   python tools/godot_watchdog.py --expect="<roaming>/wave_heroes_probe.json" -- \
##     <godot> --headless --path . --xr-mode off --script res://commons/testing/probe_wave_heroes.gd
extends SceneTree

const TOKENS := ["shadow_carousel", "bleacher_wave", "epicycle_desk", "aria_glass", "groove_lens", "unreliable_clock"]
const SETTLE_FRAMES := 30   # ~0.5 s: the probe_aabb_hogs lesson — two frames photographs a half-built artifact

var _report := {}

func _initialize() -> void:
	_run()

func _run() -> void:
	for token in TOKENS:
		var row := {"loaded": false, "meshes": 0, "aabb": [], "error": ""}
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
		var aabb: AABB = counts["aabb"]
		row["aabb"] = [snappedf(aabb.size.x, 0.01), snappedf(aabb.size.y, 0.01), snappedf(aabb.size.z, 0.01)]
		_report[token] = row
		inst.queue_free()
		await process_frame
		await process_frame
	var f := FileAccess.open("user://wave_heroes_probe.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_report, "  "))
	f.close()
	quit(0)

func _census(node: Node) -> Dictionary:
	var meshes := 0
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
		for child in n.get_children():
			stack.append(child)
	return {"meshes": meshes, "aabb": merged}

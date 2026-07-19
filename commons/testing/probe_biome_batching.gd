# probe_biome_batching.gd — biome-6 gate: batched rendering + per-map budget.
#
# Run:  <godot> --headless --path . --xr-mode off --script res://commons/testing/probe_biome_batching.gd
#
# A: synthetic perimeter-halo map batches into O(kingdoms) nodes, no clamp.
# B: same layer under a tiny _meta budget — the clamp BITES (negative test).
# C: empty layer constructs nothing.
# D: the real Biome_HaloTest rows batch into few nodes.
#
# GridSystem/GridDataComponent are NOT bare-load()ed here: scripts that name
# autoload singletons (GameManager) cannot compile in --script mode — verified
# identical at HEAD, a mode limitation, not a regression signal. Their gate is
# the live map-load (capture Biome_HaloTest + Biome_HaloBudget).
extends SceneTree

const ComponentScript = preload("res://commons/grid/GridBiomeComponent.gd")

var _failures: int = 0


func _init() -> void:
	_case_a_and_b()
	_case_c()
	_case_d()
	if _failures == 0:
		print("PROBE PASS: biome-6 batching (all cases)")
		quit(0)
	else:
		print("PROBE FAIL: %d case(s)" % _failures)
		quit(1)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		print("  ok   %s — %s" % [name, detail])
	else:
		print("  FAIL %s — %s" % [name, detail])
		_failures += 1


func _synthetic_layer(cols: int, rows: int) -> Array:
	# full perimeter halo, mixed kingdoms; a few interior marker-path seeds
	var kingdoms: Array = ["flora", "fungus", "water", "mineral"]
	var layer: Array = []
	for r in range(rows):
		var line: Array = []
		for c in range(cols):
			var on_edge: bool = (r == 0 or r == rows - 1 or c == 0 or c == cols - 1)
			if on_edge:
				var k: String = kingdoms[(r + c) % kingdoms.size()]
				line.append("%s:scatter:halo:d=0.8" % k)
			elif (r * cols + c) % 37 == 0:
				line.append("mineral:vein:seed:d=0.5")
			else:
				line.append("")
		layer.append(line)
	return layer


func _structure(cols: int, rows: int) -> Array:
	var s: Array = []
	for _r in range(rows):
		var line: Array = []
		for _c in range(cols):
			line.append("1")
		s.append(line)
	return s


func _run_component(layer: Array, structure: Array, meta: Dictionary) -> Node3D:
	var comp: Node3D = ComponentScript.new()
	root.add_child(comp)
	comp.initialize(null, 1.0, 0.0)
	comp.generate(layer, structure, 0, meta)
	return comp


func _case_a_and_b() -> void:
	print("CASE A — synthetic 20x14 perimeter halo, no budget:")
	var layer: Array = _synthetic_layer(20, 14)
	var structure: Array = _structure(20, 14)
	var a: Node3D = _run_component(layer, structure, {})
	var sa: Dictionary = a.get_stats()
	var nodes_a: int = int(sa.get("nodes", 0))
	var inst_a: int = int(sa.get("instances", 0))
	_check("nodes are O(kingdoms)", nodes_a > 0 and nodes_a <= 24,
		"%d batch nodes (was one-plus per cell for 64 halo cells)" % nodes_a)
	_check("instances present", inst_a > 200, "%d instances" % inst_a)
	_check("no clamp under default budget", int(sa.get("budget_dropped", 0)) == 0,
		"dropped=%d" % int(sa.get("budget_dropped", 0)))
	a.queue_free()
	print("CASE B — same layer, _meta budget_instances=100 (must bite):")
	var b: Node3D = _run_component(layer, structure, {"budget_instances": 100})
	var sb: Dictionary = b.get_stats()
	var inst_b: int = int(sb.get("instances", 0))
	var dropped_b: int = int(sb.get("budget_dropped", 0))
	_check("clamp bites", dropped_b > 0, "dropped=%d" % dropped_b)
	_check("instances within budget (+batch minimums)", inst_b <= 100 + 24,
		"kept=%d budget=100" % inst_b)
	_check("determinism", inst_a == inst_b + dropped_b,
		"A=%d == B kept %d + dropped %d" % [inst_a, inst_b, dropped_b])
	b.queue_free()


func _case_c() -> void:
	print("CASE C — empty layer constructs nothing:")
	var c: Node3D = _run_component([], _structure(4, 4), {})
	_check("zero children", c.get_child_count() == 0, "%d children" % c.get_child_count())
	c.queue_free()


func _case_d() -> void:
	print("CASE D — real map Biome_HaloTest:")
	var f: FileAccess = FileAccess.open("res://commons/maps/Biome_HaloTest/map_data.json", FileAccess.READ)
	if f == null:
		_check("map readable", false, "cannot open Biome_HaloTest")
		return
	var md: Dictionary = JSON.parse_string(f.get_as_text())
	var layers: Dictionary = md.get("layers", {})
	var biome: Array = layers.get("biome", [])
	var structure: Array = layers.get("structure", [])
	var d: Node3D = _run_component(biome, structure, {})
	var sd: Dictionary = d.get_stats()
	_check("nodes small on real map", int(sd.get("nodes", 0)) > 0 and int(sd.get("nodes", 0)) <= 20,
		"%d nodes for %d cells, %d instances" % [
			int(sd.get("nodes", 0)), int(sd.get("cells", 0)), int(sd.get("instances", 0))])
	d.queue_free()



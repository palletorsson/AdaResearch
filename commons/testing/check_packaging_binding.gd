extends SceneTree

## Verify the packaging binding chain without a full map:
##   1. GridInteractablesComponent.gd still PARSES (a syntax error there breaks the grid).
##   2. PackagingResolver.resolve produces sane specs for representative spatial_needs.
##   3. each resolved spec actually instantiates valid packaging (apply_grid_config builds geometry).
## Report -> ada_run/packaging_binding_report.txt.

const Resolver := preload("res://commons/artifacts/_hangar/packaging_resolver.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var lines: Array[String] = []
	var ok := true

	# 1. component parses
	var comp = load("res://commons/grid/GridInteractablesComponent.gd")
	var comp_ok := comp != null
	ok = ok and comp_ok
	lines.append("GridInteractablesComponent.gd parses : %s" % str(comp_ok))

	# 2 + 3. resolve samples, then instantiate every spec
	var samples := [
		{"name": "Point", "sn": {"platform": "pedestal", "footprint_cells": 1}, "aabb": Vector3(0.4, 0.5, 0.4)},
		{"name": "Adder Board", "sn": {"platform": "table", "footprint_cells": 2}, "aabb": Vector3(0.8, 0.3, 0.6)},
		{"name": "Lorenz Attractor", "sn": {"platform": "none", "footprint_cells": 9}, "aabb": Vector3(3.0, 2.0, 3.0)},
		{"name": "Reaction Diffusion", "sn": {"platform": "none", "footprint_cells": 2, "wall_backing": true}, "aabb": Vector3(1.2, 2.0, 0.3)},
		{"name": "Grid Lines", "sn": {"platform": "sunken", "footprint_cells": 4}, "aabb": Vector3(1.0, 0.2, 1.0)},
	]
	var root := Node3D.new()
	get_root().add_child(root)

	for s in samples:
		var specs: Array = Resolver.resolve(s["sn"], s["aabb"], s["name"])
		var tags: Array = []
		for sp in specs:
			tags.append("%s%s" % [
				str(sp["scene"]).get_file().replace(".tscn", ""),
				("↑%.2f" % float(sp.get("raise_to", -1.0))) if float(sp.get("raise_to", -1.0)) >= 0.0 else ""])
		lines.append("%-20s platform=%-8s -> %s" % [s["name"], str(s["sn"].get("platform", "?")), ", ".join(PackedStringArray(tags))])
		# instantiate each spec
		for sp in specs:
			var packed = load(str(sp["scene"]))
			if packed == null:
				lines.append("    FAIL load %s" % sp["scene"]); ok = false; continue
			var inst = packed.instantiate()
			if inst == null:
				lines.append("    FAIL instantiate %s" % sp["scene"]); ok = false; continue
			root.add_child(inst)
			if inst.has_method("apply_grid_config"):
				inst.apply_grid_config(sp.get("dna", {}))
			await process_frame
			var n := _count_meshes(inst)
			if n == 0:
				lines.append("    FAIL %s built 0 meshes" % str(sp["scene"]).get_file()); ok = false
			inst.queue_free()

	lines.append("-----------------------------------------------")
	lines.append("VERDICT: %s" % ("PASS — binding chain valid" if ok else "FAIL — see above"))
	var report := "\n".join(PackedStringArray(lines))
	print("\n" + report)
	var abs := ProjectSettings.globalize_path("res://ada_run/packaging_binding_report.txt")
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(report + "\n")
		f.close()
	quit(0 if ok else 2)


func _count_meshes(node: Node) -> int:
	var n := 0
	if node is MeshInstance3D or node is MultiMeshInstance3D:
		n += 1
	for c in node.get_children():
		n += _count_meshes(c)
	return n

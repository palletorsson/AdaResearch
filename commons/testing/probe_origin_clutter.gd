extends SceneTree
## WHAT IS STANDING ON POINT ZERO?
##
## Palle, looking at the foyer: a column drives straight down through the origin
## well and through the coordinate cube, and dark slabs lie around the pit that do
## not match the terrazzo. Naming them from a screenshot is guessing; this builds
## the museum and reports every mesh whose world footprint overlaps the well
## (x -1..1, z -1..1), with its size, its Y span and the ancestor chain that made
## it — which is enough to find the line that builds it.
##
## It injects its own EM_CONTROL so a live session's control file is never
## touched, per the standing rule.
##
##   godot --headless --path . --xr-mode off \
##       --script res://commons/testing/probe_origin_clutter.gd

const R := 1.6      # half-extent of the region of interest around the origin


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_origin_clutter_control.json")
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	for i in range(10):
		await create_timer(0.3).timeout

	var hits: Array = []
	_walk(inst, hits)
	hits.sort_custom(func(a, b): return float(a["y1"]) > float(b["y1"]))

	print("\n=== meshes overlapping the origin well (|x|<=%.1f, |z|<=%.1f) ===" % [R, R])
	print("%-34s %-22s %-16s %s" % ["node", "size (x,y,z)", "y span", "parent chain"])
	for h in hits:
		print("%-34s %-22s %-16s %s" % [
			str(h["name"]).substr(0, 33),
			"(%.2f, %.2f, %.2f)" % [h["sx"], h["sy"], h["sz"]],
			"%.2f .. %.2f" % [h["y0"], h["y1"]],
			str(h["chain"]).substr(0, 60)])
	print("\n%d mesh(es) stand in or over the well." % hits.size())
	quit(0)


func _walk(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		if mi.mesh != null:
			var ab: AABB = mi.mesh.get_aabb()
			var g: Transform3D = mi.global_transform
			var c: Vector3 = g * ab.get_center()
			var s: Vector3 = ab.size * g.basis.get_scale()
			# does its footprint touch the well?
			if abs(c.x) - s.x * 0.5 < R and abs(c.z) - s.z * 0.5 < R:
				var chain := ""
				var p: Node = mi.get_parent()
				for _i in range(3):
					if p == null:
						break
					chain = str(p.name) + "/" + chain
					p = p.get_parent()
				out.append({"name": mi.name, "sx": s.x, "sy": s.y, "sz": s.z,
					"y0": c.y - s.y * 0.5, "y1": c.y + s.y * 0.5, "chain": chain})
	for c2 in n.get_children():
		_walk(c2, out)

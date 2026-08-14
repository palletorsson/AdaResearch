extends SceneTree
## What does a live museum window actually ask the renderer to draw?
##
## Counts, not guesses: mesh instances split architecture vs artifact, unique
## mesh resources and materials (the sharing wins), lights and shadow casters,
## the ten heaviest artifact subtrees, and what the near-artifact cull hides
## from the spawn standpoint. Run before and after an optimization and the
## diff IS the evidence.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_em_render_load.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	for i in range(8):
		await create_timer(0.25).timeout

	var stats: Dictionary = {
		"mesh_total": 0, "mesh_artifact": 0, "mesh_arch": 0,
		"multimesh": 0, "lights": 0, "shadow_lights": 0,
	}
	var uniq_mesh: Dictionary = {}
	var uniq_mat: Dictionary = {}
	var vis: Array = inst.get("_vis_records")
	var art_roots: Dictionary = {}
	for r in vis:
		var n: Node3D = (r as Dictionary).get("node") as Node3D
		if n != null and is_instance_valid(n):
			art_roots[n.get_instance_id()] = n

	_walk(inst, stats, uniq_mesh, uniq_mat, art_roots, false)

	var heavy: Array = []
	for id in art_roots:
		var n: Node3D = art_roots[id]
		var c: Dictionary = {"mesh_total": 0, "mesh_artifact": 0, "mesh_arch": 0,
			"multimesh": 0, "lights": 0, "shadow_lights": 0}
		_walk(n, c, {}, {}, {}, true)
		heavy.append({"name": n.name, "meshes": c["mesh_total"], "lights": c["lights"]})
	heavy.sort_custom(func(a, b): return int(a["meshes"]) > int(b["meshes"]))

	print("RENDER LOAD  segments=%d  artifacts=%d" % [
		(inst.get("_segments") as Array).size(), vis.size()])
	print("  mesh instances: %d total = %d architecture + %d artifact (+%d multimesh)" % [
		stats["mesh_total"], stats["mesh_arch"], stats["mesh_artifact"], stats["multimesh"]])
	print("  unique meshes: %d   unique materials: %d" % [uniq_mesh.size(), uniq_mat.size()])
	print("  lights: %d (%d shadow-casting)" % [stats["lights"], stats["shadow_lights"]])
	var hidden: int = int(inst.get("_vis_hidden"))
	print("  near-artifact cull at spawn: %d of %d artifact roots hidden" % [hidden, vis.size()])
	print("  heaviest artifact subtrees:")
	for h in heavy.slice(0, 10):
		print("    %5d meshes  %2d lights  %s" % [h["meshes"], h["lights"], h["name"]])
	quit(0)


func _walk(n: Node, stats: Dictionary, uniq_mesh: Dictionary, uniq_mat: Dictionary,
		art_roots: Dictionary, inside_artifact: bool) -> void:
	if n is MeshInstance3D:
		stats["mesh_total"] += 1
		if inside_artifact:
			stats["mesh_artifact"] += 1
		else:
			stats["mesh_arch"] += 1
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			uniq_mesh[mi.mesh.get_instance_id()] = true
		var mat: Material = mi.material_override
		if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			mat = mi.mesh.surface_get_material(0)
		if mat != null:
			uniq_mat[mat.get_instance_id()] = true
	elif n is MultiMeshInstance3D:
		stats["multimesh"] += 1
	elif n is Light3D:
		stats["lights"] += 1
		if (n as Light3D).shadow_enabled:
			stats["shadow_lights"] += 1
	for c in n.get_children():
		var child_inside: bool = inside_artifact or art_roots.has(c.get_instance_id())
		_walk(c, stats, uniq_mesh, uniq_mat, art_roots, child_inside)

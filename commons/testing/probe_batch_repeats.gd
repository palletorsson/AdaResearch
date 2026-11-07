extends SceneTree
## COLLECTIONS AS MULTIMESH, every term (2026-11-07). Builds each term of commons/modular/terms.json twice - as built,
## and after builder.gd batch_repeats - and checks that only the DRAWING changed:
##   same drawn bounds, same number of drawn pieces (visible meshes + MultiMesh instances), same colliders and bodies;
## and reports the draw calls saved (visible GeometryInstance3D before - after).
## Run WITH a renderer (not --headless): a headless MultiMesh reads its transforms back as identity, and every batched
## term then "fails" its bounds - which is also the proof that the bounds check bites (2026-11-07: 47 of 50 failed so).
##   godot --path . --xr-mode off --resolution 320x200 --script res://commons/testing/probe_batch_repeats.gd -- --out=ada_run/batch_repeats
const Builder := preload("res://commons/modular/builder.gd")
const Composite := preload("res://commons/modular/composite.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var out := "res://ada_run/batch_repeats"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out) if out.begins_with("res://") else out)
	var terms: Dictionary = Composite.terms()
	var rows: Array = []
	var failed: Array = []
	for name in terms:
		var plain: Node3D = Builder.build({"t": name}, terms)
		var batched: Node3D = Builder.build({"t": name}, terms)
		for sc in Builder.scaffold_of(plain): (sc as Node).free()
		for sc in Builder.scaffold_of(batched): (sc as Node).free()
		var n := Builder.batch_repeats(batched)
		var a := _census(plain)
		var b := _census(batched)
		var row := {"term": name, "batched": n, "draws_before": a.draws, "draws_after": b.draws, "pieces": [a.pieces, b.pieces],
			"colliders": [a.colliders, b.colliders], "bodies": [a.bodies, b.bodies]}
		var problems: Array = []
		if a.pieces != b.pieces: problems.append("drawn pieces %d -> %d" % [a.pieces, b.pieces])
		if a.colliders != b.colliders or a.bodies != b.bodies: problems.append("colliders/bodies changed")
		if not a.box.is_equal_approx(b.box): problems.append("bounds %s -> %s" % [str(a.box), str(b.box)])
		if n > 0 and b.draws >= a.draws: problems.append("batched %d but no draw saved" % n)
		if not problems.is_empty():
			row["problems"] = problems
			failed.append(name)
		rows.append(row)
		plain.free(); batched.free()
	rows.sort_custom(func(x, y): return int(x.draws_before) - int(x.draws_after) > int(y.draws_before) - int(y.draws_after))
	var saved := 0
	for r in rows: saved += int(r.draws_before) - int(r.draws_after)
	var report := {"terms": rows.size(), "batched_terms": rows.filter(func(r): return int(r.batched) > 0).size(),
		"draws_saved_total": saved, "failed": failed, "rows": rows}
	var f := FileAccess.open(out.path_join("report.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	print("BATCH terms %d, batched %d, draws saved %d, failed %d %s" % [rows.size(), report.batched_terms, saved, failed.size(), str(failed.slice(0, 8))])
	for r in rows.slice(0, 12): print("BATCH %-24s draws %4d -> %4d  (%d copies)" % [r.term, r.draws_before, r.draws_after, r.batched])
	quit(0 if failed.is_empty() else 1)

## Drawn = a visible GeometryInstance3D on a layer; a MultiMesh counts its instances as pieces.
func _census(root: Node3D) -> Dictionary:
	var c := {"draws": 0, "pieces": 0, "colliders": 0, "bodies": 0, "box": AABB()}
	var first := true
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var it: Array = stack.pop_back()
		var n: Node = it[0]
		var t: Transform3D = it[1]
		if n is Node3D and n != root: t = t * (n as Node3D).transform
		if n is CollisionShape3D: c.colliders += 1
		if n is PhysicsBody3D: c.bodies += 1
		if n is Node3D and not (n as Node3D).visible: continue
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).layers != 0:
			c.draws += 1; c.pieces += 1
			var bb: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
			c.box = bb if first else c.box.merge(bb); first = false
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
			c.draws += 1; c.pieces += mm.instance_count
			for i in mm.instance_count:
				var bb: AABB = (t * mm.get_instance_transform(i)) * mm.mesh.get_aabb()
				c.box = bb if first else c.box.merge(bb); first = false
		for ch in n.get_children(): stack.append([ch, t])
	return c

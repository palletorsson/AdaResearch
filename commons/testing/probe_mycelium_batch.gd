# probe_mycelium_batch.gd — mycelium milestone 3: the batch gate.
#
# Run:  <godot> --headless --path . --xr-mode off --script res://commons/testing/probe_mycelium_batch.gd
#
# A: the colony renders in O(1) nodes, not O(segments) — one merged web mesh
#    (tapers preserved: MultiMesh cannot vary a taper ratio) + one spore
#    MultiMesh, regardless of how many hyphae grew.
# B: the budget clamp BITES (negative test) and stays deterministic.
# C: geometry survives the merge — the web mesh carries real triangles.
extends SceneTree

const ColonyScript = preload("res://algorithms/nature_system/mycelium/mycelium_colony.gd")

var _failures: int = 0


func _init() -> void:
	_amain()


func _amain() -> void:
	await process_frame
	_run()
	if _failures == 0:
		print("PROBE PASS: mycelium batch (all cases)")
		quit(0)
	else:
		print("PROBE FAIL: %d case(s)" % _failures)
		quit(1)


func _check(name: String, ok: bool, detail: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + name + " — " + detail)
	if not ok:
		_failures += 1


func _spawn(budget: int, nodes: int) -> Node3D:
	var c: Node3D = ColonyScript.new()
	c.budget_segments = budget
	c.max_nodes = nodes
	c.attractor_count = 420
	root.add_child(c)
	return c


func _counts(c: Node3D) -> Dictionary:
	var web: int = 0
	var spores: int = 0
	var tris: int = 0
	for ch in c.get_children():
		if ch is MultiMeshInstance3D:
			spores += 1
		elif ch is MeshInstance3D:
			web += 1
			var m: Mesh = (ch as MeshInstance3D).mesh
			if m != null and m.get_surface_count() > 0:
				tris += m.surface_get_array_len(0)
	return {"web": web, "spores": spores, "verts": tris, "total": c.get_child_count()}


func _run() -> void:
	print("CASE A — O(1) nodes regardless of colony size:")
	var small: Node3D = _spawn(0, 500)
	var a: Dictionary = _counts(small)
	_check("one merged web mesh", int(a["web"]) == 1, "web nodes=%d" % int(a["web"]))
	_check("one spore MultiMesh", int(a["spores"]) == 1, "spore nodes=%d" % int(a["spores"]))
	_check("total nodes is O(1), not O(segments)", int(a["total"]) <= 3,
		"%d children for a 500-node colony (was one per hypha)" % int(a["total"]))
	print("CASE C — geometry survived the merge:")
	_check("web mesh carries triangles", int(a["verts"]) > 300, "%d verts in the merged surface" % int(a["verts"]))
	small.queue_free()

	var big: Node3D = _spawn(0, 1600)
	var b: Dictionary = _counts(big)
	_check("bigger colony, same node count", int(b["total"]) == int(a["total"]),
		"500-node colony=%d children, 1600-node=%d" % [int(a["total"]), int(b["total"])])
	_check("bigger colony, more geometry", int(b["verts"]) > int(a["verts"]),
		"verts %d -> %d" % [int(a["verts"]), int(b["verts"])])
	big.queue_free()

	print("CASE B — the budget clamp bites (negative test):")
	var clamped: Node3D = _spawn(120, 1600)
	var c: Dictionary = _counts(clamped)
	_check("still one web node under clamp", int(c["web"]) == 1, "web nodes=%d" % int(c["web"]))
	_check("clamp cut the geometry", int(c["verts"]) < int(b["verts"]),
		"unbounded %d verts -> budget 120 gives %d" % [int(b["verts"]), int(c["verts"])])
	clamped.queue_free()

	var again: Node3D = _spawn(120, 1600)
	var d: Dictionary = _counts(again)
	_check("clamp is deterministic", int(d["verts"]) == int(c["verts"]),
		"same seed+budget -> %d verts twice" % int(d["verts"]))
	again.queue_free()

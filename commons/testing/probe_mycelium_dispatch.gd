# probe_mycelium_dispatch.gd — mycelium milestone 4: the algo branch gate.
#
# Run:  <godot> --headless --path . --xr-mode off --script res://commons/testing/probe_mycelium_dispatch.gd
#
# A: `fungus:mycelium` routes to the colony — a merged web mesh, not CA voxels.
# B: NEGATIVE (the additive gate) — `fungus:ca` is untouched: it still produces a
#    MultiMeshInstance CA and NO merged web, exactly as before the branch existed.
# C: the mods reach the colony — t= scales the mat, d= thins the web.
# D: per-cell determinism — the same cell twice is identical, two cells differ.
extends SceneTree

const ComponentScript = preload("res://commons/grid/GridBiomeComponent.gd")

var _failures: int = 0


func _init() -> void:
	_amain()


func _amain() -> void:
	await process_frame
	_run()
	if _failures == 0:
		print("PROBE PASS: mycelium dispatch (all cases)")
		quit(0)
	else:
		print("PROBE FAIL: %d case(s)" % _failures)
		quit(1)


func _check(name: String, ok: bool, detail: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + name + " — " + detail)
	if not ok:
		_failures += 1


func _grow(token: String) -> Node3D:
	var comp: Node3D = ComponentScript.new()
	root.add_child(comp)
	comp.initialize(null, 1.0, 0.0)
	comp.generate([[token]], [["1"]], 99, {})  # stage 99 = lab mode: kingdoms unlocked
	return comp


## Walk the whole subtree: the substrate lands under the lazily-made dispatcher.
func _scan(n: Node, acc: Dictionary) -> Dictionary:
	for ch in n.get_children():
		if ch is MultiMeshInstance3D:
			var mm: MultiMesh = (ch as MultiMeshInstance3D).multimesh
			acc["mm"] = int(acc.get("mm", 0)) + 1
			acc["mm_inst"] = int(acc.get("mm_inst", 0)) + (mm.instance_count if mm else 0)
		elif ch is MeshInstance3D:
			var m: Mesh = (ch as MeshInstance3D).mesh
			var v: int = 0
			if m != null and m.get_surface_count() > 0:
				v = m.surface_get_array_len(0)
			if String(ch.name).begins_with("MyceliumWeb"):
				acc["web"] = int(acc.get("web", 0)) + 1
				acc["web_verts"] = int(acc.get("web_verts", 0)) + v
				# SHAPE fingerprint, not size: two colonies that both hit the
				# max_nodes ceiling have identical vertex COUNTS while being
				# completely different mats. The bounds catch the difference.
				if m != null:
					acc["web_aabb"] = str(m.get_aabb())
			else:
				acc["mesh"] = int(acc.get("mesh", 0)) + 1
		_scan(ch, acc)
	return acc


func _run() -> void:
	print("CASE A — fungus:mycelium routes to the colony:")
	var myc: Node3D = _grow("fungus:mycelium:seed:t=4")
	var a: Dictionary = _scan(myc, {})
	_check("a merged web mesh exists", int(a.get("web", 0)) == 1,
		"web nodes=%d, verts=%d" % [int(a.get("web", 0)), int(a.get("web_verts", 0))])
	_check("web carries real geometry", int(a.get("web_verts", 0)) > 500,
		"%d verts" % int(a.get("web_verts", 0)))
	myc.queue_free()

	print("CASE B — NEGATIVE: fungus:ca is untouched by the branch:")
	var ca: Node3D = _grow("fungus:ca:seed:t=4")
	var b: Dictionary = _scan(ca, {})
	_check("no mycelium web on the CA path", int(b.get("web", 0)) == 0,
		"web nodes=%d (must be 0)" % int(b.get("web", 0)))
	_check("CA still renders its voxel MultiMesh", int(b.get("mm", 0)) >= 1,
		"multimesh nodes=%d, instances=%d" % [int(b.get("mm", 0)), int(b.get("mm_inst", 0))])
	ca.queue_free()

	print("CASE C — the mods reach the colony:")
	var small: Node3D = _grow("fungus:mycelium:seed:t=1")
	var big: Node3D = _grow("fungus:mycelium:seed:t=5")
	var sv: int = int(_scan(small, {}).get("web_verts", 0))
	var bv: int = int(_scan(big, {}).get("web_verts", 0))
	_check("t= scales the mat", bv > sv, "t=1 -> %d verts, t=5 -> %d verts" % [sv, bv])
	small.queue_free()
	big.queue_free()
	var dense: Node3D = _grow("fungus:mycelium:seed:t=5:d=1.0")
	var sparse: Node3D = _grow("fungus:mycelium:seed:t=5:d=0.2")
	var dense_scan: Dictionary = _scan(dense, {})
	var dv: int = int(dense_scan.get("web_verts", 0))
	var d_shape: String = String(dense_scan.get("web_aabb", ""))
	var spv: int = int(_scan(sparse, {}).get("web_verts", 0))
	_check("d= thins the web", spv < dv, "d=1.0 -> %d verts, d=0.2 -> %d verts" % [dv, spv])
	dense.queue_free()
	sparse.queue_free()

	print("CASE D — per-cell determinism:")
	var again: Node3D = _grow("fungus:mycelium:seed:t=5:d=1.0")
	var again_shape: String = String(_scan(again, {}).get("web_aabb", ""))
	_check("same cell reloads identically", again_shape == d_shape and again_shape != "",
		"identical bounds twice: %s" % again_shape)
	again.queue_free()
	# a different cell position must differ (seed is hashed from x,z)
	var comp: Node3D = ComponentScript.new()
	root.add_child(comp)
	comp.initialize(null, 1.0, 0.0)
	comp.generate([["", "fungus:mycelium:seed:t=5:d=1.0"]], [["1", "1"]], 99, {})
	var other_shape: String = String(_scan(comp, {}).get("web_aabb", ""))
	_check("a different cell grows a different mat", other_shape != d_shape and other_shape != "",
		"cell(0,0) bounds %s vs cell(1,0) bounds %s" % [d_shape, other_shape])
	comp.queue_free()

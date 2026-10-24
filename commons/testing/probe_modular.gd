extends SceneTree
## probe_modular.gd — build every term of the modular class system and count what
## came out. The gate for commons/modular: a term that fails to build, builds no
## mesh, or declares a body without a collider is a finding.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_modular.gd
##   -> ada_run/modular_probe.json, and MODULAR_PROBE ok=<n> fail=<m> on stdout

const COMPOSITE := "res://commons/modular/composite.tscn"
const Composite := preload("res://commons/modular/composite.gd")
const OUT := "res://ada_run/modular_probe.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load(COMPOSITE)
	var terms: Dictionary = Composite.terms()
	var report: Dictionary = {"terms": {}, "ok": 0, "fail": 0}
	var holder := Node3D.new()
	root.add_child(holder)
	for tid in terms.keys():
		var c: Node = packed.instantiate()
		c.term = str(tid)
		holder.add_child(c)
		await process_frame
		await process_frame
		var d: Dictionary = c.call("describe")
		var problems: Array = []
		if c.get("built") == null:
			problems.append("nothing built")
		var build_v: Variant = (terms[tid] as Dictionary).get("build", {})
		var marker: bool = build_v is Dictionary and str((build_v as Dictionary).get("p", "")) in ["grabbable", "body"]
		if int(d.get("meshes", 0)) == 0 and not marker:
			problems.append("no mesh")
		# a body declared with no collider among its direct children cannot be stood on or grabbed
		if c.get("built") != null:
			for b in _bodies(c.get("built")):
				var has := false
				for ch in b.get_children():
					if ch is CollisionShape3D and (ch as CollisionShape3D).shape != null:
						has = true
				if not has and not (b is Area3D):
					problems.append("body %s without collider" % b.name)
		var aabb: AABB = _aabb(c)
		d["size"] = [snappedf(aabb.size.x, 0.01), snappedf(aabb.size.y, 0.01), snappedf(aabb.size.z, 0.01)]
		d["problems"] = problems
		report["terms"][str(tid)] = d
		if problems.is_empty():
			report["ok"] += 1
		else:
			report["fail"] += 1
			print("  FAIL %s: %s" % [tid, ", ".join(problems)])
		c.queue_free()
		await process_frame
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  "))
		f.close()
	print("MODULAR_PROBE ok=%d fail=%d" % [report["ok"], report["fail"]])
	quit(0 if report["fail"] == 0 else 1)


func _bodies(n: Node) -> Array:
	var out: Array = []
	if n is PhysicsBody3D or n is Area3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_bodies(c))
	return out


func _aabb(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for m in _meshes(n):
		var a: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box


func _meshes(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out

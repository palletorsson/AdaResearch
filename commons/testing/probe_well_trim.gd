extends SceneTree
## WHAT DRAWS THE STRIPS OVER THE ORIGIN WELL?
##
## Palle, four times now: "list hanging in the air and following the floor from an
## old wall, pls." Every probe before this one came back empty, and the reason was
## the same each time: they counted MeshInstance3D. em_detail emits its trim as
## MULTIMESH instances (em_detail._emit -> MultiMeshInstance3D), so the skirting,
## the cornice and the seams were invisible to all of them — which is also why the
## _box refusal could not touch them.
##
## This reads the instance TRANSFORMS inside every MultiMesh and reports the ones
## standing over the well, by bucket name. The bucket name is the answer.
##
##   godot --headless --path . --xr-mode off \
##       --script res://commons/testing/probe_well_trim.gd

var R := 1.2        # the well is x -1..1, z -1..1
var CX := 0.0       # --at=x,z moves the probe: the roof hole is not at the origin
var CZ := 0.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var parts := a.split("=", 1)[1].split(",")
			if parts.size() >= 2:
				CX = float(parts[0])
				CZ = float(parts[1])
		elif a.begins_with("--r="):
			R = float(a.split("=", 1)[1])
		elif a == "--all":
			R = 9999.0        # every instance, so a bucket's real extent is visible
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_well_trim_control.json")
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	for i in range(12):
		await create_timer(0.3).timeout

	var buckets: Dictionary = {}
	_walk(inst, buckets)

	print("\n=== instances standing over the origin well (|x|<=%.1f, |z|<=%.1f) ===" % [R, R])
	if buckets.is_empty():
		print("  nothing — no multimesh instance lands there")
	var names: Array = buckets.keys()
	names.sort()
	for k in names:
		var d: Dictionary = buckets[k]
		print("  %-26s %4d   y %.2f..%.2f   z %.1f..%.1f" % [k, int(d["n"]), float(d["y0"]), float(d["y1"]),
			float(d.get("z0", 0.0)), float(d.get("z1", 0.0))])
	print("\n%d bucket(s) reach the well." % buckets.size())
	quit(0)


func _walk(n: Node, out: Dictionary) -> void:
	var mmi := n as MultiMeshInstance3D
	if mmi != null and mmi.has_meta("em_xforms"):
		# em_xforms, NOT get_instance_transform: em_detail._emit says it outright —
		# "MultiMesh instance transforms cannot be read back under the dummy renderer
		# — every origin returns identity headless". The first run of this probe read
		# the buffer and got 18 buckets all reporting y 0.00..0.00, which is that fact
		# and nothing about the museum. The array that BUILT the buffer is kept on the
		# node for precisely this.
		var xf: Array = mmi.get_meta("em_xforms")
		var g: Transform3D = mmi.global_transform
		for i in range(xf.size()):
			var t: Transform3D = g * (xf[i] as Transform3D)
			var p: Vector3 = t.origin
			if abs(p.x - CX) <= R and abs(p.z - CZ) <= R:
				var key := String(mmi.name)
				if not out.has(key):
					out[key] = {"n": 0, "y0": 999.0, "y1": -999.0}
				var d: Dictionary = out[key]
				d["n"] = int(d["n"]) + 1
				d["z0"] = minf(float(d.get("z0", 9999.0)), p.z)
				d["z1"] = maxf(float(d.get("z1", -9999.0)), p.z)
				d["y0"] = minf(float(d["y0"]), p.y)
				d["y1"] = maxf(float(d["y1"]), p.y)
	for c in n.get_children():
		_walk(c, out)

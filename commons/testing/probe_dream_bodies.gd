extends SceneTree

## Do the six dream bodies build, stand on the floor, keep to their size, and
## differ by seed? (2026-08-29) Six builders written by six hands against a
## contract; this is the contract's gate. For every figure, two seeds:
##   it builds without a script error and adds 40..260 MeshInstance3D
##   every mesh has a material
##   the merged AABB stands on y ~ 0 and is within the size the contract set
##   seed 1 and seed 2 differ (mesh count or extent) — a seed IS a statue
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_dream_bodies.gd

const BODIES := "res://commons/artifacts/dream_bodies/dream_bodies.tscn"
const FIGURES := ["rocaille", "stijl_robot", "panel_robot", "stella_wall", "dragon", "sea_forms"]
const REPORT := "res://ada_run/dream_bodies_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ps: PackedScene = load(BODIES) as PackedScene
	for fig in FIGURES:
		var stats: Array = []
		for sd in [1, 2]:
			var b: Node3D = ps.instantiate() as Node3D
			b.set("figure", fig)
			b.set("seed", sd)
			get_root().add_child(b)
			await process_frame
			await process_frame
			var meshes: Array = []
			_collect(b, meshes)
			var no_mat := 0
			var box := AABB()
			var first := true
			for mi_v in meshes:
				var mi: MeshInstance3D = mi_v
				if mi.material_override == null and (mi.mesh == null or mi.mesh.surface_get_material(0) == null):
					no_mat += 1
				if mi.mesh == null:
					continue
				var a: AABB = mi.global_transform * mi.get_aabb()
				if first:
					box = a
					first = false
				else:
					box = box.merge(a)
			stats.append({"n": meshes.size(), "no_mat": no_mat, "box": box})
			b.queue_free()
			await process_frame
		var s1: Dictionary = stats[0]
		var s2: Dictionary = stats[1]
		var n: int = int(s1["n"])
		var box: AABB = s1["box"]
		var relief: bool = fig == "stella_wall"
		var max_w: float = 2.6 if relief else 1.3
		var max_h: float = 1.75
		var min_h: float = 0.9
		_check(n >= 40 and n <= 260, "%s: %d mesh(es)" % [fig, n], "%s: mesh count out of 40..260" % fig)
		_check(int(s1["no_mat"]) == 0, "%s: %d without material" % [fig, int(s1["no_mat"])], "%s: bare mesh" % fig)
		var base_ok: bool = box.position.y > -0.03 and box.position.y < 0.25
		var h: float = box.size.y
		var w: float = maxf(box.size.x, box.size.z)
		_check(base_ok and h >= min_h and h <= max_h and w <= max_w,
			"%s: base y %.2f, %.2f m tall, %.2f m across (limits %.1f..%.2f tall, %.1f across)" % [fig, box.position.y, h, w, min_h, max_h, max_w],
			"%s: off the floor or out of size" % fig)
		var b2: AABB = s2["box"]
		var differs: bool = int(s2["n"]) != n or (b2.size - box.size).length() > 0.02 or (b2.position - box.position).length() > 0.02
		_check(differs, "%s: seed 2 differs from seed 1: %s" % [fig, str(differs)], "%s: seed ignored" % fig)
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _collect(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)

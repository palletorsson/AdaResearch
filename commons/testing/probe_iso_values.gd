extends SceneTree

## Did the ISO value actually put a body on the plinth?
## (2026-09-03)
##
## The tube_reef sweep photographed `growth = fused` as six floating eel heads
## over a coral bed with NO COLUMN — and the builder has an explicit primitive
## fallback for exactly that case, so the frame proves neither the mesher nor the
## fallback ran. A picture cannot say which. This builds each glossed family at
## its isosurface value and reports what is actually in the tree: how many
## meshes, how many triangles, and the merged extent, against the same family at
## a NON-iso value as the control.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_iso_values.gd

const REPORT := "res://ada_run/iso_values_probe.txt"

## family : [axis, iso value, a control value, optional {second axis: value}]
##
## THE HEADLINE VALUE IS NOT THE WHOLE FAMILY. tube_reef.growth=fused built 38036
## triangles at the default `tenants`, and photographed as six floating eel heads
## over an empty bed at tenants=chorus — the same trap CLAUDE.md records for
## tier_terrarium, where a live axis hid a dead one behind a peak. So every iso
## value is also measured against the OTHER axis's values, not just the default.
const CASES: Array = [
	["tube_reef", "growth", "fused", "arch"],
	["tube_reef", "growth", "fused", "arch", {"tenants": "chorus"}],
	["tube_reef", "growth", "fused", "arch", {"tenants": "shoal"}],
	["tube_reef", "growth", "fused", "arch", {"tenants": "hydra"}],
	["rocaille", "kiln", "fused", "fired"],
	["clay_splash", "clay", "fused", "boneless"],
	["dragon", "kiln", "cast", "glazed"],
	["lava_bloom", "bough", "fused", "writhe"],
	["vasarely_beast", "tube", "fused", "smooth"],
	["coral_polyp", "colony", "fused", "single"],
	["sea_forms", "flesh", "fused", "clay"],
	["oni_dragon", "curse", "fused", "flesh"],
	["nana_gloss", "nana", "poured", "dancing"],
]

## The sweep photographs the DEFAULT seed, so that is the seed a probe must
## default to as well: tube_reef.growth=fused built a full 1.40 m column at
## seed 3 and photographed as floating eel heads at seed 1. A probe standing on
## a different individual than the camera is measuring a different statue.
var _seed: int = 1
var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--seed="):
			_seed = int(String(a).split("=")[1])
	_lines.append("[probe] seed %d" % _seed)
	for c_v in CASES:
		var c: Array = c_v
		var key: String = String(c[0])
		var axis: String = String(c[1])
		var iso: String = String(c[2])
		var ctrl: String = String(c[3])
		var also: Dictionary = c[4] if c.size() > 4 else {}
		var a: Dictionary = _measure(key, axis, iso, also)
		var b: Dictionary = _measure(key, axis, ctrl, also)
		var tag: String = ""
		for k in also:
			tag += " %s=%s" % [String(k), String(also[k])]
		var line: String = "%-16s %s=%-9s%-16s %4d mesh %6d tri  biggest %6d tri / %.2f m  %s" % [
			key, axis, iso, tag, int(a["meshes"]), int(a["tris"]),
			int(a["big"]), float(a["big_d"]), _fmt(a["size"])]
		# THE AGGREGATE IS NOT THE CLAIM, and an aggregate check let the bug
		# through once already: tube_reef.growth=fused reported 45844 triangles
		# across 1.46 m and photographed as an EMPTY BED, because those triangles
		# were six eel heads and fifty coral pebbles. What an iso value promises
		# is ONE continuous marched body, so that is what is measured — the
		# LARGEST SINGLE MESH, which for a marched surface at these cell sizes
		# runs to thousands of triangles and cannot be confused with a swept tube.
		var ok: bool = int(a["big"]) > 3000 and float(a["big_d"]) > 0.5
		# and the family around it must not have quietly lost its mass
		var mass_ok: bool = int(a["tris"]) > int(b["tris"]) / 12
		_lines.append("[probe] %s  %s" % [line, "OK" if (ok and mass_ok) else "*** EMPTY ***"])
		_lines.append("[probe]                  biggest mesh: %s" % String(a["look"]))
		if not ok:
			_fails.append("%s.%s=%s%s has no marched body — biggest mesh is %d tri across %.2f m"
			% [key, axis, iso, tag, int(a["big"]), float(a["big_d"])])
		elif not mass_ok:
			_fails.append("%s.%s=%s%s has %d triangles against the control's %d — the mass is gone"
				% [key, axis, iso, tag, int(a["tris"]), int(b["tris"])])
	_finish()


func _measure(key: String, axis: String, value: String, also: Dictionary = {}) -> Dictionary:
	var path: String = "res://commons/artifacts/dream_bodies/figures/%s.tscn" % key
	if not ResourceLoader.exists(path):
		return {"meshes": 0, "tris": 0, "size": Vector3.ZERO}
	var ps: PackedScene = load(path) as PackedScene
	if ps == null:
		return {"meshes": 0, "tris": 0, "size": Vector3.ZERO}
	var n: Node = ps.instantiate()
	n.set(axis, value)
	for k in also:
		n.set(String(k), String(also[k]))
	n.set("seed", _seed)
	root.add_child(n)
	var meshes: int = 0
	var tris: int = 0
	# THE BIGGEST MESH IS THE BODY, and what it is PAINTED with decides whether it
	# reaches the film at all — a metallic 1.0 surface with nothing to reflect
	# renders near-black on a black plate, which photographs exactly like an
	# artifact that failed to build.
	var big_tris: int = -1
	var big_diag: float = 0.0
	var look: String = "-"
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := Vector3(-1e9, -1e9, -1e9)
	for m in _all_meshes(n):
		if m.mesh == null:
			continue
		meshes += 1
		for s in range(m.mesh.get_surface_count()):
			var arr: Array = m.mesh.surface_get_arrays(s)
			if arr.is_empty():
				continue
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var vcount: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			tris += (idx.size() / 3) if idx.size() > 0 else (vcount / 3)
		var mt: int = 0
		for s2 in range(m.mesh.get_surface_count()):
			var a2: Array = m.mesh.surface_get_arrays(s2)
			if not a2.is_empty():
				mt += (a2[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
		if mt > big_tris:
			big_tris = mt
			big_diag = m.get_aabb().size.length()
			var mm: StandardMaterial3D = m.material_override as StandardMaterial3D
			if mm == null:
				mm = m.get_active_material(0) as StandardMaterial3D
			if mm == null:
				look = "no StandardMaterial3D"
			else:
				look = "albedo(%.2f,%.2f,%.2f) metal %.2f rough %.2f emit %s tex %s" % [
					mm.albedo_color.r, mm.albedo_color.g, mm.albedo_color.b,
					mm.metallic, mm.roughness,
					("%.2f" % mm.emission_energy_multiplier) if mm.emission_enabled else "off",
					"yes" if mm.albedo_texture != null else "NONE"]
		var ab: AABB = m.get_aabb()
		var org: Vector3 = m.global_transform.origin
		lo = Vector3(minf(lo.x, org.x + ab.position.x), minf(lo.y, org.y + ab.position.y), minf(lo.z, org.z + ab.position.z))
		hi = Vector3(maxf(hi.x, org.x + ab.end.x), maxf(hi.y, org.y + ab.end.y), maxf(hi.z, org.z + ab.end.z))
	n.queue_free()
	var size: Vector3 = (hi - lo) if meshes > 0 else Vector3.ZERO
	return {"meshes": meshes, "tris": tris, "size": size, "look": look,
		"big": maxi(0, big_tris), "big_d": big_diag}


func _all_meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_all_meshes(c))
	return out


func _fmt(v) -> String:
	var s: Vector3 = v
	return "%.2fx%.2fx%.2f m" % [s.x, s.y, s.z]


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)

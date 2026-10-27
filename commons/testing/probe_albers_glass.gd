extends SceneTree
## probe_albers_glass.gd — the medium axis on albers_wall_gallery (paint | relief | cubes).
##
## Spec: doc/colour/albers_glass/SPEC.md.
##
##   --mode=signature   instantiate the default scene, settle 0.35 s, walk the tree and write
##                      ada_run/albers_paint_signature.json: every child in order (index path,
##                      class, mesh size or vertex/index count + a hash of positions and
##                      colours, material flags, light type, shadow flag) and the totals.
##                      Run it on the UNEDITED script: that file is the baseline paint must keep.
##                      It refuses to overwrite an existing baseline without --force (a rerun
##                      after the edit would otherwise quietly bless the edit).
##   --mode=check       the medium axis, asserted; writes ada_run/probe_albers_glass.json:
##                      (a) default + no-op configs == the baseline signature, byte for byte;
##                          paint remove + re-add (same frame, after 3 frames) rebuilds the
##                          baseline (the HEAD script left a re-added wall EMPTY)
##                      (b) relief / cubes from config_medium meta: built once, node, vertex and
##                          index counts derived here from Godot's BoxMesh (cubes: 5 nests + 12
##                          edge bars per canvas), material structure, no shadows; a repeated
##                          config keeps the same GlassHomages instance; the edge bars carry the
##                          outer face and sit inside the outer cube; the shelves are attached
##                          to the table with the table's own colour on top; a project-setting
##                          gain reaches the shader
##                      (c) solve oracle from the READ-BACK vertex colours: relief A_k = prod T,
##                          cubes A_k = prod face^2, against a palette regenerated HERE; and the
##                          error of the CLAMPED squares against the palette, which no oracle
##                          checks (sRGB /255 per channel and CIE76 dE per square), beside the
##                          paint wall's own error (it reads the palette bytes as linear)
##                      (g) containment from read-back geometry: square k inside square k-1;
##                          negative: vertical_bias -0.5 would break it and is held inside
##                      (d) round trip cubes -> relief -> paint == baseline; orphan nodes and
##                          resources back to start
##                      (e) unknown word -> paint + a warning; remove + re-add rebuilds
##                      (f) every glass and backing triangle faces outward (clockwise front).
##                          Its negative (reversed indices) is a NON-VACUITY check only: the
##                          winding EVIDENCE is the CULL_BACK relief rendering its slab colours
##                          in probe_albers_glass_render.gd
##                      Also writes ada_run/albers_glass_layers.json: every box of every
##                      medium as read back (head-on rectangles + colours), the input of
##                      tools/predict_albers_glass_degeneracy.py
##
## Run (headless is fine: the dummy renderer keeps ArrayMesh surfaces, it draws no frames):
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_albers_glass.gd -- --mode=signature
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_albers_glass.gd -- --mode=check
## The non-console exe prints nothing to stdout: read the JSON, or user://logs/godot.log.

const SCENE := "res://algorithms/primitives/homagetothesquare/albers_wall_gallery.tscn"
const SIGNATURE_FILE := "res://ada_run/albers_paint_signature.json"

var _force: bool = false


func _initialize() -> void:
	var mode: String = "signature"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.split("=", 1)[1]
		elif a == "--force":
			_force = true
	match mode:
		"signature":
			_run_signature()
		"check":
			_run_check()
		_:
			print("probe_albers_glass: unknown --mode=%s" % mode)
			quit(2)


func _run_signature() -> void:
	var inst: Node3D = (load(SCENE) as PackedScene).instantiate()
	root.add_child(inst)
	await create_timer(0.35).timeout
	await process_frame
	var sig: Dictionary = signature(inst)
	var text: String = JSON.stringify(sig, "  ", true)
	var path: String = ProjectSettings.globalize_path(SIGNATURE_FILE)
	if FileAccess.file_exists(path) and not _force:
		path = path.get_basename() + ".rerun.json"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	print("probe_albers_glass signature: %s" % JSON.stringify(sig["totals"]))
	print("wrote %s (%d rows, %d bytes)" % [path, (sig["rows"] as Array).size(), text.length()])
	quit(0)


# ---------------------------------------------------------------- the signature

static func f3(v: Vector3) -> String:
	return "%.5f,%.5f,%.5f" % [v.x, v.y, v.z]


static func fc(c: Color) -> String:
	return "%.5f,%.5f,%.5f,%.5f" % [c.r, c.g, c.b, c.a]


static func hash_bytes(b: PackedByteArray) -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(b)
	return h.finish().hex_encode().substr(0, 16)


static func mesh_desc(m: Mesh) -> String:
	if m == null:
		return "null"
	if m is BoxMesh:
		return "BoxMesh size=%s" % f3((m as BoxMesh).size)
	if m is PrimitiveMesh:
		return "%s" % m.get_class()
	var parts: PackedStringArray = [m.get_class(), "surfaces=%d" % m.get_surface_count()]
	for s in m.get_surface_count():
		var arr: Array = m.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var col: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var b := PackedByteArray()
		b.append_array(v.to_byte_array())
		b.append_array(col.to_byte_array())
		b.append_array(idx.to_byte_array())
		parts.append("s%d v=%d i=%d c=%d h=%s" % [s, v.size(), idx.size(), col.size(), hash_bytes(b)])
	return " ".join(parts)


static func material_desc(mat: Material) -> String:
	if mat == null:
		return "none"
	if not (mat is BaseMaterial3D):
		return mat.get_class()
	var m := mat as BaseMaterial3D
	return "%s shading=%d transp=%d blend=%d cull=%d depth=%d vc_albedo=%s vc_srgb=%s fog_off=%s rx_shadow_off=%s prio=%d albedo=%s rough=%.3f" % [
		m.get_class(), m.shading_mode, m.transparency, m.blend_mode, m.cull_mode,
		m.depth_draw_mode, m.vertex_color_use_as_albedo, m.vertex_color_is_srgb,
		m.disable_fog, m.disable_receive_shadows, m.render_priority, fc(m.albedo_color),
		m.roughness]


static func _walk(n: Node, path: String, rows: Array, totals: Dictionary, merged: Array) -> void:
	for i in n.get_child_count():
		var c: Node = n.get_child(i)
		var p: String = str(i) if path == "" else "%s/%d" % [path, i]
		var nm: String = "@" if String(c.name).begins_with("@") else String(c.name)
		var row: String = "%s %s %s" % [p, c.get_class(), nm]
		if c is Node3D:
			var n3 := c as Node3D
			row += " pos=%s rot=%s scl=%s vis=%s" % [f3(n3.position), f3(n3.rotation), f3(n3.scale), n3.visible]
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			totals["mesh_instances"] += 1
			row += " | mesh=%s | mat=%s | cast=%d" % [mesh_desc(mi.mesh), material_desc(mi.material_override), mi.cast_shadow]
			if mi.mesh != null:
				var bb: AABB = mi.global_transform * mi.get_aabb()
				if merged.is_empty():
					merged.append(bb)
				else:
					merged[0] = (merged[0] as AABB).merge(bb)
		if c is Light3D:
			var l := c as Light3D
			totals["lights"] += 1
			row += " | light=%s shadow=%s energy=%.3f color=%s" % [l.get_class(), l.shadow_enabled, l.light_energy, fc(l.light_color)]
			if l is SpotLight3D:
				var sl := l as SpotLight3D
				row += " angle=%.3f range=%.3f" % [sl.spot_angle, sl.spot_range]
				if sl.shadow_enabled:
					totals["shadowed_spots"] += 1
		if String(c.name).begins_with("Canvas_") and n.get_parent() != null and path == "":
			totals["canvases"] += 1
		var metas: PackedStringArray = []
		for k in c.get_meta_list():
			metas.append(String(k))
		if not metas.is_empty():
			metas.sort()
			row += " meta=%s" % ",".join(metas)
		rows.append(row)
		_walk(c, p, rows, totals, merged)


static func signature(inst: Node3D) -> Dictionary:
	var rows: Array = []
	var totals := {"mesh_instances": 0, "canvases": 0, "lights": 0, "shadowed_spots": 0}
	var merged: Array = []
	_walk(inst, "", rows, totals, merged)
	var root_metas: PackedStringArray = []
	for k in inst.get_meta_list():
		root_metas.append(String(k))
	root_metas.sort()
	totals["root_meta"] = ",".join(root_metas)
	totals["aabb"] = "none" if merged.is_empty() else "%s|%s" % [f3((merged[0] as AABB).position), f3((merged[0] as AABB).size)]
	totals["children"] = inst.get_child_count()
	return {"totals": totals, "rows": rows}


# ---------------------------------------------------------------- check mode

const OUT_FILE := "res://ada_run/probe_albers_glass.json"
const TOL := 2.0 / 255.0

var _checks: Array = []
var _numbers: Dictionary = {}
var _catch: WarnCatch


## Catches push_warning text so "falls back WITH a warning" is asserted, not assumed.
class WarnCatch extends Logger:
	var lines: PackedStringArray = []
	var _mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		_mutex.lock()
		lines.append("%s | %s" % [code, rationale])
		_mutex.unlock()

	func _log_message(message: String, error: bool) -> void:
		pass

	func saw(fragment: String) -> bool:
		_mutex.lock()
		var hit := false
		for l in lines:
			if l.contains(fragment):
				hit = true
				break
		_mutex.unlock()
		return hit


func _check(name: String, ok: bool, evidence: String) -> void:
	_checks.append({"name": name, "passed": ok, "evidence": evidence})
	print("%s  %s  %s" % ["PASS" if ok else "FAIL", name, evidence])


func _settle() -> void:
	await create_timer(0.35).timeout
	await process_frame


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _sig_text(inst: Node3D) -> String:
	return JSON.stringify(signature(inst), "  ", true)


func _new_inst(meta_medium: String = "") -> Node3D:
	var inst: Node3D = (load(SCENE) as PackedScene).instantiate()
	if meta_medium != "":
		inst.set_meta("config_medium", meta_medium)
	root.add_child(inst)
	return inst


func _drop(inst: Node) -> void:
	inst.queue_free()
	await _frames(3)


static func _all_of(n: Node, cls: String, out: Array) -> void:
	for c in n.get_children():
		if c.is_class(cls):
			out.append(c)
		_all_of(c, cls, out)


static func _count_meshes(n: Node) -> int:
	var out: Array = []
	_all_of(n, "MeshInstance3D", out)
	return out.size()


static func _shadowed_spots(n: Node) -> int:
	var out: Array = []
	_all_of(n, "SpotLight3D", out)
	var k := 0
	for s in out:
		if (s as SpotLight3D).shadow_enabled:
			k += 1
	return k


## sRGB <-> linear, written out here so the oracle shares no code with the artifact.
static func t_lin(x: float) -> float:
	if x <= 0.04045:
		return x / 12.92
	return pow((x + 0.055) / 1.055, 2.4)


static func t_srgb(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	if x <= 0.0031308:
		return x * 12.92
	return 1.055 * pow(x, 1.0 / 2.4) - 0.055


## The painting's palette, regenerated from the exports (the same RNG walk as the artifact).
static func regen_palette(inst: Node, index: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(inst.get("palette_seed")) + index * 31
	var smin: float = inst.get("palette_saturation_min")
	var smax: float = inst.get("palette_saturation_max")
	var vmin: float = inst.get("palette_value_min")
	var vmax: float = inst.get("palette_value_max")
	var n: int = inst.get("squares_per_canvas")
	var base_hue := fposmod(0.61803398875 * float(index), 1.0)
	var hue_span := rng.randf_range(0.18, 0.36)
	var sat_outer := rng.randf_range(smin, smax)
	var val_outer := rng.randf_range(vmin, vmax)
	var sat_inner := rng.randf_range(max(0.4, smin), smax)
	var val_inner := rng.randf_range(max(0.7, vmin), vmax)
	var out: Array = []
	for i in n:
		var t := 0.0 if n == 1 else float(i) / float(n - 1)
		var hue := fposmod(base_hue + t * hue_span + rng.randf_range(-0.03, 0.03), 1.0)
		out.append(Color.from_hsv(hue, lerp(sat_outer, sat_inner, t), lerp(val_outer, val_inner, t)))
	return out


## Godot's unit box as the spec cuts it: (verts, indices) per box, full or minus the two
## -Z triangles (compacted). Computed HERE from BoxMesh, not read from the artifact.
static func box_counts(drop_back: bool) -> Vector2i:
	var b := BoxMesh.new()
	b.size = Vector3.ONE
	var arr: Array = b.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	if not drop_back:
		return Vector2i(v.size(), idx.size())
	var used := {}
	var kept := 0
	for t in range(0, idx.size(), 3):
		if n[idx[t]].z < -0.5 and n[idx[t + 1]].z < -0.5 and n[idx[t + 2]].z < -0.5:
			continue
		kept += 3
		for j in 3:
			used[idx[t + j]] = true
	return Vector2i(used.size(), kept)


## Winding: per box (vb consecutive vertices), every triangle's front normal under
## Godot's clockwise-front rule, -(b-a)x(c-a), must point away from the box centre.
## Returns (bad triangles, total triangles).
static func winding_bad(arr: Array, vb: int, reverse: bool) -> Vector2i:
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var centres: Dictionary = {}
	var bad := 0
	var total := 0
	for t in range(0, idx.size(), 3):
		var ia: int = idx[t]
		var ib: int = idx[t + 2] if reverse else idx[t + 1]
		var ic: int = idx[t + 1] if reverse else idx[t + 2]
		var box: int = ia / vb
		if not centres.has(box):
			var c := Vector3.ZERO
			for k in vb:
				c += v[box * vb + k]
			centres[box] = c / float(vb)
		var a: Vector3 = v[ia]
		var front: Vector3 = -((v[ib] - a).cross(v[ic] - a))
		var out_dir: Vector3 = (a + v[ib] + v[ic]) / 3.0 - (centres[box] as Vector3)
		total += 1
		if front.dot(out_dir) <= 0.0:
			bad += 1
	return Vector2i(bad, total)


## STRUCTURE only: the render_mode line, the decode guard and the ALPHA write read off the
## shader text, and the gain parameter against the root meta. It cannot catch a wrong gain
## (both come from the artifact's rule) or a wrong decode: the pixel oracle in
## probe_albers_glass_render.gd is the behavioural check of both.
func _material_ok(m: Material, cull: int, want_gain: float) -> Array:
	var errs: PackedStringArray = []
	var sm := m as ShaderMaterial
	if sm == null or sm.shader == null:
		return [false, "not a ShaderMaterial with a shader"]
	var code: String = sm.shader.code
	var rm: String = ""
	for line in code.split("\n"):
		if line.strip_edges().begins_with("render_mode"):
			rm = line
	var want_cull: String = "cull_disabled" if cull == BaseMaterial3D.CULL_DISABLED else "cull_back"
	for tok in ["unshaded", "blend_mul", want_cull, "depth_draw_opaque", "shadows_disabled", "fog_disabled"]:
		if not rm.contains(tok):
			errs.append("render_mode lacks %s" % tok)
	if not code.contains("ALPHA = 1.0"):
		errs.append("no ALPHA write (would not be in the transparent pass)")
	if not (code.contains("12.92") and code.contains("2.4") and code.contains("!OUTPUT_IS_SRGB")):
		errs.append("no guarded sRGB decode of COLOR")
	var gain = sm.get_shader_parameter("gain")
	if gain == null or absf(float(gain) - want_gain) > 1e-6:
		errs.append("gain=%s want %s" % [gain, want_gain])
	if sm.render_priority != -1:
		errs.append("prio=%d" % sm.render_priority)
	return [errs.is_empty(), "shader %s | gain=%s (root meta %s) prio=%d %s" % [rm.strip_edges(), gain, want_gain, sm.render_priority, ",".join(errs)]]


# ---------------------------------------------------------------- colour error

## CIE L*a*b* (D65) of an sRGB colour, for a CIE76 dE.
static func lab(c: Color) -> Vector3:
	var r := t_lin(c.r)
	var g := t_lin(c.g)
	var b := t_lin(c.b)
	var x := (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047
	var y := 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
	var z := (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883
	var e := 216.0 / 24389.0
	var fx := pow(x, 1.0 / 3.0) if x > e else (841.0 / 108.0) * x + 4.0 / 29.0
	var fy := pow(y, 1.0 / 3.0) if y > e else (841.0 / 108.0) * y + 4.0 / 29.0
	var fz := pow(z, 1.0 / 3.0) if z > e else (841.0 / 108.0) * z + 4.0 / 29.0
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


static func de76(a: Color, b: Color) -> float:
	return lab(a).distance_to(lab(b))


static func dist(v: Array) -> Dictionary:
	if v.is_empty():
		return {"n": 0}
	var s: Array = v.duplicate()
	s.sort()
	var tot := 0.0
	for x in s:
		tot += float(x)
	return {"n": s.size(), "max": snappedf(s[-1], 0.01), "median": snappedf(s[s.size() / 2], 0.01),
		"p75": snappedf(s[(s.size() * 3) / 4], 0.01), "mean": snappedf(tot / s.size(), 0.01)}


## Per box b (vb consecutive vertices): its read-back AABB.
static func box_aabb(v: PackedVector3Array, vb: int, b: int) -> AABB:
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for j in vb:
		var p: Vector3 = v[b * vb + j]
		lo = lo.min(p)
		hi = hi.max(p)
	return AABB(lo, hi - lo)


## How far a sits inside b (the smallest gap on the axes asked), negative when it pokes out.
static func inside_margin(a: AABB, b: AABB, axes: Array) -> float:
	var m := INF
	for ax in axes:
		m = minf(m, a.position[ax] - b.position[ax])
		m = minf(m, b.end[ax] - a.end[ax])
	return m


const LAYERS_FILE := "res://ada_run/albers_glass_layers.json"
const GAIN_SETTING := "ada/albers_glass/mul_gain"

var _layers: Dictionary = {}


static func b3(c: Color) -> Array:
	return [roundi(c.r * 255.0), roundi(c.g * 255.0), roundi(c.b * 255.0)]


## The paint wall as the eye roughly sees it head-on, for the degeneracy predictor:
## every MeshInstance3D's head-on rectangle and front z, lit boxes at their albedo, the
## painted quads at their DISPLAYED colour (the paint material reads the palette bytes as
## linear, so the screen shows srgb(byte)).
func _dump_paint(inst: Node3D) -> Dictionary:
	var rects: Array = []
	var meshes: Array = []
	_all_of(inst, "MeshInstance3D", meshes)
	for mi in meshes:
		var m := mi as MeshInstance3D
		var bb: AABB = m.global_transform * m.get_aabb()
		if m.mesh is BoxMesh:
			var mat := m.material_override as BaseMaterial3D
			var col: Color = mat.albedo_color if mat != null else Color.WHITE
			rects.append([bb.position.x, bb.position.y, bb.end.x, bb.end.y, bb.end.z, b3(col), "lit"])
		else:
			var arr: Array = m.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var col: PackedColorArray = arr[Mesh.ARRAY_COLOR]
			for q in range(0, v.size(), 4):
				var lo := Vector3(INF, INF, INF)
				var hi := -lo
				for j in 4:
					var p: Vector3 = m.global_transform * v[q + j]
					lo = lo.min(p)
					hi = hi.max(p)
				var c: Color = col[q]
				var shown := Color(t_srgb(c.r), t_srgb(c.g), t_srgb(c.b), 1.0)
				rects.append([lo.x, lo.y, hi.x, hi.y, hi.z, b3(shown), "unshaded"])
	return {"rects": rects}


func _dump_glass(inst: Node3D, garr: Array, barr: Array, vb: int, passes: int) -> Dictionary:
	var gv: PackedVector3Array = garr[Mesh.ARRAY_VERTEX]
	var gc: PackedColorArray = garr[Mesh.ARRAY_COLOR]
	var boxes: Array = []
	for b in gv.size() / vb:
		var bb := box_aabb(gv, vb, b)
		boxes.append([bb.position.x, bb.position.y, bb.end.x, bb.end.y, bb.position.z, bb.end.z, b3(gc[b * vb])])
	var bv: PackedVector3Array = barr[Mesh.ARRAY_VERTEX]
	var bn: PackedVector3Array = barr[Mesh.ARRAY_NORMAL]
	var bc: PackedColorArray = barr[Mesh.ARRAY_COLOR]
	var backing: Array = []
	for b in bv.size() / 24:
		var bb := box_aabb(bv, 24, b)
		var front: Color = bc[b * 24]
		for j in 24:
			if bn[b * 24 + j].z > 0.5:
				front = bc[b * 24 + j]
				break
		backing.append([bb.position.x, bb.position.y, bb.end.x, bb.end.y, bb.position.z, bb.end.z, b3(front)])
	return {"passes": passes, "boxes": boxes, "backing": backing}


func _run_check() -> void:
	_catch = WarnCatch.new()
	OS.add_logger(_catch)
	var baseline: String = FileAccess.get_file_as_string(ProjectSettings.globalize_path(SIGNATURE_FILE))
	_check("baseline file present", baseline.length() > 0, "%s, %d bytes" % [SIGNATURE_FILE, baseline.length()])
	ProjectSettings.set_setting(GAIN_SETTING, null)

	# ---- (a) default + no-op configs
	var inst := _new_inst()
	await _settle()
	var s0 := _sig_text(inst)
	_check("a: default == baseline", s0 == baseline, "%d vs %d bytes, builds=%d" % [s0.length(), baseline.length(), inst.get("_build_count")])
	for cfg in [{}, {"museum_yaw": 0}, {"emissive": false}, {"medium": "paint"}]:
		inst.call("apply_grid_config", cfg)
		await _frames(2)
		var s := _sig_text(inst)
		_check("a: apply_grid_config(%s) == baseline" % JSON.stringify(cfg), s == baseline and int(inst.get("_build_count")) == 1,
			"equal=%s builds=%d" % [s == baseline, inst.get("_build_count")])
	_layers["paint"] = _dump_paint(inst)

	# ---- (a) paint remove + re-add: _exit_tree now asks for a rebuild. The HEAD script
	# queue_freed every child and never rebuilt, so a re-added wall stood EMPTY; this is a
	# behaviour change on the default path and it must give back the baseline exactly.
	root.remove_child(inst)
	root.add_child(inst)
	await _settle()
	var sp1 := _sig_text(inst)
	_check("a: paint remove + add_child (same frame) == baseline", sp1 == baseline and int(inst.get("_build_count")) == 2,
		"sig equal=%s meshes=%d builds=%d" % [sp1 == baseline, _count_meshes(inst), inst.get("_build_count")])
	root.remove_child(inst)
	await _frames(3)
	root.add_child(inst)
	await _settle()
	var sp2 := _sig_text(inst)
	_check("a: paint remove, wait 3 frames, add_child == baseline", sp2 == baseline and int(inst.get("_build_count")) == 3,
		"sig equal=%s meshes=%d builds=%d" % [sp2 == baseline, _count_meshes(inst), inst.get("_build_count")])
	await _drop(inst)

	# ---- (b, c, e re-add, f, g) relief and cubes from config_medium meta
	var full := box_counts(false)
	var slab := box_counts(true)
	var boxes: int = 98 * 5
	var bars: int = 98 * 12
	var expect := {
		"relief": {"glass": Vector2i(boxes * slab.x, boxes * slab.y), "backing": Vector2i(full.x, full.y), "vb": slab.x,
			"cull": BaseMaterial3D.CULL_BACK, "passes": 1, "axes": [0, 1]},
		"cubes": {"glass": Vector2i((boxes + bars) * full.x, (boxes + bars) * full.y), "backing": Vector2i(8 * full.x, 8 * full.y), "vb": full.x,
			"cull": BaseMaterial3D.CULL_DISABLED, "passes": 2, "axes": [0, 1, 2]},
	}
	_numbers["box_template"] = {"full_v": full.x, "full_i": full.y, "slab_v": slab.x, "slab_i": slab.y}
	for med in ["relief", "cubes"]:
		var e: Dictionary = expect[med]
		inst = _new_inst(med)
		await _settle()
		var builds: int = inst.get("_build_count")
		_check("b/%s: built once from config_medium meta" % med, builds == 1 and str(inst.get("medium")) == med
			and str(inst.get_meta("glass_medium", "")) == med,
			"builds=%d medium=%s glass_medium=%s" % [builds, inst.get("medium"), inst.get_meta("glass_medium", "")])
		var meshes := _count_meshes(inst)
		_check("b/%s: MeshInstance3D count" % med, meshes == 2, "%d (expected 2: GlassBacking + GlassHomages)" % meshes)
		var canv := 0
		var canv_kids := 0
		var canv_meta := 0
		for c in inst.get_children():
			if String(c.name).begins_with("Canvas_"):
				canv += 1
				canv_kids += c.get_child_count()
				if c.has_meta("palette") and c.has_meta("layers") and c.has_meta("clamped"):
					canv_meta += 1
		_check("b/%s: 98 empty Canvas_* markers with meta" % med, canv == 98 and canv_kids == 0 and canv_meta == 98,
			"canvases=%d children=%d with_meta=%d" % [canv, canv_kids, canv_meta])
		var gmi := inst.get_node_or_null("GlassHomages") as MeshInstance3D
		var bmi := inst.get_node_or_null("GlassBacking") as MeshInstance3D
		if gmi == null or bmi == null:
			_check("b/%s: glass nodes present" % med, false, "GlassHomages=%s GlassBacking=%s" % [gmi, bmi])
			await _drop(inst)
			continue
		var garr: Array = gmi.mesh.surface_get_arrays(0)
		var barr: Array = bmi.mesh.surface_get_arrays(0)
		var gverts: PackedVector3Array = garr[Mesh.ARRAY_VERTEX]
		var gv := Vector2i(gverts.size(), (garr[Mesh.ARRAY_INDEX] as PackedInt32Array).size())
		var bv := Vector2i((barr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), (barr[Mesh.ARRAY_INDEX] as PackedInt32Array).size())
		var eg: Vector2i = e["glass"]
		var eb: Vector2i = e["backing"]
		_check("b/%s: GlassHomages vertex/index counts" % med, gv == eg and gmi.mesh.get_surface_count() == 1,
			"got %d/%d expected %d/%d (%s boxes x %d/%d), surfaces=%d" % [gv.x, gv.y, eg.x, eg.y,
			"490 + 1176 edge bars =1666" if med == "cubes" else "490", e["vb"], (full.y if med == "cubes" else slab.y), gmi.mesh.get_surface_count()])
		_check("b/%s: GlassBacking vertex/index counts" % med, bv == eb,
			"got %d/%d expected %d/%d (%s)" % [bv.x, bv.y, eb.x, eb.y, "plate + 7 shelves" if med == "cubes" else "plate"])
		var mo: Array = _material_ok(gmi.material_override, e["cull"], float(inst.get_meta("glass_mul_gain", -1.0)))
		_check("b/%s: glass material structure (behaviour: the pixel oracle)" % med, mo[0], mo[1])
		var bm := bmi.material_override as StandardMaterial3D
		_check("b/%s: backing material" % med, bm != null and bm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
			and bm.cull_mode == BaseMaterial3D.CULL_BACK and bm.vertex_color_use_as_albedo and bm.vertex_color_is_srgb and bm.disable_fog,
			"unshaded=%s cull=%d vc_srgb=%s fog_off=%s" % [bm.shading_mode == 0, bm.cull_mode, bm.vertex_color_is_srgb, bm.disable_fog])
		var shadowed := _shadowed_spots(inst)
		_check("b/%s: no shadows" % med, shadowed == 0 and gmi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			and bmi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			"shadowed spots=%d glass cast=%d backing cast=%d" % [shadowed, gmi.cast_shadow, bmi.cast_shadow])
		var gid := gmi.get_instance_id()
		var shader_id: int = ((gmi.material_override as ShaderMaterial).shader as Shader).get_instance_id()
		for cfg in [{"medium": med}, {"medium": med}, {}, {"museum_yaw": 0}, {"emissive": false}, {"medium": med.to_upper()}]:
			inst.call("apply_grid_config", cfg)
		await _frames(2)
		var g2 := inst.get_node_or_null("GlassHomages")
		_check("b/%s: repeat config keeps the build" % med, g2 != null and g2.get_instance_id() == gid and int(inst.get("_build_count")) == 1,
			"same instance=%s builds=%d" % [g2 != null and g2.get_instance_id() == gid, inst.get("_build_count")])

		var gcol: PackedColorArray = garr[Mesh.ARRAY_COLOR]
		var bcol: PackedColorArray = barr[Mesh.ARRAY_COLOR]
		var vb: int = e["vb"]
		var passes: int = e["passes"]
		var table: Color = bcol[0]

		# ---- (b) cubes: edge bars and shelves
		if med == "cubes":
			var bar_bad_col := 0
			var bar_min_in := INF
			for ci in 98:
				var outer := box_aabb(gverts, vb, ci * 5)
				var face: Color = gcol[ci * 5 * vb]
				for j in 12:
					var bb := 490 + ci * 12 + j
					if gcol[bb * vb] != face:
						bar_bad_col += 1
					bar_min_in = minf(bar_min_in, inside_margin(box_aabb(gverts, vb, bb), outer, [0, 1, 2]))
			_check("b/cubes: 12 edge bars per canvas in the outer face colour, inside the outer cube", bar_bad_col == 0 and bar_min_in >= -1e-5,
				"bars with another colour %d of 1176; deepest poke-out %.6f m (>= 0 is inside)" % [bar_bad_col, bar_min_in])
			var bverts: PackedVector3Array = barr[Mesh.ARRAY_VERTEX]
			var bnorm: PackedVector3Array = barr[Mesh.ARRAY_NORMAL]
			var plate := box_aabb(bverts, 24, 0)
			var shelf_ok := 0
			var shelf_notes: PackedStringArray = []
			for sh in range(1, 8):
				var sb := box_aabb(bverts, 24, sh)
				var top_is_table := true
				var front_darker := false
				for j in 24:
					var vi := sh * 24 + j
					if bnorm[vi].y > 0.5 and bcol[vi] != table:
						top_is_table = false
					if bnorm[vi].z > 0.5 and bcol[vi].get_luminance() < table.get_luminance() - 0.1:
						front_darker = true
				var attached: bool = absf(sb.position.z - plate.end.z) < 1e-5
				# the row's cubes stand on it: some outer cube's bottom sits on this shelf's top
				var under := false
				for ci in 98:
					var ob := box_aabb(gverts, vb, ci * 5)
					if absf(ob.position.y - sb.end.y) < 0.001 and ob.end.z < sb.end.z and ob.position.z > sb.position.z:
						under = true
						break
				if top_is_table and front_darker and attached and under:
					shelf_ok += 1
				else:
					shelf_notes.append("shelf %d top=table %s front darker %s attached %s carries cubes %s" % [sh, top_is_table, front_darker, attached, under])
			_check("b/cubes: 7 shelves attached to the table, table colour on top, darker front, cubes standing on them", shelf_ok == 7,
				"%d of 7 ok %s" % [shelf_ok, "; ".join(shelf_notes)])

		# ---- (c) solve oracle from the read-back colours, and the clamped squares' error
		var uniform := true
		var max_err := 0.0
		var max_err_lin := 0.0
		var fails := 0
		var unclamped := 0
		var clamped := 0
		var clamped_sq := 0
		var clamp_not_255 := 0
		var meta_canvas_mismatch := 0
		var palette_meta_mismatch := 0
		var sub_byte_clamps := 0
		var clamped_err_255: Array = []
		var square_worst_255: Array = []
		var de_clamped: Array = []
		var de_all: Array = []
		var de_paint: Array = []
		for ci in 98:
			var pal: Array = regen_palette(inst, ci)
			var marker := inst.get_node_or_null("Canvas_%02d" % ci)
			var a: Array = [t_lin(table.r), t_lin(table.g), t_lin(table.b)]
			var canvas_clamped := 0
			for k in 5:
				var box: int = ci * 5 + k
				var face: Color = gcol[box * vb]
				for j in vb:
					if gcol[box * vb + j] != face:
						uniform = false
				var col: Color = pal[k]
				if marker != null:
					var mp: PackedColorArray = marker.get_meta("palette")
					if not mp[k].is_equal_approx(col):
						palette_meta_mismatch += 1
				var hit := false
				var worst := 0.0
				for ch in 3:
					var target := t_lin(col[ch])
					var tr := pow(t_lin(face[ch]), passes)
					var out: float = a[ch] * tr
					if target > a[ch]:
						clamped += 1
						canvas_clamped += 1
						hit = true
						if roundi(face[ch] * 255.0) != 255:
							clamp_not_255 += 1
						var ce := absf(t_srgb(out) - col[ch]) * 255.0
						clamped_err_255.append(ce)
						worst = maxf(worst, ce)
						if (col[ch] - t_srgb(a[ch])) * 255.0 < 0.5:
							sub_byte_clamps += 1
					else:
						unclamped += 1
						var err := absf(t_srgb(out) - col[ch])
						max_err = maxf(max_err, err)
						max_err_lin = maxf(max_err_lin, absf(out - target))
						worst = maxf(worst, err * 255.0)
						if err > TOL:
							fails += 1
					a[ch] = out
				var achieved := Color(t_srgb(a[0]), t_srgb(a[1]), t_srgb(a[2]), 1.0)
				var d := de76(achieved, col)
				de_all.append(d)
				de_paint.append(de76(Color(t_srgb(col.r), t_srgb(col.g), t_srgb(col.b), 1.0), col))
				if hit:
					clamped_sq += 1
					de_clamped.append(d)
					square_worst_255.append(worst)
			if marker != null and int(marker.get_meta("clamped", -1)) != canvas_clamped:
				meta_canvas_mismatch += 1
		var meta_cl: int = inst.get_meta("glass_clamped", -1)
		var meta_sq: int = inst.get_meta("glass_clamped_squares", -1)
		_numbers["clamp_%s" % med] = {"channels_clamped": clamped, "channels_unclamped": unclamped,
			"squares_clamped": clamped_sq, "squares_total": 490, "meta_channels": meta_cl, "meta_squares": meta_sq,
			"sub_byte_clamps": sub_byte_clamps,
			"max_err_srgb_255": max_err * 255.0, "max_err_linear": max_err_lin,
			"clamped_channel_err_srgb_255": dist(clamped_err_255),
			"clamped_square_worst_channel_255": dist(square_worst_255),
			"clamped_square_dE76": dist(de_clamped),
			"all_squares_dE76": dist(de_all),
			"paint_wall_vs_palette_dE76": dist(de_paint),
			"table_bytes": "%d,%d,%d" % [roundi(table.r * 255), roundi(table.g * 255), roundi(table.b * 255)]}
		_check("c/%s: oracle within 2/255 on every unclamped channel" % med, fails == 0 and uniform and unclamped > 0,
			"%d unclamped channels, %d over, max err %.3f/255 sRGB (linear %.5f), per-box colour uniform=%s" % [unclamped, fails, max_err * 255.0, max_err_lin, uniform])
		_check("c/%s: clamp count == root meta" % med, clamped == meta_cl and clamped_sq == meta_sq and meta_canvas_mismatch == 0 and clamp_not_255 == 0,
			"oracle %d channels / %d squares of 490; meta %d / %d; per-canvas mismatches %d; clamped faces not 255: %d" % [clamped, clamped_sq, meta_cl, meta_sq, meta_canvas_mismatch, clamp_not_255])
		_check("c/%s: Canvas meta palette == regenerated palette" % med, palette_meta_mismatch == 0, "%d mismatches" % palette_meta_mismatch)
		var dc: Dictionary = dist(clamped_err_255)
		var dd: Dictionary = dist(de_clamped)
		var dp: Dictionary = dist(de_paint)
		_check("c/%s: clamped squares measured against the palette (recorded, not gated)" % med, clamped_err_255.size() == clamped,
			"%d clamped channels: median %s/255 p75 %s max %s; %d clamped squares: dE76 median %s max %s; %d sub-byte ties; paint wall itself vs palette dE76 median %s" % [
			clamped, dc.get("median"), dc.get("p75"), dc.get("max"), clamped_sq, dd.get("median"), dd.get("max"), sub_byte_clamps, dp.get("median")])

		# ---- (g) containment, from the read-back geometry
		var min_in := INF
		var poke := 0
		for ci in 98:
			for k in range(1, 5):
				var m := inside_margin(box_aabb(gverts, vb, ci * 5 + k), box_aabb(gverts, vb, ci * 5 + k - 1), e["axes"])
				min_in = minf(min_in, m)
				if m < 0.001 - 1e-6:
					poke += 1
		_check("g/%s: every square inside the square it nests in (>= 1 mm)" % med, poke == 0 and int(inst.get_meta("glass_bias_held", -1)) == 0,
			"%d of 392 closer than 1 mm; tightest %.2f mm; held by the build %d" % [poke, min_in * 1000.0, inst.get_meta("glass_bias_held", -1)])
		_numbers["containment_%s_mm" % med] = snappedf(min_in * 1000.0, 0.01)

		# ---- (f) winding
		var wg := winding_bad(garr, vb, false)
		var wb := winding_bad(barr, full.x, false)
		var wneg := winding_bad(garr, vb, true)
		_check("f/%s: every triangle faces outward (clockwise front)" % med, wg.x == 0 and wb.x == 0 and wg.y > 0,
			"glass bad %d/%d, backing bad %d/%d" % [wg.x, wg.y, wb.x, wb.y])
		_check("f/%s: non-vacuity - the checker flags reversed indices" % med, wneg.x == wneg.y and wneg.y > 0,
			"reversed glass bad %d/%d (arithmetic, not evidence: see the CULL_BACK relief pixels)" % [wneg.x, wneg.y])

		_layers[med] = _dump_glass(inst, garr, barr, vb, passes)
		_layers[med]["table"] = b3(table)

		# ---- (e) remove + re-add rebuilds (same frame, then across frames)
		var before := _sig_text(inst)
		root.remove_child(inst)
		root.add_child(inst)
		await _settle()
		var g3 := inst.get_node_or_null("GlassHomages") as MeshInstance3D
		var after := _sig_text(inst)
		_check("e/%s: remove + add_child (same frame) rebuilds" % med, g3 != null and not g3.is_queued_for_deletion()
			and after == before and _count_meshes(inst) == 2,
			"GlassHomages=%s queued=%s meshes=%d sig equal=%s builds=%d" % [g3 != null, g3 != null and g3.is_queued_for_deletion(), _count_meshes(inst), after == before, inst.get("_build_count")])
		var same_shader: bool = g3 != null and ((g3.material_override as ShaderMaterial).shader as Shader).get_instance_id() == shader_id
		_check("e/%s: the rebuild reuses the compiled Shader" % med, same_shader, "same Shader object=%s" % same_shader)
		root.remove_child(inst)
		await _frames(3)
		root.add_child(inst)
		await _settle()
		var after2 := _sig_text(inst)
		_check("e/%s: remove, wait 3 frames, add_child rebuilds" % med, after2 == before and inst.get_node_or_null("GlassHomages") != null,
			"sig equal=%s meshes=%d builds=%d" % [after2 == before, _count_meshes(inst), inst.get("_build_count")])
		await _drop(inst)

	# ---- (g) negative: a vertical_bias that would push the nest out is held inside
	inst = (load(SCENE) as PackedScene).instantiate()
	inst.set("vertical_bias", -0.5)
	var vb_read: float = inst.get("vertical_bias")
	inst.set_meta("config_medium", "cubes")
	root.add_child(inst)
	await _settle()
	var gx := inst.get_node_or_null("GlassHomages") as MeshInstance3D
	if gx != null:
		var xv: PackedVector3Array = gx.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var o0 := box_aabb(xv, 24, 0)
		var o1 := box_aabb(xv, 24, 1)
		var s_out: float = o0.size.x
		var s_in: float = o1.size.x
		var unheld_step: float = absf(vb_read) * float(inst.get("canvas_size")) * (s_out / (float(inst.get("canvas_size")) * (1.0 - 2.0 * float(inst.get("border_ratio"))))) * 0.25
		var room: float = (s_out - s_in) * 0.5
		var min_neg := INF
		for ci in 98:
			for k in range(1, 5):
				min_neg = minf(min_neg, inside_margin(box_aabb(xv, 24, ci * 5 + k), box_aabb(xv, 24, ci * 5 + k - 1), [0, 1, 2]))
		var held_n: int = inst.get_meta("glass_bias_held", 0)
		_check("g/negative: vertical_bias -0.5 would poke square 1 out, and is held inside with a warning",
			absf(vb_read + 0.5) < 1e-6 and unheld_step > room and held_n > 0 and min_neg >= 0.001 - 1e-6 and _catch.saw("held inside"),
			"bias read back %.3f; unheld step %.4f m > room %.4f m = %s; held %d squares; tightest %.2f mm; warned=%s" % [
			vb_read, unheld_step, room, unheld_step > room, held_n, min_neg * 1000.0, _catch.saw("held inside")])
	else:
		_check("g/negative: vertical_bias -0.5 build", false, "no GlassHomages")
	await _drop(inst)

	# ---- (d) round trip cubes -> relief -> paint, orphans and resources
	inst = _new_inst()
	await _settle()
	await _frames(3)
	var orphans0: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	inst.call("apply_grid_config", {"medium": "cubes"})
	await _frames(2)
	var m_c := _count_meshes(inst)
	# Resources by weakref: Performance.OBJECT_RESOURCE_COUNT is blind here (measured: it
	# read 200 before, during and after, and did not see a stray Resource.new() either).
	var held_refs: Array = []
	for nm in ["GlassHomages", "GlassBacking"]:
		var mi := inst.get_node_or_null(nm) as MeshInstance3D
		if mi != null:
			held_refs.append(weakref(mi.mesh))
			held_refs.append(weakref(mi.material_override))
	var shader_ref: WeakRef = null
	var gh := inst.get_node_or_null("GlassHomages") as MeshInstance3D
	if gh != null:
		shader_ref = weakref((gh.material_override as ShaderMaterial).shader)
	gh = null
	inst.call("apply_grid_config", {"medium": "relief"})
	await _frames(2)
	var m_r := _count_meshes(inst)
	inst.call("apply_grid_config", {"medium": "paint"})
	await _frames(3)
	var orphans1: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var srt := _sig_text(inst)
	_check("d: round trip cubes -> relief -> paint == baseline", srt == baseline and m_c == 2 and m_r == 2,
		"equal=%s meshes cubes=%d relief=%d paint=%d builds=%d" % [srt == baseline, m_c, m_r, _count_meshes(inst), inst.get("_build_count")])
	# the monitor must be able to SEE an orphan, or "back to start" proves nothing
	var stray := Node.new()
	var orphans_seen: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	stray.free()
	_check("d: orphan nodes back to start", orphans1 == orphans0 and orphans_seen == orphans1 + 1,
		"start %d end %d (monitor sees a stray Node: %d)" % [orphans0, orphans1, orphans_seen])
	# and resources: the cubes build's meshes and materials are RefCounted and must be
	# freed with their nodes; only the cached Shader outlives them, by design
	var alive := 0
	for w in held_refs:
		if (w as WeakRef).get_ref() != null:
			alive += 1
	var shader_alive: bool = shader_ref != null and shader_ref.get_ref() != null
	var ctrl: WeakRef = weakref(Resource.new())
	_check("d: the cubes build's meshes and materials are freed after the round trip", held_refs.size() == 4 and alive == 0
		and shader_alive and ctrl.get_ref() == null,
		"%d of %d still alive; cached Shader alive=%s (by design); a dropped Resource reads freed=%s" % [alive, held_refs.size(), shader_alive, ctrl.get_ref() == null])
	_numbers["orphans"] = {"start": orphans0, "end": orphans1}
	_numbers["resources_alive_after_round_trip"] = alive

	# ---- (e) unknown word
	inst.call("apply_grid_config", {"medium": "cubes"})
	await _frames(1)
	inst.call("apply_grid_config", {"medium": "glitter"})
	await _frames(3)
	var su := _sig_text(inst)
	_check("e: unknown word -> paint with a warning", su == baseline and str(inst.get("medium")) == "paint" and _catch.saw("unknown medium 'glitter'"),
		"medium=%s sig==baseline=%s warned=%s" % [inst.get("medium"), su == baseline, _catch.saw("unknown medium 'glitter'")])
	await _drop(inst)
	inst = _new_inst("stained")
	await _settle()
	var sm := _sig_text(inst).replace("\"root_meta\": \"config_medium\"", "\"root_meta\": \"\"")
	_check("e: unknown config_medium meta -> paint with a warning", str(inst.get("medium")) == "paint" and _catch.saw("unknown medium 'stained'")
		and int(inst.get("_build_count")) == 1 and sm == baseline,
		"medium=%s warned=%s builds=%d sig==baseline (root meta aside)=%s" % [inst.get("medium"), _catch.saw("unknown medium 'stained'"), inst.get("_build_count"), sm == baseline])
	await _drop(inst)

	# ---- (b) the project setting overrides the gain table (a headset value needs no code)
	ProjectSettings.set_setting(GAIN_SETTING, 1.7)
	inst = _new_inst("relief")
	await _settle()
	var go := inst.get_node_or_null("GlassHomages") as MeshInstance3D
	var g_param = (go.material_override as ShaderMaterial).get_shader_parameter("gain") if go != null else null
	_check("b: project setting %s reaches the shader" % GAIN_SETTING, g_param != null and absf(float(g_param) - 1.7) < 1e-6
		and str(inst.get_meta("glass_mul_gain_source", "")) == "setting",
		"gain=%s source=%s" % [g_param, inst.get_meta("glass_mul_gain_source", "")])
	await _drop(inst)
	ProjectSettings.set_setting(GAIN_SETTING, null)
	inst = _new_inst("relief")
	await _settle()
	var src_after: String = str(inst.get_meta("glass_mul_gain_source", ""))
	_check("b: without the setting the measured rule applies", src_after.begins_with("rule:") and str(inst.get_meta("glass_blend_space", "")) == "linear",
		"source=%s gain=%s blend space=%s" % [src_after, inst.get_meta("glass_mul_gain", null), inst.get_meta("glass_blend_space", "")])
	await _drop(inst)

	# ---- write
	var lf := FileAccess.open(ProjectSettings.globalize_path(LAYERS_FILE), FileAccess.WRITE)
	lf.store_string(JSON.stringify(_layers))
	lf.close()
	var failed := 0
	for c in _checks:
		if not c["passed"]:
			failed += 1
	var out := {"passed": _checks.size() - failed, "failed": failed, "checks": _checks, "numbers": _numbers,
		"renderer": RenderingServer.get_current_rendering_method(), "at": Time.get_datetime_string_from_system()}
	var path: String = ProjectSettings.globalize_path(OUT_FILE)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  ", false))
	f.close()
	print("probe_albers_glass check: %d passed, %d failed -> %s" % [_checks.size() - failed, failed, path])
	OS.remove_logger(_catch)
	quit(1 if failed > 0 else 0)

# @identity
# essence: a DRESSING ROOM for one pearl at a time — every artifact from every
# SPINE map (269 maps, 24 sequences), and the whole registry as a tail, each
# standing alone on the museum's own floor, close up, wearing its real dress
# desire: dress anything anywhere without booting the museum — one pearl, one
# deck, the camera at arm's length, the backdrop always behind the work
# critical_parameter: map_name — where the string OPENS; P walks beads, N jumps maps
# triggers: every dress key WRITES THE MAP at the pearl's own cell and respawns it
# truth: the token is the pearl; the config is how it stands; the maps are the string
extends Node3D

@export var map_name: String = "Point_One"

const DRESS_FLOAT := 0.03
const _EmMaterials := preload("res://commons/scenes/em/em_materials.gd")

var _scenes: Dictionary = {}          # token -> scene path (registry scan)
var _beads: Array = []                # {map, x, z, tok, node, plinth_node}
var _sel: int = -1
var _cam: Camera3D
var _yaw := 0.6
var _pitch := -0.35
var _dist := 4.0
var _focus := Vector3(0.0, 0.9, 0.0)
var _panel: Label
var _backdrop: MeshInstance3D
var _orbit := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--map="):
			map_name = str(a).split("=")[1]
	_scan_registries()
	_build_stage()
	_load_beads()
	_build_camera()
	_build_panel()
	# open the string at map_name's first bead
	var start := 0
	for i in range(_beads.size()):
		if String((_beads[i] as Dictionary)["map"]) == map_name:
			start = i
			break
	if not _beads.is_empty():
		_select(start)


func _scan_registries() -> void:
	var dir := DirAccess.open("res://commons/artifacts/registry")
	if dir == null:
		return
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var doc_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(
			"res://commons/artifacts/registry/" + f))
		if not (doc_v is Dictionary):
			continue
		var arts: Variant = (doc_v as Dictionary).get("artifacts", {})
		if not (arts is Dictionary):
			continue
		for tok in (arts as Dictionary):
			var e: Variant = (arts as Dictionary)[tok]
			if e is Dictionary and (e as Dictionary).has("scene") and not _scenes.has(tok):
				_scenes[tok] = String((e as Dictionary)["scene"])


func _spine_maps() -> Array:
	## Every map of every spine sequence, in spine order, existing on disk.
	var out: Array = []
	var seen: Dictionary = {}
	var sp_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://commons/maps/curriculum_spine.json"))
	if not (sp_v is Dictionary):
		return out
	var seqs: Array = ((sp_v as Dictionary).get("spine", sp_v) as Dictionary).get("sequences", [])
	for s_v in seqs:
		var sname := String((s_v as Dictionary).get("name", "")) if s_v is Dictionary else String(s_v)
		if sname == "":
			continue
		var sq_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(
			"res://commons/maps/sequences/%s.json" % sname))
		if not (sq_v is Dictionary):
			continue
		for m in _find_maps(sq_v):
			var mn := String(m)
			if seen.has(mn):
				continue
			seen[mn] = true
			if FileAccess.file_exists("res://commons/maps/%s/map_data.json" % mn):
				out.append(mn)
	return out


func _find_maps(o: Variant) -> Array:
	if o is Dictionary:
		for k in (o as Dictionary):
			var v: Variant = (o as Dictionary)[k]
			if String(k) == "maps" and v is Array and not (v as Array).is_empty() \
					and (v as Array)[0] is String:
				return v
			var r := _find_maps(v)
			if not r.is_empty():
				return r
	return []


func _map_doc(mn: String) -> Dictionary:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://commons/maps/%s/map_data.json" % mn))
	return v as Dictionary if v is Dictionary else {}


func _build_stage() -> void:
	# the museum's own floor underfoot ("show museum floor")
	var fm: Material = _EmMaterials.get_material(&"floor")
	if fm == null:
		var fb := StandardMaterial3D.new()
		fb.albedo_color = Color(0.16, 0.16, 0.19)
		fm = fb
	_box(Vector3(0, -0.1, 0), Vector3(7, 0.2, 7), fm)
	# ONE backdrop wall — repositioned every frame to stand BEHIND the
	# artifact as the camera orbits ("show only the walls behind the artifact
	# as I rotate"): the studio cyclorama that follows
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.90, 0.895, 0.875)
	bm.roughness = 0.86
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(7, 3.6, 0.2)
	_backdrop = MeshInstance3D.new()
	_backdrop.mesh = bmesh
	_backdrop.material_override = bm
	add_child(_backdrop)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 34, 0)
	sun.light_energy = 1.1
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.10, 0.10, 0.12)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.72)
	e.ambient_light_energy = 0.7
	env.environment = e
	add_child(env)


func _box(p: Vector3, s: Vector3, m: Material) -> void:
	var bm := BoxMesh.new()
	bm.size = s
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	add_child(mi)


func _load_beads() -> void:
	## The whole string: every artifact of every spine map, then the registry
	## as a browsable tail ("all artifact collections" — view-only there).
	_despawn_shown()
	_beads.clear()
	for mn in _spine_maps():
		var doc := _map_doc(mn)
		var inter: Array = (doc.get("layers", {}) as Dictionary).get("interactables", [])
		for z in range(inter.size()):
			var row: Array = inter[z]
			for x in range(row.size()):
				var tok := str(row[x]).strip_edges()
				if tok == "" or tok.begins_with("cluster:"):
					continue
				_beads.append({"map": mn, "x": x, "z": z, "tok": tok,
					"node": null, "plinth_node": null})
	var regs := _scenes.keys()
	regs.sort()
	for tok2 in regs:
		_beads.append({"map": "", "x": -1, "z": -1, "tok": String(tok2),
			"node": null, "plinth_node": null})


func _despawn_shown() -> void:
	for b_v in _beads:
		for k in ["node", "plinth_node"]:
			var n: Node = (b_v as Dictionary).get(k)
			if n != null and is_instance_valid(n):
				n.queue_free()
			(b_v as Dictionary)[k] = null


func _tok_cfg(tok: String) -> Dictionary:
	var out: Dictionary = {}
	var segs := tok.split("#")
	for i in range(1, segs.size()):
		var s := str(segs[i])
		var ci := s.find(":")
		if ci > 0:
			out[s.substr(0, ci).strip_edges()] = s.substr(ci + 1).strip_edges()
	return out


func _spawn(mn: String, tok: String, x: int, z: int) -> Dictionary:
	var head := tok.split("#")[0].split(":")
	var name2 := str(head[0])
	var rot := float(head[1]) if head.size() > 1 and str(head[1]).is_valid_float() else 0.0
	var yoff := float(head[2]) if head.size() > 2 and str(head[2]).is_valid_float() else 0.0
	var cfg := _tok_cfg(tok)
	var out := {"map": mn, "x": x, "z": z, "tok": tok, "node": null, "plinth_node": null}
	var spath := String(_scenes.get(name2, ""))
	if spath == "" or not ResourceLoader.exists(spath):
		return out
	var node: Node3D = (load(spath) as PackedScene).instantiate() as Node3D
	if node == null:
		return out
	for k in cfg:
		node.set_meta("config_%s" % str(k), cfg[k])
	if node.has_method("apply_grid_config"):
		node.call("apply_grid_config", cfg)
	var ph := 0.0
	var pkind := "station_plinth"
	if cfg.has("plinth"):
		var pp := str(cfg["plinth"]).split(",")
		if str(pp[0]).strip_edges().is_valid_float():
			ph = clampf(float(str(pp[0])), 0.0, 3.0)
		if pp.size() > 1 and str(pp[1]).strip_edges() == "micropod":
			pkind = "station_micropod"
	var off := Vector3.ZERO
	if cfg.has("offset"):
		var op := str(cfg["offset"]).split(",")
		if op.size() >= 3 and str(op[0]).strip_edges().is_valid_float():
			off = Vector3(float(op[0]), float(op[1]), float(op[2]))
	# the dressing room: every pearl stands at the STAGE CENTRE — its map
	# cell rides along only as the write address
	var base := Vector3(0.0, 0.0, 0.0)
	if ph > 0.05:
		var ps: PackedScene = load("res://commons/artifacts/station/%s.tscn" % pkind) as PackedScene
		if ps != null:
			var pn: Node3D = ps.instantiate() as Node3D
			var pcfg := {"top_height": ph, "cap_meters": 0.9 if pkind == "station_plinth" else 0.6,
				"width_cells": 1, "depth_cells": 1, "top_style": "flat", "glow_light": false}
			for k2 in pcfg:
				pn.set_meta("config_%s" % str(k2), pcfg[k2])
			if pn.has_method("apply_grid_config"):
				pn.call("apply_grid_config", pcfg)
			pn.position = base
			add_child(pn)
			out["plinth_node"] = pn
		node.position = base + Vector3(off.x, ph + DRESS_FLOAT + off.y, off.z)
	else:
		node.position = base + Vector3(off.x, yoff + off.y, off.z)
	node.rotation_degrees.y = rot
	if cfg.has("scale") and str(cfg["scale"]).is_valid_float():
		node.scale = Vector3.ONE * clampf(float(str(cfg["scale"])), 0.1, 5.0)
	add_child(node)
	out["node"] = node
	return out


func _build_camera() -> void:
	_cam = Camera3D.new()
	add_child(_cam)
	_update_cam()
	_cam.current = true


func _update_cam() -> void:
	var dir := Vector3(cos(_pitch) * sin(_yaw), -sin(_pitch), cos(_pitch) * cos(_yaw))
	_cam.position = _focus + dir * _dist
	_cam.look_at(_focus, Vector3.UP)
	# the backdrop stands OPPOSITE the camera — always behind the artifact
	if _backdrop != null and is_instance_valid(_backdrop):
		var horiz := Vector3(dir.x, 0.0, dir.z)
		if horiz.length() > 0.01:
			horiz = horiz.normalized()
			_backdrop.position = Vector3(-horiz.x * 3.2, 1.6, -horiz.z * 3.2)
			_backdrop.look_at(Vector3(0, 1.6, 0), Vector3.UP)


func _build_panel() -> void:
	var cl := CanvasLayer.new()
	_panel = Label.new()
	_panel.position = Vector2(14, 12)
	_panel.add_theme_font_size_override("font_size", 15)
	cl.add_child(_panel)
	add_child(cl)
	_refresh_panel()


func _refresh_panel() -> void:
	var lines := ["PEARL DRESSING ROOM — %d pearls (spine maps + registry)" % _beads.size(),
		"P next · shift+P back · N next map · Q/A plinth · M kind · W/S scale · arrows offset · PgUp/Dn lift · R rotate", ""]
	if _sel >= 0 and _sel < _beads.size():
		var b: Dictionary = _beads[_sel]
		var mn := String(b["map"])
		if mn == "":
			lines.append("%d/%d  REGISTRY (view only — place it in a map to dress it)" % [_sel + 1, _beads.size()])
		else:
			lines.append("%d/%d  %s [%d,%d] — every key WRITES this map" % [
				_sel + 1, _beads.size(), mn, int(b["x"]), int(b["z"])])
		lines.append(str(b["tok"]))
	_panel.text = "\n".join(PackedStringArray(lines))


func _select(i: int) -> void:
	_sel = posmod(i, _beads.size()) if not _beads.is_empty() else -1
	_despawn_shown()
	if _sel >= 0:
		var b: Dictionary = _beads[_sel]
		_beads[_sel] = _spawn(String(b["map"]), str(b["tok"]), int(b["x"]), int(b["z"]))
	_refresh_panel()


func _next_map() -> void:
	if _sel < 0:
		return
	var cur := String((_beads[_sel] as Dictionary)["map"])
	for step in range(1, _beads.size()):
		var i := posmod(_sel + step, _beads.size())
		if String((_beads[i] as Dictionary)["map"]) != cur:
			_select(i)
			return


# ── the WRITES: token surgery straight into the pearl's own map ─────────────
func _rewrite(fn: Callable) -> void:
	if _sel < 0:
		return
	var b: Dictionary = _beads[_sel]
	var mn := String(b["map"])
	if mn == "":
		_refresh_panel()   # registry pearls are view-only
		return
	var path := "res://commons/maps/%s/map_data.json" % mn
	var doc_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (doc_v is Dictionary):
		return
	var inter: Array = ((doc_v as Dictionary).get("layers", {}) as Dictionary).get("interactables", [])
	var z: int = int(b["z"])
	var x: int = int(b["x"])
	if z < 0 or z >= inter.size() or x < 0 or x >= (inter[z] as Array).size():
		return
	var tok := str((inter[z] as Array)[x]).strip_edges()
	if tok == "":
		return
	var ntok := str(fn.call(tok))
	(inter[z] as Array)[x] = ntok
	var f: FileAccess = null
	for attempt in range(6):
		f = FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			break
		OS.delay_msec(50)
	if f == null:
		return
	f.store_string(JSON.stringify(doc_v, "\t"))
	f.close()
	for k in ["node", "plinth_node"]:
		var n: Node = b.get(k)
		if n != null and is_instance_valid(n):
			n.queue_free()
	_beads[_sel] = _spawn(mn, ntok, x, z)
	_refresh_panel()


func _set_key(tok: String, key: String, val: String) -> String:
	var segs := tok.split("#")
	var out := str(segs[0])
	for i in range(1, segs.size()):
		var s := str(segs[i])
		if s.begins_with(key + ":"):
			continue
		if s != "":
			out += "#" + s
	if val != "":
		out += "#" + key + ":" + val
	return out


func _get_key(tok: String, key: String) -> String:
	return str(_tok_cfg(tok).get(key, ""))


func _plinth_of(tok: String) -> Array:
	var pv := _get_key(tok, "plinth").split(",")
	var h := float(str(pv[0])) if str(pv[0]).strip_edges().is_valid_float() else 0.0
	var micro := pv.size() > 1 and str(pv[1]).strip_edges() == "micropod"
	return [h, micro]


func _bump_plinth(d: float) -> void:
	_rewrite(func(tok: String) -> String:
		var pm := _plinth_of(tok)
		var h: float = clampf(snappedf(float(pm[0]) + d, 0.05), 0.0, 3.0)
		return _set_key(tok, "plinth", "" if h < 0.05 else "%.2f%s" % [h, ",micropod" if bool(pm[1]) else ""]))


func _bump_off(d: Vector3) -> void:
	_rewrite(func(tok: String) -> String:
		var ov := _get_key(tok, "offset").split(",")
		var o := Vector3.ZERO
		if ov.size() >= 3 and str(ov[0]).strip_edges().is_valid_float():
			o = Vector3(float(ov[0]), float(ov[1]), float(ov[2]))
		o += d
		var zz := absf(o.x) < 0.001 and absf(o.y) < 0.001 and absf(o.z) < 0.001
		return _set_key(tok, "offset", "" if zz else "%.2f,%.2f,%.2f" % [o.x, o.y, o.z]))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist = clampf(_dist * 0.9, 1.2, 20.0)
			_update_cam()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist = clampf(_dist / 0.9, 1.2, 20.0)
			_update_cam()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_orbit = mb.pressed
	elif event is InputEventMouseMotion and _orbit:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * 0.008
		_pitch = clampf(_pitch - mm.relative.y * 0.006, -1.5, -0.1)
		_update_cam()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var kc := (event as InputEventKey).keycode
		var sh := (event as InputEventKey).shift_pressed
		match kc:
			KEY_P:
				_select(_sel + (-1 if sh else 1))
			KEY_N:
				_next_map()
			KEY_Q:
				_bump_plinth(0.1)
			KEY_A:
				_bump_plinth(-0.1)
			KEY_M:
				_rewrite(func(tok: String) -> String:
					var pm := _plinth_of(tok)
					if float(pm[0]) < 0.05:
						return tok
					return _set_key(tok, "plinth", "%.2f%s" % [float(pm[0]), "" if bool(pm[1]) else ",micropod"]))
			KEY_W:
				_rewrite(func(tok: String) -> String:
					var s := _get_key(tok, "scale")
					var v: float = (float(s) if s.is_valid_float() else 1.0) + 0.05
					return _set_key(tok, "scale", "" if absf(v - 1.0) < 0.02 else "%.2f" % v))
			KEY_S:
				_rewrite(func(tok: String) -> String:
					var s := _get_key(tok, "scale")
					var v: float = maxf(0.1, (float(s) if s.is_valid_float() else 1.0) - 0.05)
					return _set_key(tok, "scale", "" if absf(v - 1.0) < 0.02 else "%.2f" % v))
			KEY_R:
				_rewrite(func(tok: String) -> String:
					var hash_i := tok.find("#")
					var head := tok if hash_i == -1 else tok.substr(0, hash_i)
					var tail := "" if hash_i == -1 else tok.substr(hash_i)
					var parts := head.split(":")
					var r0 := float(str(parts[1])) if parts.size() > 1 and str(parts[1]).is_valid_float() else 0.0
					var rebuilt := [str(parts[0]), str(posmod(int(r0) + 45, 360))]
					for k in range(2, parts.size()):
						rebuilt.append(str(parts[k]))
					return ":".join(rebuilt) + tail)
			KEY_LEFT:
				_bump_off(Vector3(-0.05, 0, 0))
			KEY_RIGHT:
				_bump_off(Vector3(0.05, 0, 0))
			KEY_UP:
				_bump_off(Vector3(0, 0, -0.05))
			KEY_DOWN:
				_bump_off(Vector3(0, 0, 0.05))
			KEY_PAGEUP:
				_bump_off(Vector3(0, 0.05, 0))
			KEY_PAGEDOWN:
				_bump_off(Vector3(0, -0.05, 0))

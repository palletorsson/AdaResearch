extends Node3D
## THE PROP REFERENCE WALL — every wall prop at its ruled height, editable.
##
## "Can we make editable reference walls for all props so you know how to
## put?" — this scene is that wall. One specimen of every token in
## em_props.mount_defaults() hangs on a museum-height wall, each with a label
## naming its height and where that height comes from (code | hand). The
## 1.75 m figure stands at the end so every height is read against a body.
##
## EDITING writes commons/data/prop_wall_rules.json — the same file
## em_props._ruled_y consults when dressing the endless museum, so a nudge
## here IS the museum's new convention. The scene never edits em_props' code
## defaults; a rule is only saved for a prop whose height differs from code,
## and deleting the file restores every code convention.
##
##   Run:  godot --path . res://commons/scenes/prop_reference_wall.tscn
##   Keys: WASD + mouse look · E select · UP/DOWN nudge 5 cm · R reset to
##         code · F5 save rules · ESC release mouse

const EmProps := preload("res://commons/scenes/em/em_props.gd")
const EmDetail := preload("res://commons/scenes/em/em_detail.gd")
const EmEditor := preload("res://commons/scenes/em/em_editor.gd")
const EmPlinths := preload("res://commons/scenes/em/em_plinths.gd")

const SPACING := 3.0
const REGISTRY_DIR := "res://commons/artifacts/registry"

var _cam: Camera3D
var _yaw: float = 0.0
var _pitch: float = 0.0
var _records: Array = []   # [{node, token, label, code_h, kind, key?}]
var _sel: int = -1
var _dirty: bool = false
var _hud: Label
var _band_stripe: MeshInstance3D
var _band_x0: float = 0.0
var _band_x1: float = 0.0


func _ready() -> void:
	var wall_h: float = float(EmDetail.WALL_H)
	var defaults: Dictionary = EmProps.mount_defaults()
	var n: int = defaults.size()
	# corridor zones along +x: ruled wall props · viewing band · ceiling
	# strip · apertures · floor row · tabletop row · edge row. Specimen
	# zones are E-inspectable but carry no height rule (their convention is
	# WHERE they stand, not how high) — the nudge refuses them with a voice.
	var specs: Dictionary = _specimen_tokens()
	var n_spec: int = 0
	for cls in specs:
		n_spec += (specs[cls] as Array).size()
	var length: float = SPACING * (n + 1) + 8.0 \
		+ 10.0 + SPACING * float(n_spec) + 6.0

	# floor and wall, flat museum tones
	_slab(Vector3(length / 2.0, -0.1, 3.0), Vector3(length, 0.2, 6.0), Color(0.16, 0.16, 0.19))
	_slab(Vector3(length / 2.0, wall_h / 2.0, -0.5), Vector3(length, wall_h, 1.0), Color(0.86, 0.855, 0.845))
	# a head-height datum line on the wall, faint: the 1.65 eye line
	_slab(Vector3(length / 2.0, 1.65, 0.005), Vector3(length, 0.01, 0.01), Color(0.5, 0.45, 0.4))

	var scenes: Dictionary = _resolve_scenes(defaults.keys())
	var i: int = 0
	for token in defaults:
		i += 1
		var x: float = SPACING * i
		var code_h: float = float(defaults[token])
		var h: float = EmProps._ruled_y(token, code_h)
		var holder := Node3D.new()
		holder.name = token
		holder.position = Vector3(x, h, 0.12)
		add_child(holder)
		var path: String = String(scenes.get(token, ""))
		if path != "" and ResourceLoader.exists(path):
			var inst: Node3D = (load(path) as PackedScene).instantiate() as Node3D
			holder.add_child(inst)
		else:
			# no scene resolved — hang a placeholder so the SLOT is still real
			var ph := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.4, 0.4, 0.06)
			ph.mesh = bm
			holder.add_child(ph)
		var lbl := Label3D.new()
		lbl.position = Vector3(x, wall_h - 0.25, 0.15)
		lbl.font_size = 40
		lbl.modulate = Color(0.95, 0.9, 0.75)
		add_child(lbl)
		var rec: Dictionary = {"node": holder, "token": token, "label": lbl, "code_h": code_h}
		_records.append(rec)
		_update_label(rec)

	# ── THE VIEWING BAND — the standing conventions, editable like the props.
	# em_plinths lifts every floor artifact so its CENTRE lands here; these
	# five handles are that museology. Nudging target_centre re-aims every
	# plinth the museum builds; python's negotiator reads the same file.
	_band_x0 = SPACING * (n + 1) + 0.5
	_band_x1 = _band_x0 + 6.0
	_band_stripe = MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(1, 1, 1)
	_band_stripe.mesh = sb
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.95, 0.75, 0.25, 0.22)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_band_stripe.material_override = sm
	add_child(_band_stripe)
	var band_defs: Array = [
		["target_centre", EmPlinths.TARGET_CENTRE, "where a standing artifact's CENTRE lands"],
		["band_low", EmPlinths.BAND_LOW, "the band's floor"],
		["band_high", EmPlinths.BAND_HIGH, "the band's ceiling"],
		["min_lift", EmPlinths.MIN_LIFT, "below this, no furniture is worth it"],
		["max_lift", EmPlinths.MAX_LIFT, "the tallest pedestal the corpus ships"],
	]
	var bi: int = 0
	for bd_v in band_defs:
		var bd: Array = bd_v
		var key := String(bd[0])
		var code_v := float(bd[1])
		var v: float = EmPlinths.band(key, code_v)
		var bx: float = _band_x0 + 0.6 + bi * 1.15
		var handle := Node3D.new()
		handle.name = "band_" + key
		handle.position = Vector3(bx, v, 0.1)
		add_child(handle)
		var hm2 := MeshInstance3D.new()
		var hb := BoxMesh.new()
		hb.size = Vector3(0.9, 0.05, 0.08)
		hm2.mesh = hb
		var hmat := StandardMaterial3D.new()
		hmat.albedo_color = Color(0.95, 0.6, 0.15)
		hm2.material_override = hmat
		handle.add_child(hm2)
		var blbl := Label3D.new()
		blbl.position = Vector3(bx, wall_h - 0.25 - (bi % 2) * 0.35, 0.15)
		blbl.font_size = 36
		add_child(blbl)
		var brec: Dictionary = {"node": handle, "token": key, "label": blbl,
			"code_h": code_v, "kind": "band", "key": key}
		_records.append(brec)
		_update_label(brec)
		bi += 1
	_refresh_band_stripe()

	_figure(Vector3(_band_x1 + 0.8, 0.0, 1.2))

	# ── THE SPECIMEN ZONES — the rest of the catalogue, in situ ─────────────
	var scenes2: Dictionary = {}
	var all_spec_tokens: Array = []
	for cls in specs:
		all_spec_tokens.append_array(specs[cls])
	scenes2 = _resolve_scenes(all_spec_tokens)
	var sx: float = _band_x1 + 2.5
	# ceiling strip: a genuine soffit slab, with the ceiling class under it
	var ceil_tokens: Array = specs.get("ceiling", [])
	if not ceil_tokens.is_empty():
		var strip_len: float = SPACING * (ceil_tokens.size() + 1)
		_slab(Vector3(sx + strip_len / 2.0, float(EmDetail.CEIL_SOFFIT) + 0.1, 3.0),
			Vector3(strip_len, 0.2, 6.0), Color(0.9, 0.89, 0.87))
		for t in ceil_tokens:
			sx += SPACING
			_specimen(String(t), "ceiling", Vector3(sx, float(EmDetail.CEIL_SOFFIT) - 0.05, 3.0),
				scenes2, wall_h)
		sx += SPACING
	# apertures: door leaves against the wall — they LIVE in openings
	for t in specs.get("aperture", []):
		sx += SPACING
		_specimen(String(t), "aperture", Vector3(sx, 0.0, 0.35), scenes2, wall_h)
	# floor class: stands on the deck
	for t in specs.get("floor", []):
		sx += SPACING
		_specimen(String(t), "floor", Vector3(sx, 0.0, 2.0), scenes2, wall_h)
	# tabletop class: on a 0.9 m block, the bench convention
	for t in specs.get("tabletop", []):
		sx += SPACING
		_slab(Vector3(sx, 0.45, 2.0), Vector3(1.0, 0.9, 0.7), Color(0.4, 0.38, 0.36))
		_specimen(String(t), "tabletop", Vector3(sx, 0.9, 2.0), scenes2, wall_h)
	# edge class: hugs the wall base
	for t in specs.get("edge", []):
		sx += SPACING
		_specimen(String(t), "edge", Vector3(sx, 0.0, 0.6), scenes2, wall_h)

	_cam = Camera3D.new()
	_cam.position = Vector3(2.0, 1.65, 4.5)
	add_child(_cam)
	_cam.make_current()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.35, 0.37, 0.4)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.72)
	e.ambient_light_energy = 0.7
	env.environment = e
	add_child(env)
	_hud = _make_hud()
	_update_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("[prop-wall] %d props hung; E select, UP/DOWN nudge, R reset, F5 save" % _records.size())


func _process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir.z -= 1.0
	if Input.is_key_pressed(KEY_S): dir.z += 1.0
	if Input.is_key_pressed(KEY_A): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): dir.x += 1.0
	if dir != Vector3.ZERO:
		_cam.position += (_cam.global_transform.basis * dir.normalized()) * 4.0 * delta
		_cam.position.y = clampf(_cam.position.y, 0.4, 4.0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * 0.0028
		_pitch = clampf(_pitch - event.relative.y * 0.0028, -1.2, 1.2)
		_cam.rotation = Vector3(_pitch, _yaw, 0.0)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_F10:
				# back to the shipped menu (the corridor is reachable from
				# its sequences picker as the ✎ card)
				if _dirty:
					print("[prop-wall] leaving with UNSAVED rulings — F5 first if you meant to keep them")
				get_tree().change_scene_to_file("res://commons/scenes/vr_staging.tscn")
			KEY_E:
				_sel = EmEditor.pick(_cam, _records)
				for r in _records:
					_update_label(r)  # amber on the selected, parchment on the rest
				_update_hud()
			KEY_UP:
				_nudge(0.05)
			KEY_DOWN:
				_nudge(-0.05)
			KEY_R:
				if _sel >= 0:
					var r: Dictionary = _records[_sel]
					(r["node"] as Node3D).position.y = float(r["code_h"])
					_dirty = true
					_update_label(r)
					_update_hud()
			KEY_F5:
				_save()


func _nudge(dy: float) -> void:
	if _sel < 0:
		return
	var r: Dictionary = _records[_sel]
	if String(r.get("kind", "")) == "specimen":
		print("[prop-wall] %s is a %s specimen — its convention is WHERE it stands, no height rule (v1)"
			% [String(r["token"]), String(r.get("cls", "?"))])
		return
	var node: Node3D = r["node"]
	node.position.y = clampf(node.position.y + dy, 0.1, float(EmDetail.WALL_H) - 0.1)
	_dirty = true
	_update_label(r)
	if String(r.get("kind", "")) == "band":
		_refresh_band_stripe()
	_update_hud()


func _refresh_band_stripe() -> void:
	var lo: float = -1.0
	var hi: float = -1.0
	for r_v in _records:
		var r: Dictionary = r_v
		if String(r.get("key", "")) == "band_low":
			lo = (r["node"] as Node3D).position.y
		elif String(r.get("key", "")) == "band_high":
			hi = (r["node"] as Node3D).position.y
	if lo < 0.0 or hi <= lo:
		_band_stripe.visible = false
		return
	_band_stripe.visible = true
	_band_stripe.position = Vector3((_band_x0 + _band_x1) / 2.0, (lo + hi) / 2.0, 0.02)
	_band_stripe.scale = Vector3(_band_x1 - _band_x0, hi - lo, 0.02)


func _save() -> void:
	var rules: Dictionary = {}
	var band: Dictionary = {}
	for r_v in _records:
		var r: Dictionary = r_v
		if String(r.get("kind", "")) == "specimen":
			continue
		var h: float = (r["node"] as Node3D).position.y
		if absf(h - float(r["code_h"])) <= 0.001:
			continue
		if String(r.get("kind", "")) == "band":
			band[String(r["key"])] = snappedf(h, 0.001)
		else:
			rules[String(r["token"])] = {"h": snappedf(h, 0.001)}
	var doc: Dictionary = {
		"schema": "adaresearch.prop_wall_rules.v1",
		"_readme": ("Hand mounting heights over em_props' code conventions, written "
			+ "by the prop reference wall (prop_reference_wall.tscn). A token here "
			+ "mounts at h everywhere the museum dresses a wall; a token absent "
			+ "keeps its code height. Delete the file to restore every code "
			+ "convention. V1: one height per token — an exit_sign rule moves both "
			+ "the door and the portal sign."),
		"rules": rules,
	}
	var f := FileAccess.open(EmProps.RULES_PATH, FileAccess.WRITE)
	if f == null:
		print("[prop-wall] CANNOT WRITE %s" % EmProps.RULES_PATH)
		return
	f.store_string(JSON.stringify(doc, "\t"))
	f.close()
	# the standing conventions — read by em_plinths AND python's negotiator
	var bdoc: Dictionary = {
		"schema": "adaresearch.standing_rules.v1",
		"_readme": ("The hand's viewing band over em_plinths' code museology, "
			+ "written by the reference wall's band zone. Read by em_plinths.band() "
			+ "at build time and tools/spatial_contract.py plinth_band() at plan "
			+ "time — one file so the two languages cannot disagree. A key absent "
			+ "keeps the code constant; delete the file to restore all of them."),
		"band": band,
	}
	var bf := FileAccess.open(EmPlinths.STANDING_RULES, FileAccess.WRITE)
	if bf == null:
		print("[prop-wall] CANNOT WRITE %s" % EmPlinths.STANDING_RULES)
		return
	bf.store_string(JSON.stringify(bdoc, "\t"))
	bf.close()
	_dirty = false
	# the museum's next dress uses these immediately (static caches dropped)
	EmProps._hand_loaded = false
	EmProps._hand_rules = {}
	EmPlinths._band_loaded = false
	EmPlinths._band_hand = {}
	for r in _records:
		_update_label(r)
	_update_hud()
	print("[prop-wall] saved %d prop rule(s) + %d band rule(s)" % [rules.size(), band.size()])


func _update_label(r: Dictionary) -> void:
	var lbl: Label3D = r["label"]
	var selected: bool = _sel >= 0 and _sel < _records.size() and _records[_sel] == r
	if String(r.get("kind", "")) == "specimen":
		# specimens keep their class text; selection still burns amber
		lbl.modulate = Color(1.0, 0.62, 0.1) if selected else Color(0.75, 0.82, 0.9)
		lbl.font_size = 44 if selected else 32
		return
	var h: float = (r["node"] as Node3D).position.y
	var src: String = "code" if absf(h - float(r["code_h"])) <= 0.001 else "HAND"
	lbl.text = "%s\nh %.2f  (%s)" % [String(r["token"]), h, src]
	# the SELECTED prop's label burns amber; everyone else parchment
	lbl.modulate = Color(1.0, 0.62, 0.1) if selected else Color(0.95, 0.9, 0.75)
	lbl.font_size = 56 if selected else 40


func _update_hud() -> void:
	var line := "[PROP WALL]  E select · UP/DOWN nudge 5 cm · R reset · F5 save · F10 menu"
	if _sel >= 0 and _sel < _records.size():
		var r: Dictionary = _records[_sel]
		line += "\nselected: %s  h %.2f  (code %.2f)" % [
			String(r["token"]), (r["node"] as Node3D).position.y, float(r["code_h"])]
	if _dirty:
		line += "\n*unsaved*"
	_hud.text = line


func _make_hud() -> Label:
	var layer := CanvasLayer.new()
	var lbl := Label.new()
	lbl.position = Vector2(14, 14)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	layer.add_child(lbl)
	# the cursor — big enough to SEE against white plaster: a 14 px black
	# ring with a 8 px amber dot, dead centre. E selects what this covers.
	var ring := ColorRect.new()
	ring.set_anchors_preset(Control.PRESET_CENTER)
	ring.offset_left = -7
	ring.offset_top = -7
	ring.offset_right = 7
	ring.offset_bottom = 7
	ring.color = Color(0, 0, 0, 0.85)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ring)
	var dot := ColorRect.new()
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.offset_left = -4
	dot.offset_top = -4
	dot.offset_right = 4
	dot.offset_bottom = 4
	dot.color = Color(1.0, 0.85, 0.3)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dot)
	add_child(layer)
	return lbl


## The specimen classes, read from em_props' own CATALOGUE so the corridor's
## token list is the code's, never a copy. C_WALL is the ruled wall above;
## C_EXHIBIT belongs to the museum's dealing, not the corridor.
func _specimen_tokens() -> Dictionary:
	var out: Dictionary = {"ceiling": [], "aperture": [], "floor": [], "tabletop": [], "edge": []}
	var already: Dictionary = EmProps.mount_defaults()
	for token in EmProps.CATALOGUE:
		if already.has(String(token)):
			continue
		match String((EmProps.CATALOGUE[token] as Dictionary).get("class", "")):
			"ceiling": (out["ceiling"] as Array).append(String(token))
			"aperture": (out["aperture"] as Array).append(String(token))
			"floor": (out["floor"] as Array).append(String(token))
			"tabletop": (out["tabletop"] as Array).append(String(token))
			"edge": (out["edge"] as Array).append(String(token))
	for cls in out:
		(out[cls] as Array).sort()
	return out


## One specimen: the scene (or a placeholder) at its class's situation, a
## label naming token + class, and an E-inspectable but rule-less record.
func _specimen(token: String, cls: String, at: Vector3, scenes: Dictionary, wall_h: float) -> void:
	var holder := Node3D.new()
	holder.name = token
	holder.position = at
	add_child(holder)
	var path: String = String(scenes.get(token, ""))
	if path != "" and ResourceLoader.exists(path):
		var inst: Node3D = (load(path) as PackedScene).instantiate() as Node3D
		holder.add_child(inst)
	else:
		var ph := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.4, 0.4, 0.4)
		ph.mesh = bm
		ph.position = Vector3(0, 0.2, 0)
		holder.add_child(ph)
	var lbl := Label3D.new()
	lbl.position = Vector3(at.x, wall_h - 0.25 - (int(at.x / SPACING) % 2) * 0.35, 0.15)
	lbl.font_size = 32
	lbl.modulate = Color(0.75, 0.82, 0.9)
	lbl.text = "%s\n(%s)" % [token, cls]
	add_child(lbl)
	_records.append({"node": holder, "token": token, "label": lbl,
		"code_h": at.y, "kind": "specimen", "cls": cls})


## token -> scene path, read from the artifact registries (token-keyed dicts).
func _resolve_scenes(tokens: Array) -> Dictionary:
	var want: Dictionary = {}
	for t in tokens:
		want[String(t)] = true
	var out: Dictionary = {}
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return out
	for fname in dir.get_files():
		if not fname.ends_with(".json") or fname.ends_with(".bak"):
			continue
		var doc: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(REGISTRY_DIR + "/" + fname))
		if not (doc is Dictionary):
			continue
		# registries come in two shapes: token-keyed at the top, or nested one
		# level under a category key — take scenes from both
		_harvest(doc, want, out)
		for key in (doc as Dictionary):
			var v: Variant = (doc as Dictionary)[key]
			if v is Dictionary and not (v as Dictionary).has("scene"):
				_harvest(v, want, out)
	return out


static func _harvest(d: Variant, want: Dictionary, out: Dictionary) -> void:
	for key in (d as Dictionary):
		if want.has(String(key)) and not out.has(String(key)):
			var e: Variant = (d as Dictionary)[key]
			if e is Dictionary and (e as Dictionary).has("scene"):
				out[String(key)] = String((e as Dictionary)["scene"])


func _slab(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	mi.material_override = m
	mi.position = pos
	add_child(mi)


func _figure(at: Vector3) -> void:
	var fig := Node3D.new()
	fig.position = at
	add_child(fig)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.58, 0.57, 0.55)
	for s in [[Vector3(-0.09, 0.47, 0), 0.07, 0.94], [Vector3(0.09, 0.47, 0), 0.07, 0.94],
			[Vector3(0, 1.17, 0), 0.14, 0.72],
			[Vector3(-0.23, 1.13, 0), 0.05, 0.62], [Vector3(0.23, 1.13, 0), 0.05, 0.62]]:
		var cap := CapsuleMesh.new()
		cap.radius = float((s as Array)[1])
		cap.height = float((s as Array)[2])
		var mi := MeshInstance3D.new()
		mi.mesh = cap
		mi.material_override = m
		mi.position = (s as Array)[0]
		fig.add_child(mi)
	var head := SphereMesh.new()
	head.radius = 0.105
	head.height = 0.21
	var hm := MeshInstance3D.new()
	hm.mesh = head
	hm.material_override = m
	hm.position = Vector3(0, 1.64, 0)
	fig.add_child(hm)

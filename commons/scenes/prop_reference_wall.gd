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

const SPACING := 3.0
const REGISTRY_DIR := "res://commons/artifacts/registry"

var _cam: Camera3D
var _yaw: float = 0.0
var _pitch: float = 0.0
var _records: Array = []   # [{node, token, label, code_h}]
var _sel: int = -1
var _dirty: bool = false
var _hud: Label


func _ready() -> void:
	var wall_h: float = float(EmDetail.WALL_H)
	var defaults: Dictionary = EmProps.mount_defaults()
	var n: int = defaults.size()
	var length: float = SPACING * (n + 1)

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

	_figure(Vector3(SPACING * (n + 1) - 1.0, 0.0, 1.2))

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
			KEY_E:
				_sel = EmEditor.pick(_cam, _records)
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
	var node: Node3D = r["node"]
	node.position.y = clampf(node.position.y + dy, 0.1, float(EmDetail.WALL_H) - 0.1)
	_dirty = true
	_update_label(r)
	_update_hud()


func _save() -> void:
	var rules: Dictionary = {}
	for r_v in _records:
		var r: Dictionary = r_v
		var h: float = (r["node"] as Node3D).position.y
		if absf(h - float(r["code_h"])) > 0.001:
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
	_dirty = false
	# the museum's next dress uses these immediately (static cache dropped)
	EmProps._hand_loaded = false
	EmProps._hand_rules = {}
	for r in _records:
		_update_label(r)
	_update_hud()
	print("[prop-wall] saved %d hand rule(s) -> %s" % [rules.size(), EmProps.RULES_PATH])


func _update_label(r: Dictionary) -> void:
	var h: float = (r["node"] as Node3D).position.y
	var src: String = "code" if absf(h - float(r["code_h"])) <= 0.001 else "HAND"
	(r["label"] as Label3D).text = "%s\nh %.2f  (%s)" % [String(r["token"]), h, src]


func _update_hud() -> void:
	var line := "[PROP WALL]  E select · UP/DOWN nudge 5 cm · R reset · F5 save"
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
	add_child(layer)
	return lbl


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

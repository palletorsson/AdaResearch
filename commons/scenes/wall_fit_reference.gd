extends Node3D
## THE WALL FIT REFERENCE — the prop_reference_wall principle, for ARTIFACTS.
##
## Palle, 2026-08-20: "we need to find out how we can place things at the walls
## in the right way — does it fit the wall, can we scale to fit, does it need a
## shelf, and some nice distance to the wall?"
##
## Bays of real wall widths (0.8 / 1.2 / 1.8 / 2.6 / 4.0 m) each hang the same
## specimens the way the museum would: EmWallFit decides fit / scale-to-fit /
## shelf / stand-off, and the label under each names the decision — so a small
## wall's behaviour is a thing you can WALK PAST and judge. The 1.75 m figure
## stands at the end so every height reads against a body.
##
##   Run:  godot --path . res://commons/scenes/wall_fit_reference.tscn
##   Keys: WASD + mouse look · E cycle selection · LEFT/RIGHT stand-off 1 cm ·
##         UP/DOWN scale_min 0.05 · X toggle shelf · F5 save · ESC mouse
##
## EDITING writes commons/data/wall_fit_rules.json (per-token overrides) — the
## SAME file tools/spatial_negotiation.wall_fit_decide and the museum consult,
## so a nudge here IS the museum convention, exactly as prop_reference_wall
## nudges are the prop heights.

const EmWallFit := preload("res://commons/scenes/em/em_wall_fit.gd")
const BAYS := [0.8, 1.2, 1.8, 2.6, 4.0]
const WALL_H := 4.0
const SPECIMENS := [
	"godel_statement_plaque", "dgrid", "homogeneous_coordinates",
	"science_screen", "info_board", "perspective_lines", "shannon_entropy_meter",
]

var _cam: Camera3D
var _yaw := PI
var _pitch := 0.0
var _records: Array = []
var _sel := -1
var _hud: Label


func _ready() -> void:
	var x := 1.0
	var reg := _registry()
	for bi in range(BAYS.size()):
		var bw: float = BAYS[bi]
		var tok: String = SPECIMENS[bi % SPECIMENS.size()]
		# each bay also shows every specimen at a running x below; the primary
		# grid is bay-major so the SAME body can be compared across widths
		for si in range(SPECIMENS.size()):
			var tok2: String = SPECIMENS[si]
			var meta: Dictionary = reg.get(tok2, {})
			var body: Vector3 = meta.get("body", Vector3(0.8, 0.1, 0.8))
			var fit: Dictionary = EmWallFit.decide(tok2, body, bw, WALL_H)
			var cx := x + bw / 2.0
			_slab(Vector3(cx, WALL_H / 2.0, float(si) * 6.0), Vector3(bw - 0.06, WALL_H, 0.2), Color(0.86, 0.855, 0.845))
			_slab(Vector3(cx, -0.1, float(si) * 6.0 + 2.0), Vector3(bw + 0.3, 0.2, 4.0), Color(0.16, 0.16, 0.19))
			var verdict := String(fit["mode"])
			if verdict != "refuse" and String(meta.get("scene", "")) != "" and ResourceLoader.exists(String(meta["scene"])):
				var inst: Node3D = (load(String(meta["scene"])) as PackedScene).instantiate() as Node3D
				inst.position = Vector3(cx, float(fit["v_centre"]), float(si) * 6.0 + 0.12 + float(fit["standoff"]))
				inst.scale = Vector3.ONE * float(fit["scale"])
				add_child(inst)
				if bool(fit["shelf"]):
					var sh: MeshInstance3D = EmWallFit.make_shelf(body.x * float(fit["scale"]), body.y)
					sh.position = Vector3(cx, maxf(0.35, float(fit["v_centre"]) - body.z * float(fit["scale"]) / 2.0 - 0.05), float(si) * 6.0 + 0.12 + body.y / 2.0)
					add_child(sh)
			var lbl := Label3D.new()
			var line := "%s · %.1f m bay\n%s" % [tok2, bw, verdict]
			if verdict == "scale":
				line += " x%.2f" % float(fit["scale"])
			if bool(fit["shelf"]):
				line += " + shelf"
			line += " · off %.0f cm" % (float(fit["standoff"]) * 100.0)
			lbl.text = line
			lbl.font_size = 24
			lbl.pixel_size = 0.0015
			lbl.modulate = Color(0.22, 0.2, 0.19)
			lbl.position = Vector3(cx, 0.4, float(si) * 6.0 + 0.5)
			add_child(lbl)
			_records.append({"token": tok2, "bay": bw})
		x += bw + 0.6
	# the figure: 1.75 m read against every height
	var fig := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.height = 1.75
	cm.radius = 0.22
	fig.mesh = cm
	fig.position = Vector3(x + 0.6, 0.875, 2.0)
	add_child(fig)
	_cam = Camera3D.new()
	_cam.position = Vector3(3.0, 1.65, 6.0)
	add_child(_cam)
	_cam.make_current()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.9, 0.89, 0.87)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.environment = e
	add_child(env)
	var cl := CanvasLayer.new()
	_hud = Label.new()
	_hud.text = "WALL FIT REFERENCE — E select · LEFT/RIGHT stand-off · UP/DOWN scale_min · X shelf · F5 save"
	_hud.position = Vector2(12, 12)
	cl.add_child(_hud)
	add_child(cl)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _registry() -> Dictionary:
	var out: Dictionary = {}
	var dir := DirAccess.open("res://commons/artifacts/registry")
	if dir == null:
		return out
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/registry/" + f))
		if not (v is Dictionary):
			continue
		var arts_v: Variant = (v as Dictionary).get("artifacts", v)
		var arts: Dictionary = arts_v if arts_v is Dictionary else v
		for tok in SPECIMENS:
			if out.has(tok) or not arts.has(tok):
				continue
			var e: Dictionary = arts[tok]
			var b := Vector3(0.8, 0.1, 0.8)
			var meas_v: Variant = e.get("measurements", {})
			if meas_v is Dictionary:
				var bm_v: Variant = (meas_v as Dictionary).get("body_m")
				if bm_v is Array and (bm_v as Array).size() >= 3:
					b = Vector3(float(bm_v[0]), float(bm_v[1]), float(bm_v[2]))
			out[tok] = {"scene": String(e.get("scene_path", e.get("scene", ""))), "body": b}
	return out


func _slab(pos: Vector3, size: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	mi.material_override = m
	mi.position = pos
	add_child(mi)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= (event as InputEventMouseMotion).relative.x * 0.003
		_pitch = clampf(_pitch - (event as InputEventMouseMotion).relative.y * 0.003, -1.2, 1.2)
		_cam.rotation = Vector3(_pitch, _yaw, 0)
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		match (event as InputEventKey).keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
			KEY_E:
				_sel = (_sel + 1) % _records.size()
				_hud.text = "selected: %s (%.1f m bay) — LEFT/RIGHT stand-off · UP/DOWN scale_min · X shelf · F5 save" % [
					String(_records[_sel]["token"]), float(_records[_sel]["bay"])]
			KEY_F5:
				_save_rules()
			KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_X:
				if _sel >= 0:
					_nudge((event as InputEventKey).keycode)


func _nudge(code: int) -> void:
	var tok := String(_records[_sel]["token"])
	var rules: Dictionary = EmWallFit.rules()
	var toks: Dictionary = rules.get("tokens", {})
	var r: Dictionary = toks.get(tok, {})
	var defaults: Dictionary = rules.get("defaults", {})
	match code:
		KEY_LEFT:
			r["standoff_shallow_m"] = maxf(0.0, float(r.get("standoff_shallow_m", defaults.get("standoff_shallow_m", 0.035))) - 0.01)
		KEY_RIGHT:
			r["standoff_shallow_m"] = float(r.get("standoff_shallow_m", defaults.get("standoff_shallow_m", 0.035))) + 0.01
		KEY_UP:
			r["scale_min"] = minf(1.0, float(r.get("scale_min", defaults.get("scale_min", 0.55))) + 0.05)
		KEY_DOWN:
			r["scale_min"] = maxf(0.2, float(r.get("scale_min", defaults.get("scale_min", 0.55))) - 0.05)
		KEY_X:
			r["shelf"] = not bool(r.get("shelf", false))
	toks[tok] = r
	rules["tokens"] = toks
	_hud.text = "%s override: %s   (F5 saves; restart to re-hang)" % [tok, JSON.stringify(r)]


func _save_rules() -> void:
	var f := FileAccess.open(EmWallFit.RULES_PATH, FileAccess.WRITE)
	if f == null:
		_hud.text = "cannot write the rules (exported build?)"
		return
	f.store_string(JSON.stringify(EmWallFit.rules(), " "))
	f.close()
	_hud.text = "saved -> %s — this IS the museum convention now" % EmWallFit.RULES_PATH


func _process(delta: float) -> void:
	if _cam == null:
		return
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		dir -= _cam.global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		dir += _cam.global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		dir -= _cam.global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		dir += _cam.global_transform.basis.x
	dir.y = 0.0
	if dir.length() > 0.1:
		_cam.position += dir.normalized() * 5.0 * delta

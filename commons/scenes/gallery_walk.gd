extends Node3D

## Walk the negotiated gallery — the composed room, on your own feet.
##
## Everything the spatial pass produced, standing up and playable: a certified
## kit wall run, a DNA lineage hung in the declared feature band, signage in the
## upper band, the anchor on the plinth em_plinths chose for it, a caption from
## the registry, and a portal onto a precinct work out on open ground.
##
## The walker is the Endless Museum's, not a second one: CharacterBody3D with a
## 0.32 m capsule, camera at EYE with KEEP_WIDTH so the FOV number means what it
## says (endless_museum.gd:_setup_world explains why that matters), WASD and
## captured-mouse look, move_and_slide so the walls push back.
##
##   godot --path . --xr-mode off res://commons/scenes/gallery_walk.tscn -- \
##     --artifact=you_are_here --precinct=neural_network_visualization
##
## W A S D walk · Shift run · mouse look · Esc release the cursor · Tab overlay

const PLINTHS := preload("res://commons/scenes/em/em_plinths.gd")
const WALL_PIECE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const TextScreenRes = preload("res://commons/ui/text_screen.gd")
const REGISTRY_DIR := "res://commons/artifacts/registry"
const CONTRACT_PILOT := "res://commons/data/museum_contract_pilot.json"
const RELATIONS := "res://commons/data/artifact_relations.json"

const EYE := 1.65
const WALK_SPEED := 4.0

@export var artifact: String = "you_are_here"
@export var precinct: String = "neural_network_visualization"
@export var map_name: String = "Point_One"
## --shot=<user://path.png>: prove the room stands up without a person in it.
## A walkable scene that has only ever been launched interactively is a scene
## nobody has checked.
var _shot: String = ""

var _feature_h := [0.20, 0.80]
var _feature_v := [1.1, 2.3]
var _upper_v := [2.3, 4.0]
var _values: Array = []
var _run_w: float = 5.0

var _player: CharacterBody3D
var _cam: Camera3D
var _yaw := 0.0
var _pitch := 0.0
var _hud: Label


func _ready() -> void:
	_parse_args()
	_load_bands()
	_build_room()
	await get_tree().process_frame
	_build_walker()
	_build_hud()
	if _shot != "":
		await _take_shot()
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _take_shot() -> void:
	# Two frames then a settle, NOT RenderingServer.frame_post_draw — that
	# signal never fires under --no-window and the run hangs until something
	# kills it.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1.4).timeout
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_shot.get_base_dir()))
	img.save_png(_shot)
	print("[gallery_walk] standing at %s looking into the room -> %s"
		% [_player.position if _player else Vector3.ZERO, _shot])
	get_tree().quit(0)


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw)
		if a.begins_with("--artifact="):
			artifact = a.substr(11)
		elif a.begins_with("--precinct="):
			precinct = a.substr(11)
		elif a.begins_with("--map="):
			map_name = a.substr(6)
		elif a.begins_with("--shot="):
			_shot = a.substr(7)


# ── declared numbers, read not copied ───────────────────────────────

func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _load_bands() -> void:
	var ws = _json(CONTRACT_PILOT).get("wall_system", {})
	if not (ws is Dictionary):
		return
	var ff = (ws as Dictionary).get("feature_field", {})
	if ff is Dictionary:
		var h = (ff as Dictionary).get("horizontal_percent", [])
		var v = (ff as Dictionary).get("vertical_m", [])
		if h is Array and (h as Array).size() == 2:
			_feature_h = [float(h[0]) / 100.0, float(h[1]) / 100.0]
		if v is Array and (v as Array).size() == 2:
			_feature_v = [float(v[0]), float(v[1])]
	var up = (ws as Dictionary).get("upper_band_m", [])
	if up is Array and (up as Array).size() == 2:
		_upper_v = [float(up[0]), float(up[1])]


func _entry(token: String) -> Dictionary:
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return {}
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var d := _json("%s/%s" % [REGISTRY_DIR, f])
		var arts = d.get("artifacts", {})
		if arts is Dictionary and (arts as Dictionary).has(token):
			return (arts as Dictionary)[token]
	return {}


func _dna_values(token: String) -> Array:
	var rec = (_json(RELATIONS).get("artifacts", {}) as Dictionary).get(token, {})
	var axes = (rec as Dictionary).get("axes", {}) if rec is Dictionary else {}
	var best: Array = []
	for axis in (axes as Dictionary):
		var vals: Array = (axes as Dictionary)[axis]
		if vals.size() > best.size():
			best = vals
	return best


# ── the room ────────────────────────────────────────────────────────

func _mat(c: Color, rough := 0.7, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


## A box you can also walk into. The probe drew geometry only; a walker needs
## the wall to push back, so every surface here carries a static body.
func _solid(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)


func _build_room() -> void:
	_values = _dna_values(artifact)
	var spec: Array = [["service", 1]]
	for _v in _values:
		spec.append(["feature", 1])
	if precinct != "":
		spec.append(["portal", 2])
	spec.append(["service", 1])

	_run_w = 0.0
	for s in spec:
		_run_w += float(s[1])
	var x := -_run_w / 2.0
	for s in spec:
		var piece := WALL_PIECE.instantiate() as Node3D
		piece.set("kind", String(s[0]))
		piece.set("width_cells", int(s[1]))
		piece.set("height", 4.0)
		piece.set("quality_tier", "aaa")
		piece.set("enable_collision", true)
		piece.position = Vector3(x + float(s[1]) / 2.0, 0.0, 0.0)
		add_child(piece)
		x += float(s[1])

	_solid(Vector3(0, -0.05, 4.0), Vector3(_run_w + 8.0, 0.1, 16.0),
		_mat(Color(0.10, 0.10, 0.12), 0.18, 0.25))
	var stone := _mat(Color(0.78, 0.76, 0.71), 0.85)
	_solid(Vector3(-_run_w / 2.0 - 0.5, 2.0, 5.0), Vector3(0.3, 4.0, 10.0), stone)
	_solid(Vector3(_run_w / 2.0 + 0.5, 2.0, 5.0), Vector3(0.3, 4.0, 10.0), stone)
	_solid(Vector3(0, 2.0, 10.2), Vector3(_run_w + 1.6, 4.0, 0.3), stone)
	_solid(Vector3(0, 4.15, 5.0), Vector3(_run_w + 1.6, 0.3, 10.6), stone)

	_hang_lineage()
	_stand_anchor()
	_stand_precinct()
	_light()


func _hang_lineage() -> void:
	if _values.is_empty():
		return
	var first_x := -_run_w / 2.0 + 1.0
	var v_centre: float = (_feature_v[0] + _feature_v[1]) / 2.0
	var field_w: float = 1.0 * (_feature_h[1] - _feature_h[0])
	for i in range(_values.size()):
		var work := TextScreenRes.new()
		work.mode = TextScreenRes.Mode.SCREEN
		work.title = String(_values[i]).replace("_", " ").to_upper()
		work.width_m = field_w
		work.position = Vector3(first_x + float(i) + 0.5, v_centre, 0.14)
		add_child(work)

	var sign := TextScreenRes.new()
	sign.mode = TextScreenRes.Mode.SCREEN
	sign.title = map_name.replace("_", " ").to_upper()
	sign.width_m = 1.4
	sign.position = Vector3(_run_w * 0.5 - 2.6, _upper_v[0] + 0.45, 0.14)
	add_child(sign)


func _stand_anchor() -> void:
	var e := _entry(artifact)
	var scene_path := String(e.get("scene", ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return
	var node := (load(scene_path) as PackedScene).instantiate() as Node3D
	add_child(node)
	await get_tree().create_timer(0.4).timeout
	var m: Dictionary = PLINTHS.measure(node)
	var plan: Dictionary = PLINTHS.plan_measured(
		artifact, {}, float(m.get("height_m", 0.0)),
		float(m.get("base_m", 0.0)), float(m.get("thin_m", 0.0)))
	var lift := float(plan.get("artifact_y", 0.0))
	var pscene := String(plan.get("scene", ""))
	if pscene != "" and ResourceLoader.exists(pscene):
		var plinth := (load(pscene) as PackedScene).instantiate() as Node3D
		for k in (plan.get("config", {}) as Dictionary):
			plinth.set_meta("config_%s" % str(k), (plan["config"] as Dictionary)[k])
		plinth.position = Vector3(0.0, 0.0, 2.1)
		add_child(plinth)
	node.position = Vector3(0.0, lift, 2.1)

	var caption := TextScreenRes.new()
	caption.title = String(e.get("name", artifact)).to_upper()
	caption.body = String(e.get("description", ""))
	caption.width_m = 0.44
	caption.position = Vector3(1.4, 1.15, 2.1)
	add_child(caption)


func _stand_precinct() -> void:
	if precinct == "":
		return
	var e := _entry(precinct)
	var scene_path := String(e.get("scene", ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return
	var node := (load(scene_path) as PackedScene).instantiate() as Node3D
	add_child(node)
	node.position = Vector3(_run_w / 2.0 - 1.0, 0.0, -8.0)
	_solid(Vector3(_run_w / 2.0 - 1.0, -0.06, -10.0), Vector3(26.0, 0.1, 24.0),
		_mat(Color(0.20, 0.21, 0.19), 0.95))


func _light() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.05, 0.07)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.32, 0.32, 0.36)
	e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)

	for spot in [[Vector3(0, 3.6, 3.2), Vector3(0, 1.6, 0.4), 6.0],
				 [Vector3(-2.4, 3.4, 2.4), Vector3(-1.2, 1.4, 0.2), 2.4],
				 [Vector3(_run_w * 0.5 - 2.6, 3.9, 1.4), Vector3(_run_w * 0.5 - 2.6, 2.8, 0.1), 2.6]]:
		var l := SpotLight3D.new()
		l.position = spot[0]
		l.look_at_from_position(spot[0], spot[1], Vector3.UP)
		l.light_energy = float(spot[2])
		l.spot_range = 14.0
		l.spot_angle = 40.0
		l.shadow_enabled = true
		add_child(l)

	var sky := DirectionalLight3D.new()
	sky.rotation_degrees = Vector3(-42, 155, 0)
	sky.light_energy = 1.0
	sky.light_color = Color(0.86, 0.90, 1.0)
	sky.shadow_enabled = true
	add_child(sky)


# ── the walker, as the Endless Museum builds it ─────────────────────

func _build_walker() -> void:
	_player = CharacterBody3D.new()
	_player.name = "Walker"
	_player.position = Vector3(-1.5, 0.0, 6.0)
	# Face the wall run at z=0. endless_museum uses PI because its segments
	# extend along +z; this room is the other way round, and copying its yaw
	# pointed the walker at the back wall — the scene ran, and showed nothing.
	_yaw = 0.0
	_player.rotation = Vector3(0.0, _yaw, 0.0)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.5
	col.shape = cap
	col.position = Vector3(0, 0.95, 0)
	_player.add_child(col)
	add_child(_player)

	_cam = Camera3D.new()
	_cam.position = Vector3(0, EYE, 0)
	# KEEP_WIDTH so the FOV number means what it says across the frame, not
	# vertically — the fisheye endless_museum.gd calls out at :_setup_world.
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.fov = 75.0
	_player.add_child(_cam)
	_cam.make_current()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(18, 14)
	_hud.add_theme_color_override("font_color", Color(0.86, 0.88, 0.94))
	_hud.add_theme_font_size_override("font_size", 15)
	layer.add_child(_hud)
	_refresh_hud()


func _refresh_hud() -> void:
	if _hud == null:
		return
	_hud.text = ("%s  -  lineage of %d in the feature band %.1f-%.1f m\n"
		+ "signage in the upper band %.1f-%.1f m  -  precinct beyond the portal: %s\n"
		+ "W A S D walk   Shift run   mouse look   Esc cursor") % [
			artifact, _values.size(), _feature_v[0], _feature_v[1],
			_upper_v[0], _upper_v[1], precinct if precinct != "" else "none"]


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = (Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * 0.0025
		_pitch = clampf(_pitch - event.relative.y * 0.0025, -1.35, 1.35)
		if _player:
			_player.rotation = Vector3(0.0, _yaw, 0.0)
		if _cam:
			_cam.rotation = Vector3(_pitch, 0.0, 0.0)


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		dir -= _player.global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		dir += _player.global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		dir -= _player.global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		dir += _player.global_transform.basis.x
	dir.y = 0.0
	var speed := WALK_SPEED * (2.2 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	_player.velocity = (dir.normalized() * speed) if dir.length() > 0.01 else Vector3.ZERO
	# The deck is flat by construction, so y is clamped rather than simulated —
	# the same call endless_museum.gd makes, and for the same reason.
	_player.move_and_slide()
	_player.position.y = 0.0

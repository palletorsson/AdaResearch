extends Node3D
# endless_museum.gd — the endless museum corridor (fast loop, v1).
#
# Streams museum-template segments ahead of the walker: each segment stamps one
# principal template extracted from a real floor plan (commons/data/
# template_patterns.json, museum-tagged entries) and fills its slots from the
# artifact registries in seeded order. Walk forward (+z) and the next museum
# opens; segments three behind are freed. Valid by construction — no pathfinder
# at runtime; the templates were validated at extraction (entry-to-exit path,
# stop pocket per slot).
#
# Standalone and additive: no GridSystem, no shipped map touched.
#   Walk:  godot --path . res://commons/scenes/endless_museum.tscn -- --em-seed=46
#   Proof: ... -- --em-shot=user://em_proof.png --em-segments=3 (build, shoot, quit)
#
# Debt (v1): banner uses Label3D (canon is TextScreen); no collision walls —
# the camera glides at eye height inside the corridor bounds.

const TEMPLATES := "res://commons/data/template_patterns.json"
const REGISTRY_DIR := "res://commons/artifacts/registry"
const EYE := 1.65
const WALK_SPEED := 4.0
const BUILD_AHEAD_M := 24.0
const KEEP_BEHIND_M := 70.0
const MAX_ARTIFACTS_PER_SEGMENT := 8

var _museums: Array = []          # [{key,label,museum,w,h,tile,walk_rule}]
var _pool: Array = []             # [{lookup, scene}]
var _pool_i: int = 0
var _seed: int = 46
var _shot_path: String = ""
var _shot_segments: int = 3
var _segments: Array = []         # [{node, z0, z1, index}]
var _next_z: float = 0.0
var _seg_index: int = 0
var _cam: Camera3D
var _yaw: float = 0.0
var _pitch: float = 0.0

func _ready() -> void:
	_parse_args()
	_load_museums()
	_load_pool()
	if _museums.is_empty():
		push_error("endless_museum: no museum-tagged templates in %s" % TEMPLATES)
		return
	_setup_world()
	var preload_n: int = _shot_segments if _shot_path != "" else 2
	for i in range(preload_n):
		_build_segment()
	if _shot_path != "":
		_take_proof_shot()

func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	for a in args:
		if a.begins_with("--em-seed="):
			_seed = int(a.substr(10))
		elif a.begins_with("--em-shot="):
			_shot_path = a.substr(10)
		elif a.begins_with("--em-segments="):
			_shot_segments = int(a.substr(14))

func _load_museums() -> void:
	var f := FileAccess.open(TEMPLATES, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		return
	var patterns: Dictionary = data.get("patterns", {})
	for key in patterns:
		var p: Dictionary = patterns[key]
		if p.has("museum"):  # only the extracted museum templates
			_museums.append({"key": key, "label": p.get("label", key),
				"museum": p.get("museum", ""), "w": int(p.get("w", 15)),
				"h": int(p.get("h", 30)), "tile": p.get("tile", []),
				"walk_rule": p.get("walk_rule", "")})
	_museums.sort_custom(func(a, b): return String(a["key"]) < String(b["key"]))

func _load_pool() -> void:
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		return
	for fname in dir.get_files():
		if not fname.ends_with(".json"):
			continue
		var f := FileAccess.open(REGISTRY_DIR + "/" + fname, FileAccess.READ)
		if f == null:
			continue
		var data: Variant = JSON.parse_string(f.get_as_text())
		if not (data is Dictionary):
			continue
		var arts: Dictionary = data.get("artifacts", {})
		for lookup in arts:
			var a: Dictionary = arts[lookup]
			var scene: String = String(a.get("scene", ""))
			if scene != "" and a.get("map_ready", false) and ResourceLoader.exists(scene):
				_pool.append({"lookup": lookup, "scene": scene})
	_pool.sort_custom(func(a, b): return String(a["lookup"]) < String(b["lookup"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for i in range(_pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = _pool[i]
		_pool[i] = _pool[j]
		_pool[j] = tmp

func _setup_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = Sky.new()
	e.sky.sky_material = ProceduralSkyMaterial.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 1.2
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	_cam = Camera3D.new()
	_cam.position = Vector3(7.5, EYE, 1.5)
	_cam.fov = 90.0
	_yaw = PI  # segments extend along +z; face into the museum
	_cam.rotation = Vector3(0.0, _yaw, 0.0)
	add_child(_cam)
	_cam.make_current()

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	mi.position = pos
	parent.add_child(mi)

func _build_segment() -> void:
	var spec: Dictionary = _museums[_seg_index % _museums.size()]
	var w: int = spec["w"]
	var h: int = spec["h"]
	var tile: Array = spec["tile"]
	var seg := Node3D.new()
	seg.name = "Seg%d_%s" % [_seg_index, spec["key"]]
	seg.position = Vector3(0, 0, _next_z)
	add_child(seg)
	# collect slots first so the artifact budget prefers hero > podium > floor
	var slots: Array = []
	for y in range(tile.size()):
		var row: Array = tile[y]
		for x in range(row.size()):
			var c := String(row[x])
			match c:
				"1", "1s":
					_box(seg, Vector3(x + 0.5, -0.1, y + 0.5), Vector3(1, 0.2, 1), Color(0.16, 0.16, 0.19))
				"2", "2s":
					_box(seg, Vector3(x + 0.5, 0.1, y + 0.5), Vector3(1, 0.6, 1), Color(0.23, 0.23, 0.28))
				"3s":
					_box(seg, Vector3(x + 0.5, 0.3, y + 0.5), Vector3(1, 1.0, 1), Color(0.35, 0.27, 0.16))
				"4":
					_box(seg, Vector3(x + 0.5, 1.5, y + 0.5), Vector3(1, 3.0, 1), Color(0.32, 0.32, 0.36))
			if c == "1s":
				slots.append({"x": x, "y": y, "top": 0.0, "rank": 2})
			elif c == "2s":
				slots.append({"x": x, "y": y, "top": 0.4, "rank": 1})
			elif c == "3s":
				slots.append({"x": x, "y": y, "top": 0.8, "rank": 0})
	slots.sort_custom(func(a, b): return int(a["rank"]) < int(b["rank"]))
	var placed := 0
	for s in slots:
		if placed >= MAX_ARTIFACTS_PER_SEGMENT or _pool.is_empty():
			break
		var entry: Dictionary = _pool[_pool_i % _pool.size()]
		_pool_i += 1
		var ps: PackedScene = load(String(entry["scene"])) as PackedScene
		if ps == null:
			continue
		var node: Node3D = ps.instantiate() as Node3D
		if node == null:
			continue
		node.set_meta("artifact_lookup_name", entry["lookup"])
		node.position = Vector3(float(s["x"]) + 0.5, float(s["top"]), float(s["y"]) + 0.5)
		seg.add_child(node)
		placed += 1
	# museum banner at the threshold (v1 debt: Label3D, canon is TextScreen)
	var banner := Label3D.new()
	banner.text = "%s\n%s" % [spec["label"], spec["museum"]]
	banner.font_size = 96
	banner.pixel_size = 0.01
	banner.modulate = Color(0.88, 0.71, 0.36)
	banner.position = Vector3(w / 2.0, 2.6, 0.4)
	banner.rotation_degrees = Vector3(0, 180, 0)
	seg.add_child(banner)
	_segments.append({"node": seg, "z0": _next_z, "z1": _next_z + float(h), "index": _seg_index})
	_next_z += float(h)
	_seg_index += 1
	print("[endless_museum] seg %d = %s (%s) placed %d artifacts, z %.0f..%.0f" % [
		_seg_index - 1, spec["key"], spec["museum"], placed, _segments[-1]["z0"], _segments[-1]["z1"]])

func _process(delta: float) -> void:
	if _cam == null or _shot_path != "":
		return
	# stream: open the next museum as the walker nears the built edge
	if _cam.position.z > _next_z - BUILD_AHEAD_M:
		_build_segment()
	# free far-behind segments (keep the museum endless, not the node tree)
	while _segments.size() > 2 and float(_segments[0]["z1"]) < _cam.position.z - KEEP_BEHIND_M:
		var old: Dictionary = _segments.pop_front()
		var n: Node3D = old["node"]
		n.queue_free()
	# walk
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
	if dir.length() > 0.01:
		var speed := WALK_SPEED * (2.5 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
		_cam.position += dir.normalized() * speed * delta
	_cam.position.y = EYE

func _input(event: InputEvent) -> void:
	if _shot_path != "":
		return
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * 0.002
		_pitch = clampf(_pitch - event.relative.y * 0.002, -1.2, 1.2)
		_cam.rotation = Vector3(_pitch, _yaw, 0.0)

func _take_proof_shot() -> void:
	# stand at the first segment's entry, look down the corridor, settle, save
	var spec: Dictionary = _museums[0]
	_cam.position = Vector3(float(spec["w"]) / 2.0, EYE, 1.0)
	_cam.rotation = Vector3(-0.05, PI, 0.0)  # scene +z runs away from entry; camera looks along it
	_shoot_deferred()

func _shoot_deferred() -> void:
	var frames := 90
	var t := get_tree()
	var counter := {"n": 0}
	var cb: Callable
	cb = func() -> void:
		counter["n"] += 1
		if counter["n"] >= frames:
			t.process_frame.disconnect(cb)
			var img := get_viewport().get_texture().get_image()
			img.save_png(_shot_path)
			print("[endless_museum] proof shot -> %s" % _shot_path)
			t.quit()
	t.process_frame.connect(cb)

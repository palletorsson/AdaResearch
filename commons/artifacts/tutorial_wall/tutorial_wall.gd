extends Node3D
class_name TutorialWall

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the WALL-HANGAR PRINCIPAL of the tutorial layer — a station-kit wall that reads a map's OWN tutorial.md and blurb.md at build time and hangs them as framed 2D-in-3D boards (TITLE / THE IDEA / THE CODE / TRY), with the map's real example artifacts mounted on daises in front. One artifact, any map: config {map: <MapName>} re-skins it to that map's lesson.
# desire: to make the code tutorial inhabit the room it teaches — not a doc you read elsewhere but a wall you stand at, with the worked example three steps away on a plinth.
# critical_parameter: map — which map's docs to read; example_count — how many cast artifacts to mount as live examples.
# triggers: _ready builds from docs; apply_grid_config({map: ...}) rebuilds for another map.
# emerges: a title + claim reads "what this room teaches"; the dark code board reads "how it is computed"; the accent TRY board reads "what to do with your hands"; the mounted examples read "and here it is, running".
# needs: a backing wall [present]; framed text boards [present]; the map's tutorial.md [read at build]; example artifact scenes from the registry [resolved at build].
# relationships: the didactic sibling of [[station_panel]] (same board language, bigger claim); reads the same docs family as the /chapter reader; mounts examples the way [[curation_station]] mounts specimens.
# truth: a tutorial that lives outside its room teaches a diagram; a tutorial hung IN the room teaches a place. The wall is the map explaining itself.

@export_group("Content")
@export var map_name: String = "Change_Intro"
@export var example_count: int = 2
@export_group("Grid")
@export var width_cells: int = 4
@export_group("Color")
@export var wall_color: Color = Color(0.30, 0.31, 0.33)
@export var frame_color: Color = Color(0.74, 0.72, 0.68)
@export var board_color: Color = Color(0.88, 0.86, 0.80)
@export var code_color: Color = Color(0.10, 0.11, 0.13)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)
@export var text_dark: Color = Color(0.10, 0.10, 0.12)
@export var text_light: Color = Color(0.85, 0.92, 0.85)

const CELL := 1.0
const WALL_H := 2.6
const WALL_T := 0.12
const BOARD_Z := WALL_T * 0.5 + 0.03
const EXAMPLE_DENY := ["science_screen", "code_display", "dark_sphere", "tt", "lab_room"]

var _built := false

func _ready() -> void:
	_read_metadata_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()

func _read_metadata_overrides() -> void:
	if has_meta("config_map"): map_name = str(get_meta("config_map"))
	if has_meta("config_map_name"): map_name = str(get_meta("config_map_name"))
	if has_meta("config_example_count"): example_count = int(str(get_meta("config_example_count")))
	if has_meta("config_width_cells"): width_cells = int(str(get_meta("config_width_cells")))

# ── docs parsing ────────────────────────────────────────────────────────────

func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text() if f else ""

func _parse_tutorial(md: String) -> Dictionary:
	var out := {"title": map_name.replace("_", " "), "claim": [], "code": [], "try": []}
	if md.is_empty():
		return out
	var lines := md.split("\n")
	var in_code := false
	var code_done := false
	var claim_done := false
	for raw in lines:
		var line := String(raw)
		var s := line.strip_edges()
		if s.begins_with("# "):
			out.title = s.substr(2)
			continue
		if s.begins_with("```"):
			if in_code:
				code_done = true
			in_code = not in_code
			continue
		if in_code and not code_done:
			if out.code.size() < 10:
				out.code.append(line.replace("\t", "  ").substr(0, 44))
			continue
		if in_code:
			continue
		if s.begins_with("Try:"):
			out["try"] = _wrap(s, 40)
			continue
		if not claim_done and not s.is_empty() and out.title != "" and not s.begins_with("#"):
			out.claim = _wrap(s, 36)
			claim_done = true
	return out

func _wrap(text: String, width: int, max_lines: int = 6) -> Array:
	var words := text.split(" ")
	var lines: Array = []
	var cur := ""
	for w in words:
		if cur.length() + String(w).length() + 1 > width:
			lines.append(cur)
			cur = String(w)
			if lines.size() >= max_lines:
				return lines
		else:
			cur = cur + (" " if cur != "" else "") + String(w)
	if cur != "" and lines.size() < max_lines:
		lines.append(cur)
	return lines

# ── build ───────────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	var w: float = float(maxi(width_cells, 3)) * CELL
	var doc := _parse_tutorial(_read_file("res://commons/maps/%s/tutorial.md" % map_name))

	# backing wall + baseboard + top accent line
	add_child(_box(Vector3(0, WALL_H * 0.5, 0), Vector3(w, WALL_H, WALL_T), HangarKit.rams_body(wall_color, 0.08)))
	add_child(_box(Vector3(0, 0.06, WALL_T * 0.5), Vector3(w, 0.12, 0.04), HangarKit.rams_body(frame_color, 0.1)))
	add_child(_box(Vector3(0, WALL_H - 0.04, BOARD_Z), Vector3(w - 0.2, 0.025, 0.015), HangarKit.emissive(accent_color, 0.7)))

	# two clean columns: LIGHT column left (title/idea/try), DARK code right —
	# they must never overlap horizontally (dark-over-light collision).
	var left_x: float = -w * 0.5 + 1.0    # light column: spans left edge .. -0.1
	var left_w: float = 1.8
	var code_x: float = w * 0.5 - 1.1     # dark column: spans -0.1 .. right edge
	var code_w: float = 2.0

	# TITLE — top left, dark on light plate
	_board(Vector3(left_x, WALL_H - 0.32, 0), Vector2(left_w, 0.34), board_color)
	_label(str(doc.title).to_upper(), text_dark, Vector2(left_w - 0.2, 0.2), Vector3(left_x, WALL_H - 0.32, BOARD_Z))

	# THE IDEA — left column, claim text
	var claim: Array = doc.claim if doc.claim.size() > 0 else ["(no tutorial.md found)"]
	var idea_h: float = 0.16 * float(claim.size()) + 0.3
	var idea_bottom: float = WALL_H - 0.75 - idea_h
	_board(Vector3(left_x, WALL_H - 0.75 - idea_h * 0.5, 0), Vector2(left_w, idea_h), board_color)
	_lines(claim, text_dark, 0.13, Vector3(left_x, WALL_H - 0.75 - 0.22, BOARD_Z), left_w - 0.2, false)

	# THE CODE — right column, dark board, light text, case preserved
	var code: Array = doc.code if doc.code.size() > 0 else ["# no code block"]
	var code_h: float = 0.13 * float(code.size()) + 0.3
	_board(Vector3(code_x, WALL_H - 0.4 - code_h * 0.5, 0), Vector2(code_w, code_h), code_color)
	_lines(code, text_light, 0.105, Vector3(code_x, WALL_H - 0.4 - 0.2, BOARD_Z), code_w - 0.15, true)

	# TRY — below THE IDEA, accent-framed; top anchored under the idea board
	var try_lines: Array = doc["try"]
	if try_lines.size() > 4:
		try_lines = try_lines.slice(0, 4)
	if try_lines.size() > 0:
		var try_h: float = 0.14 * float(try_lines.size()) + 0.24
		var try_top: float = idea_bottom - 0.1
		var try_cy: float = try_top - try_h * 0.5
		_board(Vector3(left_x, try_cy, 0), Vector2(left_w, try_h), Color(0.98, 0.93, 0.86))
		add_child(_box(Vector3(left_x, try_top - 0.03, BOARD_Z), Vector3(left_w - 0.04, 0.02, 0.012), HangarKit.emissive(accent_color, 0.8)))
		_lines(try_lines, text_dark, 0.115, Vector3(left_x, try_top - 0.16, BOARD_Z), left_w - 0.2, false)

	# EXAMPLES — the map's real artifacts on daises in front of the wall
	_mount_examples(w)

func _board(center3: Vector3, size2: Vector2, face: Color) -> void:
	add_child(_box(center3 + Vector3(0, 0, WALL_T * 0.5), Vector3(size2.x + 0.06, size2.y + 0.06, 0.04), HangarKit.rams_body(frame_color, 0.06)))
	var mat := HangarKit.rams_body(face, 0.03) if face.get_luminance() > 0.45 else HangarKit.emissive(face, 0.25)
	add_child(_box(center3 + Vector3(0, 0, WALL_T * 0.5 + 0.021), Vector3(size2.x, size2.y, 0.012), mat))

func _label(text: String, col: Color, size2: Vector2, pos: Vector3) -> void:
	var m: MeshInstance3D = BakedText.make_label_mesh(text, col, size2, 1400, true)
	if m:
		m.position = pos
		add_child(m)

func _lines(rows: Array, col: Color, line_h: float, top_left_center: Vector3, max_w: float, keep_case: bool) -> void:
	var y := top_left_center.y
	for r in rows:
		var s := str(r)
		if s.strip_edges() != "":
			var t := s if keep_case else s
			var q: MeshInstance3D = BakedText.make_label_mesh(t, col, Vector2(max_w, line_h * 0.85), 1200, true)
			if q:
				q.position = Vector3(top_left_center.x, y, top_left_center.z)
				add_child(q)
		y -= line_h

# ── examples ────────────────────────────────────────────────────────────────

static var _registry_cache: Dictionary = {}

static func _registry() -> Dictionary:
	if not _registry_cache.is_empty():
		return _registry_cache
	var dir := DirAccess.open("res://commons/artifacts/registry")
	if dir == null:
		return _registry_cache
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var txt := FileAccess.get_file_as_string("res://commons/artifacts/registry/" + f)
		var d = JSON.parse_string(txt)
		if d is Dictionary and d.has("artifacts") and d.artifacts is Dictionary:
			for lk in d.artifacts:
				var m = d.artifacts[lk]
				if m is Dictionary and m.has("scene"):
					_registry_cache[lk] = str(m.scene)
	return _registry_cache

func _map_cast() -> Array:
	var txt := _read_file("res://commons/maps/%s/map_data.json" % map_name)
	if txt.is_empty():
		return []
	var d = JSON.parse_string(txt)
	if not (d is Dictionary):
		return []
	var layers = d.get("layers", d)
	var seen := {}
	var cast: Array = []
	for row in layers.get("interactables", []):
		for cell in row:
			var s := str(cell).strip_edges()
			if s.is_empty() or s.begins_with("#"):
				continue
			var name := s.split(":")[0].split("#")[0]
			if seen.has(name) or name in EXAMPLE_DENY:
				continue
			seen[name] = true
			cast.append(name)
	return cast

func _mount_examples(w: float) -> void:
	if example_count <= 0:
		return
	var reg := _registry()
	var mounted := 0
	var slots: Array = [Vector3(-w * 0.25, 0, 1.1), Vector3(w * 0.25, 0, 1.1), Vector3(0, 0, 1.5)]
	for lk in _map_cast():
		if mounted >= mini(example_count, slots.size()):
			break
		var scene_path: String = reg.get(lk, "")
		if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			continue
		var packed = load(scene_path)
		if packed == null:
			continue
		var inst: Node = packed.instantiate()
		if not (inst is Node3D):
			inst.queue_free()
			continue
		var slot: Vector3 = slots[mounted]
		# dais
		add_child(_box(slot + Vector3(0, 0.06, 0), Vector3(0.7, 0.12, 0.7), HangarKit.rams_body(frame_color, 0.1)))
		add_child(inst)
		inst.position = slot + Vector3(0, 0.12, 0)
		_fit(inst as Node3D, 1.0)
		# name tag above the dais
		var tag: Node3D = BakedText.make_tag(lk, Color(0.9, 0.95, 1.0), 0.05)
		if tag:
			tag.position = slot + Vector3(0, 1.45, 0)
			add_child(tag)
		mounted += 1

func _fit(n: Node3D, max_dim: float) -> void:
	var aabb := _measure(n)
	var m: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if m > max_dim and m > 0.001:
		n.scale = Vector3.ONE * (max_dim / m)

func _measure(n: Node) -> AABB:
	var total := AABB()
	var first := true
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		total = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).get_aabb()
		first = false
	for c in n.get_children():
		var sub := _measure(c)
		if sub.size != Vector3.ZERO:
			total = sub if first else total.merge(sub)
			first = false
	return total

func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi

extends Node3D
## Isometric / front-elevation WALL HANGAR editor.
##
## You see the wall FACE-ON (orthographic), scroll only LEFT/RIGHT along it, and
## stamp station pieces that snap with two gravities:
##   · WALL pieces (panels/signs) mount on the wall face at the cursor height.
##   · FLOOR pieces drop to the floor and STACK on whatever's beneath the cell.
## Everything snaps to a 1 m grid along the wall.
##
## Controls: move mouse = ghost follows · LMB = stamp · RMB = remove · A/D or ←/→
## or mouse-wheel = scroll the wall · click a palette piece (bottom) to pick it.
## No player, no mouse-capture — pure 2D-style editing.

const GRID := 1.0
const WALL_FACE_Z := 0.0        # wall pieces mount here (face toward +Z viewer)
const FLOOR_Z := 0.8            # floor pieces sit on this line in front of the wall
const WALL_LEN := 48.0
const WALL_TOP := 3.4           # highest wall-mount height
const PAN_SPEED := 12.0
const PAN_LIMIT := 20.0

const STATION := {
	"station_panel": "res://commons/artifacts/station/station_panel.tscn",
	"station_plinth": "res://commons/artifacts/station/station_plinth.tscn",
	"station_pillar": "res://commons/artifacts/station/station_pillar.tscn",
	"station_stage": "res://commons/artifacts/station/station_stage.tscn",
	"station_cabinet": "res://commons/artifacts/station/station_cabinet.tscn",
	"station_barrier": "res://commons/artifacts/station/station_barrier.tscn",
	"station_bench": "res://commons/artifacts/station/station_bench.tscn",
	"station_crates": "res://commons/artifacts/station/station_crates.tscn",
}
# Pieces that mount ON the wall (everything else falls to the floor + stacks).
const WALL_SET := ["station_panel"]

const C_PANEL := Color(0.11, 0.12, 0.15, 0.96)
const C_ACCENT := Color(0.86, 0.40, 0.16)
const C_TEXT := Color(0.87, 0.88, 0.90)

var _camera: Camera3D = null
var _pan_x := 0.0
var _placed: Array = []
var _held: Node3D = null
var _held_type := ""
var _held_is_wall := false
var _status: Label = null


func _ready() -> void:
	_build_world()
	_build_camera()
	_build_ui()


# ── World (floor + long wall) ─────────────────────────────────────────
func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.14, 0.17)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.63, 0.68)
	env.ambient_light_energy = 1.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, -22, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	add_child(_box(Vector3(0, -0.05, 2.0), Vector3(WALL_LEN, 0.1, 6.0), Color(0.50, 0.51, 0.55)))
	add_child(_box(Vector3(0, 2.0, -0.3), Vector3(WALL_LEN, 4.0, 0.6), Color(0.80, 0.79, 0.75)))
	# A thin Braun accent band along the wall, and 1 m floor gridlines for read.
	add_child(_box(Vector3(0, 3.0, 0.02), Vector3(WALL_LEN, 0.05, 0.02), C_ACCENT))
	for i in range(int(-WALL_LEN * 0.5), int(WALL_LEN * 0.5) + 1):
		add_child(_box(Vector3(float(i), 0.005, 2.0), Vector3(0.02, 0.01, 6.0), Color(0.42, 0.43, 0.47)))


func _box(center: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position = center
	return mi


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 7.0
	_camera.position = Vector3(0.0, 2.1, 9.0)
	_camera.rotation_degrees = Vector3(-9, 0, 0)   # near-front, slight tilt for depth
	_camera.current = true
	add_child(_camera)


# ── UI (palette along the bottom) ─────────────────────────────────────
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var hint := Label.new()
	hint.position = Vector2(14, 10)
	hint.add_theme_color_override("font_color", C_TEXT)
	hint.add_theme_font_size_override("font_size", 13)
	hint.text = "WALL HANGAR (front view)   ·   LMB stamp · RMB remove · A/D or wheel scroll · pick a piece below"
	layer.add_child(hint)
	_status = Label.new()
	_status.position = Vector2(14, 32)
	_status.add_theme_color_override("font_color", C_ACCENT)
	_status.add_theme_font_size_override("font_size", 12)
	layer.add_child(_status)

	var bar := PanelContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -60
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PANEL
	sb.set_content_margin_all(8)
	bar.add_theme_stylebox_override("panel", sb)
	layer.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)
	for token in STATION.keys():
		var b := Button.new()
		var is_wall: bool = token in WALL_SET
		b.text = ("◰ " if is_wall else "▣ ") + str(token).replace("station_", "")
		b.tooltip_text = "%s (%s)" % [token, "wall-mount" if is_wall else "floor + stack"]
		b.custom_minimum_size = Vector2(118, 40)
		b.pressed.connect(_pick.bind(str(token)))
		row.add_child(b)


# ── Picking / stamping ────────────────────────────────────────────────
func _pick(token: String) -> void:
	if _held != null and is_instance_valid(_held):
		_held.queue_free()
	_held = null
	_spawn_held(token)
	_set_status("holding %s — move to aim, LMB to stamp" % token)


func _spawn_held(token: String) -> void:
	var path: String = STATION.get(token, "")
	if path == "" or not ResourceLoader.exists(path):
		_set_status("missing: %s" % token)
		return
	var packed = load(path)
	if packed == null:
		return
	_held_type = token
	_held_is_wall = token in WALL_SET
	_held = packed.instantiate()
	_held.set_meta("wall_piece", _held_is_wall)
	add_child(_held)


func _commit() -> void:
	if _held == null or not is_instance_valid(_held):
		return
	_held.set_meta("placed", true)
	_placed.append(_held)
	var t := _held_type
	_held = null
	_spawn_held(t)   # keep stamping the same piece


func _remove_at_mouse() -> void:
	var mouse := get_viewport().get_mouse_position()
	var best: Node3D = null
	var best_d := 70.0
	for n in _placed:
		if not is_instance_valid(n) or n == _held:
			continue
		var box := _world_aabb(n)
		if box.size.y <= 0.001:
			continue
		var d := _camera.unproject_position(box.get_center()).distance_to(mouse)
		if d < best_d:
			best_d = d
			best = n
	if best != null:
		_placed.erase(best)
		best.queue_free()
		_set_status("removed")


# ── Per-frame: pan + ghost follow with two-gravity snap ───────────────
func _process(delta: float) -> void:
	_update_pan(delta)
	if _held != null and is_instance_valid(_held):
		var w := _mouse_on_wall_plane()
		var x := snappedf(w.x, GRID)
		if _held_is_wall:
			var y := clampf(snappedf(w.y, GRID * 0.5), 0.6, WALL_TOP)
			_held.global_position = Vector3(x, y, WALL_FACE_Z + 0.06)
		else:
			_held.global_position = Vector3(x, _stack_top(x, _held), FLOOR_Z)


func _update_pan(delta: float) -> void:
	var dx := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dx -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dx += 1.0
	if dx != 0.0:
		_pan_x = clampf(_pan_x + dx * PAN_SPEED * delta, -PAN_LIMIT, PAN_LIMIT)
		_camera.position.x = _pan_x


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		match (ev as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				_commit()
			MOUSE_BUTTON_RIGHT:
				_remove_at_mouse()
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
				_pan_x = clampf(_pan_x - 1.0, -PAN_LIMIT, PAN_LIMIT)
				_camera.position.x = _pan_x
			MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
				_pan_x = clampf(_pan_x + 1.0, -PAN_LIMIT, PAN_LIMIT)
				_camera.position.x = _pan_x


# ── Geometry helpers ──────────────────────────────────────────────────
func _mouse_on_wall_plane() -> Vector3:
	# Intersect the mouse ray with the wall plane (Z = WALL_FACE_Z) — gives the
	# X along the wall and the Y height, regardless of the slight camera tilt.
	var mouse := get_viewport().get_mouse_position()
	var from := _camera.project_ray_origin(mouse)
	var dir := _camera.project_ray_normal(mouse)
	if absf(dir.z) > 0.0001:
		var t := (WALL_FACE_Z - from.z) / dir.z
		if t > 0.0:
			return from + dir * t
	return Vector3(from.x, from.y, WALL_FACE_Z)


func _stack_top(x: float, exclude: Node3D) -> float:
	# Highest top among FLOOR pieces whose X footprint covers x; 0 = floor.
	var top := 0.0
	for n in _placed:
		if n == exclude or not is_instance_valid(n):
			continue
		if bool(n.get_meta("wall_piece", false)):
			continue
		var box := _world_aabb(n)
		if box.size.y <= 0.001:
			continue
		var cx := box.position.x + box.size.x * 0.5
		var hw := box.size.x * 0.5 + 0.05
		if absf(x - cx) <= hw:
			top = maxf(top, box.position.y + box.size.y)
	return top


func _world_aabb(n: Node3D) -> AABB:
	var box := AABB()
	var found := false
	var stack: Array = [n]
	while not stack.is_empty():
		var node = stack.pop_back()
		for ch in node.get_children():
			stack.append(ch)
		if node is VisualInstance3D and not (node is GPUParticles3D) and (node as VisualInstance3D).is_visible_in_tree():
			var gb: AABB = (node as VisualInstance3D).global_transform * (node as VisualInstance3D).get_aabb()
			if not found:
				box = gb
				found = true
			else:
				box = box.merge(gb)
	return box if found else AABB()


func _set_status(msg: String) -> void:
	if _status != null:
		_status.text = msg

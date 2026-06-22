extends Node3D
class_name ArtifactReviewStation

## One artifact at a time on a pedestal, with a clickable review panel — NO player body,
## NO streaming, so there is nothing to get stuck in. Orbit the artifact with the mouse,
## Next/Prev to cycle the queue, and rate / set footprint / flag needs / comment. Every
## judgement is written to ada_run/artifact_reviews.json, keyed by lookup_name, in a shape
## that maps straight onto the registry's spatial_needs (footprint_cells, platform,
## wall_backing) so a later sync step can fold ratings + footprints back in.
##
## Launch: open commons/scenes/desktop_artifact_review.tscn (or set this script on a Node3D).
## Controls: drag = orbit · wheel = zoom · 1–5 = rate · ←/→ = prev/next · S = save.
##           (typing in the comment box disables the key shortcuts automatically.)

const ArtifactQueueScript := preload("res://commons/artifacts/artifact_runner/artifact_queue.gd")
const PLATFORMS := ["none", "pedestal", "table", "sunken", "floor", "wall"]
const REVIEWS_PATH := "res://ada_run/artifact_reviews.json"

# Which artifacts to review. Empty only_maps + use_all_registry=false → the ten concept maps.
@export var only_maps: Array[String] = []
@export var use_all_registry: bool = false
@export var shuffle: bool = false
@export var start_index: int = 0

var _queue: Array = []
var _name_scene: Dictionary = {}      # lookup_name -> scene path
var _name_meta: Dictionary = {}       # lookup_name -> {spatial_needs, category, name}
var _reviews: Dictionary = {}         # lookup_name -> review dict
var _index: int = 0
var _busy: bool = false

var _mount: Node3D = null
var _current_inst: Node = null
var _camera: Camera3D = null
var _spin: bool = true

# camera orbit
var _yaw: float = 0.7
var _pitch: float = 0.5
var _dist: float = 5.0
var _target: Vector3 = Vector3(0, 1.0, 0)
var _dragging: bool = false

# walk mode (Tab toggles orbit <-> walk; no streaming, just this one room)
var _mode: String = "orbit"            # "orbit" | "walk"
var _player: CharacterBody3D = null
var _player_cam: Camera3D = null
var _look: bool = false                # mouse captured for look (RMB held in walk mode)
var _player_pitch: float = 0.0
const GRAVITY := 22.0
const WALK_SPEED := 4.5
const JUMP_VELOCITY := 7.0

# UI refs
var _title: Label = null
var _rating_buttons: Array = []
var _rating: int = 0
var _fp_label: Label = null
var _fp_cells: int = 1
var _h_label: Label = null
var _h_cells: int = 1
var _measured_label: Label = null
var _platform_opt: OptionButton = null
var _wall_check: CheckBox = null
var _ceil_check: CheckBox = null
var _isolate_check: CheckBox = null
var _comment_edit: TextEdit = null
var _status: Label = null
var _mode_btn: Button = null
var _help: Label = null


func _ready() -> void:
	_build_name_index()
	if use_all_registry:
		_queue = ArtifactQueueScript.build_all_registry()
	else:
		_queue = ArtifactQueueScript.build(only_maps, shuffle)
	_queue = _queue.filter(func(e): return _name_scene.has(str(e.get("name", ""))))
	if _queue.is_empty():
		push_error("ArtifactReviewStation: queue empty")
		return
	_load_reviews()
	_build_world()
	_build_camera()
	_build_player()
	_build_ui()
	_index = clampi(start_index, 0, _queue.size() - 1)
	_show(_index)


# ---------------------------------------------------------------- registry index
func _build_name_index() -> void:
	var dir := DirAccess.open("res://commons/artifacts/registry")
	if dir == null:
		return
	for fn in dir.get_files():
		if not fn.ends_with(".json"):
			continue
		var f := FileAccess.open("res://commons/artifacts/registry/" + fn, FileAccess.READ)
		if f == null:
			continue
		var data = JSON.parse_string(f.get_as_text())
		if not (data is Dictionary):
			continue
		for k in (data.get("artifacts", {}) as Dictionary).keys():
			var v = data["artifacts"][k]
			if v is Dictionary and v.has("scene") and ResourceLoader.exists(str(v["scene"])):
				var nm := str(v.get("lookup_name", k))
				_name_scene[nm] = str(v["scene"])
				_name_meta[nm] = {
					"spatial_needs": v.get("spatial_needs", {}),
					"category": str(v.get("category", "")),
					"name": str(v.get("name", nm)),
				}


# ---------------------------------------------------------------- world + camera
func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.11)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.70)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -40, 0)
	key.light_energy = 1.2
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-12, 135, 0)
	fill.light_energy = 0.35
	add_child(fill)

	# Pedestal + ground.
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.10, 0.11, 0.14)
	gmat.roughness = 0.98
	ground.material_override = gmat
	add_child(ground)

	# Floor collider for walk mode (the mesh above is visual only). Top surface at y=0.
	var floor_body := StaticBody3D.new()
	floor_body.name = "WalkFloor"
	var floor_col := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(80, 1.0, 80)
	floor_col.shape = floor_box
	floor_col.position = Vector3(0, -0.5, 0)
	floor_body.add_child(floor_col)
	add_child(floor_body)

	var ped := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.9
	cyl.bottom_radius = 1.1
	cyl.height = 0.6
	ped.mesh = cyl
	ped.position = Vector3(0, 0.3, 0)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.16, 0.17, 0.21)
	pmat.metallic = 0.2
	pmat.roughness = 0.7
	ped.material_override = pmat
	add_child(ped)

	_mount = Node3D.new()
	_mount.name = "ArtifactMount"
	_mount.position = Vector3(0, 0.6, 0)   # pedestal top
	add_child(_mount)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 42.0
	add_child(_camera)
	_update_camera()


func _update_camera() -> void:
	if _camera == null:
		return
	var dir := Vector3(
		cos(_pitch) * sin(_yaw),
		sin(_pitch),
		cos(_pitch) * cos(_yaw))
	_camera.global_position = _target + dir * _dist
	_camera.look_at(_target, Vector3.UP)


# ---------------------------------------------------------------- walk mode
func _build_player() -> void:
	_player = CharacterBody3D.new()
	_player.name = "WalkPlayer"
	_player.collision_layer = 0       # never collide with anything as a target
	_player.collision_mask = 1        # only stand on the floor; artifacts are inert
	var pc := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	pc.shape = cap
	pc.position = Vector3(0, 0.85, 0)
	_player.add_child(pc)
	_player_cam = Camera3D.new()
	_player_cam.fov = 70.0
	_player_cam.position = Vector3(0, 1.55, 0)
	_player_cam.current = false
	_player.add_child(_player_cam)
	add_child(_player)
	_reset_player_spawn()


func _reset_player_spawn() -> void:
	if _player == null:
		return
	# stand back far enough to see the current artifact, facing it (default basis faces -z)
	var back: float = clampf(_dist, 3.0, 14.0)
	_player.global_position = Vector3(0, 0.1, back)   # capsule origin is at the feet → rests at y≈0
	_player.rotation = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	_player_pitch = 0.0
	if _player_cam:
		_player_cam.rotation = Vector3.ZERO


func _toggle_mode() -> void:
	if _mode == "orbit":
		_mode = "walk"
		_reset_player_spawn()
		if _player_cam: _player_cam.current = true
		_dragging = false
	else:
		_mode = "orbit"
		_look = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if _camera: _camera.current = true
		_update_camera()
	_refresh_mode_label()


func _refresh_mode_label() -> void:
	if _mode_btn:
		_mode_btn.text = "Mode: WALK  (Tab)" if _mode == "walk" else "Mode: ORBIT  (Tab)"
	if _help:
		_help.text = ("WALK: WASD move · hold RMB look · Space jump · Tab orbit · 1–5 rate · ←/→ nav"
			if _mode == "walk"
			else "ORBIT: drag rotate · wheel zoom · Tab walk · 1–5 rate · ←/→ nav · S save")


func _physics_process(delta: float) -> void:
	if _mode != "walk" or _player == null:
		return
	var v := _player.velocity
	v.y -= GRAVITY * delta
	# don't drive movement while the user is typing an improvement note
	var foc = get_viewport().gui_get_focus_owner()
	var typing := foc is TextEdit or foc is LineEdit
	var dir := Vector3.ZERO
	if not typing:
		var fwd := -_player.global_transform.basis.z
		var rgt := _player.global_transform.basis.x
		fwd.y = 0.0; rgt.y = 0.0
		fwd = fwd.normalized(); rgt = rgt.normalized()
		if Input.is_key_pressed(KEY_W): dir += fwd
		if Input.is_key_pressed(KEY_S): dir -= fwd
		if Input.is_key_pressed(KEY_D): dir += rgt
		if Input.is_key_pressed(KEY_A): dir -= rgt
		if Input.is_key_pressed(KEY_SPACE) and _player.is_on_floor():
			v.y = JUMP_VELOCITY
	dir = dir.normalized()
	v.x = dir.x * WALK_SPEED
	v.z = dir.z * WALK_SPEED
	_player.velocity = v
	_player.move_and_slide()


# ---------------------------------------------------------------- UI
func _make_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE   # so they never steal keyboard from the comment box
	return b


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -400
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 18)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_title)

	_measured_label = Label.new()
	_measured_label.add_theme_font_size_override("font_size", 11)
	_measured_label.modulate = Color(0.7, 0.74, 0.82)
	vb.add_child(_measured_label)

	vb.add_child(_hsep())

	# Rating 1–5
	vb.add_child(_section_label("Rating"))
	var rate_row := HBoxContainer.new()
	rate_row.add_theme_constant_override("separation", 6)
	for i in range(1, 6):
		var rb := _make_btn(str(i))
		rb.custom_minimum_size = Vector2(54, 40)
		rb.pressed.connect(_on_rating.bind(i))
		_rating_buttons.append(rb)
		rate_row.add_child(rb)
	vb.add_child(rate_row)

	# Footprint + height steppers
	vb.add_child(_section_label("Footprint (floor cells)"))
	var fp_row := HBoxContainer.new()
	fp_row.add_theme_constant_override("separation", 8)
	var fp_minus := _make_btn("−"); fp_minus.custom_minimum_size = Vector2(40, 34)
	fp_minus.pressed.connect(func(): _set_fp(_fp_cells - 1))
	_fp_label = Label.new(); _fp_label.add_theme_font_size_override("font_size", 18)
	_fp_label.custom_minimum_size = Vector2(40, 0)
	_fp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fp_plus := _make_btn("+"); fp_plus.custom_minimum_size = Vector2(40, 34)
	fp_plus.pressed.connect(func(): _set_fp(_fp_cells + 1))
	fp_row.add_child(fp_minus); fp_row.add_child(_fp_label); fp_row.add_child(fp_plus)
	var h_lbl := Label.new(); h_lbl.text = "   Height"; fp_row.add_child(h_lbl)
	var h_minus := _make_btn("−"); h_minus.custom_minimum_size = Vector2(40, 34)
	h_minus.pressed.connect(func(): _set_h(_h_cells - 1))
	_h_label = Label.new(); _h_label.add_theme_font_size_override("font_size", 18)
	_h_label.custom_minimum_size = Vector2(36, 0)
	_h_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var h_plus := _make_btn("+"); h_plus.custom_minimum_size = Vector2(40, 34)
	h_plus.pressed.connect(func(): _set_h(_h_cells + 1))
	fp_row.add_child(h_minus); fp_row.add_child(_h_label); fp_row.add_child(h_plus)
	vb.add_child(fp_row)

	# Platform (what it stands on)
	vb.add_child(_section_label("Stands on / platform"))
	_platform_opt = OptionButton.new()
	_platform_opt.focus_mode = Control.FOCUS_NONE
	for p in PLATFORMS:
		_platform_opt.add_item(p)
	vb.add_child(_platform_opt)

	# Need toggles
	_wall_check = CheckBox.new(); _wall_check.text = "Needs a wall behind it"
	_wall_check.focus_mode = Control.FOCUS_NONE
	_ceil_check = CheckBox.new(); _ceil_check.text = "Hangs from ceiling"
	_ceil_check.focus_mode = Control.FOCUS_NONE
	_isolate_check = CheckBox.new(); _isolate_check.text = "Needs space around it"
	_isolate_check.focus_mode = Control.FOCUS_NONE
	vb.add_child(_wall_check); vb.add_child(_ceil_check); vb.add_child(_isolate_check)

	# Comment
	vb.add_child(_section_label("Improvement notes"))
	_comment_edit = TextEdit.new()
	_comment_edit.custom_minimum_size = Vector2(0, 110)
	_comment_edit.placeholder_text = "What would make this artifact better…"
	_comment_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vb.add_child(_comment_edit)

	vb.add_child(_hsep())

	# Navigation
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	var prev_b := _make_btn("◀ Prev"); prev_b.pressed.connect(func(): _go(-1))
	var skip_b := _make_btn("Skip"); skip_b.pressed.connect(func(): _show(_index + 1))
	var save_b := _make_btn("Save ✓"); save_b.pressed.connect(_save_current)
	var next_b := _make_btn("Next ▶"); next_b.pressed.connect(func(): _go(1))
	for b in [prev_b, skip_b, save_b, next_b]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(b)
	vb.add_child(nav)

	var spin_check := CheckBox.new()
	spin_check.text = "Spin"
	spin_check.button_pressed = true
	spin_check.focus_mode = Control.FOCUS_NONE
	spin_check.toggled.connect(func(on): _spin = on)
	vb.add_child(spin_check)

	_mode_btn = _make_btn("Mode: ORBIT  (Tab)")
	_mode_btn.pressed.connect(_toggle_mode)
	vb.add_child(_mode_btn)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 11)
	_status.modulate = Color(0.7, 0.78, 0.7)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_status)

	_help = Label.new()
	_help.add_theme_font_size_override("font_size", 10)
	_help.modulate = Color(0.55, 0.58, 0.64)
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.text = "ORBIT: drag rotate · wheel zoom · Tab walk · 1–5 rate · ←/→ nav · S save"
	vb.add_child(_help)


func _section_label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 12)
	l.modulate = Color(0.78, 0.82, 0.9)
	return l


func _hsep() -> HSeparator:
	return HSeparator.new()


# ---------------------------------------------------------------- show an artifact
func _show(i: int) -> void:
	if _busy:
		return
	if i < 0 or i >= _queue.size():
		return
	_busy = true
	_index = i
	if is_instance_valid(_current_inst):
		_current_inst.queue_free()
		_current_inst = null
	for c in _mount.get_children():
		c.queue_free()

	var entry: Dictionary = _queue[i]
	var nm := str(entry.get("name", ""))
	var scene_path: String = _name_scene.get(nm, "")
	var inst: Node = null
	if scene_path != "" and ResourceLoader.exists(scene_path):
		var packed = load(scene_path)
		if packed:
			inst = packed.instantiate()
	if inst:
		_current_inst = inst
		_mount.add_child(inst)
		if inst.has_method("apply_grid_config"):
			inst.apply_grid_config({"emissive": false})
		_make_inert(inst)

	# Let procedural artifacts build, then frame + ground them.
	await get_tree().process_frame
	await get_tree().process_frame

	var size := Vector3.ONE
	var center := Vector3(0, 0.5, 0)
	if is_instance_valid(_current_inst) and _current_inst is Node3D:
		var aabb := _combined_aabb(_current_inst)
		if aabb.size.length() > 0.001:
			size = aabb.size
			# sit the artifact's base on the pedestal top
			(_current_inst as Node3D).position = Vector3(0, -aabb.position.y, 0)
			center = Vector3(0, aabb.size.y * 0.5, 0)
	var max_dim: float = maxf(size.x, maxf(size.y, size.z))
	_target = _mount.position + center
	_dist = clampf(max_dim * 1.7 + 1.2, 1.5, 60.0)
	_yaw = 0.7
	_pitch = 0.45
	_update_camera()

	_populate_ui(nm, entry, size)
	_busy = false


func _make_inert(node: Node) -> void:
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
		if node is RigidBody3D:
			node.freeze = true
	elif node is SoftBody3D:
		node.collision_layer = 0
		node.collision_mask = 0
	for c in node.get_children():
		_make_inert(c)


func _combined_aabb(node: Node) -> AABB:
	var out := AABB()
	var got := false
	if node is VisualInstance3D:
		var a: AABB = (node as VisualInstance3D).get_aabb()
		var xf: Transform3D = (node as Node3D).global_transform
		var world := xf * a
		out = world
		got = true
	for c in node.get_children():
		var ca := _combined_aabb(c)
		if ca.size.length() > 0.0:
			if got:
				out = out.merge(ca)
			else:
				out = ca
				got = true
	return out


# ---------------------------------------------------------------- UI <-> review data
func _populate_ui(nm: String, entry: Dictionary, measured: Vector3) -> void:
	var meta: Dictionary = _name_meta.get(nm, {})
	var sn: Dictionary = meta.get("spatial_needs", {}) if meta.get("spatial_needs") is Dictionary else {}
	var rev: Dictionary = _reviews.get(nm, {})

	_title.text = "[%d/%d]  %s\n%s" % [_index + 1, _queue.size(), nm, str(entry.get("section", ""))]
	var sugg_fp: int = maxi(1, int(ceil(maxf(measured.x, measured.z))))
	var sugg_h: int = maxi(1, int(ceil(measured.y)))
	_measured_label.text = "measured ≈ %.1f × %.1f × %.1f m  (≈ %d×%d cells)  ·  category: %s" % [
		measured.x, measured.y, measured.z, sugg_fp, sugg_h, str(meta.get("category", "?"))]

	_rating = int(rev.get("rating", 0))
	_refresh_rating_buttons()
	_set_fp(int(rev.get("footprint_cells", sn.get("footprint_cells", sugg_fp))))
	_set_h(int(rev.get("height_cells", sn.get("height_cells", sugg_h))))
	var plat := str(rev.get("platform", sn.get("platform", "none")))
	_platform_opt.selected = maxi(0, PLATFORMS.find(plat))
	_wall_check.button_pressed = bool(rev.get("wall_backing", sn.get("wall_backing", false)))
	_ceil_check.button_pressed = bool(rev.get("ceiling", false))
	_isolate_check.button_pressed = bool(rev.get("isolate", false))
	_comment_edit.text = str(rev.get("comment", ""))

	var done := _reviews.size()
	var rated := "✓ reviewed" if rev.has("rating") else "not yet reviewed"
	_status.text = "%s  ·  %d / %d artifacts reviewed so far" % [rated, done, _queue.size()]


func _on_rating(n: int) -> void:
	_rating = n
	_refresh_rating_buttons()


func _refresh_rating_buttons() -> void:
	for idx in range(_rating_buttons.size()):
		var b: Button = _rating_buttons[idx]
		var on := (idx + 1) <= _rating
		b.modulate = Color(1.0, 0.85, 0.3) if on else Color(1, 1, 1)


func _set_fp(v: int) -> void:
	_fp_cells = clampi(v, 1, 25)
	if _fp_label:
		_fp_label.text = str(_fp_cells)


func _set_h(v: int) -> void:
	_h_cells = clampi(v, 1, 12)
	if _h_label:
		_h_label.text = str(_h_cells)


func _gather() -> Dictionary:
	return {
		"rating": _rating,
		"footprint_cells": _fp_cells,
		"height_cells": _h_cells,
		"platform": PLATFORMS[_platform_opt.selected] if _platform_opt.selected >= 0 else "none",
		"wall_backing": _wall_check.button_pressed,
		"ceiling": _ceil_check.button_pressed,
		"isolate": _isolate_check.button_pressed,
		"comment": _comment_edit.text.strip_edges(),
		"section": str(_queue[_index].get("section", "")) if _index < _queue.size() else "",
		"reviewed_at": Time.get_datetime_string_from_system(),
	}


func _save_current() -> void:
	if _index < 0 or _index >= _queue.size():
		return
	var nm := str(_queue[_index].get("name", ""))
	if nm == "":
		return
	_reviews[nm] = _gather()
	_write_reviews()
	if _status:
		_status.text = "saved ✓  %s  ·  %d / %d reviewed" % [nm, _reviews.size(), _queue.size()]


func _go(delta: int) -> void:
	_save_current()
	_show(clampi(_index + delta, 0, _queue.size() - 1))


# ---------------------------------------------------------------- persistence
func _load_reviews() -> void:
	var abs := ProjectSettings.globalize_path(REVIEWS_PATH)
	if not FileAccess.file_exists(abs):
		return
	var f := FileAccess.open(abs, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary and data.has("reviews") and data["reviews"] is Dictionary:
		_reviews = data["reviews"]


func _write_reviews() -> void:
	var abs := ProjectSettings.globalize_path(REVIEWS_PATH)
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var payload := {
		"updated_at": Time.get_datetime_string_from_system(),
		"count": _reviews.size(),
		"reviews": _reviews,
	}
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


# ---------------------------------------------------------------- input (orbit + shortcuts)
func _process(delta: float) -> void:
	if _mode == "orbit" and _spin and is_instance_valid(_current_inst) and _current_inst is Node3D:
		(_current_inst as Node3D).rotate_y(delta * 0.4)


func _unhandled_input(event: InputEvent) -> void:
	# _unhandled_input only fires for events the UI panel didn't consume — so clicking
	# buttons and typing in the comment box never reach orbit/look/shortcuts.
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_TAB:
		_toggle_mode()
		get_viewport().set_input_as_handled()
		return

	if _mode == "walk":
		# Hold RMB to look; cursor stays free otherwise so the panel is clickable.
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
			_look = (event as InputEventMouseButton).pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _look else Input.MOUSE_MODE_VISIBLE
		elif event is InputEventMouseMotion and _look and _player:
			var mm := event as InputEventMouseMotion
			_player.rotate_y(-mm.relative.x * 0.005)
			_player_pitch = clampf(_player_pitch - mm.relative.y * 0.005, -1.4, 1.4)
			if _player_cam:
				_player_cam.rotation.x = _player_pitch
	else:
		# Orbit camera.
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_dragging = mb.pressed
			elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
				_dist = clampf(_dist * 0.9, 1.0, 80.0); _update_camera()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
				_dist = clampf(_dist * 1.1, 1.0, 80.0); _update_camera()
		elif event is InputEventMouseMotion and _dragging:
			var mm := event as InputEventMouseMotion
			_yaw -= mm.relative.x * 0.01
			_pitch = clampf(_pitch + mm.relative.y * 0.01, -1.4, 1.4)
			_update_camera()

	# Shortcuts in both modes. Numbers/arrows never collide with WASD; S = save only in
	# orbit (in walk, S is "step back", and nav already auto-saves).
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = (event as InputEventKey).keycode
		match kc:
			KEY_LEFT, KEY_P: _go(-1)
			KEY_RIGHT, KEY_N: _go(1)
			KEY_1: _on_rating(1)
			KEY_2: _on_rating(2)
			KEY_3: _on_rating(3)
			KEY_4: _on_rating(4)
			KEY_5: _on_rating(5)
		if kc == KEY_S and _mode == "orbit":
			_save_current()

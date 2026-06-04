extends Node3D
## BiomeScrubberDesktop3D — scrub AND inspect the biome accrual stack.
##
## Two questions this tool answers:
##   1. ACCRUAL  — what does the biome look like at sequence N?  (stage slider)
##   2. CONTRIBUTION — what does each single layer add?  (solo / toggle)
##
## This is the ACTUAL Godot renderer driving `BiomeAccrualManager` — not a web
## approximation. Zero drift: what you scrub here is what the game builds. It
## attaches the accrual to a bare host with a synthetic grid, so you see the
## PURE accrual stack in isolation (no GridSystem ring doubling) — the clean
## surface for curating the layers themselves.
##
## Reuses the manager's built-in debug API:
##   set_stage_override(N) · apply(host, ctx) · enable_layer(kind, bool)
##   reset_overrides() · get_active_kinds() · get_contributions()
##
## Controls:
##   ] / →  next stage     [ / ←  prev stage     1-9,0 jump    - / =  ends
##   ↑ / ↓  select layer    Space  toggle layer    S  solo selected    A  all on
##   R  reset to progression    Tab  hide/show panel    R-drag orbit    wheel zoom
##
## CLI (headless):
##   --stage=N            start stage
##   --shot=<path>        screenshot to <path>, quit
##   --contact-sheet=<b>  <b>_01..19.png — accrual at each stage
##   --solo-sheet=<b>     <b>_<kind>.png — each layer ALONE at max stage
##   --solo=<kind>        one shot of a single layer alone
##   --dims=N             synthetic grid size (default 20)

const MIN_STAGE := 1
const MAX_STAGE := 19
@export var grid_size: int = 20          # synthetic default (square)
@export var cube_size: float = 1.0
@export var auto_spin: bool = true
@export var spin_speed: float = 0.18
@export var start_stage: int = 1

# The biome is PER MAP — sized to the map's grid, driven by the map's
# biome_paint, staged by the map's sequence. With no --map, the scrubber
# uses a synthetic square grid + empty paint to inspect layers abstractly.
var grid_w: int = 20
var grid_d: int = 20
var _map_arg: String = ""                # --map=<Name>; "" = synthetic
var _loaded_map: String = ""
var _map_seq: String = ""
var _map_paint: Array = []               # the map's biome_paint layer
var _stage_explicit: bool = false        # true if --stage given (allows >MAX for lab dispatcher@99)
var _map_data: Dictionary = {}           # full parsed map_data.json (for write-back)
var _map_overrides: Dictionary = {}      # settings.biome_overrides from the map
var _status_msg: String = ""             # transient HUD line (e.g. "saved")

var _accrual: Node = null
var _host: Node3D = null
var _camera: Camera3D = null
var _hud: Label = null
var _perf: Label = null
var _panel: VBoxContainer = null
var _panel_root: Control = null
var _stage: int = 1
var _orbit_yaw: float = 0.6
var _orbit_pitch: float = -0.45
var _orbit_radius: float = 0.0
var _orbit_center: Vector3 = Vector3.ZERO
var _dragging: bool = false
var _contribs: Array = []
var _order_of_kind: Dictionary = {}   # kind -> order
var _seq_of_kind: Dictionary = {}      # kind -> seq name
var _disabled: Dictionary = {}         # kind -> true (mirror of manager state)
var _selected: int = 0                 # index into current active-kinds list
var _active_kinds: Array = []          # active kinds at current stage (rendered order)

# Headless
var _shot_path: String = ""
var _contact_base: String = ""
var _solo_base: String = ""
var _solo_one: String = ""
var _capture_frames: int = 0


func _ready() -> void:
	_parse_cli()
	grid_w = grid_size
	grid_d = grid_size
	# Per-map mode: load real dimensions + biome_paint + true stage BEFORE
	# we size the camera / floor to the grid.
	if _map_arg != "":
		_load_map(_map_arg)
	var span := float(maxi(grid_w, grid_d))
	_orbit_center = Vector3(float(grid_w) * cube_size * 0.5, 1.5, float(grid_d) * cube_size * 0.5)
	_orbit_radius = span * cube_size * 1.05

	_build_environment()
	_build_light()
	_build_floor()
	_build_camera()
	_build_ui()

	_host = Node3D.new()
	_host.name = "BiomeHost"
	add_child(_host)

	_accrual = get_node_or_null("/root/BiomeAccrualManager")
	if _accrual == null:
		_set_hud("ERROR: /root/BiomeAccrualManager autoload not found.")
		push_error("BiomeScrubber: BiomeAccrualManager autoload missing")
		return
	_contribs = _accrual.get_contributions() if _accrual.has_method("get_contributions") else []
	for entry in _contribs:
		var k := str(entry.get("kind", ""))
		_order_of_kind[k] = int(entry.get("order", 0))
		_seq_of_kind[k] = str(entry.get("seq", ""))

	# Explicit --stage may exceed MAX (e.g. 99 to fire the lab dispatcher).
	_stage = start_stage if _stage_explicit else clampi(start_stage, MIN_STAGE, MAX_STAGE)
	_rebuild()

	if _solo_base != "":
		_run_solo_sheet.call_deferred()
	elif _contact_base != "":
		_run_contact_sheet.call_deferred()
	elif _solo_one != "":
		# Jump to the layer's own sequence so it's actually active, then solo it.
		if _order_of_kind.has(_solo_one):
			_stage = clampi(int(_order_of_kind[_solo_one]), MIN_STAGE, MAX_STAGE)
			_rebuild()
		_solo_layer(_solo_one)
		_capture_frames = 70
	elif _shot_path != "":
		_capture_frames = 70


func _parse_cli() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := str(raw).strip_edges()
		if a.begins_with("--stage="):
			start_stage = int(a.split("=", true, 1)[1])
			_stage_explicit = true
		elif a.begins_with("--dims="): grid_size = maxi(4, int(a.split("=", true, 1)[1]))
		elif a.begins_with("--shot="): _shot_path = a.split("=", true, 1)[1]
		elif a.begins_with("--contact-sheet="): _contact_base = a.split("=", true, 1)[1]
		elif a.begins_with("--solo-sheet="): _solo_base = a.split("=", true, 1)[1]
		elif a.begins_with("--solo="): _solo_one = a.split("=", true, 1)[1]
		elif a.begins_with("--map="): _map_arg = a.split("=", true, 1)[1]


## Per-map mode: read the map's dimensions + biome_paint, and sync the
## EcosystemManager so the map's TRUE stage drives the accrual. The biome
## is per map — this is what the player actually sees on that map (minus
## the BiomeRingComponent foliage, a separate system slated for retirement;
## what shows here is the accrual stack + painted dispatcher, the future
## single-populator view).
func _load_map(name: String) -> void:
	var path := "res://commons/maps/%s/map_data.json" % name
	if not FileAccess.file_exists(path):
		push_warning("BiomeScrubber: map not found: %s" % path)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		push_warning("BiomeScrubber: map_data parse failed: %s" % name)
		return
	var mi: Dictionary = data.get("map_info", {})
	var dims: Dictionary = mi.get("dimensions", {})
	grid_w = int(dims.get("width", grid_size))
	grid_d = int(dims.get("depth", grid_size))
	var layers: Dictionary = data.get("layers", {})
	var bp = layers.get("biome_paint", [])
	if bp is Array:
		_map_paint = bp
	_loaded_map = name
	_map_data = data
	# Read existing per-map overrides so the scrubber opens with this
	# map's current biome edits, and can re-save them.
	var settings: Dictionary = data.get("settings", {})
	_map_overrides = settings.get("biome_overrides", {})
	if not (_map_overrides is Dictionary):
		_map_overrides = {}
	for k in _map_overrides.get("disable", []):
		_disabled[str(k)] = true
	# Sync EcosystemManager to the map's sequence → true stage_order.
	var eco = get_node_or_null("/root/EcosystemManager")
	if eco:
		if eco.has_method("sync_to_map"):
			eco.sync_to_map(name)
		if eco.has_method("get_sequence_for_map"):
			_map_seq = str(eco.get_sequence_for_map(name))
		# Map's true stage drives the accrual — unless --stage was given explicitly.
		if eco.has_method("get_current_stage_order") and not _stage_explicit:
			var eco_order := int(eco.get_current_stage_order())
			# Lab sequences (biome_lab @ 99) must pass UNCAPPED so the
			# lab_only dispatcher becomes reachable. EcosystemManager
			# correctly returns 99 for lab maps; clamping it to MAX_STAGE
			# here was hiding the painted dispatcher (the bug Agent D found).
			if eco_order > MAX_STAGE:
				start_stage = mini(eco_order, 99)
				_stage_explicit = true  # bypass the _ready re-clamp
			else:
				start_stage = clampi(eco_order, MIN_STAGE, MAX_STAGE)
	# A saved per-map stage_order override wins over the eco-synced stage
	# (but not over an explicit --stage).
	if _map_overrides.has("stage_order") and not _stage_explicit:
		start_stage = clampi(int(_map_overrides["stage_order"]), MIN_STAGE, 99)
	print("[scrubber] loaded map %s — %dx%d, seq=%s, stage=%d, paint_rows=%d" % [
		name, grid_w, grid_d, _map_seq, start_stage, _map_paint.size()])


# ── Build the accrual at the current stage, honoring the disabled set ──
func _rebuild() -> void:
	if _accrual == null:
		return
	# Clear the host IMMEDIATELY (free, not queue_free). apply() internally
	# uses queue_free which defers to frame-end; since the scrubber re-applies
	# multiple times per frame (stage-set then solo, or rapid key steps), the
	# deferred frees would collide on the "BiomeAccrual" node name and pile up
	# suffixed leftovers. Immediate free guarantees a clean slate each rebuild.
	for c in _host.get_children():
		_host.remove_child(c)
		c.free()
	if _accrual.has_method("set_stage_override"):
		_accrual.set_stage_override(_stage)
	# Sync our disabled mirror into the manager before apply.
	if _accrual.has_method("enable_layer"):
		for k in _order_of_kind.keys():
			_accrual.enable_layer(k, not _disabled.has(k))
	var dims := Vector3i(grid_w, 1, grid_d)
	_accrual.apply(_host, {
		"grid_dims": dims,
		"grid_center": Vector3(float(grid_w) * cube_size * 0.5, 0.0, float(grid_d) * cube_size * 0.5),
		"cube_size": cube_size,
		"rng_seed": 0xB10E,  # stable seed so scrubbing is deterministic
		"map_name": _loaded_map if _loaded_map != "" else "BiomeScrubber",
		"biome_paint": _map_paint,
		"stage_order": _stage,
		# Pass only the map's PARAM overrides live — disable + stage are
		# driven by the scrubber's own mechanisms (enable_layer / override).
		"biome_overrides": {"params": _map_overrides.get("params", {})},
	})
	_refresh_active_kinds()
	_update_hud()
	_refresh_panel()


func _refresh_active_kinds() -> void:
	# The kinds the manager WOULD apply at this stage (order ≤ stage), in
	# table order — independent of disabled state, so toggling a layer off
	# doesn't make its row vanish.
	_active_kinds.clear()
	for entry in _contribs:
		var o := int(entry.get("order", 0))
		if o > _stage:
			break
		if bool(entry.get("lab_only", false)):
			continue
		_active_kinds.append(str(entry.get("kind", "")))
	_selected = clampi(_selected, 0, maxi(0, _active_kinds.size() - 1))


func _set_stage(n: int) -> void:
	var c := clampi(n, MIN_STAGE, MAX_STAGE)
	if c == _stage: return
	_stage = c
	_rebuild()


# ── Layer inspection ──────────────────────────────────────────────────
func _toggle_selected() -> void:
	if _selected < 0 or _selected >= _active_kinds.size(): return
	var k: String = _active_kinds[_selected]
	if _disabled.has(k): _disabled.erase(k)
	else: _disabled[k] = true
	_rebuild()


func _solo_layer(kind: String) -> void:
	# Disable everything except `kind`.
	_disabled.clear()
	for k in _active_kinds:
		if k != kind:
			_disabled[k] = true
	# `kind` may not be in active list (CLI solo at a higher stage) — also
	# disable all known kinds except it.
	for k in _order_of_kind.keys():
		if k != kind:
			_disabled[k] = true
	_rebuild()


func _solo_selected() -> void:
	if _selected >= 0 and _selected < _active_kinds.size():
		_solo_layer(_active_kinds[_selected])


func _all_on() -> void:
	_disabled.clear()
	_rebuild()


## Write the current edits (disabled layers + stage) back into the map's
## settings.biome_overrides. The sequence still provides the default; this
## is the map's delta on top. Preserves any param/add overrides already
## in the file. res:// is writable in dev/editor (read-only in export).
func _save_overrides() -> void:
	if _loaded_map == "" or _map_data.is_empty():
		_status_msg = "no map loaded — load with --map=<Name> to save"
		_update_hud()
		return
	var ov: Dictionary = {}
	var dis: Array = []
	for k in _disabled.keys():
		dis.append(k)
	if not dis.is_empty():
		ov["disable"] = dis
	ov["stage_order"] = _stage
	# Preserve param/add overrides that the scrubber doesn't edit yet.
	if _map_overrides.has("params"):
		ov["params"] = _map_overrides["params"]
	if _map_overrides.has("add"):
		ov["add"] = _map_overrides["add"]
	var settings: Dictionary = _map_data.get("settings", {})
	settings["biome_overrides"] = ov
	_map_data["settings"] = settings
	var path := "res://commons/maps/%s/map_data.json" % _loaded_map
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_status_msg = "SAVE FAILED (read-only?): %s" % path
		_update_hud()
		push_warning("BiomeScrubber: could not write %s" % path)
		return
	f.store_string(JSON.stringify(_map_data, "\t"))
	f.close()
	_map_overrides = ov
	_status_msg = "✓ saved biome_overrides → %s  (disable=%d, stage=%d)" % [_loaded_map, dis.size(), _stage]
	_update_hud()
	print("[scrubber] saved overrides to %s: %s" % [_loaded_map, str(ov)])


# ── HUD + side panel ──────────────────────────────────────────────────
func _update_hud() -> void:
	var seq_name := _seq_of_kind_for_stage()
	var truth := _truth_for_stage()
	var on := 0
	for k in _active_kinds:
		if not _disabled.has(k): on += 1
	var lines := []
	var where := "map: %s (%d×%d)" % [_loaded_map, grid_w, grid_d] if _loaded_map != "" else "synthetic %d×%d" % [grid_w, grid_d]
	lines.append("BIOME SCRUBBER   stage %d / %d   [ %s ]   layers %d/%d on   %s" % [
		_stage, MAX_STAGE, seq_name, on, _active_kinds.size(), where])
	if truth != "":
		lines.append("“%s”" % truth)
	var save_hint := "  W save→map" if _loaded_map != "" else ""
	lines.append("] step  ↑↓ select  Space toggle  S solo  A all  R reset%s  Tab panel" % save_hint)
	if _status_msg != "":
		lines.append(_status_msg)
	_set_hud("\n".join(lines))


func _refresh_panel() -> void:
	if _panel == null: return
	for c in _panel.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "LAYERS (↑↓ select · Space toggle · S solo)"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	_panel.add_child(title)
	for i in range(_active_kinds.size()):
		var k: String = _active_kinds[i]
		var row := Label.new()
		var order: int = _order_of_kind.get(k, 0)
		var seq: String = _seq_of_kind.get(k, "")
		var mark := "▶ " if i == _selected else "  "
		var state := "·" if _disabled.has(k) else "●"
		row.text = "%s%s %02d %s" % [mark, state, order, k]
		row.add_theme_font_size_override("font_size", 13)
		var col := Color(0.45, 0.47, 0.52) if _disabled.has(k) else Color(0.9, 0.94, 1.0)
		if i == _selected:
			col = Color(1.0, 0.78, 0.35)
		row.add_theme_color_override("font_color", col)
		row.tooltip_text = seq
		_panel.add_child(row)


func _seq_of_kind_for_stage() -> String:
	for entry in _contribs:
		if int(entry.get("order", -1)) == _stage:
			return str(entry.get("seq", "?"))
	return "?"


func _truth_for_stage() -> String:
	for entry in _contribs:
		if int(entry.get("order", -1)) == _stage:
			return str(entry.get("truth", ""))
	return ""


func _set_hud(text: String) -> void:
	if _hud: _hud.text = text


func _commafy(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out


# ── Input ─────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_BRACKETRIGHT, KEY_RIGHT: _set_stage(_stage + 1)
			KEY_BRACKETLEFT, KEY_LEFT:   _set_stage(_stage - 1)
			KEY_MINUS:  _set_stage(MIN_STAGE)
			KEY_EQUAL:  _set_stage(MAX_STAGE)
			KEY_UP:     _select(-1)
			KEY_DOWN:   _select(1)
			KEY_SPACE:  _toggle_selected()
			KEY_S:      _solo_selected()
			KEY_A:      _all_on()
			KEY_W:      _save_overrides()
			KEY_TAB:
				if _panel_root: _panel_root.visible = not _panel_root.visible
			KEY_R:
				if _accrual.has_method("reset_overrides"): _accrual.reset_overrides()
				_disabled.clear(); _rebuild()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				_set_stage(event.keycode - KEY_0)
			KEY_0: _set_stage(10)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_radius = maxf(2.0, _orbit_radius - 1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_radius += 1.5
	elif event is InputEventMouseMotion and _dragging:
		_orbit_yaw -= event.relative.x * 0.006
		_orbit_pitch = clampf(_orbit_pitch - event.relative.y * 0.006, -1.4, -0.05)


func _select(delta: int) -> void:
	if _active_kinds.is_empty(): return
	_selected = wrapi(_selected + delta, 0, _active_kinds.size())
	_refresh_panel()
	_update_hud()


# ── Per-frame camera orbit + capture countdown ───────────────────────
func _process(delta: float) -> void:
	if auto_spin and not _dragging:
		_orbit_yaw += spin_speed * delta
	if _camera:
		var x := _orbit_center.x + _orbit_radius * cos(_orbit_pitch) * sin(_orbit_yaw)
		var y := _orbit_center.y - _orbit_radius * sin(_orbit_pitch)
		var z := _orbit_center.z + _orbit_radius * cos(_orbit_pitch) * cos(_orbit_yaw)
		_camera.position = Vector3(x, y, z)
		_camera.look_at(_orbit_center, Vector3.UP)
	if _perf:
		var dc := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var obj := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		var prim := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		_perf.text = "draw calls: %d   objects: %d   prims: %s" % [dc, obj, _commafy(prim)]
	if _capture_frames > 0:
		_capture_frames -= 1
		if _capture_frames == 0:
			var p: String = _shot_path
			if p == "" and _solo_one != "":
				p = "user://biome_solo_%s.png" % _solo_one
			_take_screenshot(p)
			get_tree().quit()


# ── Scene construction ────────────────────────────────────────────────
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.57, 0.62)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)


func _build_light() -> void:
	var dl := DirectionalLight3D.new()
	dl.name = "Sun"
	dl.rotation = Vector3(deg_to_rad(-52), deg_to_rad(38), 0)
	dl.light_energy = 1.05
	dl.shadow_enabled = true
	add_child(dl)


func _build_floor() -> void:
	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "ReferenceFloor"
	var pm := PlaneMesh.new()
	pm.size = Vector2(float(grid_w) * cube_size * 2.4, float(grid_d) * cube_size * 2.4)
	floor_mi.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.13, 0.16)
	mat.roughness = 0.95
	floor_mi.material_override = mat
	floor_mi.position = Vector3(_orbit_center.x, -0.02, _orbit_center.z)
	add_child(floor_mi)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "PreviewCamera"
	_camera.fov = 60.0
	_camera.current = true
	add_child(_camera)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	# Top status bar.
	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0, 0.45)
	bar.anchor_right = 1.0
	bar.offset_bottom = 64.0
	layer.add_child(bar)
	_hud = Label.new()
	_hud.position = Vector2(16, 8)
	_hud.add_theme_font_size_override("font_size", 15)
	_hud.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	layer.add_child(_hud)
	# Live perf readout (bottom-left) — draw calls + object count this
	# frame. The whole point of a perf tool: see the cost as you scrub.
	_perf = Label.new()
	_perf.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_perf.position = Vector2(16, -28)
	_perf.add_theme_font_size_override("font_size", 14)
	_perf.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
	layer.add_child(_perf)
	# Right-side layer panel.
	_panel_root = PanelContainer.new()
	_panel_root.anchor_left = 1.0
	_panel_root.anchor_right = 1.0
	_panel_root.anchor_top = 0.0
	_panel_root.offset_left = -320.0
	_panel_root.offset_top = 72.0
	_panel_root.offset_right = -8.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.5)
	sb.content_margin_left = 10; sb.content_margin_right = 10
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	_panel_root.add_theme_stylebox_override("panel", sb)
	layer.add_child(_panel_root)
	_panel = VBoxContainer.new()
	_panel.add_theme_constant_override("separation", 2)
	_panel_root.add_child(_panel)


# ── Headless capture ─────────────────────────────────────────────────
func _take_screenshot(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	img.save_png(path)
	print("[scrubber] shot saved: %s" % path)


func _run_contact_sheet() -> void:
	# Accrual at each stage, all layers on.
	_disabled.clear()
	for s in range(MIN_STAGE, MAX_STAGE + 1):
		_stage = s
		_rebuild()
		for _i in range(45):
			await get_tree().process_frame
		_take_screenshot("%s_%02d.png" % [_contact_base, s])
	print("[scrubber] contact sheet complete")
	get_tree().quit()


func _run_solo_sheet() -> void:
	# Each layer ALONE at max stage — the dual of the contact sheet.
	_stage = MAX_STAGE
	_rebuild()
	var kinds := _active_kinds.duplicate()
	for k in kinds:
		_solo_layer(k)
		for _i in range(45):
			await get_tree().process_frame
		_take_screenshot("%s_%02d_%s.png" % [_solo_base, _order_of_kind.get(k, 0), k])
	print("[scrubber] solo sheet complete (%d layers)" % kinds.size())
	get_tree().quit()

class_name DressingRoomCatalog3D
extends Node3D

## Standalone 3D viewer for dressing rooms. The thing the catalog wasn't:
## no auto-rotate, close camera, see the staging clearly, cycle through
## valid rotations.
##
## Reads commons/artifacts/dressing_rooms/<name>.json, builds the scene
## via DressingRoomBuilder, frames it with a static-camera-then-orbit
## approach. Mouse drags orbit, scroll zooms — but never auto-spins.

const DressingRoomBuilderScript = preload("res://commons/artifacts/catalog/DressingRoomBuilder.gd")
const DressingRoomInspectorScript = preload("res://commons/artifacts/catalog/DressingRoomInspector.gd")

## Hotkeys.
@export var next_room_key: Key = KEY_N
@export var prev_room_key: Key = KEY_P
@export var next_rotation_key: Key = KEY_R
@export var reset_camera_key: Key = KEY_F
@export var toggle_overlay_key: Key = KEY_TAB
@export var toggle_inspector_key: Key = KEY_I
## AI capture hotkey — triggers /api/dressing-room POST against the
## encyclopedia dev server (default localhost:3003). Renders the current
## artifact's dressing room via Godot, returns mirror PNGs.
@export var ai_capture_key: Key = KEY_C
## Encyclopedia dev server origin. Override if running elsewhere.
@export var encyclopedia_origin: String = "http://localhost:3003"

## Camera tuning. The catalog's camera was distant + auto-orbited;
## this one snaps close, holds still, lets you orbit if you want.
@export_group("Camera")
@export var orbit_sensitivity: float = 0.006
@export var pan_sensitivity: float = 0.01
@export var zoom_sensitivity: float = 0.4
@export var zoom_min: float = 1.0
@export var zoom_max: float = 18.0
@export var initial_pitch_deg: float = 22.0      # gentle look-DOWN: +pitch puts the camera above the focus (y = dist*sin(pitch)), looking down at the artifact
@export var initial_yaw_deg: float = 30.0        # offset from front
@export var fit_padding: float = 0.45            # smaller = closer

@onready var _container: Node3D = $RoomContainer
@onready var _camera: Camera3D = $CameraRig/Camera3D
@onready var _camera_rig: Node3D = $CameraRig
@onready var _key_light: DirectionalLight3D = $KeyLight
@onready var _info_label: Label = $UI/Info
@onready var _hint_label: Label = $UI/Hints

var _rooms: Array[String] = []
var _index: int = 0
var _current_room_data: Dictionary = {}
var _current_rotation_index: int = 0
var _current_rotations: Array[int] = [0]
var _current_built: Node3D = null

# Inspector + tile-picking state.
var _inspector: PanelContainer = null
# The two side-panel holders — repositioned responsively by _refit_ui() so
# they always fit the current window (fixed pixel widths clipped on small
# windows / screens smaller than the launch window).
var _list_holder: Control = null
var _inspector_holder: Control = null
# Live "open this room" bridge: the web /dressing-rooms page writes a request
# file (via /api/dressing-rooms/open) and this running viewer polls it and
# jumps. A heartbeat file lets the API skip relaunching when one is already up.
const BRIDGE_REQUEST := "res://ada_run/dr_open_request.json"
const BRIDGE_HEARTBEAT := "res://ada_run/dr_viewer_alive.txt"
# Full parameter-control channel: the web UI (/dressing-rooms/live) writes
# {ts, room, set:{staged/posture/artifact_offset}, window:"float"|"normal"}
# and the running viewer applies it live — the good interface lives in the
# web window, this window is the always-correct 3D viewport.
const BRIDGE_CONTROL := "res://ada_run/dr_control.json"
var _bridge_timer: Timer
var _last_open_ts: float = 0.0
var _last_control_ts: float = 0.0
# Float mode: a clean always-on-top viewport showing ONLY the artifact + stage
# (no panels, no labels, no gizmo) — the web page is the interface. Launched
# with `-- --float`, or toggled by a control message.
var _float_mode: bool = false
# Translation gizmo — three axis arrows on the artifact; drag an arrow to move
# along that data axis, snapped to 0.25 m. Arrows point along the DATA axes
# (rotated into the world by the current room rotation) so a drag maps to one
# artifact_offset component.
const GIZMO_SNAP := 0.25
var _gizmo: Node3D = null
var _gizmo_arrows: Array = []          # [{root:Node3D, dir:Vector3, axis:int, mats:Array}]
var _gizmo_dragging: bool = false
var _gizmo_axis: int = -1              # 0=x 1=y 2=z (data space)
var _gizmo_axis_world: Vector3 = Vector3.ZERO
var _gizmo_line_origin: Vector3 = Vector3.ZERO
var _gizmo_t0: float = 0.0
var _gizmo_initial_offset: Vector3 = Vector3.ZERO
var _gizmo_art_start_pos: Vector3 = Vector3.ZERO
# STAGED mode renders the raised footing as its real station prop (a plinth is
# station_plinth) via the Element Catalog; blockout keeps the grey height-tile
# reading. [B] toggles — both views matter (the Sieve: don't seal the recipe).
var _staged: bool = true
var _pick_mode: String = "value"   # mirrors inspector's pick_mode_changed
var _tile_meta: Dictionary = {}    # MeshInstance3D → {row, col} for click-pick

# Left-panel room list state.
var _list_search: LineEdit = null
var _list_filter_btn: OptionButton = null
var _list_widget: ItemList = null
var _list_count_label: Label = null
var _filtered_indices: Array[int] = []   # indices into _rooms after filter
var _list_filter_mode: int = 0           # 0=all, 1=default-only, 2=customised, 3=has notes
# "by map" filter — which maps place which artifact, grouped by sequence
# (like /book by chapter). commons/data/artifact_maps.json.
var _map_index: Dictionary = {}
var _map_btn: OptionButton = null
var _map_option_dirs: Array = []         # OptionButton item idx -> map dir ("" = all/separator)
var _map_filter: String = ""             # selected map dir ("" = all maps)
var _map_artifacts: Dictionary = {}      # lookup -> true, for the selected map
var _staged_btn: CheckButton = null      # visible twin of the [B] hotkey
# Staging-DNA type selector — shows the current room's TYPE (specimen /
# instrument / performer / …) and lets you re-type it; Save persists.
var _type_btn: OptionButton = null
var _type_postures: Array = []           # item idx -> posture id ("" = none)

# Normalization-rule state.
var _rule_center_xz: CheckBox
var _rule_clamp_ground: CheckBox
var _rule_plinth_for_large: CheckBox
var _rule_footprint_from_aabb: CheckBox
var _rule_status: Label
var _rule_scope_btn: OptionButton             # 0=current, 1=filtered, 2=all
const LARGE_THRESHOLD_M: float = 1.5
## Above this, an offset patch is a symptom — the artifact itself is
## mis-authored and should be fixed in the .tscn / .gd, not papered over.
const ESCALATION_THRESHOLD_M: float = 0.3
const ESCALATION_REPORT_PATH: String = "res://doc/reports/dressing_room_escalations.md"

# Escalations collected during a rule run.
var _escalations: Array[Dictionary] = []

# Artifact-drag state.
var _is_dragging_artifact: bool = false
var _drag_anchor_world: Vector3 = Vector3.ZERO  # anchor cell's world centre at drag start
var _drag_initial_offset: Vector3 = Vector3.ZERO
var _drag_y_locked: bool = true     # left-drag = X/Z plane; shift-drag = Y

# Orbit state.
var _orbit_yaw: float = 0.0
var _orbit_pitch: float = 0.0
var _orbit_distance: float = 6.0
var _orbit_focus: Vector3 = Vector3(0, 0.5, 0)
var _is_orbiting: bool = false
var _is_panning: bool = false
var _last_mouse: Vector2 = Vector2.ZERO


func _ready() -> void:
	_orbit_yaw = deg_to_rad(initial_yaw_deg)
	_orbit_pitch = deg_to_rad(initial_pitch_deg)
	_fit_window_to_screen()
	_setup_inspector()
	_setup_room_list()
	# Re-fit the side panels whenever the window resizes, and once now.
	get_viewport().size_changed.connect(_refit_ui)
	call_deferred("_refit_ui")
	_rooms = DressingRoomBuilderScript.list_dressing_rooms()
	if _rooms.is_empty():
		_set_info("No dressing rooms found at\nres://commons/artifacts/dressing_rooms/")
		return
	# Optional `-- --room=<lookup>` to open straight to a specific room
	# (otherwise starts at the first alphabetically). N/P still cycle.
	for _a in OS.get_cmdline_user_args():
		var _s := String(_a).strip_edges()
		if _s.begins_with("--room="):
			var _i := _rooms.find(_s.substr(7))
			if _i >= 0:
				_index = _i
		elif _s == "--float":
			_float_mode = true
	_refresh_room_list()
	_load_room(_rooms[_index])
	_set_hints()
	if _float_mode:
		call_deferred("_apply_window_mode", "float")
	# Live bridge — ignore any pre-existing messages, then poll at 2 Hz.
	var existing = _bridge_read_json(BRIDGE_REQUEST)
	if existing is Dictionary:
		_last_open_ts = float(existing.get("ts", 0))
	var existing_ctl = _bridge_read_json(BRIDGE_CONTROL)
	if existing_ctl is Dictionary:
		_last_control_ts = float(existing_ctl.get("ts", 0))
	_bridge_timer = Timer.new()
	_bridge_timer.wait_time = 0.5
	_bridge_timer.autostart = true
	_bridge_timer.timeout.connect(_bridge_poll)
	add_child(_bridge_timer)


## Read a bridge JSON file, or null.
func _bridge_read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else null


## Emit a heartbeat (so the API knows a viewer is live) and, when the web
## page requests a different room, jump straight to it — no relaunch.
func _bridge_poll() -> void:
	var hb := FileAccess.open(BRIDGE_HEARTBEAT, FileAccess.WRITE)
	if hb:
		hb.store_string(str(Time.get_unix_time_from_system()))
		hb.close()
	# Live state write-back — the web UI reads this to confirm what the
	# viewer actually applied (room, staged, type, offset, pad footprint).
	var _tiles: Array = (_current_room_data.get("footing", {}) as Dictionary).get("tiles", [])
	var _prows: int = _tiles.size()
	var _pcols: int = 0
	for _row in _tiles:
		if _row is Array:
			_pcols = maxi(_pcols, (_row as Array).size())
	var st := FileAccess.open("res://ada_run/dr_viewer_state.json", FileAccess.WRITE)
	if st:
		st.store_string(JSON.stringify({
			"ts": Time.get_unix_time_from_system(),
			"pid": OS.get_process_id(),
			"room": str(_current_room_data.get("lookup_name", "")),
			"staged": _staged,
			"posture": str(_current_room_data.get("posture", "")),
			"artifact_offset": _current_room_data.get("artifact_offset", [0, 0, 0]),
			"rotation": (_current_rotations[_current_rotation_index] if not _current_rotations.is_empty() else 0),
			"rotations": _current_rotations,
			"pad": [_pcols, _prows],
			"show_base": bool(_current_room_data.get("show_base", true)),
			"show_light": bool(_current_room_data.get("show_light", true)),
			"show_info": bool(_current_room_data.get("show_info", true)),
			"light_mode": str(_current_room_data.get("light_mode", "glow")),
		}))
		st.close()
	var req = _bridge_read_json(BRIDGE_REQUEST)
	if req is Dictionary:
		var ts := float(req.get("ts", 0))
		var room := str(req.get("room", ""))
		if ts > _last_open_ts and not room.is_empty():
			_last_open_ts = ts
			var idx := _rooms.find(room)
			if idx >= 0:
				_index = idx
				_load_room(_rooms[_index])
				if _list_widget and _filtered_indices.has(_index):
					_list_widget.select(_filtered_indices.find(_index))
	var ctl = _bridge_read_json(BRIDGE_CONTROL)
	if ctl is Dictionary:
		var cts := float(ctl.get("ts", 0))
		if cts > _last_control_ts:
			_last_control_ts = cts
			_apply_control(ctl)


## Apply a web-UI control message to the live scene.
func _apply_control(msg: Dictionary) -> void:
	# Jump to the named room first if it isn't the current one.
	var room := str(msg.get("room", ""))
	if room != "" and str(_current_room_data.get("lookup_name", "")) != room:
		var idx := _rooms.find(room)
		if idx >= 0:
			_index = idx
			_load_room(_rooms[_index])
	var s = msg.get("set", {})
	if s is Dictionary and not s.is_empty() and not _current_room_data.is_empty():
		var changed := false
		if s.has("staged"):
			_staged = bool(s["staged"])
			if _staged_btn:
				_staged_btn.set_pressed_no_signal(_staged)
			changed = true
		if s.has("posture"):
			var p := str(s["posture"])
			if p == "":
				_current_room_data.erase("posture")
			else:
				_current_room_data["posture"] = p
			if _type_btn:
				var ti: int = _type_postures.find(p)
				_type_btn.select(ti if ti >= 0 else 0)
			changed = true
		if s.has("artifact_offset") and s["artifact_offset"] is Array and (s["artifact_offset"] as Array).size() >= 3:
			var ao: Array = s["artifact_offset"]
			_current_room_data["artifact_offset"] = [float(ao[0]), float(ao[1]), float(ao[2])]
			changed = true
		if s.has("pad") and s["pad"] is Array and (s["pad"] as Array).size() >= 2:
			_resize_pad(maxi(1, int(s["pad"][0])), maxi(1, int(s["pad"][1])))
			changed = true
		# Composition toggles — base prop / light / info board / light mode.
		if s.has("show_base"):
			_current_room_data["show_base"] = bool(s["show_base"]); changed = true
		if s.has("show_light"):
			_current_room_data["show_light"] = bool(s["show_light"]); changed = true
		if s.has("show_info"):
			_current_room_data["show_info"] = bool(s["show_info"]); changed = true
		if s.has("light_mode"):
			_current_room_data["light_mode"] = str(s["light_mode"]); changed = true
		if changed:
			if _inspector:
				_inspector.sync_data(_current_room_data)
				_inspector._mark_dirty()
			_rebuild_with_rotation()
	var wm := str(msg.get("window", ""))
	if wm != "":
		_apply_window_mode(wm)
	# One-shot actions — the same verbs the [N]/[P]/[R]/[F] hotkeys and the
	# Save bar give in the window, so the web page can drive them too.
	match str(msg.get("action", "")):
		"rotate":
			_advance_rotation()
		"reset_camera":
			_orbit_yaw = deg_to_rad(initial_yaw_deg)
			_orbit_pitch = deg_to_rad(initial_pitch_deg)
			_frame_built()
		"next_room":
			_advance_room(1)
		"prev_room":
			_advance_room(-1)
		"save":
			_on_save_requested()
		"center_xz", "clamp_floor", "derive_footprint":
			_apply_normalize(str(msg.get("action", "")))


## Run ONE Normalize rule on the CURRENT room (the web brings the Godot
## "Cross-cutting rules" over): measure the live artifact AABB, then
##   center_xz       → artifact_offset.x/z = -AABB centre (recentre on anchor)
##   clamp_floor     → artifact_offset.y   = -AABB.min.y (lowest point on surface)
##   derive_footprint→ resize the pad to the measured extent + a walkable margin
## Writes _current_room_data, marks dirty, rebuilds; the new offset/pad flow
## back to the web through the state write-back.
func _apply_normalize(op: String) -> void:
	if _current_room_data.is_empty():
		return
	var lookup := str(_current_room_data.get("lookup_name", ""))
	var aabb := _measure_artifact_aabb(lookup)
	if aabb.size.length_squared() < 1e-6:
		_set_info("normalize: couldn't measure %s" % lookup)
		return
	var off: Array = _current_room_data.get("artifact_offset", [0.0, 0.0, 0.0])
	while off.size() < 3:
		off.append(0.0)
	var ov := Vector3(float(off[0]), float(off[1]), float(off[2]))
	match op:
		"center_xz":
			ov.x = -aabb.get_center().x
			ov.z = -aabb.get_center().z
			_current_room_data["artifact_offset"] = [ov.x, ov.y, ov.z]
		"clamp_floor":
			ov.y = -aabb.position.y
			_current_room_data["artifact_offset"] = [ov.x, ov.y, ov.z]
		"derive_footprint":
			var fw: int = clampi(int(ceil(aabb.size.x)) + 2, 1, 9)
			var fd: int = clampi(int(ceil(aabb.size.z)) + 2, 1, 9)
			_resize_pad(fw, fd)
	if _inspector:
		_inspector.sync_data(_current_room_data)
		_inspector._mark_dirty()
	_rebuild_with_rotation()
	_set_info("normalize: %s applied" % op)


## "float" = a small always-on-top viewport showing ONLY the artifact + stage
## (the whole UI CanvasLayer + the gizmo hidden — the web page is the
## interface); "normal" = the full editor window back.
## A window embedded in the editor's game viewport (or as a subwindow) rejects
## resize / move / always-on-top and spams "Embedded window can't ..." warnings.
## Detect it so we skip the OS-window ops and only apply the in-scene view.
func _window_is_embedded() -> bool:
	var w: Window = get_window()
	return w != null and w.is_embedded()


func _apply_window_mode(mode: String) -> void:
	var embedded: bool = _window_is_embedded()
	if mode == "float":
		_float_mode = true
		if not embedded:                              # OS window ops fail if embedded
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
			DisplayServer.window_set_size(Vector2i(640, 560))
			DisplayServer.window_set_position(Vector2i(60, 60))
		if has_node("UI"):
			($UI as CanvasLayer).visible = false     # all panels + labels
		if _gizmo: _gizmo.visible = false             # no editing aids
		_frame_built()                                # re-centre on the artifact
	elif mode == "normal":
		_float_mode = false
		if not embedded:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, false)
			_fit_window_to_screen()
		if has_node("UI"):
			($UI as CanvasLayer).visible = true
		if _gizmo: _gizmo.visible = true
		_refit_ui()


## If the launch window is bigger than the usable screen, its right/bottom
## edges (inspector + save bar) fall off-screen. Shrink + move it on-screen.
func _fit_window_to_screen() -> void:
	if _window_is_embedded():
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return
	var scr: Vector2i = DisplayServer.screen_get_usable_rect(
		DisplayServer.window_get_current_screen()).size
	var win: Vector2i = DisplayServer.window_get_size()
	if win.x > scr.x or win.y > scr.y:
		DisplayServer.window_set_size(Vector2i(
			mini(win.x, scr.x - 40), mini(win.y, scr.y - 60)))
		DisplayServer.window_set_position(Vector2i(20, 20))


## Position the two side panels as a fraction of the current window width so
## they always fit — and never overlap the 3D view or clip off the edges.
func _refit_ui() -> void:
	var w: float = get_viewport().get_visible_rect().size.x
	var list_w: float = clampf(w * 0.22, 200.0, 300.0)
	# Floor of 460 = the inspector content's natural min width; a narrower
	# holder lets the panel grow past its right edge (Save bar off-screen).
	var insp_w: float = clampf(w * 0.36, 460.0, 480.0)
	# Guarantee a central gutter for the 3D view; shrink both panels if tight.
	var gutter: float = 200.0
	if list_w + insp_w + gutter > w:
		var s: float = maxf(0.0, w - gutter) / maxf(1.0, list_w + insp_w)
		list_w *= s
		insp_w *= s
	if _list_holder:
		_list_holder.offset_left = 16
		_list_holder.offset_right = 16 + list_w
	if _inspector_holder:
		_inspector_holder.offset_left = -insp_w - 16
		_inspector_holder.offset_right = -16


func _setup_room_list() -> void:
	if not has_node("UI"):
		return
	var ui: CanvasLayer = $UI
	var holder := Control.new()
	holder.name = "RoomListHolder"
	holder.anchor_left = 0.0
	holder.anchor_right = 0.0
	holder.anchor_top = 0.0
	holder.anchor_bottom = 1.0
	holder.offset_left = 16
	holder.offset_right = 16 + 280
	holder.offset_top = 70   # leave room for the Info label
	holder.offset_bottom = -16
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	ui.add_child(holder)
	_list_holder = holder   # width set responsively in _refit_ui()

	var panel := PanelContainer.new()
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = Color(0.13, 0.13, 0.16, 0.96)
	pbg.border_color = Color(0.08, 0.08, 0.10)
	pbg.border_width_left = 1
	pbg.border_width_top = 1
	pbg.border_width_right = 1
	pbg.border_width_bottom = 1
	pbg.content_margin_left = 6
	pbg.content_margin_right = 6
	pbg.content_margin_top = 6
	pbg.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", pbg)
	holder.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var title := Label.new()
	title.text = "Dressing rooms"
	title.add_theme_color_override("font_color", Color(0.85, 0.86, 0.90))
	v.add_child(title)

	_list_search = LineEdit.new()
	_list_search.placeholder_text = "filter (lookup name)…"
	_list_search.text_changed.connect(func(_t): _refresh_room_list())
	v.add_child(_list_search)

	_list_filter_btn = OptionButton.new()
	_list_filter_btn.add_item("show: all")
	_list_filter_btn.add_item("show: default-only (1×1 plinth)")
	_list_filter_btn.add_item("show: customised")
	_list_filter_btn.add_item("show: has notes")
	_list_filter_btn.item_selected.connect(func(idx):
		_list_filter_mode = idx
		_refresh_room_list()
	)
	v.add_child(_list_filter_btn)

	# "by map" menu — pick a sequence's map, see only rooms it places.
	_load_map_index()
	_map_btn = OptionButton.new()
	_map_option_dirs = []
	_map_btn.add_item("map: all")
	_map_option_dirs.append("")
	var maps_meta: Dictionary = _map_index.get("maps", {})
	for s in (_map_index.get("sequences", []) as Array):
		if not (s is Dictionary):
			continue
		_map_btn.add_separator(str(s.get("name", s.get("seq", ""))))
		_map_option_dirs.append("")   # keep idx aligned with items
		for m in (s.get("maps", []) as Array):
			var meta = maps_meta.get(m, {})
			var disp: String = str(meta.get("name", m)) if meta is Dictionary else str(m)
			var n: int = int(meta.get("n", 0)) if meta is Dictionary else 0
			_map_btn.add_item("  %s (%d)" % [disp, n])
			_map_option_dirs.append(str(m))
	_map_btn.item_selected.connect(func(idx):
		_map_filter = str(_map_option_dirs[idx]) if idx < _map_option_dirs.size() else ""
		_rebuild_map_artifacts()
		_refresh_room_list()
	)
	v.add_child(_map_btn)

	# Visible plinth/prop toggle (same as the [B] hotkey): blockout footing
	# tiles vs the real station prop from the Element Catalog.
	_staged_btn = CheckButton.new()
	_staged_btn.text = "station prop (B)"
	_staged_btn.tooltip_text = "ON: raised footing renders as its real station prop (a plinth is station_plinth).\nOFF: grey blockout height tiles."
	_staged_btn.button_pressed = _staged
	_staged_btn.toggled.connect(func(on: bool):
		_staged = on
		_rebuild_with_rotation()
	)
	v.add_child(_staged_btn)

	# DNA type selector — the seven staging templates. Changing it re-types
	# the room (writes `posture`; Save persists) and rebuilds the staging.
	_type_btn = OptionButton.new()
	_type_btn.tooltip_text = "Staging-DNA type: which environment template hosts this artifact (commons/data/staging_dna.json)."
	_type_btn.add_item("dna: (untyped)")
	_type_postures = [""]
	var dna_templates := DressingRoomBuilderScript.load_staging_dna()
	var posture_keys: Array = dna_templates.keys()
	posture_keys.sort()
	for p in posture_keys:
		var t: Dictionary = dna_templates[p]
		_type_btn.add_item("dna: %s (%s)" % [str(t.get("_type", p)), str(p)])
		_type_postures.append(str(p))
	_type_btn.item_selected.connect(func(idx):
		if _current_room_data.is_empty():
			return
		var p := str(_type_postures[idx]) if idx < _type_postures.size() else ""
		if p == "":
			_current_room_data.erase("posture")
		else:
			_current_room_data["posture"] = p
		if _inspector:
			_inspector._mark_dirty()
		_rebuild_with_rotation()
	)
	v.add_child(_type_btn)

	_list_count_label = Label.new()
	_list_count_label.text = "—"
	_list_count_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	v.add_child(_list_count_label)

	_list_widget = ItemList.new()
	_list_widget.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_widget.item_selected.connect(_on_room_list_selected)
	v.add_child(_list_widget)

	# ── Normalize rules ───────────────────────────────────────────────
	var sep := HSeparator.new()
	v.add_child(sep)
	var rule_title := Label.new()
	rule_title.text = "Normalize"
	rule_title.add_theme_color_override("font_color", Color(0.85, 0.86, 0.90))
	v.add_child(rule_title)
	var rule_hint := Label.new()
	rule_hint.text = "Cross-cutting rules. Measures the artifact's AABB, then writes artifact_offset / footing as needed."
	rule_hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	rule_hint.add_theme_font_size_override("font_size", 11)
	rule_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(rule_hint)

	_rule_center_xz = CheckBox.new()
	_rule_center_xz.text = "center on X/Z (AABB centre → anchor)"
	_rule_center_xz.button_pressed = true
	v.add_child(_rule_center_xz)

	_rule_clamp_ground = CheckBox.new()
	_rule_clamp_ground.text = "clamp lowest point to anchor surface"
	_rule_clamp_ground.button_pressed = true
	v.add_child(_rule_clamp_ground)

	_rule_plinth_for_large = CheckBox.new()
	_rule_plinth_for_large.text = "plinth if width/depth > %.1f m" % LARGE_THRESHOLD_M
	v.add_child(_rule_plinth_for_large)

	_rule_footprint_from_aabb = CheckBox.new()
	_rule_footprint_from_aabb.text = "derive footprint cells from AABB"
	v.add_child(_rule_footprint_from_aabb)

	_rule_scope_btn = OptionButton.new()
	_rule_scope_btn.add_item("scope: current room")
	_rule_scope_btn.add_item("scope: filtered list")
	_rule_scope_btn.add_item("scope: all rooms")
	v.add_child(_rule_scope_btn)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 4)
	v.add_child(btn_row)
	var preview_btn := Button.new()
	preview_btn.text = "preview"
	preview_btn.pressed.connect(func(): _run_rules(false))
	btn_row.add_child(preview_btn)
	var apply_btn := Button.new()
	apply_btn.text = "apply"
	apply_btn.pressed.connect(func(): _run_rules(true))
	btn_row.add_child(apply_btn)

	_rule_status = Label.new()
	_rule_status.text = ""
	_rule_status.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	_rule_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(_rule_status)


func _on_room_list_selected(item_idx: int) -> void:
	if item_idx < 0 or item_idx >= _filtered_indices.size():
		return
	var room_idx: int = _filtered_indices[item_idx]
	_index = room_idx
	_load_room(_rooms[_index])


# Returns true if the room JSON is still the canonical 1×1 plinth default.
func _is_default_room(room_name: String) -> bool:
	var path := "res://commons/artifacts/dressing_rooms/%s.json" % room_name
	var raw := FileAccess.get_file_as_string(path)
	if raw.is_empty():
		return false
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return false
	var d: Dictionary = parsed
	# Default signature: 3×3 footing with anchor [1,1] and tiles centre = 3.
	var fp: Array = d.get("footprint", [])
	if fp != [1, 1, 1]:
		return false
	var footing: Dictionary = d.get("footing", {})
	if footing.get("anchor", []) != [1, 1]:
		return false
	var tiles = footing.get("tiles", [])
	if tiles is Array and tiles.size() == 3:
		var center_row = tiles[1]
		if center_row is Array and center_row.size() == 3 and int(center_row[1]) == 3:
			var extras = d.get("extras", [])
			if extras is Array and extras.is_empty():
				return true
	return false


func _has_notes(room_name: String) -> bool:
	var path := "res://commons/artifacts/dressing_rooms/%s.json" % room_name
	var raw := FileAccess.get_file_as_string(path)
	if raw.is_empty():
		return false
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return false
	var notes = parsed.get("notes", null)
	if notes is Dictionary:
		var text := str(notes.get("text", ""))
		var tags = notes.get("tags", [])
		return not text.is_empty() or (tags is Array and not tags.is_empty())
	return false


# ──────────────────────────────────────────────────────────────────────
# Normalization rules — measure artifact AABB, mutate the room JSON
# ──────────────────────────────────────────────────────────────────────

# Loads an artifact's scene off-tree, packs/instantiates it inside a
# throwaway parent at the origin, computes the local-space AABB, then
# frees it. Returns AABB() (zero-sized) on any failure.
func _measure_artifact_aabb(lookup: String) -> AABB:
	var info: Dictionary = _lookup_artifact_info(lookup)
	if info.is_empty():
		return AABB()
	var scene_path: String = str(info.get("scene", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return AABB()
	var ps: PackedScene = load(scene_path) as PackedScene
	if ps == null:
		return AABB()
	var inst = ps.instantiate()
	if inst == null:
		return AABB()
	# Parent it transiently so transforms resolve, then measure.
	var sandbox := Node3D.new()
	add_child(sandbox)
	sandbox.add_child(inst)
	# Walk meshes for AABB in inst-local space.
	var combined := AABB()
	var first := true
	var stack: Array = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var mi: MeshInstance3D = n
			# Transform local AABB by the mesh's transform RELATIVE TO inst.
			var rel: Transform3D = sandbox.global_transform.affine_inverse() * mi.global_transform
			var aabb := rel * mi.get_aabb()
			if first:
				combined = aabb
				first = false
			else:
				combined = combined.merge(aabb)
		for c in n.get_children():
			stack.append(c)
	sandbox.queue_free()
	return combined


# Apply rules to a single room dict in place. Returns a string summary of
# changes for logging, or "" if nothing changed.
func _apply_rules_to_room(d: Dictionary, lookup: String) -> String:
	var aabb: AABB = _measure_artifact_aabb(lookup)
	if aabb.size.length_squared() < 1e-6:
		return "[%s] could not measure (no scene / empty mesh)" % lookup
	var changes: Array[String] = []
	var off: Array = d.get("artifact_offset", [0.0, 0.0, 0.0])
	while off.size() < 3:
		off.append(0.0)
	var off_v := Vector3(float(off[0]), float(off[1]), float(off[2]))
	# Reasons collected if the patch we'd apply is too big to be cosmetic.
	var escalation_reasons: Array[String] = []

	if _rule_center_xz and _rule_center_xz.button_pressed:
		var cx: float = -aabb.get_center().x
		var cz: float = -aabb.get_center().z
		if absf(cx) > ESCALATION_THRESHOLD_M or absf(cz) > ESCALATION_THRESHOLD_M:
			escalation_reasons.append(
				"mesh AABB centre is offset (%.2f, %.2f) from origin — recentre in the artifact's scene/script" % [-cx, -cz])
		if absf(off_v.x - cx) > 0.005 or absf(off_v.z - cz) > 0.005:
			off_v.x = cx
			off_v.z = cz
			changes.append("center→(%.2f,%.2f)" % [cx, cz])

	if _rule_clamp_ground and _rule_clamp_ground.button_pressed:
		# Lift so the lowest point sits at the anchor's top surface.
		var dy: float = -aabb.position.y
		if absf(dy) > ESCALATION_THRESHOLD_M:
			escalation_reasons.append(
				"AABB.y (%.2f) is far from 0 — body sinks into floor or floats; fix mesh origin in the artifact" % aabb.position.y)
		if absf(off_v.y - dy) > 0.005:
			off_v.y = dy
			changes.append("y→%.2f" % dy)

	if not changes.is_empty():
		d["artifact_offset"] = [off_v.x, off_v.y, off_v.z]

	# If we had to patch by more than the threshold, record an escalation.
	if not escalation_reasons.is_empty():
		var info := _lookup_artifact_info(lookup)
		_escalations.append({
			"lookup": lookup,
			"scene": str(info.get("scene", "")),
			"reasons": escalation_reasons,
			"aabb_min": [aabb.position.x, aabb.position.y, aabb.position.z],
			"aabb_size": [aabb.size.x, aabb.size.y, aabb.size.z],
		})
		# Also tag the room so the "has notes" filter surfaces it.
		var notes: Dictionary = d.get("notes", {}) if d.get("notes") is Dictionary else {}
		var tag_list: Array = notes.get("tags", [])
		if not tag_list.has("artifact-needs-fix"):
			tag_list.append("artifact-needs-fix")
		notes["tags"] = tag_list
		# Append the most recent reason to the free-text notes so it's visible.
		var prior_text := str(notes.get("text", ""))
		var new_line: String = "[auto] " + escalation_reasons[0]
		if not prior_text.contains(new_line):
			notes["text"] = (prior_text + ("\n" if not prior_text.is_empty() else "") + new_line)
		d["notes"] = notes
		changes.append("escalated×%d" % escalation_reasons.size())

	var w: float = aabb.size.x
	var depth: float = aabb.size.z
	if _rule_plinth_for_large and _rule_plinth_for_large.button_pressed:
		if max(w, depth) > LARGE_THRESHOLD_M:
			var footing: Dictionary = d.get("footing", {})
			var anchor: Array = footing.get("anchor", [1, 1])
			var tiles: Array = footing.get("tiles", [[1]])
			var ar: int = int(anchor[0])
			var ac: int = int(anchor[1])
			if ar < tiles.size() and tiles[ar] is Array and ac < tiles[ar].size():
				if int(tiles[ar][ac]) != 3:
					tiles[ar][ac] = 3
					footing["tiles"] = tiles
					d["footing"] = footing
					changes.append("plinth@anchor")

	if _rule_footprint_from_aabb and _rule_footprint_from_aabb.button_pressed:
		# 1 cell ≈ 1 metre. Round up; clamp to [1, 6].
		var fw: int = clampi(int(ceil(w)), 1, 6)
		var fd: int = clampi(int(ceil(depth)), 1, 6)
		var fh: int = clampi(int(ceil(aabb.size.y)), 1, 6)
		var fp: Array = d.get("footprint", [1, 1, 1])
		if fp != [fw, fd, fh]:
			d["footprint"] = [fw, fd, fh]
			changes.append("footprint→[%d,%d,%d]" % [fw, fd, fh])

	if changes.is_empty():
		return ""
	return "[%s] %s" % [lookup, ", ".join(changes)]


# `apply=false` previews (logs but doesn't write). `apply=true` writes JSONs.
func _run_rules(apply_changes: bool) -> void:
	if _rule_status == null:
		return
	var scope: int = _rule_scope_btn.selected if _rule_scope_btn else 0
	var indices: Array[int] = []
	match scope:
		0:
			indices = [_index]
		1:
			indices = _filtered_indices.duplicate()
		_:
			for i in range(_rooms.size()):
				indices.append(i)
	if indices.is_empty():
		_rule_status.text = "no rooms in scope"
		return

	var any_rule := (_rule_center_xz.button_pressed or _rule_clamp_ground.button_pressed
		or _rule_plinth_for_large.button_pressed or _rule_footprint_from_aabb.button_pressed)
	if not any_rule:
		_rule_status.text = "no rules selected"
		return

	# Reset the escalation accumulator for this run.
	_escalations.clear()

	var changed: int = 0
	var total: int = indices.size()
	var summary_lines: Array[String] = []
	_rule_status.text = "%s %d rooms…" % ["applying" if apply_changes else "previewing", total]
	for idx in indices:
		var lookup: String = _rooms[idx]
		var data: Variant = DressingRoomBuilderScript.load_dressing_room(lookup)
		if not (data is Dictionary):
			continue
		var d: Dictionary = data
		var msg: String = _apply_rules_to_room(d, lookup)
		if msg != "":
			changed += 1
			if summary_lines.size() < 8:
				summary_lines.append(msg)
			print("  ", msg)
			if apply_changes:
				var path := "res://commons/artifacts/dressing_rooms/%s.json" % lookup
				var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
				if f != null:
					f.store_string(JSON.stringify(d, "\t"))
					f.close()
	var verb := "applied" if apply_changes else "preview"
	var escalation_msg := ""
	if not _escalations.is_empty():
		escalation_msg = "\n%d escalation(s) → %s" % [_escalations.size(), ESCALATION_REPORT_PATH]
		if apply_changes:
			_write_escalation_report()
	_rule_status.text = "%s: %d / %d changed%s\n%s" % [
		verb, changed, total, escalation_msg, "\n".join(summary_lines)]
	# Reload current room so user sees the result.
	if apply_changes and _index in indices:
		_load_room(_rooms[_index])
	_refresh_room_list()


# Append (or create) the escalation report. One section per artifact. We
# don't dedupe — running again overwrites with fresh state, so the report
# always reflects the latest sweep.
func _write_escalation_report() -> void:
	if _escalations.is_empty():
		return
	# Make sure the parent dir exists.
	var dir_path: String = ESCALATION_REPORT_PATH.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var f: FileAccess = FileAccess.open(ESCALATION_REPORT_PATH, FileAccess.WRITE)
	if f == null:
		print("[DressingRoom] could not open escalation report: ", ESCALATION_REPORT_PATH)
		return
	var ts := Time.get_datetime_string_from_system()
	f.store_string("# Dressing-room escalations\n\n")
	f.store_string("> Auto-generated by `DressingRoomCatalog3D` on %s.\n" % ts)
	f.store_string("> Each entry below means the dressing-room offset would have to be larger\n")
	f.store_string("> than %.2f m to make the artifact land correctly. That is a *symptom*\n" % ESCALATION_THRESHOLD_M)
	f.store_string("> — fix the artifact's mesh origin / spawn position in the .tscn / .gd\n")
	f.store_string("> instead of patching the offset.\n\n")
	f.store_string("Total: **%d artifacts**.\n\n" % _escalations.size())
	for esc in _escalations:
		var lookup: String = str(esc.get("lookup", "?"))
		var scene: String = str(esc.get("scene", ""))
		var reasons: Array = esc.get("reasons", [])
		var amin: Array = esc.get("aabb_min", [0, 0, 0])
		var asize: Array = esc.get("aabb_size", [0, 0, 0])
		f.store_string("## `%s`\n\n" % lookup)
		if scene != "":
			f.store_string("- scene: `%s`\n" % scene)
		f.store_string("- AABB min:  (%.2f, %.2f, %.2f)\n" % [amin[0], amin[1], amin[2]])
		f.store_string("- AABB size: (%.2f, %.2f, %.2f)\n" % [asize[0], asize[1], asize[2]])
		f.store_string("- reasons:\n")
		for r in reasons:
			f.store_string("  - %s\n" % str(r))
		f.store_string("\n")
	f.close()
	print("[DressingRoom] wrote %d escalations → %s" % [_escalations.size(), ESCALATION_REPORT_PATH])


func _refresh_room_list() -> void:
	if _list_widget == null:
		return
	_list_widget.clear()
	_filtered_indices.clear()
	var query := ""
	if _list_search:
		query = _list_search.text.strip_edges().to_lower()
	for i in range(_rooms.size()):
		var name: String = _rooms[i]
		if query != "" and not name.to_lower().contains(query):
			continue
		if _map_filter != "" and not _map_artifacts.has(name):
			continue
		match _list_filter_mode:
			1: # default-only
				if not _is_default_room(name):
					continue
			2: # customised
				if _is_default_room(name):
					continue
			3: # has notes
				if not _has_notes(name):
					continue
			_:
				pass
		_filtered_indices.append(i)
		var label: String = name
		if _has_notes(name):
			label = "● " + label
		_list_widget.add_item(label)
		# Highlight currently selected room.
		if i == _index:
			_list_widget.select(_list_widget.item_count - 1)
	if _list_count_label:
		var suffix := ""
		if _map_filter != "":
			var mm = (_map_index.get("maps", {}) as Dictionary).get(_map_filter, {})
			suffix = "  · in %s" % (str(mm.get("name", _map_filter)) if mm is Dictionary else _map_filter)
		_list_count_label.text = "%d / %d shown%s" % [_filtered_indices.size(), _rooms.size(), suffix]


## Load the by-map index (which artifacts each map places, grouped by seq).
func _load_map_index() -> void:
	var p := "res://commons/data/artifact_maps.json"
	if not FileAccess.file_exists(p):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(p))
	if parsed is Dictionary:
		_map_index = parsed


## Build the lookup->true set of artifacts placed in the selected map.
func _rebuild_map_artifacts() -> void:
	_map_artifacts = {}
	if _map_filter == "":
		return
	var am = _map_index.get("artifact_maps", {})
	if am is Dictionary:
		for a in am.keys():
			var ms = am[a]
			if ms is Array and ms.has(_map_filter):
				_map_artifacts[a] = true


func _setup_inspector() -> void:
	# The inspector lives inside the UI CanvasLayer, anchored to the right side.
	if not has_node("UI"):
		return
	var ui: CanvasLayer = $UI
	# Plain Control holder so children honour explicit anchors instead of
	# being auto-sized by a MarginContainer (which lets PanelContainer
	# overflow past the bottom of the screen).
	var holder := Control.new()
	holder.name = "InspectorHolder"
	holder.anchor_left = 1.0
	holder.anchor_right = 1.0
	holder.anchor_top = 0.0
	holder.anchor_bottom = 1.0
	holder.offset_left = -420
	holder.offset_right = -16
	holder.offset_top = 16
	holder.offset_bottom = -16
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	ui.add_child(holder)
	_inspector_holder = holder   # width set responsively in _refit_ui()
	_inspector = DressingRoomInspectorScript.new()
	holder.add_child(_inspector)
	# Pin the inspector to fill the holder's rect — fixes the sticky save
	# bar disappearing when content is taller than the screen.
	_inspector.anchor_left = 0.0
	_inspector.anchor_top = 0.0
	_inspector.anchor_right = 1.0
	_inspector.anchor_bottom = 1.0
	_inspector.offset_left = 0
	_inspector.offset_top = 0
	_inspector.offset_right = 0
	_inspector.offset_bottom = 0
	_inspector.data_changed.connect(_on_inspector_data_changed)
	_inspector.save_requested.connect(_on_save_requested)
	_inspector.revert_requested.connect(_on_revert_requested)
	_inspector.pick_mode_changed.connect(func(mode): _pick_mode = mode)


func _on_revert_requested() -> void:
	if _rooms.is_empty(): return
	_load_room(_rooms[_index])
	if _inspector:
		_inspector.set_save_status("reverted from disk", true)


func _on_inspector_data_changed() -> void:
	# Update local cache + rebuild scene without resetting rotation index.
	if _inspector:
		_current_room_data = _inspector.data
		_rebuild_with_rotation()


func _on_save_requested() -> void:
	if _inspector == null or _current_room_data.is_empty():
		return
	var lookup: String = str(_current_room_data.get("lookup_name", ""))
	if lookup.is_empty():
		_inspector.set_save_status("save error: no lookup_name", false)
		return
	# Always pull from the inspector's latest dict — it is the source of
	# truth after any edits, drags, or tile clicks.
	var to_write: Dictionary = _inspector.data if _inspector.data and not _inspector.data.is_empty() else _current_room_data
	_current_room_data = to_write
	var path: String = "res://commons/artifacts/dressing_rooms/%s.json" % lookup
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		var err := FileAccess.get_open_error()
		_inspector.set_save_status("save error: cannot open %s (err=%d)" % [path, err], false)
		print("[DressingRoom] save FAILED for ", path, " err=", err)
		return
	var payload := JSON.stringify(to_write, "\t")
	f.store_string(payload)
	f.close()
	# Echo what hit disk so you can confirm the offset is in there.
	var off = to_write.get("artifact_offset", null)
	print("[DressingRoom] saved ", path, "  artifact_offset=", off, "  bytes=", payload.length())
	_inspector.set_save_status("saved %s  (offset=%s)" % [lookup, str(off)], true)
	# Notes / default-status may have changed → refresh the filtered list.
	_refresh_room_list()


func _set_hints() -> void:
	if _hint_label:
		_hint_label.text = "[N]/[P] room   [R] rotate   [B] staged/blockout   [F] reset cam   [I] inspector   [C] capture   [Tab] hide UI   drag gizmo arrow = move (snap 0.25)   click tile = paint   drag = orbit   scroll = zoom"


# ──────────────────────────────────────────────────────────────────────
# AI capture — POST /api/dressing-room to the encyclopedia dev server,
# which runs capture_dressing_room.gd and writes mirror PNGs.
# Status shown in the info label; on success, prints PNG paths so the
# user can browse them at /dressing-rooms/<artifact>.
# ──────────────────────────────────────────────────────────────────────

var _ai_http: HTTPRequest = null
var _ai_in_flight: bool = false

func _request_ai_capture() -> void:
	if _ai_in_flight:
		_set_info("AI capture: already running…")
		return
	if _current_room_data.is_empty():
		_set_info("AI capture: no room loaded")
		return
	var lookup: String = str(_current_room_data.get("lookup_name", _rooms[_index] if _index < _rooms.size() else ""))
	if lookup.is_empty():
		_set_info("AI capture: no lookup_name")
		return
	# Save first if dirty — the encyclopedia reads from disk.
	if _inspector != null and bool(_inspector.get("_dirty")):
		_on_save_requested()  # commits current edits to JSON before capture
	# Lazy-create the HTTPRequest node.
	if _ai_http == null:
		_ai_http = HTTPRequest.new()
		_ai_http.timeout = 90.0
		add_child(_ai_http)
		_ai_http.request_completed.connect(_on_ai_capture_complete)
	var url: String = "%s/api/dressing-room" % encyclopedia_origin
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var body: String = JSON.stringify({"artifact": lookup})
	var err: int = _ai_http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_set_info("AI capture: request failed (%s)" % str(err))
		return
	_ai_in_flight = true
	_set_info("AI capture: shooting %s … (≈10s)" % lookup)


func _on_ai_capture_complete(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_ai_in_flight = false
	if response_code != 200:
		_set_info("AI capture: HTTP %d" % response_code)
		print("[AI] body: ", body.get_string_from_utf8().substr(0, 400))
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		_set_info("AI capture: bad response")
		return
	var shots: Array = parsed.get("shots", [])
	var ok_count: int = 0
	for s in shots:
		if s is Dictionary and s.has("image"):
			ok_count += 1
	var size_class: String = str(parsed.get("size_class", "?"))
	var artifact: String = str(parsed.get("artifact", "?"))
	_set_info("AI capture: %d/%d mirrors  class=%s\nView: %s/dressing-rooms/%s"
		% [ok_count, shots.size(), size_class, encyclopedia_origin, artifact])
	for s in shots:
		if s is Dictionary:
			var name: String = str(s.get("name", "?"))
			var img: String = str(s.get("image", ""))
			var err: String = str(s.get("error", ""))
			if not img.is_empty():
				print("[AI] shot %s -> %s%s" % [name, encyclopedia_origin, img])
			elif not err.is_empty():
				print("[AI] shot %s ERROR: %s" % [name, err])


func _set_info(text: String) -> void:
	if _info_label:
		_info_label.text = text


# ──────────────────────────────────────────────────────────────────────
# Room loading
# ──────────────────────────────────────────────────────────────────────

func _load_room(lookup_name: String) -> void:
	# Clear existing.
	if _current_built and is_instance_valid(_current_built):
		_current_built.queue_free()
	_current_built = null
	_current_room_data = {}

	var data = DressingRoomBuilderScript.load_dressing_room(lookup_name)
	if not (data is Dictionary):
		_set_info("Could not load dressing room: %s" % lookup_name)
		return
	_current_room_data = data

	# Allowed rotations from schema.
	var rots_raw: Array = data.get("rotations", ["0"])
	_current_rotations.clear()
	for r in rots_raw:
		_current_rotations.append(int(str(r)))
	if _current_rotations.is_empty():
		_current_rotations = [0]
	_current_rotation_index = 0

	# Fresh load → clear inspector dirty.
	if _inspector:
		_inspector.set_data(_current_room_data)
	# Sync the DNA type selector to this room's posture.
	if _type_btn:
		var cur_posture := str(_current_room_data.get("posture", ""))
		var sel: int = _type_postures.find(cur_posture)
		_type_btn.select(sel if sel >= 0 else 0)
	_rebuild_with_rotation()


func _rebuild_with_rotation() -> void:
	if _current_room_data.is_empty():
		return
	if _current_built and is_instance_valid(_current_built):
		_current_built.queue_free()
	_tile_meta.clear()
	if _current_rotation_index >= _current_rotations.size():
		_current_rotation_index = 0
	var rot_deg: int = _current_rotations[_current_rotation_index]
	var lookup_cb := Callable(self, "_lookup_artifact_info")
	_current_built = DressingRoomBuilderScript.build(
		_current_room_data, rot_deg, lookup_cb, _staged)
	_container.add_child(_current_built)
	# Tag footing tile MeshInstance3Ds with their UNROTATED row/col so the
	# inspector can edit the source data on click. We re-derive that from the
	# tile's name "Tile_<row>_<col>" then inverse-rotate to source coords.
	var footing: Node = _current_built.get_node_or_null("Footing")
	if footing:
		for child in footing.get_children():
			if child is MeshInstance3D:
				var n := child.name as String
				var parts := n.split("_")
				if parts.size() >= 3:
					var rotated_r: int = int(parts[1])
					var rotated_c: int = int(parts[2])
					var src := _unrotate_coord(rotated_r, rotated_c, rot_deg)
					_tile_meta[child.get_instance_id()] = src
	_frame_built()
	_set_info(_format_info(rot_deg))
	# Use sync_data so any pending dirty edits stay marked unsaved.
	if _inspector:
		_inspector.sync_data(_current_room_data)
	# Seat the artifact ON the surface — the builder puts its ORIGIN at the
	# anchor top, so an artifact whose origin isn't at its base sinks into the
	# footing (e.g. a board under a raised table). The GAME auto-grounds too,
	# so this only makes the preview match; the recipe needs no offset.
	# Deferred, since (often procedural) meshes aren't built this frame yet.
	get_tree().create_timer(0.45).timeout.connect(
		_seat_artifact_on_surface, CONNECT_ONE_SHOT)
	# Translation gizmo on the artifact (arrows, snap 0.25).
	_build_gizmo()


## World AABB of every VisualInstance3D under a node (mesh bounds only).
func _subtree_world_aabb(node: Node) -> AABB:
	var combined := AABB()
	var has_any := false
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is VisualInstance3D):
			continue
		var vi := n as VisualInstance3D
		var local := vi.get_aabb()
		if local.size.length_squared() < 1e-6:
			continue
		var world: AABB = vi.global_transform * local
		if not has_any:
			combined = world
			has_any = true
		else:
			combined = combined.merge(world)
	return combined if has_any else AABB()


## Lift/lower the built artifact so its LOWEST point rests on the surface its
## origin was placed at (anchor top + the recipe's artifact_offset.y). No-op
## for artifacts whose origin already sits at their base (e.g. the vase).
func _seat_artifact_on_surface() -> void:
	if not (_current_built and is_instance_valid(_current_built)):
		return
	var art: Node3D = _current_built.get_node_or_null("Artifact") as Node3D
	if art == null:
		return
	var aabb := _subtree_world_aabb(art)
	if aabb.size == Vector3.ZERO:
		return  # meshes still not built — leave as placed
	var delta: float = art.global_position.y - aabb.position.y
	if absf(delta) > 0.01:
		art.global_position.y += delta
	_update_gizmo_position()   # gizmo follows the seated artifact


# Convert (rotated_r, rotated_c) back to the source tile coordinates.
func _unrotate_coord(rotated_r: int, rotated_c: int, rot_deg: int) -> Dictionary:
	var footing: Dictionary = _current_room_data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	var rows: int = tiles.size()
	var cols: int = 0
	for row in tiles:
		if row is Array and row.size() > cols:
			cols = row.size()
	rot_deg = rot_deg % 360
	var src_r: int = rotated_r
	var src_c: int = rotated_c
	if rot_deg == 90:
		# rotated[r][c] = src[rows-1-c][r]  →  src_r = rows-1-rotated_c, src_c = rotated_r
		src_r = rows - 1 - rotated_c
		src_c = rotated_r
	elif rot_deg == 180:
		src_r = rows - 1 - rotated_r
		src_c = cols - 1 - rotated_c
	elif rot_deg == 270:
		src_r = rotated_c
		src_c = cols - 1 - rotated_r
	return {"row": src_r, "col": src_c}


func _format_info(rot_deg: int) -> String:
	var name: String = str(_current_room_data.get("lookup_name", "?"))
	var fp = _current_room_data.get("footprint", [1, 1, 1])
	var extras = _current_room_data.get("extras", [])
	var approach = str(_current_room_data.get("approach", "?"))
	var exit = str(_current_room_data.get("exit", "?"))
	return "%s   (%d/%d)\nrotation: %d°   footprint: %s\napproach: %s   exit: %s   extras: %d" % [
		name, _index + 1, _rooms.size(),
		rot_deg, str(fp),
		approach, exit, extras.size()]


## Look up an artifact's scene path. Scans the registry JSON files
## directly — the catalog's data provider is GridSystem-coupled and
## not always available outside a full map context.
func _lookup_artifact_info(lookup: String) -> Dictionary:
	# If the data provider doesn't expose get_artifact_info, scan the
	# registry JSONs directly for a scene path.
	var registry_dir := "res://commons/artifacts/registry/"
	var dir := DirAccess.open(registry_dir)
	if dir == null:
		return {}
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var raw := FileAccess.get_file_as_string(registry_dir + fname)
			var parsed = JSON.parse_string(raw)
			if parsed is Dictionary:
				var arts: Variant = parsed.get("artifacts")
				if not (arts is Dictionary):
					arts = parsed
				if arts is Dictionary and arts.has(lookup):
					var entry = arts[lookup]
					if entry is Dictionary:
						dir.list_dir_end()
						return entry
		fname = dir.get_next()
	dir.list_dir_end()
	return {}


# ──────────────────────────────────────────────────────────────────────
# Camera framing
# ──────────────────────────────────────────────────────────────────────

func _frame_built() -> void:
	if not _current_built:
		return
	var aabb := _aabb_of(_current_built)
	if aabb.size.length_squared() < 1e-6:
		return
	_orbit_focus = aabb.get_center()
	# True bounding-SPHERE radius (half the diagonal), not half the largest single
	# axis: a tall pedestal+artifact stack is bigger than any one dimension, and
	# this radius is orbit-angle independent, so the whole composition always fits.
	var radius: float = aabb.size.length() * 0.5
	var fov_rad: float = deg_to_rad(_camera.fov)
	_orbit_distance = clampf(
		radius / max(0.01, sin(fov_rad * 0.5)) * (1.0 - fit_padding) + radius,
		zoom_min, zoom_max
	)
	_update_camera_from_orbit()


func _aabb_of(node: Node) -> AABB:
	var combined := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.mesh:
			var mesh_aabb: AABB = (n as MeshInstance3D).global_transform * n.get_aabb()
			if first:
				combined = mesh_aabb
				first = false
			else:
				combined = combined.merge(mesh_aabb)
		for child in n.get_children():
			stack.append(child)
	return combined


func _update_camera_from_orbit() -> void:
	if not _camera_rig or not _camera:
		return
	# Camera position on a sphere around the focus.
	var x: float = _orbit_distance * cos(_orbit_pitch) * sin(_orbit_yaw)
	var y: float = _orbit_distance * sin(_orbit_pitch)
	var z: float = _orbit_distance * cos(_orbit_pitch) * cos(_orbit_yaw)
	_camera_rig.global_position = _orbit_focus + Vector3(x, y, z)
	_camera_rig.look_at(_orbit_focus, Vector3.UP)


# ──────────────────────────────────────────────────────────────────────
# Input
# ──────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# If the mouse is hovering the inspector panel, never start orbit / pick
	# (the inspector handles its own clicks).
	if _is_pointer_over_inspector():
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				# Float mode is view-only: orbit/zoom, no editing aids.
				if _float_mode:
					_is_orbiting = true
					_last_mouse = mb.position
					return
				# Priority on press: (1) gizmo axis, (2) artifact drag,
				# (3) tile paint, (4) orbit. First match wins.
				if _try_begin_gizmo_drag(mb.position):
					_is_orbiting = false
					return
				if _try_begin_artifact_drag(mb.position, mb.shift_pressed):
					_is_orbiting = false
					return
				if _try_pick_tile(mb.position):
					return
				_is_orbiting = true
				_last_mouse = mb.position
			else:
				if _gizmo_dragging:
					_finish_gizmo_drag()
					return
				if _is_dragging_artifact:
					_finish_artifact_drag()
					return
				_is_orbiting = false
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = mb.pressed
			_last_mouse = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_orbit_distance = max(zoom_min, _orbit_distance - zoom_sensitivity)
			_update_camera_from_orbit()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_orbit_distance = min(zoom_max, _orbit_distance + zoom_sensitivity)
			_update_camera_from_orbit()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _gizmo_dragging:
			_update_gizmo_drag(mm.position)
			_last_mouse = mm.position
			return
		if _is_dragging_artifact:
			_update_artifact_drag(mm.position)
			_last_mouse = mm.position
			return
		if _is_orbiting:
			var delta: Vector2 = mm.position - _last_mouse
			_last_mouse = mm.position
			_orbit_yaw -= delta.x * orbit_sensitivity
			_orbit_pitch = clamp(_orbit_pitch + delta.y * orbit_sensitivity,
				deg_to_rad(-80), deg_to_rad(80))
			_update_camera_from_orbit()
		elif _is_panning:
			var delta: Vector2 = mm.position - _last_mouse
			_last_mouse = mm.position
			# Pan focus along camera basis.
			var basis_x: Vector3 = -_camera_rig.global_transform.basis.x
			var basis_y: Vector3 = _camera_rig.global_transform.basis.y
			_orbit_focus += basis_x * delta.x * pan_sensitivity * (_orbit_distance / 5.0)
			_orbit_focus += basis_y * delta.y * pan_sensitivity * (_orbit_distance / 5.0)
			_update_camera_from_orbit()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			next_room_key:
				_advance_room(1)
			prev_room_key:
				_advance_room(-1)
			next_rotation_key:
				_advance_rotation()
			reset_camera_key:
				_orbit_yaw = deg_to_rad(initial_yaw_deg)
				_orbit_pitch = deg_to_rad(initial_pitch_deg)
				_frame_built()
			toggle_overlay_key:
				if has_node("UI"):
					var ui: CanvasLayer = $UI
					ui.visible = not ui.visible
			toggle_inspector_key:
				if _inspector and _inspector.get_parent() is Control:
					var holder: Control = _inspector.get_parent() as Control
					holder.visible = not holder.visible
			KEY_B:
				_staged = not _staged
				if _staged_btn:
					_staged_btn.set_pressed_no_signal(_staged)
				_rebuild_with_rotation()
				_set_info("view: %s" % ("STAGED (real station props)" if _staged else "BLOCKOUT (height tiles)"))
			ai_capture_key:
				_request_ai_capture()


func _advance_room(delta: int) -> void:
	if _rooms.is_empty(): return
	_index = (_index + delta) % _rooms.size()
	if _index < 0:
		_index += _rooms.size()
	_load_room(_rooms[_index])
	# Keep the list selection in sync.
	if _list_widget and _filtered_indices.has(_index):
		_list_widget.select(_filtered_indices.find(_index))


func _advance_rotation() -> void:
	if _current_rotations.size() <= 1:
		return
	_current_rotation_index = (_current_rotation_index + 1) % _current_rotations.size()
	_rebuild_with_rotation()


## Rebuild the footing pad to cols × rows flat cells, re-centring the raised
## region (the support's blockout, value > 1) and the anchor. Driven from the
## web "footprint" control; the caller rebuilds + marks dirty. Save persists it.
func _resize_pad(cols: int, rows: int) -> void:
	if _current_room_data.is_empty():
		return
	var footing: Dictionary = _current_room_data.get("footing", {})
	var tiles: Array = footing.get("tiles", [[1]])
	# Measure the raised region (cells with value > 1) in the current pad.
	var rmin: int = 9999
	var rmax: int = -1
	var cmin: int = 9999
	var cmax: int = -1
	var rval: int = 0
	for r in range(tiles.size()):
		var row = tiles[r]
		if not (row is Array): continue
		for c in range(row.size()):
			var v: int = int(row[c])
			if v > 1:
				rmin = mini(rmin, r); rmax = maxi(rmax, r)
				cmin = mini(cmin, c); cmax = maxi(cmax, c)
				rval = maxi(rval, v)
	var raised_rows: int = (rmax - rmin + 1) if rmax >= 0 else 0
	var raised_cols: int = (cmax - cmin + 1) if cmax >= 0 else 0
	# Fresh flat pad of 1s.
	var new_tiles: Array = []
	for r in range(rows):
		var row_new: Array = []
		for c in range(cols):
			row_new.append(1)
		new_tiles.append(row_new)
	# Re-centre the raised region within the new pad.
	if rval > 1 and raised_rows > 0 and raised_cols > 0:
		var start_r: int = int(float(rows - raised_rows) / 2.0)
		var start_c: int = int(float(cols - raised_cols) / 2.0)
		for dr in range(raised_rows):
			for dc in range(raised_cols):
				var rr: int = start_r + dr
				var cc: int = start_c + dc
				if rr >= 0 and rr < rows and cc >= 0 and cc < cols:
					new_tiles[rr][cc] = rval
	footing["tiles"] = new_tiles
	footing["anchor"] = [int(rows / 2), int(cols / 2)]
	_current_room_data["footing"] = footing


# ──────────────────────────────────────────────────────────────────────
# Tile picking via raycast
# ──────────────────────────────────────────────────────────────────────

func _is_pointer_over_inspector() -> bool:
	if _inspector == null:
		return false
	var holder: Control = _inspector.get_parent() as Control
	if holder == null or not holder.visible:
		return false
	var rect := holder.get_global_rect()
	return rect.has_point(get_viewport().get_mouse_position())


# Cast a ray from the camera through the click point, find the nearest
# footing tile, and pass the (row, col) to the inspector.
func _try_pick_tile(screen_pos: Vector2) -> bool:
	if _camera == null or _current_built == null:
		return false
	var origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var direction: Vector3 = _camera.project_ray_normal(screen_pos)
	var footing := _current_built.get_node_or_null("Footing")
	if footing == null:
		return false
	var best_node: MeshInstance3D = null
	var best_t: float = INF
	for child in footing.get_children():
		if not (child is MeshInstance3D): continue
		var mi: MeshInstance3D = child
		var aabb: AABB = mi.global_transform * mi.get_aabb()
		# Slab method ray-box intersect.
		var t_hit: float = _ray_aabb_t(origin, direction, aabb)
		if t_hit >= 0.0 and t_hit < best_t:
			best_t = t_hit
			best_node = mi
	if best_node == null:
		return false
	var coord: Dictionary = _tile_meta.get(best_node.get_instance_id(), {})
	if coord.is_empty():
		return false
	if _inspector and _inspector.handle_tile_click(int(coord.row), int(coord.col)):
		_current_room_data = _inspector.data
		_rebuild_with_rotation()
	return true


# ──────────────────────────────────────────────────────────────────────
# Artifact drag — move the artifact within its dressing-room cell
# ──────────────────────────────────────────────────────────────────────

# Try to begin a drag if the click ray hits any mesh under the Artifact
# node. Returns true if drag started so the caller can suppress orbit.
# `shift_pressed` switches to a vertical (Y) drag plane.
func _try_begin_artifact_drag(screen_pos: Vector2, shift_pressed: bool) -> bool:
	if _camera == null or _current_built == null:
		return false
	var artifact_root: Node3D = _current_built.get_node_or_null("Artifact") as Node3D
	if artifact_root == null:
		return false
	var origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var direction: Vector3 = _camera.project_ray_normal(screen_pos)
	# Walk all MeshInstance3D under the artifact root, ray-test their AABBs.
	var best_t: float = INF
	var stack: Array = [artifact_root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh:
			var mi: MeshInstance3D = n
			var aabb: AABB = mi.global_transform * mi.get_aabb()
			var t_hit: float = _ray_aabb_t(origin, direction, aabb)
			if t_hit >= 0.0 and t_hit < best_t:
				best_t = t_hit
		for c in n.get_children():
			stack.append(c)
	if best_t == INF:
		return false
	# Capture initial state.
	_is_dragging_artifact = true
	_drag_y_locked = not shift_pressed
	var off_arr: Array = _current_room_data.get("artifact_offset", [0.0, 0.0, 0.0])
	while off_arr.size() < 3:
		off_arr.append(0.0)
	_drag_initial_offset = Vector3(
		float(off_arr[0]), float(off_arr[1]), float(off_arr[2]))
	# Anchor world centre = artifact_root.global_position MINUS the rotated
	# initial offset (the builder added that on top of the anchor).
	var rot_deg: int = _current_rotations[_current_rotation_index]
	var rot_rad: float = deg_to_rad(rot_deg)
	var rox: float = _drag_initial_offset.x * cos(rot_rad) + _drag_initial_offset.z * sin(rot_rad)
	var roz: float = -_drag_initial_offset.x * sin(rot_rad) + _drag_initial_offset.z * cos(rot_rad)
	_drag_anchor_world = artifact_root.global_position - Vector3(rox, _drag_initial_offset.y, roz)
	_last_mouse = screen_pos
	return true


# Project the mouse onto the drag plane and live-move the artifact node.
# Stores the new offset (data-space, unrotated) in _current_room_data and
# silently mirrors it to the inspector spin boxes.
func _update_artifact_drag(screen_pos: Vector2) -> void:
	if not _is_dragging_artifact or _camera == null or _current_built == null:
		return
	var origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var direction: Vector3 = _camera.project_ray_normal(screen_pos)
	var hit_world: Vector3 = _drag_anchor_world
	if _drag_y_locked:
		# Horizontal plane y = anchor.y.
		if absf(direction.y) < 1e-6:
			return
		var t: float = (_drag_anchor_world.y - origin.y) / direction.y
		if t <= 0.0:
			return
		hit_world = origin + direction * t
	else:
		# Vertical plane through the anchor, normal = camera flat-forward.
		var fwd: Vector3 = -_camera_rig.global_transform.basis.z
		fwd.y = 0.0
		if fwd.length_squared() < 1e-6:
			fwd = Vector3.FORWARD
		fwd = fwd.normalized()
		var denom: float = direction.dot(fwd)
		if absf(denom) < 1e-6:
			return
		var t2: float = (_drag_anchor_world - origin).dot(fwd) / denom
		if t2 <= 0.0:
			return
		hit_world = origin + direction * t2
	# Rotated (world-space) offset from the anchor.
	var rotated_offset: Vector3 = hit_world - _drag_anchor_world
	# Inverse-rotate to data space (data is described in rotation 0).
	var rot_deg: int = _current_rotations[_current_rotation_index]
	var rot_rad: float = deg_to_rad(rot_deg)
	var dx: float = rotated_offset.x * cos(-rot_rad) + rotated_offset.z * sin(-rot_rad)
	var dz: float = -rotated_offset.x * sin(-rot_rad) + rotated_offset.z * cos(-rot_rad)
	var data_offset := Vector3(dx, rotated_offset.y, dz)
	# Lock axes the user isn't dragging.
	if _drag_y_locked:
		data_offset.y = _drag_initial_offset.y
	else:
		data_offset.x = _drag_initial_offset.x
		data_offset.z = _drag_initial_offset.z
	# Clamp to inspector range.
	data_offset.x = clampf(data_offset.x, -3.0, 3.0)
	data_offset.y = clampf(data_offset.y, -3.0, 3.0)
	data_offset.z = clampf(data_offset.z, -3.0, 3.0)
	# Live-move the live Artifact node so dragging is smooth (no rebuild).
	var artifact_root: Node3D = _current_built.get_node_or_null("Artifact") as Node3D
	if artifact_root:
		var rrx: float = data_offset.x * cos(rot_rad) + data_offset.z * sin(rot_rad)
		var rrz: float = -data_offset.x * sin(rot_rad) + data_offset.z * cos(rot_rad)
		artifact_root.global_position = _drag_anchor_world + Vector3(rrx, data_offset.y, rrz)
	# Persist into the data dict and mirror to the inspector spin boxes.
	_current_room_data["artifact_offset"] = [data_offset.x, data_offset.y, data_offset.z]
	if _inspector:
		_inspector.set_artifact_offset_silent(data_offset)


func _finish_artifact_drag() -> void:
	if not _is_dragging_artifact:
		return
	_is_dragging_artifact = false
	# Mark dirty — the drag mutated artifact_offset in place, but the
	# silent setter doesn't emit data_changed.
	if _inspector:
		_inspector._mark_dirty()
	# Rebuild once so extras / labels / clearance reflect the final
	# offset. _current_room_data already holds the new value, and
	# sync_data inside rebuild preserves the dirty flag.
	_rebuild_with_rotation()


# ──────────────────────────────────────────────────────────────────────
# Translation gizmo — three axis arrows, snapped to 0.25 m
# ──────────────────────────────────────────────────────────────────────

## (Re)build the gizmo at the artifact. Arrows point along the DATA axes
## rotated into the world by the current room rotation, so a drag along an
## arrow maps to exactly one artifact_offset component.
func _build_gizmo() -> void:
	if _gizmo and is_instance_valid(_gizmo):
		_gizmo.queue_free()
	_gizmo = null
	_gizmo_arrows = []
	if _current_built == null:
		return
	var art: Node3D = _current_built.get_node_or_null("Artifact") as Node3D
	if art == null:
		return
	_gizmo = Node3D.new()
	_gizmo.name = "TranslateGizmo"
	add_child(_gizmo)
	var rot_rad: float = deg_to_rad(float(_current_rotations[_current_rotation_index]))
	var x_w := Vector3(cos(rot_rad), 0.0, -sin(rot_rad))
	var y_w := Vector3(0.0, 1.0, 0.0)
	var z_w := Vector3(sin(rot_rad), 0.0, cos(rot_rad))
	_gizmo_arrows.append(_make_gizmo_arrow(0, x_w, Color(0.92, 0.26, 0.32)))
	_gizmo_arrows.append(_make_gizmo_arrow(1, y_w, Color(0.36, 0.82, 0.38)))
	_gizmo_arrows.append(_make_gizmo_arrow(2, z_w, Color(0.30, 0.52, 0.96)))
	_update_gizmo_position()
	if _float_mode:
		_gizmo.visible = false   # clean artifact-only view


func _make_gizmo_arrow(axis: int, dir: Vector3, color: Color) -> Dictionary:
	var root := Node3D.new()
	root.name = "Axis_%d" % axis
	_gizmo.add_child(root)
	# Rotate the arrow (built along +Y) to point along `dir`.
	var d := dir.normalized()
	if d.dot(Vector3.UP) < 0.99999:
		var axis_rot := Vector3.UP.cross(d)
		if axis_rot.length() > 1e-5:
			root.rotate(axis_rot.normalized(), Vector3.UP.angle_to(d))
	var length := 0.9
	var mats: Array = []
	var shaft := MeshInstance3D.new()
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.028
	scyl.bottom_radius = 0.028
	scyl.height = length
	shaft.mesh = scyl
	shaft.position = Vector3(0, length * 0.5, 0)
	shaft.material_override = _gizmo_mat(color)
	mats.append(shaft.material_override)
	root.add_child(shaft)
	var tip := MeshInstance3D.new()
	var tcyl := CylinderMesh.new()
	tcyl.top_radius = 0.0
	tcyl.bottom_radius = 0.1
	tcyl.height = 0.24
	tip.mesh = tcyl
	tip.position = Vector3(0, length + 0.12, 0)
	tip.material_override = _gizmo_mat(color)
	mats.append(tip.material_override)
	root.add_child(tip)
	return {"root": root, "dir": d, "axis": axis, "mats": mats}


func _gizmo_mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.no_depth_test = true          # draw over the artifact so it's always grabbable
	m.render_priority = 12
	return m


func _update_gizmo_position() -> void:
	if _gizmo == null or _current_built == null:
		return
	var art: Node3D = _current_built.get_node_or_null("Artifact") as Node3D
	if art:
		_gizmo.global_position = art.global_position


func _set_gizmo_axis_highlight(active_axis: int) -> void:
	for a in _gizmo_arrows:
		var lit: bool = int(a.axis) == active_axis
		for m in a.mats:
			var sm := m as StandardMaterial3D
			sm.emission_enabled = lit
			sm.emission = sm.albedo_color
			sm.emission_energy_multiplier = (1.0 if lit else 0.0)


## Closest point PARAMETER on the axis line to the mouse ray (both dirs unit).
func _closest_t_on_axis(ray_o: Vector3, ray_d: Vector3, axis_o: Vector3, axis_d: Vector3) -> float:
	var w0 := axis_o - ray_o
	var b := ray_d.dot(axis_d)
	var d := ray_d.dot(w0)
	var e := axis_d.dot(w0)
	var denom := 1.0 - b * b
	if absf(denom) < 1e-6:
		return 0.0     # ray parallel to axis
	return (e - b * d) / denom


func _try_begin_gizmo_drag(screen_pos: Vector2) -> bool:
	if _camera == null or _gizmo == null or _current_built == null:
		return false
	var origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var direction: Vector3 = _camera.project_ray_normal(screen_pos)
	var best_axis: int = -1
	var best_t: float = INF
	for a in _gizmo_arrows:
		for child in (a.root as Node3D).get_children():
			if not (child is MeshInstance3D): continue
			var mi: MeshInstance3D = child
			var aabb: AABB = (mi.global_transform * mi.get_aabb()).grow(0.06)
			var t: float = _ray_aabb_t(origin, direction, aabb)
			if t >= 0.0 and t < best_t:
				best_t = t
				best_axis = int(a.axis)
	if best_axis < 0:
		return false
	var art: Node3D = _current_built.get_node_or_null("Artifact") as Node3D
	if art == null:
		return false
	_gizmo_dragging = true
	_gizmo_axis = best_axis
	for a in _gizmo_arrows:
		if int(a.axis) == best_axis:
			_gizmo_axis_world = (a.dir as Vector3).normalized()
	_gizmo_line_origin = art.global_position
	_gizmo_art_start_pos = art.global_position
	var off_arr: Array = _current_room_data.get("artifact_offset", [0.0, 0.0, 0.0])
	while off_arr.size() < 3:
		off_arr.append(0.0)
	_gizmo_initial_offset = Vector3(float(off_arr[0]), float(off_arr[1]), float(off_arr[2]))
	_gizmo_t0 = _closest_t_on_axis(origin, direction, _gizmo_line_origin, _gizmo_axis_world)
	_set_gizmo_axis_highlight(best_axis)
	return true


func _update_gizmo_drag(screen_pos: Vector2) -> void:
	if not _gizmo_dragging or _camera == null or _current_built == null:
		return
	var origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var direction: Vector3 = _camera.project_ray_normal(screen_pos)
	var t1: float = _closest_t_on_axis(origin, direction, _gizmo_line_origin, _gizmo_axis_world)
	var delta: float = t1 - _gizmo_t0                 # metres along the axis
	var init_comp: float = _gizmo_initial_offset[_gizmo_axis]
	var new_comp: float = clampf(snappedf(init_comp + delta, GIZMO_SNAP), -3.0, 3.0)
	var change: float = new_comp - init_comp
	# Translate from the drag-start position — preserves the auto-ground seat.
	var art: Node3D = _current_built.get_node_or_null("Artifact") as Node3D
	if art:
		art.global_position = _gizmo_art_start_pos + _gizmo_axis_world * change
	_update_gizmo_position()
	var data_offset := _gizmo_initial_offset
	data_offset[_gizmo_axis] = new_comp
	_current_room_data["artifact_offset"] = [data_offset.x, data_offset.y, data_offset.z]
	if _inspector:
		_inspector.set_artifact_offset_silent(data_offset)
	_set_info("offset %s = %.2f m  (snap %.2f)" % ["xyz"[_gizmo_axis], new_comp, GIZMO_SNAP])


func _finish_gizmo_drag() -> void:
	if not _gizmo_dragging:
		return
	_gizmo_dragging = false
	_gizmo_axis = -1
	_set_gizmo_axis_highlight(-1)
	if _inspector:
		_inspector._mark_dirty()
	_rebuild_with_rotation()   # extras / clearance reflect the final offset


# Ray-AABB slab intersection — returns t of nearest hit, or -1 if no hit.
func _ray_aabb_t(origin: Vector3, dir: Vector3, aabb: AABB) -> float:
	var inv := Vector3(
		1.0 / dir.x if absf(dir.x) > 1e-9 else 1e9,
		1.0 / dir.y if absf(dir.y) > 1e-9 else 1e9,
		1.0 / dir.z if absf(dir.z) > 1e-9 else 1e9,
	)
	var min_p: Vector3 = aabb.position
	var max_p: Vector3 = aabb.position + aabb.size
	var t1: Vector3 = (min_p - origin) * inv
	var t2: Vector3 = (max_p - origin) * inv
	var tmin: float = max(max(min(t1.x, t2.x), min(t1.y, t2.y)), min(t1.z, t2.z))
	var tmax: float = min(min(max(t1.x, t2.x), max(t1.y, t2.y)), max(t1.z, t2.z))
	if tmax < 0 or tmin > tmax:
		return -1.0
	return tmin if tmin >= 0.0 else tmax

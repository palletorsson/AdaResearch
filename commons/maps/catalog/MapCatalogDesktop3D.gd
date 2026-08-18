class_name MapCatalogDesktop3D
extends Node3D

## Standalone desktop catalog for browsing all sequence JSON maps.
## Uses MapBrowser3D and delegates loading to the global SceneManager.
## Camera modes: Static, Isometric, Spin, Player (WASD fly).

const CLEAN_KEEP_GROUP := "map_switcher_ui_keep"

enum CameraMode {
	STATIC,
	ISOMETRIC,
	SPIN,
	PLAYER
}

@export var fly_mode_enabled: bool = true
@export var fly_toggle_key: Key = KEY_F
@export var fly_look_requires_button: bool = false
@export var look_mouse_button: MouseButton = MOUSE_BUTTON_RIGHT
@export var fly_up_key: Key = KEY_E
@export var fly_down_key: Key = KEY_Q
@export var fly_speed: float = 4.0
@export var fly_boost_multiplier: float = 2.5
@export var fly_look_sensitivity: float = 0.002

@onready var _preview_camera: Camera3D = $PreviewCamera
@onready var _map_browser: Node3D = $MapBrowser3D
@onready var _status_label: Label3D = $StatusLabel
@onready var _overlay: DesktopMapSwitcherOverlay = $DesktopMapSwitcherOverlay
@onready var _map_data_editor: MapDataEditorOverlay = $MapDataEditorOverlay
@onready var _world_environment: WorldEnvironment = $WorldEnvironment
@onready var _key_light: DirectionalLight3D = $KeyLight
@onready var _fill_light: DirectionalLight3D = $FillLight

var _is_mouse_look_active: bool = false
var _fly_yaw: float = 0.0
var _fly_pitch: float = 0.0

# Walk-through mode (opt-in via --walk=<Map>): a LIT, floored, first-person
# view for looking at a map like a gallery, as opposed to the capture backdrop
# or the near-black mapsim bridge. Additive — off unless the flag is passed.
var _walk_mode: bool = false

# Camera mode state
var _camera_mode: CameraMode = CameraMode.SPIN
var _spin_angle: float = 0.0
var _spin_speed: float = 0.3  # radians/sec
var _orbit_radius: float = 8.0
var _orbit_height: float = 6.0
var _orbit_center: Vector3 = Vector3.ZERO

# Store original camera transform so STATIC can restore it
var _static_camera_position: Vector3 = Vector3(0.0, 1.2, 6.5)
var _static_camera_rotation: Vector3 = Vector3(-0.2618, 0.0, 0.0)  # ~-15° pitch

# Grid system for rendering maps in-scene
const GRID_SYSTEM_SCENE_PATH := "res://commons/grid/grid_system.tscn"
var _grid_system: Node3D = null

# ── Map-simulator live bridge (dormant unless launched with --mapsim-bridge) ──
# Same file-bridge pattern as the dressing-room viewer: the web /map-simulator
# page writes ms_control.json (which map to show), we poll it and load_map_fresh,
# and write ms_viewer_state.json back so the web knows a window is alive.
const MAPSIM_CONTROL := "res://ada_run/mapsim_control.json"
const MAPSIM_STATE := "res://ada_run/mapsim_viewer_state.json"
var _mapsim_bridge_on: bool = false
var _mapsim_float: bool = false
var _mapsim_timer: Timer = null
var _mapsim_last_ctl: float = 0.0
var _mapsim_current_map: String = ""

# Layer editor panel (right-side artifact/utility picker)
var _layer_editor_panel: MapLayerEditorPanel = null

func _ready() -> void:
	if not _map_browser:
		push_warning("MapCatalogDesktop3D: MapBrowser3D node not found")
		return

	if _map_browser.has_signal("sequence_selected"):
		_map_browser.sequence_selected.connect(_on_sequence_selected)

	if _map_browser.has_signal("map_selected"):
		_map_browser.map_selected.connect(_on_map_selected)

	if _preview_camera:
		# Capture the initial camera transform from the scene as the "static" default
		_static_camera_position = _preview_camera.global_position
		_static_camera_rotation = _preview_camera.rotation
		_fly_yaw = _preview_camera.rotation.y
		_fly_pitch = _preview_camera.rotation.x

	_mark_clean_keep(_preview_camera)
	_mark_clean_keep(_map_browser)
	_mark_clean_keep(_status_label)
	_mark_clean_keep(_world_environment)
	_mark_clean_keep(_key_light)
	_mark_clean_keep(_fill_light)
	_mark_clean_keep(_map_data_editor)

	# Connect map data editor save → reload the map live
	if _map_data_editor and _map_data_editor.has_signal("map_data_saved"):
		_map_data_editor.map_data_saved.connect(_on_map_data_saved)

	# Hide the old 3D menu — sidebar replaces it
	if _map_browser:
		_map_browser.visible = false

	_sync_mouse_look_state()

	# Create layer editor panel (right-side artifact/utility picker)
	_layer_editor_panel = MapLayerEditorPanel.new()
	_layer_editor_panel.name = "MapLayerEditorPanel"
	add_child(_layer_editor_panel)
	_mark_clean_keep(_layer_editor_panel)
	_layer_editor_panel.brush_selected.connect(_on_layer_brush_selected)

	# Default to spin camera (suppressed in capture mode — see below).
	call_deferred("_start_default_spin")

	# Walk-through mode short-circuits the capture backdrop: it wants the
	# normal lit world and the map's own floor, so parse the flag first.
	var _walk_map := ""
	for a in OS.get_cmdline_user_args():
		if a == "--walk":
			_walk_mode = true
		elif a.begins_with("--walk="):
			_walk_mode = true
			_walk_map = a.substr(7)

	# Capture-mode environment override: clean studio backdrop with no
	# sun glare or sky gradient so spine-research thumbnails focus on
	# the cube grid. Triggered via ada_run/runtime_flags.json (set by
	# the Python capture wrapper). Skipped in walk mode.
	if not _walk_mode:
		_apply_capture_environment_if_active()

	_set_status("Loaded sequence registry catalog")

	# Live map-simulator bridge — only if launched with --mapsim-bridge.
	_mapsim_bridge_setup()

	# Walk-through: lit, floored, first-person. Loads the map into the
	# default (lit) world and drops the camera at eye height framing the row.
	if _walk_mode and _walk_map != "":
		call_deferred("_walk_setup", _walk_map)


# ── Map-simulator live bridge ─────────────────────────────────────────
func _mapsim_bridge_setup() -> void:
	var initial_map := ""
	for a in OS.get_cmdline_user_args():
		if a == "--mapsim-bridge":
			_mapsim_bridge_on = true
		elif a == "--float":
			_mapsim_float = true
		elif a.begins_with("--map="):
			initial_map = a.substr(6)
	if not _mapsim_bridge_on:
		return
	# This version's defaults: NO WORLD (near-black, no sky/glow/fog) and NO
	# camera rotation (freeze the spin — the map holds still while you edit).
	_spin_speed = 0.0
	_mapsim_clean_world()
	# Ignore any pre-existing control message so we don't replay a stale one.
	var existing = _mapsim_read_json(MAPSIM_CONTROL)
	if existing is Dictionary:
		_mapsim_last_ctl = float(existing.get("ts", 0))
	_mapsim_timer = Timer.new()
	_mapsim_timer.wait_time = 0.5
	_mapsim_timer.autostart = true
	_mapsim_timer.timeout.connect(_mapsim_bridge_poll)
	add_child(_mapsim_timer)
	if initial_map != "":
		load_map_fresh(initial_map)
		_mapsim_current_map = initial_map
		_mapsim_lift_grid()
		_mapsim_schedule_stage()
	if _mapsim_float:
		call_deferred("_mapsim_apply_window", "float")
	_set_status("map-sim bridge live")


## No world: a clean near-black environment (no sky gradient, glow or fog) + the
## catalog's grey Floor plate hidden, so only the map grid reads.
func _mapsim_clean_world() -> void:
	if _world_environment:
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.06, 0.07, 0.10)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.55, 0.58, 0.65)
		env.ambient_light_energy = 1.0
		env.glow_enabled = false
		env.fog_enabled = false
		_world_environment.environment = env
	var floor_node := get_node_or_null("Floor")
	if floor_node and "visible" in floor_node:
		floor_node.visible = false


## Grid at level 1: raise the map one grid cube so all footprints sit one level
## up (load_map_fresh seats the grid at y=-0.5; +0.5 lifts the floor tops up one).
func _mapsim_lift_grid() -> void:
	if _grid_system and is_instance_valid(_grid_system):
		_grid_system.transform.origin.y = 0.5


# ── Walk-through mode ─────────────────────────────────────────────────
## Load a map into the LIT default world and frame it first-person, for
## looking at a map like a gallery. Reuses load_map_fresh + PLAYER camera;
## keeps the sky/lights (no capture backdrop, no near-black bridge world).
func _walk_setup(map_name: String) -> void:
	if not load_map_fresh(map_name):
		_set_status("Walk: map '%s' not found" % map_name)
		return
	_mapsim_lift_grid()
	# Let the interactables place, then frame the row.
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(1.4).timeout
	set_camera_mode(CameraMode.PLAYER)
	fly_mode_enabled = true
	_frame_walk_camera()
	_set_status("Walk-through: %s — F fly, WASD move, E/Q up/down, mouse look" % map_name)

## Step focus to the next/previous placed artifact and frame it by its own
## world AABB, so each member fills the view at a distance matched to its size.
var _walk_focus: int = -1
func _walk_focus_step(dir: int) -> void:
	if not _preview_camera:
		return
	var arts := _collect_all_artifacts()
	if arts.is_empty():
		return
	# order left-to-right so [ ] walks the row in the order it reads
	arts.sort_custom(func(a, b): return (a as Node3D).global_position.x < (b as Node3D).global_position.x)
	_walk_focus = wrapi(_walk_focus + dir, 0, arts.size())
	var node: Node3D = arts[_walk_focus]
	var aabb := _node_world_aabb(node)
	var c := aabb.get_center()
	var size := aabb.size
	# stand back proportional to the larger of width/height, along -Z from
	# the artifact's front (these bodies face roughly +Z in the row).
	var reach: float = maxf(maxf(size.x, size.y), size.z) * 1.15 + 1.2
	_preview_camera.global_position = Vector3(c.x, c.y + size.y * 0.10, c.z + reach)
	_preview_camera.look_at(c, Vector3.UP)
	_fly_yaw = _preview_camera.rotation.y
	_fly_pitch = _preview_camera.rotation.x
	var lookup: String = str(node.get_meta("artifact_lookup_name", node.name))
	_set_status("Walk %d/%d: %s  ([ ] step · 0 overview)" % [_walk_focus + 1, arts.size(), lookup])

## World-space AABB of an artifact subtree (union of its mesh AABBs).
func _node_world_aabb(root_node: Node) -> AABB:
	var acc := AABB()
	var have := false
	var stack: Array = [root_node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D:
			var wab: AABB = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).get_aabb()
			acc = wab if not have else acc.merge(wab)
			have = true
		for c in n.get_children():
			stack.append(c)
	return acc if have else AABB((root_node as Node3D).global_position, Vector3.ONE)

## Position the first-person camera a few metres in front of the artifact
## row, at eye height, looking at its centroid — so the framing is correct
## regardless of the grid's map->world axis convention.
func _frame_walk_camera() -> void:
	if not _preview_camera:
		return
	var arts := _collect_all_artifacts()
	if arts.is_empty():
		return
	var centroid := Vector3.ZERO
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for node in arts:
		var p: Vector3 = (node as Node3D).global_position
		centroid += p
		lo = lo.min(p)
		hi = hi.max(p)
	centroid /= float(arts.size())
	# Stand back along the SHORT axis of the row so the whole run is in view,
	# far enough that the widest member (the billboard) fits the frame.
	var span_x: float = hi.x - lo.x
	var span_z: float = hi.z - lo.z
	var eye_y: float = 1.6
	var back: float = maxf(span_x, span_z) * 0.55 + 6.0
	var cam_pos: Vector3
	if span_x >= span_z:
		cam_pos = Vector3(centroid.x, eye_y, centroid.z + back)   # row runs along X
	else:
		cam_pos = Vector3(centroid.x + back, eye_y, centroid.z)   # row runs along Z
	_preview_camera.global_position = cam_pos
	_preview_camera.look_at(Vector3(centroid.x, eye_y + 0.4, centroid.z), Vector3.UP)
	_fly_yaw = _preview_camera.rotation.y
	_fly_pitch = _preview_camera.rotation.x


# ── Staged artifacts: each map artifact shown WITH its dressing-room prop ──
const DressingRoomBuilderLib = preload("res://commons/artifacts/catalog/DressingRoomBuilder.gd")
var _mapsim_staged: bool = true

## After a map builds, wait for the interactables to place, then stage each.
func _mapsim_schedule_stage() -> void:
	if not _mapsim_staged:
		return
	await get_tree().create_timer(1.3).timeout
	_mapsim_stage_artifacts()

## For every placed artifact, build its dressing-room staging (support prop +
## the artifact seated on it, from staging DNA) at the artifact's cell and hide
## the bare grid artifact — so the map reads as staged, not a floor of objects.
func _mapsim_stage_artifacts() -> void:
	if not (_grid_system and is_instance_valid(_grid_system)):
		return
	# Free EVERY old staging host by name PREFIX: queue_free is deferred, so
	# the dying host still owns the name this frame and the fresh add_child
	# gets auto-renamed — an exact-name lookup then never finds it again and
	# every map switch leaks one full set of staged props (the "previous map
	# content stays" bug). Prefix matching catches the renamed survivors too.
	for c in get_children():
		if str(c.name).begins_with("MapSimStaging") or str(c.name).begins_with("@MapSimStaging"):
			c.queue_free()
	var host := Node3D.new()
	host.name = "MapSimStaging"
	add_child(host)
	var lookup_cb := Callable(self, "_lookup_artifact_info")
	var arts: Array = []
	_collect_artifacts(_grid_system, arts)
	for node in arts:
		if not (node is Node3D):
			continue
		var lookup := str(node.get_meta("artifact_lookup_name", ""))
		if lookup == "":
			continue
		var room = DressingRoomBuilderLib.load_dressing_room(lookup)
		if not (room is Dictionary):
			continue
		var staging: Node3D = DressingRoomBuilderLib.build(room, 0, lookup_cb, true)
		if staging == null:
			continue
		# Seat the staging where the artifact stood: its footing (local y=0) lands
		# on the map floor, the prop rises, its own artifact copy sits on top.
		# Must add to the tree BEFORE setting global_position — a node not yet
		# inside the tree can't resolve its global transform (it silently collapses
		# to the origin, piling every staged artifact at 0,0,0).
		host.add_child(staging)
		staging.global_position = (node as Node3D).global_position
		# Hide the bare grid artifact (the staging carries its own copy).
		(node as Node3D).visible = false

func _collect_artifacts(n: Node, out: Array) -> void:
	if n.has_meta("artifact_lookup_name"):
		out.append(n)
		return  # don't descend into an artifact's own subtree
	for c in n.get_children():
		_collect_artifacts(c, out)

func _collect_all_artifacts() -> Array:
	var out: Array = []
	if _grid_system and is_instance_valid(_grid_system):
		_collect_artifacts(_grid_system, out)
	return out

## Registry lookup for DressingRoomBuilder — scan registry/*.json for a scene path.
func _lookup_artifact_info(lookup: String) -> Dictionary:
	var registry_dir := "res://commons/artifacts/registry/"
	var dir := DirAccess.open(registry_dir)
	if dir == null:
		return {}
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(registry_dir + fname))
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


func _mapsim_bridge_poll() -> void:
	# Heartbeat + state write-back (the web reads this for aliveness + current map).
	var st := FileAccess.open(MAPSIM_STATE, FileAccess.WRITE)
	if st:
		st.store_string(JSON.stringify({
			"ts": Time.get_unix_time_from_system(),
			"pid": OS.get_process_id(),
			"map": _mapsim_current_map,
			"float": _mapsim_float,
		}))
		st.close()
	var ctl = _mapsim_read_json(MAPSIM_CONTROL)
	if ctl is Dictionary:
		var cts := float(ctl.get("ts", 0))
		if cts > _mapsim_last_ctl:
			_mapsim_last_ctl = cts
			_mapsim_apply_control(ctl)


func _mapsim_apply_control(msg: Dictionary) -> void:
	# {map} → (re)load that map fresh. The web writes the simulated map to a
	# scratch map dir and sends its name; a real map is sent by its own name.
	var m := str(msg.get("map", ""))
	if m != "":
		# purge the previous map's staging NOW — not 1.3s later when the new
		# stage pass runs (and never, when staging is off)
		for c in get_children():
			if str(c.name).begins_with("MapSimStaging") or str(c.name).begins_with("@MapSimStaging"):
				c.queue_free()
		load_map_fresh(m)
		_mapsim_current_map = m
		_mapsim_lift_grid()
		_mapsim_schedule_stage()
		_set_status("map-sim: " + m)
	# Toggle staged props from the web ({staged:false} = bare map artifacts).
	if msg.has("staged"):
		_mapsim_staged = bool(msg["staged"])
		if _mapsim_staged:
			_mapsim_schedule_stage()
		else:
			for c in get_children():
				if str(c.name).begins_with("MapSimStaging") or str(c.name).begins_with("@MapSimStaging"):
					c.queue_free()
			for node in _collect_all_artifacts():
				if node is Node3D: (node as Node3D).visible = true
	var wm := str(msg.get("window", ""))
	if wm != "":
		_mapsim_apply_window(wm)


func _mapsim_apply_window(mode: String) -> void:
	var w: Window = get_window()
	var embedded: bool = w != null and w.is_embedded()
	if mode == "float":
		_mapsim_float = true
		if not embedded:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
			DisplayServer.window_set_size(Vector2i(760, 560))
			DisplayServer.window_set_position(Vector2i(60, 60))
		_mapsim_set_ui_visible(false)
	elif mode == "normal":
		_mapsim_float = false
		if not embedded:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, false)
		_mapsim_set_ui_visible(true)


## Hide the catalog's overlays/panels so the float window shows only the map.
func _mapsim_set_ui_visible(v: bool) -> void:
	for n in [_status_label, _overlay, _map_data_editor, _layer_editor_panel, _map_browser]:
		if n != null and is_instance_valid(n) and "visible" in n:
			n.visible = v


func _mapsim_read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return null
	var txt := f.get_as_text()
	f.close()
	return JSON.parse_string(txt)


## Viewer camera: scroll = zoom, left-drag = orbit, right/middle-drag = pan
## across the map plane. Modifies the orbit params; SPIN's _physics_process
## (spin_speed 0) re-reads them each frame and re-seats the camera.
func _mapsim_camera_input(event: InputEvent) -> void:
	if not _preview_camera:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_radius = maxf(_orbit_radius * 0.88, 1.5)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_radius = minf(_orbit_radius * 1.14, 600.0)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_spin_angle -= mm.relative.x * 0.006
			_orbit_height = clampf(_orbit_height + mm.relative.y * 0.06, 0.5, 300.0)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			var right: Vector3 = _preview_camera.global_transform.basis.x
			var fwd: Vector3 = _preview_camera.global_transform.basis.z
			var fwd_flat: Vector3 = Vector3(fwd.x, 0.0, fwd.z)
			if fwd_flat.length() > 0.001:
				fwd_flat = fwd_flat.normalized()
			var pan: float = _orbit_radius * 0.0016
			_orbit_center -= right * mm.relative.x * pan
			_orbit_center += fwd_flat * mm.relative.y * pan


## Read runtime flag for capture-active. Mirrors GridSystem's helper.
func _runtime_flag_active() -> bool:
	var path := "res://ada_run/runtime_flags.json"
	if not FileAccess.file_exists(path): return false
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return false
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK: f.close(); return false
	f.close()
	var data = json.data
	return data is Dictionary and bool(data.get("_capture_active", false))


## Replace the catalog's default WorldEnvironment with a capture-friendly
## one: dark solid background, no sun, no fog. Lights become flat fill
## so cubes read by colour, not by lit/shadowed sides. Cleanest possible
## structural backdrop for the spine-research gallery.
func _apply_capture_environment_if_active() -> void:
	if not _runtime_flag_active(): return
	if _world_environment:
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.06, 0.07, 0.10)        # near-black
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.55, 0.58, 0.65)
		env.ambient_light_energy = 1.0
		env.ssao_enabled = false
		env.glow_enabled = false
		env.fog_enabled = false
		_world_environment.environment = env
	# Drop sun intensity so the lens-flare ribbon goes away.
	if _key_light:
		_key_light.light_energy = 0.4
		_key_light.shadow_enabled = false
	if _fill_light:
		_fill_light.light_energy = 0.7
	# Hide the catalog's grey "Floor" plate — its size dominates the
	# orthographic frame even though the cube grid is the subject.
	var floor_node := get_node_or_null("Floor")
	if floor_node:
		floor_node.visible = false
	print("MapCatalogDesktop3D: capture environment applied (floor hidden, lights damped)")

func _start_default_spin() -> void:
	set_camera_mode(CameraMode.SPIN)

## Load a map by destroying any old grid and creating a fresh one.
func load_map_fresh(map_name: String) -> bool:
	_destroy_old_grids()

	var grid_scene := load(GRID_SYSTEM_SCENE_PATH)
	if not (grid_scene is PackedScene):
		push_warning("MapCatalogDesktop3D: Cannot load grid_system.tscn")
		return false

	_grid_system = (grid_scene as PackedScene).instantiate() as Node3D
	if not _grid_system:
		return false

	# Set map_name BEFORE adding to tree so it loads on _ready()
	if "map_name" in _grid_system:
		_grid_system.map_name = map_name

	# Map-simulator bridge: no world (skip ecosystem / biome / nature sky).
	if _mapsim_bridge_on and "bare_world" in _grid_system:
		_grid_system.bare_world = true

	_grid_system.transform.origin = Vector3(0.0, -0.5, 0.0)
	add_child(_grid_system)

	# Notify the JSON editor overlay of the new map
	if _map_data_editor:
		_map_data_editor.set_current_map(map_name)

	# Listen for generation complete to recenter orbit
	if _grid_system.has_signal("map_generation_complete"):
		_grid_system.map_generation_complete.connect(_on_map_generation_complete)

	return true

func _destroy_old_grids() -> void:
	if _grid_system and is_instance_valid(_grid_system):
		remove_child(_grid_system)
		_grid_system.queue_free()
		_grid_system = null

	for node in get_tree().get_nodes_in_group("grid_system"):
		if is_instance_valid(node) and node.get_parent():
			node.get_parent().remove_child(node)
			node.queue_free()

## Create a fresh GridSystem for each map load — destroy old one first.
func ensure_grid_system() -> Node3D:
	# Kill the old one completely
	if _grid_system and is_instance_valid(_grid_system):
		_grid_system.queue_free()
		_grid_system = null

	# Also kill any other grid systems lingering in the scene
	for node in get_tree().get_nodes_in_group("grid_system"):
		if is_instance_valid(node):
			node.queue_free()

	# Instantiate fresh
	var grid_scene := load(GRID_SYSTEM_SCENE_PATH)
	if not (grid_scene is PackedScene):
		push_warning("MapCatalogDesktop3D: Cannot load grid_system.tscn")
		return null

	_grid_system = (grid_scene as PackedScene).instantiate() as Node3D
	if not _grid_system:
		return null

	_grid_system.transform.origin = Vector3(0.0, -0.5, 0.0)
	add_child(_grid_system)

	# Listen for map load to recenter orbit
	if _grid_system.has_signal("map_generation_complete"):
		_grid_system.map_generation_complete.connect(_on_map_generation_complete)

	return _grid_system

## Reload the current map after its JSON was edited and saved.
func _on_map_data_saved(map_name: String) -> void:
	if map_name.is_empty():
		return
	# Re-load the map so changes are visible immediately
	load_map_fresh(map_name)
	_set_status("Reloaded %s after JSON edit" % map_name)

## Recenter orbit on the loaded map.
func _on_map_generation_complete() -> void:
	_update_orbit_center()
	# Re-apply spin if active
	if _camera_mode == CameraMode.SPIN:
		_start_spin_camera()

## Calculate orbit center from grid dimensions, with AABB fallback.
func _update_orbit_center() -> void:
	if not _grid_system or not is_instance_valid(_grid_system):
		return

	# Try grid data_component first
	var data_comp = _grid_system.get("data_component") if "data_component" in _grid_system else null
	if data_comp and data_comp.has_method("get_grid_dimensions"):
		var dims: Vector3i = data_comp.get_grid_dimensions()
		if dims.x > 0 or dims.z > 0:
			var grid_origin: Vector3 = _grid_system.global_transform.origin
			_orbit_center = grid_origin + Vector3(float(dims.x) * 0.5, float(dims.y) * 0.5 + 0.5, float(dims.z) * 0.5)
			var map_extent := maxf(float(dims.x), float(dims.z))
			_orbit_radius = maxf(map_extent * 0.78, 5.5)
			_orbit_height = maxf(maxf(float(dims.y) + 2.5, map_extent * 0.95), 5.0)
			return

	# Fallback: compute AABB from all visible geometry in the scene
	var aabb := _compute_scene_aabb(_grid_system)
	# If grid system AABB is tiny, try the whole scene
	if aabb.size.length() < 0.1:
		aabb = _compute_scene_aabb(self)
	if aabb.size.length() > 0.1:
		_orbit_center = aabb.get_center()
		var map_extent := maxf(aabb.size.x, aabb.size.z)
		_orbit_radius = maxf(map_extent * 0.78, 5.5)
		_orbit_height = maxf(maxf(aabb.size.y + 2.5, map_extent * 0.95), 5.0)

## Compute a merged AABB from all VisualInstance3D nodes under a root.
func _compute_scene_aabb(root: Node3D) -> AABB:
	var merged := AABB()
	var first := true
	for child in root.get_children():
		# Skip cameras and lights
		if child is Camera3D or child is Light3D:
			continue
		if child is VisualInstance3D and child.visible:
			var child_aabb := (child as VisualInstance3D).get_aabb()
			if child_aabb.size.length() < 0.01:
				continue
			var global_aabb: AABB = child.global_transform * child_aabb
			if first:
				merged = global_aabb
				first = false
			else:
				merged = merged.merge(global_aabb)
		if child is Node3D and child.get_child_count() > 0:
			var sub := _compute_scene_aabb(child as Node3D)
			if sub.size.length() > 0.01:
				if first:
					merged = sub
					first = false
				else:
					merged = merged.merge(sub)
	return merged

func _unhandled_input(event: InputEvent) -> void:
	# Map-simulator bridge: a plain viewer — orbit / pan / zoom only, no editing
	# and no fly. (SPIN mode's _physics_process re-reads the orbit params below.)
	if _mapsim_bridge_on:
		_mapsim_camera_input(event)
		return

	# Walk-through focus stepping: [ / ] snap to each artifact framed at ITS
	# own size (so the billboard fills the view instead of sitting far off);
	# 0 returns to the whole-row overview. Handled before edit-mode's E.
	if _walk_mode and event is InputEventKey:
		var wk := event as InputEventKey
		if wk.pressed and not wk.echo:
			var code := wk.keycode
			if code == KEY_BRACKETRIGHT:
				_walk_focus_step(1); get_viewport().set_input_as_handled(); return
			elif code == KEY_BRACKETLEFT:
				_walk_focus_step(-1); get_viewport().set_input_as_handled(); return
			elif code == KEY_0:
				_frame_walk_camera(); _set_status("Walk: row overview"); get_viewport().set_input_as_handled(); return

	# E key toggles edit mode
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and (key.keycode == KEY_E or key.physical_keycode == KEY_E):
			if not _is_text_focused():
				_toggle_edit_mode()
				get_viewport().set_input_as_handled()
				return

	# Edit mode handles its own input
	if _edit_mode:
		_handle_edit_input(event)
		return

	if _is_fly_toggle_event(event):
		fly_mode_enabled = not fly_mode_enabled
		_sync_mouse_look_state()
		_set_status("Fly mode %s" % ("enabled" if fly_mode_enabled else "disabled"))
		get_viewport().set_input_as_handled()
		return

	if not fly_mode_enabled:
		return

	if fly_look_requires_button and event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == look_mouse_button:
			_set_mouse_look(mouse_button_event.pressed)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and _is_mouse_look_active:
		_apply_mouse_look((event as InputEventMouseMotion).relative)
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if _edit_mode:
		# In edit mode, camera is manually controlled via _handle_edit_input
		return

	_sync_mouse_look_state()

	# Handle spin mode regardless of fly_mode or overlay visibility
	if _camera_mode == CameraMode.SPIN and _preview_camera:
		# Arrow key adjustments
		if Input.is_key_pressed(KEY_UP):
			_orbit_height += 4.0 * delta
		if Input.is_key_pressed(KEY_DOWN):
			_orbit_height = maxf(_orbit_height - 4.0 * delta, 0.5)
		if Input.is_key_pressed(KEY_LEFT):
			_orbit_radius = maxf(_orbit_radius - 4.0 * delta, 2.0)
		if Input.is_key_pressed(KEY_RIGHT):
			_orbit_radius += 4.0 * delta

		_spin_angle += _spin_speed * delta
		if _spin_angle > TAU:
			_spin_angle -= TAU
		var x := _orbit_center.x + _orbit_radius * cos(_spin_angle)
		var z := _orbit_center.z + _orbit_radius * sin(_spin_angle)
		_preview_camera.global_position = Vector3(x, _orbit_center.y + _orbit_height, z)
		_preview_camera.look_at(_orbit_center, Vector3.UP)
		return

	if not fly_mode_enabled:
		return

	if _overlay and _overlay.visible:
		return

	# Only allow WASD fly in STATIC or PLAYER modes
	if _camera_mode == CameraMode.STATIC or _camera_mode == CameraMode.PLAYER:
		_apply_fly_translation(delta)

# ---------------------------------------------------------------------------
# Camera mode API — called from overlay buttons
# ---------------------------------------------------------------------------

func set_camera_mode(mode_int: int) -> void:
	var mode: CameraMode = mode_int as CameraMode
	_camera_mode = mode

	match mode:
		CameraMode.STATIC:
			_apply_static_camera()
		CameraMode.ISOMETRIC:
			_apply_isometric_camera()
		CameraMode.SPIN:
			_start_spin_camera()
		CameraMode.PLAYER:
			_apply_player_camera()

	_set_status(_camera_mode_label(mode))

func _camera_mode_label(mode: CameraMode) -> String:
	match mode:
		CameraMode.STATIC:
			return "Camera: Static (default elevated view)"
		CameraMode.ISOMETRIC:
			return "Camera: Isometric (45° top-down)"
		CameraMode.SPIN:
			return "Camera: Spin (orbiting around center)"
		CameraMode.PLAYER:
			return "Camera: Player perspective (ground level, WASD fly)"
	return "Camera mode changed"

func _apply_static_camera() -> void:
	if not _preview_camera:
		return
	_preview_camera.global_position = _static_camera_position
	_preview_camera.rotation = _static_camera_rotation
	_fly_yaw = _static_camera_rotation.y
	_fly_pitch = _static_camera_rotation.x
	fly_mode_enabled = true

func _apply_isometric_camera() -> void:
	if not _preview_camera:
		return
	# Classic isometric-ish: elevated 45° angle from a corner
	_preview_camera.global_position = Vector3(10.0, 12.0, 10.0)
	_preview_camera.look_at(Vector3.ZERO, Vector3.UP)
	_fly_yaw = _preview_camera.rotation.y
	_fly_pitch = _preview_camera.rotation.x
	fly_mode_enabled = false

func _start_spin_camera() -> void:
	if not _preview_camera:
		return
	# Recenter on actual scene content every time spin starts
	_update_orbit_center()
	# Start spinning from current angle
	var cam_pos := _preview_camera.global_position
	var dx := cam_pos.x - _orbit_center.x
	var dz := cam_pos.z - _orbit_center.z
	_spin_angle = atan2(dz, dx)
	fly_mode_enabled = false

func _apply_player_camera() -> void:
	if not _preview_camera:
		return
	# Ground-level first-person view
	_preview_camera.global_position = Vector3(0.0, 1.6, 0.0)
	_preview_camera.rotation = Vector3(0.0, 0.0, 0.0)
	_fly_yaw = 0.0
	_fly_pitch = 0.0
	fly_mode_enabled = true

# ---------------------------------------------------------------------------
# Existing functionality
# ---------------------------------------------------------------------------

func _on_sequence_selected(sequence_name: String) -> void:
	_send_to_claude("sequence_selected", sequence_name)
	if _overlay and _overlay.start_sequence_via_best_path(sequence_name):
		_set_status("Starting sequence: %s" % sequence_name)
		return

	push_warning("MapCatalogDesktop3D: Could not start sequence: %s" % sequence_name)
	_set_status("Could not start sequence: %s" % sequence_name)

func _on_map_selected(map_name: String) -> void:
	_send_to_claude("map_selected", map_name)
	if _overlay and _overlay.load_map_via_best_path(map_name):
		_set_status("Loading map: %s" % map_name)
		return

	push_warning("MapCatalogDesktop3D: Could not load map: %s" % map_name)
	_set_status("Could not load map: %s" % map_name)

## Claude Bridge — send selection events to local Claude Code session
func _send_to_claude(event_type: String, value: String) -> void:
	var http := HTTPRequest.new()
	http.name = "ClaudeBridgeHTTP"
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	var payload := JSON.stringify({
		"text": "Map catalog: %s — %s" % [event_type, value],
		"type": event_type,
		"name": value,
		"source": "MapCatalogDesktop3D",
	})
	var err := http.request(
		"http://127.0.0.1:9876/message",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		payload
	)
	if err != OK:
		http.queue_free()  # Clean up on failure

func _is_fly_toggle_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false

	return key_event.keycode == fly_toggle_key or key_event.physical_keycode == fly_toggle_key

func _set_mouse_look(enabled: bool) -> void:
	if not fly_mode_enabled:
		enabled = false

	if enabled and _overlay and _overlay.is_mouse_over_panel():
		enabled = false
	if enabled and _layer_editor_panel and _layer_editor_panel.is_mouse_over_panel():
		enabled = false

	_is_mouse_look_active = enabled
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE

func _sync_mouse_look_state() -> void:
	var overlay_blocking := _overlay and _overlay.is_mouse_over_panel()
	if not overlay_blocking and _layer_editor_panel and _layer_editor_panel.is_mouse_over_panel():
		overlay_blocking = true
	var should_capture := fly_mode_enabled and not overlay_blocking and (not fly_look_requires_button or _is_mouse_look_active)
	if should_capture and not _is_mouse_look_active:
		_set_mouse_look(true)
	elif not should_capture and _is_mouse_look_active:
		_set_mouse_look(false)
	elif not should_capture and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_mouse_look(relative: Vector2) -> void:
	if not _preview_camera:
		return

	_fly_yaw -= relative.x * fly_look_sensitivity
	_fly_pitch -= relative.y * fly_look_sensitivity
	_fly_pitch = clamp(_fly_pitch, -PI * 0.49, PI * 0.49)
	_preview_camera.rotation = Vector3(_fly_pitch, _fly_yaw, 0.0)

func _apply_fly_translation(delta: float) -> void:
	if not _preview_camera:
		return

	var forward := 0.0
	if _is_pressed(KEY_W):
		forward += 1.0
	if _is_pressed(KEY_S):
		forward -= 1.0

	var strafe := 0.0
	if _is_pressed(KEY_D):
		strafe += 1.0
	if _is_pressed(KEY_A):
		strafe -= 1.0

	var vertical := 0.0
	if _is_pressed(fly_up_key) or _is_pressed(KEY_SPACE) or _is_pressed(KEY_PAGEUP) or _is_pressed(KEY_R):
		vertical += 1.0
	if _is_pressed(fly_down_key) or _is_pressed(KEY_CTRL) or _is_pressed(KEY_PAGEDOWN) or _is_pressed(KEY_C) or _is_pressed(KEY_X) or _is_pressed(KEY_Z):
		vertical -= 1.0

	var move_vector := Vector3.ZERO
	move_vector += -_preview_camera.global_transform.basis.z * forward
	move_vector += _preview_camera.global_transform.basis.x * strafe
	move_vector += Vector3.UP * vertical

	if move_vector.length_squared() <= 0.0001:
		return

	var speed := fly_speed
	if _is_pressed(KEY_SHIFT):
		speed *= fly_boost_multiplier

	_preview_camera.global_position += move_vector.normalized() * speed * delta

func _is_pressed(keycode: Key) -> bool:
	return Input.is_key_pressed(keycode) or Input.is_physical_key_pressed(keycode)

func _set_status(text: String) -> void:
	if _status_label:
		var fly_state := "ON" if fly_mode_enabled else "OFF"
		var look_hint := "RMB look" if fly_look_requires_button else "Mouse steers"
		_status_label.text = "%s\nFly %s: F toggle, %s, WASD move, up E/Space/PgUp/R, down Q/Ctrl/PgDn/C/X/Z" % [text, fly_state, look_hint]

func _is_text_focused() -> bool:
	var vp := get_viewport()
	if not vp:
		return false
	var focused := vp.gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit

func _mark_clean_keep(node: Node) -> void:
	if node:
		node.add_to_group(CLEAN_KEEP_GROUP)

# ---------------------------------------------------------------------------
# EDIT MODE — click to add/remove cubes, mouse orbit/pan/zoom
# ---------------------------------------------------------------------------

var _edit_mode: bool = false
var _edit_paint_height: int = 1  # height value to paint (1-6)
var _edit_dragging_left: bool = false
var _edit_dragging_right: bool = false
var _edit_drag_start: Vector2 = Vector2.ZERO
var _edit_last_mouse: Vector2 = Vector2.ZERO
var _edit_drag_threshold: float = 6.0  # pixels before drag vs click
var _edit_cursor: MeshInstance3D = null  # wireframe cursor showing hovered cell

# Layer editing state
var _edit_layer: String = "structure"  # "structure", "interactables", "utilities"
var _interactables_grid: Array = []  # 2D Array[z][x] of String
var _utilities_grid: Array = []      # 2D Array[z][x] of String
var _edit_layer_brush: String = ""   # current artifact/utility to place
var _edit_cell_label: Label3D = null # floating label showing cell contents
var _layer_tab_buttons: Dictionary = {}  # "structure"->Button, "interactables"->Button, "utilities"->Button
var _layer_tab_container: Control = null
var _cell_labels_3d: Dictionary = {}    # "gx,gz" -> Label3D — persistent labels for all placed items
var _cell_labels_parent: Node3D = null  # container node for all persistent labels
var _props_popup: Control = null        # right-click properties popup (CanvasLayer child)
var _props_popup_canvas: CanvasLayer = null
var _props_gx: int = -1                # grid coords for currently open popup
var _props_gz: int = -1

func _toggle_edit_mode() -> void:
	_edit_mode = not _edit_mode
	if _edit_mode:
		# Switch to edit camera: stop spin, enable mouse
		_spin_speed = 0.0
		fly_mode_enabled = false
		_set_mouse_look(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_create_edit_cursor()
		_load_grammar_pieces()
		_load_layer_grids()
		_edit_layer = "structure"
		_create_layer_tabs()
		_update_layer_tab_highlight()
		_set_status("EDIT MODE [Structure] — Click:+1h RClick:-1h L:layer Scroll:zoom Ctrl+S:save")
	else:
		_spin_speed = 0.3
		_remove_edit_cursor()
		_remove_cell_label()
		_remove_layer_tabs()
		_remove_edit_utility_markers()
		_clear_all_cell_labels()
		_close_props_popup()
		if _layer_editor_panel:
			_layer_editor_panel.hide_panel()
		_set_status("Edit mode off")

func _create_edit_cursor() -> void:
	if _edit_cursor:
		return
	_edit_cursor = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.05, 1.05, 1.05)
	_edit_cursor.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	_edit_cursor.material_override = mat
	_edit_cursor.visible = false
	add_child(_edit_cursor)

func _remove_edit_cursor() -> void:
	if _edit_cursor:
		_edit_cursor.queue_free()
		_edit_cursor = null

func _handle_edit_input(event: InputEvent) -> void:
	if not _edit_mode or not _preview_camera:
		return

	# Mouse button events
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		# Scroll wheel = zoom
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_radius = maxf(_orbit_radius - 1.0, 2.0)
			_update_edit_camera()
			get_viewport().set_input_as_handled()
			return
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_radius += 1.0
			_update_edit_camera()
			get_viewport().set_input_as_handled()
			return

		# Left mouse button
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_edit_dragging_left = false
				_edit_drag_start = mb.position
				_edit_last_mouse = mb.position
			else:
				# Release — if no drag, treat as click (add/remove)
				if not _edit_dragging_left:
					_edit_click(mb.position, false)
				_edit_dragging_left = false
			get_viewport().set_input_as_handled()
			return

		# Right mouse button
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_edit_dragging_right = false
				_edit_drag_start = mb.position
				_edit_last_mouse = mb.position
			else:
				if not _edit_dragging_right:
					_edit_click(mb.position, true)
				_edit_dragging_right = false
			get_viewport().set_input_as_handled()
			return

	# Mouse motion = orbit (left) or pan (right)
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not _edit_dragging_left and mm.position.distance_to(_edit_drag_start) > _edit_drag_threshold:
				_edit_dragging_left = true
			if _edit_dragging_left:
				# Left drag = orbit
				_spin_angle -= mm.relative.x * 0.005
				_orbit_height += mm.relative.y * 0.05
				_orbit_height = maxf(_orbit_height, 0.5)
				_update_edit_camera()
				get_viewport().set_input_as_handled()

		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if not _edit_dragging_right and mm.position.distance_to(_edit_drag_start) > _edit_drag_threshold:
				_edit_dragging_right = true
			if _edit_dragging_right:
				# Right drag = pan
				var right := _preview_camera.global_transform.basis.x
				var up := Vector3.UP
				var pan_speed := _orbit_radius * 0.002
				_orbit_center -= right * mm.relative.x * pan_speed
				_orbit_center += up * mm.relative.y * pan_speed
				_update_edit_camera()
				get_viewport().set_input_as_handled()
		else:
			# No button — update cursor
			_update_edit_cursor_pos(mm.position)
			# Update stamp preview position if stamp is active
			if _stamp_index >= 0:
				var stamp_result := _edit_raycast(mm.position)
				if not stamp_result.is_empty():
					var sn: Vector3 = stamp_result.normal
					var sg := _world_to_grid(stamp_result.position - sn * 0.1)
					_update_stamp_preview(sg.x, sg.z)

		_edit_last_mouse = mm.position
		return

	# Key events
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return

		# Don't process edit keys when typing in a text field
		if _is_text_focused():
			return

		# Number keys 1-6 set paint height
		if key.keycode >= KEY_1 and key.keycode <= KEY_6:
			_edit_paint_height = key.keycode - KEY_0
			_set_status("EDIT — Paint height: %d" % _edit_paint_height)
			get_viewport().set_input_as_handled()
			return

		# Ctrl+S = save
		if key.keycode == KEY_S and key.ctrl_pressed:
			_edit_save_map()
			get_viewport().set_input_as_handled()
			return

		# Ctrl+Z = undo
		if key.keycode == KEY_Z and key.ctrl_pressed and not key.shift_pressed:
			_undo()
			get_viewport().set_input_as_handled()
			return

		# Ctrl+Y or Ctrl+Shift+Z = redo
		if (key.keycode == KEY_Y and key.ctrl_pressed) or (key.keycode == KEY_Z and key.ctrl_pressed and key.shift_pressed):
			_redo()
			get_viewport().set_input_as_handled()
			return

		# Tab / Shift+Tab = browse stamp pieces
		if key.keycode == KEY_TAB:
			if key.shift_pressed:
				_stamp_select_prev()
			else:
				_stamp_select_next()
			get_viewport().set_input_as_handled()
			return

		# R = rotate stamp 90° CW
		if key.keycode == KEY_R and _stamp_index >= 0:
			_stamp_rotation = (_stamp_rotation + 90) % 360
			if _stamp_grid_pos.x >= 0:
				_update_stamp_preview(_stamp_grid_pos.x, _stamp_grid_pos.y)
			_set_status("STAMP — Rotation: %d°" % _stamp_rotation)
			get_viewport().set_input_as_handled()
			return

		# M = mirror stamp on X axis
		if key.keycode == KEY_M and _stamp_index >= 0:
			_stamp_mirror_x = not _stamp_mirror_x
			if _stamp_grid_pos.x >= 0:
				_update_stamp_preview(_stamp_grid_pos.x, _stamp_grid_pos.y)
			_set_status("STAMP — Mirror: %s" % ("ON" if _stamp_mirror_x else "OFF"))
			get_viewport().set_input_as_handled()
			return

		# Enter = place stamp
		if key.keycode == KEY_ENTER and _stamp_index >= 0:
			_stamp_place()
			get_viewport().set_input_as_handled()
			return

		# Escape = close popup, cancel stamp, or exit edit mode
		if key.keycode == KEY_ESCAPE:
			if _is_props_popup_visible():
				_close_props_popup()
			elif _stamp_index >= 0:
				_stamp_cancel()
			else:
				_toggle_edit_mode()
			get_viewport().set_input_as_handled()
			return

		# L = cycle edit layer
		if key.keycode == KEY_L:
			_cycle_edit_layer()
			get_viewport().set_input_as_handled()
			return

		# Delete = remove artifact/utility at hovered cell
		if key.keycode == KEY_DELETE and _edit_layer != "structure":
			_remove_at_hovered_cell()
			get_viewport().set_input_as_handled()
			return

		# 0 = paint void (height 0)
		if key.keycode == KEY_0:
			_edit_paint_height = 0
			_set_status("EDIT — Paint height: 0 (void)")
			get_viewport().set_input_as_handled()
			return

func _update_edit_camera() -> void:
	if not _preview_camera:
		return
	var x := _orbit_center.x + _orbit_radius * cos(_spin_angle)
	var z := _orbit_center.z + _orbit_radius * sin(_spin_angle)
	_preview_camera.global_position = Vector3(x, _orbit_center.y + _orbit_height, z)
	_preview_camera.look_at(_orbit_center, Vector3.UP)

func _edit_raycast(screen_pos: Vector2) -> Dictionary:
	"""Raycast from camera through screen position. Returns {position, normal, collider} or empty."""
	if not _preview_camera:
		return {}
	var from := _preview_camera.project_ray_origin(screen_pos)
	var dir := _preview_camera.project_ray_normal(screen_pos)
	var space := get_world_3d().direct_space_state
	if not space:
		return {}
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 100.0)
	return space.intersect_ray(query)

func _world_to_grid(world_pos: Vector3) -> Vector3i:
	"""Convert world position to grid coordinates."""
	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size
	return Vector3i(roundi(world_pos.x / total_size), roundi(world_pos.y / total_size), roundi(world_pos.z / total_size))

func _update_edit_cursor_pos(screen_pos: Vector2) -> void:
	if not _edit_cursor:
		return
	var result := _edit_raycast(screen_pos)
	if result.is_empty():
		_edit_cursor.visible = false
		_hide_cell_label()
		return
	var hit_normal: Vector3 = result.normal
	var grid_pos := _world_to_grid(result.position - hit_normal * 0.1)
	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size
	# Show cursor at the top of the column
	var sc := _get_structure_component()
	if sc and grid_pos.x >= 0 and grid_pos.x < sc.grid_x and grid_pos.z >= 0 and grid_pos.z < sc.grid_z:
		var top_y := 0
		for y in range(sc.grid_y - 1, -1, -1):
			if sc.grid[grid_pos.x][y][grid_pos.z]:
				top_y = y
				break

		if _edit_layer == "structure":
			_edit_cursor.global_position = Vector3(grid_pos.x, top_y, grid_pos.z) * total_size
			_edit_cursor.visible = true
			_hide_cell_label()
		elif _edit_layer == "interactables":
			# Show cursor at ground level with green tint
			_edit_cursor.global_position = Vector3(grid_pos.x, 0, grid_pos.z) * total_size
			_edit_cursor.visible = true
			var cell_val := _get_interactable_at(grid_pos.x, grid_pos.z)
			_show_cell_label(cell_val, Vector3(grid_pos.x, top_y + 1.5, grid_pos.z) * total_size)
		elif _edit_layer == "utilities":
			_edit_cursor.global_position = Vector3(grid_pos.x, 0, grid_pos.z) * total_size
			_edit_cursor.visible = true
			var cell_val := _get_utility_at(grid_pos.x, grid_pos.z)
			_show_cell_label(cell_val, Vector3(grid_pos.x, top_y + 1.5, grid_pos.z) * total_size)
	else:
		_edit_cursor.visible = false
		_hide_cell_label()

func _edit_click(screen_pos: Vector2, is_right: bool) -> void:
	"""2.5D heightmap editor: Left click = +1 layer, Right click = -1 layer.
	Hold Shift + click to set column to exact paint_height (number keys 1-6).
	If a stamp is active, click places the stamp instead.
	In interactables/utilities mode: Left click = place brush, Right click = remove."""
	var result := _edit_raycast(screen_pos)
	if result.is_empty():
		return

	# Check if click is over the layer editor panel
	if _layer_editor_panel and _layer_editor_panel.is_mouse_over_panel():
		return

	# Check if click is over the properties popup
	if _is_props_popup_visible():
		var mouse_pos := get_viewport().get_mouse_position()
		if _props_popup and _props_popup.get_global_rect().has_point(mouse_pos):
			return  # Click is inside popup, let it handle
		else:
			_close_props_popup()  # Click outside popup, close it

	# Route to layer-specific click handler
	if _edit_layer == "interactables":
		_edit_click_interactable(result, is_right)
		return
	elif _edit_layer == "utilities":
		_edit_click_utility(result, is_right)
		return

	# If stamp is active, place it on click
	if _stamp_index >= 0 and not is_right:
		var hit_normal_s: Vector3 = result.normal
		var grid_pos_s := _world_to_grid(result.position - hit_normal_s * 0.1)
		_stamp_grid_pos = Vector2i(grid_pos_s.x, grid_pos_s.z)
		_stamp_place()
		return
	elif _stamp_index >= 0 and is_right:
		_stamp_cancel()
		return

	var hit_pos: Vector3 = result.position
	var hit_normal: Vector3 = result.normal
	var sc := _get_structure_component()
	if not sc:
		return

	# Find which x,z column we hit
	var grid_pos := _world_to_grid(hit_pos - hit_normal * 0.1)
	var gx: int = grid_pos.x
	var gz: int = grid_pos.z

	if gx < 0 or gx >= sc.grid_x or gz < 0 or gz >= sc.grid_z:
		return

	# Get current height at this column
	var current_height := 0
	for y in range(sc.grid_y - 1, -1, -1):
		if sc.grid[gx][y][gz]:
			current_height = y + 1
			break

	# Determine target height
	var target_height: int
	if Input.is_key_pressed(KEY_SHIFT):
		# Shift+click: set to exact paint height (or 0 for right click)
		target_height = 0 if is_right else _edit_paint_height
	else:
		# Normal click: increment/decrement by 1
		if is_right:
			target_height = maxi(current_height - 1, 0)
		else:
			target_height = mini(current_height + 1, sc.grid_y)

	if target_height == current_height:
		return

	_push_undo()

	# Remove cubes above target height
	for y in range(target_height, sc.grid_y):
		if sc.grid[gx][y][gz]:
			sc.remove_cube_at(gx, y, gz)

	# Add cubes below target height that are missing
	for y in range(0, target_height):
		if not sc.grid[gx][y][gz]:
			sc.add_cube_at(gx, y, gz)

	# Update the structure data in data component so saves are correct
	_update_structure_data(gx, gz, target_height)

	_set_status("EDIT — Column %d,%d → h=%d" % [gx, gz, target_height])

func _update_structure_data(x: int, z: int, height: int) -> void:
	"""Update the underlying structure layout data at x,z to the new height."""
	if not _grid_system:
		return
	var dc = _grid_system.get("data_component") if "data_component" in _grid_system else null
	if not dc:
		return
	var sd = dc.get_structure_data() if dc.has_method("get_structure_data") else null
	if not sd or not ("layout_data" in sd):
		return
	var layout: Array = sd.layout_data
	if z < layout.size() and x < layout[z].size():
		layout[z][x] = str(height)

func _remove_collision_at(grid_pos: Vector3i) -> void:
	"""Remove collision body at grid position."""
	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size
	var target_world := Vector3(grid_pos.x, grid_pos.y, grid_pos.z) * total_size
	for body in get_tree().get_nodes_in_group("grid_cubes"):
		if body is StaticBody3D and body.position.distance_to(target_world) < 0.1:
			body.queue_free()
			return

func _get_structure_component() -> GridStructureComponent:
	if _grid_system and "structure_component" in _grid_system:
		return _grid_system.structure_component as GridStructureComponent
	return null

func _get_interactables_component() -> GridInteractablesComponent:
	if _grid_system and "interactables_component" in _grid_system:
		return _grid_system.interactables_component as GridInteractablesComponent
	return null

func _get_utilities_component() -> GridUtilitiesComponent:
	if _grid_system and "utilities_component" in _grid_system:
		return _grid_system.utilities_component as GridUtilitiesComponent
	return null

func _edit_save_map() -> void:
	"""Save current grid state back to map_data.json."""
	if not _grid_system:
		_set_status("EDIT — No grid system to save")
		return

	var sc := _get_structure_component()
	var dc = _grid_system.get("data_component") if "data_component" in _grid_system else null
	if not sc or not dc:
		_set_status("EDIT — Missing structure/data component")
		return

	# Get structure layout — already updated live by _update_structure_data
	var new_structure: Array = []
	var sd = dc.get_structure_data() if dc and dc.has_method("get_structure_data") else null
	if sd and "layout_data" in sd and sd.layout_data.size() > 0:
		new_structure = sd.layout_data
	else:
		# Fallback: rebuild from grid state
		for z in range(sc.grid_z):
			var row: Array = []
			for x in range(sc.grid_x):
				var height := 0
				for y in range(sc.grid_y - 1, -1, -1):
					if sc.grid[x][y][z]:
						height = y + 1
						break
				row.append(str(height))
			new_structure.append(row)

	# Find the map_data.json path
	var map_name: String = _grid_system.map_name if "map_name" in _grid_system else ""
	if map_name.is_empty():
		_set_status("EDIT — No map name, can't save")
		return

	var candidate_paths: Array[String] = [
		"res://commons/maps/%s/map_data.json" % map_name,
	]
	var save_path := ""
	for p in candidate_paths:
		if FileAccess.file_exists(p):
			save_path = p
			break

	if save_path.is_empty():
		_set_status("EDIT — Can't find map_data.json for '%s'" % map_name)
		return

	# Read existing JSON, update structure layer, write back
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		_set_status("EDIT — Can't read %s" % save_path)
		return
	var json_text := file.get_as_text()
	file.close()

	var parser := JSON.new()
	if parser.parse(json_text) != OK:
		_set_status("EDIT — JSON parse error in %s" % save_path)
		return
	var data: Dictionary = parser.data
	if not data.has("layers"):
		data["layers"] = {}
	data["layers"]["structure"] = new_structure

	# Also save interactables and utilities if they were loaded
	if not _interactables_grid.is_empty():
		data["layers"]["interactables"] = _interactables_grid
	if not _utilities_grid.is_empty():
		data["layers"]["utilities"] = _utilities_grid

	# Update dimensions
	if data.has("map_info") and data["map_info"] is Dictionary:
		data["map_info"]["dimensions"] = {
			"width": sc.grid_x,
			"depth": sc.grid_z,
			"max_height": sc.grid_y
		}

	var out_file := FileAccess.open(save_path, FileAccess.WRITE)
	if not out_file:
		_set_status("EDIT — Can't write %s" % save_path)
		return
	# Use standard JSON.stringify then compact inner arrays onto single lines.
	# Turns multi-line ["1",\n"2",\n"3"] into ["1","2","3"] for readability.
	var json_out := JSON.stringify(data, "\t")
	json_out = _compact_inner_arrays(json_out)
	out_file.store_string(json_out)
	out_file.close()
	_set_status("EDIT — Saved to %s ✓" % save_path)

# ---------------------------------------------------------------------------
# UNDO / REDO — snapshot the whole layout + utility layer before each edit
# ---------------------------------------------------------------------------

const UNDO_MAX := 50
var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []

func _snapshot_state() -> Dictionary:
	"""Capture current layout + utility state for undo."""
	var dc = _grid_system.get("data_component") if _grid_system and "data_component" in _grid_system else null
	if not dc:
		return {}
	var sd = dc.get_structure_data() if dc.has_method("get_structure_data") else null
	if not sd or not ("layout_data" in sd):
		return {}
	# Deep copy layout
	var layout_copy: Array = []
	for row in sd.layout_data:
		var row_copy: Array = []
		for cell in row:
			row_copy.append(str(cell))
		layout_copy.append(row_copy)
	# Deep copy utility layer if present
	var utility_copy: Array = []
	var map_data := _get_current_map_data()
	if map_data.has("layers") and map_data.layers.has("utility"):
		for row in map_data.layers.utility:
			var row_copy: Array = []
			for cell in row:
				row_copy.append(str(cell) if cell != null else "")
			utility_copy.append(row_copy)

	# Deep copy interactables grid
	var interactables_copy: Array = []
	for row in _interactables_grid:
		var row_copy: Array = []
		for cell in row:
			row_copy.append(str(cell))
		interactables_copy.append(row_copy)

	# Deep copy utilities grid
	var utilities_copy: Array = []
	for row in _utilities_grid:
		var row_copy: Array = []
		for cell in row:
			row_copy.append(str(cell))
		utilities_copy.append(row_copy)

	return {"layout": layout_copy, "utility": utility_copy, "interactables": interactables_copy, "utilities_grid": utilities_copy}

func _push_undo() -> void:
	"""Push current state onto undo stack (call BEFORE making changes)."""
	var snap := _snapshot_state()
	if snap.is_empty():
		return
	_undo_stack.append(snap)
	if _undo_stack.size() > UNDO_MAX:
		_undo_stack.pop_front()
	_redo_stack.clear()

func _undo() -> void:
	if _undo_stack.is_empty():
		_set_status("EDIT — Nothing to undo")
		return
	# Push current state to redo before restoring
	var current := _snapshot_state()
	if not current.is_empty():
		_redo_stack.append(current)
	var prev: Dictionary = _undo_stack.pop_back()
	_restore_state(prev)
	_set_status("EDIT — Undo (%d left)" % _undo_stack.size())

func _redo() -> void:
	if _redo_stack.is_empty():
		_set_status("EDIT — Nothing to redo")
		return
	var current := _snapshot_state()
	if not current.is_empty():
		_undo_stack.append(current)
	var next: Dictionary = _redo_stack.pop_back()
	_restore_state(next)
	_set_status("EDIT — Redo (%d left)" % _redo_stack.size())

func _restore_state(state: Dictionary) -> void:
	"""Apply a snapshot back to the grid — rebuild structure from layout."""
	var sc := _get_structure_component()
	var dc = _grid_system.get("data_component") if _grid_system and "data_component" in _grid_system else null
	if not sc or not dc:
		return

	var layout: Array = state.get("layout", [])
	if layout.is_empty():
		return

	# Write layout back to data component
	var sd = dc.get_structure_data() if dc.has_method("get_structure_data") else null
	if sd and "layout_data" in sd:
		sd.layout_data = layout

	# Rebuild the grid visuals: clear all cubes, re-add from layout
	for x in range(sc.grid_x):
		for y in range(sc.grid_y):
			for z in range(sc.grid_z):
				if sc.grid[x][y][z]:
					sc.remove_cube_at(x, y, z)

	for z in range(mini(layout.size(), sc.grid_z)):
		for x in range(mini(layout[z].size(), sc.grid_x)):
			var h: int = int(str(layout[z][x]))
			for y in range(h):
				if y < sc.grid_y:
					sc.add_cube_at(x, y, z)

	# Restore utility layer if present
	var utility: Array = state.get("utility", [])
	if not utility.is_empty():
		var map_data := _get_current_map_data()
		if map_data.has("layers"):
			map_data.layers["utility"] = utility

	# Restore interactables grid
	var interactables: Array = state.get("interactables", [])
	if not interactables.is_empty():
		_interactables_grid = interactables

	# Restore utilities grid
	var utilities: Array = state.get("utilities_grid", [])
	if not utilities.is_empty():
		_utilities_grid = utilities

	# Refresh live visuals to match restored data
	if _edit_layer != "structure":
		_refresh_all_edit_markers()

func _get_current_map_data() -> Dictionary:
	"""Get the parsed map_data dict from the data component."""
	var dc = _grid_system.get("data_component") if _grid_system and "data_component" in _grid_system else null
	if not dc:
		return {}
	if dc.has_method("get_map_data"):
		var d = dc.get_map_data()
		if d is Dictionary:
			return d
	# Fallback: read from file
	var map_name: String = _grid_system.map_name if _grid_system and "map_name" in _grid_system else ""
	if map_name.is_empty():
		return {}
	var path := "res://commons/maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	return parser.data if parser.data is Dictionary else {}

# ---------------------------------------------------------------------------
# STAMP SYSTEM — paste voxel grammar pieces onto the grid
# ---------------------------------------------------------------------------

const GRAMMAR_PATH := "res://commons/maps/Structure_Examples/voxel_grammar_subset.json"

var _stamp_pieces: Array[Dictionary] = []  # loaded grammar pieces
var _stamp_index: int = -1                 # -1 = no stamp selected
var _stamp_rotation: int = 0               # 0, 90, 180, 270
var _stamp_mirror_x: bool = false
var _stamp_preview_meshes: Array[MeshInstance3D] = []
var _stamp_grid_pos: Vector2i = Vector2i(-1, -1)  # last hovered grid x,z

func _load_grammar_pieces() -> void:
	"""Load all pieces from the voxel grammar JSON."""
	if not _stamp_pieces.is_empty():
		return  # already loaded
	if not FileAccess.file_exists(GRAMMAR_PATH):
		push_warning("MapCatalogDesktop3D: Grammar file not found: %s" % GRAMMAR_PATH)
		return
	var file := FileAccess.open(GRAMMAR_PATH, FileAccess.READ)
	if not file:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		push_warning("MapCatalogDesktop3D: Grammar JSON parse error")
		return
	var data: Dictionary = parser.data
	if not data.has("pieces"):
		return
	for piece in data.pieces:
		if piece is Dictionary and piece.has("heightmap"):
			_stamp_pieces.append(piece)
	_set_status("EDIT — Loaded %d grammar pieces" % _stamp_pieces.size())

func _stamp_select_next() -> void:
	if _stamp_pieces.is_empty():
		_load_grammar_pieces()
	if _stamp_pieces.is_empty():
		return
	_stamp_index = (_stamp_index + 1) % _stamp_pieces.size()
	_stamp_rotation = 0
	_stamp_mirror_x = false
	var piece: Dictionary = _stamp_pieces[_stamp_index]
	_set_status("STAMP [%d/%d]: %s (%s) — R:rotate M:mirror Enter:place Esc:cancel" % [
		_stamp_index + 1, _stamp_pieces.size(),
		piece.get("name", "?"), piece.get("id", "?")])

func _stamp_select_prev() -> void:
	if _stamp_pieces.is_empty():
		_load_grammar_pieces()
	if _stamp_pieces.is_empty():
		return
	_stamp_index = (_stamp_index - 1) if _stamp_index > 0 else (_stamp_pieces.size() - 1)
	_stamp_rotation = 0
	_stamp_mirror_x = false
	var piece: Dictionary = _stamp_pieces[_stamp_index]
	_set_status("STAMP [%d/%d]: %s (%s) — R:rotate M:mirror Enter:place Esc:cancel" % [
		_stamp_index + 1, _stamp_pieces.size(),
		piece.get("name", "?"), piece.get("id", "?")])

func _stamp_cancel() -> void:
	_stamp_index = -1
	_stamp_rotation = 0
	_stamp_mirror_x = false
	_clear_stamp_preview()
	_set_status("EDIT MODE — stamp cancelled")

func _get_transformed_heightmap() -> Array:
	"""Return the current stamp piece heightmap after rotation + mirror."""
	if _stamp_index < 0 or _stamp_index >= _stamp_pieces.size():
		return []
	var piece: Dictionary = _stamp_pieces[_stamp_index]
	var hm: Array = piece.get("heightmap", [])
	if hm.is_empty():
		return []

	# Deep copy
	var result: Array = []
	for row in hm:
		var r: Array = []
		for cell in row:
			r.append(cell)
		result.append(r)

	# Apply rotation (0, 90, 180, 270) — rotate the 2D grid clockwise
	var rotations := _stamp_rotation / 90
	for _i in range(rotations):
		result = _rotate_90_cw(result)

	# Apply mirror on X axis
	if _stamp_mirror_x:
		for row in result:
			row.reverse()

	return result

static func _rotate_90_cw(grid: Array) -> Array:
	"""Rotate a 2D array 90° clockwise."""
	var rows: int = grid.size()
	if rows == 0:
		return []
	var cols: int = grid[0].size()
	var rotated: Array = []
	for c in range(cols):
		var new_row: Array = []
		for r in range(rows - 1, -1, -1):
			new_row.append(grid[r][c])
		rotated.append(new_row)
	return rotated

func _update_stamp_preview(gx: int, gz: int) -> void:
	"""Show/update a transparent preview of the stamp at grid position gx,gz."""
	_clear_stamp_preview()
	_stamp_grid_pos = Vector2i(gx, gz)

	var hm := _get_transformed_heightmap()
	if hm.is_empty():
		return

	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 1.0, 0.4, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true

	for rz in range(hm.size()):
		var row: Array = hm[rz]
		for rx in range(row.size()):
			var h: int = int(str(row[rx]))
			if h <= 0:
				continue
			for y in range(h):
				var mesh_inst := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = Vector3(0.95, 0.95, 0.95)
				mesh_inst.mesh = box
				mesh_inst.material_override = mat
				mesh_inst.global_position = Vector3(
					(gx + rx) * total_size,
					y * total_size,
					(gz + rz) * total_size
				)
				add_child(mesh_inst)
				_stamp_preview_meshes.append(mesh_inst)

func _clear_stamp_preview() -> void:
	for m in _stamp_preview_meshes:
		if is_instance_valid(m):
			m.queue_free()
	_stamp_preview_meshes.clear()

func _stamp_place() -> void:
	"""Place the current stamp at the previewed position."""
	if _stamp_index < 0 or _stamp_grid_pos.x < 0:
		return

	var sc := _get_structure_component()
	if not sc:
		return

	var hm := _get_transformed_heightmap()
	if hm.is_empty():
		return

	_push_undo()

	for rz in range(hm.size()):
		var row: Array = hm[rz]
		for rx in range(row.size()):
			var gx: int = _stamp_grid_pos.x + rx
			var gz: int = _stamp_grid_pos.y + rz
			if gx < 0 or gx >= sc.grid_x or gz < 0 or gz >= sc.grid_z:
				continue
			var target_h: int = int(str(row[rx]))

			# Get current height
			var current_h := 0
			for y in range(sc.grid_y - 1, -1, -1):
				if sc.grid[gx][y][gz]:
					current_h = y + 1
					break

			# Remove cubes above target
			for y in range(target_h, sc.grid_y):
				if sc.grid[gx][y][gz]:
					sc.remove_cube_at(gx, y, gz)

			# Add cubes below target
			for y in range(target_h):
				if y < sc.grid_y and not sc.grid[gx][y][gz]:
					sc.add_cube_at(gx, y, gz)

			_update_structure_data(gx, gz, target_h)

	var piece: Dictionary = _stamp_pieces[_stamp_index]
	_set_status("EDIT — Stamped '%s' at %d,%d" % [piece.get("name", "?"), _stamp_grid_pos.x, _stamp_grid_pos.y])
	_clear_stamp_preview()
	# Keep stamp selected for repeated placement
	_update_stamp_preview(_stamp_grid_pos.x, _stamp_grid_pos.y)

# ---------------------------------------------------------------------------
# LAYER EDITING — interactables & utilities layer support
# ---------------------------------------------------------------------------

func _load_layer_grids() -> void:
	"""Load interactables and utilities layers from map_data into in-memory grids."""
	_interactables_grid.clear()
	_utilities_grid.clear()

	var map_data := _get_current_map_data()
	if map_data.is_empty() or not map_data.has("layers"):
		return

	var layers: Dictionary = map_data["layers"]

	# Load interactables
	if layers.has("interactables") and layers["interactables"] is Array:
		for row in layers["interactables"]:
			var row_copy: Array = []
			if row is Array:
				for cell in row:
					row_copy.append(str(cell) if cell != null else " ")
			_interactables_grid.append(row_copy)

	# Load utilities
	if layers.has("utilities") and layers["utilities"] is Array:
		for row in layers["utilities"]:
			var row_copy: Array = []
			if row is Array:
				for cell in row:
					row_copy.append(str(cell) if cell != null else " ")
			_utilities_grid.append(row_copy)


func _cycle_edit_layer() -> void:
	"""Cycle through structure -> interactables -> utilities -> structure."""
	_close_props_popup()
	match _edit_layer:
		"structure":
			_edit_layer = "interactables"
		"interactables":
			_edit_layer = "utilities"
		"utilities":
			_edit_layer = "structure"
		_:
			_edit_layer = "structure"

	_update_layer_tab_highlight()
	_update_edit_cursor_color()

	# Show/hide layer editor panel
	if _layer_editor_panel:
		if _edit_layer == "interactables" or _edit_layer == "utilities":
			_layer_editor_panel.show_for_layer(_edit_layer)
		else:
			_layer_editor_panel.hide_panel()

	# Rebuild persistent 3D labels for the active layer
	_rebuild_cell_labels_for_layer()

	var status_map := {
		"structure": "EDIT [Structure] — Click:+1h RClick:-1h L:layer Ctrl+S:save",
		"interactables": "EDIT [Interactables] — Click:place RClick:edit L:layer Ctrl+S:save",
		"utilities": "EDIT [Utilities] — Click:place RClick:edit L:layer Ctrl+S:save",
	}
	_set_status(status_map.get(_edit_layer, "EDIT"))


func _set_edit_layer(layer_name: String) -> void:
	"""Set edit layer directly (from tab buttons)."""
	_close_props_popup()
	_edit_layer = layer_name
	_update_layer_tab_highlight()
	_update_edit_cursor_color()

	if _layer_editor_panel:
		if _edit_layer == "interactables" or _edit_layer == "utilities":
			_layer_editor_panel.show_for_layer(_edit_layer)
		else:
			_layer_editor_panel.hide_panel()

	# Rebuild persistent 3D labels for the active layer
	_rebuild_cell_labels_for_layer()

	var status_map := {
		"structure": "EDIT [Structure] — Click:+1h RClick:-1h L:layer Ctrl+S:save",
		"interactables": "EDIT [Interactables] — Click:place RClick:edit L:layer Ctrl+S:save",
		"utilities": "EDIT [Utilities] — Click:place RClick:edit L:layer Ctrl+S:save",
	}
	_set_status(status_map.get(_edit_layer, "EDIT"))


func _update_edit_cursor_color() -> void:
	"""Update cursor color based on active layer."""
	if not _edit_cursor or not _edit_cursor.material_override:
		return
	match _edit_layer:
		"structure":
			_edit_cursor.material_override.albedo_color = Color(0.2, 0.8, 1.0, 0.3)
		"interactables":
			_edit_cursor.material_override.albedo_color = Color(0.2, 1.0, 0.4, 0.3)
		"utilities":
			_edit_cursor.material_override.albedo_color = Color(1.0, 0.7, 0.2, 0.3)


func _on_layer_brush_selected(value: String) -> void:
	"""Callback from MapLayerEditorPanel when user selects an artifact/utility."""
	_edit_layer_brush = value
	_set_status("EDIT [%s] — Brush: %s" % [_edit_layer.capitalize(), value])


# --- Interactable/Utility grid access ---

func _get_interactable_at(gx: int, gz: int) -> String:
	if gz < 0 or gz >= _interactables_grid.size():
		return ""
	var row: Array = _interactables_grid[gz]
	if gx < 0 or gx >= row.size():
		return ""
	var val: String = str(row[gx])
	if val.strip_edges().is_empty() or val == " ":
		return ""
	return val


func _set_interactable_at(gx: int, gz: int, value: String) -> void:
	# Ensure grid is big enough
	_ensure_grid_size(_interactables_grid, gx, gz)
	_interactables_grid[gz][gx] = value


func _get_utility_at(gx: int, gz: int) -> String:
	if gz < 0 or gz >= _utilities_grid.size():
		return ""
	var row: Array = _utilities_grid[gz]
	if gx < 0 or gx >= row.size():
		return ""
	var val: String = str(row[gx])
	if val.strip_edges().is_empty() or val == " ":
		return ""
	return val


func _set_utility_at(gx: int, gz: int, value: String) -> void:
	_ensure_grid_size(_utilities_grid, gx, gz)
	_utilities_grid[gz][gx] = value


func _ensure_grid_size(grid: Array, gx: int, gz: int) -> void:
	"""Ensure the 2D grid array is large enough for position (gx, gz)."""
	while grid.size() <= gz:
		grid.append([])
	while grid[gz].size() <= gx:
		grid[gz].append(" ")


# --- Live spawn/despawn helpers ---

func _live_spawn_interactable(gx: int, gz: int, lookup_name: String) -> void:
	"""Spawn or replace the 3D artifact at grid position for immediate visual feedback."""
	var ic := _get_interactables_component()
	var sc := _get_structure_component()
	if not ic or not sc:
		return
	var y_pos: int = sc.find_highest_y_at(gx, gz)
	var total_size: float = ic.cube_size + ic.gutter
	# Remove any existing artifact at this cell first
	_live_despawn_interactable(gx, gz)
	# Use the component's _place_artifact to handle scene loading, transforms, etc.
	ic._place_artifact(gx, y_pos, gz, lookup_name, total_size)


func _live_despawn_interactable(gx: int, gz: int) -> void:
	"""Remove the 3D artifact node at grid position."""
	var ic := _get_interactables_component()
	var sc := _get_structure_component()
	if not ic or not sc:
		return
	# The artifact could be at any Y, scan the column
	for y in range(sc.grid_y - 1, -1, -1):
		var key := Vector3i(gx, y, gz)
		if ic.interactable_objects.has(key):
			var node: Node = ic.interactable_objects[key]
			if is_instance_valid(node):
				node.queue_free()
			ic.interactable_objects.erase(key)
			return
	# Also check y = grid_y (artifact placed on top of tallest column)
	var y_top: int = sc.find_highest_y_at(gx, gz)
	var key_top := Vector3i(gx, y_top, gz)
	if ic.interactable_objects.has(key_top):
		var node: Node = ic.interactable_objects[key_top]
		if is_instance_valid(node):
			node.queue_free()
		ic.interactable_objects.erase(key_top)


func _live_spawn_utility_marker(gx: int, gz: int, code: String) -> void:
	"""Spawn a simple visual marker for a utility at grid position."""
	var sc := _get_structure_component()
	if not sc:
		return
	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size
	var y_pos: int = sc.find_highest_y_at(gx, gz)
	# Remove existing marker first
	_live_despawn_utility_marker(gx, gz)
	# Create a small coloured sphere as visual indicator
	var marker := MeshInstance3D.new()
	marker.name = "EditUtilityMarker_%d_%d" % [gx, gz]
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	marker.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.7, 0.2, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = mat
	marker.position = Vector3(gx, y_pos + 0.3, gz) * total_size
	marker.set_meta("edit_utility_marker", true)
	marker.set_meta("utility_code", code)
	add_child(marker)


func _live_despawn_utility_marker(gx: int, gz: int) -> void:
	"""Remove the visual utility marker at grid position."""
	var marker_name := "EditUtilityMarker_%d_%d" % [gx, gz]
	var existing := get_node_or_null(marker_name)
	if existing and is_instance_valid(existing):
		existing.queue_free()


func _refresh_all_edit_markers() -> void:
	"""Refresh all live-spawned interactables and utility markers to match grids.
	Used after undo/redo to sync visuals with data."""
	# Clear all existing edit utility markers
	for child in get_children():
		if child.has_meta("edit_utility_marker"):
			child.queue_free()
	# Clear all spawned interactables from the component
	var ic := _get_interactables_component()
	if ic:
		ic.clear_interactables()
	# Re-spawn interactables from grid data
	var sc := _get_structure_component()
	if ic and sc:
		var total_size: float = ic.cube_size + ic.gutter
		for gz in range(_interactables_grid.size()):
			var row: Array = _interactables_grid[gz]
			for gx in range(row.size()):
				var val: String = str(row[gx]).strip_edges()
				if not val.is_empty() and val != " ":
					var y_pos: int = sc.find_highest_y_at(gx, gz)
					ic._place_artifact(gx, y_pos, gz, val, total_size)
	# Re-spawn utility markers from grid data
	for gz in range(_utilities_grid.size()):
		var row: Array = _utilities_grid[gz]
		for gx in range(row.size()):
			var val: String = str(row[gx]).strip_edges()
			if not val.is_empty() and val != " ":
				_live_spawn_utility_marker(gx, gz, val)
	# Rebuild persistent labels
	_rebuild_cell_labels_for_layer()


# --- Layer-specific click handlers ---

func _edit_click_interactable(result: Dictionary, is_right: bool) -> void:
	var hit_normal: Vector3 = result.normal
	var grid_pos := _world_to_grid(result.position - hit_normal * 0.1)
	var gx: int = grid_pos.x
	var gz: int = grid_pos.z

	var sc := _get_structure_component()
	if not sc:
		return
	if gx < 0 or gx >= sc.grid_x or gz < 0 or gz >= sc.grid_z:
		return

	if is_right:
		# Right-click: open properties popup (or show empty-cell info)
		var cell_val := _get_interactable_at(gx, gz)
		if cell_val.is_empty():
			_set_status("EDIT [Interactables] — Empty cell at %d,%d" % [gx, gz])
			return
		_open_props_popup(gx, gz, cell_val, "interactables")
	else:
		# Left-click: place brush
		if _edit_layer_brush.is_empty():
			_set_status("EDIT [Interactables] — No brush selected! Pick an artifact first.")
			return
		_push_undo()
		_set_interactable_at(gx, gz, _edit_layer_brush)
		_live_spawn_interactable(gx, gz, _edit_layer_brush)
		_update_cell_label_at(gx, gz, _edit_layer_brush)
		_set_status("EDIT [Interactables] — Placed '%s' at %d,%d" % [_edit_layer_brush, gx, gz])


func _edit_click_utility(result: Dictionary, is_right: bool) -> void:
	var hit_normal: Vector3 = result.normal
	var grid_pos := _world_to_grid(result.position - hit_normal * 0.1)
	var gx: int = grid_pos.x
	var gz: int = grid_pos.z

	var sc := _get_structure_component()
	if not sc:
		return
	if gx < 0 or gx >= sc.grid_x or gz < 0 or gz >= sc.grid_z:
		return

	if is_right:
		# Right-click: open properties popup
		var cell_val := _get_utility_at(gx, gz)
		if cell_val.is_empty():
			_set_status("EDIT [Utilities] — Empty cell at %d,%d" % [gx, gz])
			return
		_open_props_popup(gx, gz, cell_val, "utilities")
	else:
		if _edit_layer_brush.is_empty():
			_set_status("EDIT [Utilities] — No brush selected! Pick a utility first.")
			return
		_push_undo()
		_set_utility_at(gx, gz, _edit_layer_brush)
		_live_spawn_utility_marker(gx, gz, _edit_layer_brush)
		_update_cell_label_at(gx, gz, _edit_layer_brush)
		_set_status("EDIT [Utilities] — Placed '%s' at %d,%d" % [_edit_layer_brush, gx, gz])


func _remove_at_hovered_cell() -> void:
	"""Remove artifact/utility at the cell under the cursor (Delete key)."""
	if not _edit_cursor or not _edit_cursor.visible:
		return
	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size
	var cursor_pos := _edit_cursor.global_position / total_size
	var gx := roundi(cursor_pos.x)
	var gz := roundi(cursor_pos.z)

	_push_undo()
	if _edit_layer == "interactables":
		_set_interactable_at(gx, gz, " ")
		_live_despawn_interactable(gx, gz)
		_remove_cell_label_at(gx, gz)
		_set_status("EDIT [Interactables] — Removed at %d,%d" % [gx, gz])
	elif _edit_layer == "utilities":
		_set_utility_at(gx, gz, " ")
		_live_despawn_utility_marker(gx, gz)
		_remove_cell_label_at(gx, gz)
		_set_status("EDIT [Utilities] — Removed at %d,%d" % [gx, gz])


# --- Cell label (floating text showing contents) ---

func _show_cell_label(text: String, world_pos: Vector3) -> void:
	if text.is_empty():
		_hide_cell_label()
		return
	if not _edit_cell_label:
		_edit_cell_label = Label3D.new()
		_edit_cell_label.name = "EditCellLabel"
		_edit_cell_label.font_size = 20
		_edit_cell_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_edit_cell_label.no_depth_test = true
		_edit_cell_label.render_priority = 100
		_edit_cell_label.outline_size = 4
		_edit_cell_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		add_child(_edit_cell_label)

	_edit_cell_label.text = text
	_edit_cell_label.global_position = world_pos
	_edit_cell_label.visible = true

	# Color by layer type
	match _edit_layer:
		"interactables":
			_edit_cell_label.modulate = Color(0.4, 1.0, 0.5)
		"utilities":
			_edit_cell_label.modulate = Color(1.0, 0.8, 0.3)
		_:
			_edit_cell_label.modulate = Color.WHITE


func _hide_cell_label() -> void:
	if _edit_cell_label:
		_edit_cell_label.visible = false


func _remove_cell_label() -> void:
	if _edit_cell_label:
		_edit_cell_label.queue_free()
		_edit_cell_label = null


func _remove_edit_utility_markers() -> void:
	"""Remove all edit-mode utility markers from the scene."""
	for child in get_children():
		if child.has_meta("edit_utility_marker"):
			child.queue_free()


# --- Persistent 3D labels for all placed items ---

func _create_cell_label_3d(gx: int, gz: int, text: String, is_utility: bool) -> Label3D:
	"""Create a persistent 3D label floating above a grid cell."""
	var lbl := Label3D.new()
	lbl.name = "CellLabel_%d_%d" % [gx, gz]
	lbl.text = text
	lbl.font_size = 14
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.render_priority = 90
	lbl.outline_size = 6
	lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.95)
	if is_utility:
		lbl.modulate = Color(1.0, 0.85, 0.3)
	else:
		lbl.modulate = Color(0.4, 1.0, 0.55)
	# Position above the column
	var sc := _get_structure_component()
	var total_size := 1.0
	if _grid_system and "cube_size" in _grid_system:
		total_size = _grid_system.cube_size
	var top_y := 0
	if sc and gx >= 0 and gx < sc.grid_x and gz >= 0 and gz < sc.grid_z:
		for y in range(sc.grid_y - 1, -1, -1):
			if sc.grid[gx][y][gz]:
				top_y = y + 1
				break
	lbl.global_position = Vector3(gx, top_y + 1.2, gz) * total_size
	if not _cell_labels_parent:
		_cell_labels_parent = Node3D.new()
		_cell_labels_parent.name = "CellLabels3D"
		add_child(_cell_labels_parent)
	_cell_labels_parent.add_child(lbl)
	return lbl


func _rebuild_cell_labels_for_layer() -> void:
	"""Clear and recreate all persistent 3D labels for the current edit layer."""
	_clear_all_cell_labels()
	if _edit_layer == "interactables":
		for gz in range(_interactables_grid.size()):
			var row: Array = _interactables_grid[gz]
			for gx in range(row.size()):
				var val: String = str(row[gx]).strip_edges()
				if not val.is_empty() and val != " ":
					# Show only the base name (before first :)
					var display := _short_label(val)
					var lbl := _create_cell_label_3d(gx, gz, display, false)
					_cell_labels_3d["%d,%d" % [gx, gz]] = lbl
	elif _edit_layer == "utilities":
		for gz in range(_utilities_grid.size()):
			var row: Array = _utilities_grid[gz]
			for gx in range(row.size()):
				var val: String = str(row[gx]).strip_edges()
				if not val.is_empty() and val != " ":
					var lbl := _create_cell_label_3d(gx, gz, val, true)
					_cell_labels_3d["%d,%d" % [gx, gz]] = lbl
	# Structure layer: no labels


func _update_cell_label_at(gx: int, gz: int, text: String) -> void:
	"""Update or create the persistent label at a cell after placing an item."""
	var key := "%d,%d" % [gx, gz]
	if text.strip_edges().is_empty() or text == " ":
		_remove_cell_label_at(gx, gz)
		return
	var is_utility: bool = (_edit_layer == "utilities")
	var display := text if is_utility else _short_label(text)
	if _cell_labels_3d.has(key):
		var lbl: Label3D = _cell_labels_3d[key]
		if is_instance_valid(lbl):
			lbl.text = display
			return
	# Create new
	var lbl := _create_cell_label_3d(gx, gz, display, is_utility)
	_cell_labels_3d[key] = lbl


func _remove_cell_label_at(gx: int, gz: int) -> void:
	"""Remove the persistent label at a specific cell."""
	var key := "%d,%d" % [gx, gz]
	if _cell_labels_3d.has(key):
		var lbl: Label3D = _cell_labels_3d[key]
		if is_instance_valid(lbl):
			lbl.queue_free()
		_cell_labels_3d.erase(key)


func _clear_all_cell_labels() -> void:
	"""Remove all persistent 3D labels."""
	for key in _cell_labels_3d.keys():
		var lbl = _cell_labels_3d[key]
		if is_instance_valid(lbl):
			lbl.queue_free()
	_cell_labels_3d.clear()
	if _cell_labels_parent and is_instance_valid(_cell_labels_parent):
		_cell_labels_parent.queue_free()
		_cell_labels_parent = null


func _short_label(token: String) -> String:
	"""Extract just the artifact name from a token like 'name:rot:y:scale'."""
	var base := token
	# Strip #config part first
	if base.find("#") != -1:
		base = base.substr(0, base.find("#"))
	# Strip :params
	if base.find(":") != -1:
		base = base.substr(0, base.find(":"))
	# Truncate very long names
	if base.length() > 24:
		base = base.substr(0, 21) + "..."
	return base


# --- Properties popup (right-click edit) ---

func _open_props_popup(gx: int, gz: int, cell_value: String, layer: String) -> void:
	"""Open a floating properties popup for editing rotation/y/scale or deleting."""
	_close_props_popup()
	_props_gx = gx
	_props_gz = gz

	# Parse current token to extract params
	var base_name := cell_value
	var rot_y := 0.0
	var y_pos := 0.0
	var uniform_scale := 0.0  # 0 means default
	if layer == "interactables":
		# Strip #config
		var config_part := ""
		if base_name.find("#") != -1:
			config_part = base_name.substr(base_name.find("#"))
			base_name = base_name.substr(0, base_name.find("#"))
		var parts := base_name.split(":")
		if parts.size() >= 2 and parts[1].strip_edges().is_valid_float():
			rot_y = float(parts[1])
		if parts.size() >= 3 and parts[2].strip_edges().is_valid_float():
			y_pos = float(parts[2])
		if parts.size() >= 4 and parts[3].strip_edges().is_valid_float():
			uniform_scale = float(parts[3])
		base_name = parts[0] + config_part

	# Build popup CanvasLayer
	if not _props_popup_canvas:
		_props_popup_canvas = CanvasLayer.new()
		_props_popup_canvas.name = "PropsPopupCanvas"
		_props_popup_canvas.layer = 126  # Above layer editor panel (125)
		add_child(_props_popup_canvas)

	var popup := PanelContainer.new()
	popup.name = "PropsPopup"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.16, 0.97)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.3, 0.6, 0.9, 0.9)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(14)
	popup.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	popup.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "%s  [%d, %d]" % [_short_label(cell_value), gx, gz]
	title.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	# Full token display
	var token_lbl := Label.new()
	token_lbl.text = cell_value
	token_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	token_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(token_lbl)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.2, 0.35, 0.5, 0.5))
	vbox.add_child(sep)

	if layer == "interactables":
		# Rotation Y
		var rot_row := _make_prop_row("Rotation Y", str(rot_y), "rot_y")
		vbox.add_child(rot_row)
		# Y Position
		var ypos_row := _make_prop_row("Y Offset", str(y_pos), "y_pos")
		vbox.add_child(ypos_row)
		# Scale
		var scale_row := _make_prop_row("Scale", str(uniform_scale), "scale")
		vbox.add_child(scale_row)
	else:
		# For utilities: just show the code, editable
		var code_row := _make_prop_row("Code", cell_value, "code")
		vbox.add_child(code_row)

	# Separator
	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("separator", Color(0.2, 0.35, 0.5, 0.5))
	vbox.add_child(sep2)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.custom_minimum_size = Vector2(70, 30)
	_style_popup_btn(apply_btn, Color(0.12, 0.3, 0.5))
	apply_btn.pressed.connect(_on_props_apply.bind(layer, base_name, popup))
	btn_row.add_child(apply_btn)

	var delete_btn := Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(70, 30)
	_style_popup_btn(delete_btn, Color(0.5, 0.12, 0.12))
	delete_btn.pressed.connect(_on_props_delete.bind(layer))
	btn_row.add_child(delete_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(70, 30)
	_style_popup_btn(cancel_btn, Color(0.2, 0.2, 0.25))
	cancel_btn.pressed.connect(_close_props_popup)
	btn_row.add_child(cancel_btn)

	# Position popup near mouse
	var mouse_pos := get_viewport().get_mouse_position()
	popup.position = mouse_pos + Vector2(10, -20)
	# Clamp to viewport
	popup.size = Vector2(260, 0)  # auto-height

	_props_popup_canvas.add_child(popup)
	_props_popup = popup


func _make_prop_row(label_text: String, value: String, field_name: String) -> HBoxContainer:
	"""Create a label + input row for the properties popup."""
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(80, 0)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(lbl)
	var input := LineEdit.new()
	input.text = value
	input.custom_minimum_size = Vector2(100, 26)
	input.add_theme_font_size_override("font_size", 12)
	input.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	var input_sb := StyleBoxFlat.new()
	input_sb.bg_color = Color(0.12, 0.15, 0.22)
	input_sb.set_border_width_all(1)
	input_sb.border_color = Color(0.3, 0.45, 0.6, 0.7)
	input_sb.set_corner_radius_all(4)
	input_sb.set_content_margin_all(4)
	input.add_theme_stylebox_override("normal", input_sb)
	input.set_meta("field_name", field_name)
	row.add_child(input)
	return row


func _style_popup_btn(button: Button, bg_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.set_border_width_all(1)
	normal.border_color = bg_color.lightened(0.3)
	normal.set_corner_radius_all(5)
	button.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = bg_color.lightened(0.15)
	hover.set_border_width_all(1)
	hover.border_color = bg_color.lightened(0.5)
	hover.set_corner_radius_all(5)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	button.add_theme_font_size_override("font_size", 12)


func _on_props_apply(layer: String, base_name: String, popup: Control) -> void:
	"""Apply property changes from the popup."""
	var gx := _props_gx
	var gz := _props_gz
	if gx < 0 or gz < 0:
		return

	_push_undo()

	if layer == "interactables":
		# Read input values from popup
		var rot_y := 0.0
		var y_pos := 0.0
		var scale_val := 0.0
		var inputs := _find_prop_inputs(popup)
		for input in inputs:
			var fname: String = input.get_meta("field_name", "")
			var txt: String = input.text.strip_edges()
			if fname == "rot_y" and txt.is_valid_float():
				rot_y = float(txt)
			elif fname == "y_pos" and txt.is_valid_float():
				y_pos = float(txt)
			elif fname == "scale" and txt.is_valid_float():
				scale_val = float(txt)

		# Build token: name:rot:y:scale (omit trailing defaults)
		# Strip old :params from base_name (keep name + #config)
		var name_part := base_name
		# base_name already has #config but no :params
		if name_part.find(":") != -1 and name_part.find("#") == -1:
			name_part = name_part.substr(0, name_part.find(":"))

		var token := name_part
		if scale_val != 0.0:
			token = "%s:%s:%s:%s" % [name_part, str(rot_y), str(y_pos), str(scale_val)]
		elif y_pos != 0.0:
			token = "%s:%s:%s" % [name_part, str(rot_y), str(y_pos)]
		elif rot_y != 0.0:
			token = "%s:%s" % [name_part, str(rot_y)]

		_set_interactable_at(gx, gz, token)
		_live_despawn_interactable(gx, gz)
		_live_spawn_interactable(gx, gz, token)
		_update_cell_label_at(gx, gz, token)
		_set_status("EDIT [Interactables] — Updated '%s' at %d,%d" % [_short_label(token), gx, gz])
	else:
		# Utilities: read code from input
		var inputs := _find_prop_inputs(popup)
		var code := ""
		for input in inputs:
			if input.get_meta("field_name", "") == "code":
				code = input.text.strip_edges()
		if code.is_empty():
			code = " "
		_set_utility_at(gx, gz, code)
		_live_despawn_utility_marker(gx, gz)
		if code != " ":
			_live_spawn_utility_marker(gx, gz, code)
		_update_cell_label_at(gx, gz, code)
		_set_status("EDIT [Utilities] — Updated '%s' at %d,%d" % [code, gx, gz])

	_close_props_popup()


func _on_props_delete(layer: String) -> void:
	"""Delete the item at the popup's grid position."""
	var gx := _props_gx
	var gz := _props_gz
	if gx < 0 or gz < 0:
		return

	_push_undo()

	if layer == "interactables":
		_set_interactable_at(gx, gz, " ")
		_live_despawn_interactable(gx, gz)
		_remove_cell_label_at(gx, gz)
		_set_status("EDIT [Interactables] — Deleted at %d,%d" % [gx, gz])
	else:
		_set_utility_at(gx, gz, " ")
		_live_despawn_utility_marker(gx, gz)
		_remove_cell_label_at(gx, gz)
		_set_status("EDIT [Utilities] — Deleted at %d,%d" % [gx, gz])

	_close_props_popup()


func _find_prop_inputs(node: Node) -> Array:
	"""Recursively find all LineEdit nodes with 'field_name' meta."""
	var result: Array = []
	if node is LineEdit and node.has_meta("field_name"):
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_prop_inputs(child))
	return result


func _close_props_popup() -> void:
	"""Close and clean up the properties popup."""
	if _props_popup and is_instance_valid(_props_popup):
		_props_popup.queue_free()
		_props_popup = null
	_props_gx = -1
	_props_gz = -1


func _is_props_popup_visible() -> bool:
	return _props_popup != null and is_instance_valid(_props_popup) and _props_popup.visible


# --- Layer tab buttons ---

func _create_layer_tabs() -> void:
	_remove_layer_tabs()

	_layer_tab_container = Control.new()
	_layer_tab_container.name = "LayerTabs"
	_layer_tab_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_layer_tab_container.position = Vector2(268, 50)  # Right of sidebar, below camera bar
	_layer_tab_container.size = Vector2(200, 35)

	# Add as CanvasLayer child so it's always on top
	# Actually, add it to the overlay's CanvasLayer so it shares the same 2D space
	if _overlay:
		_overlay.add_child(_layer_tab_container)
	else:
		# Fallback: use a new CanvasLayer
		var cl := CanvasLayer.new()
		cl.layer = 121
		cl.name = "LayerTabsCanvas"
		add_child(cl)
		cl.add_child(_layer_tab_container)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	_layer_tab_container.add_child(hbox)

	# Label
	var lbl := Label.new()
	lbl.text = "Layer:"
	lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	lbl.add_theme_font_size_override("font_size", 12)
	hbox.add_child(lbl)

	for tab_data in [
		{"key": "structure", "label": "S"},
		{"key": "interactables", "label": "I"},
		{"key": "utilities", "label": "U"},
	]:
		var btn := Button.new()
		btn.text = tab_data.label
		btn.tooltip_text = tab_data.key.capitalize()
		btn.custom_minimum_size = Vector2(30, 28)
		btn.pressed.connect(_set_edit_layer.bind(tab_data.key))
		_style_layer_tab(btn, false)
		hbox.add_child(btn)
		_layer_tab_buttons[tab_data.key] = btn


func _remove_layer_tabs() -> void:
	if _layer_tab_container and is_instance_valid(_layer_tab_container):
		_layer_tab_container.queue_free()
		_layer_tab_container = null
	_layer_tab_buttons.clear()


func _update_layer_tab_highlight() -> void:
	for key in _layer_tab_buttons.keys():
		var btn: Button = _layer_tab_buttons[key]
		_style_layer_tab(btn, key == _edit_layer)


func _style_layer_tab(button: Button, is_active: bool) -> void:
	var normal := StyleBoxFlat.new()
	if is_active:
		normal.bg_color = Color(0.15, 0.35, 0.55, 0.98)
		normal.set_border_width_all(2)
		normal.border_color = Color(0.4, 0.85, 1.0, 1.0)
	else:
		normal.bg_color = Color(0.08, 0.13, 0.2, 0.96)
		normal.set_border_width_all(1)
		normal.border_color = Color(0.2, 0.4, 0.6, 0.6)
	normal.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.12, 0.25, 0.4, 0.98)
	hover.set_border_width_all(1)
	hover.border_color = Color(0.3, 0.65, 0.9, 0.8)
	hover.set_corner_radius_all(6)
	button.add_theme_stylebox_override("hover", hover)

	button.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0) if is_active else Color(0.6, 0.7, 0.8))
	button.add_theme_font_size_override("font_size", 13)


# ---------------------------------------------------------------------------
# JSON compact helper
# ---------------------------------------------------------------------------

static func _compact_inner_arrays(json: String) -> String:
	"""Collapse leaf arrays (no nested [] or {}) onto single lines.
	Uses regex to find arrays whose contents are only primitives."""
	var regex := RegEx.new()
	# Match [...] where the inside contains NO [ ] { } — i.e. leaf arrays only
	regex.compile("\\[([^\\[\\]{}]+)\\]")
	var result := json
	var prev := ""
	while result != prev:
		prev = result
		for m in regex.search_all(result):
			var full_match: String = m.get_string()
			var inner: String = m.get_string(1)
			# Strip newlines/tabs, tighten spacing
			var compacted := inner.replace("\n", "").replace("\t", "").strip_edges()
			while compacted.contains("  "):
				compacted = compacted.replace("  ", " ")
			# Remove spaces after commas: "1", "2" -> "1","2"
			compacted = compacted.replace(", ", ",")
			result = result.replace(full_match, "[" + compacted + "]")
		# Break after one pass to avoid infinite loop on identical arrays
		break
	return result

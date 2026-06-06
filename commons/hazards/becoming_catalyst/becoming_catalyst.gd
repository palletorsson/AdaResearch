# @identity
# essence: mode(curriculum_progress) -> hand_force(type) -- a held tool that evolves through the curriculum
# desire: an evolving hand force tracking player progression, from slow cubes to swarm intelligence
# critical_parameter: current_mode_index / unlocked_modes -- curriculum stage determines the tool's current power
# triggers: XRToolsPickable grab/release; mode cycling through unlocked abilities; curriculum progression unlocks
# emerges: the tool that grows with the learner -- same object, different capability at each understanding stage
# needs: XRToolsPickable [has]; mode system [has]; fire cooldown [has]; curriculum tracking [has]
# relationships: companion to loving_triangle (tool + atom pair); embodies Q-FEP progression across all sequences
# truth: the catalyst does not change the world -- it changes what the holder can do in the world.

# BecomingCatalyst.gd
# The Becoming Catalyst — an evolving hand force that grows with the curriculum.
# Not a weapon of destruction but a tool of transformation, becoming, and
# boundary dissolution.  Each Lab sequence unlocks a new expressive mode.
#
# Pickup behavior: the crystal shrinks into the hand and is absorbed.
# The hand permanently gains its power — trigger fires projectiles.
# The crystal is consumed. The hand is free to grab other things.
#
# QFEP arc: from order (primitives) through entropy (randomness) to the
# edge of chaos (fractals, L-systems) and collective emergence (swarm).
extends XRToolsPickable
class_name BecomingCatalyst

# ── Mode Definitions ──────────────────────────────────────────────────────
# Each entry maps a mode_id to its metadata and factory script.
const MODE_DEFS: Array[Dictionary] = [
	{"id": "voxel_editor",   "order": 0,  "name": "Voxel Editor",   "sequence": "",                   "script": "res://commons/hazards/becoming_catalyst/modes/mode_voxel_editor.gd"},
	{"id": "wedge_placer",   "order": 0,  "name": "Wedge Placer",  "sequence": "",                   "script": "res://commons/hazards/becoming_catalyst/modes/mode_wedge_placer.gd"},
	{"id": "artifact_edit",  "order": 0,  "name": "Edit",           "sequence": "",                   "script": ""},
	{"id": "lab_edit",       "order": 0,  "name": "Lab",            "sequence": "",                   "script": ""},
	{"id": "biome_brush",    "order": 0,  "name": "Biome Brush",    "sequence": "",                   "script": "res://commons/hazards/becoming_catalyst/modes/mode_biome_brush.gd"},
	{"id": "primitives",     "order": 1,  "name": "Primitives",     "sequence": "primitives",         "script": "res://commons/hazards/becoming_catalyst/modes/mode_primitives.gd"},
	{"id": "transformation", "order": 2,  "name": "Transformation", "sequence": "transformation",     "script": "res://commons/hazards/becoming_catalyst/modes/mode_transformation.gd"},
	{"id": "chromatic",      "order": 3,  "name": "Chromatic",      "sequence": "color",              "script": "res://commons/hazards/becoming_catalyst/modes/mode_chromatic.gd"},
	{"id": "forces",         "order": 4,  "name": "Forces",         "sequence": "forces",             "script": "res://commons/hazards/becoming_catalyst/modes/mode_forces.gd"},
	{"id": "waveform",       "order": 6,  "name": "Waveform",       "sequence": "wavefunctions",      "script": "res://commons/hazards/becoming_catalyst/modes/mode_waveform.gd"},
	{"id": "chaos",          "order": 7,  "name": "Chaos",          "sequence": "randomness",         "script": "res://commons/hazards/becoming_catalyst/modes/mode_chaos.gd"},
	{"id": "fractal",        "order": 10, "name": "Fractal",        "sequence": "fractals",           "script": "res://commons/hazards/becoming_catalyst/modes/mode_fractal.gd"},
	{"id": "cellular",       "order": 9,  "name": "Cellular",       "sequence": "cellularautomata",   "script": "res://commons/hazards/becoming_catalyst/modes/mode_cellular.gd"},
	{"id": "branching",      "order": 11, "name": "Branching",      "sequence": "lsystems",           "script": "res://commons/hazards/becoming_catalyst/modes/mode_branching.gd"},
	{"id": "swarm",          "order": 14, "name": "Swarm",          "sequence": "swarmintelligence",  "script": "res://commons/hazards/becoming_catalyst/modes/mode_swarm.gd"},
]

# ── State ─────────────────────────────────────────────────────────────────
var unlocked_modes: Array[String] = ["voxel_editor", "wedge_placer", "artifact_edit", "lab_edit", "biome_brush", "off"]
var current_mode_index: int = 0
var fire_cooldown: float = 0.0
var is_held: bool = false
var _absorbed: bool = false
var controller: XRController3D = null
var _pickup_controller_name: String = ""  # Remember which controller picked us up

# Mode switching debounce
var _stick_debounce: float = 0.0
const STICK_THRESHOLD := 0.7
const STICK_COOLDOWN := 0.5  # Short cooldown — smooth lerp handles the visual transition

# Voxel editing (tool mode)
var _voxel_controller: VoxelEditController = null
var _voxel_active: bool = false
# Biome Brush (tool mode) — paints biome density on the floor; B saves paint_layers.
# preload (NOT the global class_name) so the type resolves regardless of the
# script-class cache load order at runtime — the class_name isn't yet registered
# when this script parses on a fresh game load.
const BiomeBrushControllerClass = preload("res://commons/hazards/becoming_catalyst/BiomeBrushController.gd")
var _biome_brush: BiomeBrushControllerClass = null
# Left-hand Tilt-Brush-style menu (viewport_2d_in_3d) — choose element + brush size.
const BiomeMenuViewport = preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
const BiomeMenuUIScene = preload("res://commons/hazards/becoming_catalyst/biome_brush_menu_ui.tscn")
var _biome_menu: Node = null         # viewport_2d_in_3d on the off hand
var _biome_menu_ui: Control = null   # the 2D menu Control inside it
var _voxel_data_component: Node = null  # holds current map name, for B-to-save
# Voxel activation retry (grid may not be ready on map transition)
var _voxel_activate_retries: int = 0
const VOXEL_MAX_RETRIES := 10
const VOXEL_RETRY_DELAY := 0.3  # seconds between retries
# B-save POSTs the edited structure to the PC encyclopedia, which writes it into
# the repo's map_data.json. On the headset this reaches the PC over
# `adb reverse tcp:3003 tcp:3003`.
const MAP_SAVE_URL := "http://localhost:3003/api/game/save-layers"

# Head raycast (Minecraft style) — look where you want to place
var _xr_camera: XRCamera3D = null
var _xr_origin: XROrigin3D = null

# Wedge placement — placed prisms stored for removal
var _placed_wedges: Array[Dictionary] = []  # {node, grid_x, grid_z, direction}
var _wedge_ghost: MeshInstance3D = null
var _wedge_ghost_dir: float = 0.0  # Y rotation in degrees

# Artifact Edit mode — laser-grab existing artifacts and move/rotate/snap them
var _edit_target: Node3D = null        # artifact under the laser (not grabbed)
var _edit_grabbed: Node3D = null       # artifact currently being moved
var _edit_grab_offset: Transform3D = Transform3D.IDENTITY  # controller→artifact at grab
var _edit_trigger_was_down: bool = false
var _edit_highlight: MeshInstance3D = null
var _edit_is_lab: bool = false  # lab_edit mode → surface-magnetism for lab props
var _lab_surfaces: Array = []   # cached other-prop tops (room-local) for table-stacking
var _held_aabb: AABB = AABB()   # the grabbed prop's own AABB (prop-local), for flush offset
const LAB_SNAP_DIST := 0.25     # m: within this of a surface, the prop sticks flush
const LAB_SAVE_URL := "http://localhost:3003/api/labs/save"
const EDIT_MAX_RANGE := 8.0
const EDIT_RAY_RADIUS := 0.6  # how close to the laser line an artifact must be
const EDIT_HOLD_DISTANCE := 1.5  # how far in front of the hand a grabbed artifact floats
const EDIT_MAX_Y_LEVEL := 6  # artifacts can float up to this grid level when dropped in air

# Tip marker — where projectiles spawn
var _tip: Marker3D = null
var _mode_label: Label3D = null
var _mode_label_timer: float = 0.0
var _collision_shape: CollisionShape3D = null

# Held glow
var _held_glow: OmniLight3D = null
var _pickup_tween: Tween = null

# ── Signals ───────────────────────────────────────────────────────────────
signal mode_changed(mode_id: String)
signal mode_unlocked(mode_id: String)
signal projectile_fired(mode_id: String, position: Vector3)

# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super()

	_setup_physics()
	_build_tip()
	_build_mode_label()
	_load_unlocked_modes()

	add_to_group("catalyst")
	add_to_group("tool")

	# XRToolsPickable signals
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

	# Glow light (visible only when held)
	_held_glow = OmniLight3D.new()
	_held_glow.name = "HeldGlow"
	_held_glow.light_color = Color(0.7, 0.7, 1.0)
	_held_glow.light_energy = 0.0
	_held_glow.omni_range = 0.8
	_held_glow.omni_attenuation = 2.0
	add_child(_held_glow)

	# Build initial visual
	_rebuild_visual()

	# Try to connect to progression managers
	call_deferred("_connect_progression_signals")

	print("[Catalyst] Ready — modes: %s" % [unlocked_modes])

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	_stick_debounce = maxf(0.0, _stick_debounce - delta)

	# Mode label — always visible when held, shows current mode + index.
	# top_level label lives in world space; keep it hovering above the hand.
	if is_held and _mode_label:
		if is_instance_valid(controller):
			_mode_label.global_position = controller.global_position + Vector3(0.0, 0.18, 0.0)
		if _mode_label_timer > 0.0:
			_mode_label_timer -= delta
			# After the flash period, show a dimmer persistent label
			if _mode_label_timer <= 0.0:
				var mode_def := _get_current_mode_def()
				_mode_label.text = mode_def.get("name", "")
				_mode_label.modulate = CatalystVisual.get_mode_color(mode_def.get("id", "")).darkened(0.3)
				_mode_label.modulate.a = 0.6  # Dimmer but still visible
		_mode_label.visible = true
	elif _mode_label:
		_mode_label.visible = false

	# Hand glow pulse — the absorbed power breathes
	if is_held and _held_glow:
		var pulse := 1.5 + sin(Time.get_ticks_msec() / 400.0) * 0.5
		_held_glow.light_energy = pulse

	# Update cardinal neighbor targeting (shared by voxel + wedge modes)
	_update_voxel_raycast()

	# Update mode-specific ghost preview
	var _cur_mode_id := ""
	if current_mode_index >= 0 and current_mode_index < unlocked_modes.size():
		_cur_mode_id = unlocked_modes[current_mode_index]
	if _cur_mode_id == "wedge_placer":
		_update_wedge_ghost()
		# Hide voxel ghosts when in wedge mode
		if _voxel_controller:
			if _voxel_controller._ghost_add:
				_voxel_controller._ghost_add.visible = false
			if _voxel_controller._ghost_remove:
				_voxel_controller._ghost_remove.visible = false
	else:
		if _wedge_ghost:
			_wedge_ghost.visible = false

	# Artifact Edit / Lab modes — laser-grab artifacts, move, snap on release.
	# artifact_edit → grid (map) artifacts; lab_edit → lab props (net 0.1m snap).
	if is_held and (_cur_mode_id == "artifact_edit" or _cur_mode_id == "lab_edit"):
		_edit_is_lab = (_cur_mode_id == "lab_edit")
		_update_edit_mode(delta)
	elif _edit_target != null or _edit_grabbed != null or (_edit_highlight and _edit_highlight.visible):
		_end_edit_mode()

	# Biome Brush — point at the floor, trigger paints / grip erases the active
	# element's density; on release the biome rebuilds live. B saves paint_layers.
	if is_held and _cur_mode_id == "biome_brush":
		if _biome_brush == null:
			_biome_brush = BiomeBrushControllerClass.new()
			_biome_brush.name = "BiomeBrushCtrl"
			add_child(_biome_brush)
			_biome_brush.setup()
		_ensure_biome_menu()
		if _biome_menu:
			_biome_menu.visible = true
		if controller:
			var b_origin: Vector3 = controller.global_position
			var b_fwd: Vector3 = -controller.global_transform.basis.z
			var b_paint: bool = controller.is_button_pressed("trigger_click")
			var b_erase: bool = controller.is_button_pressed("grip_click")
			_biome_brush.update(b_origin, b_fwd, b_paint, b_erase)
		# Hide voxel ghosts while painting biome.
		if _voxel_controller:
			if _voxel_controller._ghost_add:
				_voxel_controller._ghost_add.visible = false
			if _voxel_controller._ghost_remove:
				_voxel_controller._ghost_remove.visible = false
	elif _biome_brush:
		_biome_brush.set_idle()
		if _biome_menu:
			_biome_menu.visible = false

	# Mode switching disabled on controller thumbstick — use the bracelet instead

# ═════════════════════════════════════════════════════════════════════════
# FIRING
# ═════════════════════════════════════════════════════════════════════════

## Called by XRToolsFunctionPickup when the trigger is pressed while held.
## Pre-absorption: do nothing — the catalyst must absorb first before firing.
## Post-absorption: never called because let_go() releases from FunctionPickup.
func action() -> void:
	super()

## Controller button handler.
## Mode switching is done by the OTHER hand grabbing and rotating the bracelet hinge.
## This handler only deals with firing/voxel actions on the catalyst hand.
##
## A/X = fire projectile OR add cube (voxel mode)
## B/Y = remove cube (voxel mode only)
## Trigger = add cube (voxel mode) — in other modes trigger is XRTools grab
## Grip = NOT used here — grip is for the OTHER hand grabbing the bracelet
##
func _on_controller_button(button_name: String) -> void:
	var mode_def := _get_current_mode_def()
	var mode_id: String = mode_def.get("id", "") if not mode_def.is_empty() else ""

	# Biome Brush intercepts its buttons before the firing/voxel dispatch:
	# trigger/grip painting is POLLED in _process; Ax cycles the element; By saves.
	# (The early return prevents trigger_click from falling through to _fire().)
	if mode_id == "biome_brush":
		match button_name:
			"ax_button":
				if _biome_brush:
					_biome_brush.cycle_element()
					if _biome_menu_ui and _biome_menu_ui.has_method("set_selected_element"):
						_biome_menu_ui.set_selected_element(_biome_brush.active_element())
					_flash_label("BRUSH: " + _biome_brush.active_element().to_upper(), Color(0.6, 0.95, 0.7))
			"by_button":
				_save_biome()
		return

	match button_name:
		"ax_button", "trigger_click":
			match mode_id:
				"voxel_editor":
					_handle_voxel_add()
				"wedge_placer":
					_handle_wedge_add()
				"artifact_edit", "lab_edit":
					pass  # grab/move handled by polling in _update_edit_mode
				_:
					if not _is_hand_busy():
						_fire()
		"grip_click":
			match mode_id:
				"voxel_editor":
					_handle_voxel_remove()
				"wedge_placer":
					_handle_wedge_remove()
		"by_button":
			# B = save the edited grid back to the repo's map_data.json.
			print("[Catalyst] B (by_button) pressed — mode=%s" % mode_id)
			match mode_id:
				"voxel_editor", "wedge_placer", "artifact_edit":
					_save_map()
				"lab_edit":
					_save_lab()
				_:
					_flash_label("B SAVES IN EDIT/VOXEL MODE", Color(1.0, 0.8, 0.3))


## Voxel mode: trigger/AX = ADD cube on the cardinal neighbor you're facing.
func _handle_voxel_add() -> void:
	if not _voxel_controller or not _voxel_controller.has_target:
		return
	_voxel_controller.try_add()
	fire_cooldown = 0.15
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.2, 0.0)


## Voxel mode: grip = REMOVE cube.
func _handle_voxel_remove() -> void:
	if not _voxel_controller:
		return
	_voxel_controller.try_remove()
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.3, 0.0)


## B button = SAVE the edited grid back to the repo's map_data.json.
## Writes only the structure layer (the cubes you placed/removed); utilities,
## interactables, lighting and settings are preserved untouched. Edit the map
## inside VR, press B, and the change lands on disk in the repo.
func _save_map() -> void:
	print("[Catalyst] _save_map() called")
	# Map name from the live grid data — works in voxel mode AND edit mode.
	var data := _get_grid_data_component()
	var map_name := ""
	if data and data.has_method("get_current_map_name"):
		map_name = data.get_current_map_name()
	if map_name == "":
		push_warning("[Catalyst] B-save aborted — no current map name")
		_flash_label("NO MAP NAME", Color(1.0, 0.4, 0.3))
		return
	# Structure layer only when we're actually voxel-editing cubes. In Edit mode
	# (artifacts) there's no voxel controller — we save placements only, leaving
	# the structure layer on disk untouched.
	var layout: Array = []
	if _voxel_controller and _voxel_controller.structure_component:
		var structure: GridStructureComponent = _voxel_controller.structure_component
		# Local write — editor only; res:// is read-only on a packaged/Quest build.
		if not OS.has_feature("android"):
			VoxelSaveManager.save(map_name, structure)
		layout = structure.get_editable_layout()
	var placements := _collect_vr_placements()
	if layout.is_empty() and placements.is_empty():
		_flash_label("NOTHING TO SAVE", Color(1.0, 0.5, 0.2))
		return
	# HTTP POST to the PC — works on the headset over `adb reverse tcp:3003 tcp:3003`.
	_save_map_over_http(map_name, layout, placements)
	_flash_label("SAVING  " + map_name + " ...", Color(0.6, 0.85, 1.0))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.12, 0.4, 0.0)

## The live GridDataComponent — the one voxel mode cached, or a fresh lookup.
func _get_grid_data_component() -> Node:
	if _voxel_data_component and is_instance_valid(_voxel_data_component):
		return _voxel_data_component
	return _find_node_by_name(get_tree().root, "GridDataComponent")


## Flash a transient message on the held tool's mode label, then revert.
func _flash_label(text: String, color: Color) -> void:
	if not _mode_label:
		return
	_mode_label.text = text
	_mode_label.modulate = color
	_mode_label.modulate.a = 1.0
	_mode_label.visible = true
	_mode_label_timer = 2.0


## POST the edited structure to the PC's encyclopedia so it lands in the repo's
## map_data.json (preserving the other layers). On the headset this reaches the
## PC over `adb reverse tcp:3003 tcp:3003`.
## Collect artifacts placed/moved in VR (group "vr_placed_artifact") into a list
## of {x, z, token} cell placements that the save endpoint overlays onto the
## map's interactables layer. When an artifact has MOVED since it was last
## saved (or since it spawned, for existing artifacts), we first emit a CLEAR
## for its old cell so it doesn't leave a duplicate behind. Clears are emitted
## before sets so a clear can never wipe a freshly-set cell.
func _collect_vr_placements() -> Array:
	var clears: Array = []
	var sets: Array = []
	var structure := _get_edit_structure()
	var total_size: float = 1.0
	if structure:
		total_size = structure.cube_size + structure.gutter
	for node in get_tree().get_nodes_in_group("vr_placed_artifact"):
		if not is_instance_valid(node):
			continue
		var lookup := String(node.get_meta("artifact_lookup_name", ""))
		var cell: Vector2i = node.get_meta("grid_cell", Vector2i(-1, -1))
		if lookup == "" or cell.x < 0 or cell.y < 0:
			continue
		var rot := int(round(float(node.get_meta("grid_rotation_y", 0.0))))
		# Free-height drops: encode the vertical offset from the column top as the
		# token's y_position param, so the artifact reloads at the same level.
		var y_token := ""
		if structure and node.has_meta("grid_y_level"):
			var y_level: int = int(node.get_meta("grid_y_level", 0))
			var base: int = structure.find_highest_y_at(cell.x, cell.y)
			var y_off: float = float(y_level - base) * total_size
			if absf(y_off) > 0.001:
				y_token = String.num(y_off, 3).rstrip("0").rstrip(".")
		var token := lookup
		if y_token != "":
			token = "%s:%d:%s" % [lookup, rot, y_token]  # lookup:yaw:y_offset
		elif rot != 0:
			token = "%s:%d" % [lookup, rot]
		# Clear the previous cell if this artifact moved.
		var saved: Vector2i = node.get_meta("vr_saved_cell", Vector2i(-1, -1))
		if saved.x >= 0 and saved.y >= 0 and saved != cell:
			clears.append({"x": saved.x, "z": saved.y, "token": " "})
		sets.append({"x": cell.x, "z": cell.y, "token": token})
		# Remember where it now lives, so the next move can clear this cell.
		node.set_meta("vr_saved_cell", cell)
	return clears + sets


func _save_map_over_http(map_name: String, layout: Array, placements: Array = []) -> void:
	print("[Catalyst] POSTing '%s' (%d rows, %d placed artifacts) -> %s" % [map_name, layout.size(), placements.size(), MAP_SAVE_URL])
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_map_save_completed.bind(http))
	var headers := PackedStringArray(["Content-Type: application/json"])
	var payload := {"mapName": map_name}
	if not layout.is_empty():
		payload["layers"] = {"structure": layout}
	if not placements.is_empty():
		payload["interactablePlacements"] = placements
	http.set_meta("map_name", map_name)
	var err := http.request(MAP_SAVE_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		http.queue_free()
		_flash_label("POST FAILED: %s" % error_string(err), Color(1.0, 0.3, 0.3))


func _on_map_save_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest) -> void:
	var mn := String(http.get_meta("map_name", ""))
	http.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		print("[Catalyst] B-save: '%s' written on the PC (HTTP %d)" % [mn, response_code])
		_flash_label("SAVED -> PC  " + mn, Color(0.4, 1.0, 0.6))
		if controller:
			controller.trigger_haptic_pulse("haptic", 0.0, 0.2, 0.6, 0.0)
	else:
		var hint := ""
		if result == HTTPRequest.RESULT_CANT_CONNECT:
			hint = "  (adb reverse tcp:3003 tcp:3003)"
		_flash_label("SAVE FAILED %d/%d%s" % [result, response_code, hint], Color(1.0, 0.35, 0.35))
		push_warning("[Catalyst] map save HTTP failed result=%d code=%d" % [result, response_code])

# ═══════════════════════════════════════════════════════════════════════════
# BIOME BRUSH SAVE — POST paint_layers to the PC, same tunnel as map saves
# ═══════════════════════════════════════════════════════════════════════════

## B (biome_brush mode) = save the painted density fields to the repo's
## map_data.json `paint_layers[]` via /api/game/save-layers (merged by element,
## non-destructive). res:// is read-only on Quest, so it POSTs over the tunnel.
func _save_biome() -> void:
	if _biome_brush == null or not _biome_brush.has_strokes():
		_flash_label("NOTHING PAINTED", Color(1.0, 0.5, 0.2))
		return
	var data := _get_grid_data_component()
	var map_name := ""
	if data and data.has_method("get_current_map_name"):
		map_name = data.get_current_map_name()
	if map_name == "":
		_flash_label("NO MAP NAME", Color(1.0, 0.4, 0.3))
		return
	_save_biome_over_http(map_name, _biome_brush.paint_layers_payload())
	_flash_label("SAVING BIOME  " + map_name + " ...", Color(0.6, 0.85, 1.0))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.12, 0.4, 0.0)


func _save_biome_over_http(map_name: String, paint_layers: Array) -> void:
	print("[Catalyst] POSTing biome '%s' (%d paint layers) -> %s" % [map_name, paint_layers.size(), MAP_SAVE_URL])
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_map_save_completed.bind(http))  # reuse SAVED→PC flash
	var headers := PackedStringArray(["Content-Type: application/json"])
	var payload := {"mapName": map_name, "paintLayers": paint_layers}
	http.set_meta("map_name", map_name)
	var err := http.request(MAP_SAVE_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		http.queue_free()
		_flash_label("POST FAILED: %s" % error_string(err), Color(1.0, 0.3, 0.3))


# ═══════════════════════════════════════════════════════════════════════════
# BIOME BRUSH MENU — Tilt-Brush-style panel on the off hand (element + size)
# ═══════════════════════════════════════════════════════════════════════════

## The off-hand XRController3D (the one NOT holding the catalyst).
func _get_left_controller() -> XRController3D:
	if controller == null:
		return null
	var origin := controller.get_parent()
	if origin == null:
		return null
	for c in origin.get_children():
		if c is XRController3D and c != controller:
			return c as XRController3D
	return null


## Build the left-hand menu viewport once, on first biome_brush use.
func _ensure_biome_menu() -> void:
	if _biome_menu and is_instance_valid(_biome_menu):
		return
	var left := _get_left_controller()
	if left == null:
		return
	var vp = BiomeMenuViewport.instantiate()
	vp.name = "BiomeBrushMenu"
	vp.scene = BiomeMenuUIScene
	vp.screen_size = Vector2(0.22, 0.18)
	vp.viewport_size = Vector2(500, 420)
	# Tilted up off the wrist, toward the face — glanceable like Tilt Brush.
	vp.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-45)), Vector3(0.0, 0.05, -0.11))
	left.add_child(vp)
	_biome_menu = vp
	call_deferred("_connect_biome_menu", vp)


func _connect_biome_menu(vp: Node) -> void:
	for i in range(15):
		await get_tree().process_frame
		_biome_menu_ui = vp.get_scene_instance() if vp.has_method("get_scene_instance") else null
		if _biome_menu_ui:
			break
	if _biome_menu_ui == null:
		return
	if _biome_menu_ui.has_signal("element_selected") and not _biome_menu_ui.element_selected.is_connected(_on_biome_menu_element):
		_biome_menu_ui.element_selected.connect(_on_biome_menu_element)
	if _biome_menu_ui.has_signal("size_changed") and not _biome_menu_ui.size_changed.is_connected(_on_biome_menu_size):
		_biome_menu_ui.size_changed.connect(_on_biome_menu_size)
	if _biome_menu_ui.has_signal("pressure_changed") and not _biome_menu_ui.pressure_changed.is_connected(_on_biome_menu_pressure):
		_biome_menu_ui.pressure_changed.connect(_on_biome_menu_pressure)
	if _biome_menu_ui.has_signal("artifact_toggle_requested") and not _biome_menu_ui.artifact_toggle_requested.is_connected(_on_biome_menu_artifact):
		_biome_menu_ui.artifact_toggle_requested.connect(_on_biome_menu_artifact)
	print("[Catalyst] Biome menu connected")


func _on_biome_menu_element(element_name: String) -> void:
	if _biome_brush:
		_biome_brush.set_element(element_name)
		if _biome_menu_ui and _biome_menu_ui.has_method("refresh_artifact_marks"):
			_biome_menu_ui.refresh_artifact_marks(_biome_brush.active_artifacts())
	_flash_label("BRUSH: " + element_name.to_upper(), Color(0.6, 0.95, 0.7))


func _on_biome_menu_artifact(artifact_name: String) -> void:
	if not _biome_brush:
		return
	var lst: Array = _biome_brush.toggle_artifact(artifact_name)
	if _biome_menu_ui and _biome_menu_ui.has_method("refresh_artifact_marks"):
		_biome_menu_ui.refresh_artifact_marks(lst)
	_flash_label("ARTIFACT: " + artifact_name, Color(0.85, 0.6, 0.95))


func _on_biome_menu_size(radius: int) -> void:
	if _biome_brush:
		_biome_brush.set_radius(radius)


func _on_biome_menu_pressure(strength: float) -> void:
	if _biome_brush:
		_biome_brush.set_strength(strength)


# ═══════════════════════════════════════════════════════════════════════════
# WEDGE PLACEMENT — PrismMesh slopes on the grid
# ═══════════════════════════════════════════════════════════════════════════

## Wedge mode: trigger/AX = place wedge on the cardinal neighbor, sloping toward you.
func _handle_wedge_add() -> void:
	if not _voxel_controller or not _voxel_controller.has_target:
		return
	if not _voxel_controller.structure_component:
		return

	var ac := _voxel_controller.add_cell
	var structure: GridStructureComponent = _voxel_controller.structure_component
	var total_size: float = structure.cube_size + structure.gutter

	# Grid origin
	var grid_origin := Vector3.ZERO
	var grid_parent := structure.get_parent()
	if grid_parent is Node3D:
		grid_origin = (grid_parent as Node3D).global_position

	# Check if there's already a wedge at this XZ
	for w in _placed_wedges:
		if w["grid_x"] == ac.x and w["grid_z"] == ac.z:
			return  # Already occupied

	# Load the walkable prism scene (has StaticBody3D + ConcavePolygonShape3D)
	var wp_scene := load("res://commons/scenes/mapobjects/walkableprism.tscn")
	if wp_scene == null:
		push_error("[Catalyst] Failed to load walkableprism.tscn")
		return
	var wedge: Node3D = wp_scene.instantiate()
	wedge.name = "Wedge_%d_%d" % [ac.x, ac.z]

	# Scale to fit one grid cell (scene default is 2x1x1, we need total_size)
	var scene_width := 2.0  # Default PrismMesh width in the scene
	var scale_factor := total_size / scene_width
	wedge.scale = Vector3(scale_factor, total_size, scale_factor)

	# Position at grid cell
	var world_pos := grid_origin + Vector3(
		float(ac.x) * total_size,
		float(ac.y) * total_size,
		float(ac.z) * total_size
	)
	wedge.global_position = world_pos

	# Rotate so the slope faces the player's look direction
	wedge.rotation_degrees.y = _wedge_ghost_dir

	# Add to scene
	get_tree().current_scene.add_child(wedge)
	_placed_wedges.append({
		"node": wedge,
		"grid_x": ac.x,
		"grid_z": ac.z,
		"direction": _wedge_ghost_dir,
	})

	fire_cooldown = 0.2
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.2, 0.0)
	print("[Catalyst] Wedge placed at (%d, %d) dir=%.0f" % [ac.x, ac.z, _wedge_ghost_dir])


## Wedge mode: grip = remove the wedge at the target neighbor.
func _handle_wedge_remove() -> void:
	if not _voxel_controller or not _voxel_controller.has_target:
		return
	var tc := _voxel_controller.add_cell  # Same cell as where we'd place

	for i in range(_placed_wedges.size() - 1, -1, -1):
		var w: Dictionary = _placed_wedges[i]
		if w["grid_x"] == tc.x and w["grid_z"] == tc.z:
			if is_instance_valid(w["node"]):
				(w["node"] as Node).queue_free()
			_placed_wedges.remove_at(i)
			if controller:
				controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.3, 0.0)
			print("[Catalyst] Wedge removed at (%d, %d)" % [tc.x, tc.z])
			return


## Build or update the wedge ghost preview.
func _update_wedge_ghost() -> void:
	if not _voxel_active or not _voxel_controller or not _voxel_controller.has_target:
		if _wedge_ghost:
			_wedge_ghost.visible = false
		return
	if not _voxel_controller.structure_component:
		return

	var structure: GridStructureComponent = _voxel_controller.structure_component
	var total_size: float = structure.cube_size + structure.gutter
	var ac := _voxel_controller.add_cell

	# Grid origin
	var grid_origin := Vector3.ZERO
	var grid_parent := structure.get_parent()
	if grid_parent is Node3D:
		grid_origin = (grid_parent as Node3D).global_position

	# Create ghost on first use
	if not _wedge_ghost:
		_wedge_ghost = MeshInstance3D.new()
		_wedge_ghost.name = "WedgeGhost"
		_wedge_ghost.top_level = true
		var prism := PrismMesh.new()
		prism.size = Vector3(total_size * 0.96, total_size * 0.96, total_size * 0.96)
		prism.left_to_right = 0.0
		_wedge_ghost.mesh = prism
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.55, 0.2, 0.15)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.no_depth_test = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(0.85, 0.55, 0.2)
		mat.emission_energy_multiplier = 0.3
		_wedge_ghost.material_override = mat
		add_child(_wedge_ghost)

	_wedge_ghost.visible = true
	_wedge_ghost.global_position = grid_origin + Vector3(
		float(ac.x) * total_size,
		float(ac.y) * total_size,
		float(ac.z) * total_size
	)

	# Compute wedge direction from look direction
	var look_dir := Vector3.ZERO
	if _xr_camera and is_instance_valid(_xr_camera):
		look_dir = -_xr_camera.global_transform.basis.z
	elif controller:
		look_dir = -controller.global_transform.basis.z
	var flat := Vector2(look_dir.x, look_dir.z)
	if flat.length() > 0.01:
		# Snap to 4 cardinal directions (0, 90, 180, 270)
		var angle_rad := atan2(flat.x, flat.y)
		var snapped := roundf(angle_rad / (PI * 0.5)) * 90.0
		_wedge_ghost_dir = snapped
	_wedge_ghost.rotation_degrees.y = _wedge_ghost_dir


## Check if FunctionPickup on this controller is currently holding a pickable.
func _is_hand_busy() -> bool:
	if not is_instance_valid(controller):
		return false
	for child in controller.get_children():
		if child is XRToolsFunctionPickup:
			if is_instance_valid(child.picked_up_object):
				return true
	return false

func _fire() -> void:
	if not is_held or fire_cooldown > 0.0:
		return

	var mode_def := _get_current_mode_def()
	if mode_def.is_empty():
		return

	# ── Tool modes: voxel cubes and wedge prisms ──
	if mode_def["id"] == "voxel_editor":
		_handle_voxel_add()
		return
	if mode_def["id"] == "wedge_placer":
		_handle_wedge_add()
		return

	# ── Standard projectile modes ──
	# Fire where the controller points (local -Z, same axis as FunctionPointer ray)
	var spawn_pos: Vector3
	var fire_dir: Vector3
	if controller:
		fire_dir = -controller.global_transform.basis.z
		spawn_pos = controller.global_position + fire_dir * 0.15
	else:
		fire_dir = -global_transform.basis.z
		spawn_pos = global_position

	# Load the mode script and call its factory
	var mode_script: GDScript = load(mode_def["script"])
	if mode_script == null:
		push_warning("[Catalyst] Could not load mode script: %s" % mode_def["script"])
		return

	var projectile: CatalystProjectile = mode_script.create_projectile(spawn_pos, fire_dir)
	if projectile == null:
		return

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_pos

	fire_cooldown = mode_script.FIRE_RATE if "FIRE_RATE" in mode_script else 0.4
	projectile_fired.emit(mode_def["id"], spawn_pos)

	# Haptic kick
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.35, 0.0)

# ═════════════════════════════════════════════════════════════════════════
# MODE SWITCHING
# ═════════════════════════════════════════════════════════════════════════

# ═════════════════════════════════════════════════════════════════════════
# VOXEL EDITING — Tool mode for adding/removing grid cubes
# ═════════════════════════════════════════════════════════════════════════

func _activate_voxel_mode() -> void:
	if _voxel_active:
		return
	# Find GridStructureComponent in scene
	var structure := _find_node_by_name(get_tree().root, "GridStructureComponent")
	if not structure or not (structure is GridStructureComponent):
		# Grid not ready yet (common after map transitions — grid needs ~3 frames)
		if _voxel_activate_retries < VOXEL_MAX_RETRIES:
			_voxel_activate_retries += 1
			print("[Catalyst] Grid not ready, retry %d/%d in %.1fs" % [_voxel_activate_retries, VOXEL_MAX_RETRIES, VOXEL_RETRY_DELAY])
			get_tree().create_timer(VOXEL_RETRY_DELAY).timeout.connect(_activate_voxel_mode)
			return
		print("[Catalyst] No GridStructureComponent found after %d retries — voxel mode unavailable" % VOXEL_MAX_RETRIES)
		return
	# Check if grid data is actually loaded (not just the node existing)
	var data := _find_node_by_name(get_tree().root, "GridDataComponent")
	if not data or not data.has_method("is_data_loaded") or not data.is_data_loaded():
		if _voxel_activate_retries < VOXEL_MAX_RETRIES:
			_voxel_activate_retries += 1
			print("[Catalyst] Grid data not loaded yet, retry %d/%d" % [_voxel_activate_retries, VOXEL_MAX_RETRIES])
			get_tree().create_timer(VOXEL_RETRY_DELAY).timeout.connect(_activate_voxel_mode)
			return
		print("[Catalyst] Grid data not available after %d retries" % VOXEL_MAX_RETRIES)
		return
	_voxel_activate_retries = 0
	_voxel_data_component = data  # remember it so B can save back to the right map
	if data.has_method("get_structure_data"):
		(structure as GridStructureComponent).enable_editing(data.get_structure_data())
	_voxel_controller = VoxelEditController.new()
	_voxel_controller.name = "CatalystVoxelEdit"
	_voxel_controller.structure_component = structure as GridStructureComponent
	_voxel_controller.cube_size = (structure as GridStructureComponent).cube_size
	add_child(_voxel_controller)
	_voxel_active = true

	# Find XR nodes for head raycast (Minecraft style)
	_xr_camera = null
	_xr_origin = null
	if controller:
		var node = controller.get_parent()
		while node:
			if node is XROrigin3D:
				_xr_origin = node
				break
			node = node.get_parent()
		if _xr_origin:
			for child in _xr_origin.get_children():
				if child is XRCamera3D:
					_xr_camera = child
					break
	if _xr_camera:
		print("[Catalyst] Head raycast active — using %s" % _xr_camera.get_path())
	else:
		push_warning("[Catalyst] No XRCamera3D found — falling back to controller ray")
	print("[Catalyst] Voxel editor activated")


func _deactivate_voxel_mode() -> void:
	if not _voxel_active:
		return
	if _voxel_controller and is_instance_valid(_voxel_controller):
		_voxel_controller.queue_free()
	_voxel_controller = null
	_xr_camera = null
	_xr_origin = null
	_voxel_active = false


func _update_voxel_raycast() -> void:
	if not _voxel_active or not _voxel_controller:
		return
	if not _voxel_controller.structure_component:
		return

	var structure: GridStructureComponent = _voxel_controller.structure_component
	var total_size: float = structure.cube_size + structure.gutter

	# Get player grid position (feet level), accounting for grid world offset
	if not _xr_origin or not is_instance_valid(_xr_origin):
		_voxel_controller.clear_target()
		return
	var grid_origin := Vector3.ZERO
	var grid_parent := structure.get_parent()
	if grid_parent is Node3D:
		grid_origin = (grid_parent as Node3D).global_position
	var local_pos: Vector3 = _xr_origin.global_position - grid_origin
	var player_grid: Vector3i = structure.world_to_grid(local_pos)

	# Get look direction from head (or controller fallback), projected onto XZ
	var look_dir := Vector3.ZERO
	if _xr_camera and is_instance_valid(_xr_camera):
		look_dir = -_xr_camera.global_transform.basis.z
	elif controller:
		look_dir = -controller.global_transform.basis.z
	else:
		_voxel_controller.clear_target()
		return

	# Project onto XZ plane and pick the dominant cardinal direction
	# Reach = 2 cells out (skip the cell right next to you for better visibility)
	var flat := Vector2(look_dir.x, look_dir.z)
	if flat.length() < 0.01:
		_voxel_controller.clear_target()
		return

	const REACH := 2  # How many cells out to place/remove
	var offset := Vector3i.ZERO
	if absf(flat.x) > absf(flat.y):
		offset = Vector3i(REACH, 0, 0) if flat.x > 0 else Vector3i(-REACH, 0, 0)
	else:
		offset = Vector3i(0, 0, REACH) if flat.y > 0 else Vector3i(0, 0, -REACH)

	var neighbor_x: int = player_grid.x + offset.x
	var neighbor_z: int = player_grid.z + offset.z
	var height: int = structure.get_height_at(neighbor_x, neighbor_z)

	# Target cell: top cube of the neighbor column (for removal)
	var target := Vector3i(neighbor_x, maxi(height - 1, 0), neighbor_z)
	# Add cell: on top of the neighbor column (for placement)
	var add := Vector3i(neighbor_x, height, neighbor_z)

	_voxel_controller.set_target_direct(target, add)


# ═════════════════════════════════════════════════════════════════════════
# ARTIFACT EDIT MODE — laser gravity-gun for existing map artifacts
# Point the catalyst at an artifact, hold trigger to grab it (it floats in
# front of the hand and follows your aim + twist), release to snap it onto the
# grid (cell on top of the structure, upright, yaw to 90°). Artifacts keep all
# their normal interactivity — nothing about them changes outside Edit mode.
# ═════════════════════════════════════════════════════════════════════════

func _update_edit_mode(_delta: float) -> void:
	if not is_instance_valid(controller):
		return
	var ray_dir: Vector3 = -controller.global_transform.basis.z
	if ray_dir.length() < 0.001:
		return
	ray_dir = ray_dir.normalized()
	var ray_origin: Vector3 = controller.global_position
	var trig_down: bool = controller.is_button_pressed("trigger_click")

	if is_instance_valid(_edit_grabbed):
		# Move: rigid follow. Lab props also magnetise — when near a wall/floor/
		# ceiling/prop-top they stick flush; otherwise they move freely.
		_edit_grabbed.global_transform = controller.global_transform * _edit_grab_offset
		if _edit_is_lab:
			_apply_lab_magnetism(_edit_grabbed)
		_show_edit_highlight(_edit_grabbed)
		if _edit_trigger_was_down and not trig_down:
			_edit_release()
	else:
		_edit_target = _find_edit_target(ray_origin, ray_dir)
		if _edit_target:
			_show_edit_highlight(_edit_target)
		else:
			_hide_edit_highlight()
		if trig_down and not _edit_trigger_was_down and _edit_target:
			_edit_grab()
	_edit_trigger_was_down = trig_down

## Nearest editable artifact to the laser line (no collider needed).
func _find_edit_target(ray_origin: Vector3, ray_dir: Vector3) -> Node3D:
	var best: Node3D = null
	var best_score: float = INF
	var group_name := "vr_lab_prop" if _edit_is_lab else "vr_editable_artifact"
	for n in get_tree().get_nodes_in_group(group_name):
		if not (n is Node3D) or not is_instance_valid(n):
			continue
		var node := n as Node3D
		var to_obj: Vector3 = node.global_position - ray_origin
		var along: float = to_obj.dot(ray_dir)
		if along < 0.2 or along > EDIT_MAX_RANGE:
			continue
		var closest: Vector3 = ray_origin + ray_dir * along
		var perp: float = node.global_position.distance_to(closest)
		if perp > EDIT_RAY_RADIUS:
			continue
		var score: float = perp + along * 0.05
		if score < best_score:
			best_score = score
			best = node
	return best

func _edit_grab() -> void:
	if not is_instance_valid(_edit_target):
		return
	_edit_grabbed = _edit_target
	# Reel it to a comfortable hold distance in front of the hand, keeping its
	# current orientation + scale relative to the controller.
	var rel: Transform3D = controller.global_transform.affine_inverse() * _edit_grabbed.global_transform
	rel.origin = Vector3(0.0, 0.0, -EDIT_HOLD_DISTANCE)
	_edit_grab_offset = rel
	if _edit_is_lab:
		_cache_lab_surfaces(_edit_grabbed)  # snapshot other props' tops for stacking
		_held_aabb = _local_aabb(_edit_grabbed)  # its own size, for flush-to-wall
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.4, 0.0)
	print("[Catalyst] Edit grab: %s" % String(_edit_grabbed.get_meta("artifact_lookup_name", "?")))

func _edit_release() -> void:
	var node := _edit_grabbed
	_edit_grabbed = null
	if not is_instance_valid(node):
		return
	if _edit_is_lab:
		_edit_release_lab(node)
		return
	var structure := _get_edit_structure()
	if structure == null:
		print("[Catalyst] Edit release: no grid — left in place")
		return
	var total_size: float = structure.cube_size + structure.gutter
	var grid_origin := _grid_origin_of(structure)
	var dims := structure.get_grid_dimensions()
	var local: Vector3 = (node.global_position - grid_origin) / total_size
	var x: int = clampi(int(round(local.x)), 0, maxi(dims.x - 1, 0))
	var z: int = clampi(int(round(local.z)), 0, maxi(dims.z - 1, 0))
	# Respect the height you dropped it at: snap Y to the nearest integer level.
	# Dropped low it lands on the surface; lifted, it stays floating at that level.
	var y_level: int = clampi(int(round(local.y)), 0, maxi(dims.y - 1, EDIT_MAX_Y_LEVEL))
	# snap rotation: upright, yaw to nearest 90°
	var yaw_deg: float = rad_to_deg(node.global_rotation.y)
	var snapped_yaw: float = round(yaw_deg / 90.0) * 90.0
	node.global_rotation = Vector3(0.0, deg_to_rad(snapped_yaw), 0.0)
	node.global_position = grid_origin + Vector3(x, y_level, z) * total_size
	node.set_meta("grid_cell", Vector2i(x, z))
	node.set_meta("grid_y_level", y_level)
	node.set_meta("grid_rotation_y", fposmod(snapped_yaw, 360.0))
	if not node.is_in_group("vr_placed_artifact"):
		node.add_to_group("vr_placed_artifact")  # now it'll save with B
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.15, 0.5, 0.0)
	_flash_label("MOVED  %s" % String(node.get_meta("artifact_lookup_name", "")), Color(0.4, 1.0, 0.6))
	print("[Catalyst] Edit drop -> cell (%d,%d) y=%d yaw=%d" % [x, z, y_level, int(snapped_yaw)])

func _end_edit_mode() -> void:
	if is_instance_valid(_edit_grabbed):
		_edit_release()
	_edit_grabbed = null
	_edit_target = null
	_edit_trigger_was_down = false
	_hide_edit_highlight()

func _get_edit_structure() -> GridStructureComponent:
	if _voxel_controller and _voxel_controller.structure_component:
		return _voxel_controller.structure_component
	var n := _find_node_by_name(get_tree().root, "GridStructureComponent")
	if n is GridStructureComponent:
		return n as GridStructureComponent
	return null

func _grid_origin_of(structure: GridStructureComponent) -> Vector3:
	var p := structure.get_parent()
	if p is Node3D:
		return (p as Node3D).global_position
	return Vector3.ZERO

func _show_edit_highlight(node: Node3D) -> void:
	if _edit_highlight == null:
		_build_edit_highlight()
	var size: float = 1.0
	var structure := _get_edit_structure()
	if structure:
		size = structure.cube_size + structure.gutter
	_edit_highlight.scale = Vector3.ONE * size
	_edit_highlight.global_position = node.global_position
	_edit_highlight.visible = true

func _hide_edit_highlight() -> void:
	if _edit_highlight:
		_edit_highlight.visible = false

func _build_edit_highlight() -> void:
	_edit_highlight = MeshInstance3D.new()
	_edit_highlight.name = "EditHighlight"
	_edit_highlight.top_level = true  # world space — ignore the shrunk catalyst
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * 0.95
	_edit_highlight.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 1.0, 0.6, 0.18)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.4, 1.0, 0.6)
	mat.emission_energy_multiplier = 0.6
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	_edit_highlight.material_override = mat
	_edit_highlight.visible = false
	add_child(_edit_highlight)

# ── Lab net editing — props stick to their face, snap in-plane to 0.1m ───────

func _edit_release_lab(node: Node3D) -> void:
	if not is_instance_valid(node):
		return
	_apply_lab_magnetism(node)  # final stick to whatever surface it's near
	node.rotation = Vector3(0.0, node.rotation.y, 0.0)  # keep upright, preserve yaw
	if not node.is_in_group("vr_lab_moved"):
		node.add_to_group("vr_lab_moved")  # B will save it
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.12, 0.5, 0.0)
	var stuck := bool(node.get_meta("lab_stuck", false))
	var suffix: String = "  (stuck)" if stuck else "  (free)"
	_flash_label("MOVED  %s%s" % [String(node.get_meta("lab_lookup", "")), suffix], Color(0.4, 1.0, 0.6))
	print("[Catalyst] Lab move: %s local=%s stuck=%s" % [String(node.get_meta("lab_prop_id", "")), str(node.position), str(stuck)])

## Surface magnetism: a held lab prop moves freely, but within LAB_SNAP_DIST of a
## wall / floor / ceiling (or the top of another prop) it sticks flush to that
## surface, gridded to 0.1m along it. Pull it away to un-stick. Works in the
## lab_room's local frame (prop positions are room-local).
func _apply_lab_magnetism(node: Node3D) -> void:
	var dims_v: Vector3 = node.get_meta("lab_room_dims", Vector3(8.0, 7.0, 4.5))
	var rw: float = dims_v.x
	var rd: float = dims_v.y
	var rh: float = dims_v.z
	var p: Vector3 = node.position

	# Nearest wall within snap distance (the wall to align + sit flush against).
	var wd: Array = [absf(p.x - rw / 2.0), absf(p.x + rw / 2.0), absf(p.z - rd / 2.0), absf(p.z + rd / 2.0)]
	var wcoord: Array = [rw / 2.0, -rw / 2.0, rd / 2.0, -rd / 2.0]
	var wyaw: Array = [270.0, 90.0, 0.0, 180.0]  # face INTO the room (front to viewer; +Z-forward)
	var wisx: Array = [true, true, false, false]
	var bw := -1
	var bd: float = LAB_SNAP_DIST + 0.001
	for i in 4:
		if wd[i] < bd:
			bd = wd[i]
			bw = i

	if bw >= 0:
		# stick to the wall, ALIGN the facing to it, and offset so it sits flush.
		var np: Vector3 = p
		if p.y <= LAB_SNAP_DIST:
			np.y = 0.0  # a wall prop near the floor also stands on it
		elif p.y >= rh - LAB_SNAP_DIST:
			np.y = rh
		if wisx[bw]:
			np.x = wcoord[bw]
		else:
			np.z = wcoord[bw]
		node.position = np
		# align: face the room. An artifact may declare wall_facing_offset_deg if
		# its front is the opposite of the +Z convention (e.g. wall_placard = 180).
		var face_off: float = 0.0
		var fo = node.get("wall_facing_offset_deg")
		if fo != null:
			face_off = float(fo)
		node.rotation = Vector3(0.0, deg_to_rad(wyaw[bw] + face_off), 0.0)
		# Flush: push the prop's wall-side edge exactly onto the wall plane.
		var ab: AABB = node.transform * _held_aabb
		if wisx[bw]:
			if wcoord[bw] > 0.0:
				node.position.x += wcoord[bw] - (ab.position.x + ab.size.x)
			else:
				node.position.x += wcoord[bw] - ab.position.x
			node.position.z = _snap01(node.position.z)  # grid along the wall
		else:
			if wcoord[bw] > 0.0:
				node.position.z += wcoord[bw] - (ab.position.z + ab.size.z)
			else:
				node.position.z += wcoord[bw] - ab.position.z
			node.position.x = _snap01(node.position.x)
		node.position.y = _snap01(node.position.y)
		_clamp_prop_to_room(node, rw, rd, rh)
		node.set_meta("lab_stuck", true)
		return

	# No wall — floor / ceiling / table for the vertical axis (free rotation kept).
	var s: Vector3 = p
	var stuck := false
	if p.y <= LAB_SNAP_DIST:
		s.y = 0.0
		stuck = true
	elif p.y >= rh - LAB_SNAP_DIST:
		s.y = rh
		stuck = true
	for surf in _lab_surfaces:
		if absf(p.x - surf["cx"]) <= surf["hx"] + 0.1 and absf(p.z - surf["cz"]) <= surf["hz"] + 0.1:
			if absf(p.y - surf["top"]) <= LAB_SNAP_DIST and p.y >= surf["top"] - 0.05:
				s.y = surf["top"]
				stuck = true
				break
	node.position = s
	# floor flush — push the prop's bottom onto the floor (base-origin → no change)
	if stuck and is_zero_approx(s.y):
		var ab2: AABB = node.transform * _held_aabb
		node.position.y += -ab2.position.y
	if stuck:
		node.position.x = _snap01(node.position.x)
		node.position.y = _snap01(node.position.y)
		node.position.z = _snap01(node.position.z)
	_clamp_prop_to_room(node, rw, rd, rh)
	node.set_meta("lab_stuck", stuck)

## Keep the prop's body inside the room — never let any part cross a wall, the
## floor, or the ceiling. Uses its AABB; pushes it back in if an edge pokes out.
## Guarantees an artifact always sits on the room side of every plane.
func _clamp_prop_to_room(node: Node3D, rw: float, rd: float, rh: float) -> void:
	var ab: AABB = node.transform * _held_aabb
	if ab.size.length() <= 0.0001:
		return
	var lo: Vector3 = ab.position
	var hi: Vector3 = ab.position + ab.size
	var push := Vector3.ZERO
	if lo.x < -rw / 2.0:
		push.x = -rw / 2.0 - lo.x
	elif hi.x > rw / 2.0:
		push.x = rw / 2.0 - hi.x
	if lo.z < -rd / 2.0:
		push.z = -rd / 2.0 - lo.z
	elif hi.z > rd / 2.0:
		push.z = rd / 2.0 - hi.z
	if lo.y < 0.0:
		push.y = -lo.y
	elif hi.y > rh:
		push.y = rh - hi.y
	node.position += push

## AABB of a node's visible meshes in the node's OWN local frame (constant; cached
## on grab). node.transform * this gives the room-local AABB (exact for the 90°-
## multiple facing yaws we use), which drives the flush-to-wall offset.
func _local_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is VisualInstance3D:
			var vi := n as VisualInstance3D
			var a: AABB = vi.get_aabb()
			if a.size.length() > 0.0001:
				var t := Transform3D.IDENTITY
				var cur: Node = n
				while cur != null and cur != root:
					if cur is Node3D:
						t = (cur as Node3D).transform * t
					cur = cur.get_parent()
				for i in 8:
					var c: Vector3 = a.position
					if i & 1:
						c.x += a.size.x
					if i & 2:
						c.y += a.size.y
					if i & 4:
						c.z += a.size.z
					var lc: Vector3 = t * c
					if first:
						result = AABB(lc, Vector3.ZERO)
						first = false
					else:
						result = result.expand(lc)
		for ch in n.get_children():
			stack.append(ch)
	return result

## Snapshot the OTHER lab props' tops + footprints (room-local) so the held prop
## can stick on them (tables). Assumes the lab_room is axis-aligned in the world.
func _cache_lab_surfaces(grabbed: Node3D) -> void:
	_lab_surfaces.clear()
	var room := grabbed.get_parent()
	if not (room is Node3D):
		return
	var room_origin: Vector3 = (room as Node3D).global_position
	for n in get_tree().get_nodes_in_group("vr_lab_prop"):
		if n == grabbed or not is_instance_valid(n) or not (n is Node3D):
			continue
		var g := _global_aabb(n as Node3D)
		if g.size.y <= 0.001:
			continue
		_lab_surfaces.append({
			"cx": g.position.x + g.size.x * 0.5 - room_origin.x,
			"cz": g.position.z + g.size.z * 0.5 - room_origin.z,
			"hx": g.size.x * 0.5,
			"hz": g.size.z * 0.5,
			"top": g.position.y + g.size.y - room_origin.y,
		})

## World-space AABB of a node's visible meshes.
func _global_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is VisualInstance3D:
			var vi := n as VisualInstance3D
			var a: AABB = vi.get_aabb()
			if a.size.length() > 0.0001:
				var gt: Transform3D = vi.global_transform
				for i in 8:
					var c: Vector3 = a.position
					if i & 1:
						c.x += a.size.x
					if i & 2:
						c.y += a.size.y
					if i & 4:
						c.z += a.size.z
					var wc: Vector3 = gt * c
					if first:
						result = AABB(wc, Vector3.ZERO)
						first = false
					else:
						result = result.expand(wc)
		for ch in n.get_children():
			stack.append(ch)
	return result

func _snap01(v: float) -> float:
	return round(v / 0.1) * 0.1

## B in Lab mode: POST the moved lab props back to their lab JSON (by id), over
## adb reverse, so the change lands in commons/labs/<name>.lab.json.
func _save_lab() -> void:
	print("[Catalyst] _save_lab() called")
	var updates: Array = []
	var lab_name := ""
	for node in get_tree().get_nodes_in_group("vr_lab_moved"):
		if not is_instance_valid(node):
			continue
		var pid := String(node.get_meta("lab_prop_id", ""))
		if pid == "":
			continue
		if lab_name == "":
			var jp := String(node.get_meta("lab_json_path", ""))
			lab_name = jp.get_file().trim_suffix(".json").trim_suffix(".lab")
		var pos: Vector3 = node.position
		updates.append({
			"id": pid,
			"position": [pos.x, pos.y, pos.z],
			"rotation_y": rad_to_deg(node.rotation.y),
		})
	if lab_name == "" or updates.is_empty():
		_flash_label("NO LAB EDITS", Color(1.0, 0.5, 0.2))
		return
	_save_lab_over_http(lab_name, updates)
	_flash_label("SAVING LAB  " + lab_name + " ...", Color(0.6, 0.85, 1.0))
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.12, 0.4, 0.0)

func _save_lab_over_http(lab_name: String, updates: Array) -> void:
	print("[Catalyst] POSTing lab '%s' (%d prop updates) -> %s" % [lab_name, updates.size(), LAB_SAVE_URL])
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_lab_save_completed.bind(http))
	var headers := PackedStringArray(["Content-Type: application/json"])
	var payload := {"name": lab_name, "propUpdates": updates}
	http.set_meta("lab_name", lab_name)
	var err := http.request(LAB_SAVE_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		http.queue_free()
		_flash_label("POST FAILED: %s" % error_string(err), Color(1.0, 0.3, 0.3))

func _on_lab_save_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray, http: HTTPRequest) -> void:
	var ln := String(http.get_meta("lab_name", ""))
	http.queue_free()
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		_flash_label("LAB SAVED -> PC  " + ln, Color(0.4, 1.0, 0.6))
		if controller:
			controller.trigger_haptic_pulse("haptic", 0.0, 0.2, 0.6, 0.0)
	else:
		var hint := ""
		if result == HTTPRequest.RESULT_CANT_CONNECT:
			hint = "  (adb reverse tcp:3003 tcp:3003)"
		_flash_label("LAB SAVE FAILED %d/%d%s" % [result, response_code, hint], Color(1.0, 0.35, 0.35))
		push_warning("[Catalyst] lab save HTTP failed result=%d code=%d" % [result, response_code])


func _voxel_save() -> void:
	if not _voxel_controller or not _voxel_controller.structure_component:
		return
	var data := _find_node_by_name(get_tree().root, "GridDataComponent")
	var map_name: String = ""
	if data and data.has_method("get_current_map_name"):
		map_name = data.get_current_map_name()
	if map_name.is_empty():
		return
	VoxelSaveManager.save(map_name, _voxel_controller.structure_component)
	print("[Catalyst] 💾 Saved: %s" % map_name)
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.15, 0.5, 0.0)


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found:
			return found
	return null


func _check_mode_switch() -> void:
	# Mode switching is done by the OTHER hand rotating the bracelet hinge.
	# No thumbstick or grip-click mode switching on the catalyst hand.
	pass

func _switch_mode(direction: int) -> void:
	var new_index := (current_mode_index + direction) % unlocked_modes.size()
	if new_index < 0:
		new_index = unlocked_modes.size() - 1
	if new_index == current_mode_index:
		return

	current_mode_index = new_index
	var mode_id := unlocked_modes[current_mode_index]

	_show_mode_label()
	mode_changed.emit(mode_id)

	# Activate/deactivate grid editing based on mode (voxel + wedge share the controller)
	if mode_id in ["voxel_editor", "wedge_placer"]:
		_activate_voxel_mode()
	else:
		_deactivate_voxel_mode()

	# Keep bracelet in sync with thumbstick switching
	var cap_mgr = get_node_or_null("/root/CatalystCapabilityManager")
	if cap_mgr and cap_mgr.has_method("get_bracelet"):
		var bracelet = cap_mgr.get_bracelet()
		if bracelet and bracelet.has_method("sync_to_mode"):
			bracelet.sync_to_mode(current_mode_index)

	# Haptic tick
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.15, 0.0)

	print("[Catalyst] Switched to mode: %s" % mode_id)

## Set mode by absolute index (called by capacity bracelet).
func set_mode_index(index: int) -> void:
	if index < 0 or index >= unlocked_modes.size() or index == current_mode_index:
		return
	current_mode_index = index
	var mode_id := unlocked_modes[current_mode_index]
	_show_mode_label()
	_rebuild_visual()
	mode_changed.emit(mode_id)

	# Activate/deactivate grid editing (voxel + wedge share the controller)
	if mode_id in ["voxel_editor", "wedge_placer"]:
		_activate_voxel_mode()
	else:
		_deactivate_voxel_mode()

	# Don't call bracelet.sync_to_mode here — the bracelet initiated this change
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.04, 0.15, 0.0)
	print("[Catalyst] Set mode to: %s" % mode_id)

func _show_mode_label() -> void:
	if not _mode_label:
		return
	var mode_def := _get_current_mode_def()
	var mode_name: String = mode_def.get("name", "???")
	var index_display: String = "%d/%d" % [current_mode_index + 1, unlocked_modes.size()]
	_mode_label.text = "%s  %s" % [index_display, mode_name]
	_mode_label.modulate = CatalystVisual.get_mode_color(mode_def.get("id", ""))
	_mode_label.visible = true
	_mode_label_timer = 4.0  # Visible longer so player can read it

func _get_current_mode_def() -> Dictionary:
	if current_mode_index < 0 or current_mode_index >= unlocked_modes.size():
		return {}
	var mode_id := unlocked_modes[current_mode_index]
	for def in MODE_DEFS:
		if def["id"] == mode_id:
			return def
	return {}

# ═════════════════════════════════════════════════════════════════════════
# PROGRESSION — MODE UNLOCKING
# ═════════════════════════════════════════════════════════════════════════

func _connect_progression_signals() -> void:
	# Try LabManager first (has is_sequence_completed)
	var lab_mgr := _find_lab_manager()
	if lab_mgr and lab_mgr.has_method("is_sequence_completed"):
		# Check already-completed sequences
		for mode_def in MODE_DEFS:
			if lab_mgr.is_sequence_completed(mode_def["sequence"]):
				_unlock_mode(mode_def["id"], false)

	# Listen for future completions from AdaSceneManager
	var scene_mgr := get_node_or_null("/root/AdaSceneManager")
	if scene_mgr and scene_mgr.has_signal("sequence_completed"):
		if not scene_mgr.sequence_completed.is_connected(_on_sequence_completed):
			scene_mgr.sequence_completed.connect(_on_sequence_completed)
			print("[Catalyst] Connected to AdaSceneManager.sequence_completed")

	# Also try MapProgressionManager
	var map_prog := get_node_or_null("/root/MapProgressionManager")
	if map_prog and map_prog.has_signal("sequence_completed"):
		if not map_prog.sequence_completed.is_connected(_on_map_progression_sequence_completed):
			map_prog.sequence_completed.connect(_on_map_progression_sequence_completed)
			print("[Catalyst] Connected to MapProgressionManager.sequence_completed")

func _on_sequence_completed(sequence_name: String, _completion_data: Dictionary) -> void:
	for mode_def in MODE_DEFS:
		if mode_def["sequence"] == sequence_name:
			_unlock_mode(mode_def["id"], true)

func _on_map_progression_sequence_completed(sequence_name: String) -> void:
	for mode_def in MODE_DEFS:
		if mode_def["sequence"] == sequence_name:
			_unlock_mode(mode_def["id"], true)

func _unlock_mode(mode_id: String, notify: bool = true) -> void:
	if mode_id in unlocked_modes:
		return
	unlocked_modes.append(mode_id)
	_save_unlocked_modes()
	_rebuild_visual()
	if notify:
		mode_unlocked.emit(mode_id)
		print("[Catalyst] 🌀 Unlocked mode: %s" % mode_id)

func unlock_all_modes() -> void:
	"""Debug: unlock everything."""
	for mode_def in MODE_DEFS:
		_unlock_mode(mode_def["id"], false)
	_rebuild_visual()
	print("[Catalyst] All modes unlocked")

func _find_lab_manager() -> Node:
	# LabManager could be autoload or in scene tree
	var mgr := get_node_or_null("/root/LabManager")
	if mgr:
		return mgr
	# Search scene tree
	var tree := get_tree()
	if tree:
		for node in tree.get_nodes_in_group("lab_manager"):
			return node
	return null

# ═════════════════════════════════════════════════════════════════════════
# SAVE / LOAD
# ═════════════════════════════════════════════════════════════════════════

func _save_unlocked_modes() -> void:
	pass  # Fresh start every session — modes unlock during gameplay

func _load_unlocked_modes() -> void:
	# Fresh start: only voxel_editor, modes unlock during gameplay
	current_mode_index = 0

# ═════════════════════════════════════════════════════════════════════════
# VISUAL CONSTRUCTION
# ═════════════════════════════════════════════════════════════════════════

func _rebuild_visual() -> void:
	CatalystVisual.build_crystal(self, unlocked_modes)

func _setup_physics() -> void:
	mass = 0.25
	gravity_scale = 1.0
	linear_damp = 1.0
	angular_damp = 2.0

	# Configure the CollisionShape3D inherited from pickable.tscn
	_collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _collision_shape:
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.06
		capsule.height = 0.22
		_collision_shape.shape = capsule
	else:
		# Fallback: create one if not instanced from pickable.tscn
		_collision_shape = CollisionShape3D.new()
		_collision_shape.name = "CollisionShape3D"
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.06
		capsule.height = 0.22
		_collision_shape.shape = capsule
		add_child(_collision_shape)

func _build_tip() -> void:
	_tip = Marker3D.new()
	_tip.name = "Tip"
	_tip.position = Vector3(0, 0.12, 0)  # Top of crystal
	add_child(_tip)

func _build_mode_label() -> void:
	_mode_label = Label3D.new()
	_mode_label.name = "ModeLabel"
	_mode_label.position = Vector3(0, 0.2, 0)
	_mode_label.pixel_size = 0.002
	_mode_label.font_size = 32
	_mode_label.outline_size = 4
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mode_label.no_depth_test = true
	_mode_label.visible = false
	# When held, the catalyst is shrunk to scale 0.01 ("absorbed into hand") so
	# the body is invisible. A normal child label would shrink with it to 1/100th
	# and never be seen. top_level makes the label ignore the parent transform; we
	# place it in world space above the controller each frame (see _physics_process).
	_mode_label.top_level = true
	_mode_label.pixel_size = 0.0012
	add_child(_mode_label)

# ═════════════════════════════════════════════════════════════════════════
# XR-TOOLS PICKABLE CALLBACKS
# ═════════════════════════════════════════════════════════════════════════

func _on_picked_up(_pickable) -> void:
	is_held = true

	# Find controller — walk up from the holder node
	controller = _find_xr_controller()
	if controller:
		_pickup_controller_name = controller.name
		print("[Catalyst] Picked up — controller: '%s' (path: %s)" % [controller.name, controller.get_path()])
		if not controller.button_pressed.is_connected(_on_controller_button):
			controller.button_pressed.connect(_on_controller_button)
	else:
		print("[Catalyst] WARNING: Could not find XRController3D in pickup hierarchy")

	# Shrink into hand, then absorb permanently
	if _pickup_tween and _pickup_tween.is_running():
		_pickup_tween.kill()
	_pickup_tween = create_tween()
	_pickup_tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.35) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	_pickup_tween.tween_callback(_absorb_into_hand)

	# Haptic pulse — absorbing the crystal
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.0, 0.15, 0.4, 0.0)

## Remove any previously absorbed catalyst on the given controller.
func _replace_existing_catalyst(ctrl: XRController3D) -> void:
	if not is_instance_valid(ctrl):
		return
	var existing := get_tree().get_nodes_in_group("catalyst")
	for cat in existing:
		if cat == self:
			continue
		if not is_instance_valid(cat):
			continue
		if cat.get("_absorbed") and cat.get("controller") == ctrl:
			# Disconnect old catalyst's button handler
			if ctrl.button_pressed.is_connected(cat._on_controller_button):
				ctrl.button_pressed.disconnect(cat._on_controller_button)
			cat.queue_free()
			print("[Catalyst] Replaced previous catalyst on '%s'" % ctrl.name)

## Crystal is consumed — reparent to controller, release FunctionPickup hold.
func _absorb_into_hand() -> void:
	_absorbed = true

	# If controller reference was lost, try to recover — prefer the SAME hand
	if not is_instance_valid(controller):
		print("[Catalyst] Controller lost since pickup, recovering...")
		# Method A: Walk up from current holder (most reliable)
		var holder = get_picked_up_by()
		if holder:
			var node = holder
			while node:
				if node is XRController3D:
					controller = node
					print("[Catalyst] Recovered controller from holder chain: '%s'" % controller.name)
					break
				node = node.get_parent()
		# Method B: Find controller by saved name
		if not is_instance_valid(controller) and not _pickup_controller_name.is_empty():
			controller = _find_controller_by_name(_pickup_controller_name)
			if controller:
				print("[Catalyst] Recovered controller by saved name: '%s'" % controller.name)
		# Method C: General fallback
		if not is_instance_valid(controller):
			controller = _find_xr_controller()
			if controller:
				print("[Catalyst] Fallback controller: '%s'" % controller.name)

	# Remove any previous catalyst on this controller — only one at a time
	_replace_existing_catalyst(controller)

	# Remember controller before let_go triggers _on_dropped
	var ctrl := controller

	# Release from FunctionPickup so the hand is free to grab other things
	var holder = get_picked_up_by()
	if holder and is_picked_up():
		let_go(holder, Vector3.ZERO, Vector3.ZERO)

	# Restore state that _on_dropped cleared
	controller = ctrl
	is_held = true

	# Kill physics — we're a ghost node now
	freeze = true
	collision_layer = 0
	collision_mask = 0
	if _collision_shape:
		_collision_shape.disabled = true

	# Reconnect trigger (let_go → _on_dropped may have disconnected it)
	if controller and not controller.button_pressed.is_connected(_on_controller_button):
		controller.button_pressed.connect(_on_controller_button)

	# Reparent to the controller so we follow the hand
	call_deferred("_deferred_reparent")

	# Hand glow
	if _held_glow:
		var mode_color := CatalystVisual.get_mode_color(unlocked_modes[current_mode_index])
		_held_glow.light_color = mode_color
		_held_glow.light_energy = 1.5

	# Activate voxel mode if it's the current mode (default on start)
	if unlocked_modes[current_mode_index] == "voxel_editor":
		call_deferred("_activate_voxel_mode")

## Auto-absorb onto a controller without pickup animation.
## Used by CatalystCapabilityManager to restore catalyst after scene transitions.
func auto_absorb(ctrl: XRController3D) -> void:
	# Remove any previous catalyst on this controller — only one at a time
	_replace_existing_catalyst(ctrl)

	_absorbed = true
	is_held = true
	controller = ctrl
	_pickup_controller_name = ctrl.name

	# Kill physics
	freeze = true
	collision_layer = 0
	collision_mask = 0
	if _collision_shape:
		_collision_shape.disabled = true

	# Connect trigger
	if not controller.button_pressed.is_connected(_on_controller_button):
		controller.button_pressed.connect(_on_controller_button)

	# Reparent to controller — tiny and invisible
	var old_parent := get_parent()
	if old_parent:
		old_parent.remove_child(self)
	controller.add_child(self)
	position = Vector3.ZERO
	scale = Vector3(0.01, 0.01, 0.01)
	# Don't set visible=false — ghost cubes are descendants and Godot hides
	# all children of invisible nodes even with top_level=true.
	# The 0.01 scale already makes the catalyst effectively invisible.

	# Hand glow
	if _held_glow and current_mode_index < unlocked_modes.size():
		var mode_color := CatalystVisual.get_mode_color(unlocked_modes[current_mode_index])
		_held_glow.light_color = mode_color
		_held_glow.light_energy = 1.5

	# Activate voxel mode if it's the current mode (same as regular pickup)
	if unlocked_modes[current_mode_index] == "voxel_editor":
		call_deferred("_activate_voxel_mode")

	print("[Catalyst] Auto-absorbed onto '%s' with %d modes: %s" % [
		controller.name, unlocked_modes.size(), unlocked_modes])

func _deferred_reparent() -> void:
	if not is_instance_valid(controller):
		print("[Catalyst] _deferred_reparent: controller INVALID, aborting")
		return
	print("[Catalyst] _deferred_reparent: reparenting to controller '%s' (path: %s, global_pos: %s)" % [
		controller.name, controller.get_path(), controller.global_position])
	var old_parent := get_parent()
	if old_parent:
		old_parent.remove_child(self)
	controller.add_child(self)
	position = Vector3.ZERO
	scale = Vector3(0.01, 0.01, 0.01)

	# Notify the capability manager to spawn the bracelet on this controller
	var cap_mgr = get_node_or_null("/root/CatalystCapabilityManager")
	if cap_mgr and cap_mgr.has_method("spawn_bracelet_on_controller"):
		print("[Catalyst] Requesting bracelet spawn on controller '%s'" % controller.name)
		cap_mgr.spawn_bracelet_on_controller(controller)
	else:
		print("[Catalyst] WARNING: CatalystCapabilityManager not found or missing spawn method")

func _on_dropped(_pickable) -> void:
	if _absorbed:
		# let_go() fired this during absorption — ignore it
		return

	is_held = false
	if controller and controller.button_pressed.is_connected(_on_controller_button):
		controller.button_pressed.disconnect(_on_controller_button)
	controller = null

	if _held_glow:
		_held_glow.light_energy = 0.0
	if _mode_label:
		_mode_label.visible = false

# ═════════════════════════════════════════════════════════════════════════
# CONTROLLER FINDING
# ═════════════════════════════════════════════════════════════════════════

func _find_xr_controller() -> XRController3D:
	# Method 1: Walk up from the holder (FunctionPickup → ... → XRController3D)
	var pickup_node = get_picked_up_by()
	if pickup_node:
		var node = pickup_node
		while node:
			if node is XRController3D:
				return node
			node = node.get_parent()

	# Method 2: Walk up from self (pickable may already be reparented under controller)
	var node = get_parent()
	while node:
		if node is XRController3D:
			return node
		node = node.get_parent()

	# Method 3: Search the scene tree for any XRController3D
	for child in get_tree().root.get_children():
		var found := _find_controller_recursive(child)
		if found:
			return found

	return null

func _find_controller_recursive(node: Node) -> XRController3D:
	if node is XRController3D:
		return node
	for child in node.get_children():
		var found := _find_controller_recursive(child)
		if found:
			return found
	return null

## Find a specific controller by name (recursive search).
func _find_controller_by_name(ctrl_name: String) -> XRController3D:
	for child in get_tree().root.get_children():
		var found := _find_named_controller_recursive(child, ctrl_name)
		if found:
			return found
	return null

func _find_named_controller_recursive(node: Node, ctrl_name: String) -> XRController3D:
	if node is XRController3D and node.name == ctrl_name:
		return node
	for child in node.get_children():
		var found := _find_named_controller_recursive(child, ctrl_name)
		if found:
			return found
	return null

# ═════════════════════════════════════════════════════════════════════════
# GRID INTEGRATION
# ═════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	configure(config_data)

func configure(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	# Debug: unlock all modes
	if config_data.has("all_modes"):
		unlock_all_modes()
	# Unlock a specific mode
	if config_data.has("start_mode"):
		_unlock_mode(str(config_data["start_mode"]))
	# Unlock up to a specific mode by order
	if config_data.has("unlock_to"):
		var target_order := int(config_data["unlock_to"])
		for mode_def in MODE_DEFS:
			if mode_def["order"] <= target_order:
				_unlock_mode(mode_def["id"], false)
	# Unlock only the SHOOTING modes (skip voxel_editor + wedge_placer
	# which are at order 0 and consume A/X for placement). Used by the
	# catalyst test maps so the bracelet starts on a projectile mode.
	# CRITICAL: also REMOVE the seeded voxel/wedge/off modes from
	# unlocked_modes — otherwise the bracelet still gets them in its
	# rotation and shows voxel as the active gem at index 0.
	if config_data.has("shooting_only"):
		unlocked_modes = unlocked_modes.filter(
			func(id: String) -> bool:
				return id not in ["voxel_editor", "wedge_placer", "off"]
		)
		for mode_def in MODE_DEFS:
			if int(mode_def.get("order", 0)) >= 1:
				_unlock_mode(mode_def["id"], false)
		# Reset index since the array shifted under us.
		current_mode_index = 0
	# Set the active mode index to point at a specific mode_id, AFTER
	# any unlocks above. This is what controls which mode A/X fires in.
	if config_data.has("active_mode"):
		var target_id: String = str(config_data["active_mode"])
		var idx: int = unlocked_modes.find(target_id)
		if idx >= 0:
			current_mode_index = idx

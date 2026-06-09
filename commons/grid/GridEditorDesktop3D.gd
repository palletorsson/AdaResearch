extends Node3D
## GridEditorDesktop3D — the DESKTOP twin of the VR bracelet grid editor.
##
## A standalone desktop editor for GRID structure + paint. It builds (or loads)
## the REAL GridSystem renderer and edits it in place, so what you see is exactly
## what the game builds — ZERO DRIFT. The side panel is the SAME TabbedEditorPanel
## the VR bracelet mounts ("one menu, both editors"); its signals drive the
## editor's active tool, brush size, level, paint op, and colour.
##
## Mirrors commons/biome_layers/BiomeScrubberDesktop3D.gd: orbit camera
## (RIGHT-drag orbit, wheel zoom), header labels + transient toast, a HIDE/SHOW
## panel (Tab), undo/redo (Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z), W = save, and a
## headless --shot screenshot+quit path.
##
## GRID tab → height ops via GridOps.stroke() over a small brush footprint
## (GridOps.brush_cells, 1..4) read/written through the structure component's
## get_height_at / set_height_at. PAINT row → ModifierStack (colorize / random /
## clear) over the same footprint → set_cell_color per cell. ARTIFACTS / BIOME
## tabs are present but light stubs (a toast) — the grid is the focus.
##
## Controls:
##   RIGHT-drag orbit   ·   wheel zoom   ·   WASD/Q/E fly (optional)
##   LEFT-drag / click  apply the active tool at the hovered cell
##   Ctrl+Z undo   ·   Ctrl+Y / Ctrl+Shift+Z redo   ·   W save → repo   ·   Tab panel
##
## CLI (headless):
##   --map=<Name>   edit an existing map's real structure
##   --dims=N       synthetic flat NxN grid when no --map
##   --shot=<path>  render one frame, screenshot to <path>, quit

# The ONE unified editor panel (GRID / ARTIFACTS / BIOME) — reused from VR.
const TabbedEditorPanelScene = preload("res://commons/hazards/becoming_catalyst/tabbed_editor_panel.tscn")
const GridSystemScene = preload("res://commons/grid/grid_system.tscn")
const GridOpsLib = preload("res://commons/modifiers/grid_ops.gd")
const ModifierStackLib = preload("res://commons/modifiers/modifier_stack.gd")

@export var cube_size: float = 1.0
@export var fly_speed: float = 6.0

# ── Map / grid state ──────────────────────────────────────────────────
var _map_arg: String = ""                 # --map=<Name>; "" = synthetic
var _loaded_map: String = ""              # the map actually being edited (may be synthetic)
var _synthetic_dims: int = 16             # --dims=N synthetic square size
var _grid_w: int = 16
var _grid_d: int = 16
var _grid_max_h: int = 5
var _grid_system: Node3D = null           # the REAL GridSystem (zero drift)
var _structure: GridStructureComponent = null
var _editing_ready: bool = false
var _map_data: Dictionary = {}            # full parsed map_data.json (for write-back)

# ── Active tool state (set by the panel's signals) ────────────────────
const TOOL_GRID := "grid"
const TOOL_PAINT := "paint"
var _active_mode: String = TOOL_GRID      # which row drives a left-click
var _active_grid_op: String = "add"       # GridOps op name
var _active_paint_op: String = "colorize" # ModifierStack op name
var _active_brush_size: int = 2           # 1..4 (GridOps.MAX_BRUSH)
var _active_level: int = 3                # height value for fill/raise/etc.
var _active_color: Color = Color(0.9, 0.6, 0.2)
var _active_tab: String = "GRID"

# ── Modifier (paint) op-stack — persisted top-level on save ───────────
var _modifier_stack: Array = []           # Array[Dictionary] colorize/random/normalize ops

# ── Hover + brush ghost ───────────────────────────────────────────────
var _hover_cell: Vector2i = Vector2i(-1, -1)   # (row, col) = (z, x)
var _hover_valid: bool = false
var _hover_highlight: MeshInstance3D = null    # single cell under the cursor
var _ghost: MultiMeshInstance3D = null         # brush footprint preview
var _painting: bool = false                    # left-button held → continuous apply

# ── Undo / redo (snapshot heights + colors before each stroke) ────────
var _undo_stack: Array = []               # Array[Dictionary] snapshots
var _redo_stack: Array = []
const UNDO_CAP := 30
var _stroke_dirty: bool = false           # a stroke happened since the last mouse-up

# ── Camera (orbit, mirrors the scrubber) ──────────────────────────────
var _camera: Camera3D = null
var _orbit_yaw: float = 0.6
var _orbit_pitch: float = -0.55
var _orbit_radius: float = 0.0
var _orbit_center: Vector3 = Vector3.ZERO
var _orbiting: bool = false

# ── Panel + HUD ───────────────────────────────────────────────────────
var _panel: Control = null
var _panel_root: Control = null
var _hud_layer: CanvasLayer = null
var _title_lbl: Label = null
var _ctx_lbl: Label = null
var _tool_lbl: Label = null
var _controls_lbl: Label = null
var _toast_lbl: Label = null
var _hud_err: Label = null
var _status_msg: String = ""

# ── Headless capture ──────────────────────────────────────────────────
var _shot_path: String = ""
var _capture_frames: int = 0

# ── Palette (matches the scrubber's designed surface) ─────────────────
const C_BG     := Color(0.05, 0.06, 0.09, 0.86)
const C_BG_SOFT := Color(0.08, 0.10, 0.14, 0.78)
const C_ACCENT := Color(0.45, 0.75, 1.0)     # grid-blue brand
const C_TEXT   := Color(0.93, 0.96, 1.0)
const C_DIM    := Color(0.58, 0.63, 0.72)
const C_GOLD   := Color(1.0, 0.78, 0.35)
const C_BAD    := Color(1.0, 0.45, 0.42)
const PANEL_W  := 360.0
const BAR_H    := 96.0


func _ready() -> void:
	_parse_cli()
	# Resolve initial grid dims (synthetic until a real map loads).
	_grid_w = _synthetic_dims
	_grid_d = _synthetic_dims
	_orbit_center = Vector3(float(_grid_w) * cube_size * 0.5, 0.0, float(_grid_d) * cube_size * 0.5)
	_orbit_radius = float(maxi(_grid_w, _grid_d)) * cube_size * 1.4

	_build_environment()
	_build_light()
	_build_camera()
	_build_ui()
	_build_hover_visuals()

	# Build the REAL grid (deferred — GridSystem loads its map asynchronously).
	call_deferred("_build_real_grid")

	if _shot_path != "":
		_capture_frames = 90


func _parse_cli() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := str(raw).strip_edges()
		if a.begins_with("--map="):
			_map_arg = a.split("=", true, 1)[1]
		elif a.begins_with("--dims="):
			_synthetic_dims = maxi(2, int(a.split("=", true, 1)[1]))
		elif a.begins_with("--shot="):
			_shot_path = a.split("=", true, 1)[1]


# ── Build the REAL GridSystem renderer (zero drift) ───────────────────
## With --map: load that map's real structure. Without: write a synthetic flat
## grid of --dims into a temp map dict and feed it the same way the game does, so
## the same renderer + editing path is exercised either way.
func _build_real_grid() -> void:
	if GridSystemScene == null:
		_fail("ERROR: grid_system.tscn failed to preload.")
		return

	var target_map := _map_arg
	if target_map == "":
		# Synthetic: synthesize a flat grid map on disk-equivalent, but we just
		# load a real GridSystem and override its editable layout after build.
		target_map = ""

	# Free any previous grid (re-entrancy guard for live reload).
	var old := get_node_or_null("GridSystem")
	if old:
		old.queue_free()
		await get_tree().process_frame

	_grid_system = GridSystemScene.instantiate()
	_grid_system.name = "GridSystem"
	if _map_arg != "" and ("map_name" in _grid_system):
		_grid_system.map_name = _map_arg
	add_child(_grid_system)

	# Wait for the map to finish generating.
	if _grid_system.has_signal("map_generation_complete"):
		await _grid_system.map_generation_complete
	else:
		for _i in range(12):
			await get_tree().process_frame

	# Find the structure component.
	if _grid_system.has_method("get_structure_component"):
		_structure = _grid_system.get_structure_component()
	if _structure == null:
		_structure = _grid_system.find_child("GridStructureComponent", true, false) as GridStructureComponent
	if _structure == null:
		_fail("ERROR: GridStructureComponent not found on GridSystem.")
		return

	# Enable editing so get_height_at / set_height_at operate on a real layout.
	var data_comp := _grid_system.find_child("GridDataComponent", true, false)
	if _map_arg != "" and data_comp and data_comp.has_method("get_structure_data"):
		_structure.enable_editing(data_comp.get_structure_data())
		_loaded_map = _map_arg
		# Read the map's real dimensions for camera + ghost sizing.
		if data_comp.has_method("get_grid_dimensions"):
			var dims: Vector3i = data_comp.get_grid_dimensions()
			_grid_w = maxi(1, dims.x)
			_grid_d = maxi(1, dims.z)
			_grid_max_h = maxi(1, dims.y)
		# Cache the full map_data.json for non-destructive write-back.
		_load_map_data(_map_arg)
	else:
		# Synthetic: build a flat editable layout directly on the structure.
		_synthesize_flat_grid()

	if "cube_size" in _structure:
		cube_size = _structure.cube_size

	_editing_ready = true
	_recenter_for_grid()
	_update_hover_grid_sized()
	_update_hud()
	print("[grid-editor] ready: map=%s  %dx%d  maxH=%d" % [
		(_loaded_map if _loaded_map != "" else "SYNTHETIC"), _grid_w, _grid_d, _grid_max_h])


## Synthetic mode: stamp a flat one-high layout into the structure so the editor
## has a real grid to mutate even without --map. enable_editing wants a structure
## data object; we fall back to set_height_at over a fresh layout built from a
## synthetic structure_data dict.
func _synthesize_flat_grid() -> void:
	_grid_w = _synthetic_dims
	_grid_d = _synthetic_dims
	_grid_max_h = GridOpsLib.MAX_H
	# Build a layout_data of all "1" rows and a minimal structure_data wrapper.
	var rows: Array = []
	for z in range(_grid_d):
		var row: Array = []
		for x in range(_grid_w):
			row.append("1")
		rows.append(row)
	var synth := _SynthStructureData.new()
	synth.layout_data = rows
	# Initialise the structure's grid arrays at the synthetic dims, then generate.
	if _structure.has_method("generate_structure"):
		_structure.generate_structure(synth, Vector3i(_grid_w, _grid_max_h, _grid_d))
	if _structure.has_method("enable_editing"):
		_structure.enable_editing(synth)
	_loaded_map = ""


## Minimal stand-in for the GridDataComponent's structure_data object — just the
## `layout_data` member the structure component reads.
class _SynthStructureData extends RefCounted:
	var layout_data: Array = []


func _load_map_data(map_name: String) -> void:
	var path := "res://commons/maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		_map_data = parsed
		# Seed the modifier stack from any existing top-level modifiers so a
		# re-save preserves earlier paint and undo can fall back past it.
		var mods = _map_data.get("modifiers", [])
		if mods is Array:
			_modifier_stack = mods.duplicate(true)


func _fail(msg: String) -> void:
	push_error("[grid-editor] " + msg)
	if _hud_err:
		_hud_err.text = msg


# ── Camera + hover sizing ─────────────────────────────────────────────
func _recenter_for_grid() -> void:
	_orbit_center = Vector3(float(_grid_w) * cube_size * 0.5, 0.6, float(_grid_d) * cube_size * 0.5)
	_orbit_radius = float(maxi(_grid_w, _grid_d)) * cube_size * 1.4


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.11)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.64)
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)


func _build_light() -> void:
	var dl := DirectionalLight3D.new()
	dl.name = "Sun"
	dl.rotation = Vector3(deg_to_rad(-52), deg_to_rad(38), 0)
	dl.light_energy = 1.1
	dl.shadow_enabled = true
	add_child(dl)


func _build_camera() -> void:
	# Reuse the scene's "Camera" child if present (mirrors the simple scene shape);
	# otherwise create one. Either way it's the active orbit camera.
	_camera = get_node_or_null("Camera") as Camera3D
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = "Camera"
		add_child(_camera)
	_camera.fov = 60.0
	_camera.current = true


# ── Hover highlight (single cell) + brush ghost (footprint) ───────────
func _build_hover_visuals() -> void:
	# Single-cell highlight quad just above the floor.
	_hover_highlight = MeshInstance3D.new()
	_hover_highlight.name = "HoverHighlight"
	var hm := PlaneMesh.new()
	hm.size = Vector2(cube_size * 0.96, cube_size * 0.96)
	_hover_highlight.mesh = hm
	var hmat := StandardMaterial3D.new()
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.albedo_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
	hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_hover_highlight.material_override = hmat
	_hover_highlight.visible = false
	add_child(_hover_highlight)

	# Brush footprint ghost — a MultiMesh of small quads, repositioned per hover.
	_ghost = MultiMeshInstance3D.new()
	_ghost.name = "BrushGhost"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var gq := PlaneMesh.new()
	gq.size = Vector2(cube_size * 0.86, cube_size * 0.86)
	mm.mesh = gq
	mm.instance_count = GridOpsLib.MAX_BRUSH * GridOpsLib.MAX_BRUSH
	_ghost.multimesh = mm
	var gmat := StandardMaterial3D.new()
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.vertex_color_use_as_albedo = true
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ghost.material_override = gmat
	_ghost.visible = false
	add_child(_ghost)


## Resize hover quads to the (possibly map-derived) cube size.
func _update_hover_grid_sized() -> void:
	if _hover_highlight and _hover_highlight.mesh is PlaneMesh:
		(_hover_highlight.mesh as PlaneMesh).size = Vector2(cube_size * 0.96, cube_size * 0.96)
	if _ghost and _ghost.multimesh and _ghost.multimesh.mesh is PlaneMesh:
		(_ghost.multimesh.mesh as PlaneMesh).size = Vector2(cube_size * 0.86, cube_size * 0.86)


# ── HUD ────────────────────────────────────────────────────────────────
func _mk_label(parent: Node, txt: String, size: int, col: Color, pos := Vector2.ZERO) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func _new_stylebox(bg: Color, accent_border_bottom := 0.0, radius := 0.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.content_margin_left = 12; sb.content_margin_right = 12
	sb.content_margin_top = 9; sb.content_margin_bottom = 9
	if radius > 0.0:
		sb.corner_radius_top_left = int(radius); sb.corner_radius_top_right = int(radius)
		sb.corner_radius_bottom_left = int(radius); sb.corner_radius_bottom_right = int(radius)
	if accent_border_bottom > 0.0:
		sb.border_width_bottom = int(accent_border_bottom)
		sb.border_color = C_ACCENT
	return sb


func _build_ui() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HUD"
	add_child(_hud_layer)

	# Top bar.
	var bar := Panel.new()
	bar.anchor_right = 1.0
	bar.offset_bottom = BAR_H
	bar.add_theme_stylebox_override("panel", _new_stylebox(C_BG, 2.0))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(bar)

	_title_lbl = _mk_label(_hud_layer, "◆  GRID  EDITOR", 22, C_ACCENT, Vector2(20, 12))
	# Context line (map · dims) right-aligned clear of the panel.
	_ctx_lbl = _mk_label(_hud_layer, "", 14, C_DIM, Vector2(0, 18))
	_ctx_lbl.anchor_right = 1.0
	_ctx_lbl.offset_right = -(PANEL_W + 24.0)
	_ctx_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Active tool + brush size readout, second row under the brand.
	_tool_lbl = _mk_label(_hud_layer, "", 16, C_TEXT, Vector2(20, 50))

	# Controls footer (bottom strip).
	_controls_lbl = _mk_label(_hud_layer, "", 13, C_DIM)
	_controls_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_controls_lbl.offset_left = 20.0
	_controls_lbl.offset_top = -26.0

	# Transient toast (gold), above the footer.
	_toast_lbl = _mk_label(_hud_layer, "", 14, C_GOLD)
	_toast_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_toast_lbl.offset_left = 20.0
	_toast_lbl.offset_top = -48.0

	# Error overlay (normally empty).
	_hud_err = _mk_label(_hud_layer, "", 15, C_BAD, Vector2(20, BAR_H + 8))

	# ── Right-side TabbedEditorPanel (one menu, both editors) ──────────
	_panel_root = Control.new()
	_panel_root.name = "PanelRoot"
	_panel_root.anchor_left = 1.0; _panel_root.anchor_right = 1.0
	_panel_root.anchor_top = 0.0; _panel_root.anchor_bottom = 1.0
	_panel_root.offset_left = -(PANEL_W + 8.0)
	_panel_root.offset_top = BAR_H + 8.0
	_panel_root.offset_right = -8.0
	_panel_root.offset_bottom = -8.0
	_hud_layer.add_child(_panel_root)

	_panel = TabbedEditorPanelScene.instantiate()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_root.add_child(_panel)
	_connect_panel_signals()


## Wire every TabbedEditorPanel signal to editor state. Each guard checks the
## signal exists so a panel revision can drop one without crashing the editor.
func _connect_panel_signals() -> void:
	if _panel == null:
		return
	if _panel.has_signal("tab_changed"):
		_panel.tab_changed.connect(_on_tab_changed)
	if _panel.has_signal("grid_op_selected"):
		_panel.grid_op_selected.connect(_on_grid_op_selected)
	if _panel.has_signal("brush_size_changed"):
		_panel.brush_size_changed.connect(_on_brush_size_changed)
	if _panel.has_signal("level_changed"):
		_panel.level_changed.connect(_on_level_changed)
	if _panel.has_signal("modifier_op_selected"):
		_panel.modifier_op_selected.connect(_on_modifier_op_selected)
	if _panel.has_signal("color_selected"):
		_panel.color_selected.connect(_on_color_selected)
	if _panel.has_signal("element_selected"):
		_panel.element_selected.connect(_on_element_selected)
	if _panel.has_signal("size_changed"):
		_panel.size_changed.connect(_on_biome_size_changed)
	if _panel.has_signal("pressure_changed"):
		_panel.pressure_changed.connect(_on_biome_pressure_changed)
	if _panel.has_signal("artifact_action"):
		_panel.artifact_action.connect(_on_artifact_action)


# ── Panel signal handlers ──────────────────────────────────────────────
func _on_tab_changed(tab_id: String) -> void:
	_active_tab = tab_id
	# GRID tab drives structure; BIOME/ARTIFACTS are stubs but keep the mode sane.
	if tab_id == "GRID":
		_active_mode = TOOL_GRID
	_update_hud()


func _on_grid_op_selected(op: String) -> void:
	_active_grid_op = op
	_active_mode = TOOL_GRID
	_status_msg = "grid op: %s" % op.to_upper()
	_update_hud()


func _on_brush_size_changed(size: int) -> void:
	_active_brush_size = clampi(size, 1, GridOpsLib.MAX_BRUSH)
	_update_hud()


func _on_level_changed(level: int) -> void:
	_active_level = clampi(level, 0, GridOpsLib.MAX_H)
	_update_hud()


func _on_modifier_op_selected(op: String) -> void:
	# Panel emits panel-side names (colorize / random / clear); map to ModifierStack.
	match op:
		"random": _active_paint_op = "random_colors"
		"clear": _active_paint_op = "normalize"
		_: _active_paint_op = "colorize"
	_active_mode = TOOL_PAINT
	_status_msg = "paint op: %s" % _active_paint_op.to_upper()
	_update_hud()


func _on_color_selected(color: Color) -> void:
	_active_color = color
	_active_mode = TOOL_PAINT
	_update_hud()


func _on_element_selected(element_name: String) -> void:
	# BIOME tab is a stub here — the grid is the focus. Acknowledge, don't crash.
	_status_msg = "biome element '%s' — paint biome in the Scrubber" % element_name
	_update_hud()


func _on_biome_size_changed(_radius: int) -> void:
	pass  # stub — biome brush not wired in the grid editor


func _on_biome_pressure_changed(_strength: float) -> void:
	pass  # stub


func _on_artifact_action(action: String) -> void:
	# ARTIFACTS tab is a stub — acknowledge with a toast.
	_status_msg = "artifacts: '%s' — placement lives in the artifact editor" % action
	_update_hud()


# ── Input ──────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_TAB:
				if _panel_root:
					_panel_root.visible = not _panel_root.visible
			KEY_W:
				# W alone = save (mirrors the scrubber). Ctrl chords reserved for undo/redo.
				if not event.ctrl_pressed:
					_save()
			KEY_Z:
				if event.ctrl_pressed and event.shift_pressed: _redo()
				elif event.ctrl_pressed: _undo()
			KEY_Y:
				if event.ctrl_pressed: _redo()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_painting = event.pressed
			if event.pressed:
				_push_undo()       # snapshot before the stroke
				_stroke_dirty = false
				_apply_at_hover()
			else:
				if _stroke_dirty:
					_stroke_dirty = false
				else:
					# Click placed nothing useful → discard the snapshot we pushed.
					if not _undo_stack.is_empty():
						_undo_stack.pop_back()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_radius = maxf(2.0, _orbit_radius - 1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_radius += 1.5
	elif event is InputEventMouseMotion:
		if _orbiting:
			_orbit_yaw -= event.relative.x * 0.006
			_orbit_pitch = clampf(_orbit_pitch - event.relative.y * 0.006, -1.45, -0.05)
		else:
			_update_hover()
			if _painting:
				_apply_at_hover()


# ── Per-frame: camera orbit + fly + capture countdown ─────────────────
func _process(delta: float) -> void:
	if _camera:
		_update_fly(delta)
		var x := _orbit_center.x + _orbit_radius * cos(_orbit_pitch) * sin(_orbit_yaw)
		var y := _orbit_center.y - _orbit_radius * sin(_orbit_pitch)
		var z := _orbit_center.z + _orbit_radius * cos(_orbit_pitch) * cos(_orbit_yaw)
		_camera.position = Vector3(x, y, z)
		_camera.look_at(_orbit_center, Vector3.UP)

	if _capture_frames > 0:
		_capture_frames -= 1
		if _capture_frames == 0:
			_take_screenshot(_shot_path)
			get_tree().quit()


## Optional WASD/Q-E fly: pan the orbit center in the camera's ground plane.
func _update_fly(delta: float) -> void:
	if _orbiting or _camera == null:
		return
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir.z -= 1.0
	if Input.is_key_pressed(KEY_S): dir.z += 1.0
	if Input.is_key_pressed(KEY_A): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): dir.x += 1.0
	if Input.is_key_pressed(KEY_Q): dir.y -= 1.0
	if Input.is_key_pressed(KEY_E): dir.y += 1.0
	if dir == Vector3.ZERO:
		return
	# Move in the camera's yaw frame (so W/S track the view, not world Z).
	var fwd := Vector3(sin(_orbit_yaw), 0.0, cos(_orbit_yaw))
	var right := Vector3(cos(_orbit_yaw), 0.0, -sin(_orbit_yaw))
	var move := right * dir.x + fwd * dir.z + Vector3.UP * dir.y
	_orbit_center += move * fly_speed * delta


# ── Mouse → ground plane → hovered cell + brush ghost ─────────────────
func _update_hover() -> void:
	_hover_valid = false
	if _camera == null:
		return
	var mp := get_viewport().get_mouse_position()
	var origin := _camera.project_ray_origin(mp)
	var ndir := _camera.project_ray_normal(mp)
	if absf(ndir.y) < 1e-5:
		_set_hover_visible(false)
		return
	var t := -origin.y / ndir.y
	if t < 0.0:
		_set_hover_visible(false)
		return
	var hit := origin + ndir * t
	var cx := int(floor(hit.x / cube_size))
	var cz := int(floor(hit.z / cube_size))
	if cx < 0 or cx >= _grid_w or cz < 0 or cz >= _grid_d:
		_set_hover_visible(false)
		return
	# (row, col) = (z, x) to match map_data + ModifierStack/GridOps cell convention.
	_hover_cell = Vector2i(cz, cx)
	_hover_valid = true
	_position_hover_visuals()


func _set_hover_visible(v: bool) -> void:
	if _hover_highlight: _hover_highlight.visible = v
	if _ghost: _ghost.visible = v


## Place the single-cell highlight and stamp the brush footprint into the ghost.
func _position_hover_visuals() -> void:
	if not _hover_valid:
		_set_hover_visible(false)
		return
	var col := _hover_cell.y   # x
	var row := _hover_cell.x   # z
	var top_y := 0.06 + _column_top_y(col, row)
	if _hover_highlight:
		_hover_highlight.visible = true
		_hover_highlight.position = Vector3((col + 0.5) * cube_size, top_y, (row + 0.5) * cube_size)

	if _ghost == null or _ghost.multimesh == null:
		return
	var mm := _ghost.multimesh
	var center := Vector2i(row, col)   # GridOps expects Vector2i(row, col)
	var cells := GridOpsLib.brush_cells(center, _active_brush_size)
	var ghost_col := _active_color if _active_mode == TOOL_PAINT else C_ACCENT
	# Hide all instances, then light up the footprint cells in-bounds.
	for i in range(mm.instance_count):
		mm.set_instance_color(i, Color(0, 0, 0, 0))
	var idx := 0
	for rc in cells:
		if idx >= mm.instance_count:
			break
		var rr := int(rc[0])   # row = z
		var cc := int(rc[1])   # col = x
		if rr < 0 or rr >= _grid_d or cc < 0 or cc >= _grid_w:
			idx += 1
			continue
		var gy := 0.05 + _column_top_y(cc, rr)
		mm.set_instance_transform(idx, Transform3D(Basis(), Vector3((cc + 0.5) * cube_size, gy, (rr + 0.5) * cube_size)))
		mm.set_instance_color(idx, Color(ghost_col.r, ghost_col.g, ghost_col.b, 0.4))
		idx += 1
	_ghost.visible = true


## World-space top of the column (so the ghost floats on the stack, not the floor).
func _column_top_y(x: int, z: int) -> float:
	if _structure and _structure.has_method("get_height_at"):
		return float(_structure.get_height_at(x, z)) * cube_size
	return 0.0


# ── Apply the active tool at the hovered cell ─────────────────────────
func _apply_at_hover() -> void:
	if not _editing_ready or not _hover_valid or _structure == null:
		return
	if _active_mode == TOOL_PAINT:
		_apply_paint()
	else:
		_apply_grid_op()
	_stroke_dirty = true
	_position_hover_visuals()   # refresh ghost height after the edit


## GRID structure op: read footprint heights → GridOps.stroke → write back.
func _apply_grid_op() -> void:
	var center := _hover_cell   # Vector2i(row, col)
	var cells := GridOpsLib.brush_cells(center, _active_brush_size)
	# Build the base height model for exactly the footprint cells (clamped in-bounds).
	var base: Dictionary = {}
	for rc in cells:
		var rr := int(rc[0])   # z
		var cc := int(rc[1])   # x
		if rr < 0 or rr >= _grid_d or cc < 0 or cc >= _grid_w:
			continue
		base[Vector2i(rr, cc)] = _structure.get_height_at(cc, rr)
	if base.is_empty():
		return
	# Stroke with level passed as fill/raise value; seed from undo depth for repeatable randomize.
	var params := {"value": _active_level, "amount": 1, "min": 0, "max": _grid_max_h}
	var op_seed := _undo_stack.size() * 131 + _hover_cell.x * 7 + _hover_cell.y
	var result: Dictionary = GridOpsLib.stroke(base, _active_grid_op, center, _active_brush_size, params, op_seed)
	# Write back every changed cell via the real structure (zero drift).
	for k in result.keys():
		var rr: int = k.x   # z
		var cc: int = k.y   # x
		_structure.set_height_at(cc, rr, clampi(int(result[k]), 0, _grid_max_h))


## PAINT op: ModifierStack over the footprint → set_cell_color per cell, and
## record an op in the modifier stack so W persists it.
func _apply_paint() -> void:
	if not _structure.has_method("set_cell_color"):
		return
	var center := _hover_cell
	var cells := GridOpsLib.brush_cells(center, _active_brush_size)
	# Build the base cell model (Vector2i(row, col) → {height, color}) for the footprint.
	var base: Dictionary = {}
	var cell_list: Array = []
	for rc in cells:
		var rr := int(rc[0])   # z
		var cc := int(rc[1])   # x
		if rr < 0 or rr >= _grid_d or cc < 0 or cc >= _grid_w:
			continue
		var k := Vector2i(rr, cc)
		base[k] = {"height": maxi(1, _structure.get_height_at(cc, rr)), "color": ModifierStackLib.DEFAULT_COLOR}
		cell_list.append([rr, cc])
	if base.is_empty():
		return
	# One modifier op over the footprint, mirroring becoming_catalyst's shape.
	var op := _build_paint_op(cell_list)
	var result: Dictionary = ModifierStackLib.apply(base, [op])
	for k in result.keys():
		var cell: Dictionary = result[k]
		var col: Color = cell.get("color", ModifierStackLib.DEFAULT_COLOR)
		_structure.set_cell_color(k, col)
	# Append to the persisted stack (so save writes it; undo can pop it).
	_modifier_stack.append(op)


func _build_paint_op(cell_list: Array) -> Dictionary:
	match _active_paint_op:
		"random_colors":
			return {
				"op": "random_colors",
				"target": {"cells": cell_list},
				"params": {"palette": "spectrum"},
				"seed": _modifier_stack.size(),
			}
		"normalize":
			return {
				"op": "normalize",
				"target": {"cells": cell_list},
				"params": {},
			}
		_:
			return {
				"op": "colorize",
				"target": {"cells": cell_list},
				"params": {"color": "#" + _active_color.to_html(false)},
			}


# ── Undo / redo (snapshot heights + colors before each stroke) ────────
func _snapshot() -> Dictionary:
	# Heights: dense map of every column. Colors: the current modifier stack
	# (the authoritative source for per-cell tint — replaying it reproduces colors).
	var heights: Dictionary = {}
	if _structure and _structure.has_method("get_height_at"):
		for z in range(_grid_d):
			for x in range(_grid_w):
				heights[Vector2i(z, x)] = _structure.get_height_at(x, z)
	return {"heights": heights, "modifiers": _modifier_stack.duplicate(true)}


func _push_undo() -> void:
	if not _editing_ready:
		return
	_undo_stack.append(_snapshot())
	if _undo_stack.size() > UNDO_CAP:
		_undo_stack.pop_front()
	_redo_stack.clear()


func _restore(snap: Dictionary) -> void:
	if _structure == null:
		return
	var heights: Dictionary = snap.get("heights", {})
	for k in heights.keys():
		var rr: int = k.x   # z
		var cc: int = k.y   # x
		if _structure.has_method("set_height_at"):
			_structure.set_height_at(cc, rr, int(heights[k]))
	# Restore colors by replaying the snapshot's modifier stack on the real grid.
	_modifier_stack = (snap.get("modifiers", []) as Array).duplicate(true)
	_replay_modifiers()
	_position_hover_visuals()
	_update_hud()


## Re-tint every cell touched by the current modifier stack (and reset others to
## the default), so undo/redo reproduce the exact colour state.
func _replay_modifiers() -> void:
	if _structure == null or not _structure.has_method("set_cell_color"):
		return
	# Reset all columns to the default tint first.
	var base: Dictionary = {}
	for z in range(_grid_d):
		for x in range(_grid_w):
			base[Vector2i(z, x)] = {"height": maxi(1, _structure.get_height_at(x, z)), "color": ModifierStackLib.DEFAULT_COLOR}
	var result: Dictionary = ModifierStackLib.apply(base, _modifier_stack)
	for k in result.keys():
		var cell: Dictionary = result[k]
		_structure.set_cell_color(k, cell.get("color", ModifierStackLib.DEFAULT_COLOR))


func _undo() -> void:
	if _undo_stack.is_empty():
		_status_msg = "nothing to undo"; _update_hud(); return
	_redo_stack.append(_snapshot())
	var prev: Dictionary = _undo_stack.pop_back()
	_status_msg = "↩ undo"
	_restore(prev)


func _redo() -> void:
	if _redo_stack.is_empty():
		_status_msg = "nothing to redo"; _update_hud(); return
	_undo_stack.append(_snapshot())
	var nxt: Dictionary = _redo_stack.pop_back()
	_status_msg = "↪ redo"
	_restore(nxt)


# ── Save (W) — structure layer + top-level modifiers, non-destructive ─
## Read-merge-write: load the map's map_data.json, replace only layers.structure
## (the edited heights) and the top-level modifiers (the paint), preserve every
## other key. Synthetic grids have no map file → toast and skip.
func _save() -> void:
	if _loaded_map == "":
		_status_msg = "no map — launch with --map=<Name> to save"
		_update_hud()
		return
	if _structure == null or not _structure.has_method("get_editable_layout"):
		_status_msg = "SAVE FAILED: no editable structure"
		_update_hud()
		return
	var layout: Array = _structure.get_editable_layout()
	if layout.is_empty():
		_status_msg = "SAVE FAILED: empty layout"
		_update_hud()
		return

	var path := "res://commons/maps/%s/map_data.json" % _loaded_map
	# Re-read from disk to merge against the freshest on-disk copy (preserve keys).
	var data: Dictionary = {}
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			data = parsed
	elif not _map_data.is_empty():
		data = _map_data.duplicate(true)
	else:
		_status_msg = "SAVE FAILED: map file not found"
		_update_hud()
		return

	# Replace only the structure layer.
	if not data.has("layers") or not (data["layers"] is Dictionary):
		data["layers"] = {}
	data["layers"]["structure"] = layout

	# Persist the paint as the top-level modifiers op-stack (additive). Omit when
	# empty so untouched maps stay diff-clean.
	if not _modifier_stack.is_empty():
		data["modifiers"] = _modifier_stack
	elif data.has("modifiers"):
		data.erase("modifiers")

	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_status_msg = "SAVE FAILED (read-only?): %s" % path
		_update_hud()
		push_warning("[grid-editor] could not write %s" % path)
		return
	f.store_string(JSON.stringify(data, "\t") + "\n")
	f.close()
	_map_data = data
	_status_msg = "✓ saved → repo  (%s · %d rows · %d mods)" % [_loaded_map, layout.size(), _modifier_stack.size()]
	_update_hud()
	print("[grid-editor] saved %s (%d rows, %d modifiers)" % [_loaded_map, layout.size(), _modifier_stack.size()])


# ── HUD refresh ─────────────────────────────────────────────────────────
func _update_hud() -> void:
	if _ctx_lbl == null:
		return
	var map_show := _loaded_map if _loaded_map != "" else "SYNTHETIC"
	_ctx_lbl.text = "%s    ·    %d×%d    ·    maxH %d" % [map_show, _grid_w, _grid_d, _grid_max_h]
	# Active tool line.
	if _active_mode == TOOL_PAINT:
		_tool_lbl.text = "PAINT · %s   ·   brush %dx%d   ·   #%s" % [
			_active_paint_op.to_upper(), _active_brush_size, _active_brush_size, _active_color.to_html(false)]
		_tool_lbl.add_theme_color_override("font_color", _active_color)
	else:
		_tool_lbl.text = "GRID · %s   ·   brush %dx%d   ·   level %d" % [
			_active_grid_op.to_upper(), _active_brush_size, _active_brush_size, _active_level]
		_tool_lbl.add_theme_color_override("font_color", C_TEXT)
	# Controls footer.
	var save_hint := "   ·   W save→repo" if _loaded_map != "" else ""
	_controls_lbl.text = "L-drag apply   ·   R-drag orbit   ·   wheel zoom   ·   WASD/QE fly   ·   Ctrl+Z undo   ·   Tab panel%s" % save_hint
	# Toast.
	_toast_lbl.text = _status_msg


# ── Headless capture ──────────────────────────────────────────────────
func _take_screenshot(path: String) -> void:
	if path == "":
		return
	var img := get_viewport().get_texture().get_image()
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	img.save_png(path)
	print("[grid-editor] shot saved: %s" % path)

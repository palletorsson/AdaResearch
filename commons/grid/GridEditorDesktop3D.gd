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
## clear) over the same footprint → set_cell_color per cell.
##
## ARTIFACTS tab → a selected artifact (the catalog's map-ready lookups, sorted).
## PREV/NEXT cycle the selection; LEFT-click PLACES it (writes the interactables
## layer cell + spawns it via GridInteractablesComponent); RIGHT-click clears the
## cell. The hovered-cell ghost shows the selected artifact name.
##
## BIOME tab → the SAME brush model AND the SAME renderer as BiomeScrubberDesktop3D.
## The right-panel element/size/pressure set the active element + radius + strength;
## LEFT-drag stamps a per-cell density field (the painted overlay is the cursor); on
## release the fields become paint_layers and BiomeAccrualManager.apply() rebuilds REAL
## foliage (trees/critters/flowers) onto a dedicated "EditorBiomeHost" — visible biome,
## not a flat tint. Stage = the loaded map's sequence stage (else 12 so foliage shows).
##
## SAVE (W) is non-destructive read-merge-write: it replaces layers.structure +
## top-level modifiers (GRID), layers.interactables (ARTIFACTS), and top-level
## paint_layers (BIOME), preserving every other key.
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
# ARTIFACTS tab — the placeable-artifact catalog (map-ready lookups).
const CatalogProvider = preload("res://commons/artifacts/catalog/ArtifactCatalogDataProvider.gd")
# BIOME tab — the same paint model the scrubber uses (one source of truth).
const BiomeElementsLib = preload("res://commons/biome_layers/biome_elements.gd")
const DistributionFieldLib = preload("res://commons/biome_layers/distribution_field.gd")

# Biome painting wraps a MARGIN RING around the grid: the paintable/foliage area
# spans grid cells [-M, _grid_w+M) × [-M, _grid_d+M), so you can paint (and foliage
# renders) all the way AROUND the grid, not just on its cells. GRID/ARTIFACTS/UTILITY
# editing stays clamped to the grid [0,_grid_w)×[0,_grid_d) — only BIOME uses the ring.
const BIOME_MARGIN := 12   # cells of paintable ground on every side of the grid

@export var cube_size: float = 1.0
@export var fly_speed: float = 6.0

# ── Map / grid state ──────────────────────────────────────────────────
var _map_arg: String = ""                 # --map=<Name>; "" = synthetic
var _target_map: String = ""              # the map _build_real_grid should build (set by CLI or _reload_map)
var _loaded_map: String = ""              # the map actually being edited (may be synthetic)
var _reloading: bool = false              # guard: a _reload_map teardown→rebuild is in flight
var _synthetic_dims: int = 16             # --dims=N synthetic square size
var _grid_w: int = 16
var _grid_d: int = 16
var _grid_max_h: int = 6
var _grid_system: Node3D = null           # the REAL GridSystem (zero drift)
var _structure: GridStructureComponent = null
var _editing_ready: bool = false
var _map_data: Dictionary = {}            # full parsed map_data.json (for write-back)

# ── Active tool state (set by the panel's signals) ────────────────────
const TOOL_GRID := "grid"
const TOOL_PAINT := "paint"
var _active_mode: String = TOOL_GRID      # which row drives a left-click
var _active_grid_op: String = "fill"      # GridOps op name — paint the selected LEVEL (not +1)
var _active_paint_op: String = "colorize" # ModifierStack op name
var _active_brush_size: int = 2           # 1..4 (GridOps.MAX_BRUSH)
var _active_level: int = 1                # height value for fill/raise/etc. (base = 1)
var _active_color: Color = Color(0.9, 0.6, 0.2)
var _active_tab: String = "GRID"

# ── Modifier (paint) op-stack — persisted top-level on save ───────────
var _modifier_stack: Array = []           # Array[Dictionary] colorize/random/normalize ops

# ── ARTIFACTS tab state ───────────────────────────────────────────────
var _artifact_list: Array = []            # sorted lookup_names (the CURRENT filtered view)
var _artifact_idx: int = -1               # index into _artifact_list; -1 = none/unavailable
# Full map-ready catalog: lookup_name -> map_sequences (Array[String]). Source for the
# sequence filter; _artifact_list is a filtered slice of its keys.
var _artifact_seqs_by_lookup: Dictionary = {}
var _artifact_sequences: Array = []       # sorted unique sequence names present (for the panel)
var _artifact_seq_filter: String = "ALL"  # active sequence filter ("ALL" = no filter)
# NAME filter — a HUD LineEdit narrowing _artifact_list by lookup-name substring (mirrors
# the MAP filter). Composes with the sequence filter: a lookup must match BOTH to appear.
var _artifact_filter: String = ""         # lower-cased substring narrowing the artifact list
var _artifact_filter_edit: LineEdit = null # the artifact name filter text field
# Live interactables layer, rows[z][col] = token string (" " = empty). Built from
# the loaded map's layer (or blank) and edited by placement; saved into map_data.
var _interactables: Array = []
var _interactables_comp: GridInteractablesComponent = null
# ARTIFACTS MOVE — a pick-then-place gesture. When _artifact_move_mode is on, the first
# LEFT-click on an occupied cell PICKS UP (remembers token + cell, despawns it); the next
# LEFT-click MOVES it to the target. Esc / right-click cancels.
var _artifact_move_mode: bool = false
var _artifact_move_picked: bool = false
var _artifact_move_token: String = ""
var _artifact_move_from: Vector2i = Vector2i(-1, -1)   # (row, col) = (z, x)

# ── UTILITY tab state (the utilities layer) ───────────────────────────
# Live utilities layer, rows[z][col] = code string (" " = empty). Loaded from the map's
# layers.utilities (or blank) and edited by the UTILITY tab; saved into map_data.
var _utilities: Array = []
var _utilities_comp: GridUtilitiesComponent = null
var _util_code: String = "s"          # active utility type code (set by the panel)
var _util_op: String = "ADD"          # active op: ADD / MOVE / ROTATE / REMOVE
# UTILITY MOVE — same pick-then-place gesture as artifact MOVE, on the utilities layer.
var _util_move_picked: bool = false
var _util_move_token: String = ""
var _util_move_from: Vector2i = Vector2i(-1, -1)
var _util_ghost: MeshInstance3D = null   # hover marker for the selected utility type

# ── BIOME tab state (mirrors the scrubber's brush model) ──────────────
var _biome_elements: Array = BiomeElementsLib.NAMES   # single source of truth
var _biome_idx: int = -1                  # active element index; -1 = none
var _brush_fields: Dictionary = {}        # element -> PackedFloat32Array (_biome_w*_biome_d, margin-offset)
var _brush_radius: int = 2
var _brush_strength: float = 0.6
var _biome_dirty: bool = false            # a biome stamp happened this stroke → rebuild on release
# REAL foliage: the SAME accrual path BiomeScrubberDesktop3D drives. The brush fields
# become paint_layers; BiomeAccrualManager renders trees/critters/flowers onto _biome_host
# (NOT the grid — so the painted overlay stays a cursor, the host carries visible biome).
var _accrual: Node = null                 # /root/BiomeAccrualManager autoload (may be absent)
var _biome_host: Node3D = null            # the host the accrual renders foliage onto
var _biome_stage: int = 12                # stage_order fed to the accrual (resolved per map)

# ── Hover + brush ghost ───────────────────────────────────────────────
var _hover_cell: Vector2i = Vector2i(-1, -1)   # (row, col) = (z, x)
var _hover_valid: bool = false
var _hover_highlight: MeshInstance3D = null    # single cell under the cursor
var _ghost: MultiMeshInstance3D = null         # brush footprint preview (GRID/PAINT)
var _artifact_ghost: MeshInstance3D = null     # selected-artifact marker (ARTIFACTS)
var _move_select_box: MeshInstance3D = null    # bright wireframe box marking the MOVE source / pick-this cell
var _biome_overlay: MultiMeshInstance3D = null # per-cell density field (BIOME)
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
var _left_is_orbit: bool = false          # the current LEFT-drag began off-grid → orbit, not edit

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
# Top-bar controls: an explicit SAVE button + a MAP dropdown (open any map in-editor).
var _save_btn: Button = null
var _map_dropdown: OptionButton = null
var _map_names: Array = []                # filtered map names backing the dropdown (index-aligned)
var _all_map_names: Array = []            # full scanned map set (cached; filtered into _map_names)
var _map_filter: String = ""              # lower-cased substring narrowing the dropdown
var _map_filter_edit: LineEdit = null     # the filter text field

# ── ARTIFACTS 3D preview (corner HUD card, embedded in this CanvasLayer — NOT the
#    shared wrist panel, to dodge nested-viewport issues in VR) ────────────────
var _preview_panel: PanelContainer = null  # top-right card hosting the 3D view
var _preview_viewport: SubViewport = null  # renders the selected artifact in 3D
var _preview_world_root: Node3D = null     # holds the spin pivot + cam + light
var _preview_pivot: Node3D = null          # rotates in place; the artifact mounts under it
var _preview_camera: Camera3D = null
var _preview_node: Node3D = null           # the currently-instanced artifact (freed on cycle)
var _preview_lookup: String = ""           # what's currently shown (skip redundant rebuilds)
var _preview_name_lbl: Label = null        # name caption under the 3D view
var _preview_spin: float = 0.0             # idle yaw so the preview reads as 3D
const PREVIEW_PX := 240.0                  # square viewport edge (px)

# ── Headless capture ──────────────────────────────────────────────────
var _shot_path: String = ""
var _capture_frames: int = 0
# --paintbiome=<element>: headless proof that biome painting renders. Auto-selects
# the element, stamps the brush at grid centre, updates the overlay + live rebuild.
var _paintbiome_arg: String = ""
var _testmove: bool = false               # --testmove: headless proof that moving an EXISTING artifact respawns
var _testpersist: bool = false            # --testpersist: headless proof that painted biome survives save→reload

# ── Palette (matches the scrubber's designed surface) ─────────────────
const C_BG     := Color(0.05, 0.06, 0.09, 0.86)
const C_BG_SOFT := Color(0.08, 0.10, 0.14, 0.78)
const C_ACCENT := Color(0.45, 0.75, 1.0)     # grid-blue brand
const C_TEXT   := Color(0.93, 0.96, 1.0)
const C_DIM    := Color(0.58, 0.63, 0.72)
const C_GOLD   := Color(1.0, 0.78, 0.35)
const C_BAD    := Color(1.0, 0.45, 0.42)
const PANEL_W  := 540.0   # match the TabbedEditorPanel's 540px content width (else it overflows off-screen)
const BAR_H    := 96.0


func _ready() -> void:
	_parse_cli()
	# The first build targets the CLI map (if any); _reload_map retargets it later.
	_target_map = _map_arg
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
		elif a.begins_with("--paintbiome="):
			_paintbiome_arg = a.split("=", true, 1)[1].strip_edges()
		elif a == "--testmove":
			_testmove = true
		elif a == "--testpersist":
			_testpersist = true


# ── Build the REAL GridSystem renderer (zero drift) ───────────────────
## With --map: load that map's real structure. Without: write a synthetic flat
## grid of --dims into a temp map dict and feed it the same way the game does, so
## the same renderer + editing path is exercised either way.
func _build_real_grid() -> void:
	if GridSystemScene == null:
		_fail("ERROR: grid_system.tscn failed to preload.")
		return

	# The map this build targets: _map_arg on the CLI path, or whatever _reload_map set.
	# "" = synthetic (flat --dims grid). _target_map is the single source the build reads.
	var target_map := _target_map

	# Free any previous grid (re-entrancy guard for live reload).
	var old := get_node_or_null("GridSystem")
	if old:
		old.queue_free()
		await get_tree().process_frame

	_grid_system = GridSystemScene.instantiate()
	_grid_system.name = "GridSystem"
	if target_map != "" and ("map_name" in _grid_system):
		_grid_system.map_name = target_map
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
	if target_map != "" and data_comp and data_comp.has_method("get_structure_data"):
		_structure.enable_editing(data_comp.get_structure_data())
		_loaded_map = target_map
		# Read the map's real dimensions for camera + ghost sizing.
		if data_comp.has_method("get_grid_dimensions"):
			var dims: Vector3i = data_comp.get_grid_dimensions()
			_grid_w = maxi(1, dims.x)
			_grid_d = maxi(1, dims.z)
			_grid_max_h = maxi(1, dims.y)
		# Building terrain (ADD = +1) needs vertical headroom: a flat map's grid_y is
		# often 1, and the structure clamps every set_height_at to grid_y AND only renders
		# stacks up to grid_y. Without this, ADD silently caps at the map's tiny grid_y.
		# Grow the structure's vertical capacity to GridOps.MAX_H so ADD can build up.
		_ensure_build_height()
		# Cache the full map_data.json for non-destructive write-back.
		_load_map_data(target_map)
	else:
		# Synthetic: build a flat editable layout directly on the structure.
		_synthesize_flat_grid()

	if "cube_size" in _structure:
		cube_size = _structure.cube_size

	# Cache the interactables component for artifact placement (may be absent in
	# synthetic mode — guarded everywhere it's used).
	if _grid_system.has_method("get_interactables_component"):
		_interactables_comp = _grid_system.get_interactables_component()
	if _interactables_comp == null:
		_interactables_comp = _grid_system.find_child("GridInteractablesComponent", true, false) as GridInteractablesComponent

	# Cache the utilities component for live utility placement. In synthetic mode the
	# component exists but is never initialize()'d (no map load) — its parent_node stays
	# null, so live spawn degrades gracefully and the UTILITY tab edits data only.
	if _grid_system.has_method("get_utilities_component"):
		_utilities_comp = _grid_system.get_utilities_component()
	if _utilities_comp == null:
		_utilities_comp = _grid_system.find_child("GridUtilitiesComponent", true, false) as GridUtilitiesComponent

	# ARTIFACTS: seed the placeable-artifact list + the live interactables layer.
	_load_artifact_catalog()
	_load_interactables_layer()
	# UTILITY: seed the live utilities layer (and spawn whatever the map already carries).
	_load_utilities_layer()

	# BIOME: size the per-element brush overlay to the (now known) grid.
	_resize_biome_overlay()
	# BIOME: wire the REAL accrual path (host + autoload + stage) — the brush fields
	# render as visible foliage exactly like BiomeScrubberDesktop3D, not as a flat field.
	_setup_biome_accrual()

	_editing_ready = true
	_recenter_for_grid()
	_update_hover_grid_sized()
	_sync_biome_size()
	# Restore a previously-painted biome so it PERSISTS across save→reload: re-seed the
	# brush fields from the map's saved paint_layers + rebuild the foliage. Without this,
	# the editor's biome host starts empty even though paint_layers were saved.
	_load_biome_paint_layers()
	if not _brush_fields.is_empty():
		_rebuild_biome()
	# Refresh the MAP dropdown to the post-build truth: drops the "SYNTHETIC" header once a
	# real map is up and re-selects whatever actually loaded (CLI map or _reload_map target).
	# clear()/add_item()/select() never emit item_selected, so this can't re-fire a reload.
	_populate_map_dropdown()
	_reloading = false
	_update_hud()
	print("[grid-editor] ready: map=%s  %dx%d  maxH=%d" % [
		(_loaded_map if _loaded_map != "" else "SYNTHETIC"), _grid_w, _grid_d, _grid_max_h])

	# Headless biome-paint proof — stamp a brush blob at the grid centre and run the
	# live rebuild, so a --map=<X> --paintbiome=<el> --shot=<p> run renders painted
	# biome without a mouse. Runs once the grid is ready, before the --shot countdown.
	if _paintbiome_arg != "":
		_headless_paint_biome(_paintbiome_arg)
	if _testmove:
		_headless_test_move()
	if _testpersist:
		_headless_test_persist()


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
	# Synthetic grids already generate at MAX_H, but normalise so ADD has headroom.
	_ensure_build_height()
	_loaded_map = ""


## Minimal stand-in for the GridDataComponent's structure_data object — just the
## `layout_data` member the structure component reads.
class _SynthStructureData extends RefCounted:
	var layout_data: Array = []


## Give the structure vertical headroom so the GRID "ADD" op can RAISE terrain.
##
## The structure component (GridStructureComponent) clamps every set_height_at write to
## its grid_y AND only renders stacks up to grid_y in _rebuild_from_layout. Loaded maps
## carry the map's own grid_y, which for flat maps is 1 — so ADD (+1) would be silently
## capped and look like a no-op. We grow grid_y to GridOps.MAX_H and reallocate the
## structure's backing `grid` array to match (mirroring _initialize_grid's x/y/z shape),
## then rebuild from the editable layout so existing cubes are preserved. _grid_max_h is
## bumped in lockstep so the editor's own write-back clamp matches.
func _ensure_build_height() -> void:
	if _structure == null:
		return
	var want_h: int = GridOpsLib.MAX_H
	_grid_max_h = maxi(_grid_max_h, want_h)
	if not ("grid_y" in _structure):
		return
	var cur_h: int = int(_structure.grid_y)
	if cur_h >= want_h:
		return
	# Resolve current x/z extents (prefer the structure's own dims).
	var gx: int = _grid_w
	var gz: int = _grid_d
	if "grid_x" in _structure:
		gx = maxi(1, int(_structure.grid_x))
	if "grid_z" in _structure:
		gz = maxi(1, int(_structure.grid_z))
	_structure.grid_y = want_h
	# Reallocate the bool backing array grid[x][y][z] at the taller height.
	if "grid" in _structure:
		var new_grid: Array = []
		new_grid.resize(gx)
		for x in range(gx):
			var y_arr: Array = []
			y_arr.resize(want_h)
			for y in range(want_h):
				var z_arr: Array = []
				z_arr.resize(gz)
				for z in range(gz):
					z_arr[z] = false
				y_arr[y] = z_arr
			new_grid[x] = y_arr
		_structure.grid = new_grid
	# Rebuild the rendered stacks from the editable layout into the taller grid.
	if _structure.has_method("_rebuild_from_layout"):
		_structure._rebuild_from_layout()


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

	# ── Artifact ghost — a single upright marker box at the hovered cell (shown
	#    only on the ARTIFACTS tab; the selected artifact's footprint preview). ──
	_artifact_ghost = MeshInstance3D.new()
	_artifact_ghost.name = "ArtifactGhost"
	var bm := BoxMesh.new()
	bm.size = Vector3(cube_size * 0.5, cube_size * 0.9, cube_size * 0.5)
	_artifact_ghost.mesh = bm
	var amat := StandardMaterial3D.new()
	amat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	amat.albedo_color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.45)
	amat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	amat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_artifact_ghost.material_override = amat
	_artifact_ghost.visible = false
	add_child(_artifact_ghost)

	# ── Utility ghost — a single upright marker (UTILITY tab) tinted the UTILITY tab's
	#    colour, for the selected utility type at the hovered cell. ──
	_util_ghost = MeshInstance3D.new()
	_util_ghost.name = "UtilityGhost"
	var um := BoxMesh.new()
	um.size = Vector3(cube_size * 0.4, cube_size * 0.7, cube_size * 0.4)
	_util_ghost.mesh = um
	var umat := StandardMaterial3D.new()
	umat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	umat.albedo_color = Color(0.85, 0.5, 0.95, 0.5)   # matches the panel's UTILITY tab colour
	umat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	umat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_util_ghost.material_override = umat
	_util_ghost.visible = false
	add_child(_util_ghost)

	# ── Biome brush overlay — a per-cell quad grid, alpha = the active element's
	#    painted density (shown only on the BIOME tab). Sized once the grid loads. ──
	_biome_overlay = MultiMeshInstance3D.new()
	_biome_overlay.name = "BiomeBrushOverlay"
	var bmm := MultiMesh.new()
	bmm.transform_format = MultiMesh.TRANSFORM_3D
	bmm.use_colors = true                  # MUST precede instance_count
	var bpl := PlaneMesh.new()
	bpl.size = Vector2(cube_size * 0.92, cube_size * 0.92)
	bmm.mesh = bpl
	bmm.instance_count = 0
	_biome_overlay.multimesh = bmm
	var bmat := StandardMaterial3D.new()
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.vertex_color_use_as_albedo = true
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_biome_overlay.material_override = bmat
	_biome_overlay.visible = false
	add_child(_biome_overlay)


# ── MOVE select box ──────────────────────────────────────────────────
## Lazily build the bright wireframe MOVE box: the 12 edges of a unit cube as a LINES
## ArrayMesh, with an unshaded emissive material so it glows regardless of scene light.
## Built once, sized to one cell, hidden until a MOVE is armed. Cheap (one MeshInstance3D).
func _ensure_move_select_box() -> void:
	if _move_select_box and is_instance_valid(_move_select_box):
		return
	_move_select_box = MeshInstance3D.new()
	_move_select_box.name = "MoveSelectBox"
	# Unit cube spanning [-0.5,0.5]³; positioned + scaled per cell at hover time.
	var h := 0.5
	var c := [
		Vector3(-h, -h, -h), Vector3(h, -h, -h), Vector3(h, -h, h), Vector3(-h, -h, h),  # bottom
		Vector3(-h, h, -h), Vector3(h, h, -h), Vector3(h, h, h), Vector3(-h, h, h),       # top
	]
	var edges := [
		0, 1, 1, 2, 2, 3, 3, 0,   # bottom ring
		4, 5, 5, 6, 6, 7, 7, 4,   # top ring
		0, 4, 1, 5, 2, 6, 3, 7,   # verticals
	]
	var verts := PackedVector3Array()
	for e in edges:
		verts.append(c[int(e)])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)
	_move_select_box.mesh = am
	var emat := StandardMaterial3D.new()
	emat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	emat.albedo_color = Color(0.4, 1.0, 0.55)            # bright green edge
	emat.emission_enabled = true
	emat.emission = Color(0.4, 1.0, 0.55)
	emat.emission_energy_multiplier = 2.0
	emat.cull_mode = BaseMaterial3D.CULL_DISABLED
	emat.disable_receive_shadows = true
	_move_select_box.material_override = emat
	_move_select_box.visible = false
	add_child(_move_select_box)


## Show/hide + position the MOVE select box, given a target (row, col) cell. Scales the unit
## cube to ~one cell and floats it on the column top. tint sets the edge/emission colour so
## the held-source ("pick this" / origin) and the drop-target read differently.
func _set_move_box(show_box: bool, row: int = -1, col: int = -1, tint: Color = Color(0.4, 1.0, 0.55)) -> void:
	if not show_box:
		if _move_select_box and is_instance_valid(_move_select_box):
			_move_select_box.visible = false
		return
	_ensure_move_select_box()
	if row < 0 or row >= _grid_d or col < 0 or col >= _grid_w:
		_move_select_box.visible = false
		return
	var bh := cube_size * 0.96
	_move_select_box.scale = Vector3(cube_size * 0.96, bh, cube_size * 0.96)
	var top_y := 0.06 + _column_top_y(col, row)
	_move_select_box.position = Vector3((col + 0.5) * cube_size, top_y + bh * 0.5, (row + 0.5) * cube_size)
	var emat := _move_select_box.material_override as StandardMaterial3D
	if emat:
		emat.albedo_color = tint
		emat.emission = tint
	_move_select_box.visible = true


## Resize hover quads to the (possibly map-derived) cube size.
func _update_hover_grid_sized() -> void:
	if _hover_highlight and _hover_highlight.mesh is PlaneMesh:
		(_hover_highlight.mesh as PlaneMesh).size = Vector2(cube_size * 0.96, cube_size * 0.96)
	if _ghost and _ghost.multimesh and _ghost.multimesh.mesh is PlaneMesh:
		(_ghost.multimesh.mesh as PlaneMesh).size = Vector2(cube_size * 0.86, cube_size * 0.86)
	if _artifact_ghost and _artifact_ghost.mesh is BoxMesh:
		(_artifact_ghost.mesh as BoxMesh).size = Vector3(cube_size * 0.5, cube_size * 0.9, cube_size * 0.5)
	if _util_ghost and _util_ghost.mesh is BoxMesh:
		(_util_ghost.mesh as BoxMesh).size = Vector3(cube_size * 0.4, cube_size * 0.7, cube_size * 0.4)
	if _biome_overlay and _biome_overlay.multimesh and _biome_overlay.multimesh.mesh is PlaneMesh:
		(_biome_overlay.multimesh.mesh as PlaneMesh).size = Vector2(cube_size * 0.92, cube_size * 0.92)


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

	# ── Top-bar controls: SAVE button + MAP dropdown ──────────────────
	# Real, clickable controls in the header (the bar Panel ignores the mouse, so these
	# siblings receive clicks). Anchored to the right edge, clear of the side panel.
	_build_top_bar_controls()

	# ── Right-side TabbedEditorPanel (one menu, both editors) ──────────
	# Pushed down to leave room for the 3D artifact-preview card above it (top-right).
	_panel_root = Control.new()
	_panel_root.name = "PanelRoot"
	_panel_root.anchor_left = 1.0; _panel_root.anchor_right = 1.0
	_panel_root.anchor_top = 0.0; _panel_root.anchor_bottom = 1.0
	_panel_root.offset_left = -(PANEL_W + 8.0)
	_panel_root.offset_top = BAR_H + 8.0 + PREVIEW_PX + 36.0
	_panel_root.offset_right = -8.0
	_panel_root.offset_bottom = -8.0
	_hud_layer.add_child(_panel_root)

	_panel = TabbedEditorPanelScene.instantiate()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_root.add_child(_panel)
	_connect_panel_signals()

	# ── ARTIFACTS 3D preview card (top-right corner of THIS CanvasLayer) ──
	# A SubViewport rendering the selected artifact's scene in 3D, sized ~260px.
	# Embedded here (not in the shared wrist panel) so VR avoids nested-viewport
	# pickups. Degrades gracefully — if it can't build, the panel's name label remains.
	_build_artifact_preview_card()


# ══════════════════════════════════════════════════════════════════════
# Top-bar controls — an explicit SAVE button + a MAP selector (open any map
# in-editor). Built as real Controls on the HUD CanvasLayer; the header bar
# Panel ignores the mouse so these siblings receive the clicks. Fully guarded:
# any failure here leaves the rest of the HUD (and the W-key save) intact.
# ══════════════════════════════════════════════════════════════════════

## Mount the SAVE button + MAP dropdown in the top bar, anchored to the right edge so
## they clear the left-aligned brand/tool labels and the side panel. Populates the map
## list (DirAccess scan) and pre-selects the loaded map.
func _build_top_bar_controls() -> void:
	if _hud_layer == null:
		return
	# Right edge of the controls cluster sits just left of the side panel's column.
	var right_off := -(PANEL_W + 24.0)

	# SAVE → repo button (flat, dark, accent text — matches the surface).
	_save_btn = Button.new()
	_save_btn.name = "SaveButton"
	_save_btn.text = "SAVE → repo"
	_save_btn.focus_mode = Control.FOCUS_NONE   # never steal keyboard focus from the editor
	_save_btn.add_theme_font_size_override("font_size", 14)
	_save_btn.add_theme_color_override("font_color", C_GOLD)
	_save_btn.add_theme_color_override("font_hover_color", C_TEXT)
	_save_btn.add_theme_color_override("font_pressed_color", C_TEXT)
	_save_btn.add_theme_stylebox_override("normal", _new_stylebox(C_BG_SOFT, 0.0, 6.0))
	_save_btn.add_theme_stylebox_override("hover", _new_stylebox(Color(0.14, 0.17, 0.22, 0.92), 0.0, 6.0))
	_save_btn.add_theme_stylebox_override("pressed", _new_stylebox(Color(0.10, 0.12, 0.16, 0.95), 0.0, 6.0))
	_save_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_save_btn.anchor_left = 1.0; _save_btn.anchor_right = 1.0
	_save_btn.anchor_top = 0.0; _save_btn.anchor_bottom = 0.0
	_save_btn.offset_top = 8.0
	_save_btn.offset_bottom = 32.0
	_save_btn.offset_right = right_off
	_save_btn.offset_left = right_off - 140.0
	_save_btn.pressed.connect(_on_save_pressed)
	_hud_layer.add_child(_save_btn)

	# MAP FILTER — narrows the dropdown as you type (case-insensitive substring on the name).
	# Focusable so it can take text; _update_fly + the focus check suppress WASD/shortcuts while typing.
	_map_filter_edit = LineEdit.new()
	_map_filter_edit.name = "MapFilter"
	_map_filter_edit.placeholder_text = "filter maps…"
	_map_filter_edit.focus_mode = Control.FOCUS_CLICK
	_map_filter_edit.clear_button_enabled = true
	_map_filter_edit.add_theme_font_size_override("font_size", 14)
	_map_filter_edit.add_theme_color_override("font_color", C_TEXT)
	_map_filter_edit.add_theme_color_override("font_placeholder_color", Color(0.55, 0.60, 0.70))
	_map_filter_edit.add_theme_stylebox_override("normal", _new_stylebox(C_BG_SOFT, 0.0, 6.0))
	_map_filter_edit.add_theme_stylebox_override("focus", _new_stylebox(Color(0.14, 0.17, 0.22, 0.95), 0.0, 6.0))
	_map_filter_edit.anchor_left = 1.0; _map_filter_edit.anchor_right = 1.0
	_map_filter_edit.anchor_top = 0.0; _map_filter_edit.anchor_bottom = 0.0
	_map_filter_edit.offset_top = 38.0
	_map_filter_edit.offset_bottom = 62.0
	_map_filter_edit.offset_right = right_off
	_map_filter_edit.offset_left = right_off - 260.0
	_map_filter_edit.text_changed.connect(_on_map_filter_changed)
	_hud_layer.add_child(_map_filter_edit)

	# MAP dropdown — every available map (DirAccess scan), pre-selecting the loaded one.
	_map_dropdown = OptionButton.new()
	_map_dropdown.name = "MapDropdown"
	_map_dropdown.focus_mode = Control.FOCUS_NONE
	_map_dropdown.add_theme_font_size_override("font_size", 14)
	_map_dropdown.add_theme_color_override("font_color", C_TEXT)
	_map_dropdown.add_theme_stylebox_override("normal", _new_stylebox(C_BG_SOFT, 0.0, 6.0))
	_map_dropdown.add_theme_stylebox_override("hover", _new_stylebox(Color(0.14, 0.17, 0.22, 0.92), 0.0, 6.0))
	_map_dropdown.add_theme_stylebox_override("pressed", _new_stylebox(Color(0.10, 0.12, 0.16, 0.95), 0.0, 6.0))
	_map_dropdown.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_map_dropdown.anchor_left = 1.0; _map_dropdown.anchor_right = 1.0
	_map_dropdown.anchor_top = 0.0; _map_dropdown.anchor_bottom = 0.0
	_map_dropdown.offset_top = 68.0
	_map_dropdown.offset_bottom = 92.0
	_map_dropdown.offset_right = right_off
	_map_dropdown.offset_left = right_off - 260.0
	_hud_layer.add_child(_map_dropdown)

	_populate_map_dropdown()
	# Connect AFTER populating so the initial pre-select doesn't fire a reload.
	_map_dropdown.item_selected.connect(_on_map_dropdown_selected)


## Scan res://commons/maps/ for subdirectories that contain map_data.json — the
## authoritative map set. Returns a sorted Array[String] of map names. Tolerant of a
## missing maps dir (returns empty); never crashes.
func _scan_map_names() -> Array:
	var out: Array = []
	var base := "res://commons/maps"
	var dir := DirAccess.open(base)
	if dir == null:
		push_warning("[grid-editor] map scan: cannot open %s" % base)
		return out
	for sub in dir.get_directories():
		var map_name := str(sub).strip_edges()
		if map_name == "" or map_name.begins_with("."):
			continue
		if FileAccess.file_exists("%s/%s/map_data.json" % [base, map_name]):
			out.append(map_name)
	out.sort()
	return out


## Fill the dropdown from the scanned map set + pre-select the loaded map. Rebuildable
## (clears first) so a later refresh stays consistent. Synthetic mode shows a disabled
## "SYNTHETIC" header item so the control still reads sensibly.
func _populate_map_dropdown() -> void:
	if _map_dropdown == null:
		return
	if _all_map_names.is_empty():
		_all_map_names = _scan_map_names()
	# Filter the full set by the current substring (empty filter = all maps).
	_map_names = []
	for m in _all_map_names:
		if _map_filter == "" or str(m).to_lower().contains(_map_filter):
			_map_names.append(m)
	_map_dropdown.clear()
	# When running synthetic (no loaded map), surface that as a non-selectable first item.
	var item_base := 0
	if _loaded_map == "":
		_map_dropdown.add_item("— SYNTHETIC —")
		_map_dropdown.set_item_disabled(0, true)
		item_base = 1
	for i in range(_map_names.size()):
		_map_dropdown.add_item(str(_map_names[i]))
		# Stash the map name as item metadata so selection is robust to index offsets.
		_map_dropdown.set_item_metadata(item_base + i, str(_map_names[i]))
	if _map_names.is_empty():
		var msg: String = "(no match)" if _map_filter != "" else "(no maps found)"
		_map_dropdown.add_item(msg)
		_map_dropdown.set_item_disabled(_map_dropdown.get_item_count() - 1, true)
	_sync_map_dropdown_selection()


## Point the dropdown's selected entry at the currently-loaded map (no signal — selection
## is set programmatically). No-op when the control is absent or the map isn't listed.
func _sync_map_dropdown_selection() -> void:
	if _map_dropdown == null:
		return
	if _loaded_map == "":
		# Synthetic: select the disabled "SYNTHETIC" header if present.
		if _map_dropdown.get_item_count() > 0:
			_map_dropdown.select(0)
		return
	for i in range(_map_dropdown.get_item_count()):
		if str(_map_dropdown.get_item_metadata(i)) == _loaded_map:
			_map_dropdown.select(i)
			return


## SAVE button → the SAME save path as the W key. The toast surfaces the result.
func _on_save_pressed() -> void:
	_save()


## MAP FILTER changed → narrow the dropdown to names containing the substring (re-selects
## the loaded map if it's still in the filtered list). Cached scan = no disk hit per keystroke.
func _on_map_filter_changed(text: String) -> void:
	_map_filter = text.strip_edges().to_lower()
	_populate_map_dropdown()


## MAP dropdown selection → reload the editor with that map. Resolves the chosen item's
## metadata (the map name), ignores re-selecting the loaded map, and routes to _reload_map.
func _on_map_dropdown_selected(index: int) -> void:
	if _map_dropdown == null:
		return
	if index < 0 or index >= _map_dropdown.get_item_count():
		return
	if _map_dropdown.is_item_disabled(index):
		_sync_map_dropdown_selection()   # snap back off the disabled header
		return
	var picked := str(_map_dropdown.get_item_metadata(index)).strip_edges()
	if picked == "":
		picked = str(_map_dropdown.get_item_text(index)).strip_edges()
	if picked == "" or picked == _loaded_map:
		return
	_reload_map(picked)


## Tear down the current grid + all grid-referencing editor state, then rebuild the SAME
## way the --map CLI path does (via _build_real_grid, retargeted through _target_map). Frees
## the GridSystem + its components, the biome host, every spawned ghost/preview that pointed
## at the old grid, and clears the layers/undo stacks — so switching maps never leaks an old
## grid or double-spawns. Guards a missing map (toast + keep current state) and re-entrancy.
func _reload_map(map_name: String) -> void:
	var want := str(map_name).strip_edges()
	if want == "":
		return
	if _reloading:
		return   # a reload is already in flight — ignore the spurious second selection
	# Validate the target exists before touching anything, so a bad pick keeps the prior map.
	if not FileAccess.file_exists("res://commons/maps/%s/map_data.json" % want):
		_status_msg = "map '%s' not found — keeping %s" % [want, (_loaded_map if _loaded_map != "" else "SYNTHETIC")]
		_sync_map_dropdown_selection()
		_update_hud()
		return

	_reloading = true
	# Freeze editing so no stray input mutates a half-torn-down grid during the await.
	_editing_ready = false

	# ── Tear down the old grid + everything that referenced it ──────────
	# Cancel any in-progress MOVE so a held token doesn't dangle into the new grid.
	_artifact_move_picked = false
	_artifact_move_mode = false
	_artifact_move_token = ""
	_artifact_move_from = Vector2i(-1, -1)
	_util_move_picked = false
	_util_move_token = ""
	_util_move_from = Vector2i(-1, -1)

	# Free the biome host (and its accrued foliage children) — _setup_biome_accrual rebuilds it.
	if _biome_host and is_instance_valid(_biome_host):
		for c in _biome_host.get_children():
			_biome_host.remove_child(c)
			c.free()
		_biome_host.queue_free()
	_biome_host = null
	_accrual = null

	# Free the real GridSystem; its component children (structure/interactables/utilities)
	# go with it, so just drop our cached refs (their spawned nodes were grid children).
	if _grid_system and is_instance_valid(_grid_system):
		_grid_system.queue_free()
	_grid_system = null
	_structure = null
	_interactables_comp = null
	_utilities_comp = null

	# Clear the live layers, painted fields, modifier + undo/redo stacks, and the cached map.
	_interactables = []
	_utilities = []
	_brush_fields = {}
	_biome_dirty = false
	_modifier_stack = []
	_undo_stack = []
	_redo_stack = []
	_stroke_dirty = false
	_map_data = {}
	_hover_valid = false
	_painting = false

	# Drop the ARTIFACTS 3D preview's spawned node (it lived in the preview viewport, not
	# the grid, but clear it so the next selection re-instances cleanly).
	_clear_preview_node()
	_preview_lookup = ""

	# Hide the hover visuals until the new grid is up.
	_set_hover_visible(false)
	if _biome_overlay:
		_biome_overlay.visible = false

	# Let the queue_free()s settle before rebuilding.
	await get_tree().process_frame

	# ── Rebuild via the SAME path as --map ──────────────────────────────
	_target_map = want
	_status_msg = "loading %s…" % want
	_update_hud()
	await _build_real_grid()
	# _build_real_grid clears _reloading on its success tail; force-clear here too so an
	# early-return failure path inside the build can't leave reloads permanently locked.
	_reloading = false
	# _build_real_grid already recenters the camera + syncs the dropdown on success.
	if _loaded_map == want:
		_status_msg = "loaded %s" % want
	else:
		# Build fell through to synthetic (e.g. data component missing) — report honestly.
		_status_msg = "load of '%s' incomplete — see log" % want
	_update_hud()


# ══════════════════════════════════════════════════════════════════════
# ARTIFACTS 3D preview — a corner card that instantiates the selected
# artifact's scene into a SubViewport, framed + idly spun, so the picker
# shows what it's about to place. (ArtifactPreview.gd is a 2D detail panel
# with no scene of its own, so wiring it directly would crash on its null
# @onready refs; this builds the equivalent 3D view inline instead.)
# ══════════════════════════════════════════════════════════════════════

## Build the top-right preview card: a PanelContainer wrapping a SubViewportContainer
## (the 3D render) over a name caption. Fully guarded — any failure leaves the rest of
## the HUD intact and the panel's own name/preview label still informs the selection.
func _build_artifact_preview_card() -> void:
	_preview_panel = PanelContainer.new()
	_preview_panel.name = "ArtifactPreviewCard"
	_preview_panel.anchor_left = 1.0; _preview_panel.anchor_right = 1.0
	_preview_panel.anchor_top = 0.0; _preview_panel.anchor_bottom = 0.0
	_preview_panel.offset_left = -(PANEL_W + 8.0)
	_preview_panel.offset_right = -8.0
	_preview_panel.offset_top = BAR_H + 8.0
	_preview_panel.offset_bottom = BAR_H + 8.0 + PREVIEW_PX + 32.0
	_preview_panel.add_theme_stylebox_override("panel", _new_stylebox(C_BG, 0.0, 8.0))
	_preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_panel.visible = false   # shown only on the ARTIFACTS tab
	_hud_layer.add_child(_preview_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_panel.add_child(vb)

	# The 3D view: a SubViewportContainer hosting our own SubViewport + world.
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(PREVIEW_PX, PREVIEW_PX)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(svc)

	_preview_viewport = SubViewport.new()
	_preview_viewport.size = Vector2i(int(PREVIEW_PX), int(PREVIEW_PX))
	_preview_viewport.transparent_bg = true
	_preview_viewport.own_world_3d = true   # isolate from the editor scene's world
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(_preview_viewport)

	# World root: spin pivot (artifact mount) + framing camera + a soft light.
	_preview_world_root = Node3D.new()
	_preview_world_root.name = "PreviewWorld"
	_preview_viewport.add_child(_preview_world_root)

	# Pivot at world origin: the artifact is centred under it (AABB centre → origin),
	# so rotating the pivot spins the artifact in place rather than orbiting it.
	_preview_pivot = Node3D.new()
	_preview_pivot.name = "PreviewPivot"
	_preview_world_root.add_child(_preview_pivot)

	_preview_camera = Camera3D.new()
	_preview_camera.fov = 45.0
	_preview_camera.current = true
	_preview_world_root.add_child(_preview_camera)

	var plight := DirectionalLight3D.new()
	plight.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
	plight.light_energy = 1.2
	_preview_world_root.add_child(plight)

	# Caption under the 3D view.
	_preview_name_lbl = _mk_label(vb, "", 13, C_TEXT)
	_preview_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# ── ARTIFACT NAME filter — a flat dark LineEdit just below the preview card, mirroring
	# the MAP filter (cached substring, case-insensitive). Anchored top-right of the HUD so it
	# sits directly under the card; shown only on the ARTIFACTS tab (toggled in _on_tab_changed
	# alongside the card). Focusable so it can take text; _update_fly + the focus check suppress
	# WASD/shortcuts while typing (a focused LineEdit consumes its keys, pre-empting _unhandled_input).
	_artifact_filter_edit = LineEdit.new()
	_artifact_filter_edit.name = "ArtifactFilter"
	_artifact_filter_edit.placeholder_text = "filter artifacts…"
	_artifact_filter_edit.focus_mode = Control.FOCUS_CLICK
	_artifact_filter_edit.clear_button_enabled = true
	_artifact_filter_edit.add_theme_font_size_override("font_size", 14)
	_artifact_filter_edit.add_theme_color_override("font_color", C_TEXT)
	_artifact_filter_edit.add_theme_color_override("font_placeholder_color", Color(0.55, 0.60, 0.70))
	_artifact_filter_edit.add_theme_stylebox_override("normal", _new_stylebox(C_BG_SOFT, 0.0, 6.0))
	_artifact_filter_edit.add_theme_stylebox_override("focus", _new_stylebox(Color(0.14, 0.17, 0.22, 0.95), 0.0, 6.0))
	_artifact_filter_edit.anchor_left = 1.0; _artifact_filter_edit.anchor_right = 1.0
	_artifact_filter_edit.anchor_top = 0.0; _artifact_filter_edit.anchor_bottom = 0.0
	_artifact_filter_edit.offset_left = -(PANEL_W + 8.0)
	_artifact_filter_edit.offset_right = -8.0
	_artifact_filter_edit.offset_top = BAR_H + 8.0 + PREVIEW_PX + 36.0
	_artifact_filter_edit.offset_bottom = BAR_H + 8.0 + PREVIEW_PX + 64.0
	_artifact_filter_edit.text_changed.connect(_on_artifact_filter_changed)
	_artifact_filter_edit.visible = false   # shown only on the ARTIFACTS tab
	_hud_layer.add_child(_artifact_filter_edit)


## Refresh the 3D preview to the current selection. Called on PREV/NEXT and sequence
## filter changes. No-op when the card failed to build; re-instantiates the artifact
## scene into the SubViewport and frames it. Same selection → skip (avoids re-spawn).
func _update_artifact_3d_preview() -> void:
	if _preview_panel == null:
		return
	var on_artifacts := _active_tab == "ARTIFACTS"
	_preview_panel.visible = on_artifacts
	# The artifact NAME filter field rides with the preview card (ARTIFACTS tab only).
	if _artifact_filter_edit:
		_artifact_filter_edit.visible = on_artifacts
	if not on_artifacts:
		return
	var lookup := _selected_artifact()
	if lookup == _preview_lookup and _preview_node != null:
		return   # already showing this one
	_preview_lookup = lookup
	_clear_preview_node()
	if _preview_name_lbl:
		if lookup != "":
			_preview_name_lbl.text = lookup
		elif _artifact_filter != "":
			_preview_name_lbl.text = "(no match)"
		else:
			_preview_name_lbl.text = "no artifact selected"
	if lookup == "" or _preview_viewport == null:
		return
	var node := _instantiate_preview(lookup)
	if node == null:
		return
	_preview_spin = 0.0
	if _preview_pivot:
		_preview_pivot.rotation = Vector3.ZERO
		_preview_pivot.add_child(node)
	else:
		_preview_world_root.add_child(node)
	_preview_node = node
	# Frame now (cheap default if geometry isn't built yet) AND again next frame, after
	# procedural artifacts populate their meshes in _ready() — so the AABB is real.
	_frame_preview(node)
	call_deferred("_reframe_preview", node)


## Deferred re-frame: procedural artifacts build meshes in _ready() (one frame after
## add_child), so the first _frame_preview can see an empty AABB. Re-run once the node
## is still the active preview, giving a correctly-fit shot.
func _reframe_preview(node: Node3D) -> void:
	if node == null or not is_instance_valid(node) or node != _preview_node:
		return
	_frame_preview(node)


## Free the currently-shown preview artifact (if any), so cycling never stacks nodes.
func _clear_preview_node() -> void:
	if _preview_node and is_instance_valid(_preview_node):
		_preview_node.queue_free()
	_preview_node = null


## Resolve a lookup → scene → Node3D instance, with the catalog's placeholder fallback
## (mirrors ArtifactCatalogDesktop3D). Returns null if nothing instantiable (degrades to
## the name caption only). Never crashes the editor.
func _instantiate_preview(lookup: String) -> Node3D:
	if CatalogProvider == null:
		return null
	var info: Dictionary = CatalogProvider.get_artifact_by_lookup_name(lookup)
	var scene_path := ""
	if info is Dictionary:
		scene_path = str(info.get("scene", "")).strip_edges()
	# The catalog's placeholder scene (a const on the provider) — the fallback when an
	# artifact has no scene / a bad path. Kept in a local so the resolution below is flat.
	var placeholder := str(CatalogProvider.PLACEHOLDER_ARTIFACT_SCENE_PATH)
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		scene_path = placeholder
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return null
	var scene = ResourceLoader.load(scene_path)
	if scene == null and placeholder != "" and ResourceLoader.exists(placeholder):
		scene = ResourceLoader.load(placeholder)
	if scene == null or not (scene is PackedScene):
		return null
	var inst = scene.instantiate()
	if inst == null:
		return null
	if not (inst is Node3D):
		# Non-3D root can't be framed in a 3D viewport → drop it, try the placeholder.
		inst.queue_free()
		if placeholder == "" or not ResourceLoader.exists(placeholder):
			return null
		var ph = ResourceLoader.load(placeholder)
		if ph == null or not (ph is PackedScene):
			return null
		inst = ph.instantiate()
		if inst == null or not (inst is Node3D):
			if inst:
				inst.queue_free()
			return null
	return inst as Node3D


## Centre + distance the preview camera from the artifact's AABB so it fills the frame.
## Uses the visual AABB when available; falls back to a fixed pull-back for empty bounds.
func _frame_preview(node: Node3D) -> void:
	if _preview_camera == null or node == null:
		return
	var aabb := _node_visual_aabb(node)
	if aabb.size.length() < 0.001:
		# No measurable geometry yet (procedural _ready may populate later) — safe default.
		node.position = Vector3(0.0, 0.0, 0.0)
		_preview_camera.position = Vector3(2.0, 1.6, 3.4)
		_preview_camera.look_at(Vector3(0.0, 0.6, 0.0), Vector3.UP)
		return
	var center := aabb.get_center()
	# Sit the artifact's base near the origin so the camera frames it consistently.
	node.position = -center
	node.position.y += -aabb.position.y
	var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var dist: float = maxf(1.5, max_dim * 1.9)
	var focus := Vector3(0.0, aabb.size.y * 0.5, 0.0)
	_preview_camera.position = focus + Vector3(dist * 0.7, dist * 0.55, dist * 0.9)
	_preview_camera.look_at(focus, Vector3.UP)


## Recursive visual AABB across the node's MeshInstance3D children (global → local of
## the node). Avoids a hard PerfectShotFramer dependency; tolerant of empty subtrees.
func _node_visual_aabb(node: Node3D) -> AABB:
	var out := AABB()
	var has := false
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi := n as MeshInstance3D
			var local := mi.get_aabb()
			# Transform the mesh AABB into `node`'s local space.
			var xf := node.global_transform.affine_inverse() * mi.global_transform
			var world_aabb := xf * local
			if not has:
				out = world_aabb
				has = true
			else:
				out = out.merge(world_aabb)
		for c in n.get_children():
			if c is Node3D:
				stack.append(c)
	return out


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
	if _panel.has_signal("artifact_sequence_changed"):
		_panel.artifact_sequence_changed.connect(_on_artifact_sequence_changed)
	# UTILITY tab — the utilities layer (guarded so an older panel without these
	# signals still loads the rest of the editor).
	if _panel.has_signal("utility_type_changed"):
		_panel.utility_type_changed.connect(_on_utility_type_changed)
	if _panel.has_signal("utility_op_selected"):
		_panel.utility_op_selected.connect(_on_utility_op_selected)


# ── Panel signal handlers ──────────────────────────────────────────────
func _on_tab_changed(tab_id: String) -> void:
	_active_tab = tab_id
	# Each tab edits its own layer; the GRID mode toggle (grid vs paint) only
	# matters on the GRID tab. The other tabs read their own active selection.
	if tab_id == "GRID":
		_active_mode = TOOL_GRID
	# BIOME: auto-select the first element the moment the tab opens, so painting
	# works immediately (no silent "pick a biome element first" dead-click). The
	# panel's element grid can still change it afterwards.
	if tab_id == "BIOME":
		_ensure_biome_element()
	# Leaving ARTIFACTS mid-MOVE shouldn't strand a picked-up artifact.
	if tab_id != "ARTIFACTS":
		_cancel_artifact_move()
	# Leaving UTILITY mid-MOVE shouldn't strand a picked-up utility.
	if tab_id != "UTILITY":
		_cancel_utility_move()
	# Show the right overlays per tab; the per-frame hover refresh handles the rest.
	if _biome_overlay:
		_biome_overlay.visible = (tab_id == "BIOME")
	if _active_tab == "BIOME":
		_update_biome_overlay()
	# The 3D artifact-preview card lives on the ARTIFACTS tab only.
	_update_artifact_3d_preview()
	_position_hover_visuals()
	_update_hud()


## Default the active biome element to the first one (BiomeElements.NAMES[0]) when
## none is selected, so the BIOME tab paints from the first click without needing a
## prior element tap. No-op once any element is chosen.
func _ensure_biome_element() -> void:
	if _biome_idx >= 0 and _biome_idx < _biome_elements.size():
		return
	if _biome_elements.is_empty():
		return
	_biome_idx = 0
	_status_msg = "biome element: %s" % str(_biome_elements[0]).to_upper()


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
	# BIOME tab: set the active brush element (mirrors the scrubber's element grid).
	var idx := _biome_elements.find(element_name)
	if idx < 0:
		_status_msg = "unknown biome element '%s'" % element_name
		_update_hud()
		return
	_biome_idx = idx
	_active_tab = "BIOME"
	if _biome_overlay:
		_biome_overlay.visible = true
	_update_biome_overlay()
	_status_msg = "biome element: %s" % element_name.to_upper()
	_update_hud()


func _on_biome_size_changed(radius: int) -> void:
	# Maps to the brush radius (the scrubber uses the same panel slider 1..6/8).
	_brush_radius = clampi(radius, 0, 8)
	_update_hud()


func _on_biome_pressure_changed(strength: float) -> void:
	_brush_strength = clampf(strength, 0.1, 1.0)
	_update_hud()


func _on_artifact_action(action: String) -> void:
	# ARTIFACTS tab: PREV/NEXT cycle the selected artifact; PLACE stamps it at the
	# hovered cell. The panel emits "◀ PREV" / "NEXT ▶" / "PLACE"; match loosely so
	# a panel-label tweak (or a future "REMOVE") still routes correctly.
	_active_tab = "ARTIFACTS"
	var up := action.to_upper()
	if _artifact_list.is_empty():
		if _artifact_filter != "":
			_status_msg = "no artifact matches filter '%s'" % _artifact_filter
		else:
			_status_msg = "no map-ready artifacts in the catalog"
		_update_hud()
		return
	if up.contains("PREV"):
		_cycle_artifact(-1)
	elif up.contains("NEXT"):
		_cycle_artifact(1)
	elif up.contains("MOVE"):
		_toggle_artifact_move()
	elif up.contains("REMOVE") or up.contains("CLEAR"):
		_clear_artifact_at_hover()
	elif up.contains("PLACE"):
		# PLACE leaves MOVE mode (so the next click drops the palette artifact).
		_artifact_move_mode = false
		_cancel_artifact_move()
		_place_artifact_at_hover()
	else:
		_status_msg = "artifacts: '%s'" % action
		_update_hud()


## ARTIFACTS sequence filter changed (panel ◀/▶): re-filter the placeable list to the
## artifacts in that sequence ("ALL" = no filter), reset the index, refresh the preview.
func _on_artifact_sequence_changed(seq: String) -> void:
	_active_tab = "ARTIFACTS"
	_apply_artifact_filter(seq)
	_update_artifact_preview()
	_update_artifact_3d_preview()   # filter changed the selection → re-render the 3D card
	if _artifact_list.is_empty():
		_status_msg = "sequence '%s' — no map-ready artifacts" % _artifact_seq_filter
	else:
		_status_msg = "sequence '%s' — %d artifact%s   ·   %s" % [
			_artifact_seq_filter, _artifact_list.size(),
			"" if _artifact_list.size() == 1 else "s", _selected_artifact()]
	_update_hud()


## UTILITY tab: the panel selected a utility TYPE (code). Cancel any pending utility
## move (the held token belongs to the previous type) and surface the new selection.
func _on_utility_type_changed(code: String) -> void:
	_active_tab = "UTILITY"
	_cancel_utility_move()
	_util_code = str(code).strip_edges()
	_status_msg = "utility: %s  (%s)" % [_util_friendly_name(_util_code), _util_code]
	_update_hud()


## UTILITY tab: the panel selected an OP (ADD / MOVE / ROTATE / REMOVE). Switching away
## from MOVE cancels any pickup so it never strands.
func _on_utility_op_selected(op: String) -> void:
	_active_tab = "UTILITY"
	var up := op.strip_edges().to_upper()
	if up != "MOVE":
		_cancel_utility_move()
	_util_op = up
	_status_msg = "utility op: %s" % up
	_update_hud()


# ── Input ──────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				# Cancel an in-progress MOVE pickup (artifact or utility) without dropping it.
				_cancel_artifact_move()
				_cancel_utility_move()
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
			if event.pressed:
				# Click OUTSIDE the edit area (off the grid / biome ring) → rotate the map
				# (orbit). Click ON it → edit. So a left-drag on empty space spins the view,
				# while a left-drag on the grid still paints/places.
				_update_hover()
				if not _hover_valid:
					_orbiting = true
					_left_is_orbit = true
					_set_hover_visible(false)
				else:
					_left_is_orbit = false
					_on_left_button(true)
			else:
				if _left_is_orbit:
					_orbiting = false
					_left_is_orbit = false
				else:
					_on_left_button(false)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# On ARTIFACTS/UTILITY, RIGHT-click clears the hovered cell (instead of
			# orbiting) — a one-click remove. If a MOVE pickup is in progress it cancels
			# that instead. Press only; drag still orbits on the other tabs.
			if event.pressed and _active_tab == "ARTIFACTS":
				if _artifact_move_picked:
					_cancel_artifact_move()
				else:
					_clear_artifact_at_hover()
			elif event.pressed and _active_tab == "UTILITY":
				if _util_move_picked:
					_cancel_utility_move()
				else:
					_clear_utility_at_hover()
			else:
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
			# Continuous apply while dragging: GRID/PAINT strokes structure/paint;
			# BIOME stamps the brush field. ARTIFACTS / UTILITY are click-only (no
			# drag-paint) — _painting is never set on those tabs, but exclude explicitly.
			if _painting:
				if _active_tab == "BIOME":
					_stamp_biome_at_hover()
				elif _active_tab != "ARTIFACTS" and _active_tab != "UTILITY":
					_apply_at_hover()


## LEFT-button press/release, routed by the active tab. GRID/PAINT keep the
## original stroke+undo flow; BIOME runs a biome-brush stroke (rebuild on release);
## ARTIFACTS places the selected artifact at the hovered cell on press.
func _on_left_button(pressed: bool) -> void:
	if _active_tab == "ARTIFACTS":
		if pressed:
			if _artifact_move_mode:
				_artifact_move_click()
			else:
				_place_artifact_at_hover()
		return
	if _active_tab == "UTILITY":
		if pressed:
			_utility_left_click()
		return
	if _active_tab == "BIOME":
		_painting = pressed
		if pressed:
			_biome_dirty = false
			_stamp_biome_at_hover()
		elif _biome_dirty:
			_biome_dirty = false
			_repaint_biome_live()   # full live rebuild on stroke-release
		return
	# GRID / PAINT — original behaviour, unchanged.
	_painting = pressed
	if pressed:
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


# ── Per-frame: camera orbit + fly + capture countdown ─────────────────
func _process(delta: float) -> void:
	if _camera:
		_update_fly(delta)
		var x := _orbit_center.x + _orbit_radius * cos(_orbit_pitch) * sin(_orbit_yaw)
		var y := _orbit_center.y - _orbit_radius * sin(_orbit_pitch)
		var z := _orbit_center.z + _orbit_radius * cos(_orbit_pitch) * cos(_orbit_yaw)
		_camera.position = Vector3(x, y, z)
		_camera.look_at(_orbit_center, Vector3.UP)

	# Idle-spin the ARTIFACTS preview so it reads as a 3D object, not a flat icon.
	if _preview_pivot and _preview_node and is_instance_valid(_preview_node) and _preview_panel and _preview_panel.visible:
		_preview_spin += delta * 0.7
		_preview_pivot.rotation.y = _preview_spin

	if _capture_frames > 0:
		_capture_frames -= 1
		if _capture_frames == 0:
			_take_screenshot(_shot_path)
			get_tree().quit()


## Optional WASD/Q-E fly: pan the orbit center in the camera's ground plane.
func _update_fly(delta: float) -> void:
	if _orbiting or _camera == null:
		return
	if _map_filter_edit and _map_filter_edit.has_focus():
		return   # typing in the map filter — W/A/S/D are text, not camera fly
	if _artifact_filter_edit and _artifact_filter_edit.has_focus():
		return   # typing in the artifact filter — W/A/S/D are text, not camera fly
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
	if _active_tab == "BIOME":
		# BIOME paints the whole biome AREA (grid + margin ring), so accept any cell in
		# [-M, _grid_w+M) × [-M, _grid_d+M) — cx/cz may be NEGATIVE. Reject only outside
		# the ring. The grid clamp below is for the grid-editing tabs alone.
		if cx < -BIOME_MARGIN or cx >= _grid_w + BIOME_MARGIN or cz < -BIOME_MARGIN or cz >= _grid_d + BIOME_MARGIN:
			_set_hover_visible(false)
			return
	elif cx < 0 or cx >= _grid_w or cz < 0 or cz >= _grid_d:
		# GRID / ARTIFACTS / UTILITY edit grid cells only → clamp to the grid (unchanged).
		_set_hover_visible(false)
		return
	# (row, col) = (z, x) to match map_data + ModifierStack/GridOps cell convention.
	_hover_cell = Vector2i(cz, cx)
	_hover_valid = true
	_position_hover_visuals()


## Hide the hovered-cell visuals. The persistent biome overlay is independent (its
## visibility is tab-driven), so it's not touched here.
func _set_hover_visible(v: bool) -> void:
	if _hover_highlight: _hover_highlight.visible = v and _active_tab != "ARTIFACTS"
	if _ghost: _ghost.visible = v and (_active_tab == "GRID")
	if _artifact_ghost: _artifact_ghost.visible = v and (_active_tab == "ARTIFACTS")
	if _util_ghost: _util_ghost.visible = v and (_active_tab == "UTILITY")
	# MOVE select box: while HOLDING it anchors to the source cell (independent of the
	# cursor, so it stays put when the hover goes invalid); otherwise it only follows a
	# valid hover, so hide it here when hover is lost or we leave ARTIFACTS.
	if _active_tab == "ARTIFACTS" and _artifact_move_picked:
		_set_move_box(true, _artifact_move_from.x, _artifact_move_from.y, Color(0.4, 1.0, 0.55))
	elif not v or _active_tab != "ARTIFACTS":
		_set_move_box(false)


## Place the single-cell highlight and the per-tab ghost at the hovered cell.
##   GRID      → footprint MultiMesh ghost (structure/paint brush)
##   ARTIFACTS → upright marker box for the selected artifact
##   BIOME     → single-cell highlight (the density field overlay carries the rest)
func _position_hover_visuals() -> void:
	if not _hover_valid:
		_set_hover_visible(false)
		return
	var col := _hover_cell.y   # x
	var row := _hover_cell.x   # z
	var top_y := 0.06 + _column_top_y(col, row)

	# Single-cell highlight (hidden on ARTIFACTS, where the marker box stands in).
	if _hover_highlight:
		_hover_highlight.visible = _active_tab != "ARTIFACTS"
		_hover_highlight.position = Vector3((col + 0.5) * cube_size, top_y, (row + 0.5) * cube_size)

	# Artifact marker ghost.
	if _artifact_ghost:
		_artifact_ghost.visible = (_active_tab == "ARTIFACTS")
		if _active_tab == "ARTIFACTS":
			var bh := cube_size * 0.9
			if _artifact_ghost.mesh is BoxMesh:
				bh = (_artifact_ghost.mesh as BoxMesh).size.y
			_artifact_ghost.position = Vector3((col + 0.5) * cube_size, top_y + bh * 0.5, (row + 0.5) * cube_size)
			# While HOLDING a moved artifact, tint the hovered ghost as the DROP TARGET (warm
			# gold) so it reads as "lands here"; otherwise the normal blue selection tint.
			var amat := _artifact_ghost.material_override as StandardMaterial3D
			if amat:
				if _artifact_move_picked:
					amat.albedo_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
				else:
					amat.albedo_color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.45)

	# MOVE select box — the visual anchor of a MOVE gesture (ARTIFACTS tab only):
	#   HOLDING        → mark the SOURCE cell (origin of the held artifact) in green.
	#   ARMED, EMPTY   → follow the hovered cell as a "pick this" cue, but only when that
	#                    cell is occupied (nothing to pick on an empty cell).
	#   otherwise      → hidden.
	if _active_tab == "ARTIFACTS" and _artifact_move_picked:
		_set_move_box(true, _artifact_move_from.x, _artifact_move_from.y, Color(0.4, 1.0, 0.55))
	elif _active_tab == "ARTIFACTS" and _artifact_move_mode and _artifact_occupied_at(row, col):
		_set_move_box(true, row, col, Color(0.4, 1.0, 0.55))
	else:
		_set_move_box(false)

	# Utility marker ghost.
	if _util_ghost:
		_util_ghost.visible = (_active_tab == "UTILITY")
		if _active_tab == "UTILITY":
			var uh := cube_size * 0.7
			if _util_ghost.mesh is BoxMesh:
				uh = (_util_ghost.mesh as BoxMesh).size.y
			_util_ghost.position = Vector3((col + 0.5) * cube_size, top_y + uh * 0.5, (row + 0.5) * cube_size)

	# Footprint ghost — GRID/PAINT only.
	if _ghost == null or _ghost.multimesh == null:
		return
	if _active_tab != "GRID":
		_ghost.visible = false
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


# ══════════════════════════════════════════════════════════════════════
# ARTIFACTS tab — place artifacts into the interactables layer + spawn them
# ══════════════════════════════════════════════════════════════════════

## Build the sorted list of placeable lookups: the catalog's map-ready artifacts
## (map_ready OR include_in_map_data true). Degrades to an empty list (toast) if the
## provider is missing — no crash in synthetic mode.
func _load_artifact_catalog() -> void:
	_artifact_list.clear()
	_artifact_idx = -1
	_artifact_seqs_by_lookup.clear()
	_artifact_sequences.clear()
	_artifact_seq_filter = "ALL"
	if CatalogProvider == null:
		return
	var all: Array = CatalogProvider.get_all_artifacts()  # static
	var seq_set: Dictionary = {}
	for a in all:
		if not (a is Dictionary):
			continue
		# Skip placeholders — they have no real scene to spawn.
		if str(a.get("artifact_type", "")) == "placeholder":
			continue
		if not (bool(a.get("map_ready", false)) or bool(a.get("include_in_map_data", false))):
			continue
		var lk := str(a.get("lookup_name", "")).strip_edges()
		if lk == "" or _artifact_seqs_by_lookup.has(lk):
			continue
		# Capture map_sequences for the per-sequence filter (mirrors the web /editor).
		var seqs: Array = []
		var raw_seqs = a.get("map_sequences", [])
		if raw_seqs is Array:
			for s in raw_seqs:
				var sn := str(s).strip_edges()
				if sn != "":
					seqs.append(sn)
					seq_set[sn] = true
		_artifact_seqs_by_lookup[lk] = seqs
	_artifact_sequences = seq_set.keys()
	_artifact_sequences.sort()
	# Build the initial (unfiltered) list.
	_apply_artifact_filter("ALL")
	# Hand the panel the sequence list it can cycle through, then prime the preview.
	if _panel and _panel.has_method("set_artifact_sequences"):
		_panel.set_artifact_sequences(_artifact_sequences)
	_update_artifact_preview()
	print("[grid-editor] artifact catalog: %d map-ready lookups, %d sequences" % [
		_artifact_list.size(), _artifact_sequences.size()])


## Set the active sequence filter, then rebuild the composed list. Kept for the
## sequence-change call site ("ALL" = no sequence narrowing); the actual list build is in
## _rebuild_artifact_list so name + sequence predicates compose in one place.
func _apply_artifact_filter(seq: String) -> void:
	_artifact_seq_filter = seq if seq != "" else "ALL"
	_rebuild_artifact_list()


## Rebuild _artifact_list from the FULL catalog applying BOTH active predicates:
##   sequence — "ALL" = every map-ready artifact; else map_sequences must contain it
##   name     — _artifact_filter empty = no narrowing; else the lookup must contain it
## Sorts the result and resets the selection to the first entry (or -1 when nothing matches).
func _rebuild_artifact_list() -> void:
	var names: Array = []
	var want_all: bool = _artifact_seq_filter.to_upper() == "ALL"
	for lk in _artifact_seqs_by_lookup.keys():
		# Sequence predicate.
		if not want_all:
			var seqs: Array = _artifact_seqs_by_lookup[lk]
			if not seqs.has(_artifact_seq_filter):
				continue
		# Name predicate (case-insensitive substring on the lookup name).
		if _artifact_filter != "" and not str(lk).to_lower().contains(_artifact_filter):
			continue
		names.append(lk)
	names.sort()
	_artifact_list = names
	_artifact_idx = 0 if not _artifact_list.is_empty() else -1


## ARTIFACT NAME filter changed → cache the lower-cased substring, recompose the list with
## the active sequence filter, reset the selection, and refresh the preview + 3D card. PREV/
## NEXT then cycle the narrowed list. Empty match leaves an empty list (PLACE guards on it).
func _on_artifact_filter_changed(text: String) -> void:
	_active_tab = "ARTIFACTS"
	_artifact_filter = text.strip_edges().to_lower()
	_rebuild_artifact_list()
	_update_artifact_preview()
	_update_artifact_3d_preview()   # filter changed the selection → re-render the 3D card
	if _artifact_list.is_empty():
		_status_msg = "filter '%s' — no match   (0 total)" % _artifact_filter
	else:
		_status_msg = "filter '%s' — %d artifact%s   ·   %s" % [
			_artifact_filter, _artifact_list.size(),
			"" if _artifact_list.size() == 1 else "s", _selected_artifact()]
	_update_hud()


## Push the current selection to the panel's preview label (name + n/total).
func _update_artifact_preview() -> void:
	if _panel == null or not _panel.has_method("set_artifact_preview"):
		return
	_panel.set_artifact_preview(_selected_artifact(), _artifact_idx, _artifact_list.size())


## Seed the live interactables layer from the loaded map (or a blank grid). Stored
## as rows[z] = Array[col] of token strings; " " marks an empty cell.
func _load_interactables_layer() -> void:
	_interactables = _blank_interactables()
	var layers = _map_data.get("layers", {})
	if not (layers is Dictionary):
		return
	var existing = layers.get("interactables", [])
	if not (existing is Array):
		return
	for z in range(mini(_grid_d, existing.size())):
		var row = existing[z]
		if not (row is Array):
			continue
		for x in range(mini(_grid_w, row.size())):
			_interactables[z][x] = str(row[x])


func _blank_interactables() -> Array:
	var rows: Array = []
	for z in range(_grid_d):
		var row: Array = []
		for x in range(_grid_w):
			row.append(" ")
		rows.append(row)
	return rows


func _selected_artifact() -> String:
	if _artifact_idx < 0 or _artifact_idx >= _artifact_list.size():
		return ""
	return str(_artifact_list[_artifact_idx])


## PREV/NEXT — cycle the selected artifact and surface its name in the toast/HUD.
func _cycle_artifact(delta: int) -> void:
	if _artifact_list.is_empty():
		_status_msg = "no map-ready artifacts"
		_update_hud()
		return
	_artifact_idx = wrapi(_artifact_idx + delta, 0, _artifact_list.size())
	_status_msg = "artifact: %s   (%d/%d)" % [_selected_artifact(), _artifact_idx + 1, _artifact_list.size()]
	_update_artifact_preview()
	_update_artifact_3d_preview()   # render the newly-selected artifact in the 3D card
	_update_hud()


## LEFT-click on ARTIFACTS: write interactables[row][col] = lookup, then spawn it on
## the real grid via GridInteractablesComponent (zero drift). Clears any prior
## occupant of the cell first so placements don't stack.
func _place_artifact_at_hover() -> void:
	if not _editing_ready or not _hover_valid:
		return
	var lookup := _selected_artifact()
	if lookup == "":
		_status_msg = "no artifact selected"
		_update_hud()
		return
	var col := _hover_cell.y   # x
	var row := _hover_cell.x   # z
	if row < 0 or row >= _interactables.size() or col < 0 or col >= _interactables[row].size():
		return
	_push_artifact_undo()
	# Remove a prior spawned object at this cell (data + scene), then place fresh.
	_despawn_artifact_at(col, row)
	_interactables[row][col] = lookup
	if not _spawn_artifact(col, row, lookup):
		_status_msg = "placed '%s' in layer (no live spawn — synthetic?)" % lookup
	else:
		_status_msg = "placed '%s' at (%d,%d)" % [lookup, row, col]
	_update_hud()


## RIGHT-click / REMOVE: clear the hovered cell (data + spawned scene).
func _clear_artifact_at_hover() -> void:
	if not _editing_ready or not _hover_valid:
		return
	var col := _hover_cell.y
	var row := _hover_cell.x
	if row < 0 or row >= _interactables.size() or col < 0 or col >= _interactables[row].size():
		return
	if str(_interactables[row][col]).strip_edges() in ["", " "]:
		_status_msg = "cell (%d,%d) already empty" % [row, col]
		_update_hud()
		return
	_push_artifact_undo()
	_despawn_artifact_at(col, row)
	_interactables[row][col] = " "
	_status_msg = "cleared (%d,%d)" % [row, col]
	_update_hud()


# ── ARTIFACTS MOVE — pick-then-place an existing artifact ─────────────
## True when the interactables cell (row=z, col=x) holds a placed artifact (not blank).
## Bounds-guarded; used to gate the MOVE select box's "pick this" cue.
func _artifact_occupied_at(row: int, col: int) -> bool:
	if row < 0 or row >= _interactables.size():
		return false
	if col < 0 or col >= _interactables[row].size():
		return false
	return str(_interactables[row][col]).strip_edges() not in ["", " "]


## Toggle MOVE mode on/off (the MOVE button). Turning it off cancels any pending
## pickup so a half-finished move never lingers.
func _toggle_artifact_move() -> void:
	_artifact_move_mode = not _artifact_move_mode
	if not _artifact_move_mode:
		_cancel_artifact_move()
		_status_msg = "MOVE off — L-click places the selected artifact"
	else:
		_artifact_move_picked = false
		_status_msg = "MOVE on — L-click an occupied cell to pick it up"
	_position_hover_visuals()   # refresh the select box for the new MOVE state
	_update_hud()


## One LEFT-click while MOVE mode is active: pick up if nothing is held, else drop.
func _artifact_move_click() -> void:
	if _util_move_picked:
		return
	if not _artifact_move_picked:
		_artifact_pick_up()
	else:
		_artifact_drop()


## Pick up the artifact at the hovered cell: remember its token + cell, despawn its
## live scene, blank the data cell, highlight the source. No-op on an empty cell.
func _artifact_pick_up() -> void:
	if not _editing_ready or not _hover_valid:
		return
	var col := _hover_cell.y   # x
	var row := _hover_cell.x   # z
	if row < 0 or row >= _interactables.size() or col < 0 or col >= _interactables[row].size():
		return
	var tok := str(_interactables[row][col]).strip_edges()
	if tok == "" or tok == " ":
		_status_msg = "MOVE — cell (%d,%d) is empty, pick an occupied cell" % [row, col]
		_update_hud()
		return
	_push_artifact_undo()   # snapshot the whole layer so undo reverts the move
	_despawn_artifact_at(col, row)
	_interactables[row][col] = " "
	_artifact_move_token = tok
	_artifact_move_from = Vector2i(row, col)
	_artifact_move_picked = true
	_status_msg = "MOVE — picked '%s' from (%d,%d); L-click a target cell" % [tok, row, col]
	_position_hover_visuals()   # anchor the select box to the source cell
	_update_hud()


## Drop the held artifact at the hovered target cell: clear any occupant there, write the
## token + spawn it. The undo snapshot was taken at pick-up, so one undo reverts the move.
func _artifact_drop() -> void:
	if not _hover_valid:
		return
	var col := _hover_cell.y   # x
	var row := _hover_cell.x   # z
	if row < 0 or row >= _interactables.size() or col < 0 or col >= _interactables[row].size():
		return
	_despawn_artifact_at(col, row)
	_interactables[row][col] = _artifact_move_token
	var moved := _artifact_move_token
	var spawned := _spawn_artifact(col, row, _artifact_move_token)
	_artifact_move_picked = false
	_artifact_move_token = ""
	_artifact_move_from = Vector2i(-1, -1)
	_set_move_box(false)   # dropped — clear the source marker
	if spawned:
		_status_msg = "MOVE — '%s' → (%d,%d)" % [moved, row, col]
	else:
		_status_msg = "MOVE — '%s' moved to (%d,%d) in layer (no live spawn — synthetic?)" % [moved, row, col]
	_position_hover_visuals()   # re-evaluate the pick-cue for the now-empty hand
	_update_hud()


## Cancel a pending artifact pickup: respawn the held token back at its source cell and
## restore the data so nothing is lost. No-op when nothing is held.
func _cancel_artifact_move() -> void:
	if not _artifact_move_picked:
		return
	var row := _artifact_move_from.x   # z
	var col := _artifact_move_from.y   # x
	if row >= 0 and row < _interactables.size() and col >= 0 and col < _interactables[row].size():
		_interactables[row][col] = _artifact_move_token
		_spawn_artifact(col, row, _artifact_move_token)
	_artifact_move_picked = false
	_artifact_move_token = ""
	_artifact_move_from = Vector2i(-1, -1)
	_set_move_box(false)   # cancelled — clear the source marker
	_status_msg = "MOVE cancelled"
	_update_hud()


## Spawn one artifact on the real grid at column (x=col, z=row) using the
## interactables component's existing placement path. Returns false if the
## subsystem is absent (synthetic mode) so the caller can toast a hint.
func _spawn_artifact(col: int, row: int, lookup: String) -> bool:
	if _interactables_comp == null:
		return false
	# Map tokens carry a "lookup:rot:yoff" suffix (e.g. "force_pad:0:0"); _place_artifact
	# wants the BARE lookup + overrides. Parse it here — WITHOUT this, moving an EXISTING
	# (suffixed) artifact despawns it but the respawn fails and it vanishes.
	var parts: PackedStringArray = lookup.split(":", false)
	var bare: String = lookup.strip_edges()
	var overrides: Dictionary = {}
	if parts.size() >= 1:
		bare = str(parts[0]).strip_edges()
	if parts.size() >= 2 and str(parts[1]).strip_edges() != "":
		overrides["rotation_y_degrees"] = float(str(parts[1]))
	if parts.size() >= 3 and str(parts[2]).strip_edges() != "":
		overrides["y_offset"] = float(str(parts[2]))
	if bare == "" or bare == " ":
		return false
	var y_pos := 0
	if _structure and _structure.has_method("find_highest_y_at"):
		y_pos = _structure.find_highest_y_at(col, row)
	var total_size: float = cube_size
	if "cube_size" in _interactables_comp:
		total_size = _interactables_comp.cube_size + _interactables_comp.gutter
	if not _interactables_comp.has_method("_place_artifact"):
		return false
	# Same path generate_interactables uses → spawns match the game. The bare lookup +
	# parsed overrides make moving a suffixed/existing artifact respawn correctly.
	return bool(_interactables_comp._place_artifact(col, y_pos, row, bare, total_size, overrides))


## Remove any spawned interactable object(s) at column (x=col, z=row). The component
## keys interactable_objects by Vector3i(x,y,z); we don't know y, so scan the column.
func _despawn_artifact_at(col: int, row: int) -> void:
	# Normal artifacts (map-built AND editor-placed) are NOT in interactable_objects —
	# _place_artifact tags them with group "vr_editable_artifact" + meta grid_cell=Vector2i(x,z).
	# Despawn by the group first (this is what makes MOVE work on EXISTING artifacts), then
	# also sweep interactable_objects for the special types (mc/agent/generator) that DO record there.
	var cell := Vector2i(col, row)   # (x, z)
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group("vr_editable_artifact"):
			if is_instance_valid(node) and node.has_meta("grid_cell") and node.get_meta("grid_cell") == cell:
				node.queue_free()
	if _interactables_comp and ("interactable_objects" in _interactables_comp):
		var objs: Dictionary = _interactables_comp.interactable_objects
		var to_free: Array = []
		for key in objs.keys():
			if key is Vector3i and key.x == col and key.z == row:
				to_free.append(key)
		for key in to_free:
			var node = objs[key]
			if is_instance_valid(node):
				node.queue_free()
			objs.erase(key)


# ══════════════════════════════════════════════════════════════════════
# UTILITY tab — edit the utilities layer (spawn/teleporter/ramp/…) + spawn live
# via GridUtilitiesComponent. The layer is utilities[row][col] = "<code>" (some carry
# params/rotation as a colon suffix). Live spawn degrades gracefully in synthetic mode
# (the component is never initialize()'d without a --map, so its parent_node is null).
# ══════════════════════════════════════════════════════════════════════

## Seed the live utilities layer from the loaded map (or a blank grid), and spawn whatever
## the map already carries so the UTILITY tab starts from the real scene. Stored as
## rows[z] = Array[col] of code strings; " " marks an empty cell.
func _load_utilities_layer() -> void:
	_utilities = _blank_utilities()
	var layers = _map_data.get("layers", {})
	if layers is Dictionary:
		var existing = layers.get("utilities", [])
		if existing is Array:
			for z in range(mini(_grid_d, existing.size())):
				var row = existing[z]
				if not (row is Array):
					continue
				for x in range(mini(_grid_w, row.size())):
					_utilities[z][x] = str(row[x])
	# Spawn the existing utilities live (so what loads matches the game). The map's own
	# generate path already spawned them during GridSystem build; avoid double-spawning by
	# only seeding the layer here. We do NOT re-spawn — the grid already rendered them.


func _blank_utilities() -> Array:
	var rows: Array = []
	for z in range(_grid_d):
		var row: Array = []
		for x in range(_grid_w):
			row.append(" ")
		rows.append(row)
	return rows


## Friendly name for a utility code (registry name, else the code). Tolerates codes that
## carry a param suffix (e.g. "t:next") by reading only the base before the first colon.
func _util_friendly_name(code: String) -> String:
	var base := code
	if ":" in base:
		base = base.split(":")[0]
	if UtilityRegistry.is_valid_utility_type(base):
		return UtilityRegistry.get_utility_name(base)
	return code


## LEFT-click on the UTILITY tab: dispatch the active op at the hovered cell.
func _utility_left_click() -> void:
	if not _editing_ready or not _hover_valid:
		return
	match _util_op:
		"ADD": _add_utility_at_hover()
		"REMOVE": _clear_utility_at_hover()
		"ROTATE": _rotate_utility_at_hover()
		"MOVE": _utility_move_click()
		_: _add_utility_at_hover()


## ADD: write utilities[row][col] = code and spawn it live (clearing any prior occupant).
func _add_utility_at_hover() -> void:
	var col := _hover_cell.y   # x
	var row := _hover_cell.x   # z
	if row < 0 or row >= _utilities.size() or col < 0 or col >= _utilities[row].size():
		return
	if _util_code.strip_edges() == "":
		_status_msg = "pick a utility type first"
		_update_hud()
		return
	_push_utility_undo()
	_despawn_utility_at(col, row)
	_utilities[row][col] = _util_code
	if _spawn_utility(col, row, _util_code):
		_status_msg = "placed %s at (%d,%d)" % [_util_friendly_name(_util_code), row, col]
	else:
		_status_msg = "placed %s in layer (no live spawn — synthetic?)" % _util_friendly_name(_util_code)
	_update_hud()


## REMOVE: clear the hovered cell (data + spawned scene).
func _clear_utility_at_hover() -> void:
	var col := _hover_cell.y
	var row := _hover_cell.x
	if row < 0 or row >= _utilities.size() or col < 0 or col >= _utilities[row].size():
		return
	if str(_utilities[row][col]).strip_edges() in ["", " "]:
		_status_msg = "utility cell (%d,%d) already empty" % [row, col]
		_update_hud()
		return
	_push_utility_undo()
	_despawn_utility_at(col, row)
	_utilities[row][col] = " "
	_status_msg = "cleared utility (%d,%d)" % [row, col]
	_update_hud()


## ROTATE: advance the utility's facing by 90°. Rotation rides on the cell token as a
## trailing numeric param (the registry's convention for s/t/an/wp etc.: a degrees suffix).
## We parse the current token, bump the rotation param, rewrite the cell, and respawn.
func _rotate_utility_at_hover() -> void:
	var col := _hover_cell.y
	var row := _hover_cell.x
	if row < 0 or row >= _utilities.size() or col < 0 or col >= _utilities[row].size():
		return
	var tok := str(_utilities[row][col]).strip_edges()
	if tok in ["", " "]:
		_status_msg = "nothing to rotate at (%d,%d)" % [row, col]
		_update_hud()
		return
	_push_utility_undo()
	var rotated := _bump_rotation_token(tok)
	_despawn_utility_at(col, row)
	_utilities[row][col] = rotated
	_spawn_utility(col, row, rotated)
	_status_msg = "rotated %s → '%s' at (%d,%d)" % [_util_friendly_name(tok), rotated, row, col]
	_update_hud()


## Append/advance a rotation (degrees) param on a utility token by +90°, wrapping 0..270.
## "<code>" → "<code>:90"; "<code>:90" → "<code>:180"; preserves any non-rotation params by
## treating only a trailing pure-integer param as the rotation slot.
func _bump_rotation_token(tok: String) -> String:
	var parts: PackedStringArray = tok.split(":")
	if parts.size() == 0:
		return tok
	var base := str(parts[0])
	# If the last part is a pure integer, treat it as the existing rotation and bump it.
	if parts.size() >= 2 and str(parts[parts.size() - 1]).is_valid_int():
		var deg := int(str(parts[parts.size() - 1]))
		deg = wrapi(deg + 90, 0, 360)
		parts[parts.size() - 1] = str(deg)
		return ":".join(parts)
	# Otherwise append a fresh rotation param after whatever params exist.
	var out := base
	for i in range(1, parts.size()):
		out += ":" + str(parts[i])
	out += ":90"
	return out


# ── UTILITY MOVE — pick-then-place on the utilities layer ─────────────
func _utility_move_click() -> void:
	if _artifact_move_picked:
		return
	if not _util_move_picked:
		_utility_pick_up()
	else:
		_utility_drop()


func _utility_pick_up() -> void:
	var col := _hover_cell.y
	var row := _hover_cell.x
	if row < 0 or row >= _utilities.size() or col < 0 or col >= _utilities[row].size():
		return
	var tok := str(_utilities[row][col]).strip_edges()
	if tok in ["", " "]:
		_status_msg = "MOVE — utility cell (%d,%d) is empty" % [row, col]
		_update_hud()
		return
	_push_utility_undo()
	_despawn_utility_at(col, row)
	_utilities[row][col] = " "
	_util_move_token = tok
	_util_move_from = Vector2i(row, col)
	_util_move_picked = true
	_status_msg = "MOVE — picked %s from (%d,%d); L-click a target" % [_util_friendly_name(tok), row, col]
	_update_hud()


func _utility_drop() -> void:
	var col := _hover_cell.y
	var row := _hover_cell.x
	if row < 0 or row >= _utilities.size() or col < 0 or col >= _utilities[row].size():
		return
	_despawn_utility_at(col, row)
	_utilities[row][col] = _util_move_token
	var moved := _util_move_token
	var spawned := _spawn_utility(col, row, _util_move_token)
	_util_move_picked = false
	_util_move_token = ""
	_util_move_from = Vector2i(-1, -1)
	if spawned:
		_status_msg = "MOVE — %s → (%d,%d)" % [_util_friendly_name(moved), row, col]
	else:
		_status_msg = "MOVE — %s moved to (%d,%d) in layer (no live spawn — synthetic?)" % [_util_friendly_name(moved), row, col]
	_update_hud()


func _cancel_utility_move() -> void:
	if not _util_move_picked:
		return
	var row := _util_move_from.x
	var col := _util_move_from.y
	if row >= 0 and row < _utilities.size() and col >= 0 and col < _utilities[row].size():
		_utilities[row][col] = _util_move_token
		_spawn_utility(col, row, _util_move_token)
	_util_move_picked = false
	_util_move_token = ""
	_util_move_from = Vector2i(-1, -1)
	_status_msg = "utility MOVE cancelled"
	_update_hud()


## Spawn one utility on the real grid at column (x=col, z=row) via the utilities
## component's existing _place_utility path (zero drift). Returns false if the subsystem
## is absent / uninitialised (synthetic mode) so the caller can toast a hint.
func _spawn_utility(col: int, row: int, token: String) -> bool:
	if _utilities_comp == null:
		return false
	# Without a --map the component is never initialize()'d, so parent_node is null and
	# _place_utility would crash on add_child. Guard on parent_node before spawning.
	if not ("parent_node" in _utilities_comp) or _utilities_comp.parent_node == null:
		return false
	if not _utilities_comp.has_method("_place_utility"):
		return false
	var parsed: Dictionary = UtilityRegistry.parse_utility_cell(token)
	var code := str(parsed.get("type", "")).strip_edges()
	if code == "" or code == " ":
		return false
	if not UtilityRegistry.is_valid_utility_type(code):
		return false
	# Some codes carry no scene file (authorial annotations, f:/bp: handled elsewhere) —
	# skip live spawn for those but the data write still stands.
	if UtilityRegistry.get_utility_scene_path(code) == "":
		return false
	var params: Array = parsed.get("parameters", [])
	var y_pos := 0
	if _structure and _structure.has_method("find_highest_y_at"):
		y_pos = _structure.find_highest_y_at(col, row)
	var total_size: float = cube_size
	if "gutter" in _utilities_comp:
		total_size = cube_size + float(_utilities_comp.gutter)
	_utilities_comp._place_utility(col, y_pos, row, code, params, {}, total_size)
	return true


## Remove any spawned utility object(s) at column (x=col, z=row). The component keys
## utility_objects by Vector3i(x,y,z); y is unknown here, so scan the column.
func _despawn_utility_at(col: int, row: int) -> void:
	if _utilities_comp == null:
		return
	if not ("utility_objects" in _utilities_comp):
		return
	var objs: Dictionary = _utilities_comp.utility_objects
	var to_free: Array = []
	for key in objs.keys():
		if key is Vector3i and key.x == col and key.z == row:
			to_free.append(key)
	for key in to_free:
		var node = objs[key]
		if is_instance_valid(node):
			node.queue_free()
		objs.erase(key)


## UTILITY edits snapshot the utilities layer (data only) onto the shared undo stack, so
## Ctrl+Z reverts an ADD/REMOVE/MOVE/ROTATE. Restoring re-spawns the layer.
func _push_utility_undo() -> void:
	if not _editing_ready:
		return
	var snap := _snapshot()
	snap["utilities"] = _dup_utilities()
	_undo_stack.append(snap)
	if _undo_stack.size() > UNDO_CAP:
		_undo_stack.pop_front()
	_redo_stack.clear()


func _dup_utilities() -> Array:
	var out: Array = []
	for row in _utilities:
		out.append((row as Array).duplicate())
	return out


## Re-apply a snapshotted utilities layer: clear all spawned utilities, replace the live
## layer, then spawn each non-empty cell back. Keeps data + scene in sync on undo.
func _restore_utilities(rows) -> void:
	if not (rows is Array):
		return
	if _utilities_comp and ("utility_objects" in _utilities_comp):
		var objs: Dictionary = _utilities_comp.utility_objects
		for key in objs.keys():
			var node = objs[key]
			if is_instance_valid(node):
				node.queue_free()
		objs.clear()
	_utilities = []
	for row in rows:
		_utilities.append((row as Array).duplicate())
	for z in range(_utilities.size()):
		var r: Array = _utilities[z]
		for x in range(r.size()):
			var tok := str(r[x]).strip_edges()
			if tok != "" and tok != " ":
				_spawn_utility(x, z, tok)


# ══════════════════════════════════════════════════════════════════════
# BIOME tab — paint a per-element density field → paint_layers → repaint live
# (the brush model is lifted from BiomeScrubberDesktop3D, not re-derived)
# ══════════════════════════════════════════════════════════════════════

func _active_biome_element() -> String:
	if _biome_idx < 0 or _biome_idx >= _biome_elements.size():
		return ""
	return str(_biome_elements[_biome_idx])


## Biome-area dimensions = grid + a margin ring on every side. The painted field,
## the density overlay, and the accrual grid_dims are all sized to this, and the
## biome host is offset by -M cells so its local [0,dims) maps to world
## [-M, grid+M] — foliage scatters around the grid, not just on it.
func _biome_w() -> int:
	return _grid_w + 2 * BIOME_MARGIN


func _biome_d() -> int:
	return _grid_d + 2 * BIOME_MARGIN


## Margin-offset field index for a grid cell (cx, cz), where cx/cz may be negative
## (in the margin ring). Returns -1 if the cell falls outside the biome area.
func _biome_field_index(cx: int, cz: int) -> int:
	var bw := _biome_w()
	var bd := _biome_d()
	var fx := cx + BIOME_MARGIN
	var fz := cz + BIOME_MARGIN
	if fx < 0 or fx >= bw or fz < 0 or fz >= bd:
		return -1
	return fz * bw + fx


func _biome_color(el: String) -> Color:
	return BiomeElementsLib.ui_color(el)


## Raycast the mouse to the ground plane → grid cell → stamp the active element's
## brush field (radial falloff, Shift = erase). Mirrors the scrubber's _stamp.
func _stamp_biome_at_hover() -> void:
	# Biome painting only needs valid grid dims + a hovered cell + the overlay — it
	# does NOT depend on structure-editing readiness (that gate is for GRID/PAINT
	# height/colour ops). Guard on dims + hover, not _editing_ready.
	if not _hover_valid or _grid_w <= 0 or _grid_d <= 0:
		return
	# Auto-select the first element if none is active, so the very first stroke paints
	# instead of dead-clicking with a "pick an element" toast.
	_ensure_biome_element()
	var el := _active_biome_element()
	if el == "":
		_status_msg = "pick a biome element first"
		_update_hud()
		return
	var cx := _hover_cell.y   # x
	var cz := _hover_cell.x   # z
	var erasing := Input.is_key_pressed(KEY_SHIFT)
	_stamp_biome_field(el, cx, cz, _brush_radius, erasing)
	_biome_dirty = true
	_update_biome_overlay()


## Stamp the element's per-cell density field with a radial-falloff brush at (cx,cz).
## Pure field math (no input/hover deps) — reused by the mouse stroke AND the headless
## --paintbiome proof. Allocates the field lazily (sized to the biome AREA); clamps to
## [0,1] (or floors at 0 when erasing). Uses the margin-OFFSET field index, so cx/cz (and
## the brush footprint) may be NEGATIVE — anywhere in the biome area [-M, grid+M). The
## radial blob is clamped to the biome AREA (via _biome_field_index returning -1 outside
## the ring), NOT the grid.
func _stamp_biome_field(el: String, cx: int, cz: int, r: int, erasing: bool) -> void:
	if el == "" or _grid_w <= 0 or _grid_d <= 0:
		return
	var need := _biome_w() * _biome_d()
	if not _brush_fields.has(el):
		var nf := PackedFloat32Array()
		nf.resize(need)
		_brush_fields[el] = nf
	var field: PackedFloat32Array = _brush_fields[el]
	# Grow a stale field if the grid (and thus the biome area) changed since allocation.
	if field.size() != need:
		field.resize(need)
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var x := cx + dx
			var z := cz + dz
			var i := _biome_field_index(x, z)
			if i < 0:
				continue
			var dist := sqrt(float(dx * dx + dz * dz))
			if dist > float(r) + 0.001:
				continue
			var falloff := 1.0 - dist / (float(r) + 0.0001)
			if erasing:
				field[i] = maxf(0.0, field[i] - _brush_strength * falloff)
			else:
				field[i] = minf(1.0, field[i] + _brush_strength * falloff)
	_brush_fields[el] = field


## Headless biome-paint proof (--paintbiome=<element>). Selects the element, stamps a
## brush blob at the grid centre over a few cells, lights the overlay, and runs the
## live rebuild — so a screenshot proves biome painting renders without a mouse.
func _headless_paint_biome(element: String) -> void:
	var el := element.strip_edges()
	var idx := _biome_elements.find(el)
	if idx < 0:
		# Unknown element name → fall back to the first, so the proof still produces output.
		push_warning("[grid-editor] --paintbiome: unknown element '%s', using '%s'" % [el, str(_biome_elements[0]) if not _biome_elements.is_empty() else ""])
		_ensure_biome_element()
		el = _active_biome_element()
	else:
		_biome_idx = idx
	if el == "":
		return
	_active_tab = "BIOME"
	if _biome_overlay:
		_biome_overlay.visible = true
	# Stamp a generous blob at the grid centre across a small cluster of cells, so the
	# field clearly registers regardless of brush radius.
	var ccx := int(_grid_w / 2)
	var ccz := int(_grid_d / 2)
	var rad := maxi(_brush_radius, 4)
	var m := int(BIOME_MARGIN / 2)   # stamp into the margin ring, just outside the grid
	# Centre + a ring of spots AROUND the grid (cells in the margin, outside [0,grid)) —
	# proves painting + foliage now wrap the grid, not only +x/+z.
	var spots := [
		Vector2i(ccx, ccz),
		Vector2i(-m, ccz), Vector2i(_grid_w + m, ccz),               # west / east
		Vector2i(ccx, -m), Vector2i(ccx, _grid_d + m),               # south / north
		Vector2i(-m, -m), Vector2i(_grid_w + m, -m),                 # corners
		Vector2i(-m, _grid_d + m), Vector2i(_grid_w + m, _grid_d + m),
	]
	for sp in spots:
		_stamp_biome_field(el, sp.x, sp.y, rad, false)
	_biome_dirty = true
	_update_biome_overlay()
	_repaint_biome_live()
	print("[grid-editor] --paintbiome=%s: stamped centre+ring (margin %d) r=%d, %d field cell(s)" % [
		el, m, rad, _painted_cell_count(el)])


## Count of cells with non-zero painted density for `el` (proof diagnostic).
func _painted_cell_count(el: String) -> int:
	var field: PackedFloat32Array = _brush_fields.get(el, PackedFloat32Array())
	var n := 0
	for v in field:
		if v > 0.01:
			n += 1
	return n


## Headless proof for moving an EXISTING (map-loaded) artifact (--testmove): find the
## first occupied interactables cell, pick it up + drop it on an adjacent cell, and report
## whether it respawned at the target. Proves the suffixed-token respawn fix end-to-end.
func _headless_test_move() -> void:
	_active_tab = "ARTIFACTS"
	var from := Vector2i(-1, -1)
	for z in range(_interactables.size()):
		for x in range(_interactables[z].size()):
			if str(_interactables[z][x]).strip_edges() not in ["", " "]:
				from = Vector2i(z, x)
				break
		if from.x >= 0:
			break
	if from.x < 0:
		print("[grid-editor] --testmove: no existing artifacts to move")
		return
	var tok := str(_interactables[from.x][from.y]).strip_edges()
	_hover_cell = from
	_hover_valid = true
	_artifact_move_mode = true
	_artifact_move_picked = false
	_artifact_pick_up()
	var picked := _artifact_move_picked
	# Pick an EMPTY target cell that has floor (so _place_artifact can spawn on it).
	var to := Vector2i(-1, -1)
	for dx in [1, 2, -1, -2, 3, -3]:
		var tx: int = from.y + int(dx)
		if tx < 0 or tx >= _grid_w:
			continue
		if str(_interactables[from.x][tx]).strip_edges() not in ["", " "]:
			continue
		if _structure and _structure.has_method("get_height_at") and int(_structure.get_height_at(tx, from.x)) > 0:
			to = Vector2i(from.x, tx)
			break
	if to.x < 0:
		to = Vector2i(from.x, clampi(from.y + 2, 0, _grid_w - 1))
	_hover_cell = to
	_artifact_drop()
	var respawned := false
	var target := Vector2i(to.y, to.x)   # (x, z)
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group("vr_editable_artifact"):
			if is_instance_valid(node) and not node.is_queued_for_deletion() and node.has_meta("grid_cell") and node.get_meta("grid_cell") == target:
				respawned = true
				break
	print("[grid-editor] --testmove: tok='%s' picked=%s  (%d,%d)->(%d,%d)  respawned=%s  data='%s'" % [
		tok, str(picked), from.x, from.y, to.x, to.y, str(respawned), str(_interactables[to.x][to.y])])


## Headless proof that a painted biome PERSISTS across save→reload (--testpersist): paint a
## blob, serialize to paint_layers (as the save does), wipe the live fields, then reload from
## paint_layers (the persistence path) and confirm the field came back.
func _headless_test_persist() -> void:
	_ensure_biome_element()
	var el := _active_biome_element()
	if el == "":
		print("[grid-editor] --testpersist: no biome element")
		return
	_stamp_biome_field(el, int(_grid_w / 2), int(_grid_d / 2), maxi(_brush_radius, 4), false)
	var before := _painted_cell_count(el)
	_map_data["paint_layers"] = _biome_paint_layers()   # serialize as save would
	_brush_fields.clear()                                # wipe live fields (simulate reload)
	var cleared := _painted_cell_count(el)
	_load_biome_paint_layers()                           # reload from saved paint_layers
	var after := _painted_cell_count(el)
	print("[grid-editor] --testpersist: el='%s' painted=%d  cleared=%d  reloaded=%d  persists=%s" % [
		el, before, cleared, after, str(after > 0 and after == before)])


## (Re)allocate the biome overlay's per-cell instances to the current grid and lay
## them out flat on the floor. Called when the grid dims are known / change.
func _resize_biome_overlay() -> void:
	if _biome_overlay == null or _biome_overlay.multimesh == null:
		return
	var mm := _biome_overlay.multimesh
	var bw := _biome_w()
	var bd := _biome_d()
	mm.instance_count = bw * bd
	# The overlay covers the WHOLE biome area: instance (x,z) at biome-local cell (x,z)
	# sits at world cell (x - M, z - M), so the ring extends M cells past the grid on
	# every side. World position uses the grid origin (no host offset — the overlay is a
	# direct child of the editor, NOT under _biome_host).
	for z in range(bd):
		for x in range(bw):
			var i := z * bw + x
			var wx := (float(x - BIOME_MARGIN) + 0.5) * cube_size
			var wz := (float(z - BIOME_MARGIN) + 0.5) * cube_size
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(wx, 0.07, wz)))
			mm.set_instance_color(i, Color(0, 0, 0, 0))


## Tint each overlay cell by the active element's painted density. No-op off BIOME.
func _update_biome_overlay() -> void:
	if _biome_overlay == null or _biome_overlay.multimesh == null:
		return
	var mm := _biome_overlay.multimesh
	var bw := _biome_w()
	var bd := _biome_d()
	if mm.instance_count != bw * bd:
		_resize_biome_overlay()
	var el := _active_biome_element()
	if _active_tab != "BIOME" or el == "":
		for i in range(mm.instance_count):
			mm.set_instance_color(i, Color(0, 0, 0, 0))
		return
	var col := _biome_color(el)
	var field: PackedFloat32Array = _brush_fields.get(el, PackedFloat32Array())
	# Overlay index == field index (both are biome-area, margin-offset, row-major over bw*bd).
	for z in range(bd):
		for x in range(bw):
			var i := z * bw + x
			var v: float = field[i] if i < field.size() else 0.0
			mm.set_instance_color(i, Color(col.r, col.g, col.b, v * 0.75))


## Build paint_layers from the painted fields (mirrors the scrubber's _effective_paint_layers
## brush payload: one mode:"brush" layer per element, compact sparse mask via DistributionField).
## Fed straight into BiomeAccrualManager.apply() as ctx.paint_layers — the wired spawn layers
## (tree/critter/flower) place visible foliage by these distributions. Also persisted on save.
func _biome_paint_layers() -> Array:
	var out: Array = []
	var bw := _biome_w()
	var bd := _biome_d()
	for el in _brush_fields:
		var field: PackedFloat32Array = _brush_fields[el]
		# Sparse mask is built over the biome AREA (bw×bd), so the accrual scatters foliage
		# across the whole ring around the grid. The host offset (see _rebuild_biome) maps
		# biome-local cell 0 → world cell -M, so foliage lands around the grid in world space.
		var layer := {
			"element": str(el),
			"mode": "brush",
			"density": 1.0,
			"brush": DistributionFieldLib.field_to_sparse(field, bw, bd),
		}
		if str(el) == "ground":
			layer["height"] = 1.5
		elif str(el) == "shader":
			var c := _biome_color(str(el))
			layer["color"] = [c.r, c.g, c.b]
		out.append(layer)
	return out


## Inverse of _biome_paint_layers: re-seed _brush_fields from the loaded map's saved
## paint_layers so a painted biome PERSISTS across save→reload. Each brush-mode layer's
## sparse {w,d,cells:[[x,z,v]]} → a field over the current biome area.
func _load_biome_paint_layers() -> void:
	var pls = _map_data.get("paint_layers", [])
	if not (pls is Array):
		return
	var bw := _biome_w()
	var bd := _biome_d()
	for layer in pls:
		if not (layer is Dictionary):
			continue
		var el := str(layer.get("element", "")).strip_edges()
		if el == "":
			continue
		var brush = layer.get("brush", null)
		if not (brush is Dictionary) or not brush.has("cells"):
			continue
		var field := PackedFloat32Array()
		field.resize(bw * bd)
		for c in brush.get("cells", []):
			if c is Array and (c as Array).size() >= 3:
				var x := int(c[0])
				var z := int(c[1])
				if x >= 0 and x < bw and z >= 0 and z < bd:
					field[z * bw + x] = float(c[2])
		_brush_fields[el] = field


## On stroke-release: rebuild the REAL biome (visible foliage) from the painted
## fields. Was GridSystem.repaint_biome (a flat overlay, no foliage); now drives
## BiomeAccrualManager on a dedicated host, exactly like the scrubber.
func _repaint_biome_live() -> void:
	_rebuild_biome()


## Wire the accrual path once the grid is known: grab the autoload, create the host,
## and resolve the stage from the loaded map's sequence (else a high stage so foliage
## is visibly present). Degrades to the overlay-only fallback if the autoload is absent.
func _setup_biome_accrual() -> void:
	if _biome_host == null:
		_biome_host = Node3D.new()
		_biome_host.name = "EditorBiomeHost"
		# Offset by -M cells so the accrual's local biome-area frame lands as a margin ring
		# around the grid in world space (re-asserted each rebuild in _rebuild_biome).
		_biome_host.position = Vector3(-float(BIOME_MARGIN) * cube_size, 0.0, -float(BIOME_MARGIN) * cube_size)
		add_child(_biome_host)
	_accrual = get_node_or_null("/root/BiomeAccrualManager")
	if _accrual == null:
		_status_msg = "BiomeAccrualManager autoload missing — biome overlay only"
		push_warning("[grid-editor] BiomeAccrualManager autoload missing; painted-field overlay is the only biome feedback")
		return
	_biome_stage = _resolve_biome_stage()


## The stage_order to feed the accrual. With a real map, sync EcosystemManager to it
## and read its true stage (the scrubber's path). Otherwise fall back to a high stage
## (12) so painted foliage is clearly present even in synthetic mode.
func _resolve_biome_stage() -> int:
	var fallback := 12
	if _loaded_map == "":
		return fallback
	var eco := get_node_or_null("/root/EcosystemManager")
	if eco == null:
		return fallback
	if eco.has_method("sync_to_map"):
		eco.sync_to_map(_loaded_map)
	if eco.has_method("get_current_stage_order"):
		var order := int(eco.get_current_stage_order())
		# Lab maps return 99 (uncapped) so the lab dispatcher is reachable; keep it.
		# A real low/zero order shouldn't blank the preview, so floor non-lab stages at 1.
		if order > 0:
			return mini(order, 99)
	return fallback


## Rebuild the visible biome from the painted fields — MIRRORS BiomeScrubberDesktop3D
## ._rebuild(): free the host's children immediately, set the stage override, sync the
## enabled layers, then BiomeAccrualManager.apply(host, ctx) with the SAME ctx keys.
## paint_layers = the editor's painted brush fields (_biome_paint_layers); rng_seed =
## hash(_loaded_map) for parity with the game's arrangement. No autoload → overlay only.
func _rebuild_biome() -> void:
	if _accrual == null or _biome_host == null:
		# No accrual path available → keep the painted overlay as the only feedback.
		_status_msg = "painted %d biome field%s — no accrual to render foliage" % [
			_brush_fields.size(), "" if _brush_fields.size() == 1 else "s"]
		_update_hud()
		return
	# Immediate free (not queue_free) — apply()'s internal queue_free defers to
	# frame-end, and we may re-apply several times per frame, so clear now to avoid
	# suffixed leftovers piling up under the host (the scrubber's reasoning).
	for c in _biome_host.get_children():
		_biome_host.remove_child(c)
		c.free()
	if _accrual.has_method("set_stage_override"):
		_accrual.set_stage_override(_biome_stage)
	if _accrual.has_method("enable_layer") and _accrual.has_method("get_contributions"):
		for entry in _accrual.get_contributions():
			if entry is Dictionary:
				_accrual.enable_layer(str(entry.get("kind", "")), true)
	# Offset the host so its local [0,dims) maps to world [-M, grid+M]: the accrual
	# scatters foliage in the host's LOCAL frame over the biome-area dims, and this
	# shift places that area as a margin ring AROUND the grid in world space.
	_biome_host.position = Vector3(-float(BIOME_MARGIN) * cube_size, 0.0, -float(BIOME_MARGIN) * cube_size)
	var bw := _biome_w()
	var bd := _biome_d()
	var layers := _biome_paint_layers()
	var ctx := {
		# grid_dims spans the whole biome AREA (grid + margin ring) so foliage scatters
		# across it; grid_center is that area's centre in the host's LOCAL frame.
		"grid_dims": Vector3i(bw, 1, bd),
		"grid_center": Vector3(float(bw) * cube_size * 0.5, 0.0, float(bd) * cube_size * 0.5),
		"cube_size": cube_size,
		# Seed parity with GridSystem (hash(map_name)) so the editor preview is the SAME
		# arrangement the game renders. Synthetic mode uses a fixed seed.
		"rng_seed": (hash(_loaded_map) if _loaded_map != "" else 0xB10E),
		"map_name": _loaded_map if _loaded_map != "" else "GridEditor",
		"biome_paint": [],
		"stage_order": _biome_stage,
		"biome_overrides": {"params": {}},
		"paint_layers": layers,
		"budget_scale": 1.0,
	}
	_accrual.apply(_biome_host, ctx)
	_status_msg = "biome rebuilt — %d element field%s @ stage %d" % [
		layers.size(), "" if layers.size() == 1 else "s", _biome_stage]
	_update_hud()


## Sync the active brush radius/strength readouts (no-op placeholder for parity with
## the scrubber; kept so HUD reads correctly right after load).
func _sync_biome_size() -> void:
	_brush_radius = clampi(_brush_radius, 0, 8)
	_brush_strength = clampf(_brush_strength, 0.1, 1.0)


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


## ARTIFACTS edits also snapshot the interactables layer (data only). Restoring it
## re-spawns the layer so undo brings back / clears the right cells. Same stack as
## the structure undo — Ctrl+Z walks them in order.
func _push_artifact_undo() -> void:
	if not _editing_ready:
		return
	var snap := _snapshot()
	snap["interactables"] = _dup_interactables()
	_undo_stack.append(snap)
	if _undo_stack.size() > UNDO_CAP:
		_undo_stack.pop_front()
	_redo_stack.clear()


func _dup_interactables() -> Array:
	var out: Array = []
	for row in _interactables:
		out.append((row as Array).duplicate())
	return out


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
	# Restore the interactables layer + re-spawn, when the snapshot carried it.
	if snap.has("interactables"):
		_restore_interactables(snap["interactables"])
	# Restore the utilities layer + re-spawn, when the snapshot carried it.
	if snap.has("utilities"):
		_restore_utilities(snap["utilities"])
	_position_hover_visuals()
	_update_hud()


## Re-apply a snapshotted interactables layer: clear all spawned objects, replace the
## live layer, then spawn each non-empty cell back. Keeps data + scene in sync on undo.
func _restore_interactables(rows) -> void:
	if not (rows is Array):
		return
	# Despawn everything currently placed.
	if _interactables_comp and ("interactable_objects" in _interactables_comp):
		var objs: Dictionary = _interactables_comp.interactable_objects
		for key in objs.keys():
			var node = objs[key]
			if is_instance_valid(node):
				node.queue_free()
		objs.clear()
	# Replace the live layer (deep copy so the snapshot stays immutable).
	_interactables = []
	for row in rows:
		_interactables.append((row as Array).duplicate())
	# Re-spawn non-empty cells.
	for z in range(_interactables.size()):
		var row: Array = _interactables[z]
		for x in range(row.size()):
			var tok := str(row[x]).strip_edges()
			if tok != "" and tok != " ":
				_spawn_artifact(x, z, tok)


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

	# ARTIFACTS — write the interactables layer (placed artifacts). Only when the
	# live layer holds at least one token, so a GRID-only edit never clobbers an
	# existing interactables layer with blanks.
	var inter_count := _write_interactables_layer(data)

	# UTILITY — write the utilities layer (placed spawn/teleporter/ramp/…). Same
	# guard: only when the live layer holds a token, so a non-UTILITY session never
	# clobbers a hand-authored utilities layer with blanks.
	var util_count := _write_utilities_layer(data)

	# BIOME — merge the painted fields into top-level paint_layers[]: an authored
	# element replaces its prior layer; other layers (and CLI/distribution ones the
	# editor didn't touch) are preserved. Omitted entirely when nothing's painted.
	var paint_count := _write_paint_layers(data)

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
	_status_msg = "✓ saved → repo  (%s · %d rows · %d mods · %d artifacts · %d util · %d paint)" % [
		_loaded_map, layout.size(), _modifier_stack.size(), inter_count, util_count, paint_count]
	_update_hud()
	print("[grid-editor] saved %s (%d rows, %d modifiers, %d artifacts, %d utilities, %d paint layers)" % [
		_loaded_map, layout.size(), _modifier_stack.size(), inter_count, util_count, paint_count])


## Write the live interactables layer into data.layers.interactables, preserving the
## existing layer when nothing has been placed. Returns the count of non-empty cells.
func _write_interactables_layer(data: Dictionary) -> int:
	var count := 0
	var rows: Array = []
	for z in range(_interactables.size()):
		var src: Array = _interactables[z]
		var row: Array = []
		for x in range(src.size()):
			var tok := str(src[x])
			if tok.strip_edges() != "" and tok.strip_edges() != " ":
				count += 1
				row.append(tok)
			else:
				row.append(" ")
		rows.append(row)
	# A blank live layer should not erase a hand-authored interactables layer that
	# the editor simply didn't touch (e.g. GRID-only session). Only write when we
	# actually hold tokens, OR when there is no existing layer to protect.
	var has_existing: bool = data.has("layers") and (data["layers"] is Dictionary) and bool(data["layers"].has("interactables"))
	if count > 0 or not has_existing:
		if not data.has("layers") or not (data["layers"] is Dictionary):
			data["layers"] = {}
		data["layers"]["interactables"] = rows
	return count


## Write the live utilities layer into data.layers.utilities, preserving an existing
## hand-authored layer when the editor placed nothing. Returns the count of non-empty
## cells. Mirrors _write_interactables_layer's non-destructive guard.
func _write_utilities_layer(data: Dictionary) -> int:
	var count := 0
	var rows: Array = []
	for z in range(_utilities.size()):
		var src: Array = _utilities[z]
		var row: Array = []
		for x in range(src.size()):
			var tok := str(src[x])
			if tok.strip_edges() != "" and tok.strip_edges() != " ":
				count += 1
				row.append(tok)
			else:
				row.append(" ")
		rows.append(row)
	var has_existing: bool = data.has("layers") and (data["layers"] is Dictionary) and bool(data["layers"].has("utilities"))
	if count > 0 or not has_existing:
		if not data.has("layers") or not (data["layers"] is Dictionary):
			data["layers"] = {}
		data["layers"]["utilities"] = rows
	return count


## Merge painted biome fields into top-level paint_layers[]. Authored elements
## replace their existing layer; untouched layers are kept. Returns layers written.
func _write_paint_layers(data: Dictionary) -> int:
	var authored := _biome_paint_layers()
	if authored.is_empty():
		return 0
	var authored_elements: Dictionary = {}
	for layer in authored:
		authored_elements[str(layer.get("element", ""))] = true
	var existing: Array = data.get("paint_layers", []) if (data.get("paint_layers") is Array) else []
	var kept: Array = []
	for layer in existing:
		if layer is Dictionary and not authored_elements.has(str(layer.get("element", ""))):
			kept.append(layer)
	kept.append_array(authored)
	data["paint_layers"] = kept
	return authored.size()


# ── HUD refresh ─────────────────────────────────────────────────────────
func _update_hud() -> void:
	if _ctx_lbl == null:
		return
	var map_show := _loaded_map if _loaded_map != "" else "SYNTHETIC"
	_ctx_lbl.text = "%s    ·    %d×%d    ·    maxH %d    ·    [%s]" % [map_show, _grid_w, _grid_d, _grid_max_h, _active_tab]
	# Active tool line — per tab.
	var save_hint := "   ·   W save→repo" if _loaded_map != "" else ""
	if _active_tab == "ARTIFACTS":
		var sel := _selected_artifact()
		var move_tag := "  [MOVE]" if _artifact_move_mode else ""
		if _artifact_move_picked:
			move_tag = "  [MOVE: holding '%s']" % _artifact_move_token
		if _artifact_list.is_empty():
			_tool_lbl.text = "ARTIFACTS · no map-ready artifacts in the catalog"
			_tool_lbl.add_theme_color_override("font_color", C_BAD)
		else:
			_tool_lbl.text = "ARTIFACTS · %s   (%d/%d)%s" % [sel, _artifact_idx + 1, _artifact_list.size(), move_tag]
			_tool_lbl.add_theme_color_override("font_color", C_GOLD)
		_controls_lbl.text = "PREV/NEXT cycle   ·   L-click place   ·   MOVE pick→drop   ·   R-click remove   ·   Esc cancel   ·   Tab panel%s" % save_hint
	elif _active_tab == "UTILITY":
		var move_tag2 := ""
		if _util_move_picked:
			move_tag2 = "  [MOVE: holding '%s']" % _util_move_token
		_tool_lbl.text = "UTILITY · %s (%s)   ·   op %s%s" % [_util_friendly_name(_util_code), _util_code, _util_op, move_tag2]
		_tool_lbl.add_theme_color_override("font_color", Color(0.85, 0.5, 0.95))
		_controls_lbl.text = "L-click apply op   ·   type+op in panel   ·   R-click remove   ·   Esc cancel   ·   R-drag orbit   ·   Tab panel%s" % save_hint
	elif _active_tab == "BIOME":
		var el := _active_biome_element()
		if el == "":
			_tool_lbl.text = "BIOME · pick an element to paint"
			_tool_lbl.add_theme_color_override("font_color", C_DIM)
		else:
			_tool_lbl.text = "BIOME · %s   ·   radius %d   ·   pressure %.1f" % [el.to_upper(), _brush_radius, _brush_strength]
			_tool_lbl.add_theme_color_override("font_color", _biome_color(el))
		_controls_lbl.text = "L-drag paint   ·   Shift erase   ·   R-drag orbit   ·   element/size/pressure in panel   ·   Tab panel%s" % save_hint
	elif _active_mode == TOOL_PAINT:
		_tool_lbl.text = "PAINT · %s   ·   brush %dx%d   ·   #%s" % [
			_active_paint_op.to_upper(), _active_brush_size, _active_brush_size, _active_color.to_html(false)]
		_tool_lbl.add_theme_color_override("font_color", _active_color)
		_controls_lbl.text = "L-drag apply   ·   R-drag orbit   ·   wheel zoom   ·   WASD/QE fly   ·   Ctrl+Z undo   ·   Tab panel%s" % save_hint
	else:
		_tool_lbl.text = "GRID · %s   ·   brush %dx%d   ·   level %d" % [
			_active_grid_op.to_upper(), _active_brush_size, _active_brush_size, _active_level]
		_tool_lbl.add_theme_color_override("font_color", C_TEXT)
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

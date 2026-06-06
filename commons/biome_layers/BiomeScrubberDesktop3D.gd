extends Node3D
## BiomeScrubberDesktop3D — scrub AND inspect the biome accrual stack.
##
## Two questions this tool answers:
##   1. WALK  — step map-to-map through the spine; each map's biome builds on the
##      maps before it in its sequence (sequence accrual). [ / ] walk maps.
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
##   ] / →  next map       [ / ←  prev map       - / =  first/last    1-9,0  map in seq
##   ↑ / ↓  select layer    Space  toggle layer    S  solo selected    A  all on
##   R  reset to progression    Tab  hide/show panel    R-drag orbit    wheel zoom
##   B  brush element (ground→tree→critter→…→off)   L-drag  paint   E  erase
##   , / .  brush size    ; / '  pressure    C  clear    W  save brush+overrides → map
##
## CLI (headless):
##   --stage=N            start stage
##   --shot=<path>        screenshot to <path>, quit
##   --contact-sheet=<b>  <b>_01..19.png — accrual at each stage
##   --solo-sheet=<b>     <b>_<kind>.png — each layer ALONE at max stage
##   --solo=<kind>        one shot of a single layer alone
##   --dims=N             synthetic grid size (default 20)
##   --paint=el:mode:d[:scale:thr]  inject a paint layer to test a distribution,
##                        e.g. --paint=tree:plane:0.6  --paint=flower:noise:0.8:0.25:0.4
##                        (a loaded map's own paint_layers render automatically)

const MIN_STAGE := 1
const MAX_STAGE := 19
# Reuse the VR brush menu (element grid + size + pressure sliders) as the
# desktop's right-side brush-settings panel — one menu, both editors.
const BrushMenuScene = preload("res://commons/hazards/becoming_catalyst/biome_brush_menu_ui.tscn")
# Sequence accrual: a map's biome builds on the maps before it. Applied here too
# (the scrubber builds the accrual directly, not via GridSystem) so walking
# map-to-map shows the biome thicken across a sequence. See sequence_accrual.gd.
const SequenceAccrualLib = preload("res://commons/biome_layers/sequence_accrual.gd")
const BiomeElementsLib = preload("res://commons/biome_layers/biome_elements.gd")
const DistributionFieldLib = preload("res://commons/biome_layers/distribution_field.gd")
const ArtifactPaletteLib = preload("res://commons/biome_layers/artifact_palette.gd")
@export var grid_size: int = 20          # synthetic default (square)
@export var cube_size: float = 1.0
@export var auto_spin: bool = false   # OFF — a spinning scene fights painting (R-drag still orbits)
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
# Map-to-map walk: the scrubber steps through the ordered curriculum maps
# (EcosystemManager.get_ordered_map_list) rather than abstract sequence stages.
var _all_maps: Array = []                # ordered map names across the whole spine
var _map_index: int = -1                 # position in _all_maps; -1 = synthetic / off-list
var _eco: Node = null                    # EcosystemManager (cached: map list + accrual)
var _map_paint: Array = []               # the map's biome_paint layer
var _map_paint_layers: Array = []        # the map's paint_layers[] (distribution authoring)
var _cli_paint: Array = []               # --paint synthetic layers (override map's, for quick tests)
var _stage_explicit: bool = false        # true if --stage given (allows >MAX for lab dispatcher@99)
var _map_data: Dictionary = {}           # full parsed map_data.json (for write-back)
var _map_overrides: Dictionary = {}      # settings.biome_overrides from the map
var _status_msg: String = ""             # transient HUD line (e.g. "saved")

var _accrual: Node = null
var _host: Node3D = null
var _camera: Camera3D = null
var _hud: Label = null               # error overlay only (normal info → labels below)
var _perf: Label = null
var _perf_panel: PanelContainer = null
var _panel: VBoxContainer = null
var _panel_root: Control = null
# Header labels (replace the old single cramped multi-line label).
var _title_lbl: Label = null
var _stage_big: Label = null
var _seq_lbl: Label = null
var _truth_lbl: Label = null
var _controls_lbl: Label = null
var _toast_lbl: Label = null
# Stage timeline — the signature "scrubber" widget: 19 ticks, filled to the
# current stage. Built once, recoloured on every stage change.
var _timeline: HBoxContainer = null
var _tick_rects: Array = []          # Array[ColorRect], one per stage 1..MAX
# Brush painting (step 3) — left-drag paints a per-cell density field for the
# active element; the wired spawn layers place by it; W saves to the map.
var _paint_elements: Array = BiomeElementsLib.NAMES   # single source of truth (BiomeElements)
var _paint_idx: int = -1             # -1 = not painting; else index into _paint_elements
var _brush_fields: Dictionary = {}   # element -> PackedFloat32Array (grid_w*grid_d)
var _brush_radius: int = 2
var _brush_strength: float = 0.6
var _brush_erase: bool = false
var _painting: bool = false
var _brush_dirty: bool = false       # set while dragging; triggers rebuild on release
# Stroke-level undo/redo: each entry is a deep snapshot of _brush_fields, pushed at
# stroke-start + before a clear. Ctrl+Z / Ctrl+Y. Capped so it can't grow unbounded.
var _undo_stack: Array = []
var _redo_stack: Array = []
const UNDO_CAP := 30
# Distribution mode per element (M cycles the active one). "brush" = hand-painted
# mask; the others fill the whole grid by the engine's distribution — reaching the
# noise/curve/plane/random the brush alone can't gesture. See doc/PAINT_LAYERS.md.
const PAINT_MODES: Array = ["brush", "noise", "curve", "plane", "random", "fractal"]
var _element_mode: Dictionary = {}   # element -> mode (absent = "brush")
# Per-element artifact list (the picker, toggled with O). When non-empty, the
# element's emitted layer carries `artifacts: [...]` → object_scatter scatters them
# (picked per placement) by the layer's distribution, instead of the morphology.
var _element_artifacts: Dictionary = {}   # element -> Array[name]
var _picker_root: PanelContainer = null
var _picker_filter: LineEdit = null
var _picker_list: VBoxContainer = null
var _picker_header: Label = null
var _picker_sel: Label = null
var _picker_visible: bool = false
var _brush_overlay: MultiMeshInstance3D = null
var _brush_menu_ui: Control = null   # right-side brush-settings panel (reused VR menu)
var _brushtest: String = ""          # --brushtest=<element> headless proof
var _brushsave: bool = false         # --brushsave: save after brushtest (headless save proof)
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
	# Build the ordered map list so ]/[ walk the curriculum map-to-map.
	_eco = get_node_or_null("/root/EcosystemManager")
	if _eco and _eco.has_method("get_ordered_map_list"):
		_all_maps = _eco.get_ordered_map_list()
	if _loaded_map != "":
		_map_index = _all_maps.find(_loaded_map)
	var span := float(maxi(grid_w, grid_d))
	_orbit_center = Vector3(float(grid_w) * cube_size * 0.5, 1.5, float(grid_d) * cube_size * 0.5)
	_orbit_radius = span * cube_size * 1.05

	_build_environment()
	_build_light()
	_build_floor()
	_build_camera()
	_build_ui()
	_build_brush_overlay()

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

	# Headless brush proof: stamp a disc, rebuild, then fall through to capture.
	if _brushtest != "":
		_apply_brushtest(_brushtest)
		if _brushsave:
			_save_overrides()

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
		elif a.begins_with("--paint="): _add_cli_paint(a.split("=", true, 1)[1])
		elif a.begins_with("--brushtest="): _brushtest = a.split("=", true, 1)[1]
		elif a == "--brushsave": _brushsave = true


## --paint=element:mode:density[:scale:threshold] — inject a synthetic paint
## layer for quick distribution testing without editing a map. Repeatable.
## e.g. --paint=tree:plane:0.6   --paint=flower:noise:0.8:0.25:0.4
func _add_cli_paint(spec: String) -> void:
	var parts := spec.split(":")
	if parts.size() < 2:
		return
	var layer := {"element": str(parts[0]), "mode": str(parts[1])}
	if parts.size() >= 3:
		layer["density"] = float(parts[2])
	match str(parts[1]):
		"noise":
			if parts.size() >= 4: layer["scale"] = float(parts[3])
			if parts.size() >= 5: layer["threshold"] = float(parts[4])
		"curve":
			layer["axis"] = str(parts[3]) if parts.size() >= 4 else "radial"
			layer["falloff"] = str(parts[4]) if parts.size() >= 5 else "smooth"
	_cli_paint.append(layer)


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
	# paint_layers[] is top-level (distribution authoring), not under layers.
	var pl = data.get("paint_layers", [])
	if pl is Array:
		_map_paint_layers = pl
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
		# Seed parity: match GridSystem's hash(map_name) so the scrubber preview is
		# the SAME arrangement the game renders. Synthetic mode keeps a fixed seed.
		"rng_seed": (hash(_loaded_map) if _loaded_map != "" else 0xB10E),
		"map_name": _loaded_map if _loaded_map != "" else "BiomeScrubber",
		"biome_paint": _map_paint,
		"stage_order": _stage,
		# Pass only the map's PARAM overrides live — disable + stage are
		# driven by the scrubber's own mechanisms (enable_layer / override).
		"biome_overrides": {"params": _map_overrides.get("params", {})},
		# Paint layers: brush fields + (--paint synthetic | the map's); the wired
		# spawn layers (tree/critter/flower) place by these distributions.
		"paint_layers": _effective_paint_layers(),
		"budget_scale": 1.0,
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


# ── Map-to-map walk (primary navigation) ──────────────────────────────
## Step to map `index` in the spine-ordered list: load its real grid + paint +
## sequence (which drives the stage), re-centre the view, and rebuild with
## sequence accrual so the biome's build-up across the sequence is visible.
func _goto_map(index: int) -> void:
	if _all_maps.is_empty():
		# No map list (e.g. EcosystemManager absent) — fall back to stage stepping.
		_set_stage(_stage + (1 if index > _map_index else -1))
		return
	var target := clampi(index, 0, _all_maps.size() - 1)
	if target == _map_index:
		return
	_map_index = target
	# A different map → its own brush-in-progress no longer applies; the map's
	# saved paint_layers load from disk. Clear the live brush so we don't smear
	# one map's strokes (sized to its grid) onto the next.
	_brush_fields.clear()
	_paint_idx = -1
	_stage_explicit = false   # let the new map's sequence drive the stage
	_load_map(str(_all_maps[_map_index]))
	_stage = start_stage if _stage_explicit else clampi(start_stage, MIN_STAGE, MAX_STAGE)
	_recenter_for_grid()
	_rebuild()


## Jump to the Nth map (1-based) of the current map's sequence — quick hop within
## a sequence while staying map-based.
func _goto_map_in_current_sequence(n: int) -> void:
	if _eco == null or _map_seq == "" or not _eco.has_method("get_sequence_maps"):
		return
	var seq_maps: Array = _eco.get_sequence_maps(_map_seq)
	if n >= 1 and n <= seq_maps.size():
		var gi: int = _all_maps.find(str(seq_maps[n - 1]))
		if gi >= 0:
			_goto_map(gi)


## Grid dims differ between maps → re-centre the orbit and rebuild the grid-sized
## visuals (reference floor + brush overlay).
func _recenter_for_grid() -> void:
	_orbit_center = Vector3(float(grid_w) * cube_size * 0.5, 1.5, float(grid_d) * cube_size * 0.5)
	_orbit_radius = float(maxi(grid_w, grid_d)) * cube_size * 1.05
	var old_floor := get_node_or_null("ReferenceFloor")
	if old_floor:
		old_floor.free()
	_build_floor()
	var old_overlay := get_node_or_null("BrushOverlay")
	if old_overlay:
		old_overlay.free()
	_build_brush_overlay()


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
	# Only persist a DELIBERATE stage override — not the map's natural sequence
	# stage (which map-walk derives into _stage). Writing it unconditionally pinned
	# every saved map to a fixed stage, desyncing it from curriculum reordering.
	if _stage != start_stage:
		ov["stage_order"] = _stage
	# Preserve param/add overrides that the scrubber doesn't edit yet.
	if _map_overrides.has("params"):
		ov["params"] = _map_overrides["params"]
	if _map_overrides.has("add"):
		ov["add"] = _map_overrides["add"]
	var settings: Dictionary = _map_data.get("settings", {})
	settings["biome_overrides"] = ov
	_map_data["settings"] = settings
	# Persist the authored layers into the map's top-level paint_layers[]: brush
	# fields, distribution modes, and picked artifact lists. An authored element
	# replaces any existing layer for it; other layers are preserved.
	var authored: Dictionary = {}
	for el in _brush_fields:
		authored[el] = true
	for el in _element_mode:
		if _mode_of(el) != "brush":
			authored[el] = true
	for el in _element_artifacts:
		if not (_element_artifacts[el] as Array).is_empty():
			authored[el] = true
	if not authored.is_empty():
		var existing: Array = _map_data.get("paint_layers", []) if (_map_data.get("paint_layers") is Array) else []
		var kept: Array = []
		for layer in existing:
			if layer is Dictionary and not authored.has(str(layer.get("element", ""))):
				kept.append(layer)
		for el in authored:
			var gl: Dictionary
			if _brush_fields.has(el) and _mode_of(el) == "brush":
				gl = {"element": el, "mode": "brush", "density": 1.0, "brush": _field_to_brush(_brush_fields[el])}
				if el == "ground":
					gl["height"] = 1.5
				elif el == "shader":
					var c := _element_color(el)
					gl["color"] = [c.r, c.g, c.b]
			else:
				gl = _distribution_layer(el, _mode_of(el))
			_attach_artifacts(gl, el)
			kept.append(gl)
		_map_data["paint_layers"] = kept
	var path := "res://commons/maps/%s/map_data.json" % _loaded_map
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_status_msg = "SAVE FAILED (read-only?): %s" % path
		_update_hud()
		push_warning("BiomeScrubber: could not write %s" % path)
		return
	f.store_string(JSON.stringify(_map_data, "\t"))
	f.close()
	SequenceAccrualLib.invalidate(_loaded_map)   # this map's accrual cache is now stale
	_map_overrides = ov
	_status_msg = "✓ saved → %s  (disable=%d, stage=%d, brush=%d)" % [_loaded_map, dis.size(), _stage, _brush_fields.size()]
	_update_hud()
	print("[scrubber] saved overrides to %s: %s" % [_loaded_map, str(ov)])


# ── HUD + side panel ──────────────────────────────────────────────────
## "map 2/10  ·  #14/503" — position within the current sequence and overall.
func _map_position_text() -> String:
	if _loaded_map == "" or _eco == null:
		return ""
	var seq_maps: Array = _eco.get_sequence_maps(_map_seq) if _eco.has_method("get_sequence_maps") else []
	var local: int = seq_maps.find(_loaded_map) + 1
	var glob: int = _map_index + 1
	if local >= 1 and seq_maps.size() > 0:
		return "map %d/%d  ·  #%d/%d" % [local, seq_maps.size(), glob, _all_maps.size()]
	if glob >= 1:
		return "#%d/%d" % [glob, _all_maps.size()]
	return ""


func _update_hud() -> void:
	if _stage_big == null:
		return
	var seq_name := _seq_of_kind_for_stage()
	var truth := _truth_for_stage()
	var on := 0
	for k in _active_kinds:
		if not _disabled.has(k): on += 1
	# Big stage readout.
	_stage_big.text = _loaded_map if _loaded_map != "" else ("SYNTHETIC · STAGE %d" % _stage)
	# Context line: sequence · map position · stage · grid · paint.
	var where := "%d×%d" % [grid_w, grid_d]
	var seq_show := _map_seq if _map_seq != "" else (seq_name if seq_name != "?" else "—")
	var pos := _map_position_text()
	var pos_tag := ("    ·    %s" % pos) if pos != "" else ""
	var stage_tag := "    ·    stage %d" % _stage
	var active_paint: Array = _cli_paint if not _cli_paint.is_empty() else _map_paint_layers
	var paint_tag := "    ·    🖌 %d paint" % active_paint.size() if active_paint.size() > 0 else ""
	_seq_lbl.text = "%s%s%s    ·    %d/%d layers    ·    %s%s" % [seq_show, pos_tag, stage_tag, on, _active_kinds.size(), where, paint_tag]
	# Truth quote.
	_truth_lbl.text = ("“%s”" % truth) if truth != "" else ""
	# Controls footer — brush controls when a paint element is active.
	if _paint_idx >= 0:
		var el: String = _paint_elements[_paint_idx]
		var art_n: int = _element_artifacts.get(el, []).size()
		var art_tag: String = ("  · %d artifacts" % art_n) if art_n > 0 else ""
		_controls_lbl.text = "🖌 PAINT %s · %s%s  (size %d · pressure %.1f%s)   L-drag · Shift erase · M mode · O artifacts · Ctrl+Z undo · B element · , . size · C clear · W save" % [
			el.to_upper(), _mode_of(el).to_upper(), art_tag, _brush_radius, _brush_strength, "  · ERASE" if _brush_erase else ""]
		_controls_lbl.add_theme_color_override("font_color", _element_color(el))
	else:
		var save_hint := "      W save→map" if _loaded_map != "" else ""
		_controls_lbl.text = "[ / ] map    - = first/last    1-9 map in seq    ↑↓ select    Space toggle    S solo    A all    B brush    Tab panel%s" % save_hint
		_controls_lbl.add_theme_color_override("font_color", C_DIM)
	# Transient toast.
	_toast_lbl.text = _status_msg
	_recolor_timeline()


## Colour the 19 timeline ticks: past = teal, current = gold, future = dim.
func _recolor_timeline() -> void:
	if _tick_rects.is_empty():
		return
	var cur := clampi(_stage, MIN_STAGE, MAX_STAGE)
	for i in range(_tick_rects.size()):
		var s := i + MIN_STAGE
		var rect: ColorRect = _tick_rects[i]
		if s == cur:
			rect.color = C_GOLD
		elif s < cur:
			rect.color = C_ACCENT
		else:
			rect.color = Color(0.20, 0.23, 0.29, 0.9)


## A readable colour family per layer, grouped by what the layer spawns —
## so the inspector dots visually map to the kingdoms on screen.
func _kind_color(kind: String) -> Color:
	match kind:
		"floating_primitives", "floating_points", "animated_primitives", "ambient_particles":
			return Color(0.55, 0.70, 1.0)    # abstract / ambient motes — blue
		"color_tint":
			return Color(0.90, 0.62, 1.0)    # spectrum — violet
		"force_field", "lattice_snap", "wave_displace", "jitter_seed", "noise_dust":
			return Color(0.66, 0.78, 0.94)   # field transforms — pale blue
		"ca_surface":
			return Color(0.80, 0.55, 0.95)   # fungus/CA — purple
		"fractal_bloom", "softbody_flora":
			return Color(1.0, 0.55, 0.76)    # flower — pink
		"lsystem_trees", "ground_ring":
			return Color(0.45, 0.85, 0.50)   # tree/ground — green
		"dna_creatures", "swarm_creatures", "adaptive_behavior":
			return Color(1.0, 0.70, 0.36)    # creatures — orange
		"paradox_zones", "tunable_field", "critical_overlay", "graph_connections", "biome_paint_dispatcher":
			return Color(0.55, 0.92, 0.95)   # qfep/late — teal
	return Color(0.60, 0.63, 0.70)


func _refresh_panel() -> void:
	if _panel == null: return
	for c in _panel.get_children():
		c.queue_free()
	_mk_label(_panel, "LAYERS", 13, C_ACCENT)
	_mk_label(_panel, "↑↓ select · Space toggle · S solo", 11, C_DIM)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	_panel.add_child(spacer)

	for i in range(_active_kinds.size()):
		var k: String = _active_kinds[i]
		var order: int = _order_of_kind.get(k, 0)
		var seq: String = _seq_of_kind.get(k, "")
		var off := _disabled.has(k)
		var sel := (i == _selected)

		# Row wrapper — selected row gets a faint gold highlight bar.
		var rowp := PanelContainer.new()
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color(1.0, 0.78, 0.35, 0.15) if sel else Color(0, 0, 0, 0)
		rsb.content_margin_left = 6; rsb.content_margin_right = 6
		rsb.content_margin_top = 3;  rsb.content_margin_bottom = 3
		if sel:
			rsb.corner_radius_top_left = 4; rsb.corner_radius_top_right = 4
			rsb.corner_radius_bottom_left = 4; rsb.corner_radius_bottom_right = 4
		rowp.add_theme_stylebox_override("panel", rsb)
		rowp.tooltip_text = seq
		_panel.add_child(rowp)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		rowp.add_child(row)

		# Kingdom colour dot (dimmed when the layer is off).
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var kc := _kind_color(k)
		dot.color = kc if not off else Color(kc.r, kc.g, kc.b, 0.25)
		row.add_child(dot)

		# Order badge.
		_mk_label(row, "%02d" % order, 12, C_DIM)

		# Layer name — fills, gold when selected, dim when off.
		var nm := _mk_label(row, k, 13, C_DIM if off else C_TEXT)
		if sel:
			nm.add_theme_color_override("font_color", C_GOLD)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# On/off state pill.
		_mk_label(row, "ON" if not off else "off", 11, C_GOOD if not off else C_DIM)


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
			KEY_BRACKETRIGHT, KEY_RIGHT: _goto_map((_map_index + 1) if _map_index >= 0 else 0)
			KEY_BRACKETLEFT, KEY_LEFT:   _goto_map((_map_index - 1) if _map_index > 0 else 0)
			KEY_MINUS:  _goto_map(0)
			KEY_EQUAL:  _goto_map(_all_maps.size() - 1)
			KEY_UP:     _select(-1)
			KEY_DOWN:   _select(1)
			KEY_SPACE:  _toggle_selected()
			KEY_S:      _solo_selected()
			KEY_A:      _all_on()
			KEY_W:      _save_overrides()
			KEY_B:      _cycle_paint_element()
			KEY_M:      _cycle_paint_mode()
			KEY_O:      _toggle_picker()
			KEY_ESCAPE:
				if _picker_visible: _toggle_picker()
			KEY_E:
				_brush_erase = not _brush_erase
				_update_hud()
			KEY_Z:
				if event.ctrl_pressed and event.shift_pressed: _redo()
				elif event.ctrl_pressed: _undo()
			KEY_Y:
				if event.ctrl_pressed: _redo()
			KEY_C:
				if _paint_idx >= 0:
					_push_undo()
					_brush_fields.erase(_paint_elements[_paint_idx])
					_update_brush_overlay()
					_rebuild()
			KEY_COMMA:  _brush_radius = maxi(0, _brush_radius - 1); _update_hud()
			KEY_PERIOD: _brush_radius = mini(8, _brush_radius + 1); _update_hud()
			KEY_SEMICOLON:  _brush_strength = clampf(_brush_strength - 0.1, 0.1, 1.0); _update_hud()
			KEY_APOSTROPHE: _brush_strength = clampf(_brush_strength + 0.1, 0.1, 1.0); _update_hud()
			KEY_TAB:
				if _panel_root: _panel_root.visible = not _panel_root.visible
			KEY_R:
				if _accrual.has_method("reset_overrides"): _accrual.reset_overrides()
				_disabled.clear(); _rebuild()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				_goto_map_in_current_sequence(event.keycode - KEY_0)
			KEY_0: _goto_map_in_current_sequence(10)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and _paint_idx >= 0:
			# Left-drag paints the active element's brush; rebuild on release.
			_painting = event.pressed
			if event.pressed:
				_push_undo()                 # snapshot before the stroke (for Ctrl+Z)
				_paint_at_mouse()
			elif _brush_dirty:
				_brush_dirty = false
				_rebuild()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_radius = maxf(2.0, _orbit_radius - 1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_radius += 1.5
	elif event is InputEventMouseMotion:
		if _painting:
			_paint_at_mouse()
		elif _dragging:
			_orbit_yaw -= event.relative.x * 0.006
			_orbit_pitch = clampf(_orbit_pitch - event.relative.y * 0.006, -1.4, -0.05)


func _select(delta: int) -> void:
	if _active_kinds.is_empty(): return
	_selected = wrapi(_selected + delta, 0, _active_kinds.size())
	_refresh_panel()
	_update_hud()


# ── Per-frame camera orbit + capture countdown ───────────────────────
func _process(delta: float) -> void:
	# Never auto-spin while painting (a moving target is unpaintable).
	if auto_spin and not _dragging and _paint_idx < 0:
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
		_perf.text = "▮ %s draw calls     %s objects     %s prims" % [_commafy(dc), _commafy(obj), _commafy(prim)]
		# Threshold colour — VR wants low draw calls, so flag heavy stages.
		var col := C_GOOD
		if dc >= 200: col = C_BAD
		elif dc >= 80: col = C_WARN
		_perf.add_theme_color_override("font_color", col)
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


## Palette — one place so the whole HUD reads as a designed surface.
const C_BG       := Color(0.05, 0.06, 0.09, 0.86)
const C_BG_SOFT  := Color(0.08, 0.10, 0.14, 0.78)
const C_ACCENT   := Color(0.42, 0.86, 0.95)   # teal — brand
const C_TEXT     := Color(0.93, 0.96, 1.0)
const C_DIM      := Color(0.58, 0.63, 0.72)
const C_GOLD     := Color(1.0, 0.78, 0.35)    # selection
const C_GOOD     := Color(0.50, 0.95, 0.62)
const C_WARN     := Color(1.0, 0.80, 0.35)
const C_BAD      := Color(1.0, 0.45, 0.42)
const PANEL_W    := 332.0
const BAR_H      := 128.0


func _new_stylebox(bg: Color, accent_border_bottom := 0.0, radius := 0.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.content_margin_left = 12; sb.content_margin_right = 12
	sb.content_margin_top = 9;  sb.content_margin_bottom = 9
	if radius > 0.0:
		sb.corner_radius_top_left = int(radius); sb.corner_radius_top_right = int(radius)
		sb.corner_radius_bottom_left = int(radius); sb.corner_radius_bottom_right = int(radius)
	if accent_border_bottom > 0.0:
		sb.border_width_bottom = int(accent_border_bottom)
		sb.border_color = C_ACCENT
	return sb


func _mk_label(parent: Node, txt: String, size: int, col: Color, pos := Vector2.ZERO) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	# ── Top bar ───────────────────────────────────────────────────────
	var bar := Panel.new()
	bar.anchor_right = 1.0
	bar.offset_bottom = BAR_H
	bar.add_theme_stylebox_override("panel", _new_stylebox(C_BG, 2.0))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bar)

	# Brand (top-left) + context (top-right, right-aligned clear of the panel).
	_title_lbl = _mk_label(layer, "◆  BIOME  SCRUBBER", 12, C_ACCENT, Vector2(20, 11))
	_seq_lbl = _mk_label(layer, "", 13, C_DIM, Vector2(0, 11))
	_seq_lbl.anchor_right = 1.0
	_seq_lbl.offset_right = -(PANEL_W + 24.0)
	_seq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Big stage readout, its own row below the brand.
	_stage_big = _mk_label(layer, "STAGE 1", 28, C_TEXT, Vector2(18, 30))

	# Stage timeline — 19 ticks filling the bar width, recoloured per stage.
	_timeline = HBoxContainer.new()
	_timeline.anchor_right = 1.0
	_timeline.offset_left = 20.0
	_timeline.offset_right = -20.0
	_timeline.offset_top = 74.0
	_timeline.offset_bottom = 90.0
	_timeline.add_theme_constant_override("separation", 3)
	_timeline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_timeline)
	_tick_rects.clear()
	for i in range(MIN_STAGE, MAX_STAGE + 1):
		var tick := ColorRect.new()
		tick.custom_minimum_size = Vector2(0, 14)
		tick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_timeline.add_child(tick)
		_tick_rects.append(tick)

	# Truth quote — dim line INSIDE the bar (so it stays readable over a bright
	# biome), below the timeline, spanning nearly the full width.
	_truth_lbl = _mk_label(layer, "", 14, C_DIM, Vector2(20, 96))
	_truth_lbl.anchor_right = 1.0
	_truth_lbl.offset_right = -24.0
	_truth_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Controls footer — dim, bottom strip.
	_controls_lbl = _mk_label(layer, "", 13, C_DIM)
	_controls_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_controls_lbl.offset_left = 20.0
	_controls_lbl.offset_top = -26.0

	# Transient toast (e.g. "✓ saved") — near the footer, gold.
	_toast_lbl = _mk_label(layer, "", 14, C_GOLD)
	_toast_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_toast_lbl.offset_left = 20.0
	_toast_lbl.offset_top = -48.0

	# ── Live perf readout (bottom-left panel) ─────────────────────────
	# The point of a perf tool: see the cost as you scrub. Draw calls are
	# threshold-coloured (green/amber/red) so a heavy stage is obvious.
	_perf_panel = PanelContainer.new()
	_perf_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_perf_panel.offset_left = 14.0
	_perf_panel.offset_top = -84.0
	_perf_panel.add_theme_stylebox_override("panel", _new_stylebox(C_BG_SOFT, 0.0, 6.0))
	_perf_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_perf_panel)
	_perf = Label.new()
	_perf.add_theme_font_size_override("font_size", 14)
	_perf.add_theme_color_override("font_color", C_GOOD)
	_perf_panel.add_child(_perf)

	# ── LEFT-side layer panel (moved from the right to make room for the
	#    brush-settings menu) ──────────────────────────────────────────
	_panel_root = PanelContainer.new()
	_panel_root.anchor_left = 0.0
	_panel_root.anchor_right = 0.0
	_panel_root.anchor_top = 0.0
	_panel_root.offset_left = 8.0
	_panel_root.offset_top = BAR_H + 8.0
	_panel_root.offset_right = 8.0 + PANEL_W
	_panel_root.add_theme_stylebox_override("panel", _new_stylebox(C_BG, 0.0, 8.0))
	layer.add_child(_panel_root)
	_panel = VBoxContainer.new()
	_panel.add_theme_constant_override("separation", 3)
	_panel_root.add_child(_panel)

	# ── Right-side BRUSH SETTINGS menu (reused VR menu: element grid +
	#    size + pressure). The pointer selects; signals drive the brush. ──
	var brush_wrap := Control.new()
	brush_wrap.anchor_left = 1.0; brush_wrap.anchor_right = 1.0
	brush_wrap.anchor_top = 0.0; brush_wrap.anchor_bottom = 1.0
	brush_wrap.offset_left = -498.0
	brush_wrap.offset_top = BAR_H + 8.0
	brush_wrap.offset_right = -8.0
	brush_wrap.offset_bottom = -8.0
	layer.add_child(brush_wrap)
	_brush_menu_ui = BrushMenuScene.instantiate()
	brush_wrap.add_child(_brush_menu_ui)
	if _brush_menu_ui.has_signal("element_selected"):
		_brush_menu_ui.element_selected.connect(_on_menu_element)
	if _brush_menu_ui.has_signal("size_changed"):
		_brush_menu_ui.size_changed.connect(_on_menu_size)
	if _brush_menu_ui.has_signal("pressure_changed"):
		_brush_menu_ui.pressure_changed.connect(_on_menu_pressure)

	_build_picker(layer)

	# Error overlay label (normally hidden) — used only when an autoload
	# is missing, before the info labels have anything to show.
	_hud = _mk_label(layer, "", 15, C_BAD, Vector2(20, BAR_H + 8))


# ── Brush painting (step 3) ──────────────────────────────────────────
## A flat grid of per-cell quads over the ground; alpha = the active element's
## brush density. Built once, recoloured as you paint.
# ── Artifact picker (O) — compose the active element's artifact list ──────
func _build_picker(layer: CanvasLayer) -> void:
	_picker_root = PanelContainer.new()
	_picker_root.anchor_left = 0.5; _picker_root.anchor_right = 0.5
	_picker_root.anchor_top = 1.0;  _picker_root.anchor_bottom = 1.0
	_picker_root.offset_left = -280.0; _picker_root.offset_right = 280.0
	_picker_root.offset_top = -382.0;  _picker_root.offset_bottom = -18.0
	_picker_root.add_theme_stylebox_override("panel", _new_stylebox(C_BG, 0.0, 8.0))
	_picker_root.visible = false
	layer.add_child(_picker_root)
	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 10)
	_picker_root.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	margin.add_child(vb)
	_picker_header = _mk_label(vb, "ARTIFACTS", 14, C_ACCENT)
	_picker_filter = LineEdit.new()
	_picker_filter.placeholder_text = "filter artifacts…"
	_picker_filter.custom_minimum_size = Vector2(520, 28)
	_picker_filter.text_changed.connect(_on_picker_filter_changed)
	vb.add_child(_picker_filter)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	_picker_list = VBoxContainer.new()
	_picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_picker_list)
	_picker_sel = _mk_label(vb, "", 11, C_DIM)


func _active_paint_element() -> String:
	return str(_paint_elements[_paint_idx]) if _paint_idx >= 0 else "object"


func _toggle_picker() -> void:
	_picker_visible = not _picker_visible
	if _picker_root:
		_picker_root.visible = _picker_visible
	if _picker_visible:
		_refresh_picker()
		if _picker_filter:
			_picker_filter.grab_focus()


func _on_picker_filter_changed(_t: String) -> void:
	_refresh_picker()


## Rebuild the filtered artifact list (the unlocked palette at this stage, narrowed
## by the filter), marking the ones already in the active element's list.
func _refresh_picker() -> void:
	if _picker_root == null or not _picker_visible:
		return
	var el := _active_paint_element()
	_picker_header.text = "ARTIFACTS  ·  %s   (click toggles · O/Esc closes)" % el.to_upper()
	for c in _picker_list.get_children():
		c.queue_free()
	var sel: Array = _element_artifacts.get(el, [])
	var q := _picker_filter.text.strip_edges().to_lower()
	var avail: Array = ArtifactPaletteLib.available(_stage)
	var shown := 0
	for raw in avail:
		if shown >= 50:
			break
		var nm := str(raw)
		if q != "" and not nm.to_lower().contains(q):
			continue
		var b := Button.new()
		b.text = ("✓  " if nm in sel else "+  ") + nm
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", C_GOLD if nm in sel else C_TEXT)
		b.pressed.connect(_on_pick_artifact.bind(nm))
		_picker_list.add_child(b)
		shown += 1
	_picker_sel.text = "%s list: %d selected   ·   showing %d / %d unlocked @stage %d" % [el, sel.size(), shown, avail.size(), _stage]


func _on_pick_artifact(nm: String) -> void:
	var el := _active_paint_element()
	var lst: Array = _element_artifacts.get(el, [])
	if nm in lst:
		lst.erase(nm)
	else:
		lst.append(nm)
	_element_artifacts[el] = lst
	_refresh_picker()
	_rebuild()


## Attach the active artifact list (if any) to an emitted paint layer, so
## object_scatter places those artifacts instead of the element's morphology.
func _attach_artifacts(layer: Dictionary, el: String) -> void:
	var lst: Array = _element_artifacts.get(el, [])
	if not lst.is_empty():
		layer["artifacts"] = lst.duplicate()


func _build_brush_overlay() -> void:
	_brush_overlay = MultiMeshInstance3D.new()
	_brush_overlay.name = "BrushOverlay"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true                 # MUST precede instance_count
	var plane := PlaneMesh.new()
	plane.size = Vector2(cube_size * 0.92, cube_size * 0.92)
	mm.mesh = plane
	mm.instance_count = grid_w * grid_d
	_brush_overlay.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_brush_overlay.material_override = mat
	add_child(_brush_overlay)
	for z in grid_d:
		for x in grid_w:
			var i := z * grid_w + x
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3((x + 0.5) * cube_size, 0.06, (z + 0.5) * cube_size)))
			mm.set_instance_color(i, Color(0, 0, 0, 0))
	_brush_overlay.visible = false


func _cycle_paint_element() -> void:
	_paint_idx += 1
	if _paint_idx >= _paint_elements.size():
		_paint_idx = -1
	if _brush_overlay:
		_brush_overlay.visible = _paint_idx >= 0
	# Keep the right-side menu highlight in sync with the keyboard cycle.
	if _brush_menu_ui and _paint_idx >= 0 and _brush_menu_ui.has_method("set_selected_element"):
		_brush_menu_ui.set_selected_element(str(_paint_elements[_paint_idx]))
	_update_brush_overlay()
	_update_hud()


func _mode_of(el: String) -> String:
	return str(_element_mode.get(el, "brush"))


## M cycles the active element through brush → noise → curve → plane → random.
## Non-brush modes fill the grid by distribution (no painting); the overlay + 3D
## rebuild show the result immediately.
func _cycle_paint_mode() -> void:
	if _paint_idx < 0:
		return
	var el: String = _paint_elements[_paint_idx]
	var ni: int = (PAINT_MODES.find(_mode_of(el)) + 1) % PAINT_MODES.size()
	_element_mode[el] = str(PAINT_MODES[ni])
	_status_msg = "%s → %s" % [el, _element_mode[el]]
	_update_brush_overlay()
	_rebuild()
	_update_hud()


## The paint-layer spec a non-brush element contributes (density from the pressure
## slider; sensible defaults per mode).
func _distribution_layer(el: String, mode: String) -> Dictionary:
	var layer: Dictionary = {"element": el, "mode": mode, "density": _brush_strength}
	match mode:
		"noise":
			layer["scale"] = 0.3
			layer["threshold"] = 0.45
		"fractal":
			layer["scale"] = 0.16
			layer["threshold"] = 0.5
			layer["octaves"] = 4
		"curve":
			layer["axis"] = "radial"
			layer["falloff"] = "smooth"
	if el == "ground":
		layer["height"] = 1.5
	elif el == "shader":
		var c := _element_color(el)
		layer["color"] = [c.r, c.g, c.b]
	return layer


func _overlay_seed() -> int:
	return hash(_loaded_map) if _loaded_map != "" else 0xB10E


# ── Right-side brush-settings menu signals ────────────────────────────
func _on_menu_element(element_name: String) -> void:
	var idx := _paint_elements.find(element_name)
	if idx < 0:
		return
	_paint_idx = idx
	if _brush_overlay:
		_brush_overlay.visible = true
	_update_brush_overlay()
	_update_hud()


func _on_menu_size(r: int) -> void:
	_brush_radius = clampi(r, 0, 8)
	_update_hud()


func _on_menu_pressure(p: float) -> void:
	_brush_strength = clampf(p, 0.1, 1.0)
	_update_hud()


func _element_color(el: String) -> Color:
	return BiomeElementsLib.ui_color(el)


## Raycast the mouse onto the ground plane (y=0) → grid cell → stamp the brush.
func _paint_at_mouse() -> void:
	if _camera == null or _paint_idx < 0:
		return
	var mp := get_viewport().get_mouse_position()
	var origin := _camera.project_ray_origin(mp)
	var dir := _camera.project_ray_normal(mp)
	if absf(dir.y) < 1e-5:
		return
	var t := -origin.y / dir.y
	if t < 0.0:
		return
	var hit := origin + dir * t
	_stamp(int(floor(hit.x / cube_size)), int(floor(hit.z / cube_size)))


# ── Undo / redo (stroke-level) ─────────────────────────────────────────
func _snapshot() -> Dictionary:
	var snap: Dictionary = {}
	for el in _brush_fields:
		snap[el] = (_brush_fields[el] as PackedFloat32Array).duplicate()
	return snap


## Record the pre-stroke state. Called at stroke-start + before a clear.
func _push_undo() -> void:
	_undo_stack.append(_snapshot())
	if _undo_stack.size() > UNDO_CAP:
		_undo_stack.pop_front()
	_redo_stack.clear()


func _restore_fields(snap: Dictionary) -> void:
	_brush_fields = {}
	for el in snap:
		_brush_fields[el] = (snap[el] as PackedFloat32Array).duplicate()
	_update_brush_overlay()
	_rebuild()
	_update_hud()


func _undo() -> void:
	if _undo_stack.is_empty():
		_status_msg = "nothing to undo"; _update_hud(); return
	_redo_stack.append(_snapshot())
	var prev: Dictionary = _undo_stack.pop_back()
	_status_msg = "↩ undo"
	_restore_fields(prev)


func _redo() -> void:
	if _redo_stack.is_empty():
		_status_msg = "nothing to redo"; _update_hud(); return
	_undo_stack.append(_snapshot())
	var nxt: Dictionary = _redo_stack.pop_back()
	_status_msg = "↪ redo"
	_restore_fields(nxt)


func _stamp(cx: int, cz: int) -> void:
	var el: String = _paint_elements[_paint_idx]
	_element_mode[el] = "brush"   # painting a mask implies brush mode for this element
	if not _brush_fields.has(el):
		var nf := PackedFloat32Array()
		nf.resize(grid_w * grid_d)
		_brush_fields[el] = nf
	var field: PackedFloat32Array = _brush_fields[el]
	var r := _brush_radius
	# Hold Shift to erase temporarily (no need to toggle the E mode and back).
	var erasing := _brush_erase or Input.is_key_pressed(KEY_SHIFT)
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var x := cx + dx
			var z := cz + dz
			if x < 0 or x >= grid_w or z < 0 or z >= grid_d:
				continue
			var dist := sqrt(float(dx * dx + dz * dz))
			if dist > float(r) + 0.001:
				continue
			var falloff := 1.0 - dist / (float(r) + 0.0001)
			var i := z * grid_w + x
			if erasing:
				field[i] = maxf(0.0, field[i] - _brush_strength * falloff)
			else:
				field[i] = minf(1.0, field[i] + _brush_strength * falloff)
	_brush_fields[el] = field
	_brush_dirty = true
	_update_brush_overlay()
	# Live ground terrain preview — see the mesh rise as you paint (mesh only;
	# the full rebuild + collider lands on mouse-release via _rebuild()).
	if el == "ground" and _host:
		var sub := _find_descendant(_host, "BiomeGroundSubstrate")
		if sub and sub.has_method("apply_height_preview"):
			sub.apply_height_preview(field, grid_w, grid_d, 1.5)


func _find_descendant(root: Node, nm: String) -> Node:
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			if c.name == nm:
				return c
			stack.append(c)
	return null


func _update_brush_overlay() -> void:
	if _brush_overlay == null:
		return
	var mm: MultiMesh = _brush_overlay.multimesh
	if _paint_idx < 0:
		for i in grid_w * grid_d:
			mm.set_instance_color(i, Color(0, 0, 0, 0))
		return
	var el: String = _paint_elements[_paint_idx]
	var col := _element_color(el)
	# Brush mode → show the painted mask. Distribution mode → show the generated
	# field so you SEE where noise/curve/plane/random will place.
	var field: PackedFloat32Array
	if _mode_of(el) == "brush":
		field = _brush_fields.get(el, PackedFloat32Array())
	else:
		field = DistributionFieldLib.build_field(_distribution_layer(el, _mode_of(el)), grid_w, grid_d, _overlay_seed())
	for z in grid_d:
		for x in grid_w:
			var i := z * grid_w + x
			var v: float = field[i] if i < field.size() else 0.0
			mm.set_instance_color(i, Color(col.r, col.g, col.b, v * 0.75))


## Brush fields (as mode:"brush" layers) + the map's/CLI's other layers.
## A painted element overrides the map's layer for that element.
func _effective_paint_layers() -> Array:
	var out: Array = []
	var painted: Dictionary = {}
	# Elements the user has authored: brush-painted, or set to a distribution mode.
	var active: Dictionary = {}
	for el in _brush_fields:
		active[el] = true
	for el in _element_mode:
		if _mode_of(el) != "brush":
			active[el] = true
	for el in _element_artifacts:
		if not (_element_artifacts[el] as Array).is_empty():
			active[el] = true   # a picked artifact list is enough to populate the field
	for el in active:
		if _mode_of(el) == "brush":
			if not _brush_fields.has(el):
				# Artifacts picked but no brush stroke → scatter them across the map
				# by a default distribution, so picking alone populates the field.
				if not (_element_artifacts.get(el, []) as Array).is_empty():
					painted[el] = true
					var dl0 := _distribution_layer(el, "random")
					_attach_artifacts(dl0, el)
					out.append(dl0)
				continue
			painted[el] = true
			var layer := {"element": el, "mode": "brush", "density": 1.0, "brush": _field_to_brush(_brush_fields[el])}
			if el == "ground":
				layer["height"] = 1.5   # painted bumps rise to ~1.5 m
			elif el == "shader":
				var c := _element_color(el)
				layer["color"] = [c.r, c.g, c.b]   # the colour painted into the ground texture
			_attach_artifacts(layer, el)   # picked artifacts → object_scatter places them here
			out.append(layer)
		else:
			painted[el] = true
			var dl := _distribution_layer(el, _mode_of(el))
			_attach_artifacts(dl, el)
			out.append(dl)
	var base: Array = _cli_paint if not _cli_paint.is_empty() else _map_paint_layers
	for layer in base:
		if layer is Dictionary and not painted.has(str(layer.get("element", ""))):
			out.append(layer)
	# Sequence accrual: prepend the earlier maps' painted layers so the biome
	# builds on what came before (same as in-game). Only for a real loaded map
	# in a sequence; synthetic / --paint tests stay isolated.
	if _loaded_map != "" and _eco != null:
		return SequenceAccrualLib.accrued_layers(_eco, _loaded_map, out)
	return out


## Brush field → compact sparse {w,d,cells} form (only painted cells, not a dense
## grid of zeros — keeps map_data.json + git diffs small). _read_brush decodes it.
func _field_to_brush(field: PackedFloat32Array) -> Dictionary:
	return DistributionFieldLib.field_to_sparse(field, grid_w, grid_d)


## --brushtest=<element>: stamp a filled disc and rebuild — headless proof of
## the brush → field → placement path without a mouse.
func _apply_brushtest(el: String) -> void:
	var idx := _paint_elements.find(el)
	if idx < 0:
		return
	_paint_idx = idx
	if _brush_overlay:
		_brush_overlay.visible = true
	var cx := grid_w / 2
	var cz := grid_d / 2
	var saved := _brush_radius
	_brush_radius = maxi(3, mini(grid_w, grid_d) / 3)
	_stamp(cx, cz)
	_brush_radius = saved
	_rebuild()


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

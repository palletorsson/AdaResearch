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
##   B  brush element (tree→critter→flower→off)   L-drag  paint   E  erase
##   C  clear brush   , / .  brush radius   W  save brush+overrides → map
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
var _paint_elements: Array = ["tree", "critter", "flower"]
var _paint_idx: int = -1             # -1 = not painting; else index into _paint_elements
var _brush_fields: Dictionary = {}   # element -> PackedFloat32Array (grid_w*grid_d)
var _brush_radius: int = 2
var _brush_strength: float = 0.6
var _brush_erase: bool = false
var _painting: bool = false
var _brush_dirty: bool = false       # set while dragging; triggers rebuild on release
var _brush_overlay: MultiMeshInstance3D = null
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
		"rng_seed": 0xB10E,  # stable seed so scrubbing is deterministic
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
	# Persist painted brush fields into the map's top-level paint_layers[].
	# A painted element replaces any existing layer for that element; other
	# layers (plane/noise/etc. the scrubber doesn't paint) are preserved.
	if not _brush_fields.is_empty():
		var existing: Array = _map_data.get("paint_layers", []) if (_map_data.get("paint_layers") is Array) else []
		var kept: Array = []
		for layer in existing:
			if layer is Dictionary and not _brush_fields.has(str(layer.get("element", ""))):
				kept.append(layer)
		for el in _brush_fields:
			kept.append({"element": el, "mode": "brush", "density": 1.0, "brush": _field_to_rows(_brush_fields[el])})
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
	_map_overrides = ov
	_status_msg = "✓ saved → %s  (disable=%d, stage=%d, brush=%d)" % [_loaded_map, dis.size(), _stage, _brush_fields.size()]
	_update_hud()
	print("[scrubber] saved overrides to %s: %s" % [_loaded_map, str(ov)])


# ── HUD + side panel ──────────────────────────────────────────────────
func _update_hud() -> void:
	if _stage_big == null:
		return
	var seq_name := _seq_of_kind_for_stage()
	var truth := _truth_for_stage()
	var on := 0
	for k in _active_kinds:
		if not _disabled.has(k): on += 1
	# Big stage readout.
	_stage_big.text = "STAGE %d · LAB" % _stage if _stage > MAX_STAGE else "STAGE %d / %d" % [_stage, MAX_STAGE]
	# Context line: sequence · layers on · where.
	var where := "%s  %d×%d" % [_loaded_map, grid_w, grid_d] if _loaded_map != "" else "synthetic  %d×%d" % [grid_w, grid_d]
	var seq_show := seq_name if seq_name != "?" else "—"
	var active_paint: Array = _cli_paint if not _cli_paint.is_empty() else _map_paint_layers
	var paint_tag := "    ·    🖌 %d paint" % active_paint.size() if active_paint.size() > 0 else ""
	_seq_lbl.text = "%s    ·    %d/%d layers on    ·    %s%s" % [seq_show, on, _active_kinds.size(), where, paint_tag]
	# Truth quote.
	_truth_lbl.text = ("“%s”" % truth) if truth != "" else ""
	# Controls footer — brush controls when a paint element is active.
	if _paint_idx >= 0:
		var el: String = _paint_elements[_paint_idx]
		_controls_lbl.text = "🖌 PAINT %s  (r%d%s)      L-drag paint      B element      E erase      C clear      , . radius      W save" % [
			el.to_upper(), _brush_radius, "  ERASE" if _brush_erase else ""]
		_controls_lbl.add_theme_color_override("font_color", _element_color(el))
	else:
		var save_hint := "      W save→map" if _loaded_map != "" else ""
		_controls_lbl.text = "[ / ] stage    ↑↓ select    Space toggle    S solo    A all    R reset    B brush    Tab panel%s" % save_hint
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
		"floating_primitives", "floating_points", "animated_primitives":
			return Color(0.55, 0.70, 1.0)    # abstract — blue
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
			KEY_B:      _cycle_paint_element()
			KEY_E:
				_brush_erase = not _brush_erase
				_update_hud()
			KEY_C:
				if _paint_idx >= 0:
					_brush_fields.erase(_paint_elements[_paint_idx])
					_update_brush_overlay()
					_rebuild()
			KEY_COMMA:  _brush_radius = maxi(0, _brush_radius - 1); _update_hud()
			KEY_PERIOD: _brush_radius = mini(8, _brush_radius + 1); _update_hud()
			KEY_TAB:
				if _panel_root: _panel_root.visible = not _panel_root.visible
			KEY_R:
				if _accrual.has_method("reset_overrides"): _accrual.reset_overrides()
				_disabled.clear(); _rebuild()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				_set_stage(event.keycode - KEY_0)
			KEY_0: _set_stage(10)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and _paint_idx >= 0:
			# Left-drag paints the active element's brush; rebuild on release.
			_painting = event.pressed
			if event.pressed:
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

	# ── Right-side layer panel ────────────────────────────────────────
	_panel_root = PanelContainer.new()
	_panel_root.anchor_left = 1.0
	_panel_root.anchor_right = 1.0
	_panel_root.anchor_top = 0.0
	_panel_root.offset_left = -(PANEL_W + 8.0)
	_panel_root.offset_top = BAR_H + 8.0
	_panel_root.offset_right = -8.0
	_panel_root.add_theme_stylebox_override("panel", _new_stylebox(C_BG, 0.0, 8.0))
	layer.add_child(_panel_root)
	_panel = VBoxContainer.new()
	_panel.add_theme_constant_override("separation", 3)
	_panel_root.add_child(_panel)

	# Error overlay label (normally hidden) — used only when an autoload
	# is missing, before the info labels have anything to show.
	_hud = _mk_label(layer, "", 15, C_BAD, Vector2(20, BAR_H + 8))


# ── Brush painting (step 3) ──────────────────────────────────────────
## A flat grid of per-cell quads over the ground; alpha = the active element's
## brush density. Built once, recoloured as you paint.
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
	_update_brush_overlay()
	_update_hud()


func _element_color(el: String) -> Color:
	match el:
		"tree": return Color(0.45, 0.85, 0.50)
		"critter": return Color(1.0, 0.70, 0.36)
		"flower": return Color(1.0, 0.55, 0.76)
	return Color(0.7, 0.7, 0.7)


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


func _stamp(cx: int, cz: int) -> void:
	var el: String = _paint_elements[_paint_idx]
	if not _brush_fields.has(el):
		var nf := PackedFloat32Array()
		nf.resize(grid_w * grid_d)
		_brush_fields[el] = nf
	var field: PackedFloat32Array = _brush_fields[el]
	var r := _brush_radius
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
			if _brush_erase:
				field[i] = maxf(0.0, field[i] - _brush_strength * falloff)
			else:
				field[i] = minf(1.0, field[i] + _brush_strength * falloff)
	_brush_fields[el] = field
	_brush_dirty = true
	_update_brush_overlay()


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
	var field: PackedFloat32Array = _brush_fields.get(el, PackedFloat32Array())
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
	for el in _brush_fields:
		painted[el] = true
		out.append({"element": el, "mode": "brush", "density": 1.0, "brush": _field_to_rows(_brush_fields[el])})
	var base: Array = _cli_paint if not _cli_paint.is_empty() else _map_paint_layers
	for layer in base:
		if layer is Dictionary and not painted.has(str(layer.get("element", ""))):
			out.append(layer)
	return out


func _field_to_rows(field: PackedFloat32Array) -> Array:
	var rows: Array = []
	for z in grid_d:
		var row: Array = []
		for x in grid_w:
			var i := z * grid_w + x
			row.append(snappedf(field[i] if i < field.size() else 0.0, 0.01))
		rows.append(row)
	return rows


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

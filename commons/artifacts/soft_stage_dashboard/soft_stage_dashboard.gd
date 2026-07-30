extends Node3D
class_name SoftStageDashboard

## Wall-mounted read-only panel showing live state from EcosystemManager,
## HazardManager, and CatalystCapabilityManager. Three-column layout with
## a rolling signal log at the bottom.

# @identity
# essence: read(EcosystemManager) + read(HazardManager) + read(CatalystCapabilityManager) → three columns of Label3D + scrolling log. A passive observer of three managers' shared world state.
# desire: To make the invisible game state legible — soft-stage progression is hidden in autoload singletons until this panel pins it to a wall and lets you read where you are in the curriculum.
# critical_parameter: panel_size sets footprint; MAX_LOG = 8 caps the rolling signal log; the labels update from manager signals, not polling, so refresh cost is zero between events.
# triggers: manager signal (stage_advanced, hazard_befriended, capability_unlocked) → label update + log append → scroll oldest out
# emerges: A diegetic UI — game state becomes architecture, and "the rules of this room" are something you read off a wall instead of inferring from feel.
# needs: read-only (no inputs), but pairs with progression_driver as its writable twin
# relationships: Wall-mounted partner to progression_driver (read vs write); appears in Hazards_Zoo_4 onward where soft-stage transitions become curriculum events.
# truth: Hidden state is hostile state — once managers' fields are pinned to a Label3D, the world has receipts, and the player can finally find out what the curriculum thinks it's doing.

# --- Configuration ---
@export var panel_size: Vector2 = Vector2(1.2, 0.9)

## --- DNA (stage 2, promoted 2026-07-29) ---
##
## STAGE-2 DNA PROMOTION. The sweep refused this artifact for having no turnable
## knobs: panel_size was the only export, and a size is not an argument. The two
## constants that actually carry the argument were buried in the builder —
##
##   report    WHICH managers the wall is a witness to
##   mounting  HOW the readout attaches to the room it reports on
##
## report was hard-coded as three equal columns: ecosystem, hazards, capability,
## co-equal by construction, at a third of the panel each. That is a claim — that
## the world's state is three systems of the same weight — and every room made it
## whether or not the room was about all three. Narrowed to one manager, the panel
## becomes a monitor for THIS room's concern and the column takes the full width.
##
## mounting was not a constant so much as an absence. The docstring says
## "wall-mounted", and the geometry is a quad at the placement origin with nothing
## holding it: a floating readout, which is the same sin the cabinet grammar's first
## rule forbids. lectern gives it a slanted face on legs you read down at; kiosk
## stands it on a pedestal at reading height. wall is the shipped no-body case.
##
## report=all + mounting=wall reproduces the shipped panel exactly — the column
## slots, the divider positions and the label wrap width all come out at the old
## hard-coded panel_size.x / 3 — so the 7 existing placements are untouched.
##
## Usage in map_data.json:
##   "soft_stage_dashboard#report:hazards"
##   "soft_stage_dashboard#report:capability#mounting:lectern"

## Which managers get a column. "all" is the shipped three-column layout.
@export_enum("all", "ecosystem", "hazards", "capability") var report: String = "all"

## How the panel meets the room. "wall" is the shipped bare quad with no body.
@export_enum("wall", "lectern", "kiosk") var mounting: String = "wall"

# --- Colors ---
const COL_BG := Color(0.05, 0.05, 0.08)
const COL_FRAME := Color(0.15, 0.2, 0.35)
const COL_TITLE := Color(0.85, 0.9, 1.0)
const COL_SECTION := Color(0.6, 0.75, 0.95)
const COL_VALUE := Color(0.8, 0.85, 0.9)
const COL_ECO := Color(0.3, 0.85, 0.4)
const COL_HAZ := Color(0.9, 0.35, 0.3)
const COL_CAP := Color(0.35, 0.75, 0.95)
const COL_LOG := Color(0.5, 0.5, 0.6)
const COL_DIVIDER := Color(0.12, 0.14, 0.2)

# --- Internal ---
var _title_label: Label3D
var _stage_label: Label3D

# Ecosystem column labels
var _eco_header: Label3D
var _eco_terrain: Label3D
var _eco_ambient: Label3D
var _eco_density: Label3D
var _eco_kingdoms: Label3D
var _eco_flags: Label3D

# Hazards column labels
var _haz_header: Label3D
var _haz_behavior: Label3D
var _haz_concurrent: Label3D
var _haz_types: Label3D
var _haz_personalities: Label3D

# Capability column labels
var _cap_header: Label3D
var _cap_level: Label3D
var _cap_verbs: Label3D
var _cap_movement: Label3D
var _cap_modes: Label3D

# Signal log
var _log_label: Label3D
var _log_entries: Array[String] = []
const MAX_LOG := 8

var _start_time: float = 0.0
var _current_stage_name: String = "—"
var _current_stage_order: int = 0

## Everything the builder makes hangs off this, so mounting can tilt or raise the
## whole face without touching the artifact's own transform (which the grid owns).
## For mounting=wall it stays at identity, which is exactly where the children were
## before this node existed.
var _face: Node3D = null
## Label wrap width in metres — derived from the number of active columns. At
## report=all this comes out at panel_size.x / 3 - 0.06, the old hard-coded value.
var _label_width_m: float = 0.0
var _built: bool = false


func _ready() -> void:
	_start_time = Time.get_ticks_msec() / 1000.0
	_build_panel()
	_build_header()
	_build_columns()
	_build_signal_log()
	_connect_all_manager_signals()
	_refresh_all()
	_built = true


## Which manager columns are live, in order. Named short because the column
## builders are keyed by these.
func _active_columns() -> Array[String]:
	var cols: Array[String] = []
	match report:
		"ecosystem":
			cols.append("eco")
		"hazards":
			cols.append("haz")
		"capability":
			cols.append("cap")
		_:
			cols.append("eco")
			cols.append("haz")
			cols.append("cap")
	return cols


# ---------------------------------------------------------------------------
# Panel construction (follows shannon_entropy_meter pattern)
# ---------------------------------------------------------------------------

func _build_panel() -> void:
	# The face carries everything. mounting=wall leaves it at identity, which is where
	# the panel's children sat before this node existed.
	_face = Node3D.new()
	_face.name = "Face"
	add_child(_face)
	_apply_mounting()

	var slot_count: int = _active_columns().size()
	_label_width_m = panel_size.x / float(slot_count) - 0.06

	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = panel_size
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COL_BG
	mat.roughness = 0.85
	mat.metallic = 0.1
	mi.material_override = mat
	_face.add_child(mi)

	# Frame edges
	_add_frame_edge(Vector3(0, panel_size.y / 2.0, 0.001), Vector3(panel_size.x + 0.02, 0.015, 0.002))
	_add_frame_edge(Vector3(0, -panel_size.y / 2.0, 0.001), Vector3(panel_size.x + 0.02, 0.015, 0.002))
	_add_frame_edge(Vector3(-panel_size.x / 2.0, 0, 0.001), Vector3(0.015, panel_size.y + 0.02, 0.002))
	_add_frame_edge(Vector3(panel_size.x / 2.0, 0, 0.001), Vector3(0.015, panel_size.y + 0.02, 0.002))

	# Column dividers — one between each pair of live columns. At three columns these
	# land on 1/3 and 2/3, exactly where they were hard-coded; at one column there are
	# none to draw.
	var slot := panel_size.x / float(slot_count)
	var body_top := panel_size.y / 2.0 - 0.08
	var body_bot := -panel_size.y / 2.0 + 0.12
	var body_h := body_top - body_bot
	for i in range(1, slot_count):
		_add_divider(
			Vector3(-panel_size.x / 2.0 + slot * float(i), (body_top + body_bot) / 2.0, 0.001),
			Vector3(0.004, body_h, 0.001))

	# Horizontal divider above signal log
	_add_divider(Vector3(0, -panel_size.y / 2.0 + 0.12, 0.001), Vector3(panel_size.x - 0.04, 0.004, 0.001))


## The body the readout stands on.
## wall    — no body at all: the shipped quad, hanging where it was placed.
## lectern — a slanted reading face on splayed legs, met by walking up to it.
## kiosk   — upright on a pedestal, the panel's bottom edge at chest height.
func _apply_mounting() -> void:
	match mounting:
		"lectern":
			_face.position = Vector3(0, 0.95, 0)
			_face.rotation_degrees = Vector3(-32.0, 0, 0)
			_add_support(Vector3(-panel_size.x * 0.34, 0.45, 0.06), Vector3(0.05, 0.90, 0.05))
			_add_support(Vector3(panel_size.x * 0.34, 0.45, 0.06), Vector3(0.05, 0.90, 0.05))
			_add_support(Vector3(0, 0.02, 0.10), Vector3(panel_size.x * 0.80, 0.04, 0.34))
		"kiosk":
			_face.position = Vector3(0, 1.10 + panel_size.y / 2.0, 0)
			_add_support(Vector3(0, 0.55, -0.03), Vector3(panel_size.x * 0.40, 1.10, 0.16))
			_add_support(Vector3(0, 0.03, -0.03), Vector3(panel_size.x * 0.66, 0.06, 0.36))


## A structural piece of the mounting — parented to the artifact, NOT to the face, so
## it stays upright when the face tilts.
func _add_support(pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COL_FRAME * 0.7
	mat.roughness = 0.9
	mat.metallic = 0.2
	mi.material_override = mat
	add_child(mi)


func _add_frame_edge(pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COL_FRAME
	mat.emission_enabled = true
	mat.emission = COL_FRAME * 0.4
	mat.emission_energy_multiplier = 0.3
	mi.material_override = mat
	_face.add_child(mi)


func _add_divider(pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COL_DIVIDER
	mi.material_override = mat
	_face.add_child(mi)


# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

func _build_header() -> void:
	var title: String = "SOFT STAGE DASHBOARD"
	if report != "all":
		title = "SOFT STAGE — %s" % report.to_upper()
	_title_label = _make_label(title, 36, COL_TITLE,
		Vector3(-panel_size.x / 2.0 + 0.04, panel_size.y / 2.0 - 0.035, 0.003),
		HORIZONTAL_ALIGNMENT_LEFT)

	_stage_label = _make_label("Stage: — / —", 24, COL_SECTION,
		Vector3(panel_size.x / 2.0 - 0.04, panel_size.y / 2.0 - 0.035, 0.003),
		HORIZONTAL_ALIGNMENT_RIGHT)


# ---------------------------------------------------------------------------
# Three columns
# ---------------------------------------------------------------------------

func _build_columns() -> void:
	var cols: Array[String] = _active_columns()
	var slot := panel_size.x / float(cols.size())
	var col_left := -panel_size.x / 2.0 + 0.04
	var top := panel_size.y / 2.0 - 0.08

	# At three columns the slot is panel_size.x / 3, so these x values are identical to
	# the ones that were written out by hand.
	for i in range(cols.size()):
		var x: float = col_left + slot * float(i)
		match cols[i]:
			"eco":
				_build_eco_column(x, top)
			"haz":
				_build_haz_column(x, top)
			"cap":
				_build_cap_column(x, top)


func _build_eco_column(col: float, top: float) -> void:
	_eco_header = _make_label("ECOSYSTEM", 22, COL_ECO, Vector3(col, top, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_eco_terrain = _make_label("Terrain: —", 18, COL_VALUE, Vector3(col, top - 0.04, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_eco_ambient = _make_label("Ambient: —", 18, COL_VALUE, Vector3(col, top - 0.065, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_eco_density = _make_label("Density: —", 18, COL_VALUE, Vector3(col, top - 0.09, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_eco_kingdoms = _make_label("Kingdoms: —", 18, COL_VALUE, Vector3(col, top - 0.13, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_eco_flags = _make_label("Flags: —", 16, COL_VALUE, Vector3(col, top - 0.17, 0.003), HORIZONTAL_ALIGNMENT_LEFT)


func _build_haz_column(col: float, top: float) -> void:
	_haz_header = _make_label("HAZARDS", 22, COL_HAZ, Vector3(col, top, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_haz_behavior = _make_label("Behavior: —", 18, COL_VALUE, Vector3(col, top - 0.04, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_haz_concurrent = _make_label("Max Concurrent: —", 18, COL_VALUE, Vector3(col, top - 0.065, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_haz_types = _make_label("Types: —", 16, COL_VALUE, Vector3(col, top - 0.11, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_haz_personalities = _make_label("Personalities: —", 16, COL_VALUE, Vector3(col, top - 0.30, 0.003), HORIZONTAL_ALIGNMENT_LEFT)


func _build_cap_column(col: float, top: float) -> void:
	_cap_header = _make_label("CAPABILITY", 22, COL_CAP, Vector3(col, top, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_cap_level = _make_label("Level: —", 20, COL_VALUE, Vector3(col, top - 0.04, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_cap_verbs = _make_label("Hand Verbs: —", 16, COL_VALUE, Vector3(col, top - 0.09, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_cap_movement = _make_label("Movement: —", 16, COL_VALUE, Vector3(col, top - 0.30, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_cap_modes = _make_label("Modes: —", 16, COL_VALUE, Vector3(col, top - 0.37, 0.003), HORIZONTAL_ALIGNMENT_LEFT)


# ---------------------------------------------------------------------------
# Signal log
# ---------------------------------------------------------------------------

func _build_signal_log() -> void:
	var log_y := -panel_size.y / 2.0 + 0.06
	_make_label("SIGNAL LOG", 16, COL_LOG, Vector3(-panel_size.x / 2.0 + 0.04, log_y + 0.04, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_log_label = _make_label("(waiting for signals...)", 14, COL_LOG,
		Vector3(-panel_size.x / 2.0 + 0.04, log_y, 0.003), HORIZONTAL_ALIGNMENT_LEFT)


func _append_log(manager_short: String, signal_name: String, detail: String) -> void:
	var elapsed := (Time.get_ticks_msec() / 1000.0) - _start_time
	var entry := "[%.0fs] %s.%s %s" % [elapsed, manager_short, signal_name, detail]
	_log_entries.append(entry)
	if _log_entries.size() > MAX_LOG:
		_log_entries = _log_entries.slice(_log_entries.size() - MAX_LOG)
	if is_instance_valid(_log_label):
		_log_label.text = "\n".join(_log_entries)


# ---------------------------------------------------------------------------
# Manager signal connections
# ---------------------------------------------------------------------------

func _connect_all_manager_signals() -> void:
	var eco = get_node_or_null("/root/EcosystemManager")
	if eco:
		eco.allow_flags_changed.connect(_on_eco_flags)
		eco.vegetation_config_changed.connect(_on_eco_veg)
		eco.terrain_mode_changed.connect(_on_eco_terrain)
		eco.nature_kingdoms_changed.connect(_on_eco_kingdoms)
		eco.ecosystem_stage_advanced.connect(_on_eco_advanced)

	var haz = get_node_or_null("/root/HazardManager")
	if haz:
		haz.hazard_types_updated.connect(_on_haz_types)
		haz.hazard_personality_changed.connect(_on_haz_personality)
		haz.spawner_behavior_changed.connect(_on_haz_behavior)
		haz.hazard_befriended.connect(_on_haz_befriended)
		haz.stage_advanced.connect(_on_haz_advanced)

	var cap = get_node_or_null("/root/CatalystCapabilityManager")
	if cap:
		cap.capacity_level_changed.connect(_on_cap_level)
		cap.hand_verbs_changed.connect(_on_cap_verbs)
		cap.movement_ability_unlocked.connect(_on_cap_movement)
		cap.catalyst_mode_registered.connect(_on_cap_mode)


# ---------------------------------------------------------------------------
# Signal callbacks — refresh + log
# ---------------------------------------------------------------------------

# Ecosystem
func _on_eco_flags(flags: Array) -> void:
	_refresh_ecosystem()
	_append_log("Eco", "allow_flags_changed", "(%d flags)" % flags.size())

func _on_eco_veg(_config: Dictionary) -> void:
	_refresh_ecosystem()
	_append_log("Eco", "vegetation_config_changed", "")

func _on_eco_terrain(new_mode: String) -> void:
	_refresh_ecosystem()
	_append_log("Eco", "terrain_mode_changed", new_mode)

func _on_eco_kingdoms(kingdoms: Array) -> void:
	_refresh_ecosystem()
	_append_log("Eco", "nature_kingdoms_changed", "(%d)" % kingdoms.size())

func _on_eco_advanced(seq_name: String) -> void:
	_current_stage_name = seq_name
	_refresh_header()
	_append_log("Eco", "stage_advanced", seq_name)

# Hazards
func _on_haz_types(types: Array) -> void:
	_refresh_hazards()
	_append_log("Haz", "types_updated", "(%d types)" % types.size())

func _on_haz_personality(hazard_type: String, new_personality: String) -> void:
	_refresh_hazards()
	_append_log("Haz", "personality_changed", "%s→%s" % [hazard_type, new_personality])

func _on_haz_behavior(new_behavior: String) -> void:
	_refresh_hazards()
	_append_log("Haz", "behavior_changed", new_behavior)

func _on_haz_befriended(hazard_type: String) -> void:
	_refresh_hazards()
	_append_log("Haz", "befriended", hazard_type)

func _on_haz_advanced(seq_name: String) -> void:
	_current_stage_name = seq_name
	_refresh_header()
	_append_log("Haz", "stage_advanced", seq_name)

# Capability
func _on_cap_level(new_level: int) -> void:
	_refresh_capability()
	_append_log("Cap", "capacity_level_changed", "L%d" % new_level)

func _on_cap_verbs(verbs: Array) -> void:
	_refresh_capability()
	_append_log("Cap", "verbs_changed", "(%d verbs)" % verbs.size())

func _on_cap_movement(ability: String) -> void:
	_refresh_capability()
	_append_log("Cap", "movement_unlocked", ability)

func _on_cap_mode(mode_id: String) -> void:
	_refresh_capability()
	_append_log("Cap", "mode_registered", mode_id)


# ---------------------------------------------------------------------------
# Refresh functions — query managers and update labels
# ---------------------------------------------------------------------------

func _refresh_all() -> void:
	_refresh_header()
	_refresh_ecosystem()
	_refresh_hazards()
	_refresh_capability()


func _refresh_header() -> void:
	if not is_instance_valid(_stage_label):
		return
	_stage_label.text = "Stage: %d / %s" % [_current_stage_order, _current_stage_name]


func _refresh_ecosystem() -> void:
	# A column the current `report` did not build has no labels to write into. The
	# manager signals stay connected either way, so the log still records everything
	# that happens — only the readout narrows.
	if not is_instance_valid(_eco_header):
		return
	var eco = get_node_or_null("/root/EcosystemManager")
	if not eco:
		_eco_header.text = "ECOSYSTEM (not loaded)"
		return

	_eco_terrain.text = "Terrain: %s" % eco.get_terrain_mode()
	_eco_ambient.text = "Ambient: %s" % eco.get_ambient_preset()
	_eco_density.text = "Density: %.2f" % eco.get_vegetation_density()

	var kingdoms: Array = eco.get_allowed_kingdoms()
	_eco_kingdoms.text = "Kingdoms: %s" % (", ".join(kingdoms) if kingdoms.size() > 0 else "none")

	var flags: Array = eco.get_all_allowed_flags()
	var flag_lines := "Flags (%d):\n" % flags.size()
	for f in flags:
		flag_lines += "  %s\n" % f
	_eco_flags.text = flag_lines.strip_edges()


func _refresh_hazards() -> void:
	if not is_instance_valid(_haz_header):
		return
	var haz = get_node_or_null("/root/HazardManager")
	if not haz:
		_haz_header.text = "HAZARDS (not loaded)"
		return

	_haz_behavior.text = "Behavior: %s" % haz.get_spawner_behavior()
	_haz_concurrent.text = "Max Concurrent: %d" % haz.get_max_concurrent()

	var types: Array = haz.get_allowed_hazard_types()
	var types_lines := "Types (%d):\n" % types.size()
	for t in types:
		types_lines += "  %s\n" % t
	_haz_types.text = types_lines.strip_edges()

	# Show personalities for allowed types
	var pers_lines := "Personalities:\n"
	for t in types:
		var p: String = haz.get_hazard_personality(t)
		pers_lines += "  %s: %s\n" % [_short_name(t), p]
	_haz_personalities.text = pers_lines.strip_edges()


func _refresh_capability() -> void:
	if not is_instance_valid(_cap_header):
		return
	var cap = get_node_or_null("/root/CatalystCapabilityManager")
	if not cap:
		_cap_header.text = "CAPABILITY (not loaded)"
		return

	var level: int = cap.get_capacity_level()
	var level_name: String = cap.get_capacity_level_name()
	_cap_level.text = "L%d %s" % [level, level_name]

	var verbs: Array = cap.get_available_hand_verbs()
	var verb_lines := "Hand Verbs (%d):\n" % verbs.size()
	for v in verbs:
		verb_lines += "  %s\n" % v
	_cap_verbs.text = verb_lines.strip_edges()

	var movement: Array = cap.get_available_movement_abilities()
	var move_lines := "Movement:\n"
	if movement.size() == 0:
		move_lines += "  none"
	else:
		for m in movement:
			move_lines += "  %s\n" % m
	_cap_movement.text = move_lines.strip_edges()

	var modes: Array = cap.get_unlocked_catalyst_modes()
	var mode_lines := "Modes (%d):\n" % modes.size()
	for m in modes:
		mode_lines += "  %s\n" % m
	_cap_modes.text = mode_lines.strip_edges()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_label(text: String, size: int, color: Color, pos: Vector3, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = size
	lbl.pixel_size = 0.001
	lbl.outline_size = max(2, size / 8)
	lbl.position = pos
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl.modulate = color
	# Wrap within column. At report=all this is panel_size.x / 3 - 0.06, the value that
	# used to be written here directly.
	lbl.width = _label_width_m / 0.001
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_face.add_child(lbl)
	return lbl


func _short_name(hazard_type: String) -> String:
	# "miura_crawler" → "miura", "kaleidocycle_enemy" → "kaleido"
	var parts := hazard_type.split("_")
	if parts.size() > 0:
		var name := parts[0]
		return name.substr(0, 8) if name.length() > 8 else name
	return hazard_type


## Rebuild the face for a changed report or mounting. The manager signals are NOT
## reconnected — they are bound to methods on this node, which survives — so this
## cannot double-connect. The log's accumulated entries survive too and are reprinted.
func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_face = null
	_title_label = null
	_stage_label = null
	_eco_header = null
	_eco_terrain = null
	_eco_ambient = null
	_eco_density = null
	_eco_kingdoms = null
	_eco_flags = null
	_haz_header = null
	_haz_behavior = null
	_haz_concurrent = null
	_haz_types = null
	_haz_personalities = null
	_cap_header = null
	_cap_level = null
	_cap_verbs = null
	_cap_movement = null
	_cap_modes = null
	_log_label = null

	_build_panel()
	_build_header()
	_build_columns()
	_build_signal_log()
	_refresh_all()
	if _log_entries.size() > 0 and is_instance_valid(_log_label):
		_log_label.text = "\n".join(_log_entries)


## Grid system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("panel_scale"):
		var s := float(config_data["panel_scale"])
		scale = Vector3(s, s, s)

	# The grid calls this DEFERRED, after _ready has already built the panel once, so
	# the rebuild is gated twice: only on a value that actually changed, and only once
	# there is something built to replace.
	var wants_rebuild: bool = false
	if config_data.has("report"):
		var r: String = str(config_data["report"])
		if r != report:
			report = r
			wants_rebuild = true
	if config_data.has("mounting"):
		var m: String = str(config_data["mounting"])
		if m != mounting:
			mounting = m
			wants_rebuild = true
	if wants_rebuild and _built:
		_rebuild()

	if config_data.has("show_log") and not config_data["show_log"]:
		if _log_label:
			_log_label.visible = false

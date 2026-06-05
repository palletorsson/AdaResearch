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


func _ready() -> void:
	_start_time = Time.get_ticks_msec() / 1000.0
	_build_panel()
	_build_header()
	_build_columns()
	_build_signal_log()
	_connect_all_manager_signals()
	_refresh_all()


# ---------------------------------------------------------------------------
# Panel construction (follows shannon_entropy_meter pattern)
# ---------------------------------------------------------------------------

func _build_panel() -> void:
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = panel_size
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COL_BG
	mat.roughness = 0.85
	mat.metallic = 0.1
	mi.material_override = mat
	add_child(mi)

	# Frame edges
	_add_frame_edge(Vector3(0, panel_size.y / 2.0, 0.001), Vector3(panel_size.x + 0.02, 0.015, 0.002))
	_add_frame_edge(Vector3(0, -panel_size.y / 2.0, 0.001), Vector3(panel_size.x + 0.02, 0.015, 0.002))
	_add_frame_edge(Vector3(-panel_size.x / 2.0, 0, 0.001), Vector3(0.015, panel_size.y + 0.02, 0.002))
	_add_frame_edge(Vector3(panel_size.x / 2.0, 0, 0.001), Vector3(0.015, panel_size.y + 0.02, 0.002))

	# Column dividers — two vertical lines at 1/3 and 2/3
	var third := panel_size.x / 3.0
	var body_top := panel_size.y / 2.0 - 0.08
	var body_bot := -panel_size.y / 2.0 + 0.12
	var body_h := body_top - body_bot
	_add_divider(Vector3(-panel_size.x / 2.0 + third, (body_top + body_bot) / 2.0, 0.001), Vector3(0.004, body_h, 0.001))
	_add_divider(Vector3(-panel_size.x / 2.0 + third * 2.0, (body_top + body_bot) / 2.0, 0.001), Vector3(0.004, body_h, 0.001))

	# Horizontal divider above signal log
	_add_divider(Vector3(0, -panel_size.y / 2.0 + 0.12, 0.001), Vector3(panel_size.x - 0.04, 0.004, 0.001))


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
	add_child(mi)


func _add_divider(pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COL_DIVIDER
	mi.material_override = mat
	add_child(mi)


# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

func _build_header() -> void:
	_title_label = _make_label("SOFT STAGE DASHBOARD", 36, COL_TITLE,
		Vector3(-panel_size.x / 2.0 + 0.04, panel_size.y / 2.0 - 0.035, 0.003),
		HORIZONTAL_ALIGNMENT_LEFT)

	_stage_label = _make_label("Stage: — / —", 24, COL_SECTION,
		Vector3(panel_size.x / 2.0 - 0.04, panel_size.y / 2.0 - 0.035, 0.003),
		HORIZONTAL_ALIGNMENT_RIGHT)


# ---------------------------------------------------------------------------
# Three columns
# ---------------------------------------------------------------------------

func _build_columns() -> void:
	var third := panel_size.x / 3.0
	var col_left := -panel_size.x / 2.0 + 0.04
	var col_mid := col_left + third
	var col_right := col_left + third * 2.0
	var top := panel_size.y / 2.0 - 0.08

	# --- ECOSYSTEM column (left) ---
	_eco_header = _make_label("ECOSYSTEM", 22, COL_ECO, Vector3(col_left, top, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_eco_terrain = _make_label("Terrain: —", 18, COL_VALUE, Vector3(col_left, top - 0.04, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_eco_ambient = _make_label("Ambient: —", 18, COL_VALUE, Vector3(col_left, top - 0.065, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_eco_density = _make_label("Density: —", 18, COL_VALUE, Vector3(col_left, top - 0.09, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_eco_kingdoms = _make_label("Kingdoms: —", 18, COL_VALUE, Vector3(col_left, top - 0.13, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_eco_flags = _make_label("Flags: —", 16, COL_VALUE, Vector3(col_left, top - 0.17, 0.003), HORIZONTAL_ALIGNMENT_LEFT)

	# --- HAZARDS column (center) ---
	_haz_header = _make_label("HAZARDS", 22, COL_HAZ, Vector3(col_mid, top, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_haz_behavior = _make_label("Behavior: —", 18, COL_VALUE, Vector3(col_mid, top - 0.04, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_haz_concurrent = _make_label("Max Concurrent: —", 18, COL_VALUE, Vector3(col_mid, top - 0.065, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_haz_types = _make_label("Types: —", 16, COL_VALUE, Vector3(col_mid, top - 0.11, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_haz_personalities = _make_label("Personalities: —", 16, COL_VALUE, Vector3(col_mid, top - 0.30, 0.003), HORIZONTAL_ALIGNMENT_LEFT)

	# --- CAPABILITY column (right) ---
	_cap_header = _make_label("CAPABILITY", 22, COL_CAP, Vector3(col_right, top, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_cap_level = _make_label("Level: —", 20, COL_VALUE, Vector3(col_right, top - 0.04, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_cap_verbs = _make_label("Hand Verbs: —", 16, COL_VALUE, Vector3(col_right, top - 0.09, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_cap_movement = _make_label("Movement: —", 16, COL_VALUE, Vector3(col_right, top - 0.30, 0.003), HORIZONTAL_ALIGNMENT_LEFT)
	_cap_modes = _make_label("Modes: —", 16, COL_VALUE, Vector3(col_right, top - 0.37, 0.003), HORIZONTAL_ALIGNMENT_LEFT)


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
	_stage_label.text = "Stage: %d / %s" % [_current_stage_order, _current_stage_name]


func _refresh_ecosystem() -> void:
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
	lbl.width = (panel_size.x / 3.0 - 0.06) / 0.001  # Wrap within column
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(lbl)
	return lbl


func _short_name(hazard_type: String) -> String:
	# "miura_crawler" → "miura", "kaleidocycle_enemy" → "kaleido"
	var parts := hazard_type.split("_")
	if parts.size() > 0:
		var name := parts[0]
		return name.substr(0, 8) if name.length() > 8 else name
	return hazard_type


## Grid system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("panel_scale"):
		var s := float(config_data["panel_scale"])
		scale = Vector3(s, s, s)
	if config_data.has("show_log") and not config_data["show_log"]:
		if _log_label:
			_log_label.visible = false

class_name ProjectDashboardOverlay
extends CanvasLayer

## Visual control panel for project completeness.
## Toggle with P key. Shows color-coded dashboard of all sequences × all layers.
## Reads sequence_requirements.json and cross-references actual files on disk.

@export var toggle_key: Key = KEY_P
@export var slide_duration: float = 0.25

# ── Paths ────────────────────────────────────────────────────────────────
const REQUIREMENTS_PATH := "res://commons/maps/sequence_requirements.json"
const RELEASE_GATES_PATH := "res://doc/reports/RELEASE_GATES.json"
const RELEASE_GATES_TOGGLES_USER_PATH := "user://project_dashboard_gate_toggles.json"
const RELEASE_GATES_TOGGLES_SHARED_PATH := "res://doc/reports/RELEASE_GATES_TOGGLES.json"
const SEQUENCES_DIR := "res://commons/maps/sequences/"
const MAPS_DIR := "res://commons/maps/"
const LAB_DIR := "res://commons/maps/Lab/"
const ALGO_DIR := "res://algorithms/"
const REGISTRY_DIR := "res://commons/artifacts/registry/"
const MAP_RULES_REPORT_PATH := "res://doc/reports/MAP_RULES_REPORT.json"
const OVERSIGHT_URL := "http://localhost:3001"

# ── QFEP Phase Colors (from WorldMapDataProvider) ────────────────────────
const PHASE_COLORS := {
	"F_order": Color("#4A90D9"),
	"oscillation": Color("#9B59B6"),
	"E_entropy": Color("#E74C3C"),
	"lambda_edge": Color("#F39C12"),
	"integration": Color("#2ECC71"),
	"synthesis": Color("#E91E63")
}
const PHASE_ORDER := ["F_order", "oscillation", "E_entropy", "lambda_edge", "integration", "synthesis"]
const PHASE_LABELS := {
	"F_order": "F order",
	"oscillation": "Oscillation",
	"E_entropy": "E entropy",
	"lambda_edge": "Lambda edge",
	"integration": "Integration",
	"synthesis": "Synthesis"
}

# ── Dashboard Colors ─────────────────────────────────────────────────────
const COLOR_BG := Color(0.04, 0.05, 0.08, 1.0)
const COLOR_PANEL := Color(0.06, 0.08, 0.12, 1.0)
const COLOR_BORDER := Color(0.15, 0.25, 0.4, 1.0)
const COLOR_ACCENT := Color(0.22, 0.66, 0.98, 1.0)
const COLOR_TEXT := Color(0.82, 0.88, 0.96, 1.0)
const COLOR_TEXT_DIM := Color(0.45, 0.50, 0.58, 1.0)
const COLOR_TEXT_BRIGHT := Color(1.0, 1.0, 1.0, 1.0)

const COLOR_COMPLETE := Color(0.2, 0.75, 0.4, 1.0)
const COLOR_PARTIAL := Color(0.9, 0.75, 0.2, 1.0)
const COLOR_CRITICAL := Color(0.9, 0.25, 0.2, 1.0)
const COLOR_DEFERRED := Color(0.35, 0.35, 0.4, 1.0)
const COLOR_MISSING := Color(0.55, 0.15, 0.15, 1.0)

const COLOR_TAB_ACTIVE := Color(0.12, 0.18, 0.28, 1.0)
const COLOR_TAB_INACTIVE := Color(0.06, 0.08, 0.12, 1.0)
const COLOR_CARD_BG := Color(0.08, 0.10, 0.16, 1.0)

# ── Grid column definitions ─────────────────────────────────────────────
const GRID_COLUMNS := ["Maps", "Algo", "Blurb", "Summ", "Tech", "Crit", "PostLab", "QFEP", "Nature", "Caps", "Book", "Wiki"]

# ── State ────────────────────────────────────────────────────────────────
var _is_open: bool = false
var _is_animating: bool = false
var _tween: Tween = null
var _current_tab: int = 0  # 0=Overview, 1=Grid, 2=Graph, 3=Issues

# ── Data ─────────────────────────────────────────────────────────────────
var _requirements: Dictionary = {}
var _spine_results: Array[Dictionary] = []
var _branch_results: Array[Dictionary] = []
var _all_results: Array[Dictionary] = []
var _mismatches: Array[Dictionary] = []
var _issues: Array[Dictionary] = []
var _summary: Dictionary = {}
var _release_gates: Dictionary = {}
var _release_gates_loaded: bool = false
var _release_gate_enabled: Dictionary = {}
var _data_loaded: bool = false
var _map_rules_data: Dictionary = {}
var _map_rules_loaded: bool = false

# ── UI Nodes ─────────────────────────────────────────────────────────────
var _root: Control
var _backdrop: ColorRect
var _main_panel: PanelContainer
var _title_bar: HBoxContainer
var _tab_buttons: Array[Button] = []
var _tab_containers: Array[Control] = []
var _status_label: Label
var _detail_popup: PanelContainer
var _detail_label: RichTextLabel

# Tab-specific
var _overview_container: VBoxContainer
var _grid_scroll: ScrollContainer
var _grid_container: VBoxContainer
var _graph_control: Control
var _issues_scroll: ScrollContainer
var _issues_container: VBoxContainer
var _map_rules_scroll: ScrollContainer
var _map_rules_container: VBoxContainer
var _task_popup: PanelContainer
var _task_popup_title: Label
var _task_text_edit: TextEdit
var _task_status_label: Label
var _task_map_name: String = ""
var _task_seq_id: String = ""
var _json_editor_popup: PanelContainer
var _json_editor_title: Label
var _json_editor_text: TextEdit
var _json_editor_status: Label
var _json_editor_path: String = ""


# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 140
	visible = true
	_build_ui()
	_set_panel_hidden()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return

	if _is_foreign_text_focused():
		return

	if key.keycode == toggle_key or key.physical_keycode == toggle_key:
		_toggle()
		get_viewport().set_input_as_handled()
		return

	if not _is_open:
		return

	# Tab switching: 1-4
	if not key.ctrl_pressed:
		match key.keycode:
			KEY_1:
				_switch_tab(0)
				get_viewport().set_input_as_handled()
			KEY_2:
				_switch_tab(1)
				get_viewport().set_input_as_handled()
			KEY_3:
				_switch_tab(2)
				get_viewport().set_input_as_handled()
			KEY_4:
				_switch_tab(3)
				get_viewport().set_input_as_handled()
			KEY_5:
				_switch_tab(4)
				get_viewport().set_input_as_handled()

	if key.keycode == KEY_ESCAPE:
		if _json_editor_popup and _json_editor_popup.visible:
			_json_editor_popup.visible = false
		elif _task_popup and _task_popup.visible:
			_task_popup.visible = false
		elif _detail_popup and _detail_popup.visible:
			_detail_popup.visible = false
		else:
			_toggle()
		get_viewport().set_input_as_handled()


func _is_foreign_text_focused() -> bool:
	var viewport := get_viewport()
	if not viewport:
		return false
	var focused := viewport.gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit


# ═══════════════════════════════════════════════════════════════════════════
# TOGGLE / SLIDE
# ═══════════════════════════════════════════════════════════════════════════

func _toggle() -> void:
	if _is_animating:
		return
	if _is_open:
		_slide_out()
	else:
		if not _data_loaded:
			_load_data()
		_slide_in()


func _slide_in() -> void:
	_is_open = true
	_is_animating = true
	_main_panel.visible = true
	_backdrop.visible = true
	_backdrop.color.a = 0.0
	_main_panel.modulate.a = 0.0

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(true)
	_tween.tween_property(_backdrop, "color:a", 0.6, slide_duration)
	_tween.tween_property(_main_panel, "modulate:a", 1.0, slide_duration)
	_tween.set_parallel(false)
	_tween.tween_callback(func() -> void:
		_is_animating = false
	)


func _slide_out() -> void:
	_is_animating = true
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(true)
	_tween.tween_property(_backdrop, "color:a", 0.0, slide_duration)
	_tween.tween_property(_main_panel, "modulate:a", 0.0, slide_duration)
	_tween.set_parallel(false)
	_tween.tween_callback(func() -> void:
		_is_open = false
		_is_animating = false
		_main_panel.visible = false
		_backdrop.visible = false
	)


func _set_panel_hidden() -> void:
	if _main_panel:
		_main_panel.visible = false
	if _backdrop:
		_backdrop.visible = false


# ═══════════════════════════════════════════════════════════════════════════
# DATA LOADING
# ═══════════════════════════════════════════════════════════════════════════

func _load_data() -> void:
	_requirements = _read_json(REQUIREMENTS_PATH)
	if _requirements.is_empty():
		push_warning("ProjectDashboard: Could not load sequence_requirements.json")
		return

	_release_gates = _read_json(RELEASE_GATES_PATH)
	_release_gates_loaded = not _release_gates.is_empty()
	_load_release_gate_toggles()
	_sync_release_gate_toggles_with_report()

	_spine_results.clear()
	_branch_results.clear()
	_all_results.clear()
	_mismatches.clear()
	_issues.clear()

	# Process spine sequences
	var spine_seqs: Dictionary = _requirements.get("spine_sequences", {}) as Dictionary
	for seq_name in spine_seqs:
		var seq_data: Dictionary = spine_seqs[seq_name] as Dictionary
		var result := _validate_sequence(seq_name, seq_data, "spine")
		_spine_results.append(result)

	# Sort spine by spine_order
	_spine_results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("spine_order", 99)) < int(b.get("spine_order", 99))
	)

	# Process branch sequences
	var branch_seqs: Dictionary = _requirements.get("branch_sequences", {}) as Dictionary
	for seq_name in branch_seqs:
		var seq_data: Dictionary = branch_seqs[seq_name] as Dictionary
		var result := _validate_sequence(seq_name, seq_data, "branch")
		_branch_results.append(result)

	# Sort branches by phase then name
	_branch_results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: int = PHASE_ORDER.find(str(a.get("phase", "")))
		var pb: int = PHASE_ORDER.find(str(b.get("phase", "")))
		if pa != pb:
			return pa < pb
		return str(a.get("name", "")) < str(b.get("name", ""))
	)

	_all_results = _spine_results + _branch_results

	# Collect mismatches
	for r in _all_results:
		_mismatches.append_array(r.get("mismatches", []))

	# Build summary
	_build_summary()

	# Build issues list
	_build_issues()

	# Load map rules report
	_map_rules_data = _read_json(MAP_RULES_REPORT_PATH)
	_map_rules_loaded = not _map_rules_data.is_empty()

	_data_loaded = true

	# Refresh UI
	_populate_overview_tab()
	_populate_grid_tab()
	_populate_graph_tab()
	_populate_issues_tab()
	_populate_map_rules_tab()

	if _status_label:
		var mismatch_text := ""
		if _mismatches.size() > 0:
			mismatch_text = "  |  %d mismatches" % _mismatches.size()
		var rules_text := ""
		if _map_rules_loaded:
			var rules_summary: Dictionary = _map_rules_data.get("summary", {}) as Dictionary
			var rules_fail: int = int(rules_summary.get("fail", 0))
			var rules_ok: int = int(rules_summary.get("ok", 0))
			rules_text = "  |  rules: %d OK, %d fail" % [rules_ok, rules_fail]
		_status_label.text = "Loaded %d sequences%s%s" % [_all_results.size(), mismatch_text, rules_text]


func _validate_sequence(seq_name: String, seq_data: Dictionary, seq_type: String) -> Dictionary:
	var result: Dictionary = {
		"name": seq_name,
		"type": seq_type,
		"phase": "",
		"spine_order": seq_data.get("spine_order", 99),
		"branches_from": seq_data.get("branches_from", null),
		"maps_expected": 0,
		"maps_found": 0,
		"map_list": [],
		"blurb": {"have": 0, "of": 0},
		"summary": {"have": 0, "of": 0},
		"technical": {"have": 0, "of": 0},
		"critical": {"have": 0, "of": 0},
		"post_lab": false,
		"algo_exists": false,
		"qfep_complete": false,
		"nature_complete": false,
		"capability_complete": false,
		"book_ready": false,
		"wiki_ready": false,
		"deferred": false,
		"mismatches": [],
		"missing_maps_blurb": [],
		"missing_maps_summary": [],
		"missing_maps_technical": [],
		"missing_maps_critical": [],
	}

	# Phase
	var qfep: Dictionary = seq_data.get("qfep", {}) as Dictionary
	result["phase"] = qfep.get("phase", seq_data.get("phase", ""))

	# Check deferred
	var maps_data: Dictionary = seq_data.get("maps", {}) as Dictionary
	if maps_data.get("status", "") == "deferred":
		result["deferred"] = true
		result["maps_expected"] = maps_data.get("deferred", 0)
		return result

	# Maps from sequence file
	var map_list: Array = _get_sequence_map_list(seq_name)
	result["map_list"] = map_list
	result["maps_expected"] = maps_data.get("count", map_list.size())

	# Count maps with map_data.json
	var maps_found: int = 0
	for map_name in map_list:
		if _file_exists(MAPS_DIR + str(map_name) + "/map_data.json"):
			maps_found += 1
	result["maps_found"] = maps_found

	# Count .md files per map
	var blurb_count: int = 0
	var summary_count: int = 0
	var technical_count: int = 0
	var critical_count: int = 0
	var missing_blurb: Array[String] = []
	var missing_summary: Array[String] = []
	var missing_technical: Array[String] = []
	var missing_critical: Array[String] = []

	for map_name in map_list:
		var map_str: String = str(map_name)
		var base_path: String = MAPS_DIR + map_str + "/"
		if _file_exists(base_path + "blurb.md"):
			blurb_count += 1
		else:
			missing_blurb.append(map_str)
		if _file_exists(base_path + "summary.md"):
			summary_count += 1
		else:
			missing_summary.append(map_str)
		if _file_exists(base_path + "technical.md"):
			technical_count += 1
		else:
			missing_technical.append(map_str)
		if _file_exists(base_path + "critical.md"):
			critical_count += 1
		else:
			missing_critical.append(map_str)

	var total: int = map_list.size()
	result["blurb"] = {"have": blurb_count, "of": total}
	result["summary"] = {"have": summary_count, "of": total}
	result["technical"] = {"have": technical_count, "of": total}
	result["critical"] = {"have": critical_count, "of": total}
	result["missing_maps_blurb"] = missing_blurb
	result["missing_maps_summary"] = missing_summary
	result["missing_maps_technical"] = missing_technical
	result["missing_maps_critical"] = missing_critical

	# Post-lab map
	result["post_lab"] = _file_exists(LAB_DIR + "map_data_post_" + seq_name + ".json")

	# Algorithm directory
	result["algo_exists"] = _dir_exists(ALGO_DIR + seq_name + "/")

	# QFEP completeness
	var qfep_ok: bool = qfep.has("phase") and str(qfep.get("phase", "")) != ""
	qfep_ok = qfep_ok and qfep.has("contribution") and str(qfep.get("contribution", "")) != ""
	result["qfep_complete"] = qfep_ok

	# Nature entry
	var nature: Dictionary = seq_data.get("nature", {}) as Dictionary
	var nature_ok: bool = str(nature.get("element", "")) != "" and str(nature.get("category", "")) != ""
	result["nature_complete"] = nature_ok

	# Capability triple
	var cap: Dictionary = seq_data.get("capability", {}) as Dictionary
	var cap_ok: bool = str(cap.get("perception", "")) != ""
	result["capability_complete"] = cap_ok

	# Book/Wiki readiness (derived from filesystem)
	result["book_ready"] = (technical_count == total) and (critical_count == total) and total > 0
	result["wiki_ready"] = (blurb_count == total) and (summary_count == total) and total > 0

	# Cross-validation: requirements claims vs filesystem
	var text_data: Dictionary = seq_data.get("text", {}) as Dictionary
	for md_type in ["blurb", "summary", "technical", "critical"]:
		var md_info = text_data.get(md_type, {})
		if md_info is Dictionary and md_info.has("have"):
			var claimed: int = int(md_info.get("have", 0))
			var actual: int = result[md_type]["have"]
			if claimed != actual:
				result["mismatches"].append({
					"sequence": seq_name,
					"field": "text.%s.have" % md_type,
					"claimed": claimed,
					"actual": actual,
				})

	return result


func _get_sequence_map_list(seq_name: String) -> Array:
	var data := _read_json(SEQUENCES_DIR + seq_name + ".json")
	if data.is_empty():
		return []

	var sequences: Dictionary = data.get("sequences", {}) as Dictionary
	for key in sequences:
		var seq_entry: Dictionary = sequences[key] as Dictionary
		if seq_entry.has("maps"):
			var maps = seq_entry["maps"]
			if maps is Array:
				return maps
	return []


func _build_summary() -> void:
	var total: int = _all_results.size()
	var book_ready: int = 0
	var wiki_ready: int = 0
	var total_maps: int = 0
	var missing_blurb: int = 0
	var missing_summary: int = 0
	var missing_technical: int = 0
	var missing_critical: int = 0
	var missing_post_lab: int = 0

	for r in _all_results:
		if bool(r.get("deferred", false)):
			continue
		if bool(r.get("book_ready", false)):
			book_ready += 1
		if bool(r.get("wiki_ready", false)):
			wiki_ready += 1
		var blurb_d: Dictionary = r.get("blurb", {}) as Dictionary
		var maps: int = int(blurb_d.get("of", 0))
		total_maps += maps
		missing_blurb += maps - int(blurb_d.get("have", 0))
		var summ_d: Dictionary = r.get("summary", {}) as Dictionary
		missing_summary += maps - int(summ_d.get("have", 0))
		var tech_d: Dictionary = r.get("technical", {}) as Dictionary
		missing_technical += maps - int(tech_d.get("have", 0))
		var crit_d: Dictionary = r.get("critical", {}) as Dictionary
		missing_critical += maps - int(crit_d.get("have", 0))
		if not bool(r.get("post_lab", false)) and not bool(r.get("deferred", false)):
			missing_post_lab += 1

	_summary = {
		"total_sequences": total,
		"spine_count": _spine_results.size(),
		"branch_count": _branch_results.size(),
		"book_ready": book_ready,
		"wiki_ready": wiki_ready,
		"total_maps": total_maps,
		"missing_blurb": missing_blurb,
		"missing_summary": missing_summary,
		"missing_technical": missing_technical,
		"missing_critical": missing_critical,
		"total_missing_md": missing_blurb + missing_summary + missing_technical + missing_critical,
		"missing_post_lab": missing_post_lab,
		"mismatch_count": _mismatches.size(),
	}


func _build_issues() -> void:
	_issues.clear()

	# Critical: sequences with 0% coverage in any md type
	for r in _all_results:
		if bool(r.get("deferred", false)):
			continue
		var blurb_info: Dictionary = r.get("blurb", {}) as Dictionary
		var total: int = int(blurb_info.get("of", 0))
		if total == 0:
			continue

		var blurb_dict: Dictionary = r.get("blurb", {}) as Dictionary
		var summ_dict: Dictionary = r.get("summary", {}) as Dictionary
		var tech_dict: Dictionary = r.get("technical", {}) as Dictionary
		var crit_dict: Dictionary = r.get("critical", {}) as Dictionary
		var blurb_have: int = int(blurb_dict.get("have", 0))
		var summ_have: int = int(summ_dict.get("have", 0))
		var tech_have: int = int(tech_dict.get("have", 0))
		var crit_have: int = int(crit_dict.get("have", 0))

		var missing_count: int = (total - blurb_have) + (total - summ_have) + (total - tech_have) + (total - crit_have)

		if missing_count > 0:
			var priority: String = "critical" if (summ_have == 0 or tech_have == 0 or crit_have == 0) else "partial"
			var desc: String = ""
			var gaps: Array[String] = []
			if blurb_have < total:
				gaps.append("%d/%d blurb" % [blurb_have, total])
			if summ_have < total:
				gaps.append("%d/%d summary" % [summ_have, total])
			if tech_have < total:
				gaps.append("%d/%d technical" % [tech_have, total])
			if crit_have < total:
				gaps.append("%d/%d critical" % [crit_have, total])
			desc = ", ".join(gaps)

			_issues.append({
				"priority": priority,
				"category": "text",
				"sequence": str(r.get("name", "")),
				"description": desc,
				"missing_count": missing_count,
				"maps": total,
			})

	# Missing post-lab maps
	for r in _all_results:
		if bool(r.get("deferred", false)):
			continue
		if not bool(r.get("post_lab", false)):
			_issues.append({
				"priority": "warning",
				"category": "post_lab",
				"sequence": str(r.get("name", "")),
				"description": "Missing post-lab map",
				"missing_count": 1,
			})

	# Mismatches
	for m in _mismatches:
		_issues.append({
			"priority": "mismatch",
			"category": "data",
			"sequence": str(m.get("sequence", "")),
			"description": "%s: claimed %d, actual %d" % [str(m.get("field", "")), int(m.get("claimed", 0)), int(m.get("actual", 0))],
			"missing_count": 0,
		})

	# Sort: critical first (by missing_count desc), then partial, then warnings
	var priority_order: Dictionary = {"critical": 0, "partial": 1, "mismatch": 2, "warning": 3}
	_issues.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa: int = int(priority_order.get(str(a.get("priority", "warning")), 9))
		var pb: int = int(priority_order.get(str(b.get("priority", "warning")), 9))
		if pa != pb:
			return pa < pb
		return int(a.get("missing_count", 0)) > int(b.get("missing_count", 0))
	)


# ═══════════════════════════════════════════════════════════════════════════
# FILE HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	if json.data is Dictionary:
		return json.data
	return {}


func _load_release_gate_toggles() -> void:
	_release_gate_enabled.clear()
	var toggle_data: Dictionary = _read_json(RELEASE_GATES_TOGGLES_SHARED_PATH)
	if toggle_data.is_empty():
		toggle_data = _read_json(RELEASE_GATES_TOGGLES_USER_PATH)
	var enabled_value: Variant = toggle_data.get("enabled", {})
	if enabled_value is Dictionary:
		var enabled_dict: Dictionary = enabled_value as Dictionary
		for key in enabled_dict.keys():
			var gate_id: String = str(key)
			_release_gate_enabled[gate_id] = bool(enabled_dict.get(key, true))


func _save_release_gate_toggles() -> void:
	var payload: Dictionary = {
		"enabled": _release_gate_enabled
	}
	_write_json(RELEASE_GATES_TOGGLES_USER_PATH, payload)
	_write_json(RELEASE_GATES_TOGGLES_SHARED_PATH, payload)


func _write_json(path: String, data: Dictionary) -> void:
	var resolved_path: String = path
	if path.begins_with("res://"):
		resolved_path = ProjectSettings.globalize_path(path)
	var file: FileAccess = FileAccess.open(resolved_path, FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify(data, "\t"))


func _extract_release_gates() -> Array[Dictionary]:
	var gates: Array[Dictionary] = []
	var gates_value: Variant = _release_gates.get("gates", [])
	if gates_value is Array:
		var gates_raw: Array = gates_value as Array
		for gate_item in gates_raw:
			if gate_item is Dictionary:
				gates.append(gate_item as Dictionary)
	return gates


func _sync_release_gate_toggles_with_report() -> void:
	var gates: Array[Dictionary] = _extract_release_gates()
	var valid_ids: Dictionary = {}
	var changed: bool = false

	for gate in gates:
		var gate_id: String = str(gate.get("id", ""))
		if gate_id == "":
			continue
		valid_ids[gate_id] = true
		if not _release_gate_enabled.has(gate_id):
			_release_gate_enabled[gate_id] = true
			changed = true

	var existing_keys: Array = _release_gate_enabled.keys()
	for key in existing_keys:
		var gate_key: String = str(key)
		if not valid_ids.has(gate_key):
			_release_gate_enabled.erase(gate_key)
			changed = true

	if changed:
		_save_release_gate_toggles()


func _is_release_gate_enabled(gate_id: String) -> bool:
	return bool(_release_gate_enabled.get(gate_id, true))


func _set_release_gates_enabled(gate_ids: Array[String], enabled: bool) -> void:
	for gate_id in gate_ids:
		if gate_id == "":
			continue
		_release_gate_enabled[gate_id] = enabled
	_save_release_gate_toggles()
	_populate_overview_tab()


func _reset_release_gate_toggles_to_default() -> void:
	_release_gate_enabled.clear()
	_sync_release_gate_toggles_with_report()
	_save_release_gate_toggles()
	_populate_overview_tab()


func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)


func _dir_exists(path: String) -> bool:
	return DirAccess.dir_exists_absolute(path)


# ═══════════════════════════════════════════════════════════════════════════
# UI CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	# Root control — passes input through
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Backdrop
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_input)
	_root.add_child(_backdrop)

	# Main panel — centered, 92% of screen
	_main_panel = PanelContainer.new()
	_main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main_panel.anchor_left = 0.04
	_main_panel.anchor_right = 0.96
	_main_panel.anchor_top = 0.03
	_main_panel.anchor_bottom = 0.97
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL
	panel_style.set_border_width_all(2)
	panel_style.border_color = COLOR_BORDER
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(0)
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	_root.add_child(_main_panel)

	# Main vertical layout
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 0)
	_main_panel.add_child(main_vbox)

	# Title bar
	_build_title_bar(main_vbox)

	# Tab bar
	_build_tab_bar(main_vbox)

	# Tab content area — each tab is stacked in its own container
	# We use a Control with anchors as the tab area
	var tab_area := Control.new()
	tab_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_area.clip_contents = true
	main_vbox.add_child(tab_area)

	# Create tab containers — each one fills the tab_area via anchors
	_build_overview_tab(tab_area)
	_build_grid_tab(tab_area)
	_build_graph_tab(tab_area)
	_build_issues_tab(tab_area)
	_build_map_rules_tab(tab_area)

	# Status bar
	_build_status_bar(main_vbox)

	# Detail popup (hidden by default)
	_build_detail_popup()

	# Task creation popup (hidden by default)
	_build_task_popup()

	# JSON editor popup (hidden by default)
	_build_json_editor_popup()

	# Show first tab
	_switch_tab(0)


func _build_title_bar(parent: Control) -> void:
	var bar := PanelContainer.new()
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.05, 0.07, 0.10, 1.0)
	bar_style.set_content_margin_all(10)
	bar_style.content_margin_left = 16
	bar_style.content_margin_right = 16
	bar_style.corner_radius_top_left = 8
	bar_style.corner_radius_top_right = 8
	bar.add_theme_stylebox_override("panel", bar_style)
	parent.add_child(bar)

	_title_bar = HBoxContainer.new()
	_title_bar.add_theme_constant_override("separation", 12)
	bar.add_child(_title_bar)

	var title := Label.new()
	title.text = "PROJECT DASHBOARD"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	_title_bar.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_bar.add_child(spacer)

	var hint := Label.new()
	hint.text = "P: toggle  |  1-5: tabs  |  ESC: close"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	_title_bar.add_child(hint)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	close_btn.pressed.connect(_toggle)
	_title_bar.add_child(close_btn)


func _build_tab_bar(parent: Control) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 2)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 0)
	parent.add_child(margin)
	margin.add_child(bar)

	var tab_names := ["Overview", "Sequence Grid", "Dependency Graph", "Issues & Todos", "Map Rules"]
	_tab_buttons.clear()
	for i in range(tab_names.size()):
		var btn := Button.new()
		btn.text = " %d. %s " % [i + 1, tab_names[i]]
		btn.flat = false
		btn.add_theme_font_size_override("font_size", 13)
		_style_tab_button(btn, i == 0)
		btn.pressed.connect(_switch_tab.bind(i))
		bar.add_child(btn)
		_tab_buttons.append(btn)


func _build_overview_tab(parent: Control) -> void:
	_overview_container = VBoxContainer.new()
	_overview_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overview_container.add_theme_constant_override("separation", 12)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	parent.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	scroll.add_child(_overview_container)
	_overview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_tab_containers.append(margin)


func _build_grid_tab(parent: Control) -> void:
	_grid_scroll = ScrollContainer.new()
	_grid_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	parent.add_child(margin)
	margin.add_child(_grid_scroll)

	_grid_container = VBoxContainer.new()
	_grid_container.add_theme_constant_override("separation", 1)
	_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_scroll.add_child(_grid_container)

	_tab_containers.append(margin)


func _build_graph_tab(parent: Control) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	parent.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(scroll)

	_graph_control = Control.new()
	_graph_control.custom_minimum_size = Vector2(1400, 1800)
	scroll.add_child(_graph_control)

	# The graph draws itself via a custom draw node
	var draw_node := Control.new()
	draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_node.draw.connect(_draw_graph.bind(draw_node))
	draw_node.mouse_filter = Control.MOUSE_FILTER_PASS
	_graph_control.add_child(draw_node)

	_tab_containers.append(margin)


func _build_issues_tab(parent: Control) -> void:
	_issues_scroll = ScrollContainer.new()
	_issues_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_issues_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	parent.add_child(margin)
	margin.add_child(_issues_scroll)

	_issues_container = VBoxContainer.new()
	_issues_container.add_theme_constant_override("separation", 4)
	_issues_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_issues_scroll.add_child(_issues_container)

	_tab_containers.append(margin)


func _build_status_bar(parent: Control) -> void:
	var bar := PanelContainer.new()
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	bar_style.set_content_margin_all(6)
	bar_style.content_margin_left = 16
	bar_style.corner_radius_bottom_left = 8
	bar_style.corner_radius_bottom_right = 8
	bar.add_theme_stylebox_override("panel", bar_style)
	parent.add_child(bar)

	_status_label = Label.new()
	_status_label.text = "Press P to load data"
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	bar.add_child(_status_label)


func _build_detail_popup() -> void:
	_detail_popup = PanelContainer.new()
	_detail_popup.visible = false
	_detail_popup.set_anchors_preset(Control.PRESET_CENTER)
	_detail_popup.custom_minimum_size = Vector2(400, 300)
	_detail_popup.anchor_left = 0.3
	_detail_popup.anchor_right = 0.7
	_detail_popup.anchor_top = 0.2
	_detail_popup.anchor_bottom = 0.8
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	style.set_border_width_all(2)
	style.border_color = COLOR_ACCENT
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	_detail_popup.add_theme_stylebox_override("panel", style)
	_root.add_child(_detail_popup)

	var vbox := VBoxContainer.new()
	_detail_popup.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var popup_title := Label.new()
	popup_title.text = "Detail"
	popup_title.add_theme_font_size_override("font_size", 15)
	popup_title.add_theme_color_override("font_color", COLOR_ACCENT)
	popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(popup_title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.flat = true
	close_btn.pressed.connect(func() -> void: _detail_popup.visible = false)
	header.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_detail_label = RichTextLabel.new()
	_detail_label.bbcode_enabled = true
	_detail_label.fit_content = true
	_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_label.add_theme_font_size_override("normal_font_size", 12)
	_detail_label.add_theme_color_override("default_color", COLOR_TEXT)
	scroll.add_child(_detail_label)


# ═══════════════════════════════════════════════════════════════════════════
# TAB SWITCHING
# ═══════════════════════════════════════════════════════════════════════════

func _switch_tab(index: int) -> void:
	_current_tab = index
	for i in range(_tab_containers.size()):
		_tab_containers[i].visible = (i == index)
	for i in range(_tab_buttons.size()):
		_style_tab_button(_tab_buttons[i], i == index)

	if index == 2 and _graph_control:
		# Trigger graph redraw
		for child in _graph_control.get_children():
			child.queue_redraw()


func _style_tab_button(btn: Button, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_TAB_ACTIVE if active else COLOR_TAB_INACTIVE
	style.set_border_width_all(1)
	style.border_color = COLOR_ACCENT if active else COLOR_BORDER
	style.border_width_bottom = 2 if active else 1
	style.set_corner_radius_all(4)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.set_content_margin_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", COLOR_TEXT_BRIGHT if active else COLOR_TEXT_DIM)


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_toggle()


# ═══════════════════════════════════════════════════════════════════════════
# TAB 1: OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════

func _populate_overview_tab() -> void:
	_clear_children(_overview_container)

	# ── Section: Summary Stats ───────────────────────────────────────────
	var section_title := _make_section_label("PROJECT STATUS")
	_overview_container.add_child(section_title)

	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 8)
	_overview_container.add_child(cards_row)

	var s_total: int = int(_summary.get("total_sequences", 0))
	var s_spine: int = int(_summary.get("spine_count", 0))
	var s_branch: int = int(_summary.get("branch_count", 0))
	var s_maps: int = int(_summary.get("total_maps", 0))
	var s_book: int = int(_summary.get("book_ready", 0))
	var s_wiki: int = int(_summary.get("wiki_ready", 0))
	var s_missing_md: int = int(_summary.get("total_missing_md", 0))
	var s_mismatch: int = int(_summary.get("mismatch_count", 0))

	_add_stat_card(cards_row, "Sequences", "%d" % s_total,
		"%d spine + %d branch" % [s_spine, s_branch], COLOR_ACCENT)
	_add_stat_card(cards_row, "Total Maps", "%d" % s_maps, "", COLOR_ACCENT)
	_add_stat_card(cards_row, "Book Ready", "%d/%d" % [s_book, s_total],
		"%d%%" % _percent(s_book, maxi(s_total, 1)),
		COLOR_COMPLETE if s_book > 15 else COLOR_PARTIAL)
	_add_stat_card(cards_row, "Wiki Ready", "%d/%d" % [s_wiki, s_total],
		"%d%%" % _percent(s_wiki, maxi(s_total, 1)),
		COLOR_COMPLETE if s_wiki > 15 else COLOR_PARTIAL)
	_add_stat_card(cards_row, "Missing .md", "%d" % s_missing_md,
		"files needed", COLOR_CRITICAL if s_missing_md > 100 else COLOR_PARTIAL)
	_add_stat_card(cards_row, "Mismatches", "%d" % s_mismatch,
		"stale data", COLOR_CRITICAL if s_mismatch > 0 else COLOR_COMPLETE)
	_add_release_gates_section(_overview_container)

	# ── Section: Deliverable Progress ────────────────────────────────────
	_overview_container.add_child(_make_spacer(8))
	_overview_container.add_child(_make_section_label("DELIVERABLE PROGRESS"))

	var s_miss_tech: int = int(_summary.get("missing_technical", 0))
	var s_miss_crit: int = int(_summary.get("missing_critical", 0))
	var s_miss_blurb: int = int(_summary.get("missing_blurb", 0))
	var s_miss_summ: int = int(_summary.get("missing_summary", 0))

	_add_progress_row(_overview_container, "VR World (maps + algorithms)",
		s_maps, s_maps, COLOR_COMPLETE, "All maps have map_data.json")
	_add_progress_row(_overview_container, "Book (technical.md + critical.md)",
		s_maps - s_miss_tech - s_miss_crit,
		s_maps * 2, Color("#E74C3C"),
		"%d technical + %d critical missing" % [s_miss_tech, s_miss_crit])
	_add_progress_row(_overview_container, "Wiki (blurb.md + summary.md)",
		s_maps - s_miss_blurb - s_miss_summ,
		s_maps * 2, Color("#F39C12"),
		"%d blurb + %d summary missing" % [s_miss_blurb, s_miss_summ])

	# ── Section: QFEP Phase Breakdown ────────────────────────────────────
	_overview_container.add_child(_make_spacer(8))
	_overview_container.add_child(_make_section_label("QFEP PHASE BREAKDOWN"))

	for phase in PHASE_ORDER:
		var phase_seqs: Array[Dictionary] = []
		for r in _all_results:
			if str(r.get("phase", "")) == phase:
				phase_seqs.append(r)

		if phase_seqs.is_empty():
			continue

		var phase_book: int = 0
		var phase_total: int = phase_seqs.size()
		for r in phase_seqs:
			if bool(r.get("book_ready", false)):
				phase_book += 1

		var phase_color: Color = Color(PHASE_COLORS.get(phase, Color.WHITE))
		var label_text: String = str(PHASE_LABELS.get(phase, phase))
		var seq_names: Array[String] = []
		for r in phase_seqs:
			seq_names.append(str(r.get("name", "")))

		_add_phase_row(_overview_container, label_text, phase_book, phase_total, phase_color, ", ".join(seq_names))


# ═══════════════════════════════════════════════════════════════════════════
# TAB 2: SEQUENCE GRID
# ═══════════════════════════════════════════════════════════════════════════

func _populate_grid_tab() -> void:
	_clear_children(_grid_container)

	# Header row
	var header := _make_grid_row(null, true)
	_grid_container.add_child(header)

	# Separator label
	var spine_label := _make_section_label("SPINE SEQUENCES (%d)" % _spine_results.size())
	spine_label.add_theme_font_size_override("font_size", 12)
	_grid_container.add_child(spine_label)

	for r in _spine_results:
		var row := _make_grid_row(r, false)
		_grid_container.add_child(row)

	var branch_label := _make_section_label("BRANCH SEQUENCES (%d)" % _branch_results.size())
	branch_label.add_theme_font_size_override("font_size", 12)
	_grid_container.add_child(branch_label)

	for r in _branch_results:
		var row := _make_grid_row(r, false)
		_grid_container.add_child(row)


func _make_grid_row(result: Variant, is_header: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	if is_header:
		# Name column (wider)
		var name_label := _make_grid_cell("Sequence", COLOR_TEXT_DIM, 160)
		row.add_child(name_label)
		# Phase
		var phase_label := _make_grid_cell("Phase", COLOR_TEXT_DIM, 80)
		row.add_child(phase_label)
		# Data columns
		for col_name in GRID_COLUMNS:
			var cell := _make_grid_cell(col_name, COLOR_TEXT_DIM, 55)
			row.add_child(cell)
		return row

	var r: Dictionary = result
	var seq_name: String = str(r.get("name", ""))
	var is_deferred: bool = bool(r.get("deferred", false))
	var phase: String = str(r.get("phase", ""))

	# Name
	var name_cell := _make_grid_cell(seq_name, COLOR_TEXT, 160)
	row.add_child(name_cell)

	# Phase color indicator
	var phase_color: Color = Color(PHASE_COLORS.get(phase, COLOR_DEFERRED))
	var phase_cell := _make_colored_cell(phase.substr(0, 6) if phase.length() > 0 else "--", phase_color.darkened(0.3), 80)
	row.add_child(phase_cell)

	if is_deferred:
		for col_name in GRID_COLUMNS:
			var cell := _make_colored_cell("DEF", COLOR_DEFERRED, 55)
			row.add_child(cell)
		return row

	# Maps
	var maps_expected: int = int(r.get("maps_expected", 0))
	var maps_found: int = int(r.get("maps_found", 0))
	row.add_child(_make_ratio_cell(maps_found, maps_expected, 55, seq_name, "maps"))

	# Algo
	var has_algo: bool = bool(r.get("algo_exists", false))
	row.add_child(_make_colored_cell("OK" if has_algo else "!!", COLOR_COMPLETE if has_algo else COLOR_MISSING, 55))

	# Blurb, Summary, Technical, Critical
	for md_type in ["blurb", "summary", "technical", "critical"]:
		var md_data: Dictionary = r.get(md_type, {}) as Dictionary
		var have: int = int(md_data.get("have", 0))
		var of_count: int = int(md_data.get("of", 0))
		row.add_child(_make_ratio_cell(have, of_count, 55, seq_name, str(md_type)))

	# PostLab
	var has_post_lab: bool = bool(r.get("post_lab", false))
	row.add_child(_make_colored_cell("OK" if has_post_lab else "!!", COLOR_COMPLETE if has_post_lab else COLOR_MISSING, 55))

	# QFEP
	var has_qfep: bool = bool(r.get("qfep_complete", false))
	row.add_child(_make_colored_cell("OK" if has_qfep else "!!", COLOR_COMPLETE if has_qfep else COLOR_MISSING, 55))

	# Nature
	var has_nature: bool = bool(r.get("nature_complete", false))
	row.add_child(_make_colored_cell("OK" if has_nature else "!!", COLOR_COMPLETE if has_nature else COLOR_MISSING, 55))

	# Caps
	var has_cap: bool = bool(r.get("capability_complete", false))
	row.add_child(_make_colored_cell("OK" if has_cap else "!!", COLOR_COMPLETE if has_cap else COLOR_MISSING, 55))

	# Book
	var has_book: bool = bool(r.get("book_ready", false))
	row.add_child(_make_colored_cell("OK" if has_book else "!!", COLOR_COMPLETE if has_book else COLOR_CRITICAL, 55))

	# Wiki
	var has_wiki: bool = bool(r.get("wiki_ready", false))
	row.add_child(_make_colored_cell("OK" if has_wiki else "!!", COLOR_COMPLETE if has_wiki else COLOR_CRITICAL, 55))

	return row


func _make_grid_cell(text: String, color: Color, min_width: int) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = min_width
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	label.clip_text = true
	return label


func _make_colored_cell(text: String, bg_color: Color, min_width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min_width, 20)
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color.darkened(0.5)
	style.set_border_width_all(1)
	style.border_color = bg_color.darkened(0.2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(2)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", bg_color.lightened(0.5))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _make_ratio_cell(have: int, of: int, min_width: int, seq_name: String, md_type: String) -> PanelContainer:
	var color: Color
	if of == 0:
		color = COLOR_DEFERRED
	elif have == of:
		color = COLOR_COMPLETE
	elif have > 0:
		color = COLOR_PARTIAL
	else:
		color = COLOR_CRITICAL

	var text := "%d/%d" % [have, of] if of > 0 else "--"
	var panel := _make_colored_cell(text, color, min_width)

	# Make clickable for detail
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_show_cell_detail(seq_name, md_type, have, of)
	)

	return panel


func _show_cell_detail(seq_name: String, md_type: String, have: int, of: int) -> void:
	if not _detail_popup:
		return

	var text := "[b]%s[/b] / [b]%s[/b]\n\n" % [seq_name, md_type]
	text += "Coverage: [b]%d / %d[/b]\n\n" % [have, of]

	# Find missing maps
	var result: Dictionary = {}
	for r in _all_results:
		if str(r.get("name", "")) == seq_name:
			result = r
			break

	var missing_key := "missing_maps_" + md_type
	var missing: Array = result.get(missing_key, [])
	if missing.size() > 0:
		text += "[color=#E74C3C]Missing %s.md for:[/color]\n" % md_type
		for map_name in missing:
			text += "  - %s\n" % map_name
	else:
		text += "[color=#2ECC71]All maps have %s.md[/color]" % md_type

	_detail_label.text = text
	_detail_popup.visible = true


# ═══════════════════════════════════════════════════════════════════════════
# TAB 3: DEPENDENCY GRAPH
# ═══════════════════════════════════════════════════════════════════════════

func _populate_graph_tab() -> void:
	if _graph_control:
		for child in _graph_control.get_children():
			child.queue_redraw()


func _draw_graph(draw_node: Control) -> void:
	if _all_results.is_empty():
		return

	var area_size := draw_node.size
	draw_node.draw_rect(Rect2(Vector2.ZERO, area_size), Color(0.03, 0.04, 0.06, 1.0))

	# Layout: compute positions
	var layout: Dictionary = {}  # seq_name -> Vector2
	var margin_x := 120.0
	var margin_y := 60.0
	var center_x := area_size.x * 0.4

	# Place spine sequences vertically down the center
	var spine_spacing: float = (area_size.y - margin_y * 2) / maxf(float(_spine_results.size() - 1), 1.0)
	for i in range(_spine_results.size()):
		var r: Dictionary = _spine_results[i]
		var seq_name: String = str(r.get("name", ""))
		layout[seq_name] = Vector2(center_x, margin_y + i * spine_spacing)

	# Place branch sequences to the right of their parent
	var branch_offset_x := 200.0
	var branch_positions_used: Dictionary = {}  # y_pos -> count (avoid overlaps)
	for r in _branch_results:
		var seq_name: String = str(r.get("name", ""))
		var parent_name: String = ""
		var branches_from_val = r.get("branches_from")
		if branches_from_val:
			parent_name = str(branches_from_val)

		if layout.has(parent_name):
			var parent_pos: Vector2 = layout[parent_name] as Vector2
			var offset_count: int = int(branch_positions_used.get(parent_name, 0))
			branch_positions_used[parent_name] = offset_count + 1
			var y_offset := (offset_count - 1) * 35.0
			layout[seq_name] = Vector2(parent_pos.x + branch_offset_x + offset_count * 40, parent_pos.y + y_offset)
		else:
			# Unassigned branches — place at bottom right
			var idx: int = 0
			for r2 in _branch_results:
				var r2_from = r2.get("branches_from")
				if r2_from == null or str(r2_from) == "null":
					if str(r2.get("name", "")) == seq_name:
						break
					idx += 1
			layout[seq_name] = Vector2(area_size.x - margin_x - 100, area_size.y - margin_y - idx * 50)

	# Draw phase bands
	_draw_graph_phase_bands(draw_node, layout)

	# Draw edges (builds_on connections from requirements)
	for r in _all_results:
		var seq_name: String = str(r.get("name", ""))
		if not layout.has(seq_name):
			continue
		var pos: Vector2 = layout[seq_name] as Vector2

		# Draw branch connection (parent → child)
		var parent_val = r.get("branches_from")
		if parent_val and str(parent_val) != "null" and layout.has(str(parent_val)):
			var parent_pos: Vector2 = layout[str(parent_val)] as Vector2
			var branch_phase: String = str(r.get("phase", ""))
			var branch_color: Color = Color(PHASE_COLORS.get(branch_phase, Color.GRAY))
			draw_node.draw_line(parent_pos, pos, branch_color.darkened(0.3), 2.0, true)

	# Draw spine connections
	for i in range(_spine_results.size() - 1):
		var from_name: String = str(_spine_results[i].get("name", ""))
		var to_name: String = str(_spine_results[i + 1].get("name", ""))
		if layout.has(from_name) and layout.has(to_name):
			var from_pos: Vector2 = layout[from_name] as Vector2
			var to_pos: Vector2 = layout[to_name] as Vector2
			var phase: String = str(_spine_results[i + 1].get("phase", ""))
			var color: Color = Color(PHASE_COLORS.get(phase, Color.GRAY))
			# Glow
			draw_node.draw_line(from_pos, to_pos, Color(color, 0.25), 8.0, true)
			# Line
			draw_node.draw_line(from_pos, to_pos, color, 4.0, true)

	# Draw nodes
	for r in _all_results:
		var seq_name: String = str(r.get("name", ""))
		if not layout.has(seq_name):
			continue
		var pos: Vector2 = layout[seq_name] as Vector2
		var phase: String = str(r.get("phase", ""))
		var phase_color: Color = Color(PHASE_COLORS.get(phase, Color.GRAY))
		var is_spine: bool = str(r.get("type", "")) == "spine"
		var radius: float = 14.0 if is_spine else 9.0

		# Completeness ring (background)
		draw_node.draw_circle(pos, radius + 3, Color(0.15, 0.15, 0.2, 0.8))

		# Completeness arc
		var completeness: float = _sequence_completeness(r)
		if completeness >= 1.0:
			draw_node.draw_circle(pos, radius + 3, COLOR_COMPLETE.darkened(0.3))
		elif completeness > 0.0:
			# Partial ring — draw arc
			draw_node.draw_arc(pos, radius + 3, -PI / 2.0, -PI / 2.0 + TAU * completeness, 32, COLOR_PARTIAL, 2.0, true)

		# Main circle
		var is_def: bool = bool(r.get("deferred", false))
		draw_node.draw_circle(pos, radius, phase_color.darkened(0.2) if is_def else phase_color)

		# Label
		var font: Font = ThemeDB.fallback_font
		var font_sz: int = 10 if is_spine else 8
		var label_pos := Vector2(pos.x + radius + 6, pos.y + 4)
		draw_node.draw_string(font, label_pos, seq_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, COLOR_TEXT)


func _draw_graph_phase_bands(draw_node: Control, layout: Dictionary) -> void:
	# Group spine positions by phase to draw background bands
	var phase_ranges: Dictionary = {}
	for r in _spine_results:
		var phase: String = str(r.get("phase", ""))
		var seq_name: String = str(r.get("name", ""))
		if not layout.has(seq_name):
			continue
		var pos_vec: Vector2 = layout[seq_name] as Vector2
		var y: float = pos_vec.y
		if not phase_ranges.has(phase):
			phase_ranges[phase] = {"min_y": y, "max_y": y}
		else:
			var pr: Dictionary = phase_ranges[phase] as Dictionary
			pr["min_y"] = min(float(pr["min_y"]), y)
			pr["max_y"] = max(float(pr["max_y"]), y)

	for phase in PHASE_ORDER:
		if not phase_ranges.has(phase):
			continue
		var color: Color = Color(PHASE_COLORS.get(phase, Color.WHITE))
		var band_color := color.darkened(0.85)
		band_color.a = 0.25
		var pr: Dictionary = phase_ranges[phase] as Dictionary
		var min_y: float = float(pr["min_y"]) - 25
		var max_y: float = float(pr["max_y"]) + 25
		draw_node.draw_rect(Rect2(0, min_y, draw_node.size.x, max_y - min_y), band_color)

		# Phase label
		var font: Font = ThemeDB.fallback_font
		var label: String = str(PHASE_LABELS.get(phase, phase))
		draw_node.draw_string(font, Vector2(10, min_y + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color.darkened(0.3))


func _sequence_completeness(r: Dictionary) -> float:
	if bool(r.get("deferred", false)):
		return 0.0
	var checks: int = 0
	var passes: int = 0

	# Text coverage
	for md_type in ["blurb", "summary", "technical", "critical"]:
		var md_dict: Dictionary = r.get(md_type, {}) as Dictionary
		var have: int = int(md_dict.get("have", 0))
		var of_count: int = int(md_dict.get("of", 0))
		if of_count > 0:
			checks += 1
			if have == of_count:
				passes += 1

	# Post-lab
	checks += 1
	if bool(r.get("post_lab", false)):
		passes += 1

	# QFEP
	checks += 1
	if bool(r.get("qfep_complete", false)):
		passes += 1

	# Nature
	checks += 1
	if bool(r.get("nature_complete", false)):
		passes += 1

	# Capability
	checks += 1
	if bool(r.get("capability_complete", false)):
		passes += 1

	if checks == 0:
		return 0.0
	return float(passes) / float(checks)


# ═══════════════════════════════════════════════════════════════════════════
# TAB 4: ISSUES & TODOS
# ═══════════════════════════════════════════════════════════════════════════

func _populate_issues_tab() -> void:
	_clear_children(_issues_container)

	if _issues.is_empty():
		var label := Label.new()
		label.text = "No issues found."
		label.add_theme_color_override("font_color", COLOR_COMPLETE)
		_issues_container.add_child(label)
		return

	# Count by priority
	var critical_count: int = 0
	var partial_count: int = 0
	var mismatch_count: int = 0
	var warning_count: int = 0
	for issue in _issues:
		var p: String = str(issue.get("priority", ""))
		match p:
			"critical": critical_count += 1
			"partial": partial_count += 1
			"mismatch": mismatch_count += 1
			"warning": warning_count += 1

	# Summary
	var summary_label := Label.new()
	summary_label.text = "%d critical  |  %d partial  |  %d mismatches  |  %d warnings" % [critical_count, partial_count, mismatch_count, warning_count]
	summary_label.add_theme_font_size_override("font_size", 13)
	summary_label.add_theme_color_override("font_color", COLOR_TEXT)
	_issues_container.add_child(summary_label)
	_issues_container.add_child(_make_spacer(8))

	# Group by priority
	var current_priority := ""
	for issue in _issues:
		var priority: String = str(issue.get("priority", ""))
		if priority != current_priority:
			current_priority = priority
			var section_color: Color
			match priority:
				"critical": section_color = COLOR_CRITICAL
				"partial": section_color = COLOR_PARTIAL
				"mismatch": section_color = COLOR_ACCENT
				_: section_color = COLOR_TEXT_DIM
			var section := _make_section_label(priority.to_upper())
			section.add_theme_color_override("font_color", section_color)
			_issues_container.add_child(section)

		_add_issue_row(_issues_container, issue)


func _add_issue_row(parent: VBoxContainer, issue: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Priority icon
	var icon_text := ""
	var icon_color := COLOR_TEXT_DIM
	var issue_priority: String = str(issue.get("priority", ""))
	match issue_priority:
		"critical":
			icon_text = "!!"
			icon_color = COLOR_CRITICAL
		"partial":
			icon_text = "~~"
			icon_color = COLOR_PARTIAL
		"mismatch":
			icon_text = "<>"
			icon_color = COLOR_ACCENT
		"warning":
			icon_text = "--"
			icon_color = COLOR_PARTIAL

	var icon := Label.new()
	icon.text = icon_text
	icon.custom_minimum_size.x = 24
	icon.add_theme_font_size_override("font_size", 12)
	icon.add_theme_color_override("font_color", icon_color)
	row.add_child(icon)

	# Sequence name
	var name_label := Label.new()
	name_label.text = str(issue.get("sequence", ""))
	name_label.custom_minimum_size.x = 180
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_label.clip_text = true
	row.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = str(issue.get("description", ""))
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	desc_label.clip_text = true
	row.add_child(desc_label)

	# Count badge
	var count: int = int(issue.get("missing_count", 0))
	if count > 0:
		var badge := _make_colored_cell("%d" % count, icon_color, 40)
		row.add_child(badge)

	parent.add_child(row)


# ═══════════════════════════════════════════════════════════════════════════
# TAB 5: MAP RULES
# ═══════════════════════════════════════════════════════════════════════════

func _build_map_rules_tab(parent: Control) -> void:
	_map_rules_scroll = ScrollContainer.new()
	_map_rules_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_rules_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	parent.add_child(margin)
	margin.add_child(_map_rules_scroll)

	_map_rules_container = VBoxContainer.new()
	_map_rules_container.add_theme_constant_override("separation", 4)
	_map_rules_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_rules_scroll.add_child(_map_rules_container)

	_tab_containers.append(margin)


func _populate_map_rules_tab() -> void:
	_clear_children(_map_rules_container)

	if not _map_rules_loaded:
		var hint_label := Label.new()
		hint_label.text = "No map rules report found. Generate with:\npython tools/map_pathfinder.py report --output doc/reports/MAP_RULES_REPORT.md"
		hint_label.add_theme_font_size_override("font_size", 12)
		hint_label.add_theme_color_override("font_color", COLOR_PARTIAL)
		_map_rules_container.add_child(hint_label)
		return

	# ── Summary stats ────────────────────────────────────────────────────
	var summary_data: Dictionary = _map_rules_data.get("summary", {}) as Dictionary
	var s_total: int = int(summary_data.get("total_maps", 0))
	var s_ok: int = int(summary_data.get("ok", 0))
	var s_fail: int = int(summary_data.get("fail", 0))
	var s_missing: int = int(summary_data.get("missing", 0))
	var s_seqs: int = int(summary_data.get("total_sequences", 0))

	_map_rules_container.add_child(_make_section_label("MAP RULES REPORT"))

	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 8)
	_map_rules_container.add_child(cards_row)

	_add_stat_card(cards_row, "Sequences", "%d" % s_seqs, "", COLOR_ACCENT)
	_add_stat_card(cards_row, "Total Maps", "%d" % s_total, "", COLOR_ACCENT)
	_add_stat_card(cards_row, "Passing", "%d" % s_ok,
		"%d%%" % _percent(s_ok, maxi(s_total, 1)),
		COLOR_COMPLETE if s_fail == 0 else COLOR_PARTIAL)
	_add_stat_card(cards_row, "Failing", "%d" % s_fail,
		"%d%%" % _percent(s_fail, maxi(s_total, 1)),
		COLOR_CRITICAL if s_fail > 0 else COLOR_COMPLETE)
	_add_stat_card(cards_row, "Missing", "%d" % s_missing, "",
		COLOR_MISSING if s_missing > 0 else COLOR_COMPLETE)

	var generated_text: String = str(_map_rules_data.get("generated", "unknown"))
	var gen_label := Label.new()
	gen_label.text = "Generated: %s" % generated_text
	gen_label.add_theme_font_size_override("font_size", 10)
	gen_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	_map_rules_container.add_child(gen_label)

	_map_rules_container.add_child(_make_spacer(8))

	# ── Per-sequence sections ────────────────────────────────────────────
	var sequences_value: Variant = _map_rules_data.get("sequences", [])
	if not (sequences_value is Array):
		return
	var sequences: Array = sequences_value as Array

	for seq_item in sequences:
		if not (seq_item is Dictionary):
			continue
		var seq: Dictionary = seq_item as Dictionary
		var seq_id: String = str(seq.get("id", ""))
		var seq_title: String = str(seq.get("title", ""))
		var seq_ok: int = int(seq.get("ok", 0))
		var seq_fail: int = int(seq.get("fail", 0))
		var seq_missing: int = int(seq.get("missing", 0))

		var maps_value: Variant = seq.get("maps", [])
		if not (maps_value is Array):
			continue
		var maps: Array = maps_value as Array
		var map_count: int = maps.size()

		# Skip sequences with no maps
		if map_count == 0:
			continue

		# Only show sequences that have failures or missing maps (collapse passing ones)
		var has_problems: bool = seq_fail > 0 or seq_missing > 0

		# Section header
		var header_color: Color = COLOR_CRITICAL if seq_fail > 0 else (COLOR_PARTIAL if seq_missing > 0 else COLOR_COMPLETE)
		var header_text: String = "%s — %s (%d maps: %d OK" % [seq_id.to_upper(), seq_title, map_count, seq_ok]
		if seq_fail > 0:
			header_text += ", %d fail" % seq_fail
		if seq_missing > 0:
			header_text += ", %d missing" % seq_missing
		header_text += ")"

		var section := _make_section_label(header_text)
		section.add_theme_color_override("font_color", header_color)
		section.add_theme_font_size_override("font_size", 12)
		_map_rules_container.add_child(section)

		# Map rows — only show failing/missing maps for compact display
		for map_item in maps:
			if not (map_item is Dictionary):
				continue
			var m: Dictionary = map_item as Dictionary
			var map_name: String = str(m.get("name", ""))
			var map_status: String = str(m.get("status", ""))

			# Skip OK maps in sequences that have problems (compact view)
			if map_status == "OK" and has_problems:
				continue

			_add_map_rules_row(_map_rules_container, map_name, map_status, m, seq_id)


func _add_map_rules_row(parent: VBoxContainer, map_name: String, status: String, map_data: Dictionary, seq_id: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Status badge
	var badge_text: String = status
	var badge_color: Color
	match status:
		"OK":
			badge_color = COLOR_COMPLETE
		"FAIL":
			badge_color = COLOR_CRITICAL
		"MISSING":
			badge_color = COLOR_MISSING
		"ERROR":
			badge_color = COLOR_CRITICAL
		_:
			badge_color = COLOR_DEFERRED
	var badge := _make_colored_cell(badge_text, badge_color, 60)
	row.add_child(badge)

	# Map name — clickable to open JSON editor
	var name_btn := Button.new()
	name_btn.text = map_name
	name_btn.flat = true
	name_btn.custom_minimum_size.x = 280
	name_btn.add_theme_font_size_override("font_size", 12)
	name_btn.add_theme_color_override("font_color", COLOR_TEXT)
	name_btn.add_theme_color_override("font_hover_color", COLOR_ACCENT)
	name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_btn.clip_text = true
	if status != "MISSING":
		var captured_name: String = map_name
		name_btn.pressed.connect(func() -> void:
			_open_json_editor(captured_name)
		)
	else:
		name_btn.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	row.add_child(name_btn)

	# Issues text
	var issues_value: Variant = map_data.get("issues", [])
	var issue_str: String = ""
	if issues_value is Array:
		var issues: Array = issues_value as Array
		var error_parts: Array[String] = []
		for iss_item in issues:
			if iss_item is Dictionary:
				var iss: Dictionary = iss_item as Dictionary
				if str(iss.get("severity", "")) == "ERROR":
					error_parts.append("R%s: %s" % [str(iss.get("rule", "")), str(iss.get("msg", "")).substr(0, 50)])
		issue_str = "; ".join(error_parts)

	var issue_label := Label.new()
	issue_label.text = issue_str
	issue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	issue_label.add_theme_font_size_override("font_size", 11)
	issue_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	issue_label.clip_text = true
	row.add_child(issue_label)

	# "Create Task" button — only for FAIL/ERROR maps
	if status == "FAIL" or status == "ERROR":
		var fix_text: String = str(map_data.get("fix_text", ""))
		var btn := Button.new()
		btn.text = "Create Task"
		btn.custom_minimum_size.x = 90
		btn.add_theme_font_size_override("font_size", 11)
		var captured_name: String = map_name
		var captured_seq: String = seq_id
		var captured_fix: String = fix_text
		btn.pressed.connect(func() -> void:
			_open_task_popup(captured_name, captured_seq, captured_fix)
		)
		row.add_child(btn)

	parent.add_child(row)


# ── Task creation popup ──────────────────────────────────────────────────

func _build_task_popup() -> void:
	_task_popup = PanelContainer.new()
	_task_popup.visible = false
	_task_popup.set_anchors_preset(Control.PRESET_CENTER)
	_task_popup.anchor_left = 0.2
	_task_popup.anchor_right = 0.8
	_task_popup.anchor_top = 0.15
	_task_popup.anchor_bottom = 0.85
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	style.set_border_width_all(2)
	style.border_color = COLOR_ACCENT
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	_task_popup.add_theme_stylebox_override("panel", style)
	_root.add_child(_task_popup)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_task_popup.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)

	_task_popup_title = Label.new()
	_task_popup_title.text = "Create Fix Task"
	_task_popup_title.add_theme_font_size_override("font_size", 15)
	_task_popup_title.add_theme_color_override("font_color", COLOR_ACCENT)
	_task_popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_task_popup_title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.flat = true
	close_btn.pressed.connect(func() -> void: _task_popup.visible = false)
	header.add_child(close_btn)

	# TextEdit for fix instructions
	_task_text_edit = TextEdit.new()
	_task_text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_task_text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_task_text_edit.add_theme_font_size_override("font_size", 12)
	_task_text_edit.add_theme_color_override("font_color", COLOR_TEXT)
	var te_style := StyleBoxFlat.new()
	te_style.bg_color = Color(0.04, 0.05, 0.08, 1.0)
	te_style.set_border_width_all(1)
	te_style.border_color = COLOR_BORDER
	te_style.set_corner_radius_all(4)
	te_style.set_content_margin_all(8)
	_task_text_edit.add_theme_stylebox_override("normal", te_style)
	vbox.add_child(_task_text_edit)

	# Status label
	_task_status_label = Label.new()
	_task_status_label.text = ""
	_task_status_label.add_theme_font_size_override("font_size", 11)
	_task_status_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	vbox.add_child(_task_status_label)

	# Button bar
	var btn_bar := HBoxContainer.new()
	btn_bar.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_bar)

	var send_btn := Button.new()
	send_btn.text = "Send to Oversight"
	send_btn.custom_minimum_size.x = 140
	send_btn.pressed.connect(_send_task_to_oversight)
	btn_bar.add_child(send_btn)

	var copy_btn := Button.new()
	copy_btn.text = "Copy to Clipboard"
	copy_btn.custom_minimum_size.x = 130
	copy_btn.pressed.connect(_copy_task_to_clipboard)
	btn_bar.add_child(copy_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bar.add_child(spacer)

	var cancel_btn := Button.new()
	cancel_btn.text = "Close"
	cancel_btn.custom_minimum_size.x = 80
	cancel_btn.pressed.connect(func() -> void: _task_popup.visible = false)
	btn_bar.add_child(cancel_btn)


func _open_task_popup(map_name: String, seq_id: String, fix_text: String) -> void:
	_task_map_name = map_name
	_task_seq_id = seq_id
	_task_popup_title.text = "Create Fix Task: %s" % map_name
	_task_text_edit.text = fix_text
	_task_status_label.text = ""
	_task_popup.visible = true


func _send_task_to_oversight() -> void:
	var task_payload := {
		"title": "Fix map rules: %s" % _task_map_name,
		"description": _task_text_edit.text,
		"status": "todo",
		"priority": "medium",
		"tags": JSON.stringify(["map-rules", "pathfinder", _task_seq_id]),
		"source": "pathfinder-dashboard",
	}

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_task_sent.bind(http))

	var url := "%s/api/tasks" % OVERSIGHT_URL
	var headers := PackedStringArray(["Content-Type: application/json"])
	var body := JSON.stringify(task_payload)

	_task_status_label.text = "Sending..."
	_task_status_label.add_theme_color_override("font_color", COLOR_ACCENT)

	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_task_status_label.text = "Request failed: error %d" % err
		_task_status_label.add_theme_color_override("font_color", COLOR_CRITICAL)
		http.queue_free()


func _on_task_sent(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS:
		_task_status_label.text = "Connection failed (is Oversight running on %s?)" % OVERSIGHT_URL
		_task_status_label.add_theme_color_override("font_color", COLOR_CRITICAL)
		return

	if response_code == 201 or response_code == 200:
		_task_status_label.text = "Task created for %s" % _task_map_name
		_task_status_label.add_theme_color_override("font_color", COLOR_COMPLETE)
	else:
		var body_text := body.get_string_from_utf8()
		_task_status_label.text = "Error %d: %s" % [response_code, body_text.substr(0, 80)]
		_task_status_label.add_theme_color_override("font_color", COLOR_CRITICAL)


func _copy_task_to_clipboard() -> void:
	DisplayServer.clipboard_set(_task_text_edit.text)
	_task_status_label.text = "Copied to clipboard"
	_task_status_label.add_theme_color_override("font_color", COLOR_COMPLETE)


# ── JSON editor popup ────────────────────────────────────────────────────

func _build_json_editor_popup() -> void:
	_json_editor_popup = PanelContainer.new()
	_json_editor_popup.visible = false
	_json_editor_popup.set_anchors_preset(Control.PRESET_CENTER)
	_json_editor_popup.anchor_left = 0.08
	_json_editor_popup.anchor_right = 0.92
	_json_editor_popup.anchor_top = 0.06
	_json_editor_popup.anchor_bottom = 0.94
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.99)
	style.set_border_width_all(2)
	style.border_color = COLOR_ACCENT
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	_json_editor_popup.add_theme_stylebox_override("panel", style)
	_root.add_child(_json_editor_popup)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_json_editor_popup.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	_json_editor_title = Label.new()
	_json_editor_title.text = "Edit map_data.json"
	_json_editor_title.add_theme_font_size_override("font_size", 15)
	_json_editor_title.add_theme_color_override("font_color", COLOR_ACCENT)
	_json_editor_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_json_editor_title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.flat = true
	close_btn.pressed.connect(func() -> void: _json_editor_popup.visible = false)
	header.add_child(close_btn)

	# TextEdit for JSON content
	_json_editor_text = TextEdit.new()
	_json_editor_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_json_editor_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_json_editor_text.add_theme_font_size_override("font_size", 12)
	_json_editor_text.add_theme_color_override("font_color", COLOR_TEXT)
	_json_editor_text.scroll_fit_content_height = false
	var te_style := StyleBoxFlat.new()
	te_style.bg_color = Color(0.03, 0.04, 0.06, 1.0)
	te_style.set_border_width_all(1)
	te_style.border_color = COLOR_BORDER
	te_style.set_corner_radius_all(4)
	te_style.set_content_margin_all(8)
	_json_editor_text.add_theme_stylebox_override("normal", te_style)
	vbox.add_child(_json_editor_text)

	# Status label
	_json_editor_status = Label.new()
	_json_editor_status.text = ""
	_json_editor_status.add_theme_font_size_override("font_size", 11)
	_json_editor_status.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	vbox.add_child(_json_editor_status)

	# Button bar
	var btn_bar := HBoxContainer.new()
	btn_bar.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_bar)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.custom_minimum_size.x = 80
	save_btn.pressed.connect(_save_json_editor)
	btn_bar.add_child(save_btn)

	var reload_btn := Button.new()
	reload_btn.text = "Reload"
	reload_btn.custom_minimum_size.x = 80
	reload_btn.pressed.connect(_reload_json_editor)
	btn_bar.add_child(reload_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bar.add_child(spacer)

	var cancel_btn := Button.new()
	cancel_btn.text = "Close"
	cancel_btn.custom_minimum_size.x = 80
	cancel_btn.pressed.connect(func() -> void: _json_editor_popup.visible = false)
	btn_bar.add_child(cancel_btn)


func _open_json_editor(map_name: String) -> void:
	var path := "res://commons/maps/%s/map_data.json" % map_name
	var abs_path: String = ProjectSettings.globalize_path(path)
	var file := FileAccess.open(abs_path, FileAccess.READ)
	if not file:
		if _json_editor_status:
			_json_editor_status.text = "Cannot open: %s" % path
			_json_editor_status.add_theme_color_override("font_color", COLOR_CRITICAL)
			_json_editor_popup.visible = true
		return
	_json_editor_path = abs_path
	_json_editor_text.text = file.get_as_text()
	_json_editor_title.text = "Edit: %s/map_data.json" % map_name
	_json_editor_status.text = ""
	_json_editor_status.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	_json_editor_popup.visible = true


func _save_json_editor() -> void:
	# Validate JSON first
	var json := JSON.new()
	if json.parse(_json_editor_text.text) != OK:
		_json_editor_status.text = "Invalid JSON: %s (line %d)" % [json.get_error_message(), json.get_error_line()]
		_json_editor_status.add_theme_color_override("font_color", COLOR_CRITICAL)
		return
	# Write to file
	var file := FileAccess.open(_json_editor_path, FileAccess.WRITE)
	if not file:
		_json_editor_status.text = "Cannot write: %s" % _json_editor_path
		_json_editor_status.add_theme_color_override("font_color", COLOR_CRITICAL)
		return
	file.store_string(_json_editor_text.text)
	_json_editor_status.text = "Saved"
	_json_editor_status.add_theme_color_override("font_color", COLOR_COMPLETE)


func _reload_json_editor() -> void:
	if _json_editor_path == "":
		return
	var file := FileAccess.open(_json_editor_path, FileAccess.READ)
	if not file:
		_json_editor_status.text = "Cannot reload: %s" % _json_editor_path
		_json_editor_status.add_theme_color_override("font_color", COLOR_CRITICAL)
		return
	_json_editor_text.text = file.get_as_text()
	_json_editor_status.text = "Reloaded from disk"
	_json_editor_status.add_theme_color_override("font_color", COLOR_ACCENT)


# ═══════════════════════════════════════════════════════════════════════════
# UI HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_ACCENT)
	return label


func _make_spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	return spacer


func _add_stat_card(parent: HBoxContainer, title: String, value: String, subtitle: String, accent: Color) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_CARD_BG
	style.set_border_width_all(1)
	style.border_color = accent.darkened(0.5)
	style.border_width_top = 3
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	vbox.add_child(title_label)

	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.add_theme_color_override("font_color", accent)
	vbox.add_child(value_label)

	if subtitle != "":
		var sub_label := Label.new()
		sub_label.text = subtitle
		sub_label.add_theme_font_size_override("font_size", 10)
		sub_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		vbox.add_child(sub_label)

	parent.add_child(card)


func _add_progress_row(parent: VBoxContainer, label_text: String, have: int, of: int, color: Color, detail: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 280
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(label)

	# Progress bar (manual)
	var bar_bg := ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(300, 18)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_bg.color = Color(0.1, 0.1, 0.15, 1.0)
	row.add_child(bar_bg)

	var pct := _percent(have, of) if of > 0 else 0
	var bar_fill := ColorRect.new()
	bar_fill.custom_minimum_size = Vector2(300.0 * pct / 100.0, 18)
	bar_fill.color = color.darkened(0.2)
	bar_fill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar_bg.add_child(bar_fill)

	var pct_label := Label.new()
	pct_label.text = "%d%%" % pct
	pct_label.custom_minimum_size.x = 40
	pct_label.add_theme_font_size_override("font_size", 12)
	pct_label.add_theme_color_override("font_color", color)
	row.add_child(pct_label)

	var detail_label := Label.new()
	detail_label.text = detail
	detail_label.add_theme_font_size_override("font_size", 10)
	detail_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	detail_label.clip_text = true
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail_label)

	parent.add_child(row)


func _add_phase_row(parent: VBoxContainer, label_text: String, book_ready: int, total: int, color: Color, seq_names: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Phase color dot
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(12, 12)
	dot.color = color
	row.add_child(dot)

	# Phase name
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 100
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(label)

	# Count
	var count_label := Label.new()
	count_label.text = "%d sequences" % total
	count_label.custom_minimum_size.x = 90
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	row.add_child(count_label)

	# Book ready
	var book_label := Label.new()
	book_label.text = "%d/%d book-ready" % [book_ready, total]
	book_label.custom_minimum_size.x = 110
	book_label.add_theme_font_size_override("font_size", 12)
	book_label.add_theme_color_override("font_color", COLOR_COMPLETE if book_ready == total else COLOR_PARTIAL)
	row.add_child(book_label)

	# Sequence names
	var names_label := Label.new()
	names_label.text = seq_names
	names_label.add_theme_font_size_override("font_size", 10)
	names_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	names_label.clip_text = true
	names_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(names_label)

	parent.add_child(row)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _percent(part: int, whole: int) -> int:
	if whole <= 0:
		return 0
	return int(float(part) / float(whole) * 100.0)


func _add_release_gates_section(parent: VBoxContainer) -> void:
	parent.add_child(_make_spacer(8))
	parent.add_child(_make_section_label("RELEASE GATES"))

	if not _release_gates_loaded:
		var missing_label := Label.new()
		missing_label.text = "No release gate report found at %s" % RELEASE_GATES_PATH
		missing_label.add_theme_font_size_override("font_size", 11)
		missing_label.add_theme_color_override("font_color", COLOR_PARTIAL)
		parent.add_child(missing_label)
		return

	var gates: Array[Dictionary] = _extract_release_gates()
	_sync_release_gate_toggles_with_report()

	if gates.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Release gate report is loaded but has no gate rows."
		empty_label.add_theme_font_size_override("font_size", 11)
		empty_label.add_theme_color_override("font_color", COLOR_PARTIAL)
		parent.add_child(empty_label)
		return

	var gate_ids: Array[String] = []
	var enabled_count: int = 0
	var pass_count: int = 0
	for gate in gates:
		var gate_id: String = str(gate.get("id", ""))
		if gate_id != "":
			gate_ids.append(gate_id)
		if not _is_release_gate_enabled(gate_id):
			continue
		enabled_count += 1
		if bool(gate.get("pass", false)):
			pass_count += 1

	var has_enabled_gates: bool = enabled_count > 0
	var overall_pass: bool = has_enabled_gates and pass_count == enabled_count
	var summary_text: String = "PASS" if overall_pass else ("N/A" if not has_enabled_gates else "FAIL")
	var summary_color: Color = COLOR_COMPLETE if overall_pass else (COLOR_DEFERRED if not has_enabled_gates else COLOR_CRITICAL)

	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 8)

	var summary_label := Label.new()
	summary_label.text = "Overall release status"
	summary_label.custom_minimum_size.x = 220
	summary_label.add_theme_font_size_override("font_size", 12)
	summary_label.add_theme_color_override("font_color", COLOR_TEXT)
	summary_row.add_child(summary_label)

	var summary_badge := _make_colored_cell(
		summary_text,
		summary_color,
		56
	)
	summary_row.add_child(summary_badge)

	var summary_metrics := Label.new()
	summary_metrics.text = "%d/%d enabled gates passing (%d total)" % [pass_count, enabled_count, gates.size()]
	summary_metrics.add_theme_font_size_override("font_size", 10)
	summary_metrics.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	summary_metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_metrics.clip_text = true
	summary_row.add_child(summary_metrics)

	parent.add_child(summary_row)

	var hint_label := Label.new()
	hint_label.text = "Toggle gates ON/OFF. Disabled gates are excluded from overall release status."
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	hint_label.clip_text = true
	parent.add_child(hint_label)

	var actions_row := HBoxContainer.new()
	actions_row.add_theme_constant_override("separation", 6)

	var all_on_button := Button.new()
	all_on_button.text = "All ON"
	all_on_button.custom_minimum_size.x = 72
	all_on_button.pressed.connect(func() -> void:
		_set_release_gates_enabled(gate_ids, true)
	)
	actions_row.add_child(all_on_button)

	var all_off_button := Button.new()
	all_off_button.text = "All OFF"
	all_off_button.custom_minimum_size.x = 72
	all_off_button.pressed.connect(func() -> void:
		_set_release_gates_enabled(gate_ids, false)
	)
	actions_row.add_child(all_off_button)

	var reset_button := Button.new()
	reset_button.text = "Reset"
	reset_button.custom_minimum_size.x = 72
	reset_button.pressed.connect(func() -> void:
		_reset_release_gate_toggles_to_default()
	)
	actions_row.add_child(reset_button)

	var actions_hint := Label.new()
	actions_hint.text = "Reset = enable all known gates"
	actions_hint.add_theme_font_size_override("font_size", 10)
	actions_hint.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	actions_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_hint.clip_text = true
	actions_row.add_child(actions_hint)
	parent.add_child(actions_row)

	for gate in gates:
		_add_release_gate_row(parent, gate)


func _add_release_gate_row(parent: VBoxContainer, gate: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var gate_id: String = str(gate.get("id", "?"))
	var gate_name: String = str(gate.get("name", "Unnamed Gate"))
	var gate_enabled: bool = _is_release_gate_enabled(gate_id)
	var gate_pass: bool = bool(gate.get("pass", false))
	var metrics: Dictionary = {}
	var metrics_value: Variant = gate.get("metrics", {})
	if metrics_value is Dictionary:
		metrics = metrics_value as Dictionary

	var toggle := CheckBox.new()
	toggle.text = "ON"
	toggle.button_pressed = gate_enabled
	toggle.custom_minimum_size.x = 52
	var toggle_gate_id: String = gate_id
	toggle.toggled.connect(func(pressed: bool) -> void:
		_release_gate_enabled[toggle_gate_id] = pressed
		_save_release_gate_toggles()
		_populate_overview_tab()
	)
	row.add_child(toggle)

	var name_label := Label.new()
	name_label.text = "Gate %s: %s" % [gate_id, gate_name]
	name_label.custom_minimum_size.x = 220
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", COLOR_TEXT if gate_enabled else COLOR_TEXT_DIM)
	name_label.clip_text = true
	row.add_child(name_label)

	var status_text: String = "OFF"
	var status_color: Color = COLOR_DEFERRED
	if gate_enabled:
		status_text = "PASS" if gate_pass else "FAIL"
		status_color = COLOR_COMPLETE if gate_pass else COLOR_CRITICAL

	var status_badge := _make_colored_cell(
		status_text,
		status_color,
		56
	)
	row.add_child(status_badge)

	var metrics_label := Label.new()
	metrics_label.text = _gate_metrics_text(gate_id, metrics)
	metrics_label.add_theme_font_size_override("font_size", 10)
	metrics_label.add_theme_color_override("font_color", COLOR_TEXT_DIM if gate_enabled else COLOR_DEFERRED)
	metrics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics_label.clip_text = true
	row.add_child(metrics_label)

	parent.add_child(row)


func _gate_metrics_text(gate_id: String, metrics: Dictionary) -> String:
	match gate_id:
		"A":
			var missing_declared_maps: int = int(metrics.get("missing_declared_maps", 0))
			var duplicate_entries: int = int(metrics.get("duplicate_entries_within_sequence", 0))
			var undeclared_folders: int = int(metrics.get("undeclared_map_folders", 0))
			return "missing declared: %d, duplicate entries: %d, undeclared folders: %d" % [missing_declared_maps, duplicate_entries, undeclared_folders]
		"B":
			var unresolved_scene_files: int = int(metrics.get("unresolved_scene_files", 0))
			var missing_scene_path: int = int(metrics.get("missing_scene_path", 0))
			var missing_map_ready: int = int(metrics.get("missing_map_ready", 0))
			return "unresolved scenes: %d, missing scene_path: %d, missing map_ready: %d" % [unresolved_scene_files, missing_scene_path, missing_map_ready]
		"C":
			var grade_a: int = int(metrics.get("grade_A", 0))
			var grade_b: int = int(metrics.get("grade_B", 0))
			var grade_c: int = int(metrics.get("grade_C", 0))
			var grade_f: int = int(metrics.get("grade_F", 0))
			return "grades A:%d B:%d C:%d F:%d" % [grade_a, grade_b, grade_c, grade_f]
		"D":
			var lost_count: int = int(metrics.get("lost_count", 0))
			var changed_count: int = int(metrics.get("changed_count", 0))
			var total_issues: int = int(metrics.get("total_issues", 0))
			return "lost: %d, changed: %d, total issues: %d" % [lost_count, changed_count, total_issues]
		_:
			if metrics.is_empty():
				return "no metrics"
			var metric_keys: Array[String] = []
			for metric_key in metrics.keys():
				metric_keys.append(str(metric_key))
			metric_keys.sort()
			var parts: Array[String] = []
			for key_name in metric_keys:
				var metric_value: Variant = metrics.get(key_name, null)
				parts.append("%s: %s" % [key_name, str(metric_value)])
			return ", ".join(parts)

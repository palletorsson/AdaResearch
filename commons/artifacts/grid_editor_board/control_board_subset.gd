# control_board_subset.gd
# Static data for the Control Board grid-editor subset.
# Mirrors the web grid-editor's control_board subset data.
# 9 categories, 34 elements, 4 presets.
extends RefCounted
class_name ControlBoardSubset

# ═══════════════════════════════════════════════════════════════
# CATEGORIES
# ═══════════════════════════════════════════════════════════════

const CATEGORIES: Array[Dictionary] = [
	{ "id": "monitors", "name": "Monitors", "color": "#4CAF50" },
	{ "id": "meters", "name": "Meters", "color": "#FF9800" },
	{ "id": "buttons", "name": "Buttons", "color": "#F44336" },
	{ "id": "switches", "name": "Switches", "color": "#E91E63" },
	{ "id": "dials", "name": "Dials", "color": "#9C27B0" },
	{ "id": "sliders", "name": "Sliders", "color": "#2196F3" },
	{ "id": "speakers", "name": "Speakers", "color": "#795548" },
	{ "id": "panels", "name": "Panels", "color": "#607D8B" },
	{ "id": "lights", "name": "Lights", "color": "#FFEB3B" },
]

# ═══════════════════════════════════════════════════════════════
# ELEMENTS
# ═══════════════════════════════════════════════════════════════

const ELEMENTS: Array[Dictionary] = [
	# ── Monitors ──
	{ "id": "crt_large", "name": "CRT Monitor", "category": "monitors", "w": 5, "h": 4 },
	{ "id": "crt_small", "name": "CRT (Small)", "category": "monitors", "w": 3, "h": 3 },
	{ "id": "waveform_display", "name": "Waveform Scope", "category": "monitors", "w": 3, "h": 3 },
	{ "id": "radar_display", "name": "Radar Screen", "category": "monitors", "w": 4, "h": 4 },
	{ "id": "status_panel", "name": "Status Panel", "category": "monitors", "w": 3, "h": 4 },
	# ── Meters ──
	{ "id": "vu_meter", "name": "VU Meter", "category": "meters", "w": 3, "h": 2 },
	{ "id": "gauge_round", "name": "Gauge (Round)", "category": "meters", "w": 3, "h": 3 },
	{ "id": "led_bar_v", "name": "LED Bar", "category": "meters", "w": 1, "h": 4 },
	# ── Buttons ──
	{ "id": "btn_red", "name": "Red Button", "category": "buttons", "w": 1, "h": 1 },
	{ "id": "btn_green", "name": "Green Button", "category": "buttons", "w": 1, "h": 1 },
	{ "id": "btn_blue", "name": "Blue Button", "category": "buttons", "w": 1, "h": 1 },
	{ "id": "btn_yellow", "name": "Yellow Button", "category": "buttons", "w": 1, "h": 1 },
	{ "id": "btn_square", "name": "Square Button", "category": "buttons", "w": 1, "h": 1 },
	{ "id": "emergency_stop", "name": "Emergency Stop", "category": "buttons", "w": 2, "h": 2 },
	# ── Switches ──
	{ "id": "toggle_switch", "name": "Toggle Switch", "category": "switches", "w": 1, "h": 2 },
	{ "id": "rocker_switch", "name": "Rocker Switch", "category": "switches", "w": 1, "h": 2 },
	{ "id": "key_switch", "name": "Key Switch", "category": "switches", "w": 1, "h": 2 },
	# ── Dials ──
	{ "id": "knob_large", "name": "Knob (Large)", "category": "dials", "w": 2, "h": 2 },
	{ "id": "knob_small", "name": "Knob (Small)", "category": "dials", "w": 1, "h": 1 },
	{ "id": "dial_selector", "name": "Selector Dial", "category": "dials", "w": 3, "h": 3 },
	# ── Sliders ──
	{ "id": "fader_v", "name": "Fader (V)", "category": "sliders", "w": 1, "h": 4 },
	{ "id": "fader_h", "name": "Fader (H)", "category": "sliders", "w": 4, "h": 1 },
	{ "id": "lever", "name": "Lever", "category": "sliders", "w": 2, "h": 4 },
	# ── Speakers ──
	{ "id": "speaker_large", "name": "Speaker (Lg)", "category": "speakers", "w": 4, "h": 4 },
	{ "id": "speaker_small", "name": "Speaker (Sm)", "category": "speakers", "w": 2, "h": 2 },
	{ "id": "microphone", "name": "Microphone", "category": "speakers", "w": 1, "h": 2 },
	{ "id": "headphone_jack", "name": "Headphone Jack", "category": "speakers", "w": 1, "h": 1 },
	# ── Panels ──
	{ "id": "nameplate", "name": "Nameplate", "category": "panels", "w": 4, "h": 1 },
	{ "id": "blank_panel", "name": "Blank Panel", "category": "panels", "w": 4, "h": 2 },
	{ "id": "patch_bay", "name": "Patch Bay", "category": "panels", "w": 4, "h": 2 },
	# ── Lights ──
	{ "id": "led_green", "name": "LED (Green)", "category": "lights", "w": 1, "h": 1 },
	{ "id": "led_red", "name": "LED (Red)", "category": "lights", "w": 1, "h": 1 },
	{ "id": "led_amber", "name": "LED (Amber)", "category": "lights", "w": 1, "h": 1 },
	{ "id": "warning_light", "name": "Warning Light", "category": "lights", "w": 2, "h": 2 },
]

# ═══════════════════════════════════════════════════════════════
# PRESETS
# ═══════════════════════════════════════════════════════════════

const PRESET_MISSION_CONTROL: Dictionary = {
	"id": "mission_control_desk",
	"name": "Mission Control",
	"grid_w": 24, "grid_h": 14,
	"placements": [
		{ "element": "crt_large", "x": 1, "y": 0 },
		{ "element": "crt_large", "x": 7, "y": 0 },
		{ "element": "crt_small", "x": 13, "y": 0 },
		{ "element": "status_panel", "x": 16, "y": 0 },
		{ "element": "led_bar_v", "x": 20, "y": 0 },
		{ "element": "led_bar_v", "x": 21, "y": 0 },
		{ "element": "led_bar_v", "x": 22, "y": 0 },
		{ "element": "vu_meter", "x": 0, "y": 5 },
		{ "element": "vu_meter", "x": 3, "y": 5 },
		{ "element": "gauge_round", "x": 6, "y": 5 },
		{ "element": "dial_selector", "x": 9, "y": 5 },
		{ "element": "dial_selector", "x": 12, "y": 5 },
		{ "element": "knob_large", "x": 15, "y": 5 },
		{ "element": "knob_large", "x": 17, "y": 5 },
		{ "element": "knob_small", "x": 19, "y": 6 },
		{ "element": "knob_small", "x": 20, "y": 6 },
		{ "element": "knob_small", "x": 21, "y": 6 },
		{ "element": "knob_small", "x": 22, "y": 6 },
		{ "element": "fader_v", "x": 0, "y": 8 },
		{ "element": "fader_v", "x": 1, "y": 8 },
		{ "element": "fader_v", "x": 2, "y": 8 },
		{ "element": "fader_v", "x": 3, "y": 8 },
		{ "element": "lever", "x": 5, "y": 8 },
		{ "element": "lever", "x": 7, "y": 8 },
		{ "element": "fader_h", "x": 9, "y": 8 },
		{ "element": "fader_h", "x": 9, "y": 9 },
		{ "element": "fader_h", "x": 9, "y": 10 },
		{ "element": "speaker_large", "x": 14, "y": 8 },
		{ "element": "speaker_small", "x": 19, "y": 8 },
		{ "element": "speaker_small", "x": 21, "y": 8 },
		{ "element": "btn_red", "x": 0, "y": 12 },
		{ "element": "btn_green", "x": 1, "y": 12 },
		{ "element": "btn_blue", "x": 2, "y": 12 },
		{ "element": "btn_yellow", "x": 3, "y": 12 },
		{ "element": "btn_square", "x": 5, "y": 12 },
		{ "element": "btn_square", "x": 6, "y": 12 },
		{ "element": "toggle_switch", "x": 8, "y": 12 },
		{ "element": "toggle_switch", "x": 9, "y": 12 },
		{ "element": "toggle_switch", "x": 10, "y": 12 },
		{ "element": "toggle_switch", "x": 11, "y": 12 },
		{ "element": "rocker_switch", "x": 13, "y": 12 },
		{ "element": "rocker_switch", "x": 14, "y": 12 },
		{ "element": "key_switch", "x": 16, "y": 12 },
		{ "element": "led_green", "x": 18, "y": 12 },
		{ "element": "led_red", "x": 19, "y": 12 },
		{ "element": "led_green", "x": 20, "y": 12 },
		{ "element": "led_amber", "x": 21, "y": 12 },
		{ "element": "led_red", "x": 22, "y": 12 },
		{ "element": "led_green", "x": 23, "y": 12 },
	]
}

const PRESET_SERVER_RACK: Dictionary = {
	"id": "server_rack_panel",
	"name": "Server Rack",
	"grid_w": 12, "grid_h": 16,
	"placements": [
		{ "element": "crt_small", "x": 1, "y": 0 },
		{ "element": "crt_small", "x": 5, "y": 0 },
		{ "element": "waveform_display", "x": 9, "y": 0 },
		{ "element": "led_bar_v", "x": 0, "y": 4 },
		{ "element": "led_bar_v", "x": 1, "y": 4 },
		{ "element": "led_bar_v", "x": 2, "y": 4 },
		{ "element": "led_bar_v", "x": 3, "y": 4 },
		{ "element": "gauge_round", "x": 5, "y": 4 },
		{ "element": "gauge_round", "x": 8, "y": 4 },
		{ "element": "nameplate", "x": 0, "y": 8 },
		{ "element": "toggle_switch", "x": 0, "y": 9 },
		{ "element": "toggle_switch", "x": 1, "y": 9 },
		{ "element": "toggle_switch", "x": 2, "y": 9 },
		{ "element": "toggle_switch", "x": 3, "y": 9 },
		{ "element": "toggle_switch", "x": 4, "y": 9 },
		{ "element": "toggle_switch", "x": 5, "y": 9 },
		{ "element": "toggle_switch", "x": 6, "y": 9 },
		{ "element": "toggle_switch", "x": 7, "y": 9 },
		{ "element": "knob_small", "x": 9, "y": 9 },
		{ "element": "knob_small", "x": 10, "y": 9 },
		{ "element": "btn_red", "x": 0, "y": 11 },
		{ "element": "btn_green", "x": 1, "y": 11 },
		{ "element": "emergency_stop", "x": 3, "y": 11 },
		{ "element": "led_green", "x": 6, "y": 11 },
		{ "element": "led_green", "x": 7, "y": 11 },
		{ "element": "led_red", "x": 8, "y": 11 },
		{ "element": "led_amber", "x": 9, "y": 11 },
		{ "element": "led_green", "x": 10, "y": 11 },
		{ "element": "led_green", "x": 11, "y": 11 },
		{ "element": "speaker_small", "x": 5, "y": 13 },
		{ "element": "microphone", "x": 8, "y": 14 },
	]
}

const PRESET_COMM_STATION: Dictionary = {
	"id": "comm_station",
	"name": "Comms Station",
	"grid_w": 16, "grid_h": 12,
	"placements": [
		{ "element": "radar_display", "x": 0, "y": 0 },
		{ "element": "crt_small", "x": 5, "y": 0 },
		{ "element": "waveform_display", "x": 9, "y": 0 },
		{ "element": "dial_selector", "x": 13, "y": 0 },
		{ "element": "dial_selector", "x": 13, "y": 3 },
		{ "element": "knob_large", "x": 0, "y": 5 },
		{ "element": "knob_large", "x": 2, "y": 5 },
		{ "element": "knob_large", "x": 4, "y": 5 },
		{ "element": "vu_meter", "x": 7, "y": 5 },
		{ "element": "vu_meter", "x": 10, "y": 5 },
		{ "element": "fader_h", "x": 0, "y": 8 },
		{ "element": "fader_h", "x": 0, "y": 9 },
		{ "element": "fader_h", "x": 5, "y": 8 },
		{ "element": "speaker_large", "x": 10, "y": 8 },
		{ "element": "btn_red", "x": 0, "y": 11 },
		{ "element": "btn_green", "x": 1, "y": 11 },
		{ "element": "toggle_switch", "x": 3, "y": 11 },
		{ "element": "toggle_switch", "x": 4, "y": 11 },
		{ "element": "toggle_switch", "x": 5, "y": 11 },
		{ "element": "microphone", "x": 7, "y": 10 },
		{ "element": "headphone_jack", "x": 9, "y": 11 },
		{ "element": "led_green", "x": 11, "y": 11 },
		{ "element": "led_red", "x": 12, "y": 11 },
		{ "element": "led_amber", "x": 13, "y": 11 },
		{ "element": "key_switch", "x": 15, "y": 11 },
	]
}

const PRESET_EMPTY: Dictionary = {
	"id": "empty",
	"name": "Empty Board",
	"grid_w": 20, "grid_h": 12,
	"placements": []
}

static func get_presets() -> Array[Dictionary]:
	return [PRESET_MISSION_CONTROL, PRESET_SERVER_RACK, PRESET_COMM_STATION, PRESET_EMPTY]

# ═══════════════════════════════════════════════════════════════
# LOOKUP HELPERS
# ═══════════════════════════════════════════════════════════════

static var _element_cache: Dictionary = {}

static func get_element(id: String) -> Dictionary:
	if _element_cache.is_empty():
		for el in ELEMENTS:
			_element_cache[el["id"]] = el
	return _element_cache.get(id, {})

static var _category_color_cache: Dictionary = {}

static func get_category_color(cat_id: String) -> Color:
	if _category_color_cache.is_empty():
		for cat in CATEGORIES:
			_category_color_cache[cat["id"]] = Color.from_string(cat["color"], Color.GRAY)
	return _category_color_cache.get(cat_id, Color.GRAY)

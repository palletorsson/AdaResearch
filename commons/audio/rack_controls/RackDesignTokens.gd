# RackDesignTokens.gd
# Static loader for rack_design_tokens.json — shared visual contract
# Used by all RackControl* classes for colors, sizes, and layout constants

class_name RackDesignTokens
extends RefCounted

const TOKEN_PATH := "res://commons/audio/rack_controls/rack_design_tokens.json"

static var _tokens: Dictionary = {}
static var _loaded: bool = false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	var file := FileAccess.open(TOKEN_PATH, FileAccess.READ)
	if file:
		var json := JSON.new()
		var err := json.parse(file.get_as_text())
		if err == OK and json.data is Dictionary:
			_tokens = json.data
		else:
			push_warning("RackDesignTokens: failed to parse %s" % TOKEN_PATH)
			_tokens = {}
	else:
		push_warning("RackDesignTokens: cannot open %s" % TOKEN_PATH)
		_tokens = {}
	_loaded = true


static func get_color(name: String) -> Color:
	_ensure_loaded()
	var colors: Dictionary = _tokens.get("colors", {})
	var entry: Dictionary = colors.get(name, {})
	var rgba: Array = entry.get("rgba", [0.5, 0.5, 0.5, 1.0])
	return Color(rgba[0], rgba[1], rgba[2], rgba[3])


static func get_control_accent(control_type: String) -> Color:
	_ensure_loaded()
	var map: Dictionary = _tokens.get("control_type_accent", {})
	var color_name: String = map.get(control_type, "accent_orange")
	return get_color(color_name)


static func get_size_px(control_type: String) -> Vector2:
	_ensure_loaded()
	var sizes: Dictionary = _tokens.get("sizes_px", {})
	var entry: Dictionary = sizes.get(control_type, {"w": 80, "h": 80})
	return Vector2(entry.get("w", 80), entry.get("h", 80))


static func get_layout(key: String, default_val: float = 0.0) -> float:
	_ensure_loaded()
	var layout: Dictionary = _tokens.get("layout", {})
	return float(layout.get(key, default_val))


static func get_font_size(key: String) -> int:
	_ensure_loaded()
	var typo: Dictionary = _tokens.get("typography", {})
	return int(typo.get(key, 12))


static func get_emission(level: String) -> float:
	_ensure_loaded()
	var em: Dictionary = _tokens.get("emission", {})
	return float(em.get(level, 0.3))

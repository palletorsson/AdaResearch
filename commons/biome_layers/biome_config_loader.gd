# biome_config_loader.gd
# Tiny helper that loads commons/biome_layers/biome_config.json once
# (cached) and exposes the values via typed accessors. Used by
# biome_paint_dispatcher.gd and any future biome layer that needs to
# read kingdom unlock_order / colors / substrate routing.
#
# The JSON is the SINGLE SOURCE OF TRUTH for all biome parameters.
# Both Godot and the encyclopedia consume it. Pre-extraction the same
# constants lived in 3+ places and silently drifted.

class_name BiomeConfigLoader
extends RefCounted

const CONFIG_PATH := "res://commons/biome_layers/biome_config.json"

static var _cache: Dictionary = {}

# Kingdom token → numeric id (matches BiomePaintTokens constants).
const KINGDOM_TREE := 0
const KINGDOM_CREATURE := 1
const KINGDOM_FLOWER := 2
const KINGDOM_FUNGUS := 3


## Force a reload from disk on next access. Useful if the config was
## edited at runtime (live-tune from the encyclopedia's /biome-control).
static func invalidate() -> void:
	_cache.clear()


## Load and cache the full config dict. Returns empty dict on failure.
static func get_config() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("BiomeConfigLoader: missing %s" % CONFIG_PATH)
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("BiomeConfigLoader: failed to parse %s" % CONFIG_PATH)
		return {}
	_cache = parsed
	return _cache


## Get the kingdom's unlock_order. Painted cells of a locked kingdom
## fall back to primitive rendering. Mirrors KINGDOM_UNLOCK_ORDER in
## the encyclopedia's foldBiome strategy.
static func get_unlock_order(kingdom_id: int) -> int:
	var k := _kingdom_by_id(kingdom_id)
	if k.is_empty():
		return 0
	return int(k.get("unlock_order", 0))


## Get the kingdom's RGB color (Vector of 3 floats 0..1).
## Used by primitive_fallback to tint the placeholder cube.
static func get_kingdom_color(kingdom_id: int) -> Color:
	var k := _kingdom_by_id(kingdom_id)
	if k.is_empty():
		return Color.WHITE
	var rgb: Array = k.get("color_rgb", [1.0, 1.0, 1.0])
	if rgb.size() < 3:
		return Color.WHITE
	return Color(float(rgb[0]), float(rgb[1]), float(rgb[2]))


## Get the flower preset for a painted intensity (1..5). Returns
## empty string if intensity out of range.
static func get_flower_preset(intensity: int) -> String:
	var cfg := get_config()
	var presets: Dictionary = cfg.get("flower_presets_by_intensity", {})
	return String(presets.get(str(intensity), ""))


## Get the per-kingdom intensity_scaling dict — caller pulls specific
## fields like "scale_base" / "scale_per_intensity" / "segments_base".
## Returns empty dict if kingdom is unknown.
static func get_intensity_scaling(kingdom_name: String) -> Dictionary:
	var cfg := get_config()
	var scaling: Dictionary = cfg.get("intensity_scaling", {})
	return scaling.get(kingdom_name, {})


## Map kingdom_id to the kingdom's config dict. Returns empty if the
## id isn't recognised.
static func _kingdom_by_id(kingdom_id: int) -> Dictionary:
	var cfg := get_config()
	var kingdoms: Dictionary = cfg.get("kingdoms", {})
	for name in kingdoms:
		var k: Dictionary = kingdoms[name]
		if int(k.get("id", -1)) == kingdom_id:
			return k
	return {}

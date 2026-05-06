## CompositionZone
## A named zone within a spatial composition.
## Contains a region (hit-testing) and arbitrary properties (content-specific).
##
## The properties dictionary is intentionally generic:
##   - Pattern compositor puts: wallpaper_group, palette_index, seed, tile_scale, aging
##   - Facade builder puts: element_type, material, window_style
##   - Control board puts: widget_category, preset_elements
##
## Priority controls overlap resolution — higher priority zones override lower ones.

class_name CompositionZone extends RefCounted

var id: String = ""
var region: CompositionRegion = null
var properties: Dictionary = {}
var priority: int = 0

func _init(p_id: String = "", p_region: CompositionRegion = null, p_properties: Dictionary = {}, p_priority: int = 0) -> void:
	id = p_id
	region = p_region if p_region else CompositionRegion.fill()
	properties = p_properties
	priority = p_priority

func contains(gx: int, gy: int, grid_w: int, grid_h: int) -> bool:
	return region.contains(gx, gy, grid_w, grid_h)

# ═══════════════════════════════════════════════════════════════════
# SERIALIZATION
# ═══════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	return {
		"id": id,
		"region": region.to_dict(),
		"properties": properties,
		"priority": priority,
	}

static func from_dict(data: Dictionary) -> CompositionZone:
	var zone := CompositionZone.new()
	zone.id = str(data.get("id", ""))
	if data.has("region"):
		zone.region = CompositionRegion.from_dict(data["region"])
	zone.properties = data.get("properties", {})
	zone.priority = int(data.get("priority", 0))
	return zone

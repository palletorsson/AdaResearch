# floor_pattern_editor.gd — Live preview of Pompeii mosaic floor patterns
# Dynamically loads floor scripts and adjusts their @export vars.
extends BaseGeometryEditor

const FLOOR_SCRIPTS: Array[String] = [
	"res://commons/artifacts/pompeii_mosaic_floor/basket_weave_floor.gd",
	"res://commons/artifacts/pompeii_mosaic_floor/herringbone_floor.gd",
	"res://commons/artifacts/pompeii_mosaic_floor/honeycomb_hex_floor.gd",
	"res://commons/artifacts/pompeii_mosaic_floor/diamond_lattice_floor.gd",
	"res://commons/artifacts/pompeii_mosaic_floor/tumbling_blocks_floor.gd",
	"res://commons/artifacts/pompeii_mosaic_floor/windmill_floor.gd",
	"res://commons/artifacts/pompeii_mosaic_floor/labyrinth_floor.gd",
	"res://commons/artifacts/pompeii_mosaic_floor/star_rosette_floor.gd",
	"res://commons/artifacts/pompeii_mosaic_floor/spiral_mosaic_floor.gd",
	"res://commons/artifacts/pompeii_mosaic_floor/compass_rose_floor.gd",
]


func _get_editor_name() -> String:
	return "Floor Pattern"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Pattern", "params": [
			{"id": "type", "label": "Pattern", "options": ["Basket Weave", "Herringbone", "Honeycomb Hex", "Diamond Lattice", "Tumbling Blocks", "Windmill", "Labyrinth", "Star Rosette", "Spiral Mosaic", "Compass Rose"], "default": 0.0},
		]},
		{"name": "Dimensions", "params": [
			{"id": "floor_width", "label": "Floor Width", "min": 1.0, "max": 5.0, "step": 0.25, "default": 2.0},
			{"id": "floor_depth", "label": "Floor Depth", "min": 1.0, "max": 5.0, "step": 0.25, "default": 2.0},
			{"id": "tile_size", "label": "Tile Size", "min": 0.05, "max": 0.5, "step": 0.01, "default": 0.15},
			{"id": "wear_level", "label": "Wear Level", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.0},
		]},
	]


func _create_initial_geometry() -> void:
	# Floors look best from above — raise the camera pitch and distance
	orbit_pitch = 1.2
	orbit_dist = 5.0
	_auto_rotate = false
	_set_defaults()
	_rebuild()


func _rebuild() -> void:
	_clear_content()

	var idx: int = clampi(int(p("type", 0)), 0, FLOOR_SCRIPTS.size() - 1)
	var script_path: String = FLOOR_SCRIPTS[idx]

	if not ResourceLoader.exists(script_path):
		return

	var scr: GDScript = load(script_path) as GDScript
	if not scr:
		return

	var floor_node := Node3D.new()
	floor_node.set_script(scr)

	# Configure via apply_grid_config which all floor scripts support
	var config := {
		"floor_size": [p("floor_width", 2.0), p("floor_depth", 2.0)],
		"wear_level": p("wear_level", 0.0),
	}
	# Tile size: some floors use tiles_short derived from size / tile_size
	var tile_sz: float = maxf(p("tile_size", 0.15), 0.05)
	var tiles_short: int = maxi(int(minf(p("floor_width", 2.0), p("floor_depth", 2.0)) / tile_sz), 3)
	config["tiles_short"] = tiles_short

	floor_node.apply_grid_config(config)

	content_root.add_child(floor_node)

	if info_label:
		var names: Array[String] = [
			"Basket Weave", "Herringbone", "Honeycomb Hex", "Diamond Lattice",
			"Tumbling Blocks", "Windmill", "Labyrinth", "Star Rosette",
			"Spiral Mosaic", "Compass Rose",
		]
		info_label.text = "Pattern: %s | Tiles: %d" % [names[idx], tiles_short]

# BotanicalFlowerArtifact.gd
# Grid-system wrapper for the BotanicalFlower procedural flower generator.
# Instances the core botanical_flower scene and exposes grid config for
# map-driven parameter control (petal count, color, symmetry, etc.).

extends Node3D
class_name BotanicalFlowerArtifact

const BOTANICAL_FLOWER := preload("res://commons/flora/botanical_flower.tscn")

var _flower: Node3D = null


func _ready() -> void:
	_flower = BOTANICAL_FLOWER.instantiate()
	add_child(_flower)


func apply_grid_config(config_data: Dictionary) -> void:
	if not _flower:
		return

	# Forward recognized keys to BotanicalFlower.configure()
	var config := {}

	if config_data.has("petal_count"):
		config["petal_count"] = int(config_data["petal_count"])
	if config_data.has("petal_length"):
		config["petal_length"] = float(config_data["petal_length"])
	if config_data.has("petal_width"):
		config["petal_width"] = float(config_data["petal_width"])
	if config_data.has("petal_curve"):
		config["petal_curve"] = float(config_data["petal_curve"])
	if config_data.has("stem_height"):
		config["stem_height"] = float(config_data["stem_height"])
	if config_data.has("leaf_count"):
		config["leaf_count"] = int(config_data["leaf_count"])
	if config_data.has("color_hue"):
		var hue := float(config_data["color_hue"])
		config["petal_color"] = Color.from_hsv(hue, 0.75, 0.85)
	if config_data.has("preset") and _flower.has_method("set"):
		_flower.preset = str(config_data["preset"])
	if config_data.has("symmetry"):
		var sym = config_data["symmetry"]
		if sym is String:
			config["symmetry"] = BotanicalFlower.Symmetry.BILATERAL if sym.to_lower() == "bilateral" else BotanicalFlower.Symmetry.RADIAL
		else:
			config["symmetry"] = BotanicalFlower.Symmetry.RADIAL if int(sym) == 0 else BotanicalFlower.Symmetry.BILATERAL

	if config.size() > 0 and _flower.has_method("configure"):
		_flower.configure(config)
		if _flower.has_method("rebuild"):
			_flower.rebuild()

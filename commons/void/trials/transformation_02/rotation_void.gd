extends "res://commons/scenes/mapobjects/rotation_cube.gd"
## Preserve the original grid utility parameters in an editable Void placement.

func apply_grid_config(config_data: Dictionary) -> void:
	var old_offset := y_offset
	var parameters: Array = [str(config_data.get("angle",90)),str(config_data.get("axis","y")),str(config_data.get("pause",4)),str(config_data.get("y_offset",-.6))]
	if config_data.has("utility_params"):
		parameters=Array(str(config_data.utility_params).split(":"))
	preload("res://commons/grid/UtilityRegistry.gd").apply_params(self, "rc", parameters, {"config": config_data})
	if is_node_ready(): position.y += y_offset - old_offset

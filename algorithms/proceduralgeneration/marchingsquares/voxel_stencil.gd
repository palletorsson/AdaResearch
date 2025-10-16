# voxel_stencil.gd - Base stencil for editing
class_name VoxelStencil

var fill_type: bool = true
var center_x: int = 0
var center_y: int = 0
var radius: int = 0

func initialize(new_fill_type: bool, new_radius: int):
	fill_type = new_fill_type
	radius = new_radius

func set_center(x: int, y: int):
	center_x = x
	center_y = y

func apply(x: int, y: int, voxel: bool) -> bool:
	return fill_type

func get_x_start() -> int:
	return center_x - radius

func get_x_end() -> int:
	return center_x + radius

func get_y_start() -> int:
	return center_y - radius

func get_y_end() -> int:
	return center_y + radius

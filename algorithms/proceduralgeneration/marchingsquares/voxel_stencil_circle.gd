# voxel_stencil_circle.gd - Circular stencil
extends VoxelStencil

var sqr_radius: int = 0

func initialize(new_fill_type: bool, new_radius: int):
	super.initialize(new_fill_type, new_radius)
	sqr_radius = new_radius * new_radius

func apply(x: int, y: int, voxel: bool) -> bool:
	var dx = x - center_x
	var dy = y - center_y
	if dx * dx + dy * dy <= sqr_radius:
		return fill_type
	return voxel

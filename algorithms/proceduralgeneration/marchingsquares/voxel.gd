# voxel.gd - Voxel data structure
class_name Voxel

var state: bool = false
var position: Vector2 = Vector2.ZERO
var x_edge_position: Vector2 = Vector2.ZERO
var y_edge_position: Vector2 = Vector2.ZERO
var x_normal: Vector2 = Vector2.ZERO
var y_normal: Vector2 = Vector2.ZERO

func _init(x: int = 0, y: int = 0, size: float = 1.0):
	if size > 0:
		position = Vector2(x + 0.5, y + 0.5) * size
		x_edge_position = position + Vector2(size * 0.5, 0)
		y_edge_position = position + Vector2(0, size * 0.5)

func become_x_dummy_of(voxel: Voxel, offset: float):
	state = voxel.state
	position = voxel.position + Vector2(offset, 0)
	x_edge_position = voxel.x_edge_position + Vector2(offset, 0)
	y_edge_position = voxel.y_edge_position + Vector2(offset, 0)
	x_normal = voxel.x_normal
	y_normal = voxel.y_normal

func become_y_dummy_of(voxel: Voxel, offset: float):
	state = voxel.state
	position = voxel.position + Vector2(0, offset)
	x_edge_position = voxel.x_edge_position + Vector2(0, offset)
	y_edge_position = voxel.y_edge_position + Vector2(0, offset)
	x_normal = voxel.x_normal
	y_normal = voxel.y_normal

func become_xy_dummy_of(voxel: Voxel, offset: float):
	state = voxel.state
	position = voxel.position + Vector2(offset, offset)
	x_edge_position = voxel.x_edge_position + Vector2(offset, offset)
	y_edge_position = voxel.y_edge_position + Vector2(offset, offset)
	x_normal = voxel.x_normal
	y_normal = voxel.y_normal

func get_x_edge_point() -> Vector2:
	return x_edge_position

func get_y_edge_point() -> Vector2:
	return y_edge_position

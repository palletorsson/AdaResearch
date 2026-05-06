## RectangularCS — Standard rectangular grid coordinate system
## Wraps the existing (gx, gy) integer grid behavior.
## Each cell is a QuadMesh. cell_to_normalized maps directly to grid fractions.

extends "res://commons/composition/coordinate_system.gd"

func _init(w: int = 20, h: int = 20, cs: float = 1.0) -> void:
	type = Type.RECTANGULAR
	grid_width = w
	grid_height = h
	cell_size = cs

func iterate_cells() -> Array:
	var cells: Array = []
	for gy in grid_height:
		for gx in grid_width:
			cells.append(Vector2i(gx, gy))
	return cells

func cell_to_world(cell_key) -> Vector3:
	var gx: int = cell_key.x
	var gy: int = cell_key.y
	var wx := (float(gx) - float(grid_width) / 2.0 + 0.5) * cell_size
	var wz := (float(gy) - float(grid_height) / 2.0 + 0.5) * cell_size
	return Vector3(wx, 0.0, wz)

func create_cell_mesh(_cell_key) -> Mesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(cell_size * 0.96, cell_size * 0.96)
	return quad

func cell_to_normalized(cell_key) -> Vector2:
	return Vector2(
		(float(cell_key.x) + 0.5) / float(grid_width),
		(float(cell_key.y) + 0.5) / float(grid_height)
	)

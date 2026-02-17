class_name CAGrid
extends Node3D



var grid_size: Vector3i = Vector3i(20, 20, 25)
var cells: Array = []
var generation: int = 0

# Visualization
var multimesh_instance: MultiMeshInstance3D
var cell_positions: PackedVector3Array = []
var cell_colors: PackedColorArray = []

func _ready():
	# Get or create MultiMeshInstance3D
	if has_node("MultiMeshInstance3D"):
		multimesh_instance = get_node("MultiMeshInstance3D")
	else:
		multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.name = "MultiMeshInstance3D"
		add_child(multimesh_instance)

	setup_multimesh()
	initialize_grid()

func setup_multimesh():
	"""Setup MultiMesh for efficient rendering"""
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.8, 0.8, 0.8)
	
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = box_mesh
	multi_mesh.use_colors = true  # Must be set BEFORE instance_count > 0
	multi_mesh.instance_count = grid_size.x * grid_size.y * grid_size.z
	
	multimesh_instance.multimesh = multi_mesh
	multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func initialize_grid():
	"""Initialize 3D cell grid"""
	cells.clear()
	cells.resize(grid_size.x * grid_size.y * grid_size.z)
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				var idx = get_cell_index(x, y, z)
				cells[idx] = ChairCell.new(Vector3i(x, y, z))

func get_cell_index(x: int, y: int, z: int) -> int:
	return x + y * grid_size.x + z * grid_size.x * grid_size.y

func get_cell(x: int, y: int, z: int) -> ChairCell:
	if x < 0 or x >= grid_size.x or y < 0 or y >= grid_size.y or z < 0 or z >= grid_size.z:
		return null
	return cells[get_cell_index(x, y, z)]

func get_cell_by_index(idx: int) -> ChairCell:
	if idx >= 0 and idx < cells.size():
		return cells[idx]
	return null

func reset():
	"""Clear all cells"""
	generation = 0
	for cell in cells:
		if cell:
			cell.clear()
	update_visualization()

func seed_chair_base():
	"""Seed initial 4 pillar positions"""
	var center_x = grid_size.x / 2
	var center_y = grid_size.y / 2
	var spacing = 3
	
	var positions = [
		Vector3i(center_x - spacing, center_y - spacing, 0),
		Vector3i(center_x + spacing, center_y - spacing, 0),
		Vector3i(center_x - spacing, center_y + spacing, 0),
		Vector3i(center_x + spacing, center_y + spacing, 0),
	]
	
	var types = [
		ChairCell.CellType.FRONT_LEFT,
		ChairCell.CellType.FRONT_RIGHT,
		ChairCell.CellType.BACK_LEFT,
		ChairCell.CellType.BACK_RIGHT,
	]
	
	for i in range(positions.size()):
		var pos = positions[i]
		var cell = get_cell(pos.x, pos.y, pos.z)
		if cell:
			cell.set_occupied(types[i], generation)

func seed_floating_platform():
	"""Seed 8x8 platform at height 6"""
	var start_x = 6
	var end_x = 13
	var start_y = 6
	var end_y = 13
	var z = 6
	
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var cell = get_cell(x, y, z)
			if cell:
				cell.set_occupied(ChairCell.CellType.STRUCTURE, generation)

func get_occupied_count() -> int:
	var count = 0
	for cell in cells:
		if cell and cell.is_occupied:
			count += 1
	return count

func update_visualization():
	"""Update MultiMesh with current cell states"""
	cell_positions.clear()
	cell_colors.clear()
	
	var occupied_cells = []
	for cell in cells:
		if cell and cell.is_occupied:
			occupied_cells.append(cell)
	
	var mm = multimesh_instance.multimesh
	if occupied_cells.is_empty():
		mm.visible_instance_count = 0
		return

	# Reset to 0 first so use_colors stays enabled when resizing
	mm.instance_count = 0
	mm.instance_count = occupied_cells.size()
	
	for i in range(occupied_cells.size()):
		var cell = occupied_cells[i]
		var pos = cell.position

		# Set transform
		var xform = Transform3D()
		xform.origin = Vector3(pos.x, pos.z, pos.y)  # Y is up in Godot
		mm.set_instance_transform(i, xform)

		# Set color based on height
		var height_ratio = float(pos.z) / float(grid_size.z)
		var color = Color(0.3 + height_ratio * 0.5, 0.5, 0.3 + height_ratio * 0.3)
		mm.set_instance_color(i, color)

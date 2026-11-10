class_name CAGrid
extends Node3D



var grid_size: Vector3i = Vector3i(20, 20, 25)
## "part" (2026-11-10): each cell in the colour of the part it grew from - front legs amber, back legs teal,
## seat and platform pale - so the anatomy the rules found can be read. "height": the original gradient.
## (Neither showed before: the material never read the instance colours, every cell stood grey.)
@export_enum("part", "height") var colour_by: String = "part"
var cells: Array = []
var generation: int = 0
## The occupied cells, in the order they grew (2026-11-10). Every strategy and every redraw walked all
## 10 000 cells to find the few hundred alive: 2-8 ms a step, and the gradient strategy 84 ms.
var occupied: Array = []

# Visualization
var multimesh_instance: MultiMeshInstance3D
var cell_positions: PackedVector3Array = []
var cell_colors: PackedColorArray = []

func _ready() -> void:
	# Get or create MultiMeshInstance3D
	if has_node("MultiMeshInstance3D"):
		multimesh_instance = get_node("MultiMeshInstance3D")
	else:
		multimesh_instance = MultiMeshInstance3D.new()
		multimesh_instance.name = "MultiMeshInstance3D"
		add_child(multimesh_instance)

	setup_multimesh()
	initialize_grid()

func setup_multimesh() -> void:
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
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.7
	multimesh_instance.material_override = mat

func initialize_grid() -> void:
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

func reset() -> void:
	"""Clear all cells"""
	generation = 0
	for cell in occupied:
		cell.clear()
	occupied.clear()
	update_visualization()

## Occupy a cell and remember it. Strategies and seeds go through here, never set_occupied directly.
func occupy(cell: ChairCell, type: ChairCell.CellType) -> void:
	if not cell.is_occupied:
		occupied.append(cell)
	cell.set_occupied(type, generation)

func seed_chair_base() -> void:
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
			occupy(cell, types[i])

func seed_floating_platform() -> void:
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
				occupy(cell, ChairCell.CellType.STRUCTURE)

func get_occupied_count() -> int:
	return occupied.size()

func update_visualization() -> void:
	"""Update MultiMesh with current cell states"""
	cell_positions.clear()
	cell_colors.clear()
	
	var occupied_cells = occupied
	
	var mm = multimesh_instance.multimesh
	if occupied_cells.is_empty():
		mm.visible_instance_count = 0
		return

	# Reset to 0 first so use_colors stays enabled when resizing
	mm.instance_count = 0
	mm.instance_count = occupied_cells.size()
	# An empty grid set visible_instance_count to 0 above and nothing set it back: a reset-then-seed drew nothing.
	mm.visible_instance_count = -1
	
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
		if colour_by == "part":
			var part := Color(0.86, 0.84, 0.78)                                   # seat, platform, structure
			match cell.cell_type:
				ChairCell.CellType.FRONT_LEFT, ChairCell.CellType.FRONT_RIGHT:
					part = Color(0.95, 0.62, 0.28)
				ChairCell.CellType.BACK_LEFT, ChairCell.CellType.BACK_RIGHT:
					part = Color(0.3, 0.7, 0.86)
			color = part * (0.72 + 0.28 * height_ratio)
			color.a = 1.0
		mm.set_instance_color(i, color)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass

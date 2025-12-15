@tool
extends Node3D

# Dürer's Magic Square (4x4)
# 16  3  2 13
#  5 10 11  8
#  9  6  7 12
#  4 15 14  1

@export var cell_size: float = 0.2
@export var spacing: float = 0.05
@export var font_size: int = 48

var magic_data = [
	[16, 3, 2, 13],
	[5, 10, 11, 8],
	[9, 6, 7, 12],
	[4, 15, 14, 1]
]

func _ready():
	_generate_grid()

func _generate_grid():
	for child in get_children():
		child.queue_free()
		
	for row in range(4):
		for col in range(4):
			var val = magic_data[row][col]
			_create_cell(row, col, val)

func _create_cell(row: int, col: int, value: int):
	var label = Label3D.new()
	label.text = str(value)
	label.font_size = font_size
	
	# Highlight the year 1514 in the bottom row
	if row == 3 and (col == 1 or col == 2):
		label.modulate = Color(1.0, 0.8, 0.2) # Gold
	
	# Position
	# Center (1.5, 1.5)
	var x = (col - 1.5) * (cell_size + spacing)
	var y = -(row - 1.5) * (cell_size + spacing) # Top down
	
	label.position = Vector3(x, y, 0)
	add_child(label)
	
	# Background plate
	var plate = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(cell_size, cell_size, 0.02)
	plate.mesh = box
	plate.position = Vector3(x, y, -0.02)
	
	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	plate.material_override = mat
	
	add_child(plate)

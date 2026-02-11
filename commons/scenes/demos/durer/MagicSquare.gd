@tool
extends Node3D

# Dürer's Magic Square (4x4)
# 16  3  2 13
#  5 10 11  8
#  9  6  7 12
#  4 15 14  1
#
# All rows, columns, diagonals, and 2x2 corners sum to 34.
# Bottom row contains "15 14" = 1514, the year of creation.

@export var cell_size: float = 0.22
@export var spacing: float = 0.04
@export var font_size: int = 38
@export var emit_light: bool = true

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
	
	# Create frame
	_create_frame()
	
	for row in range(4):
		for col in range(4):
			var val = magic_data[row][col]
			_create_cell(row, col, val)

func _create_frame():
	var frame = MeshInstance3D.new()
	var box = BoxMesh.new()
	var total_size = 4 * cell_size + 3 * spacing + 0.08
	box.size = Vector3(total_size, total_size, 0.03)
	frame.mesh = box
	frame.position = Vector3(0, 0, -0.025)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.1, 0.08)
	mat.roughness = 0.9
	frame.material_override = mat
	
	add_child(frame)

func _create_cell(row: int, col: int, value: int):
	var label = Label3D.new()
	label.text = str(value)
	label.font_size = font_size
	label.outline_size = 2
	label.outline_modulate = Color(0.1, 0.1, 0.1)
	
	# Default color - ivory/cream for visibility
	var text_color = Color(0.95, 0.92, 0.85)
	var plate_color = Color(0.22, 0.2, 0.18)
	var glow_color = Color(0.0, 0.0, 0.0)
	
	# Highlight the year 1514 in the bottom row (columns 1 and 2)
	if row == 3 and (col == 1 or col == 2):
		text_color = Color(1.0, 0.85, 0.3) # Gold
		plate_color = Color(0.3, 0.25, 0.15)
		glow_color = Color(0.4, 0.3, 0.1)
	
	# Highlight corners (which also sum to 34)
	if (row == 0 or row == 3) and (col == 0 or col == 3):
		text_color = Color(0.85, 0.9, 1.0) # Slight blue tint
		plate_color = Color(0.18, 0.2, 0.25)
	
	label.modulate = text_color
	
	# Position - center at (1.5, 1.5)
	var x = (col - 1.5) * (cell_size + spacing)
	var y = -(row - 1.5) * (cell_size + spacing)
	
	label.position = Vector3(x, y, 0.02)
	add_child(label)
	
	# Background plate
	var plate = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(cell_size, cell_size, 0.015)
	plate.mesh = box
	plate.position = Vector3(x, y, 0)
	
	# Material with subtle emission for visibility
	var mat = StandardMaterial3D.new()
	mat.albedo_color = plate_color
	mat.roughness = 0.7
	mat.metallic = 0.1
	
	if emit_light and glow_color != Color(0, 0, 0):
		mat.emission_enabled = true
		mat.emission = glow_color
		mat.emission_energy_multiplier = 0.5
	
	plate.material_override = mat
	add_child(plate)
	
	# Add subtle border
	_create_border(x, y, cell_size)

func _create_border(x: float, y: float, size: float):
	var border = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(size + 0.01, size + 0.01, 0.008)
	border.mesh = box
	border.position = Vector3(x, y, -0.005)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.3, 0.22)
	mat.metallic = 0.3
	mat.roughness = 0.6
	border.material_override = mat
	
	add_child(border)

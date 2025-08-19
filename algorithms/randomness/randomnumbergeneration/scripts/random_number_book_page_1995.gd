extends Node3D 

@export var font_file: FontFile
@export var grid_width: int = 10 # Number of columns (excluding the index column)
@export var grid_height: int = 28 # Number of rows per page
@export var number_spacing_x: float = 0.3
@export var number_spacing_y: float = 0.15  # Increased for better spacing
@export var cluster_spacing_x: float = 0.7
@export var cluster_spacing_y: float = 0.6
@export var change_interval: float = 10.0  

@onready var label3D = $Label3D_Title
@onready var label3D_side_number = $Label3D_Side_Number

var number_labels: Array[Label3D] = []
var timer: Timer
var side_number: int
var start_index: int  

func _ready():
	if font_file == null:
		push_error("Font file not assigned!")
		return

	# Generate a random 3-digit number (between 100 - 999)
	side_number = randi_range(100, 999)
	label3D_side_number.text = str(side_number)

	# Scale the start_index based on the original relation (17600 → 353)
	var scale_factor = 17600.0 / 353.0
	start_index = int(side_number * scale_factor)

	_create_label_grid()

func _create_label_grid():
	var current_y_offset = -2.3 # Keeps track of the Y position
	
	for row in range(grid_height): 
		var row_number_text = str(start_index + row) + "       "  # Start with the row index + tab

		for col in range(grid_width):
			# Generate a new 5-digit number
			var number = NumberHelper.random_5_digit_number()
			row_number_text += number + "  "

			# Insert a tab after every second number cluster
			if (col + 1) % 2 == 0:
				row_number_text += "       "

		# Create a separate label for each row
		var row_label = LabelHelper.create_number_label(Vector3(0, -current_y_offset, -0.001), row_number_text, font_file)
		row_label.font_size = 16
		row_label.outline_size = 3
		row_label.modulate = Color(0, 0, 0)  # Black text
		row_label.rotate(Vector3(0, 1, 0), 3.14159)
		add_child(row_label)

		# Move down for the next row
		current_y_offset += number_spacing_y

		# Add extra spacing after every 5 rows to simulate a page break
		if (row + 1) % 5 == 0:
			current_y_offset += number_spacing_y * 1.2  # Larger spacing after every 5 rows
	print(current_y_offset) 

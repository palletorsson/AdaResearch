extends Node3D

@export var grid_spacing: float = 0.2  # Distance between grid points
@onready var player = $"../XROrigin3D" #   $Camera3D #   # Reference to the player
@onready var label = $Label3D  # Reference to the first question label
@onready var label2 = $Label3D2  # Label for snapped position
@onready var label3 = $Label3D3  # Label for sphere snapped position
@onready var PlainGrid = $GrabCube2/PlanGrid  # Reference to the plane grid
 
var drawing_texture: Image
var drawing_texture_data: ImageTexture

func _ready():
	# Display the initial question
	label3.text = "In what way are we becoming a point on a grid?"
	# Initialize grid texture
	_create_grid_texture(24, 24)

func _process(delta):
	# Snap the player to the nearest grid point based on their position
	if player:
		var player_pos = player.global_transform.origin
		var snapped_pos = snap_to_grid(player_pos, grid_spacing)

		# Update labels for debugging
		var rounded_x = player_pos.x
		var rounded_y = player_pos.y
		var rounded_z = player_pos.z

		label.text = "Player Position: X: " + str(rounded_x) + ", Y: " + str(rounded_y) + ", Z: " + str(rounded_z)
		label2.text = "Position Snapped: " + str(snapped_pos)

		# Update grid texture to highlight player position
		_update_grid_texture(snapped_pos)
	 


func snap_to_grid(play_position: Vector3, spacing: float) -> Vector3:
	# Restrict values between 0 and 3 with 16 steps
	var min_value = 0.0
	var max_value = 1.0
	var step_size = 10 

	var snapped_x = round(play_position.x) 
	var snapped_y = round(play_position.y) 
	var snapped_z = round(play_position.z)


	return Vector3(snapped_x, snapped_y, snapped_z)

func _create_grid_texture(rows: int, cols: int):
	# Create an image to represent the grid
	drawing_texture = Image.create(rows, cols, false, Image.FORMAT_RGBA8)
	drawing_texture.fill(Color(1, 1, 1, 1))  # White background with full alpha

	# Draw grid lines
	var line_color = Color(0, 0, 0, 1)  # Black grid lines
	for row in range(rows):
		for col in range(cols):
			# Draw grid points
			if row % 2 == 0 or col % 2 == 0:
				drawing_texture.set_pixel(row, col, line_color)

	drawing_texture_data = ImageTexture.create_from_image(drawing_texture)
	update_material(drawing_texture_data)
func _update_grid_texture(snapped_pos: Vector3):
	# Define grid dimensions (if needed for further operations)
	var rows = 8
	var cols = 8
	# Define the base highlight color (if needed)
	var highlight_color = Color(1, 0, 0, 1)  # Red color

	# Calculate grid coordinates from snapped position.
	# (Cast to int since image pixels are addressed with integer coordinates.)
	var grid_x = int(snapped_pos.z + 0)
	var grid_y = int(snapped_pos.x + 24)  # Up farward

	# Get the current color of the pixel at (grid_x, grid_y)
	var current_color = drawing_texture.get_pixel(grid_x, grid_y)

	# Add 0.01 to the red channel (and clamp it between 0.0 and 1.0)
	current_color.r = clamp(current_color.r + 0.2, 0.1, 1.0)

	# Set the pixel to the new color
	drawing_texture.set_pixel(grid_x, grid_y, current_color)

	# Update the label text for debugging.
	label.text = "x: " + str(grid_x) + " y: " + str(grid_y)
	
	# Update the texture
	drawing_texture_data.update(drawing_texture)
	update_material(drawing_texture_data)

# Function to update the material's albedo texture
func update_material(tex: ImageTexture):
	if PlainGrid.material_override is ShaderMaterial:
		var shader_material = PlainGrid.material_override as ShaderMaterial
		shader_material.set_shader_parameter("texture_albedo", tex)
	else:
		var material = StandardMaterial3D.new()
		material.albedo_texture = tex
		PlainGrid.material_override = material

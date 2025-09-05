# Attach this script to your main node or player
extends Node3D

@onready var position_label: Label3D = $Label3D  # Adjust path as needed

func _ready():
	# Configure the Label3D for better visibility
	if position_label:

		position_label.font_size = 48
		position_label.modulate = Color.WHITE
		position_label.pixel_size = 0.0005
		# Position the label above the object
 
		# Initial position update
		update_position_display()

func _process(delta):
	# Update position display every frame
	update_position_display()

func update_position_display():
	if position_label:
		# Get current world position
		var current_pos = global_position
		
		# Format the position text
		position_label.text = "x:%.1f, y:%.1f, z:%.1f)" % [
			current_pos.x, 
			current_pos.y, 
			current_pos.z
		]
		
		# Optional: Also show grid position if using the grid system
		# Uncomment if you want to show grid coordinates too
		# var grid_pos = GridCommon.world_to_grid_position(current_pos, 1.0, 0.0)
		# position_label.text += "\nGrid: (%d, %d, %d)" % [grid_pos.x, grid_pos.y, grid_pos.z]

# Alternative: Update only when position changes significantly
var last_displayed_position: Vector3

func _physics_process(delta):
	var current_pos = global_position
	
	# Only update if position changed by more than 0.1 units
	if current_pos.distance_to(last_displayed_position) > 0.1:
		update_position_display()
		last_displayed_position = current_pos

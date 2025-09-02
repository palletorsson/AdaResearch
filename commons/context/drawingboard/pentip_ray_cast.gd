extends Node3D

@onready var raycast: RayCast3D = $"../RayCast3D"  
@onready var debug_label: Label3D = $"../Label3D"  
@onready var paper_surface: MeshInstance3D = $"../../../DrawingArea3D/PaperDrawSurface"  

# Paper surface dimensions
@export var paper_width: float = 2.0  
@export var paper_height: float = 2.0  
@export var smoothing_factor: float = 0.5  
@export var brush_size: int = 10  
@export var snap_grid_size: int = 16  
@export var is_experimental: bool = false  # Set true for the experimental pen, false for the black pen

# Experimental Pen Settings
@export var available_colors: Array = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
@export var min_brush_size: int = 1
@export var max_brush_size: int = 10
@export var min_snap_size: int = 4  
@export var max_snap_size: int = 32  
@export var use_random_dots: bool = false  
@export var random_dot_count: int = 4  
@export var random_dot_colors: Array = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW]  
@export var random_dot_spread: float = 0.02  

var last_uv_position: Vector2 = Vector2(-1, -1)  
var smoothed_uv_position: Vector2 = Vector2(-1, -1)  
var is_grabbed: bool = false  

func _ready():
	raycast.visible = true  
	raycast.enabled = false  

func _process(delta):
	if is_grabbed and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider:
			var hit_position = raycast.get_collision_point()
			var local_hit_position = paper_surface.to_local(hit_position)

			# Convert to UV coordinates
			var uv = Vector2(
				(local_hit_position.x + paper_width / 2) / paper_width,
				(local_hit_position.z + paper_height / 2) / paper_height
			)

			# Smooth the position for better drawing quality
			if smoothed_uv_position != Vector2(-1, -1):
				smoothed_uv_position = smoothed_uv_position.lerp(uv, smoothing_factor)
			else:
				smoothed_uv_position = uv  

			# Always draw a line from the last position to the new position
			if last_uv_position != Vector2(-1, -1):
				paper_surface.call("draw_line", last_uv_position, smoothed_uv_position, brush_size)
			else:
				paper_surface.call("draw_point", smoothed_uv_position, brush_size)  

			# Optionally draw random dots
			if use_random_dots and is_experimental:
				draw_random_dots(smoothed_uv_position)

			last_uv_position = smoothed_uv_position  # Update last position
		else:
			reset_positions()

	else:
		reset_positions()

# Draws random dots for the experimental pen
func draw_random_dots(uv_position: Vector2):
	for i in range(random_dot_count):
		var random_offset = Vector2(randf_range(-random_dot_spread, random_dot_spread), randf_range(-random_dot_spread, random_dot_spread))
		var dot_position = uv_position + random_offset
		var random_color = random_dot_colors[randi() % random_dot_colors.size()]
		paper_surface.call("draw_point", dot_position, random_color)

# Called when the pen is grabbed
func _on_grab_pen_1_grabbed(pickable: Variant, by: Variant) -> void:
	is_grabbed = true
	raycast.enabled = true

	if is_experimental:
		# Dynamic experimental pen behavior
		var pen_color = available_colors[randi() % available_colors.size()]
		var pen_size = randi_range(min_brush_size, max_brush_size)
		var snap_size = randi_range(min_snap_size, max_snap_size)
		use_random_dots = randf() > 0.5  

		paper_surface.call("update_pen", pen_size, pen_color, snap_size, use_random_dots)
		debug_label.text = "Experimental Pen Active: " + str(pen_color)
	else:
		# Basic pen (always black)
		paper_surface.call("update_pen", brush_size, Color.BLACK, snap_grid_size, false)
		debug_label.text = "Basic Pen Active"

# Called when the pen is released
func _on_grab_pen_1_dropped(pickable: Variant) -> void:
	is_grabbed = false
	raycast.enabled = false  
	reset_positions()
	debug_label.text = "Pen Released."

# Reset positions when drawing stops
func reset_positions():
	last_uv_position = Vector2(-1, -1)
	smoothed_uv_position = Vector2(-1, -1)

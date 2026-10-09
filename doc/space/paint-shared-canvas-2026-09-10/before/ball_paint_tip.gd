extends Node3D

var raycast: RayCast3D
var debug_label: Label3D

# Reference to the paper surface - set via script or find automatically
@export var paper_surface: MeshInstance3D
@export var paper_width: float = 4.0
@export var paper_height: float = 4.0
@export var brush_size: int = 10
@export var snap_grid_size: int = 16
@export var brush_color: Color = Color.BLACK
@export var is_experimental: bool = false

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
var is_painting: bool = false

func _ready():
	# Find raycast
	raycast = get_node_or_null("RayCast3D")
	if raycast:
		raycast.visible = false
		raycast.enabled = true
	else:
		push_error("BallPaintTip: RayCast3D not found!")
		return

	# Find debug label
	debug_label = get_node_or_null("../Label3D")

	# Find paper surface if not set
	if paper_surface == null:
		paper_surface = get_tree().get_first_node_in_group("drawing_surface")
		if paper_surface == null:
			# Try to find it by path
			var drawing_area = get_node_or_null("/root/*/DrawingArea3D")
			if drawing_area:
				paper_surface = drawing_area.get_node_or_null("PaperDrawSurface")

	# Update the pen properties on the surface
	if paper_surface:
		paper_surface.call("update_pen", brush_size, brush_color, snap_grid_size, use_random_dots)

func _process(_delta):
	if not raycast or not raycast.is_colliding():
		if is_painting:
			is_painting = false
			reset_positions()
		return

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("drawing_area"):
			# The drawing surface can be freed on map reload — re-acquire or bail
			# so we never call into a previously freed instance.
			if not is_instance_valid(paper_surface):
				paper_surface = get_tree().get_first_node_in_group("drawing_surface")
				if not is_instance_valid(paper_surface):
					return

			if not is_painting:
				is_painting = true
				reset_positions()

			var hit_position = raycast.get_collision_point()
			var local_hit_position = paper_surface.to_local(hit_position)

			# Convert to UV coordinates
			var uv = Vector2(
				(local_hit_position.x + paper_width / 2) / paper_width,
				(local_hit_position.z + paper_height / 2) / paper_height
			)

			# Smooth the position for better drawing quality
			if smoothed_uv_position != Vector2(-1, -1):
				smoothed_uv_position = smoothed_uv_position.lerp(uv, 0.5)
			else:
				smoothed_uv_position = uv

			# Always draw a line from the last position to the new position
			if last_uv_position != Vector2(-1, -1):
				paper_surface.call("draw_line", last_uv_position, smoothed_uv_position, brush_color, brush_size, snap_grid_size)
			else:
				paper_surface.call("draw_point", smoothed_uv_position, brush_color, brush_size, snap_grid_size)

			# Optionally draw random dots
			if use_random_dots and is_experimental:
				draw_random_dots(smoothed_uv_position)

			last_uv_position = smoothed_uv_position
		else:
			if is_painting:
				is_painting = false
				reset_positions()
	else:
		if is_painting:
			is_painting = false
			reset_positions()

# Draws random dots for the experimental pen
func draw_random_dots(uv_position: Vector2):
	for i in range(random_dot_count):
		var random_offset = Vector2(randf_range(-random_dot_spread, random_dot_spread), randf_range(-random_dot_spread, random_dot_spread))
		var dot_position = uv_position + random_offset
		var random_color = random_dot_colors[randi() % random_dot_colors.size()]
		paper_surface.call("draw_point", dot_position, random_color)

# Reset positions when drawing stops
func reset_positions():
	last_uv_position = Vector2(-1, -1)
	smoothed_uv_position = Vector2(-1, -1)

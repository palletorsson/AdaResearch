extends Node2D

# Grid properties
@export var grid_size: Vector2 = Vector2(10, 10)  # Number of cells
@export var cell_size: Vector2 = Vector2(50, 50)  # Size of each cell in pixels
@export var grid_color: Color = Color(0.7, 0.7, 0.7, 0.3)  # Subtle light gray, semi-transparent
@export var background_color: Color = Color(0.95, 0.95, 0.9, 1.0)  # Off-white/cream background
@export var line_width: float = 1.0
@export var grid_margin: Vector2 = Vector2(50, 50)  # Margin from the edges

func _ready():
	# Optional: Center the grid on the screen
	position = get_viewport_rect().size / 2 - (grid_size * cell_size) / 2

func _draw():
	# Calculate grid boundaries
	var grid_rect = Rect2(
		grid_margin, 
		Vector2(grid_size.x * cell_size.x, grid_size.y * cell_size.y)
	)
	
	# Draw background
	draw_rect(grid_rect, background_color)
	
	# Draw horizontal lines
	for y in range(grid_size.y + 1):
		var start_pos = Vector2(grid_rect.position.x, grid_rect.position.y + y * cell_size.y)
		var end_pos = Vector2(grid_rect.position.x + grid_rect.size.x, grid_rect.position.y + y * cell_size.y)
		draw_line(start_pos, end_pos, grid_color, line_width)
	
	# Draw vertical lines
	for x in range(grid_size.x + 1):
		var start_pos = Vector2(grid_rect.position.x + x * cell_size.x, grid_rect.position.y)
		var end_pos = Vector2(grid_rect.position.x + x * cell_size.x, grid_rect.position.y + grid_rect.size.y)
		draw_line(start_pos, end_pos, grid_color, line_width)

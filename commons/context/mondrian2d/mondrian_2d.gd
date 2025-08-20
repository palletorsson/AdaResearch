extends Node2D

# Signals
signal pattern_changed()  # Emitted when a new pattern is generated

# Mondrian color palette
const COLOR_WHITE = Color(0.95, 0.95, 0.95)
const COLOR_BLACK = Color(0.1, 0.1, 0.1)
const COLOR_RED = Color(0.9, 0.1, 0.1)
const COLOR_BLUE = Color(0.1, 0.1, 0.9)
const COLOR_YELLOW = Color(0.9, 0.9, 0.1)

# Grid configuration
const LINE_THICKNESS = 8

# Auto-change settings
@export var auto_change_pattern: bool = true
@export var pattern_change_interval: float = 10.0  # Change every 10 seconds

# Lists to store grid lines and colored sections
var horizontal_lines = []
var vertical_lines = []
var colored_sections = []

# Timer for automatic pattern changes
var pattern_timer: Timer

# Viewport size (will be set in _ready)
var viewport_size = Vector2(600, 600)
var canvas_width = 0
var canvas_height = 0

func _ready():
	# Get the actual viewport size with error handling
	var viewport = get_viewport()
	if viewport:
		viewport_size = viewport.get_visible_rect().size
	else:
		# Fallback to default size if viewport not available
		viewport_size = Vector2(600, 600)
	
	# Calculate canvas dimensions to maintain 60:55 aspect ratio
	# But fill the viewport completely (no empty space)
	if viewport_size.x / viewport_size.y > 60.0 / 55.0:
		# Viewport is wider than painting aspect ratio
		canvas_height = viewport_size.y
		canvas_width = canvas_height * (60.0 / 55.0)
	else:
		# Viewport is taller than painting aspect ratio
		canvas_width = viewport_size.x
		canvas_height = canvas_width * (55.0 / 60.0)
	
	# Center the canvas in the viewport
	position = (viewport_size - Vector2(canvas_width, canvas_height)) / 2
	
	# Create the Mondrian composition data
	generate_new_pattern()
	
	# Call to draw will happen automatically through _draw
	
	# Setup automatic pattern changes
	if auto_change_pattern:
		setup_pattern_timer()
	
	# Start continuous updates for countdown display
	if auto_change_pattern:
		# Update countdown every second
		var countdown_timer = Timer.new()
		countdown_timer.wait_time = 1.0
		countdown_timer.one_shot = false
		countdown_timer.timeout.connect(_on_countdown_update)
		add_child(countdown_timer)
		countdown_timer.start()

func setup_pattern_timer():
	"""Setup timer for automatic pattern changes"""
	pattern_timer = Timer.new()
	pattern_timer.wait_time = pattern_change_interval
	pattern_timer.one_shot = false  # Repeat continuously
	pattern_timer.timeout.connect(_on_pattern_timer_timeout)
	add_child(pattern_timer)
	pattern_timer.start()
	print("Pattern change timer started - changing every ", pattern_change_interval, " seconds")

func _on_pattern_timer_timeout():
	"""Called every time the pattern timer expires"""
	print("Timer expired - generating new pattern automatically")
	generate_new_pattern()
	# Force immediate update for 3D context
	force_immediate_update()

func _on_countdown_update():
	"""Update countdown display every second"""
	if auto_change_pattern:
		queue_redraw()  # Redraw to update countdown

# Timer control methods
func start_auto_change():
	"""Start automatic pattern changes"""
	if not pattern_timer:
		setup_pattern_timer()
	else:
		pattern_timer.start()
	print("Auto pattern change started")

func stop_auto_change():
	"""Stop automatic pattern changes"""
	if pattern_timer:
		pattern_timer.stop()
	print("Auto pattern change stopped")

func set_change_interval(new_interval: float):
	"""Change the interval between pattern changes"""
	pattern_change_interval = new_interval
	if pattern_timer:
		pattern_timer.wait_time = new_interval
		print("Pattern change interval set to ", new_interval, " seconds")

func get_timer_status() -> Dictionary:
	"""Get current timer status for debugging"""
	var status = {
		"auto_change_enabled": auto_change_pattern,
		"interval": pattern_change_interval,
		"timer_active": pattern_timer != null and pattern_timer.time_left > 0,
		"time_until_next": pattern_timer.time_left if pattern_timer else -1
	}
	return status

# Simple manual trigger method
func change_pattern_now():
	"""Manually trigger a pattern change immediately"""
	print("Manual pattern change triggered")
	generate_new_pattern()
	force_immediate_update()
	# Reset timer so next automatic change happens in full interval
	if pattern_timer:
		pattern_timer.start()

func define_grid_lines():
	# Define the horizontal grid lines based on the image
	# Format: {y_position, start_x, end_x}
	
	# Calculate positions based on canvas height
	var top_border = 0      # Top edge
	var first_horizontal = canvas_height * 0.33 # ~33% from top
	var second_horizontal = canvas_height * 0.66 # ~66% from top
	var bottom_border = canvas_height    # Bottom edge
	
	horizontal_lines = [
		# Horizontal lines from top to bottom
		{"y": top_border, "start_x": 0, "end_x": canvas_width},             # Top border
		{"y": first_horizontal, "start_x": 0, "end_x": canvas_width},       # First internal horizontal
		{"y": second_horizontal, "start_x": 0, "end_x": canvas_width},      # Second internal horizontal
		{"y": bottom_border, "start_x": 0, "end_x": canvas_width}           # Bottom border
	]
	
	# Define vertical grid lines
	# Calculate positions based on canvas width
	var left_border = 0       # Left edge
	var first_vertical = canvas_width * 0.16    # ~16% from left
	var second_vertical = canvas_width * 0.33    # ~33% from left
	var third_vertical = canvas_width * 0.5    # Middle (50%)
	var fourth_vertical = canvas_width * 0.66    # ~66% from left
	
	# Fibonacci-like sequence for right vertical lines
	var right_v1 = canvas_width * 0.75         # ~75% from left
	var right_v2 = canvas_width * 0.81         # ~81% from left
	var right_v3 = canvas_width * 0.87         # ~87% from left
	var right_v4 = canvas_width * 0.93         # ~93% from left
	var right_border = canvas_width            # Right edge
	
	vertical_lines = [
		# Main vertical lines from left to right
		{"x": left_border, "start_y": top_border, "end_y": bottom_border},      # Left border
		{"x": first_vertical, "start_y": top_border, "end_y": bottom_border},    # First internal vertical
		{"x": second_vertical, "start_y": top_border, "end_y": bottom_border},   # Second internal vertical
		{"x": third_vertical, "start_y": top_border, "end_y": bottom_border},    # Third internal vertical (middle)
		{"x": fourth_vertical, "start_y": top_border, "end_y": bottom_border},   # Fourth internal vertical
		
		# The closely spaced Fibonacci-like vertical lines on the right side
		{"x": right_v1, "start_y": top_border, "end_y": bottom_border},         # First narrow vertical
		{"x": right_v2, "start_y": top_border, "end_y": bottom_border},         # Second narrow vertical
		{"x": right_v3, "start_y": top_border, "end_y": bottom_border},         # Third narrow vertical
		{"x": right_v4, "start_y": top_border, "end_y": bottom_border},         # Fourth narrow vertical
		{"x": right_border, "start_y": top_border, "end_y": bottom_border}      # Right border
	]

func define_colored_sections():
	# Get grid positions for easy reference
	var top = horizontal_lines[0]["y"]
	var middle_top = horizontal_lines[1]["y"] 
	var middle_bottom = horizontal_lines[2]["y"]
	var bottom = horizontal_lines[3]["y"]
	
	var left = vertical_lines[0]["x"]
	var first_v = vertical_lines[1]["x"]
	var second_v = vertical_lines[2]["x"] 
	var middle = vertical_lines[3]["x"]
	var fourth_v = vertical_lines[4]["x"]
	var right_area = vertical_lines[5]["x"]  # Start of narrow streets
	
	# Define colored sections
	# Red sections - top right and bottom left
	colored_sections.append({
		"rect": Rect2(fourth_v, top, right_area - fourth_v, middle_top - top),  # Top-right red rectangle
		"color": COLOR_RED
	})
	
	colored_sections.append({
		"rect": Rect2(left, middle_top, first_v - left, middle_bottom - middle_top),  # Bottom-left red rectangle
		"color": COLOR_RED
	})
	
	# Blue section - top middle
	colored_sections.append({
		"rect": Rect2(second_v, top, middle - second_v, middle_top - top),  # Top-middle blue rectangle
		"color": COLOR_BLUE
	})
	
	# Yellow section - middle bottom
	colored_sections.append({
		"rect": Rect2(second_v, middle_bottom, middle - second_v, bottom - middle_bottom),  # Middle-bottom yellow rectangle
		"color": COLOR_YELLOW
	})

# Add countdown display to the drawing
func _draw():
	# Draw white background for the entire canvas
	draw_rect(Rect2(0, 0, canvas_width, canvas_height), COLOR_WHITE, true)
	
	# Draw colored sections
	for section in colored_sections:
		draw_rect(section["rect"], section["color"], true)
	
	# Draw horizontal grid lines
	for line in horizontal_lines:
		draw_line(
			Vector2(line["start_x"], line["y"]), 
			Vector2(line["end_x"], line["y"]), 
			COLOR_BLACK, 
			LINE_THICKNESS
		)
	
	# Draw vertical grid lines
	for line in vertical_lines:
		draw_line(
			Vector2(line["x"], line["start_y"]), 
			Vector2(line["x"], line["end_y"]), 
			COLOR_BLACK, 
			LINE_THICKNESS
		)
	
	# Draw countdown timer if auto-change is enabled
	if auto_change_pattern and pattern_timer:
		var time_left = pattern_timer.time_left
		var countdown_text = "Next: " + str(int(time_left)) + "s"
		var font_size = 24
		var text_pos = Vector2(10, 30)
		
		# Draw background for text
		draw_rect(Rect2(text_pos.x - 5, text_pos.y - font_size + 5, 120, font_size + 10), Color(0, 0, 0, 0.7), true)
		# Draw simple visual countdown indicator instead of text
		var progress = 1.0 - (time_left / pattern_change_interval)
		var bar_width = 100
		var bar_height = 8
		var bar_x = text_pos.x
		var bar_y = text_pos.y + 5
		
		# Draw progress bar background
		draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.3, 0.3, 0.3, 0.8), true)
		# Draw progress bar fill
		draw_rect(Rect2(bar_x, bar_y, bar_width * progress, bar_height), Color(0.8, 1.0, 0.8, 0.9), true)
		# Draw border
		draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(1, 1, 1, 0.5), false, 2.0)

# For animation/interaction
func animate_construction():
	# Temporarily store original data
	var original_horizontals = horizontal_lines.duplicate(true)
	var original_verticals = vertical_lines.duplicate(true)
	var original_colors = colored_sections.duplicate(true)
	
	# Clear everything
	horizontal_lines.clear()
	vertical_lines.clear()
	colored_sections.clear()
	queue_redraw()
	
	# Sequence with delays
	await get_tree().create_timer(0.5).timeout
	
	# Step 1: Draw horizontal lines
	horizontal_lines = original_horizontals.duplicate(true)
	queue_redraw()
	await get_tree().create_timer(0.5).timeout
	
	# Step 2: Draw vertical lines
	vertical_lines = original_verticals.duplicate(true)
	queue_redraw()
	await get_tree().create_timer(0.5).timeout
	
	# Step 3: Add red sections
	for section in original_colors:
		if section["color"] == COLOR_RED:
			colored_sections.append(section)
	queue_redraw()
	await get_tree().create_timer(0.5).timeout
	
	# Step 4: Add blue sections
	for section in original_colors:
		if section["color"] == COLOR_BLUE:
			colored_sections.append(section)
	queue_redraw()
	await get_tree().create_timer(0.5).timeout
	
	# Step 5: Add yellow section
	for section in original_colors:
		if section["color"] == COLOR_YELLOW:
			colored_sections.append(section)
	queue_redraw()

# Generate a new random Mondrian pattern
func generate_new_pattern():
	"""Generate a new random Mondrian composition while maintaining the classic style"""
	# Clear existing data
	horizontal_lines.clear()
	vertical_lines.clear()
	colored_sections.clear()
	
	# Generate random grid lines in Mondrian style
	generate_random_grid_lines()
	generate_random_colored_sections()
	
	# Force a redraw
	queue_redraw()
	
	# Force SubViewport update if we're in a 3D context
	_force_viewport_update()
	
	# Emit signal for pattern change
	pattern_changed.emit()
	
	print("Generated new Mondrian pattern")

func _force_viewport_update():
	"""Force the SubViewport to update and refresh the 3D texture"""
	# Find parent SubViewport if we're in a 3D context
	var parent = get_parent()
	while parent:
		if parent is SubViewport:
			# Force the viewport to update
			parent.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			# Trigger a texture update by forcing a size change
			var current_size = parent.size
			parent.size = Vector2(current_size.x + 1, current_size.y + 1)
			await get_tree().process_frame
			parent.size = current_size
			print("Forced SubViewport update")
			break
		parent = parent.get_parent()
	
	# Also try to find the SubViewport in the scene tree
	var subviewport = get_node_or_null("../SubViewport")
	if subviewport:
		# Force the SubViewport to update
		subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		subviewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
		
		# Force immediate update
		var current_size = subviewport.size
		subviewport.size = Vector2(current_size.x + 1, current_size.y + 1)
		await get_tree().process_frame
		subviewport.size = current_size
		
		print("Forced SubViewport update via direct path")

# Public method to force a pattern update (can be called from 3D context)
func force_pattern_update():
	"""Public method to force a complete pattern update and viewport refresh"""
	generate_new_pattern()
	
	# Additional viewport forcing for stubborn cases
	var parent = get_parent()
	while parent:
		if parent is SubViewport:
			# Multiple update strategies
			parent.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			parent.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
			
			# Force immediate update
			parent.size = parent.size
			parent.update_mode = SubViewport.UPDATE_ALWAYS
			
			print("Forced comprehensive SubViewport update")
			break
		parent = parent.get_parent()
	
	# Direct SubViewport access and force update
	var subviewport = get_node_or_null("../SubViewport")
	if subviewport:
		# Force aggressive update
		subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		subviewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
		subviewport.update_mode = SubViewport.UPDATE_ALWAYS
		
		# Force texture refresh
		subviewport.size = subviewport.size
		subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		
		# Wait a frame and force again
		await get_tree().process_frame
		subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		
		print("Forced aggressive SubViewport update via direct access")

# Method to force immediate update without waiting
func force_immediate_update():
	"""Force immediate SubViewport update without waiting for frames"""
	var subviewport = get_node_or_null("../SubViewport")
	if subviewport:
		# Set to always update
		subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		subviewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
		subviewport.update_mode = SubViewport.UPDATE_ALWAYS
		
		# Force size change to trigger update
		var current_size = subviewport.size
		subviewport.size = Vector2(current_size.x + 1, current_size.y + 1)
		subviewport.size = current_size
		
		# Force render target update
		subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		
		print("Forced immediate SubViewport update")

# Public method that can be called from 3D context
func manual_pattern_change():
	"""Public method to manually trigger a pattern change - useful for debugging"""
	print("Manual pattern change triggered")
	generate_new_pattern()
	force_immediate_update()
	pattern_changed.emit()

func generate_random_grid_lines():
	"""Generate random grid lines in Mondrian style"""
	# Add some random horizontal lines
	var h_line_count = randi_range(3, 6)
	for i in range(h_line_count):
		var y_pos = randf_range(0.1, 0.9) * canvas_height
		var start_x = randf_range(0.0, 0.3) * canvas_width
		var end_x = randf_range(0.7, 1.0) * canvas_width
		horizontal_lines.append({
			"y": y_pos,
			"start_x": start_x,
			"end_x": end_x
		})
	
	# Add some random vertical lines
	var v_line_count = randi_range(3, 6)
	for i in range(v_line_count):
		var x_pos = randf_range(0.1, 0.9) * canvas_width
		var start_y = randf_range(0.0, 0.3) * canvas_height
		var end_y = randf_range(0.7, 1.0) * canvas_height
		vertical_lines.append({
			"x": x_pos,
			"start_y": start_y,
			"end_y": end_y
		})

func generate_random_colored_sections():
	"""Generate random colored sections in Mondrian style"""
	var colors = [COLOR_RED, COLOR_BLUE, COLOR_YELLOW]
	var section_count = randi_range(2, 5)
	
	for i in range(section_count):
		var color = colors[randi() % colors.size()]
		
		# Generate random bounds
		var left = randf_range(0.0, 0.6) * canvas_width
		var right = randf_range(0.4, 1.0) * canvas_width
		var top = randf_range(0.0, 0.6) * canvas_height
		var bottom = randf_range(0.4, 1.0) * canvas_height
		
		# Ensure section bounds are valid
		if left < right and top < bottom:
			var section = {
				"rect": Rect2(left, top, right - left, bottom - top),
				"color": color
			}
			colored_sections.append(section)

# Event handlers for grab/drop functionality
func _on_grab_cube_grabbed():
	"""Called when the Mondrian is grabbed"""
	print("Mondrian grabbed")

func _on_grab_cube_dropped():
	"""Called when the Mondrian is dropped"""
	print("Mondrian dropped - generating new pattern")
	# Use the more robust update method
	force_pattern_update()
	# Also force immediate update for better responsiveness
	force_immediate_update()

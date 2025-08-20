extends Node3D

# This is a revised animation sequence for the Mondrian Grid
# that doesn't use anonymous functions in arrays

# Reference to the main mondrian grid
@onready var mondrian_grid = $".."  # Update this path to match your scene structure

var current_step = 0
var timer = null

func _ready():
	# Create timer for sequencing
	timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = false
	add_child(timer)
	
	# Connect timer signal
	timer.timeout.connect(_on_timer_timeout)

func start_animation():
	# Start the animation sequence
	current_step = 0
	
	# Execute first step
	_execute_step(current_step)
	current_step += 1
	
	# Start timer for next steps
	timer.start()

func _on_timer_timeout():
	if current_step < 6:  # Total number of steps
		_execute_step(current_step)
		current_step += 1
	else:
		# Animation complete, restart
		current_step = 0
		_execute_step(current_step)
		current_step += 1

func _execute_step(step):
	# Execute the appropriate step based on the step number
	match step:
		0:
			_step_show_grid_only()
		1:
			_step_add_red_cells()
		2:
			_step_add_blue_cells()
		3:
			_step_add_yellow_cells()
		4:
			_step_show_explanation()
		5:
			_step_reset()

func _step_show_grid_only():
	# Reset to normal view first
	if mondrian_grid.has_method("reset_to_normal"):
		mondrian_grid.reset_to_normal()
	else:
		# Alternative approach if reset_to_normal doesn't exist
		_show_all_elements()
	
	# Make only grid lines visible
	for cell in mondrian_grid.mondrian_elements["cells"]:
		cell.visible = false

func _step_add_red_cells():
	for cell in mondrian_grid.mondrian_elements["cells"]:
		if cell.material_override.albedo_color.is_equal_approx(mondrian_grid.COLOR_RED):
			cell.visible = true
			
			# Animate cell appearing
			var tween = create_tween()
			cell.scale = Vector3.ZERO
			tween.tween_property(cell, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC)

func _step_add_blue_cells():
	for cell in mondrian_grid.mondrian_elements["cells"]:
		if cell.material_override.albedo_color.is_equal_approx(mondrian_grid.COLOR_BLUE):
			cell.visible = true
			
			# Animate cell appearing
			var tween = create_tween()
			cell.scale = Vector3.ZERO
			tween.tween_property(cell, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC)

func _step_add_yellow_cells():
	for cell in mondrian_grid.mondrian_elements["cells"]:
		if cell.material_override.albedo_color.is_equal_approx(mondrian_grid.COLOR_YELLOW):
			cell.visible = true
			
			# Animate cell appearing
			var tween = create_tween()
			cell.scale = Vector3.ZERO
			tween.tween_property(cell, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC)

func _step_show_explanation():
	# Create explanation text
	var explanation = Label3D.new()
	explanation.text = "Mondrian's grid-based compositions demonstrate how simple geometric forms and primary colors can create balanced, harmonious artworks."
	explanation.font_size = 28
	explanation.position = Vector3(0, -4, 1)
	explanation.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(explanation)
	explanation.name = "FinalExplanation"

func _step_reset():
	# Reset to normal view
	if mondrian_grid.has_method("reset_to_normal"):
		mondrian_grid.reset_to_normal()
	else:
		# Alternative approach
		_show_all_elements()
	
	# Remove explanation if it exists
	if has_node("FinalExplanation"):
		get_node("FinalExplanation").queue_free()
	
	# Restart after a pause by stopping the timer
	timer.stop()
	# Wait a bit before restarting
	await get_tree().create_timer(3.0).timeout
	
	# Restart animation
	start_animation()

func _show_all_elements():
	# Make all elements visible
	if "mondrian_elements" in mondrian_grid:
		for cell in mondrian_grid.mondrian_elements["cells"]:
			cell.visible = true
			cell.scale = Vector3.ONE
		
		for line in mondrian_grid.mondrian_elements["lines"]:
			line.visible = true

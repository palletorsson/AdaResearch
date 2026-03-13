# ===========================================================================
# Hilbert3D Curve - L-System Space-Filling Curve
# Implementation: AI-assisted GDScript, 2025
#
# A 3D Hilbert curve demonstrating space-filling properties using L-Systems
# License: CC BY-NC-SA 3.0
# ===========================================================================

extends Node3D

## 3D Hilbert Curve - Space-Filling Curve Visualization
## Demonstrates how L-Systems can efficiently fill 3D space
## Chapter: L-Systems (Architecture & Space-Filling)

@export var generations: int = 2  # 2 generations = ~50 segments
@export var step_length: float = 2.5  # 2.5 meters per segment to fill 10x10 area
@export var turn_angle: float = 90.0
@export var show_generation_animation: bool = false
@export var curve_thickness: float = 0.08  # Thicker for visibility at larger scale
@export var animate_drawing: bool = true
@export var drawing_speed: float = 20.0  # Segments per second
@export var ball_size: float = 0.15  # Larger balls for 2.5m segments

var lsystem
var turtle: Turtle3D

# Current generation being displayed
var current_generation: int = 0
var generation_timer: float = 0.0
var generation_speed: float = 2.0  # Seconds per generation

# Animation variables
var all_segments: Array = []  # Array of {start: Vector3, end: Vector3}
var current_segment_index: int = 0
var segment_timer: float = 0.0
var is_animating: bool = false
var animated_cylinders: Array = []
var animated_balls: Array = []

# UI
var info_label: Label3D
var description_label: Label3D
var generation_controller: ParameterController3D

func _ready() -> void:
	# Create turtle
	turtle = Turtle3D.new()
	turtle.use_pink_palette = false
	turtle.branch_thickness = curve_thickness
	# Set custom colors for space-filling curve - WHITE with emission
	turtle.set_colors(Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 1.0))
	turtle.position = Vector3.ZERO
	add_child(turtle)

	# Create 3D Hilbert L-System
	var LSystemClass = load("res://utils/lsystem.gd")
	lsystem = LSystemClass.create_3d_hilbert()

	# Create UI
	create_info_labels()
	create_controllers()

	# Generate and draw
	if show_generation_animation:
		current_generation = 0
		# Start with at least 1 generation
		lsystem.generate()
		current_generation = 1
		if animate_drawing:
			compute_segments()
			start_animation()
		else:
			draw_lsystem()
	else:
		lsystem.generate_n(generations)
		if animate_drawing:
			compute_segments()
			start_animation()
		else:
			draw_lsystem()
		current_generation = generations

	update_info_label()
	print("Hilbert3D: 3D Space-Filling Curve - Generations: %d" % generations)

func _process(delta: float) -> void:
	# Handle generation animation
	if show_generation_animation and current_generation < generations:
		generation_timer += delta
		if generation_timer >= generation_speed:
			generation_timer = 0.0
			lsystem.generate()
			current_generation += 1
			if animate_drawing:
				compute_segments()
				start_animation()
			else:
				draw_lsystem()
			update_info_label()

	# Handle drawing animation
	if is_animating:
		segment_timer += delta * drawing_speed

		while segment_timer >= 1.0 and current_segment_index < all_segments.size():
			var segment = all_segments[current_segment_index]
			create_animated_segment(segment["start"], segment["end"])
			current_segment_index += 1
			segment_timer -= 1.0

		if current_segment_index >= all_segments.size():
			is_animating = false
			print("Hilbert3D: Animation complete!")

func create_info_labels() -> void:
	"""Create info labels"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(0.3, 0.9, 1.0)
	info_label.position = Vector3(0, 1.2, 0)
	add_child(info_label)

	description_label = Label3D.new()
	description_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	description_label.font_size = 20
	description_label.modulate = Color(0.7, 0.85, 1.0)
	description_label.position = Vector3(0, 1.0, 0)
	description_label.text = "3D Space-Filling Curve"
	description_label.width = 600.0
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description_label)

func create_controllers() -> void:
	"""Create 3D controllers"""
	generation_controller = ParameterController3D.new()
	generation_controller.parameter_name = "Generations"
	generation_controller.min_value = 1.0
	generation_controller.max_value = 4.0
	generation_controller.default_value = float(generations)
	generation_controller.step_size = 1.0
	generation_controller.position = Vector3(0, -1.0, 0)
	generation_controller.value_changed.connect(_on_generation_changed)
	add_child(generation_controller)

func _on_generation_changed(new_gen: float) -> void:
	"""Update generation count and redraw"""
	generations = int(new_gen)
	reset()
	lsystem.generate_n(generations)
	current_generation = generations
	draw_lsystem()
	update_info_label()

func update_info_label() -> void:
	"""Update info labels"""
	if info_label:
		var instruction_length = lsystem.get_sentence().length()
		var path_segments = count_forward_moves(lsystem.get_sentence())
		info_label.text = "3D Hilbert Curve\nGeneration: %d\nPath Segments: %d" % [current_generation, path_segments]

func count_forward_moves(instructions: String) -> int:
	"""Count forward movement commands in L-System string"""
	var count = 0
	for char in instructions:
		if char == "F" or char == "G":
			count += 1
	return count

func draw_lsystem() -> void:
	"""Draw the L-System using turtle graphics"""
	if turtle:
		var instructions = lsystem.get_sentence()
		turtle.interpret_lsystem(instructions, step_length, turn_angle)

func increase_generations() -> void:
	"""Increase generation count"""
	if generations < 4:  # Limit to prevent excessive complexity
		generations += 1
		reset()
		lsystem.generate_n(current_generation)
		draw_lsystem()
		if generation_controller:
			generation_controller.set_value(float(generations))
		print("Generations increased to: %d" % generations)

func decrease_generations() -> void:
	"""Decrease generation count"""
	if generations > 1:
		generations -= 1
		if current_generation > generations:
			current_generation = generations
		reset()
		lsystem.generate_n(current_generation)
		draw_lsystem()
		if generation_controller:
			generation_controller.set_value(float(generations))
		print("Generations decreased to: %d" % generations)

func reset() -> void:
	"""Reset L-System and turtle"""
	current_generation = 0
	generation_timer = 0.0
	lsystem.reset()
	if turtle:
		turtle.reset()
	update_info_label()

func toggle_animation() -> void:
	"""Toggle generation animation"""
	show_generation_animation = !show_generation_animation
	if not show_generation_animation:
		# Show final generation immediately
		reset()
		lsystem.generate_n(generations)
		current_generation = generations
		draw_lsystem()
		update_info_label()

func compute_segments() -> void:
	"""Compute all line segments from the L-System instructions"""
	all_segments.clear()

	var cursor_transform = Transform3D.IDENTITY
	var state_stack: Array = []
	var instructions = lsystem.get_sentence()

	for char in instructions:
		match char:
			"F", "G":  # Forward with drawing
				var start_pos = cursor_transform.origin
				cursor_transform = cursor_transform.translated_local(Vector3.UP * step_length)
				var end_pos = cursor_transform.origin
				all_segments.append({"start": start_pos, "end": end_pos})

			"f":  # Forward without drawing
				cursor_transform = cursor_transform.translated_local(Vector3.UP * step_length)

			"+":  # Turn left
				var angle_rad = deg_to_rad(turn_angle)
				cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.z, angle_rad)

			"-":  # Turn right
				var angle_rad = deg_to_rad(turn_angle)
				cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.z, -angle_rad)

			"^":  # Pitch up
				var angle_rad = deg_to_rad(turn_angle)
				cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.x, angle_rad)

			"&":  # Pitch down
				var angle_rad = deg_to_rad(turn_angle)
				cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.x, -angle_rad)

			"<":  # Roll left
				var angle_rad = deg_to_rad(turn_angle)
				cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.y, angle_rad)

			">":  # Roll right
				var angle_rad = deg_to_rad(turn_angle)
				cursor_transform.basis = cursor_transform.basis.rotated(cursor_transform.basis.y, -angle_rad)

			"[":  # Push state
				state_stack.append(cursor_transform)

			"]":  # Pop state
				if not state_stack.is_empty():
					cursor_transform = state_stack.pop_back()

func start_animation() -> void:
	"""Start the drawing animation"""
	clear_animated_objects()
	current_segment_index = 0
	segment_timer = 0.0
	is_animating = true

	# Create starting ball at origin
	if all_segments.size() > 0:
		create_ball(all_segments[0]["start"])

func clear_animated_objects() -> void:
	"""Clear all animated cylinders and balls"""
	for cylinder in animated_cylinders:
		cylinder.queue_free()
	for ball in animated_balls:
		ball.queue_free()

	animated_cylinders.clear()
	animated_balls.clear()

func create_animated_segment(start: Vector3, end: Vector3) -> void:
	"""Create a cylinder segment and balls at corners"""
	# Create ball at the start point
	create_ball(start)

	# Create white emissive cylinder
	var cylinder = MeshInstance3D.new()
	var direction = end - start
	var length = direction.length()
	var midpoint = start + direction / 2.0

	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = curve_thickness
	cylinder_mesh.bottom_radius = curve_thickness
	cylinder_mesh.height = length

	cylinder.mesh = cylinder_mesh
	cylinder.position = midpoint

	# Orient cylinder
	if direction.length() > 0.001:
		var up = direction.normalized()
		var right = up.cross(Vector3.UP if abs(up.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT).normalized()
		var forward = right.cross(up).normalized()
		cylinder.basis = Basis(right, up, forward)

	# White emissive material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0, 1.0) * 0.8
	material.emission_energy_multiplier = 2.0
	cylinder.material_override = material

	add_child(cylinder)
	animated_cylinders.append(cylinder)

	# Create ball at the end point
	create_ball(end)

func create_ball(position: Vector3) -> void:
	"""Create a small black ball at the given position"""
	var ball = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = ball_size
	sphere.height = ball_size * 2

	ball.mesh = sphere
	ball.position = position

	# Black material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.0, 0.0, 1.0)
	material.roughness = 0.8
	ball.material_override = material

	add_child(ball)
	animated_balls.append(ball)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


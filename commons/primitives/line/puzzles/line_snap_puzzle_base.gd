extends Node3D
class_name LineSnapPuzzleBase

## LineSnapPuzzleBase - Base class for interactive line snap puzzles
## Child classes define line_definitions with start/end/target positions

## Puzzle Configuration
@export_group("Puzzle Configuration")
@export var auto_validate: bool = true  # Check on every endpoint move
@export var show_ghost_guides: bool = true  # Show target positions
@export var ghost_alpha: float = 0.3
@export var ghost_color: Color = Color(0.5, 0.5, 1, 0.3)
@export var ghost_line_width: float = 0.008  # Slightly thinner than actual lines

@export_group("Success Feedback")
@export var success_message: String = "Puzzle Complete!"
@export var lock_on_complete: bool = true
@export var show_success_label: bool = true
@export var success_display_duration: float = 3.0

@export_group("Tag System")
@export var trigger_tag: String = ""  # Tag to trigger on puzzle completion
@export var trigger_action: String = ""  # Action to execute (reveal, remove, hide, etc.)

## Internal state
var line_definitions: Array[Dictionary] = []  # Defined by child classes
var snap_lines: Array[SnapLineSegment] = []
var ghost_guides_container: Node3D
var instruction_label: Label3D
var success_label: Label3D
var is_completed: bool = false

## Signals
signal puzzle_completed()
signal line_snapped_to_target(line: SnapLineSegment)
signal all_lines_aligned()

func _ready() -> void:
	# Find or create containers
	_setup_containers()
	
	# Child class should have populated line_definitions
	if line_definitions.is_empty():
		push_error("LineSnapPuzzleBase: line_definitions not set by child class!")
		return
	
	# Wait for transform to be fully applied (rotation from GridInteractablesComponent)
	await get_tree().process_frame
	
	print("LineSnapPuzzleBase: Puzzle global_position = ", global_position)
	print("LineSnapPuzzleBase: Puzzle rotation_degrees = ", rotation_degrees)
	
	# Create the snap lines
	call_deferred("_setup_lines")
	
	# Create ghost guides
	if show_ghost_guides:
		call_deferred("_setup_ghost_guides")
	
	# Find instruction label
	instruction_label = get_node_or_null("InstructionLabel")
	
	# Create success label
	if show_success_label:
		_create_success_label()

func _setup_containers() -> void:
	"""Create container nodes for organization"""
	# Ghost guides container
	ghost_guides_container = get_node_or_null("GhostGuides")
	if not ghost_guides_container:
		ghost_guides_container = Node3D.new()
		ghost_guides_container.name = "GhostGuides"
		add_child(ghost_guides_container)

func _setup_lines() -> void:
	"""Create SnapLineSegment instances from line_definitions"""
	print("LineSnapPuzzleBase: Setting up %d lines..." % line_definitions.size())
	
	# Load the snap line segment scene
	var snap_line_scene = load("res://commons/primitives/line/snap_line_segment.tscn")
	if not snap_line_scene:
		push_error("LineSnapPuzzleBase: Could not load snap_line_segment.tscn")
		return
	
	for i in range(line_definitions.size()):
		var definition = line_definitions[i]
		print("  Line %d definition:" % (i + 1))
		print("    Start pos: ", definition["start_pos"])
		print("    End pos: ", definition["end_pos"])
		print("    Target start: ", definition["target_start"])
		print("    Target end: ", definition["target_end"])
		
		# Create line instance
		var snap_line = snap_line_scene.instantiate()
		snap_line.name = "SnapLine%d" % (i + 1)
		add_child(snap_line)
		
		# Give it a frame to initialize before setting positions
		await get_tree().process_frame
		
		# Set initial endpoint positions (relative to this node)
		if snap_line.endpoint_a and snap_line.endpoint_b:
			# Use transform to account for rotation
			snap_line.endpoint_a.global_position = global_transform * definition["start_pos"]
			snap_line.endpoint_b.global_position = global_transform * definition["end_pos"]
			print("    Set endpoints at: A=", snap_line.endpoint_a.global_position, " B=", snap_line.endpoint_b.global_position)
			
			# Set target positions (convert to global coordinates accounting for rotation)
			var target_start_global = global_transform * definition["target_start"]
			var target_end_global = global_transform * definition["target_end"]
			snap_line.set_targets(target_start_global, target_end_global)
			print("    Set targets (global) at: A=", target_start_global, " B=", target_end_global)
			
			# Give each line a slightly different color for visibility
			if i == 0:
				snap_line.set_line_color(Color(1.0, 0.9, 0.9, 0.9))  # Slightly reddish white
			elif i == 1:
				snap_line.set_line_color(Color(0.9, 0.9, 1.0, 0.9))  # Slightly bluish white
			
			# Connect signals
			snap_line.endpoints_changed.connect(_on_endpoints_changed.bind(snap_line))
			snap_line.snapped_to_target.connect(_on_line_snapped.bind(snap_line))
			snap_line.line_locked.connect(_on_line_locked.bind(snap_line))
			print("    Signals connected")
			
			# Force update line geometry
			snap_line._update_line_geometry()
			
			snap_lines.append(snap_line)
			print("  ✓ Line %d created successfully (color: %s)" % [i + 1, "reddish" if i == 0 else "bluish"])
		else:
			push_error("  ✗ Line %d missing endpoints!" % (i + 1))
	
	print("LineSnapPuzzleBase: All %d lines set up complete" % snap_lines.size())

func _setup_ghost_guides() -> void:
	"""Create visual guides showing target positions"""
	if not ghost_guides_container:
		return
	
	print("LineSnapPuzzleBase: Creating ghost guides...")
	print("  Puzzle rotation: ", rotation_degrees)
	for i in range(line_definitions.size()):
		var definition = line_definitions[i]
		print("  Ghost guide %d:" % (i + 1))
		print("    Start (local): ", definition["target_start"])
		print("    End (local):   ", definition["target_end"])
		print("    Start (global): ", global_transform * definition["target_start"])
		print("    End (global):   ", global_transform * definition["target_end"])
		
		var ghost_line = _create_ghost_line(
			definition["target_start"],
			definition["target_end"]
		)
		ghost_guides_container.add_child(ghost_line)
	
	print("LineSnapPuzzleBase: Created %d ghost guides" % line_definitions.size())

func _create_ghost_line(start: Vector3, end: Vector3) -> MeshInstance3D:
	"""Create a semi-transparent guide line at target position"""
	var ghost = MeshInstance3D.new()
	
	# Calculate line parameters
	var line_vector = end - start
	var line_length = line_vector.length()
	var line_center = (start + end) / 2.0
	
	if line_length < 0.001:
		return ghost
	
	# Create cylinder mesh
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = ghost_line_width
	cylinder.bottom_radius = ghost_line_width
	cylinder.height = line_length
	cylinder.radial_segments = 8
	cylinder.rings = 1
	
	ghost.mesh = cylinder
	
	# Create transparent material
	var ghost_material = StandardMaterial3D.new()
	ghost_material.albedo_color = ghost_color
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_material.emission_enabled = true
	ghost_material.emission = ghost_color
	ghost_material.emission_energy_multiplier = 0.3
	ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from both sides
	
	ghost.material_override = ghost_material
	
	# Position at center
	ghost.position = line_center
	
	# Rotate to align with line direction
	var up = Vector3.UP
	var direction = line_vector.normalized()
	
	# Avoid gimbal lock when line is vertical
	if abs(direction.dot(up)) > 0.999:
		up = Vector3.FORWARD
	
	ghost.transform.basis = Basis.looking_at(direction, up) * Basis(Vector3(1, 0, 0), PI/2)
	
	return ghost

func _create_success_label() -> void:
	"""Create the success message label"""
	success_label = Label3D.new()
	success_label.name = "SuccessLabel"
	success_label.text = success_message
	success_label.font_size = 36
	success_label.outline_size = 10
	success_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	success_label.modulate = Color(0.2, 1.0, 0.3, 1.0)  # Bright green
	success_label.visible = false
	add_child(success_label)

func _on_endpoints_changed(_start_pos: Vector3, _end_pos: Vector3, line: SnapLineSegment) -> void:
	"""Called when any line's endpoints move"""
	if is_completed or not auto_validate:
		return
	
	# Check if this line is now at its target
	if line.is_at_target():
		_validate_puzzle()

func _on_line_snapped(line: SnapLineSegment) -> void:
	"""Called when a line snaps to its target"""
	print("LineSnapPuzzleBase: Line snapped to target")
	line_snapped_to_target.emit(line)
	
	if auto_validate:
		_validate_puzzle()

func _on_line_locked(_line: SnapLineSegment) -> void:
	"""Called when a line is locked"""
	pass

func _validate_puzzle() -> void:
	"""Check if all lines are at their targets"""
	if is_completed:
		return
	
	var all_at_target = true
	for line in snap_lines:
		if not line.is_at_target():
			all_at_target = false
			break
	
	if all_at_target:
		_complete_puzzle()

func _complete_puzzle() -> void:
	"""Puzzle solved - lock lines and show success"""
	if is_completed:
		return
	
	is_completed = true
	
	print("LineSnapPuzzleBase: Puzzle completed!")
	
	# Play completion sound
	_play_completion_sound()
	
	# Wait for 1 second before visual cleanup/action
	await get_tree().create_timer(1.0).timeout
	
	# First, snap ALL lines to exact target positions and hide ALL endpoint spheres
	for line in snap_lines:
		if line.has_method("_hide_endpoint_spheres"):
			# Snap endpoints to exact positions
			if line.endpoint_a and line.has_targets:
				line.endpoint_a.global_position = line.target_start_global
			if line.endpoint_b and line.has_targets:
				line.endpoint_b.global_position = line.target_end_global
			
			# Update line geometry
			line._update_line_geometry()
			
			# Hide endpoint spheres and target markers
			line._hide_endpoint_spheres()
			
			print("  Cleaned up line: ", line.name)
	
	# Lock all lines
	if lock_on_complete:
		for line in snap_lines:
			line.lock_line()
	
	# Hide ghost guides
	if ghost_guides_container:
		ghost_guides_container.visible = false
	
	# Trigger tag-based action if configured
	if trigger_tag != "":
		# Default to shrink_and_remove if action is not specified or set to remove
		var action = trigger_action
		if action == "" or action == "remove":
			action = "shrink_and_remove"
			
		print("LineSnapPuzzleBase: Triggering tag action: %s -> %s" % [trigger_tag, action])
		TagSystem.trigger_tag_action(trigger_tag, action)
	
	# Show success message
	if success_label:
		success_label.visible = true
		success_label.global_position = global_position + Vector3(0, 0.5, 0)
		
		# Auto-hide after duration
		await get_tree().create_timer(success_display_duration).timeout
		if success_label:
			success_label.visible = false
	
	# Update instruction label
	if instruction_label:
		instruction_label.text = success_message
		instruction_label.modulate = Color(0.2, 1.0, 0.3, 1.0)
	
	# Emit signals
	all_lines_aligned.emit()
	puzzle_completed.emit()

func _play_completion_sound() -> void:
	"""Play a happy sound when puzzle is completed"""
	if not has_node("/root/SoundBank"):
		print("LineSnapPuzzleBase: SoundBank not found, skipping completion sound")
		return
	
	var sound_bank = get_node("/root/SoundBank")
	var sound_stream = sound_bank.get_sound("AudioSynthesizer.POWER_UP_JINGLE")
	
	if not sound_stream:
		print("LineSnapPuzzleBase: Could not get completion sound")
		return
	
	var player = AudioStreamPlayer3D.new()
	player.name = "CompletionSoundPlayer"
	player.stream = sound_stream
	player.volume_db = 0.0
	player.max_distance = 20.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	player.global_position = global_position
	add_child(player)
	
	player.finished.connect(player.queue_free)
	player.play()
	print("LineSnapPuzzleBase: Playing completion sound")

func get_completion_percentage() -> float:
	"""Return percentage of lines at their targets (0.0 to 1.0)"""
	if snap_lines.is_empty():
		return 0.0
	
	var lines_at_target = 0
	for line in snap_lines:
		if line.is_at_target():
			lines_at_target += 1
	
	return float(lines_at_target) / float(snap_lines.size())

func reset_puzzle() -> void:
	"""Reset the puzzle to initial state"""
	is_completed = false
	
	# Unlock all lines
	for line in snap_lines:
		line.unlock_line()
	
	# Reset positions
	for i in range(snap_lines.size()):
		if i < line_definitions.size():
			var definition = line_definitions[i]
			var line = snap_lines[i]
			
			if line.endpoint_a and line.endpoint_b:
				line.endpoint_a.global_position = global_position + definition["start_pos"]
				line.endpoint_b.global_position = global_position + definition["end_pos"]
				line._update_line_geometry()
	
	# Show ghost guides
	if ghost_guides_container:
		ghost_guides_container.visible = show_ghost_guides
	
	# Hide success label
	if success_label:
		success_label.visible = false
	
	# Reset instruction label
	if instruction_label:
		instruction_label.modulate = Color(1, 1, 1, 1)
	
	print("LineSnapPuzzleBase: Puzzle reset")

func _find_grid_scene() -> Node:
	"""Find the GridScene node to spawn objects in"""
	# Search up the parent chain
	var current = self
	while current:
		if current.name == "GridScene":
			return current
		current = current.get_parent()
	
	# Search the entire scene tree
	var root = get_tree().current_scene
	if not root:
		root = get_tree().root
	
	return _find_grid_scene_recursive(root)

func _find_grid_scene_recursive(node: Node) -> Node:
	"""Recursively search for GridScene node"""
	if node.name == "GridScene":
		return node
	for child in node.get_children():
		var result = _find_grid_scene_recursive(child)
		if result:
			return result
	return null

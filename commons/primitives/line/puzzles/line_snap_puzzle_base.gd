extends Node3D
class_name LineSnapPuzzleBase

## LineSnapPuzzleBase - Simplified base class for interactive line snap puzzles
## Any endpoint can snap to any target point from a shared pool

## Puzzle Configuration
@export_group("Puzzle Configuration")
@export var auto_validate: bool = true  # Check on every snap
@export var show_target_markers: bool = true  # Show visual markers at targets
@export var target_marker_color: Color = Color(1, 1, 0, 0.8)  # Yellow markers

@export_group("Success Feedback")
@export var success_message: String = "Puzzle Complete!"
@export var lock_on_complete: bool = true
@export var show_success_label: bool = true
@export var success_display_duration: float = 3.0

@export_group("Tag System")
@export var trigger_tag: String = ""  # Tag to trigger on puzzle completion
@export var trigger_action: String = ""  # Action to execute (reveal, remove, hide, etc.)

@export_group("Form Validation")
@export var use_form_constraints: bool = true  # Use relationship-based validation
@export var require_all_at_targets: bool = true  # Also require endpoints at targets (hybrid mode)

## Internal state - SIMPLIFIED: any endpoint can snap to any target
var target_positions: Array[Vector3] = []  # All target points (local coordinates)
var line_start_positions: Array[Array] = []  # [[start_a, end_a], [start_b, end_b], ...] for each line
var form_constraints: Array[FormConstraint] = []  # Geometric relationship constraints
var snap_lines: Array[SnapLineSegment] = []
var target_markers: Array[Node3D] = []  # Visual markers at target positions
var instruction_label: Label3D
var success_label: Label3D
var is_completed: bool = false

## Signals
signal puzzle_completed()
signal line_snapped_to_target(line: SnapLineSegment)
signal all_lines_aligned()

func _ready() -> void:
	# Child class should have populated target_positions and line_start_positions
	if target_positions.is_empty():
		push_error("LineSnapPuzzleBase: target_positions not set by child class!")
		return

	if line_start_positions.is_empty():
		push_error("LineSnapPuzzleBase: line_start_positions not set by child class!")
		return

	# Wait for transform to be fully applied
	await get_tree().process_frame

	print("LineSnapPuzzleBase: Setting up puzzle with %d targets and %d lines" % [target_positions.size(), line_start_positions.size()])

	# Create target markers
	if show_target_markers:
		call_deferred("_setup_target_markers")

	# Create the snap lines
	call_deferred("_setup_lines")

	# Find instruction label
	instruction_label = get_node_or_null("InstructionLabel")

	# Create success label
	if show_success_label:
		_create_success_label()

func _setup_target_markers() -> void:
	"""Create visual markers at all target positions"""
	print("LineSnapPuzzleBase: Creating %d target markers..." % target_positions.size())

	for i in range(target_positions.size()):
		var local_pos = target_positions[i]
		var marker = _create_target_marker(i)
		add_child(marker)
		marker.global_position = global_transform * local_pos
		target_markers.append(marker)
		print("  Target %d at %s (global: %s)" % [i, local_pos, marker.global_position])

func _create_target_marker(index: int) -> Node3D:
	"""Create a visual sphere marker at a target position"""
	var marker = Node3D.new()
	marker.name = "TargetMarker%d" % index

	# Create sphere
	var sphere_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	sphere.radial_segments = 12
	sphere.rings = 6
	sphere_mesh.mesh = sphere

	# Create emissive material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = target_marker_color
	mat.emission_enabled = true
	mat.emission = target_marker_color
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mesh.material_override = mat

	marker.add_child(sphere_mesh)
	return marker

func _setup_lines() -> void:
	"""Create SnapLineSegment instances"""
	print("LineSnapPuzzleBase: Setting up %d lines..." % line_start_positions.size())

	# Convert all targets to global coordinates
	var global_targets: Array[Vector3] = []
	for local_pos in target_positions:
		global_targets.append(global_transform * local_pos)

	# Load the snap line segment scene
	var snap_line_scene = load("res://commons/primitives/line/snap_line_segment.tscn")
	if not snap_line_scene:
		push_error("LineSnapPuzzleBase: Could not load snap_line_segment.tscn")
		return

	for i in range(line_start_positions.size()):
		var positions = line_start_positions[i]
		var start_pos: Vector3 = positions[0]
		var end_pos: Vector3 = positions[1]

		print("  Line %d: start=%s, end=%s" % [i + 1, start_pos, end_pos])

		# Create line instance
		var snap_line = snap_line_scene.instantiate()
		snap_line.name = "SnapLine%d" % (i + 1)
		add_child(snap_line)

		# Wait a frame for initialization
		await get_tree().process_frame

		# Set initial endpoint positions
		if snap_line.endpoint_a and snap_line.endpoint_b:
			snap_line.endpoint_a.global_position = global_transform * start_pos
			snap_line.endpoint_b.global_position = global_transform * end_pos

			# Pass the shared target pool to this line
			snap_line.set_shared_targets(global_targets)

			# Connect signals
			snap_line.endpoints_changed.connect(_on_endpoints_changed.bind(snap_line))
			snap_line.snapped_to_target.connect(_on_line_snapped.bind(snap_line))
			snap_line.line_locked.connect(_on_line_locked.bind(snap_line))

			# Update line geometry
			snap_line._update_line_geometry()

			snap_lines.append(snap_line)
			print("  ✓ Line %d created" % (i + 1))
		else:
			push_error("  ✗ Line %d missing endpoints!" % (i + 1))

	print("LineSnapPuzzleBase: All %d lines set up" % snap_lines.size())

func _create_success_label() -> void:
	"""Create the success message label"""
	success_label = Label3D.new()
	success_label.name = "SuccessLabel"
	success_label.text = success_message
	success_label.font_size = 64
	success_label.outline_size = 16
	success_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	success_label.modulate = Color(0.2, 1.0, 0.3, 1.0)
	success_label.outline_modulate = Color(0.0, 0.3, 0.0, 1.0)
	success_label.visible = false
	add_child(success_label)

func _on_endpoints_changed(_start_pos: Vector3, _end_pos: Vector3, line: SnapLineSegment) -> void:
	"""Called when any line's endpoints move"""
	if is_completed or not auto_validate:
		return

	if line.is_at_target():
		_validate_puzzle()

func _on_line_snapped(line: SnapLineSegment) -> void:
	"""Called when a line snaps to a target"""
	print("LineSnapPuzzleBase: Line snapped")
	line_snapped_to_target.emit(line)

	# Hide target markers that have been snapped to
	_update_target_marker_visibility()

	if auto_validate:
		_validate_puzzle()

func _on_line_locked(_line: SnapLineSegment) -> void:
	"""Called when a line is locked"""
	pass

func _update_target_marker_visibility() -> void:
	"""Hide target markers that have endpoints snapped to them"""
	# Collect all snapped target positions
	var snapped_positions: Array[Vector3] = []
	for line in snap_lines:
		snapped_positions.append_array(line.get_snapped_targets())

	# Update marker visibility
	for i in range(target_markers.size()):
		var marker = target_markers[i]
		var marker_pos = marker.global_position
		var is_snapped = false

		for snapped_pos in snapped_positions:
			if marker_pos.distance_to(snapped_pos) < 0.05:
				is_snapped = true
				break

		marker.visible = not is_snapped

func _validate_puzzle() -> void:
	"""Check if puzzle is complete using form constraints and/or position checking"""
	if is_completed:
		return

	# Check position requirements (hybrid mode or position-only mode)
	if require_all_at_targets:
		var all_at_targets = true
		for i in range(snap_lines.size()):
			var line = snap_lines[i]
			if not line.is_at_target():
				print("  Line %d not at target yet" % i)
				all_at_targets = false
		if not all_at_targets:
			return  # Not all lines at targets yet
		print("LineSnapPuzzleBase: All lines at targets, checking constraints...")

	# Check form constraints (relationship-based validation)
	if use_form_constraints and not form_constraints.is_empty():
		var line_data = _get_line_endpoint_data()
		for constraint in form_constraints:
			var valid = constraint.validate(line_data)
			print("  Constraint '%s': %s" % [constraint.description, "PASS" if valid else "FAIL"])
			if not valid:
				return  # Constraint not satisfied

	# All validations passed
	print("LineSnapPuzzleBase: All validations passed!")
	_complete_puzzle()


## Get current line endpoint positions for constraint validation
func _get_line_endpoint_data() -> Array:
	var line_data: Array = []
	for line in snap_lines:
		if line.endpoint_a and line.endpoint_b:
			line_data.append({
				"start": line.endpoint_a.global_position,
				"end": line.endpoint_b.global_position
			})
	return line_data

func _complete_puzzle() -> void:
	"""Puzzle solved - lock lines and show success"""
	if is_completed:
		return

	is_completed = true
	print("LineSnapPuzzleBase: Puzzle completed!")

	# Show success message IMMEDIATELY
	if success_label:
		success_label.visible = true
		success_label.global_position = global_position + Vector3(0, 0.5, 0)

	# Update instruction label immediately
	if instruction_label:
		instruction_label.text = success_message
		instruction_label.modulate = Color(0.2, 1.0, 0.3, 1.0)

	# Play completion sound
	_play_completion_sound()

	# Emit signals immediately
	all_lines_aligned.emit()
	puzzle_completed.emit()

	# Wait before cleanup
	await get_tree().create_timer(1.0).timeout

	# Hide all endpoint spheres
	for line in snap_lines:
		if line.has_method("_hide_endpoint_spheres"):
			line._update_line_geometry()
			line._hide_endpoint_spheres()

	# Lock all lines
	if lock_on_complete:
		for line in snap_lines:
			line.lock_line()

	# Hide all target markers
	for marker in target_markers:
		marker.visible = false

	# Trigger tag-based action if configured
	if trigger_tag != "":
		var action = trigger_action
		if action == "" or action == "remove":
			action = "shrink_and_remove"
		print("LineSnapPuzzleBase: Triggering tag action: %s -> %s" % [trigger_tag, action])
		TagSystem.trigger_tag_action(trigger_tag, action)

	# Hide success message after display duration
	await get_tree().create_timer(success_display_duration).timeout
	if success_label:
		success_label.visible = false

func _play_completion_sound() -> void:
	"""Play a happy sound when puzzle is completed (max 3 seconds)"""
	if not has_node("/root/SoundBank"):
		return

	var sound_bank = get_node("/root/SoundBank")
	var sound_stream = sound_bank.get_sound("AudioSynthesizer.POWER_UP_JINGLE")

	if not sound_stream:
		return

	var player = AudioStreamPlayer3D.new()
	player.name = "CompletionSoundPlayer"
	player.stream = sound_stream
	player.volume_db = 0.0
	player.max_distance = 20.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	add_child(player)
	player.global_position = global_position

	player.finished.connect(player.queue_free)
	player.play()

	# Stop sound after 3 seconds max
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	)

func get_completion_percentage() -> float:
	"""Return percentage of lines complete (0.0 to 1.0)"""
	if snap_lines.is_empty():
		return 0.0

	var lines_complete = 0
	for line in snap_lines:
		if line.is_at_target():
			lines_complete += 1

	return float(lines_complete) / float(snap_lines.size())

func reset_puzzle() -> void:
	"""Reset the puzzle to initial state"""
	is_completed = false

	# Unlock and reset all lines
	for i in range(snap_lines.size()):
		var line = snap_lines[i]
		line.unlock_line()
		line.reset_snapped_targets()

		if i < line_start_positions.size():
			var positions = line_start_positions[i]
			if line.endpoint_a and line.endpoint_b:
				line.endpoint_a.global_position = global_transform * positions[0]
				line.endpoint_b.global_position = global_transform * positions[1]
				line.endpoint_a.visible = true
				line.endpoint_b.visible = true
				line._update_line_geometry()

	# Show all target markers
	for marker in target_markers:
		marker.visible = true

	# Hide success label
	if success_label:
		success_label.visible = false

	# Reset instruction label
	if instruction_label:
		instruction_label.modulate = Color(1, 1, 1, 1)

	print("LineSnapPuzzleBase: Puzzle reset")

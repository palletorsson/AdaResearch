extends Node3D
class_name LineSnapPuzzleBase

## LineSnapPuzzleBase - Half-Life: Alyx style holographic puzzles
## Clean, minimal UI with glowing elements

## Puzzle Configuration
@export_group("Puzzle Configuration")
@export var auto_validate: bool = true
@export var show_target_markers: bool = true

## Alyx-style colors
@export_group("Visual Style")
@export var marker_color: Color = Color(0.0, 0.8, 1.0, 0.6)  # Cyan hologram
@export var marker_active_color: Color = Color(0.0, 1.0, 0.8, 0.9)  # Bright when active
@export var completion_color: Color = Color(0.2, 1.0, 0.6, 1.0)  # Green pulse on complete
@export var line_color: Color = Color(0.1, 0.7, 0.9, 0.9)  # Cyan line
@export var line_locked_color: Color = Color(0.3, 1.0, 0.7, 1.0)  # Green locked

@export_group("Completion")
@export var lock_on_complete: bool = true
@export var completion_pulse_duration: float = 0.5

@export_group("Tag System")
@export var trigger_tag: String = ""
@export var trigger_action: String = ""

@export_group("Form Validation")
@export var use_form_constraints: bool = true
@export var require_all_at_targets: bool = true

## Internal state
var target_positions: Array[Vector3] = []
var line_start_positions: Array[Array] = []
var form_constraints: Array[FormConstraint] = []
var snap_lines: Array[SnapLineSegment] = []
var target_markers: Array[Node3D] = []
var is_completed: bool = false
var success_message: String = ""  # Kept for compatibility but not displayed

## Signals
signal puzzle_completed()
signal line_snapped_to_target(line: SnapLineSegment)
signal all_lines_aligned()

func _ready() -> void:
	if target_positions.is_empty():
		push_error("LineSnapPuzzleBase: target_positions not set!")
		return
	if line_start_positions.is_empty():
		push_error("LineSnapPuzzleBase: line_start_positions not set!")
		return

	await get_tree().process_frame

	if show_target_markers:
		call_deferred("_setup_target_markers")
	call_deferred("_setup_lines")

func _setup_target_markers() -> void:
	"""Create Alyx-style holographic markers"""
	for i in range(target_positions.size()):
		var local_pos = target_positions[i]
		var marker = _create_alyx_marker(i)
		add_child(marker)
		marker.global_position = global_transform * local_pos
		target_markers.append(marker)

func _create_alyx_marker(_index: int) -> Node3D:
	"""Create a sleek holographic target marker"""
	var marker = Node3D.new()
	marker.name = "TargetMarker"
	
	# Outer ring (torus)
	var ring_mesh = MeshInstance3D.new()
	ring_mesh.name = "Ring"
	var torus = TorusMesh.new()
	torus.inner_radius = 0.018
	torus.outer_radius = 0.025
	torus.rings = 24
	torus.ring_segments = 12
	ring_mesh.mesh = torus
	ring_mesh.rotation.x = PI / 2  # Lay flat
	
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = marker_color
	ring_mat.emission_enabled = true
	ring_mat.emission = marker_color
	ring_mat.emission_energy_multiplier = 1.5
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mesh.material_override = ring_mat
	marker.add_child(ring_mesh)
	
	# Inner dot
	var dot_mesh = MeshInstance3D.new()
	dot_mesh.name = "Dot"
	var sphere = SphereMesh.new()
	sphere.radius = 0.008
	sphere.height = 0.016
	sphere.radial_segments = 16
	sphere.rings = 8
	dot_mesh.mesh = sphere
	
	var dot_mat = StandardMaterial3D.new()
	dot_mat.albedo_color = marker_active_color
	dot_mat.emission_enabled = true
	dot_mat.emission = marker_active_color
	dot_mat.emission_energy_multiplier = 2.0
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_mesh.material_override = dot_mat
	marker.add_child(dot_mesh)
	
	# Add subtle animation
	var anim_script = GDScript.new()
	anim_script.source_code = """
extends Node3D
var time: float = 0.0
var base_scale: float = 1.0
func _process(delta):
	time += delta
	var pulse = 1.0 + sin(time * 3.0) * 0.1
	scale = Vector3.ONE * base_scale * pulse
	$Ring.rotation.y += delta * 0.5
"""
	marker.set_script(anim_script)
	
	return marker

func _setup_lines() -> void:
	"""Create snap lines with Alyx styling"""
	var global_targets: Array[Vector3] = []
	for local_pos in target_positions:
		global_targets.append(global_transform * local_pos)

	var snap_line_scene = load("res://commons/primitives/line/snap_line_segment.tscn")
	if not snap_line_scene:
		push_error("LineSnapPuzzleBase: Could not load snap_line_segment.tscn")
		return

	for i in range(line_start_positions.size()):
		var positions = line_start_positions[i]
		var start_pos: Vector3 = positions[0]
		var end_pos: Vector3 = positions[1]

		var snap_line = snap_line_scene.instantiate()
		snap_line.name = "SnapLine%d" % (i + 1)
		
		# Apply Alyx colors
		snap_line.line_color = line_color
		snap_line.locked_color = line_locked_color
		
		add_child(snap_line)
		await get_tree().process_frame

		if snap_line.endpoint_a and snap_line.endpoint_b:
			snap_line.endpoint_a.global_position = global_transform * start_pos
			snap_line.endpoint_b.global_position = global_transform * end_pos
			snap_line.set_shared_targets(global_targets)
			
			snap_line.endpoints_changed.connect(_on_endpoints_changed.bind(snap_line))
			snap_line.snapped_to_target.connect(_on_line_snapped.bind(snap_line))
			snap_line.line_locked.connect(_on_line_locked.bind(snap_line))
			snap_line._update_line_geometry()
			
			snap_lines.append(snap_line)

func _on_endpoints_changed(_start_pos: Vector3, _end_pos: Vector3, line: SnapLineSegment) -> void:
	if is_completed or not auto_validate:
		return
	if line.is_at_target():
		_validate_puzzle()

func _on_line_snapped(line: SnapLineSegment) -> void:
	line_snapped_to_target.emit(line)
	_update_target_marker_visibility()
	if auto_validate:
		_validate_puzzle()

func _on_line_locked(_line: SnapLineSegment) -> void:
	pass

func _update_target_marker_visibility() -> void:
	"""Fade out markers when snapped"""
	var snapped_positions: Array[Vector3] = []
	for line in snap_lines:
		snapped_positions.append_array(line.get_snapped_targets())

	for i in range(target_markers.size()):
		var marker = target_markers[i]
		var marker_pos = marker.global_position
		var is_snapped = false

		for snapped_pos in snapped_positions:
			if marker_pos.distance_to(snapped_pos) < 0.05:
				is_snapped = true
				break

		# Fade instead of hide
		if is_snapped:
			_fade_marker(marker, 0.0, 0.2)
		else:
			marker.visible = true

func _fade_marker(marker: Node3D, target_alpha: float, duration: float) -> void:
	"""Smoothly fade a marker"""
	var tween = create_tween()
	tween.tween_property(marker, "scale", Vector3.ONE * target_alpha, duration)
	tween.tween_callback(func(): marker.visible = target_alpha > 0.1)

func _validate_puzzle() -> void:
	if is_completed:
		return

	if require_all_at_targets:
		for line in snap_lines:
			if not line.is_at_target():
				return

	if use_form_constraints and not form_constraints.is_empty():
		var line_data = _get_line_endpoint_data()
		for constraint in form_constraints:
			if not constraint.validate(line_data):
				return

	_complete_puzzle()

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
	"""Puzzle solved - clean Alyx-style completion (no text)"""
	if is_completed:
		return

	is_completed = true
	
	# Play completion pulse on all lines
	_play_completion_pulse()
	
	# Play subtle sound
	_play_completion_sound()
	
	# Emit signals
	all_lines_aligned.emit()
	puzzle_completed.emit()

	await get_tree().create_timer(completion_pulse_duration).timeout

	# Hide endpoint spheres smoothly
	for line in snap_lines:
		if line.has_method("_hide_endpoint_spheres"):
			line._update_line_geometry()
			line._hide_endpoint_spheres()

	# Lock lines
	if lock_on_complete:
		for line in snap_lines:
			line.lock_line()

	# Fade out remaining markers
	for marker in target_markers:
		_fade_marker(marker, 0.0, 0.3)

	# Trigger tag action
	if trigger_tag != "":
		var action = trigger_action if trigger_action != "" else "shrink_and_remove"
		TagSystem.trigger_tag_action(trigger_tag, action)

func _play_completion_pulse() -> void:
	"""Flash all lines with completion color"""
	for line in snap_lines:
		if line.material:
			var original_emission = line.material.emission_energy_multiplier
			var tween = create_tween()
			tween.tween_property(line.material, "emission", completion_color, 0.1)
			tween.tween_property(line.material, "emission_energy_multiplier", 3.0, 0.1)
			tween.tween_property(line.material, "emission_energy_multiplier", original_emission, 0.3)

func _play_completion_sound() -> void:
	"""Play subtle confirmation sound"""
	if not has_node("/root/SoundBank"):
		return

	var sound_bank = get_node("/root/SoundBank")
	var sound_stream = sound_bank.get_sound("AudioSynthesizer.POWER_UP_JINGLE")
	if not sound_stream:
		return

	var player = AudioStreamPlayer3D.new()
	player.stream = sound_stream
	player.volume_db = -6.0  # Quieter
	player.max_distance = 15.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	add_child(player)
	player.global_position = global_position
	player.finished.connect(player.queue_free)
	player.play()

	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	)

func get_completion_percentage() -> float:
	if snap_lines.is_empty():
		return 0.0
	var complete = 0
	for line in snap_lines:
		if line.is_at_target():
			complete += 1
	return float(complete) / float(snap_lines.size())

func reset_puzzle() -> void:
	is_completed = false

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

	for marker in target_markers:
		marker.visible = true
		marker.scale = Vector3.ONE

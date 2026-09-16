extends "res://commons/primitives/line/puzzles/plus_line_puzzle.gd"
## The paired encounter keeps testing after success. Other PlusLinePuzzle
## placements retain their completion animation, hidden handles and locking.

signal verdict_changed(accepted: bool)

var ready_for_comparison := false

func _ready() -> void:
	lock_on_complete = false
	super._ready()

func _apply_dna() -> void:
	super._apply_dna()
	# Both bays offer the same visible references and snapping assistance.
	# Only A includes those positions in its acceptance test.
	show_target_markers = true

func _setup_lines() -> void:
	await super._setup_lines()
	for line in snap_lines:
		for endpoint in [line.endpoint_a, line.endpoint_b]:
			if endpoint is RigidBody3D:
				endpoint.freeze = true
			endpoint.dropped.connect(_hold_released_endpoint.bind(endpoint))
	_reseat()
	assess()

func _hold_released_endpoint(_pickable: Node3D, endpoint: Node3D) -> void:
	# The ordinary snap line only freezes an endpoint dropped at a target.
	# Here a relation away from the targets must also remain where it was put.
	if endpoint is RigidBody3D:
		endpoint.freeze = true
	assess()

func _process(_delta: float) -> void:
	if not ready_for_comparison and snap_lines.size() == 2:
		ready_for_comparison = true
		assess()

func _on_endpoints_changed(_a: Vector3, _b: Vector3, _line: SnapLineSegment) -> void:
	assess()

func _on_line_snapped(line: SnapLineSegment) -> void:
	line_snapped_to_target.emit(line)
	assess()

func _validate_puzzle() -> void:
	assess()

func assess() -> bool:
	if snap_lines.size() != 2:
		return false
	var data := _get_line_endpoint_data()
	var accepted := data.size() == 2
	for segment in data:
		# A zero direction cannot supply an angle or a cross.
		if segment.start.distance_squared_to(segment.end) < 0.000001:
			accepted = false
	if require_all_at_targets:
		for line in snap_lines:
			accepted = accepted and line.is_at_target()
	for constraint in form_constraints:
		accepted = accepted and constraint.validate(data)
	if is_completed != accepted:
		is_completed = accepted
		for line in snap_lines:
			if line.material:
				line.material.albedo_color = completion_color if accepted else line_color
				line.material.emission = completion_color if accepted else line_color
		verdict_changed.emit(accepted)
	return accepted

func translate_relation(local_delta: Vector3) -> void:
	if not ready_for_comparison:
		return
	var world_delta := global_basis * local_delta
	for line in snap_lines:
		line.reset_snapped_targets()
		line.endpoint_a.freeze = true
		line.endpoint_b.freeze = true
		line.endpoint_a.global_position += world_delta
		line.endpoint_b.global_position += world_delta
		line._update_line_geometry()
	assess()

func reset_puzzle() -> void:
	var previous := is_completed
	super.reset_puzzle()
	for line in snap_lines:
		line.endpoint_a.freeze = true
		line.endpoint_b.freeze = true
	is_completed = previous
	assess()
	# Reset must clear a previously accepted readout even when the new stock
	# has the same false verdict as the base's reset state.
	verdict_changed.emit(is_completed)

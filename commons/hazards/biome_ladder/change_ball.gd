extends "res://commons/hazards/biome_ladder/ladder_ball.gd"
## Prescribed motion: sample the field, announce one sampled target, commit to a line.
## No accumulated velocity, force or homing. Those are different later operations.
enum Flight { FIELD, WARNING, COMMITTED }
const FIELD_SECONDS := 1.4
const WARNING_SECONDS := 0.9
var flight := Flight.FIELD
var phase_seconds := 0.0
var field_sampler: Callable
var target_sampler: Callable
var sampled_target := Vector3.ZERO
var target_sample_count := 0
var turn_count := 0
var turn_line: MeshInstance3D
signal turn_announced()
signal turn_committed()

func _advance_motion(delta: float) -> void:
	if spent: return
	lifetime -= delta
	if lifetime <= 0: queue_free(); return
	var remaining := delta
	while remaining > 0.000001 and not spent:
		if flight == Flight.FIELD:
			# Bounded spatial sampling also handles a slow frame without jumping cells.
			var step := minf(remaining, minf(0.025, FIELD_SECONDS - phase_seconds))
			direction = field_sampler.call(global_position) if field_sampler.is_valid() else Vector3.BACK
			_sweep(direction.normalized() * speed * step)
			phase_seconds += step; remaining -= step
			if not spent and phase_seconds >= FIELD_SECONDS - 0.000001: _announce_turn()
		elif flight == Flight.WARNING:
			var step := minf(remaining, WARNING_SECONDS - phase_seconds)
			phase_seconds += step; remaining -= step
			if phase_seconds >= WARNING_SECONDS - 0.000001:
				direction = global_position.direction_to(sampled_target)
				if direction.is_zero_approx(): direction = Vector3.BACK
				flight = Flight.COMMITTED; turn_count += 1
				if is_instance_valid(turn_line): turn_line.queue_free()
				get_child(1).material_override.albedo_color = tint
				get_child(2).material_override.set_shader_parameter("strength", 0.8)
				turn_committed.emit()
		else:
			_sweep(direction * speed * remaining); remaining = 0

func _announce_turn() -> void:
	flight = Flight.WARNING; phase_seconds = 0
	sampled_target = target_sampler.call() if target_sampler.is_valid() else global_position + direction * 4.0
	target_sample_count += 1
	turn_line = ArrayPath.drawing(PackedVector3Array([global_position, sampled_target]))
	add_child(turn_line); turn_line.global_transform = Transform3D.IDENTITY
	get_child(1).material_override.albedo_color = Color.WHITE
	get_child(2).material_override.set_shader_parameter("strength", 1.7)
	turn_announced.emit()

func _sweep(displacement: Vector3) -> void:
	var collision := move_and_collide(displacement)
	if collision == null: return
	spent = true
	var body: Node = collision.get_collider()
	if body is Node3D: surface_hit.emit(body, collision.get_position())
	if body != null and (body.is_in_group("player_body") or body.is_in_group("player")):
		player_hit.emit(body)
	queue_free()

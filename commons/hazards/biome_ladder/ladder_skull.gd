extends "res://commons/hazards/catalyst_counterpart/flying_skull.gd"
## Same sculpted skull; the ladder adds only the preceding chapter's operations.
const LadderBall := preload("res://commons/hazards/biome_ladder/ladder_ball.gd")
const ChangeBall := preload("res://commons/hazards/biome_ladder/change_ball.gd")
const ArrayPath := preload("res://commons/hazards/biome_ladder/array_path.gd")
var stage := 0
var slot := 0
var fallen := false
var fall_speed := 0.0
var array_controlled := false
var pending_path := PackedVector3Array()
var path_preview: MeshInstance3D
signal ball_sent(ball: Node3D)

func _ready() -> void:
	combat_enabled = true
	super()
	flame.emitting = false
	# Heads remain monochrome, including in the colour chapter.
	for child in visual.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var c: Color = child.material_override.albedo_color
			var v := (c.r + c.g + c.b) / 3.0
			child.material_override.albedo_color = Color(v, v, v)
	visual.rotation.y = PI

func set_active(value: bool) -> void:
	super(value)
	_clear_path_preview()
	if value: elapsed = -float(slot) * 1.4

func advance(delta: float, target: Vector3) -> void:
	if destroyed:
		if not fallen:
			fall_speed += 5.0 * delta
			var contact := move_and_collide(Vector3.DOWN * fall_speed * delta)
			visual.rotation.z = move_toward(visual.rotation.z, PI * 0.5, delta * 2.4)
			if contact != null or position.y <= RADIUS:
				position.y = maxf(position.y, RADIUS); fallen = true
		return
	if not active: return
	phase += delta; elapsed += delta
	if stage >= 1 and not (array_controlled and state == State.TELEGRAPH):
		var sway := 0.16 if array_controlled else 0.8
		position = home_position + Vector3(sin(phase * 0.55 + slot) * sway, sin(phase * 0.8) * 0.16, 0)
		visual.rotation.y = PI + sin(phase * 0.65) * 0.45
	eye_material.albedo_color = Color.WHITE if state == State.TELEGRAPH else Color(0.2, 0.2, 0.2)
	if not array_controlled and state == State.RECOVER and elapsed >= 3.5:
		begin_telegraph((get_parent() as Node3D).to_local(target))
	elif state == State.TELEGRAPH and elapsed >= WINDUP:
		throw_ball(); state = State.RECOVER; elapsed = 0; cue.hide()

func begin_telegraph(local_target: Vector3) -> void:
	super(local_target)
	if not array_controlled: return
	_clear_path_preview()
	var target := (get_parent() as Node3D).to_global(destination)
	var start := global_position + global_position.direction_to(target) * 0.42
	pending_path = ArrayPath.positions(start, target, 1.0 if slot % 2 == 0 else -1.0)
	pending_path = ArrayPath.ending_on_floor(pending_path, get_parent().global_transform)
	if uses_field():
		start = global_position + Vector3.BACK * 0.42
		pending_path = get_parent().direction_field.preview(start, ChangeBall.FIELD_SECONDS, 1.8)
	path_preview = ArrayPath.drawing(pending_path)
	add_child(path_preview); path_preview.global_transform = Transform3D.IDENTITY
	cue.hide() # Display the actual ordered path instead of a straight warning.

func _clear_path_preview() -> void:
	if is_instance_valid(path_preview): path_preview.queue_free()
	path_preview = null

func throw_ball() -> Node3D:
	if not active or destroyed: return null
	var shot: Node3D = ChangeBall.new() if uses_field() else LadderBall.new()
	shot.stage = stage
	shot.arena_frame = get_parent()
	shot.tint = Color.from_hsv(fposmod(slot * 0.27 + phase * 0.025, 1), 0.65, 0.95) if stage >= 3 else Color(0.85, 0.85, 0.85)
	shot.direction = global_position.direction_to((get_parent() as Node3D).to_global(destination))
	shot.position = position + shot.direction * 0.42
	if uses_field():
		shot.position = position + Vector3.BACK * 0.42
		shot.field_sampler = get_parent().direction_field.sample
		shot.target_sampler = target_position
		pending_path.clear(); _clear_path_preview()
	elif array_controlled:
		if pending_path.is_empty():
			var target := (get_parent() as Node3D).to_global(destination)
			pending_path = ArrayPath.positions(global_position + shot.direction * 0.42, target, 1.0 if slot % 2 == 0 else -1.0)
			pending_path = ArrayPath.ending_on_floor(pending_path, get_parent().global_transform)
		shot.waypoints = pending_path.duplicate()
		shot.position = (get_parent() as Node3D).to_local(shot.waypoints[0])
		pending_path.clear(); _clear_path_preview()
	shot.player_hit.connect(func(body): ball_hit_player.emit(body))
	get_parent().add_child(shot)
	ball_sent.emit(shot)
	projectiles = projectiles.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	if projectiles.size() >= 3: projectiles.pop_front().queue_free()
	projectiles.append(shot)
	return shot

func uses_field() -> bool:
	# Keep the outer columns' stored paths; one column demonstrates a new rule.
	return stage >= 5 and slot % 3 == 1

func hit_by_catalyst_mode(_colour: Color, _mode: String) -> void:
	# START/REST control attacks. A visible practice target still receives hits.
	if destroyed: return
	incoming_hits += 1; interruptions += 1
	destroyed = true; active = false; fall_speed = 0; fallen = false
	_clear_path_preview(); pending_path.clear()
	cue.hide(); clear_shots(); collision_layer = 0
	interrupted.emit(); defeated.emit()

func restore() -> void:
	super()
	position = home_position; visual.rotation = Vector3(0, PI, 0)
	fallen = false; fall_speed = 0; phase = 0
	pending_path.clear(); _clear_path_preview()

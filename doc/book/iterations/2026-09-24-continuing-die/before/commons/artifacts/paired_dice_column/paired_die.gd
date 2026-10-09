extends "res://algorithms/randomness/dice_throw/dice_throw.gd"
## The existing pickable die and settle test, in a small tray for a paired trial.
signal lifted
signal released
signal landed(value: int)
signal returned
var _away_seconds := 0.0

func _ready() -> void:
	dice_size = 0.11
	dice_bounce = 0.22
	table_width = 0.82
	table_depth = 0.66
	table_height = 0.90
	balls_per_pip = 0
	_create_table()
	_create_rim()
	_create_dice()
	_dice_spawn_pos = Vector3(0, table_height + dice_size, 0)
	_result_label = Label3D.new()
	_result_label.text = "?"
	_result_label.font_size = 42
	_result_label.pixel_size = 0.0016
	_result_label.modulate = dice_color
	_result_label.position = Vector3(0, 1.09, -0.32)
	add_child(_result_label)
	_stats_label = Label3D.new()
	_stats_label.visible = false
	add_child(_stats_label)

func _process(delta: float) -> void:
	if not is_instance_valid(_dice_body): return
	# Held objects belong to the hand, even when far away from their tray.
	if _dice_body.freeze or (_dice_body.has_method("is_picked_up") and _dice_body.is_picked_up()):
		_away_seconds = 0.0
		return
	var p: Vector3 = to_local(_dice_body.global_position)
	if p.y < 0.18 or p.length() > 3.0:
		_away_seconds += minf(delta, 0.1)
		if _away_seconds > 0.7: return_to_tray()
		return
	_away_seconds = 0.0
	# A die on the floor, a rim, or a neighbour is not a throw into this tray.
	var on_tray := absf(p.x) < table_width * 0.5 - dice_size * 0.48 and absf(p.z) < table_depth * 0.5 - dice_size * 0.48 and p.y > table_height and p.y < table_height + dice_size * 0.9
	if not on_tray:
		_settle_timer = 0.0
		_still_armed = false
		return
	super._process(delta)

func _on_dice_picked_up(pickable) -> void:
	super._on_dice_picked_up(pickable)
	_result_label.text = "?"
	lifted.emit()

func _on_dice_dropped(pickable) -> void:
	super._on_dice_dropped(pickable)
	released.emit()

func _read_dice_result() -> void:
	super._read_dice_result()
	landed.emit(_last_result)

func return_to_tray() -> bool:
	if _dice_body.freeze or (_dice_body.has_method("is_picked_up") and _dice_body.is_picked_up()): return false
	_is_rolling = false
	_settle_timer = 0.0
	_still_armed = false
	_away_seconds = 0.0
	_dice_body.freeze = true
	_dice_body.global_transform = Transform3D(global_basis.orthonormalized(), to_global(_dice_spawn_pos))
	_dice_body.linear_velocity = Vector3.ZERO
	_dice_body.angular_velocity = Vector3.ZERO
	_dice_body.set_deferred("freeze", false)
	_result_label.text = "?"
	returned.emit()
	return true

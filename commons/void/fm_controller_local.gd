extends "res://algorithms/wavefunctions/mariocontrol/DualBallFMController.gd"
## A preset moves frozen physics points. Let their queued pose settle without
## mistaking the physics synchronization for a visitor dragging another note.
var _preset_frames := 0

func set_baseline() -> void:
	super.set_baseline()
	_preset_frames = 3

func _process(delta: float) -> void:
	if _preset_frames > 0:
		_preset_frames -= 1
		if carrier_ball: last_carrier_pos = carrier_ball.global_position
		if modulator_ball: last_mod_pos = modulator_ball.global_position
		return
	super._process(delta)

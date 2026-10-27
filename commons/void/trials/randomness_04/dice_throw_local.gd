extends "res://algorithms/randomness/dice_throw/dice_throw.gd"
## Trial-only adapter (randomness_04, f1_dice_throw_3_2). Table, die, settle test, face
## read, reward rain, warrant and console are the source's own.
##
## One host seam. Measured on debug case `dice` (desktop, 21 Oct): with the die settled
## on the floor after a throw, a real pointer RESET ran (result blanked to "?", rain
## cleared) but the die stayed 1.10 m from its spawn, unfrozen. _reset_dice() freezes the
## die, writes its global_position and unfreezes it with a deferred call. The die is an
## XR Tools pickable, whose scene freezes in KINEMATIC mode (pickable.tscn freeze_mode = 1).
## Static reading: under Jolt a frozen kinematic body takes a written transform as its
## target for the next physics step, and the deferred unfreeze lands before that step, so
## the move is dropped. A STATIC-frozen body moves at once: the galton pool balls are
## respawned exactly this way and were measured at their new position. So the reset
## freezes in static mode for its teleport, then restores the pickable's own mode after
## the deferred unfreeze. Picking the die up still freezes it kinematically, as XR Tools
## expects.
func _reset_dice() -> void:
	if not _dice_body:
		return
	var mode: int = _dice_body.freeze_mode
	_dice_body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	super._reset_dice()
	# Spawn is authored in artifact coordinates, including editor scale and yaw.
	_dice_body.global_position = to_global(_dice_spawn_pos)
	_dice_body.set_deferred("freeze_mode", mode)

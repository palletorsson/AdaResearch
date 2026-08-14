extends "res://commons/scenes/endless_museum.gd"
## The endless museum as a MENU DESTINATION.
##
## Launched from the main-menu sequence picker there are no command-line flags,
## and the generator's default for _plan_path is empty — which means "deal from
## the pool as v1 did", ignoring everything the negotiator ruled. A museum
## reached from the shipped game loop must be the NEGOTIATED museum, so this
## wrapper presets the plan path before _ready's arg parse runs. Flags still
## win when present (the parse only overwrites members whose flags it sees),
## so a desktop `--em-plan=...` run through this scene behaves identically.
##
## Nothing else is overridden: VR detection stays automatic (_is_vr() finds
## the live OpenXR interface that vr_staging initialised before loading us),
## and on a desktop run of the same menu the museum builds its own walker
## exactly as res://commons/scenes/endless_museum.tscn does.

func _init() -> void:
	_plan_path = EM_PLAN

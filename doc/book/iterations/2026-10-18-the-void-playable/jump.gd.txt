extends "res://addons/godot-xr-tools/functions/movement_provider.gd"
## One press, one attempt. Holding A must not jump again on the next landing.
@export var order := 20
var queued := false

func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool) -> void:
	if queued:
		queued = false
		player_body.request_jump()

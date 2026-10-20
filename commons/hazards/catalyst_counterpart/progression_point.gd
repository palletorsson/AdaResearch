extends "res://commons/artifacts/ignorance_gallery/resolution_catalyst.gd"
## One existing PointBody gains permission to simplify, then emit. No duplicate weapon.
var resolution_enabled := false
var emission_enabled := false

func advance(delta: float) -> void:
	if resolution_enabled:
		super(delta)

func _send_form(body: Node) -> void:
	if emission_enabled:
		super(body)

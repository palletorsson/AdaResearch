extends "study.gd"
## The exact printed study with a portable museum control/readout.
var hand_control:Node3D
func _ready()->void:
	super._ready()
	hand_control=preload("pso_hand_control.gd").new()
	hand_control.study=self
	add_child(hand_control)

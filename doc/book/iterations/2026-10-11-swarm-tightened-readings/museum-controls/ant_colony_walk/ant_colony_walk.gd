extends "study.gd"
## Permanent museum instance of the exact printed learner host.
var hand_control:Node3D
func _ready()->void:
	super._ready()
	hand_control=preload("colony_hand_control.gd").new()
	hand_control.study=self
	add_child(hand_control)

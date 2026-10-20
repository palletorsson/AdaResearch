extends "study.gd"
## Exact printed lesson with a portable view of its existing account.
var hand_account:Node3D
func _ready()->void:
	super._ready()
	hand_account=preload("population_hand_account.gd").new()
	hand_account.study=self
	add_child(hand_account)

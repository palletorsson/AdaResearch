extends "res://algorithms/spacetopology/marchingcubes/scenes/RhizomeCaveDemoController.gd"
## The original shell supplies real footing beyond the fixed tower slab.
func _ready() -> void:
	if passage_study or _as_bool(get_meta("config_passage_study",false)):
		add_to_group("void_exterior_walk")
	super._ready()

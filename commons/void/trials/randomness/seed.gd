extends "res://algorithms/randomness/seed_replay/seed_replay_demo.gd"
## Keep the existing seed experiment and its movement sampler in one editable mount.
func _place_editor_parts() -> void:
	if is_instance_valid(_movement_sampler):
		_movement_sampler.set_as_top_level(false)
		_movement_sampler.position = Vector3(-2.3, 0, 1.1)
		_movement_sampler.rotation = Vector3.ZERO

func _ready() -> void:
	super._ready()
	# The Void mouse hand uses XRTools ownership but has no tracked controller.
	# Preserve the original recorder's honest desktop-object measurement mode.
	if is_instance_valid(_movement_sampler):
		_movement_sampler.point.picked_up.connect(_select_input_source)

func _select_input_source(_body: Node3D) -> void:
	var point: XRToolsPickable = _movement_sampler.point
	if point.get_picked_up_by_controller() == null and is_instance_valid(point.get_picked_up_by()):
		_movement_sampler._desktop = point.get_picked_up_by()
		_movement_sampler.sample.start("desktop_movement")

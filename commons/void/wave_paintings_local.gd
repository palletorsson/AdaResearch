extends "res://algorithms/wavefunctions/oscillation_driver/WavePaintings.gd"
## Called by the original builder before each child enters the tree.
func _disable_camera(pendulum: Node3D) -> void:
	super._disable_camera(pendulum)
	var settings:Dictionary={}
	for p in pendulum.get_property_list():
		if int(p.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE and int(p.usage)&PROPERTY_USAGE_EDITOR:
			settings[p.name]=pendulum.get(p.name)
	pendulum.set_script(load("res://commons/void/double_pendulum_local.gd"))
	for key in settings:pendulum.set(key,settings[key])

extends "res://algorithms/physicssimulation/softbody3d/softbody3d.gd"
## Void adapter for softbody3d.gd (the mill's soft sphere, the four falling stop bodies).
##
## The original guards its body with WORLD heights: below y 1.0 at setup it is moved
## to y 2.0, and below y -0.5 on any frame it is moved to y 1.0. Those numbers assume
## the hall floor is world y 0. Void content floors stand at -6, -12 and lower, so the
## original sends every body up through the slabs onto the canopy. The same two
## guards are applied here relative to the enclosing Void content floor. Outside the
## Void (no `void_content_floor` ancestor) the datum is 0 and nothing differs.
## Nothing else is changed: type detection, pressure, precision, states, wind and
## force-field hooks are the original's.
var _datum := 0.0

func _floor_datum() -> float:
	var n: Node = get_parent()
	while n != null:
		if n is Node3D and n.has_meta("void_content_floor"): return (n as Node3D).global_position.y
		n = n.get_parent()
	return 0.0

func _setup_physics() -> void:
	collision_layer = 1
	collision_mask = 1
	_datum = _floor_datum()
	if global_position.y - _datum < 1.0:
		global_position.y = _datum + 2.0

func _validate_physics() -> void:
	if global_position.y - _datum < -0.5:
		global_position.y = _datum + 1.0

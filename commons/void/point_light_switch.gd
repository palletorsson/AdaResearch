extends "res://commons/primitives/point/point_sun_switch.gd"
## Reuse the museum switch's real pointer/hand button, scoped to this floor's lamps.

func _ready() -> void:
	super._ready()
	sun.free(); sun = null
	fill.free(); fill = null
	box(Vector3(.055,1.25,.07),Vector3(0,.625,-.05),Color("34313c"))
	box(Vector3(.35,.025,.28),Vector3(0,.012,0),Color("34313c"))

func _bind_hall() -> void:
	# Palette previews have no floor; the search may reach SceneTree's Window.
	var ancestor: Node = get_parent()
	while ancestor != null and not ancestor.has_meta("void_content_floor"):
		ancestor = ancestor.get_parent()
	_hall = ancestor as Node3D
	if _hall != null: set_sun_enabled(bool(_hall.get_meta("point_lights_enabled",true)))

func set_sun_enabled(value: bool) -> void:
	enabled = value
	if is_instance_valid(_hall):
		_hall.set_meta("point_lights_enabled",value)
		for node in _hall.find_children("*", "Node3D", true, false):
			if node.is_in_group("void_point_rod_light"): node.set_lit(value)
	caption.text = "POINT LIGHTS / ON" if value else "POINT LIGHTS / OFF"
	if _turn: _turn.kill()
	_turn = create_tween()
	_turn.tween_property(lever,"rotation:x",deg_to_rad(-24 if value else 24),.16)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < .25 or not is_instance_valid(_hall): return
	_elapsed = 0
	var state := bool(_hall.get_meta("point_lights_enabled",true))
	if state != enabled: set_sun_enabled(state)

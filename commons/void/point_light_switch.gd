extends "res://commons/primitives/point/point_sun_switch.gd"
## Reuse the museum switch's real pointer/hand button, scoped to this floor's lamps.
const Hardware := preload("res://commons/void/array_control_hardware.gd")
const Supply := preload("res://commons/void/hardware_supply.gd")

func _ready() -> void:
	super._ready()
	sun.free(); sun = null
	fill.free(); fill = null
	# Same rectangular rocker and touch target; an installed mains cabinet.
	var cream := Color("e5e0cf")
	var steel := Color("384249")
	box(Vector3(.40,.60,.18),Vector3(0,1.30,-.105),cream).name="SwitchCabinet"
	box(Vector3(.45,.67,.05),Vector3(0,1.30,-.22),steel).name="RearPlate"
	box(Vector3(.09,1.30,.10),Vector3(0,.65,-.20),steel).name="FloorUpright"
	box(Vector3(.40,.06,.42),Vector3(0,.03,-.20),steel).name="FloorShoe"
	caption.position = Vector3(0,1.50,.003)
	caption.font_size = 32
	caption.pixel_size = .00065
	Hardware.mark(self,"LIGHT CIRCUIT / 01",Vector3(0,1.57,-.008),Vector2(.33,.035))
	Hardware.mark(self,"PRESS / ON · OFF",Vector3(0,1.08,-.008),Vector2(.30,.033))
	for x in [-.16,.16]:
		for y in [1.05,1.55]:
			box(Vector3(.018,.018,.01),Vector3(x,y,-.008),steel)
	Supply.connect_unit(self,Vector3(0,1.62,-.20))

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

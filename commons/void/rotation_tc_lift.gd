extends Node3D
## Existing tc carrier/carry law, with its established Void boarding deck.
const Transport=preload("res://commons/scenes/mapobjects/transport_cube.tscn")
const Ride=preload("res://commons/void/ride_platform.gd")
const Finish=preload("res://commons/void/abstract_finish.gd")
var platform:Node3D
var rise:=3.5
func _ready() -> void:
	rise=float(get_meta("config_rise",rise))
	platform=Transport.instantiate();platform.set_script(Ride);platform.name="TransportCube"
	platform.position.y=-.5;platform.move_speed=2.5;platform.start_delay=1.5;platform.return_delay=3.0;platform.auto_start=false
	add_child(platform)
	Finish.blocks(platform,Color("55d6ed"))
	var top_label:=Label3D.new();top_label.text="tc";top_label.font_size=55;top_label.pixel_size=.006;top_label.position.y=.55;top_label.rotation.x=-PI/2;platform.add_child(top_label)
	platform.auto_start=true
	platform.reset_route(to_global(Vector3(0,-.5,0)),to_global(Vector3(0,rise-.5,0)))
	var label:=Label3D.new();label.text="tc / GANTRY LIFT";label.font_size=30;label.pixel_size=.003;label.position=Vector3(0,.4,1.2);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(label)
	set_meta("source_utility","tc")
func prepare_editor_preview() -> void:
	platform.set_physics_process(false);platform.global_position=to_global(Vector3(0,-.5,0))

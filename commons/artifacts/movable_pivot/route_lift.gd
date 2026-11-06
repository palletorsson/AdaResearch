extends Node3D
## Original tc and Void boarding deck, between ground and the raised C landing.
const Transport=preload("res://commons/scenes/mapobjects/transport_cube.tscn")
const Ride=preload("res://commons/void/ride_platform.gd")
const Finish=preload("res://commons/void/abstract_finish.gd")
var platform:Node3D
var rise:=2.02
var preview:=false
func _ready()->void:
	platform=Transport.instantiate();platform.set_script(Ride);platform.name="TransportCube"
	platform.position.y=-.5;platform.move_speed=.8;platform.start_delay=2.4;platform.return_delay=3.0;platform.auto_start=false;add_child(platform)
	Finish.blocks(platform,Color("69cad9"))
	var label:=Label3D.new();label.name="TCLabel";label.text="tc → C";label.position=Vector3(0,.52,0);label.rotation.x=-PI/2;label.pixel_size=.006;label.font_size=48;platform.add_child(label)
	set_meta("source_utility","tc")
	rebase()
func rebase()->void:
	if not is_instance_valid(platform):return
	platform.auto_start=not preview
	platform.reset_route(to_global(Vector3(0,-.5,0)),to_global(Vector3(0,rise-.5,0)))
	if preview:platform.set_physics_process(false);platform.global_position=to_global(Vector3(0,rise-.5,0))
func prepare_editor_preview()->void:
	preview=true;rebase()

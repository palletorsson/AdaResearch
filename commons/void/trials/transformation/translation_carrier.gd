extends Node3D
## Fixed editable anchor; the museum tc carries bodies along this local vector.
const Transport = preload("res://commons/scenes/mapobjects/transport_cube.tscn")
const Ride = preload("res://commons/void/ride_platform.gd")
const Finish = preload("res://commons/void/abstract_finish.gd")
var displacement := Vector3.ZERO
var caption := ""
var tint := Color("86cfd4")
var platform: Node3D

func _ready() -> void:
	platform=Transport.instantiate()
	platform.set_script(Ride)
	platform.name="Transport"
	platform.position.y=-.5
	platform.move_speed=1.5
	platform.start_delay=4.0
	platform.return_delay=5.0
	platform.auto_start=false
	add_child(platform)
	Finish.blocks(platform, Color("91c9c9"))
	var label := Label3D.new()
	label.name="RouteLabel"
	label.text=caption
	label.font_size=40;label.pixel_size=.0013;label.outline_size=2
	label.position=Vector3(0,.75,0)
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=tint
	add_child(label)
	rebase()

func rebase() -> void:
	if not is_instance_valid(platform): return
	platform.auto_start=true
	platform.reset_route(to_global(Vector3(0,-.5,0)),to_global(displacement+Vector3(0,-.5,0)))

func prepare_editor_preview() -> void:
	platform.set_physics_process(false)
	platform.global_position=to_global(Vector3(0,-.5,0))

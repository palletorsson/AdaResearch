extends Node3D
## The editor moves this fixed route anchor. Its child travels between local docks.
const Transport = preload("res://commons/scenes/mapobjects/transport_cube.tscn")
const Ride = preload("res://commons/void/ride_platform.gd")
const Geometry = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
var platform: Node3D

func _ready() -> void:
	platform=Transport.instantiate()
	platform.set_script(Ride)
	platform.name="Transport"
	platform.position=Vector3(0,.5,0)
	platform.move_speed=.75
	platform.start_delay=3.0
	platform.return_delay=4.0
	platform.move_distance=3.0
	platform.move_direction=global_basis.x.normalized()
	platform.auto_start=false
	add_child(platform)
	# These are route indicators, not an invisible floor over the gap.
	for side in [-1,1]:
		Geometry.box(self,"RouteRail",Vector3(1.5,.18,side*1.16),Vector3(5,.035,.035),Color("577c8c"),false)
	var label := Label3D.new()
	label.name="BoardingInstruction"
	label.text="STEP ON / RIDE ACROSS\nWAIT HERE FOR THE RETURN"
	label.font_size=48;label.pixel_size=.0016;label.outline_size=0
	label.position=Vector3(-.5,1.02,0);label.rotation.x=-PI/2
	add_child(label)
	rebase()

func rebase() -> void:
	if not is_instance_valid(platform): return
	platform.auto_start=true
	platform.reset_route(to_global(Vector3(0,.5,0)),to_global(Vector3(3,.5,0)))

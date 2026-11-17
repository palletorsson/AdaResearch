extends "res://addons/godot-xr-tools/objects/pickable.gd"
## One mushroom you can take and eat. Taken in a hand (or with the right mouse button), it is eaten by bringing it to
## the mouth in a headset, or by the trigger (left mouse button on the desktop) while it is held. Eaten, it is gone
## from the hand, its kind's operation comes into the visitor's eyes (mushroom_trip.gd), and the basket grows it again.

const Trip := preload("res://commons/artifacts/mushroom_basket/mushroom_trip.gd")
const MOUTH := 0.2           ## metres from the eyes at which a held mushroom is eaten
const CAPS := [Color("e85d8f"), Color("f2c14e"), Color("7fc4d8"), Color("b28ad8"), Color("f08a4b"), Color("e8e3d4")]

var kind := 0
var basket: Node3D
var spot := 0
var eaten := false


func _init() -> void:
	collision_layer = 4
	collision_mask = 1
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = ReleaseMode.UNFROZEN
	mass = 0.05


func _ready() -> void:
	add_to_group("no_gravity_gun")
	var shape := CapsuleShape3D.new()
	shape.radius = 0.04
	shape.height = 0.13
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(0, 0.05, 0)
	add_child(collision)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.014
	stem.bottom_radius = 0.019
	stem.height = 0.075
	_part(stem, Vector3(0, 0.037, 0), Color("efe6d6"))
	var cap := SphereMesh.new()
	cap.radius = 0.042
	cap.height = 0.05
	cap.is_hemisphere = true
	_part(cap, Vector3(0, 0.072, 0), CAPS[kind % CAPS.size()])
	# spots, so a cap reads as a mushroom and not a dome
	for i in 5:
		var dot := SphereMesh.new()
		dot.radius = 0.006
		dot.height = 0.006
		var a := TAU * float(i) / 5.0 + float(kind)
		_part(dot, Vector3(cos(a) * 0.024, 0.093 - 0.004 * float(i % 2), sin(a) * 0.024), Color("fff8ee"))
	action_pressed.connect(func(_p): eat())
	super()


func _part(mesh: Mesh, at: Vector3, colour: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	var surface := StandardMaterial3D.new()
	surface.albedo_color = colour
	surface.roughness = 0.6
	part.material_override = surface
	add_child(part)
	return part


func _physics_process(delta: float) -> void:
	if eaten or not is_picked_up(): return
	var eyes := get_viewport().get_camera_3d()
	if eyes != null and eyes.global_position.distance_to(global_position) < MOUTH: eat()


## Eat it: the eyes change, the mushroom goes, the basket grows another.
func eat() -> void:
	if eaten: return
	eaten = true
	var eyes := get_viewport().get_camera_3d()
	if eyes != null: Trip.on(eyes).call("eat", kind)
	if is_picked_up(): let_go(get_picked_up_by(), Vector3.ZERO, Vector3.ZERO)
	if basket != null and basket.has_method("regrow"): basket.call("regrow", spot, kind)
	queue_free()

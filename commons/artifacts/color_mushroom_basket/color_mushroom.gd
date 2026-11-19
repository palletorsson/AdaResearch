extends "res://addons/godot-xr-tools/objects/pickable.gd"
## A pickable colour mushroom in a Rainbow Playground basket.
## Eating it (bring near mouth in VR, or trigger/left-click while held on desktop)
## floods the entire world in this mushroom's cap colour via RainbowWorldWash,
## then regrows in the basket.

const WorldWash := preload("res://commons/artifacts/rainbow_playground/world_color_wash.gd")
const MOUTH_DIST := 0.24

var cap_colour: Color = Color("fa4c9a")
var colour_name: String = "Rose"
var basket: Node3D
var spot: int = 0
var eaten: bool = false
var floor_y: float = -198.0

func _init() -> void:
	collision_layer = 4
	collision_mask = 1
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = ReleaseMode.UNFROZEN
	mass = 0.05

func _ready() -> void:
	add_to_group("no_gravity_gun")
	add_to_group("mushroom")
	add_to_group("edible")
	var shape := CapsuleShape3D.new()
	shape.radius = 0.055
	shape.height = 0.16
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 0.07, 0)
	add_child(col)

	var stem := CylinderMesh.new()
	stem.top_radius = 0.020
	stem.bottom_radius = 0.028
	stem.height = 0.135
	_part(stem, Vector3(0, 0.068, 0), Color("f5ecd8"), false)

	var cap := SphereMesh.new()
	cap.radius = 0.072
	cap.height = 0.084
	cap.is_hemisphere = true
	_part(cap, Vector3(0, 0.128, 0), cap_colour, true)

	for i in range(6):
		var dot := SphereMesh.new()
		dot.radius = 0.011
		dot.height = 0.011
		var a := TAU * float(i) / 6.0 + cap_colour.h * 6.0
		_part(dot, Vector3(cos(a) * 0.044, 0.165 - 0.008 * float(i % 2), sin(a) * 0.044), Color("fff9f0"), false)

	action_pressed.connect(func(_p): eat())
	super()

func _part(mesh: Mesh, at: Vector3, colour: Color, glowing: bool) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.35 if glowing else 0.65
	if glowing:
		mat.emission_enabled = true
		mat.emission = colour
		mat.emission_energy_multiplier = 0.35
	part.material_override = mat
	add_child(part)
	return part

func _physics_process(_delta: float) -> void:
	if eaten or not is_picked_up():
		return
	var eyes := get_viewport().get_camera_3d()
	if eyes != null and eyes.global_position.distance_to(global_position) < MOUTH_DIST:
		eat()

func eat() -> void:
	if eaten:
		return
	eaten = true
	var wash: Node3D = WorldWash.ensure(self, floor_y)
	if wash != null and wash.has_method("tint_from_mushroom"):
		wash.call("tint_from_mushroom", cap_colour, colour_name, 12.0)
	if is_picked_up():
		let_go(get_picked_up_by(), Vector3.ZERO, Vector3.ZERO)
	if basket != null and basket.has_method("regrow"):
		basket.call("regrow", spot, cap_colour, colour_name)
	queue_free()

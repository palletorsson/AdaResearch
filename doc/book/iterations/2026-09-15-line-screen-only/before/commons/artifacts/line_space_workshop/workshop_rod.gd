extends "res://addons/godot-xr-tools/objects/pickable.gd"
## A fixed-length segment. Release keeps the arrangement where the hand left it.
var span := 0.8
var ink := Color("ffc468")
var presence := 1.0
var film_layer := 0 # Visual layer only; XR pickable physics stays on layer 3.
var _material: StandardMaterial3D

func _init() -> void:
	freeze = true
	gravity_scale = 0.0
	release_mode = ReleaseMode.FROZEN
	collision_layer = 4 # XRTools' pickable layer; captured before inherited @onready.
	collision_mask = 0

func _ready() -> void:
	add_to_group("line_workshop_rod")
	var mat := StandardMaterial3D.new()
	_material = mat
	mat.albedo_color = ink
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = ink
	mat.emission_energy_multiplier = 0.3
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.height = span
	cylinder.radial_segments = 8
	mesh.mesh = cylinder
	mesh.layers = 1 | film_layer
	mesh.material_override = mat
	mesh.rotation_degrees.z = 90
	add_child(mesh)
	for sign_ in [-1, 1]:
		var end := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.023
		sphere.height = 0.046
		sphere.radial_segments = 8
		sphere.rings = 4
		end.mesh = sphere
		end.layers = 1 | film_layer
		end.material_override = mat
		end.position.x = sign_ * span * 0.5
		add_child(end)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.032
	capsule.height = span + 0.064
	shape.shape = capsule
	shape.rotation_degrees.z = 90
	add_child(shape)
	super()

func endpoints() -> Array[Vector3]:
	return [to_global(Vector3(-span * 0.5, 0, 0)), to_global(Vector3(span * 0.5, 0, 0))]

func set_presence(amount: float) -> void:
	presence = clampf(amount, 0.0, 1.0)
	visible = presence > 0.001
	enabled = presence > 0.99
	if not is_picked_up(): collision_layer = 4 if enabled else 0
	if _material:
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if presence < 0.999 else BaseMaterial3D.TRANSPARENCY_DISABLED
		var color := ink
		color.a = presence
		_material.albedo_color = color

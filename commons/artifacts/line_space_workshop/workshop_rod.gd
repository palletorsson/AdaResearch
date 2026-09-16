extends Node3D
## Fixed-length filmed geometry: no collision, grab target or museum-world mesh.
var span := 0.8
var ink := Color("ffc468")
var presence := 1.0
var film_layer := 1
var _material: StandardMaterial3D

func _ready() -> void:
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
	mesh.layers = film_layer
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
		end.layers = film_layer
		end.material_override = mat
		end.position.x = sign_ * span * 0.5
		add_child(end)

func endpoints() -> Array[Vector3]:
	return [to_global(Vector3(-span * 0.5, 0, 0)), to_global(Vector3(span * 0.5, 0, 0))]

func set_presence(amount: float) -> void:
	presence = clampf(amount, 0.0, 1.0)
	visible = presence > 0.001
	if _material:
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if presence < 0.999 else BaseMaterial3D.TRANSPARENCY_DISABLED
		var color := ink
		color.a = presence
		_material.albedo_color = color

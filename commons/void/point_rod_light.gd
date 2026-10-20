extends Node3D
## A small downward lamp at the existing pink feed's terminal.
var beam: SpotLight3D
var finish: StandardMaterial3D

func _ready() -> void:
	var housing := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = .07; shape.bottom_radius = .09; shape.height = .1
	shape.radial_segments = 16; shape.rings = 0
	housing.mesh = shape
	var dark := StandardMaterial3D.new(); dark.albedo_color = Color("302631")
	dark.metallic = .6; dark.roughness = .3; housing.material_override = dark
	add_child(housing)
	var lens := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = .075; disc.bottom_radius = .075; disc.height = .008
	disc.radial_segments = 16; disc.rings = 0
	lens.mesh = disc; lens.position.y = -.054
	finish = StandardMaterial3D.new()
	finish.albedo_color = Color("ffe7ed"); finish.emission = Color("ffcbdc")
	finish.emission_energy_multiplier = 1.5
	lens.material_override = finish; add_child(lens)
	beam = SpotLight3D.new(); beam.name = "RodLight"
	beam.rotation.x = -PI/2
	beam.position.y = -.065
	beam.light_color = Color("ffe3d5"); beam.light_energy = 3.0
	beam.spot_range = 3.6; beam.spot_angle = 46
	beam.spot_attenuation = 1.2; beam.shadow_enabled = true
	add_child(beam)
	add_to_group("void_point_rod_light")

func set_lit(value: bool) -> void:
	beam.visible = value
	finish.emission_enabled = value

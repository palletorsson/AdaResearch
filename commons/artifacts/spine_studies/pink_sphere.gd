extends Node3D
## The five-switch score from sphere-in-pink, without its private camera or GUI.
const PINK := Color(1.0,0.50,0.70)
const PALE := Color(0.78,0.78,0.78)
const LIGHT_POSITIONS := [Vector3(0,3.8,0),Vector3(-3,1,0),Vector3(3,1,0),Vector3(0,1,3),Vector3(0,1,-3)]
var lights: Array[SpotLight3D] = []
var sphere_material: StandardMaterial3D
var mask := 1
var pink_material := false
func _ready() -> void:
	var sphere := MeshInstance3D.new(); var mesh := SphereMesh.new()
	mesh.radius = 0.72; mesh.height = 1.44; mesh.radial_segments = 96; mesh.rings = 48
	sphere.mesh = mesh; sphere.position.y = 0.72
	sphere_material = StandardMaterial3D.new(); sphere_material.albedo_color = PALE
	sphere_material.roughness = 0.88; sphere_material.metallic_specular = 0.18
	sphere_material.disable_ambient_light = true; sphere_material.disable_receive_shadows = true
	sphere.material_override = sphere_material; add_child(sphere)
	var body := StaticBody3D.new(); var col := CollisionShape3D.new(); var shape := SphereShape3D.new()
	shape.radius = 0.72; col.shape = shape; body.add_child(col); sphere.add_child(body)
	# A fixed roof and back screen separate this lighting comparison from daylight.
	for pair in [[Vector3(0,0.006,0),Vector3(8,0.012,8)],[Vector3(0,2,-4),Vector3(8,4,0.14)],[Vector3(0,4.2,0),Vector3(8,0.12,8)]]:
		var surface := MeshInstance3D.new(); var cube := BoxMesh.new(); cube.size = pair[1]
		surface.mesh = cube; surface.position = pair[0]
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.38,0.38,0.38); mat.roughness = 1
		mat.disable_ambient_light = true; surface.material_override = mat; add_child(surface)
		surface.create_trimesh_collision()
	for i in 5:
		var lamp := SpotLight3D.new(); add_child(lamp); lamp.position = LIGHT_POSITIONS[i]
		lamp.look_at(to_global(sphere.position),Vector3.FORWARD if i == 0 else Vector3.UP)
		lamp.light_color = PINK; lamp.light_energy = 0.6; lamp.spot_range = 7
		lamp.spot_angle = 64; lamp.spot_attenuation = 0.45; lamp.shadow_enabled = true
		lamp.shadow_bias = 0.15; lamp.shadow_normal_bias = 1.0; lights.append(lamp)
	set_lights(1)
func set_lights(value: int) -> void:
	mask = clampi(value,0,31)
	for i in lights.size(): lights[i].visible = (mask & (1 << i)) != 0
func set_pink_material(value: bool) -> void:
	pink_material = value; sphere_material.albedo_color = PINK if value else PALE
	for lamp in lights: lamp.light_color = Color.WHITE if value else PINK

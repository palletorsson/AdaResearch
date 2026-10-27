extends "res://commons/artifacts/spine_studies/pink_sphere.gd"
## Compact receiving box; keeps the original specimen's five-switch mask logic.
var sphere_mesh: SphereMesh
var study_layer := 2
var sphere: MeshInstance3D
var shell: Array[MeshInstance3D] = []

func _ready() -> void:
	sphere = MeshInstance3D.new()
	sphere.name = "PaleSphere"
	sphere.mesh = sphere_mesh
	sphere.position = Vector3(0,.31,0)
	sphere.layers = study_layer
	sphere_material = StandardMaterial3D.new()
	sphere_material.albedo_color = PALE
	sphere_material.roughness = .88
	sphere_material.metallic_specular = .18
	sphere_material.disable_ambient_light = true
	sphere.material_override = sphere_material
	add_child(sphere)
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color(.58,.58,.58)
	wall_material.roughness = 1.0
	wall_material.metallic_specular = .0
	# Five surfaces, with the front open. A sphere casts onto its floor and sides.
	for pair in [
		[Vector3(0,.025,0),Vector3(1.02,.05,1.02)],
		[Vector3(0,1,0),Vector3(1.02,.05,1.02)],
		[Vector3(-.5,.5,0),Vector3(.05,1,1.02)],
		[Vector3(.5,.5,0),Vector3(.05,1,1.02)],
		[Vector3(0,.5,-.5),Vector3(1.02,1,.05)]]:
		var panel := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = pair[1]
		panel.mesh = mesh
		panel.position = pair[0]
		panel.layers = study_layer
		panel.material_override = wall_material
		add_child(panel)
		shell.append(panel)
	var positions := [Vector3(0,.9,.03),Vector3(-.45,.34,.03),
		Vector3(.45,.34,.03),Vector3(0,.34,.48),Vector3(0,.34,-.46)]
	for i in 5:
		var lamp := SpotLight3D.new()
		lamp.name = ["Top","Left","Right","Front","Back"][i]
		add_child(lamp)
		lamp.position = positions[i]
		lamp.look_at(to_global(sphere.position),Vector3.FORWARD if i==0 else Vector3.UP)
		lamp.light_color = Color.RED
		lamp.light_energy = .65
		lamp.spot_range = 1.35
		lamp.spot_angle = 68
		lamp.spot_attenuation = .45
		lamp.light_cull_mask = study_layer
		lamp.shadow_enabled = true
		lamp.shadow_bias = .01
		lamp.shadow_normal_bias = .01
		lights.append(lamp)
	set_lights(1)

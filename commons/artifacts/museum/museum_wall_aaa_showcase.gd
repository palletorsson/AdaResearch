extends Node3D
class_name MuseumWallAAAShowcase

const WALL_RUN_SCENE := preload("res://commons/artifacts/museum/museum_wall_run.tscn")
const ARCH := preload("res://commons/artifacts/museum/museum_wall_architectural_spans.gd")

@export var enable_lights := true

var _built := false
var _stone: Material
var _stone_dark: Material
var _bronze: Material
var _floor_a: StandardMaterial3D
var _floor_b: StandardMaterial3D
var _ceiling: StandardMaterial3D
var _black: StandardMaterial3D
var _white: StandardMaterial3D
var _red: StandardMaterial3D
var _emissive: StandardMaterial3D


func _ready() -> void:
	_build()


func _build() -> void:
	if _built:
		return
	_built = true
	_build_materials()
	var room := Node3D.new()
	room.name = "AAA_AcceptanceRoom"
	room.set_meta("grid_m", 1.0)
	room.set_meta("wall_run_m", 16.0)
	room.set_meta("quality_intent", "museum_wall_vertical_slice")
	room.set_meta("light_budget", 6)
	add_child(room)

	_build_wall(room)
	_build_floor(room)
	_build_returns(room)
	_build_ceiling(room)
	_build_feature_context(room)
	_build_service_context(room)
	_build_scale_context(room)
	if enable_lights:
		_build_lighting(room)


func _build_materials() -> void:
	_stone = ARCH.create_pbr_material("stone", Color(0.74, 0.68, 0.58), Vector2(1.4, 2.6), 2)
	_stone_dark = ARCH.create_pbr_material("stone", Color(0.57, 0.51, 0.44), Vector2(1.5, 2.8), 5)
	_bronze = ARCH.create_pbr_material("bronze", Color(0.42, 0.28, 0.13), Vector2(1.5, 2.2), 3)
	_floor_a = _mat(Color(0.105, 0.11, 0.115), 0.76, 0.02)
	_floor_b = _mat(Color(0.14, 0.145, 0.15), 0.7, 0.03)
	_ceiling = _mat(Color(0.16, 0.155, 0.145), 0.82, 0.0)
	_black = _mat(Color(0.025, 0.027, 0.03), 0.34, 0.25)
	_white = _mat(Color(0.72, 0.69, 0.64), 0.78, 0.0)
	_red = _mat(Color(0.62, 0.035, 0.02), 0.42, 0.2)
	_emissive = _mat(Color(0.78, 0.9, 0.82), 0.28, 0.0)
	_emissive.emission_enabled = true
	_emissive.emission = Color(0.5, 1.0, 0.72)
	_emissive.emission_energy_multiplier = 2.1


func _build_wall(parent: Node3D) -> void:
	var run: Node3D = WALL_RUN_SCENE.instantiate()
	run.name = "MainWallRun_16m"
	run.set("run_spec", "portal:2|service:2|feature:4|window:3|vitrine:3|solid:2")
	run.set("height", 4.0)
	run.set("finish", "uffizi_stone")
	run.set("quality_tier", "aaa")
	run.set("detail_seed", 13249)
	run.set("enable_collision", true)
	parent.add_child(run)


func _build_floor(parent: Node3D) -> void:
	var floor := Node3D.new()
	floor.name = "FloorGrid_1m"
	parent.add_child(floor)
	for x in range(16):
		for z in range(6):
			var px := -7.5 + float(x)
			var pz := 0.55 + float(z)
			var material: Material = _floor_a if (x + z) % 2 == 0 else _floor_b
			floor.add_child(_box("FloorTile_%02d_%02d" % [x, z], Vector3(px, -0.055, pz), Vector3(0.985, 0.11, 0.985), material))
	# A continuous under-slab prevents light leaks between the readable 1 m tiles.
	floor.add_child(_box("FloorUnderSlab", Vector3(0, -0.12, 3.05), Vector3(16.0, 0.14, 6.0), _black))
	floor.add_child(_box("FloorDatumBronze", Vector3(0, 0.008, 1.02), Vector3(15.65, 0.016, 0.028), _bronze))


func _build_returns(parent: Node3D) -> void:
	var returns := Node3D.new()
	returns.name = "ReturnWalls"
	parent.add_child(returns)
	for side_value in [-1.0, 1.0]:
		var side := float(side_value)
		var side_name := "West" if side < 0.0 else "East"
		var x: float = side * 7.925
		for z in range(6):
			returns.add_child(_box("Return_%s_%02d" % [side_name, z], Vector3(x, 2.0, 0.5 + float(z)), Vector3(0.15, 4.0, 1.0), _stone if z % 2 == 0 else _stone_dark))
		returns.add_child(_box("ReturnSkirting_%s" % side_name, Vector3(x - side * 0.09, 0.16, 3.0), Vector3(0.12, 0.3, 5.8), _stone_dark))
		returns.add_child(_box("ReturnNosing_%s" % side_name, Vector3(x - side * 0.1, 2.55, 3.0), Vector3(0.055, 0.07, 5.8), _bronze))


func _build_ceiling(parent: Node3D) -> void:
	var ceiling := Node3D.new()
	ceiling.name = "CeilingGrid_1m"
	parent.add_child(ceiling)
	for x in range(16):
		ceiling.add_child(_box("CeilingCoffer_%02d" % x, Vector3(-7.5 + float(x), 4.32, 2.95), Vector3(0.97, 0.12, 5.85), _ceiling))
	for z in range(7):
		ceiling.add_child(_box("CeilingBeam_%02d" % z, Vector3(0, 4.23, float(z)), Vector3(16.0, 0.16, 0.1), _black))
	for x_value in [-6.0, -2.0, 2.0, 6.0]:
		var track_x := float(x_value)
		ceiling.add_child(_box("Track_%s" % str(track_x), Vector3(track_x, 4.14, 2.25), Vector3(0.08, 0.08, 3.9), _black))


func _build_feature_context(parent: Node3D) -> void:
	var context := Node3D.new()
	context.name = "FeatureArtwork_ContextProof"
	parent.add_child(context)
	# The feature span occupies x=-4..0 in the 16 m run.
	context.add_child(_box("ArtworkShadowBox", Vector3(-2.0, 2.05, 0.27), Vector3(2.7, 2.15, 0.16), _black))
	context.add_child(_box("ArtworkLinen", Vector3(-2.0, 2.05, 0.37), Vector3(2.5, 1.95, 0.055), _white))
	context.add_child(_box("ArtworkFieldA", Vector3(-2.42, 2.1, 0.405), Vector3(0.76, 1.16, 0.025), _red))
	context.add_child(_box("ArtworkFieldB", Vector3(-1.64, 1.82, 0.41), Vector3(0.84, 0.16, 0.032), _bronze))
	context.add_child(_box("ArtworkFieldC", Vector3(-1.55, 2.38, 0.415), Vector3(0.25, 0.78, 0.032), _black))
	context.set_meta("protected_feature_field", true)


func _build_service_context(parent: Node3D) -> void:
	var props := Node3D.new()
	props.name = "PeripheralServiceProps"
	parent.add_child(props)
	# Service span occupies x=-6..-4; props stay near its outer edge.
	props.add_child(_box("ExtinguisherCabinet", Vector3(-5.72, 0.78, 0.38), Vector3(0.42, 0.9, 0.2), _black))
	props.add_child(_cylinder("FireExtinguisher", Vector3(-5.72, 0.66, 0.53), 0.12, 0.62, _red))
	props.add_child(_box("ExtinguisherLabel", Vector3(-5.72, 1.18, 0.5), Vector3(0.3, 0.13, 0.025), _white))
	props.add_child(_box("ExitSignHousing", Vector3(-7.0, 3.43, 0.29), Vector3(0.9, 0.28, 0.12), _black))
	props.add_child(_box("ExitSignFace", Vector3(-7.0, 3.43, 0.36), Vector3(0.72, 0.16, 0.025), _emissive))
	props.set_meta("wall_zone", "peripheral")


func _build_scale_context(parent: Node3D) -> void:
	var scale := Node3D.new()
	scale.name = "HumanScaleWitness"
	scale.position = Vector3(6.45, 0, 1.15)
	parent.add_child(scale)
	scale.add_child(_box("Torso", Vector3(0, 1.22, 0), Vector3(0.38, 0.72, 0.2), _black))
	scale.add_child(_cylinder("LegLeft", Vector3(-0.09, 0.42, 0), 0.065, 0.84, _black))
	scale.add_child(_cylinder("LegRight", Vector3(0.09, 0.42, 0), 0.065, 0.84, _black))
	scale.add_child(_cylinder("ArmLeft", Vector3(-0.25, 1.18, 0), 0.05, 0.68, _black))
	scale.add_child(_cylinder("ArmRight", Vector3(0.25, 1.18, 0), 0.05, 0.68, _black))
	var head := MeshInstance3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.74, 0)
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.26
	head.mesh = sphere
	head.material_override = _black
	scale.add_child(head)
	scale.set_meta("height_m", 1.87)


func _build_lighting(parent: Node3D) -> void:
	var lights := Node3D.new()
	lights.name = "LightingRig"
	parent.add_child(lights)
	for index in range(4):
		var light := SpotLight3D.new()
		light.name = "WallWash_%02d" % index
		light.position = Vector3(-6.0 + float(index) * 4.0, 3.58, 3.0)
		light.rotation_degrees.x = -15.0
		light.light_color = Color(1.0, 0.82, 0.64)
		light.light_energy = 4.1
		light.spot_range = 6.4
		light.spot_angle = 34.0
		light.shadow_enabled = index in [1, 2]
		lights.add_child(light)
	var ambient_fill := OmniLight3D.new()
	ambient_fill.name = "GalleryFill"
	ambient_fill.position = Vector3(0, 2.6, 4.7)
	ambient_fill.light_color = Color(0.46, 0.6, 0.82)
	ambient_fill.light_energy = 0.42
	ambient_fill.omni_range = 9.0
	ambient_fill.shadow_enabled = false
	lights.add_child(ambient_fill)


func _box(node_name: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = mesh
	instance.material_override = material
	return instance


func _cylinder(node_name: String, at: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = at
	instance.mesh = mesh
	instance.material_override = material
	return instance


func _mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

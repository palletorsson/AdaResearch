extends Node3D
class_name KapoorVoidStudies

## Three original spatial studies after Anish Kapoor: a deep floor aperture,
## six hollow blocks, and a wall with a convex swelling beside a concavity.
## These are not reconstructions of Kapoor's works.

const NEAR_BLACK_SHADER := preload("res://commons/artifacts/kapoor_void_studies/near_black.gdshader")

var _ink_material: ShaderMaterial
var _chalk_material: StandardMaterial3D
var _stone_material: StandardMaterial3D
var _wall_material: StandardMaterial3D
var _bowls: Array[MeshInstance3D] = []
var _studio_lights: Array[Light3D] = []
var _black_surface := true


func _ready() -> void:
	_make_materials()
	_build_gallery()
	set_black_surface(true)
	set_studio_lights(true)


func set_black_surface(enabled: bool) -> void:
	_black_surface = enabled
	for bowl in _bowls:
		if is_instance_valid(bowl):
			bowl.material_override = _ink_material if enabled else _chalk_material


func set_studio_lights(enabled: bool) -> void:
	for lamp in _studio_lights:
		if is_instance_valid(lamp):
			lamp.visible = enabled


func _make_materials() -> void:
	_ink_material = ShaderMaterial.new()
	_ink_material.shader = NEAR_BLACK_SHADER
	_chalk_material = StandardMaterial3D.new()
	_chalk_material.albedo_color = Color(0.48, 0.46, 0.48)
	_chalk_material.roughness = 0.9
	_stone_material = StandardMaterial3D.new()
	_stone_material.albedo_color = Color(0.58, 0.55, 0.49)
	_stone_material.roughness = 0.94
	_wall_material = StandardMaterial3D.new()
	_wall_material.albedo_color = Color(0.78, 0.75, 0.70)
	_wall_material.roughness = 0.88


func _build_gallery() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "GraphiteEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.065, 0.060, 0.073)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.43, 0.39, 0.45)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	var floor := _box("GalleryFloor", Vector3(19.0, 0.30, 10.0), Vector3(0.0, -0.17, 0.0), _floor_material())
	add_child(floor)
	_add_backdrop()
	_build_descent_study(Vector3(-5.4, 0.0, 0.0))
	_build_void_field_study(Vector3(0.0, 0.0, 0.0))
	_build_wall_study(Vector3(5.6, 0.0, 0.0))
	_add_lights()


func _floor_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.145, 0.16)
	material.roughness = 0.87
	return material


func _add_backdrop() -> void:
	var back := _box("ShadowWall", Vector3(19.0, 6.0, 0.25), Vector3(0.0, 2.8, -4.9), _wall_material)
	add_child(back)
	var ceiling := _box("CeilingBaffle", Vector3(19.0, 0.12, 9.8), Vector3(0.0, 5.9, 0.0), _floor_material())
	add_child(ceiling)


func _build_descent_study(at: Vector3) -> void:
	# The circular void is a real aperture in this plinth. The bowl is contained;
	# it reads as depth without making the gallery floor itself a hazard.
	var study := Node3D.new()
	study.name = "01_Descent_After"
	study.position = at
	add_child(study)
	var plinth := _csg_cut_box("FloorAperture", Vector3(3.55, 0.56, 3.55), 1.10, 1.85, _wall_material)
	study.add_child(plinth)
	_add_bowl(study, 1.075, 1.22, Vector3(0.0, 0.56, 0.0))
	_add_rim(study, 1.10, Vector3(0.0, 0.565, 0.0), false, 1.0)
	_add_label(study, "DESCENT / AFTER", Vector3(0.0, 0.10, 2.04))
	_add_label(study, "A contained depth", Vector3(0.0, -0.015, 2.04), 25, Color(0.70, 0.66, 0.70))


func _build_void_field_study(at: Vector3) -> void:
	var study := Node3D.new()
	study.name = "02_Void_Field_After"
	study.position = at
	add_child(study)
	var base := _box("FieldPlinth", Vector3(5.25, 0.46, 3.18), Vector3(0.0, 0.23, 0.0), _wall_material)
	study.add_child(base)
	var widths := [0.90, 0.82, 0.94, 0.86, 0.92, 0.84]
	var heights := [0.70, 0.84, 0.76, 0.81, 0.69, 0.88]
	var depths := [0.22, 0.26, 0.20, 0.24, 0.21, 0.27]
	for i in range(6):
		var col := i % 3
		var row := int(i / 3)
		var x := (float(col) - 1.0) * 1.38
		var z := (float(row) - 0.5) * 1.20
		var size := Vector3(widths[i], heights[i], 0.88)
		var holder := Node3D.new()
		holder.name = "HollowBlock_%02d" % (i + 1)
		holder.position = Vector3(x, 0.46, z)
		holder.rotation.y = [0.0, 0.04, -0.06, 0.08, -0.03, 0.02][i]
		study.add_child(holder)
		var block := _csg_cut_box("StoneAndAperture", size, 0.17, size.y + 0.22, _stone_material)
		holder.add_child(block)
		_add_bowl(holder, 0.158, depths[i], Vector3(0.0, size.y, 0.0))
		_add_rim(holder, 0.17, Vector3(0.0, size.y + 0.008, 0.0), false, 0.42)
	_add_label(study, "VOID FIELD / AFTER", Vector3(0.0, 0.10, 2.02))
	_add_label(study, "Six apertures, one address field", Vector3(0.0, -0.015, 2.02), 25, Color(0.70, 0.66, 0.70))


func _build_wall_study(at: Vector3) -> void:
	var study := Node3D.new()
	study.name = "03_Wall_Body_After"
	study.position = at
	add_child(study)
	var footing := _box("WallFooting", Vector3(4.05, 0.26, 1.15), Vector3(0.0, 0.13, 0.0), _wall_material)
	study.add_child(footing)
	var panel := CSGCombiner3D.new()
	panel.name = "WallWithRecess"
	panel.use_collision = false
	study.add_child(panel)
	var wall := CSGBox3D.new()
	wall.name = "WallStock"
	wall.size = Vector3(3.80, 4.18, 0.34)
	wall.position = Vector3(0.0, 2.35, -0.05)
	wall.material = _wall_material
	panel.add_child(wall)
	var cutter := CSGCylinder3D.new()
	cutter.name = "OvalAperture"
	cutter.radius = 0.58
	cutter.height = 1.25
	cutter.sides = 64
	cutter.operation = CSGShape3D.OPERATION_SUBTRACTION
	cutter.position = Vector3(0.91, 2.36, -0.05)
	cutter.rotation.x = PI * 0.5
	cutter.scale = Vector3(0.80, 1.0, 1.0)
	panel.add_child(cutter)
	# The same plaster skin swells at left; the aperture at right turns inward.
	var swelling := MeshInstance3D.new()
	swelling.name = "WhenIAmPregnant_After"
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 48
	sphere.rings = 32
	swelling.mesh = sphere
	swelling.scale = Vector3(0.88, 1.10, 0.42)
	swelling.position = Vector3(-0.98, 2.36, 0.13)
	swelling.material_override = _wall_material
	study.add_child(swelling)
	_add_bowl(study, 0.56, 0.72, Vector3(0.91, 2.36, 0.12), Vector2(0.80, 1.0), PI * 0.5)
	_add_rim(study, 0.565, Vector3(0.91, 2.36, 0.135), true, 0.8)
	_add_label(study, "WALL / BODY / RECESS", Vector3(0.0, 0.10, 1.03))
	_add_label(study, "Convex beside concave", Vector3(0.0, -0.015, 1.03), 25, Color(0.70, 0.66, 0.70))


func _csg_cut_box(label: String, size: Vector3, radius: float, cutter_height: float, material: Material) -> CSGCombiner3D:
	var group := CSGCombiner3D.new()
	group.name = label
	group.use_collision = false
	var stock := CSGBox3D.new()
	stock.name = "Stock"
	stock.size = size
	stock.position.y = size.y * 0.5
	stock.material = material
	group.add_child(stock)
	var cut := CSGCylinder3D.new()
	cut.name = "SubtractiveVoid"
	cut.radius = radius
	cut.height = cutter_height
	cut.sides = 64
	cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	cut.position.y = size.y * 0.5
	group.add_child(cut)
	return group


func _add_bowl(parent: Node3D, radius: float, depth: float, at: Vector3, stretch: Vector2 = Vector2.ONE, rotate_x: float = 0.0) -> MeshInstance3D:
	var bowl := MeshInstance3D.new()
	bowl.name = "NearBlackConcavity"
	bowl.mesh = _make_bowl_mesh(radius, depth, 22, 72)
	bowl.position = at
	bowl.scale = Vector3(stretch.x, 1.0, stretch.y)
	bowl.rotation.x = rotate_x
	bowl.material_override = _ink_material
	parent.add_child(bowl)
	_bowls.append(bowl)
	return bowl


func _make_bowl_mesh(radius: float, depth: float, rings: int, segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for ring in range(rings + 1):
		var t := float(ring) / float(rings)
		for segment in range(segments + 1):
			var angle := TAU * float(segment) / float(segments)
			var px := radius * t * cos(angle)
			var pz := radius * t * sin(angle)
			vertices.append(Vector3(px, -depth * (1.0 - t * t), pz))
			normals.append(Vector3(-2.0 * depth * px / (radius * radius), 1.0, -2.0 * depth * pz / (radius * radius)).normalized())
			uvs.append(Vector2(0.5 + 0.5 * t * cos(angle), 0.5 + 0.5 * t * sin(angle)))
	for ring in range(rings):
		for segment in range(segments):
			var a := ring * (segments + 1) + segment
			var b := (ring + 1) * (segments + 1) + segment
			var c := (ring + 1) * (segments + 1) + segment + 1
			var d := ring * (segments + 1) + segment + 1
			indices.append_array(PackedInt32Array([a, c, b, a, d, c]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _add_rim(parent: Node3D, radius: float, at: Vector3, vertical: bool, strength: float) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(radius - 0.012, 0.005)
	torus.outer_radius = radius + 0.012
	torus.rings = 72
	torus.ring_segments = 8
	var rim := MeshInstance3D.new()
	rim.name = "EdgeLight"
	rim.mesh = torus
	rim.position = at
	if vertical:
		rim.rotation.x = PI * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.29, 0.23, 0.29)
	material.roughness = 0.38
	material.metallic = 0.24
	material.emission_enabled = true
	material.emission = Color(0.30, 0.055, 0.18)
	material.emission_energy_multiplier = strength * 0.20
	rim.material_override = material
	parent.add_child(rim)


func _box(label: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	return instance


func _add_label(parent: Node3D, words: String, at: Vector3, font_size: int = 34, color: Color = Color(0.90, 0.86, 0.81)) -> void:
	var label := Label3D.new()
	label.text = words
	label.font_size = font_size
	label.pixel_size = 0.0035
	label.modulate = color
	label.position = at
	parent.add_child(label)


func _add_lights() -> void:
	_add_spot(Vector3(-5.6, 5.1, 1.8), Vector3(-5.4, 0.2, 0.0), Color(0.88, 0.77, 0.82), 4.2, 29.0)
	_add_spot(Vector3(0.0, 5.0, 2.0), Vector3(0.0, 0.5, 0.0), Color(0.91, 0.85, 0.73), 3.6, 32.0)
	_add_spot(Vector3(5.6, 5.3, 2.2), Vector3(5.6, 1.8, 0.0), Color(0.75, 0.73, 0.91), 4.0, 30.0)
	var fill := DirectionalLight3D.new()
	fill.name = "SoftRoomFill"
	fill.rotation_degrees = Vector3(-48.0, -26.0, 0.0)
	fill.light_color = Color(0.73, 0.69, 0.79)
	fill.light_energy = 0.42
	fill.shadow_enabled = true
	add_child(fill)
	_studio_lights.append(fill)


func _add_spot(at: Vector3, target: Vector3, color: Color, energy: float, angle: float) -> void:
	var light := SpotLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.spot_range = 10.0
	light.spot_angle = angle
	light.shadow_enabled = true
	add_child(light)
	light.look_at(to_global(target), Vector3.UP)
	_studio_lights.append(light)

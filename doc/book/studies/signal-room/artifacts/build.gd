extends Node3D
## Shared fabrication tools. The five scores live in their own scripts.
## No player, environment, autoload or input capture belongs to the artifact.
signal state_changed(state: Dictionary)
@export_range(0.0, 1.0, 0.01) var amount := 1.0
var evidence: Dictionary = {}
var animated_materials: Array[ShaderMaterial] = []

func _ready() -> void:
	rebuild()

func set_amount(value: float) -> void:
	amount = clampf(value, 0.0, 1.0)
	if is_inside_tree():
		rebuild()
	state_changed.emit({"amount": amount})

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	animated_materials.clear()
	evidence.clear()
	build()

func build() -> void:
	pass

func set_clock(seconds: float) -> void:
	for material in animated_materials:
		material.set_shader_parameter("clock", seconds)

func material(colour: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = colour
	result.roughness = roughness
	result.metallic = metallic
	return result

func emissive(colour: Color, power: float = 1.0) -> StandardMaterial3D:
	var result := material(colour, 0.5)
	result.emission_enabled = true
	result.emission = colour
	result.emission_energy_multiplier = power
	return result

func mesh_at(mesh: Mesh, at: Vector3, surface: Material, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.scale = size
	instance.material_override = surface
	add_child(instance)
	return instance

func box(at: Vector3, size: Vector3, surface: Material, solid: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := mesh_at(mesh, at, surface)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		body.add_child(shape)
		instance.add_child(body)
	return instance

func ball(at: Vector3, size: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 48
	mesh.rings = 24
	return mesh_at(mesh, at, surface, size)

func cylinder(at: Vector3, radius: float, height: float, surface: Material, sides: int = 32, top: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0.0 else top
	mesh.height = height
	mesh.radial_segments = sides
	return mesh_at(mesh, at, surface)

func segment(a: Vector3, b: Vector3, width: float, surface: Material) -> MeshInstance3D:
	var instance := cylinder((a + b) * 0.5, width, a.distance_to(b), surface, 12)
	var direction := (b - a).normalized()
	instance.quaternion = Quaternion(Vector3.UP, direction)
	return instance

func ring(at: Vector3, radius: float, thickness: float, surface: Material, rotate: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 64
	mesh.ring_segments = 16
	var instance := mesh_at(mesh, at, surface)
	instance.rotation_degrees = rotate
	return instance

func tube(points: PackedVector3Array, radius: float, surface: Material) -> MeshInstance3D:
	# Parallel rings around a sampled curve; normals come from radial directions.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var sides := 12
	for i in points.size():
		var tangent := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var reference := Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
		var u := tangent.cross(reference).normalized()
		var v := tangent.cross(u).normalized()
		var taper := 0.5 + 0.5 * sin(PI * float(i) / float(points.size() - 1))
		for j in sides + 1:
			var angle := TAU * float(j) / float(sides)
			var normal := u * cos(angle) + v * sin(angle)
			vertices.append(points[i] + radius * taper * normal)
			normals.append(normal)
			uvs.append(Vector2(float(j) / sides, float(i) / (points.size() - 1)))
			if i < points.size() - 1 and j < sides:
				var a := i * (sides + 1) + j
				indices.append_array(PackedInt32Array([a, a + sides + 1, a + 1, a + 1, a + sides + 1, a + sides + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh_at(mesh, Vector3.ZERO, surface)

func plaque(text: String, at: Vector3, colour: Color = Color(0.23, 0.22, 0.21)) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 38
	label.pixel_size = 0.003
	label.modulate = colour
	label.outline_size = 0
	add_child(label)

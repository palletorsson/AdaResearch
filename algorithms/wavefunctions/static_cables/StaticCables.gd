extends Node3D

@export var cable_count: int = 8
@export var points_per_cable: int = 80
@export var cable_length: float = 12.0
@export var cable_spacing: float = 2.5
@export var sag_amount: float = 2.2
@export var cable_radius: float = 0.12
@export var ring_segments: int = 12
@export var color_start: Color = Color(0.9, 0.5, 0.6)
@export var color_end: Color = Color(0.5, 0.7, 1.0)

var cables: Array[MeshInstance3D] = []

func _ready() -> void:
	_create_environment()
	_generate_cables()

func _create_environment() -> void:
	var env_node := WorldEnvironment.new()
	add_child(env_node)
	var env := Environment.new()
	env_node.environment = env
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.08)
	env.ambient_light_color = Color(0.1, 0.1, 0.2)
	env.glow_enabled = true
	env.glow_intensity = 0.6

func _generate_cables() -> void:
	for i in range(cable_count):
		var offset_z: float = (float(i) - (cable_count - 1) / 2.0) * cable_spacing
		var path: PackedVector3Array = _create_cable_path(offset_z)
		var cable := MeshInstance3D.new()
		cable.mesh = _create_tube_mesh(path)
		cable.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

		var material := StandardMaterial3D.new()
		material.metallic = 0.6
		material.roughness = 0.25
		var tcol = float(i) / max(1, cable_count - 1)
		material.albedo_color = color_start.lerp(color_end, tcol)
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.3
		cable.material_override = material

		add_child(cable)
		cables.append(cable)

# === Path generation (hanging shape) ===
func _create_cable_path(z_offset: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for j in range(points_per_cable):
		var t: float = float(j) / float(points_per_cable - 1)
		var x: float = lerp(-cable_length / 2.0, cable_length / 2.0, t)
		# smooth sag — sine-based
		var y: float = -sin(PI * t) * sag_amount
		var z: float = z_offset
		pts.append(Vector3(x, y, z))
	return pts

# === Tube mesh generation (from ColoredLinesVR principles) ===
func _create_tube_mesh(path: PackedVector3Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if path.size() < 2:
		return mesh

	var segments: int = max(3, ring_segments)
	var radius: float = cable_radius

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for i in range(path.size()):
		var p := path[i]
		var dir := Vector3.ZERO
		if i == 0:
			dir = (path[i + 1] - p).normalized()
		elif i == path.size() - 1:
			dir = (p - path[i - 1]).normalized()
		else:
			dir = (path[i + 1] - path[i - 1]).normalized()
		if dir.length_squared() == 0.0:
			dir = Vector3.FORWARD
		var up := Vector3.UP
		if abs(dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right := dir.cross(up).normalized()
		var real_up := right.cross(dir).normalized()

		for j in range(segments):
			var a := float(j) / float(segments) * TAU
			var offset := (right * cos(a) + real_up * sin(a)) * radius
			vertices.append(p + offset)
			normals.append(offset.normalized())
			uvs.append(Vector2(float(i) / (path.size() - 1), float(j) / float(segments)))

	for i in range(path.size() - 1):
		var ringA := i * segments
		var ringB := (i + 1) * segments
		for j in range(segments):
			var nj := (j + 1) % segments
			indices.append(ringA + j)
			indices.append(ringB + j)
			indices.append(ringA + nj)
			indices.append(ringA + nj)
			indices.append(ringB + j)
			indices.append(ringB + nj)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

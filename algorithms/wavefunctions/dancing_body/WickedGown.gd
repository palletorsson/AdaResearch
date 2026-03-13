# WickedGown - Multi-layered mathematical ball gown
# Inspired by Elphaba's dramatic Act 2 dress with multiple flowing layers
# Each layer uses different parametric surfaces (Dini, spiral, waves)

extends Node3D

@export_group("Gown Structure")
@export var num_layers: int = 3
@export var waist_height: float = 0.0
@export var layer_separation: float = 0.1

@export_group("Layer 1 - Underskirt (Seashell Spiral)")
@export var layer1_radius_top: float = 0.12
@export var layer1_radius_bottom: float = 0.35
@export var layer1_length: float = 0.85
@export var layer1_spiral_intensity: float = 0.3

@export_group("Layer 2 - Overskirt (Wave Torus Pattern)")
@export var layer2_radius_top: float = 0.15
@export var layer2_radius_bottom: float = 0.5
@export var layer2_length: float = 0.75
@export var layer2_wave_frequency: float = 6.0
@export var layer2_wave_amplitude: float = 0.04

@export_group("Layer 3 - Train (Dini Surface Flow)")
@export var layer3_radius_top: float = 0.18
@export var layer3_radius_bottom: float = 0.6
@export var layer3_length: float = 0.95
@export var layer3_a: float = 0.3
@export var layer3_b: float = 0.15

@export_group("Animation")
@export var animation_speed: float = 1.5
@export var flutter_base: float = 0.02
@export var wind_direction: Vector3 = Vector3(1, 0, 0.3)

@export_group("Elphaba Colors")
@export var color_layer1: Color = Color(0.0, 0.15, 0.05)  # Darkest green
@export var color_layer2: Color = Color(0.0, 0.25, 0.08)  # Medium green
@export var color_layer3: Color = Color(0.0, 0.35, 0.12)  # Brightest green
@export var wireframe_color: Color = Color(0.1, 0.8, 0.3)
@export var emission_strength: float = 1.2

var _layers: Array[MeshInstance3D] = []
var _layer_base_vertices: Array = []
var _time: float = 0.0
var u_steps: int = 40
var v_steps: int = 28
var _initialized: bool = false

func _ready() -> void:
	call_deferred("_create_all_layers")

func _create_all_layers() -> void:
	_layers.clear()
	_layer_base_vertices.clear()

	# Layer 1 - Underskirt with spiral pattern
	var layer1 = _create_layer(
		layer1_radius_top, layer1_radius_bottom, layer1_length,
		"spiral", color_layer1, 0
	)
	_layers.append(layer1)

	# Layer 2 - Overskirt with wave torus pattern
	var layer2 = _create_layer(
		layer2_radius_top, layer2_radius_bottom, layer2_length,
		"wave", color_layer2, 1
	)
	_layers.append(layer2)

	# Layer 3 - Outer train with Dini-inspired flow
	var layer3 = _create_layer(
		layer3_radius_top, layer3_radius_bottom, layer3_length,
		"dini", color_layer3, 2
	)
	_layers.append(layer3)

	_initialized = true
	print("WickedGown: Created %d layers" % _layers.size())

func _create_layer(r_top: float, r_bottom: float, length: float, pattern: String, color: Color, layer_idx: int) -> MeshInstance3D:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = []

	for i in range(u_steps + 1):
		var row = []
		var u = float(i) / float(u_steps)

		for j in range(v_steps + 1):
			var v = float(j) / float(v_steps)
			var angle = v * TAU

			# Base flared shape
			var flare = ease(u, 0.6 + layer_idx * 0.1)
			var radius = lerp(r_top, r_bottom, flare)

			# Apply pattern-specific modulation
			match pattern:
				"spiral":
					radius += _spiral_modulation(u, angle, layer_idx)
				"wave":
					radius += _wave_modulation(u, angle, layer_idx)
				"dini":
					radius += _dini_modulation(u, angle, layer_idx)

			var x = radius * cos(angle)
			var z = radius * sin(angle)
			var y = -u * length - layer_idx * layer_separation

			# Vertical wave for flow
			y += sin(angle * 3.0) * 0.01 * u

			row.append(Vector3(x, y, z))
		vertices.append(row)

	_layer_base_vertices.append(vertices)

	# Build mesh
	_build_faces(surface_tool, vertices)
	surface_tool.generate_normals()

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = surface_tool.commit()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mesh_instance)

	# Apply material
	_apply_layer_material(mesh_instance, color)

	return mesh_instance

func _spiral_modulation(u: float, angle: float, _layer_idx: int) -> float:
	# Seashell-like logarithmic spiral influence
	var spiral = sin(angle * 4.0 + u * TAU * layer1_spiral_intensity) * 0.02 * u
	var secondary = cos(angle * 2.0 - u * PI) * 0.015 * u
	return spiral + secondary

func _wave_modulation(u: float, angle: float, _layer_idx: int) -> float:
	# Wave torus pattern - multiple sine waves combined
	var wave_u = sin(u * 3.0 * TAU) * layer2_wave_amplitude * u
	var wave_v = sin(angle * layer2_wave_frequency) * layer2_wave_amplitude * 0.7 * u
	var combined = sin(angle * 3.0 + u * TAU * 2.0) * layer2_wave_amplitude * 0.4 * u
	return wave_u + wave_v + combined

func _dini_modulation(u: float, angle: float, _layer_idx: int) -> float:
	# Dini surface-inspired twisted flow
	var dini_twist = layer3_a * cos(u * TAU) * sin(angle * 5.0) * 0.03
	var dini_flow = layer3_b * sin(u * PI * 2.0) * cos(angle * 3.0) * 0.025 * u
	var asymmetry = sin(angle + u * PI) * 0.02 * u  # Makes the back trail longer
	return dini_twist + dini_flow + asymmetry

func _build_faces(surface_tool: SurfaceTool, vertices: Array) -> void:
	for i in range(u_steps):
		for j in range(v_steps):
			var v0 = vertices[i][j]
			var v1 = vertices[i + 1][j]
			var v2 = vertices[i + 1][j + 1]
			var v3 = vertices[i][j + 1]

			var edge1 = v1 - v0
			var edge2 = v3 - v0
			var normal = edge1.cross(edge2).normalized()

			# First triangle
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v1)
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v2)

			# Second triangle
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v0)
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v2)
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v3)

func _apply_layer_material(mesh_instance: MeshInstance3D, color: Color) -> void:
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")

	if shader:
		material.shader = shader
		material.set_shader_parameter("modelColor", color)
		material.set_shader_parameter("wireframeColor", wireframe_color)
		material.set_shader_parameter("emissionColor", color * 1.3)
		material.set_shader_parameter("width", 1.2)
		material.set_shader_parameter("emission_strength", emission_strength)
		mesh_instance.material_override = material
	else:
		var standard = StandardMaterial3D.new()
		standard.albedo_color = color
		standard.emission_enabled = true
		standard.emission = color * 1.2
		standard.emission_energy_multiplier = emission_strength
		standard.cull_mode = BaseMaterial3D.CULL_DISABLED
		standard.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		standard.albedo_color.a = 0.95
		mesh_instance.mesh.surface_set_material(0, standard)

func _process(delta: float) -> void:
	_time += delta * animation_speed
	_animate_all_layers()

func _animate_all_layers() -> void:
	# Safety check
	if not _initialized:
		return

	for layer_idx in range(_layers.size()):
		if layer_idx >= _layer_base_vertices.size():
			continue

		var mesh_instance = _layers[layer_idx]
		var base_vertices = _layer_base_vertices[layer_idx]

		if base_vertices.size() < u_steps:
			continue

		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

		var animated = []
		var flutter = flutter_base * (1.0 + layer_idx * 0.3)  # Outer layers flutter more

		for i in range(u_steps + 1):
			if i >= base_vertices.size():
				break
			var row = []
			var u = float(i) / float(u_steps)

			for j in range(v_steps + 1):
				if j >= base_vertices[i].size():
					break
				var base_pos = base_vertices[i][j]
				var v = float(j) / float(v_steps)
				var angle = v * TAU

				# Time-based wave animation
				var time_phase = _time + layer_idx * 0.5  # Phase offset per layer
				var wave1 = sin(time_phase + angle * 4.0) * flutter * u
				var wave2 = cos(time_phase * 0.7 + angle * 2.0) * flutter * 0.5 * u

				# Wind effect (directional)
				var wind_strength = sin(_time * 0.3) * flutter * u * 1.5
				var wind_offset = wind_direction.normalized() * wind_strength

				var pos = base_pos
				pos.x += wave1 * cos(angle) + wind_offset.x
				pos.z += wave1 * sin(angle) + wind_offset.z
				pos.y += wave2 * 0.3 + wind_offset.y * 0.2

				row.append(pos)
			animated.append(row)

		# Verify we have enough vertices
		if animated.size() < u_steps or animated[0].size() < v_steps:
			continue

		_build_faces(surface_tool, animated)
		surface_tool.generate_normals()

		var new_mesh = surface_tool.commit()
		if new_mesh and new_mesh.get_surface_count() > 0:
			var old_material = mesh_instance.material_override
			mesh_instance.mesh = new_mesh
			mesh_instance.material_override = old_material

# API for runtime adjustments
func set_wind(direction: Vector3, intensity: float) -> void:
	wind_direction = direction
	flutter_base = intensity

func set_layer_colors(colors: Array[Color]) -> void:
	if colors.size() >= 1: color_layer1 = colors[0]
	if colors.size() >= 2: color_layer2 = colors[1]
	if colors.size() >= 3: color_layer3 = colors[2]

	for i in range(min(_layers.size(), colors.size())):
		_apply_layer_material(_layers[i], colors[i])

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


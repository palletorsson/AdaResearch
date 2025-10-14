# res://algorithms/wavefunctions/static_cables/StaticCables.gd
# Static running cables using the line technique from ColoredLinesVR

extends Node3D

@export var cable_count: int = 15
@export var cable_length: float = 40.0
@export var cable_spacing: float = 2.5
@export var cable_radius: float = 0.08
@export var ring_segments: int = 8
@export var points_per_cable: int = 80

@export_category("Cable Patterns")
@export var pattern_type: String = "Straight"  # "Straight", "Sag", "Wave", "Spiral", "Random"
@export var sag_amount: float = 1.5
@export var wave_amplitude: float = 2.0
@export var wave_frequency: float = 1.2
@export var spiral_turns: float = 3.0
@export var random_variation: float = 0.8

@export_category("Visual Settings")
@export var cable_color: Color = Color(0.8, 0.8, 0.9)
@export var cable_metallic: float = 0.3
@export var cable_roughness: float = 0.4
@export var cable_emission: float = 0.1
@export var use_vertex_colors: bool = true
@export var color_variation: float = 0.3

@export_category("Environment")
@export var environment_brightness: float = 0.3
@export var fog_density: float = 0.02
@export var ambient_color: Color = Color(0.1, 0.1, 0.15)

var cable_meshes: Array[MeshInstance3D] = []
var cable_materials: Array[StandardMaterial3D] = []
var cable_paths: Array[PackedVector3Array] = []

var _cable_container: Node3D

const CABLE_SHADER := """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec4 cable_color : source_color = vec4(0.8, 0.8, 0.9, 1.0);
uniform float metallic_factor = 0.3;
uniform float roughness_factor = 0.4;
uniform float emission_strength = 0.1;
uniform float color_variation = 0.3;
uniform float time_offset = 0.0;

varying float cable_progress;
varying vec3 world_position;

void vertex() {
	cable_progress = UV.x;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base_color = cable_color.rgb;
	
	// Add subtle color variation along the cable
	float color_shift = sin(cable_progress * 6.2831 + time_offset * 0.5) * color_variation;
	vec3 varied_color = base_color + vec3(color_shift * 0.1, color_shift * 0.05, -color_shift * 0.1);
	
	// Add slight metallic sheen
	float metallic = metallic_factor + sin(cable_progress * 20.0 + time_offset) * 0.1;
	float roughness = roughness_factor + cos(cable_progress * 15.0 + time_offset * 0.3) * 0.1;
	
	ALBEDO = varied_color;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	EMISSION = varied_color * emission_strength;
}
"""

func _ready() -> void:
	randomize()
	_setup_environment()
	generate_cable_paths()
	create_cable_meshes()

func _setup_environment() -> void:
	var env_node := get_node_or_null("WorldEnvironment")
	if env_node == null:
		env_node = WorldEnvironment.new()
		env_node.name = "WorldEnvironment"
		add_child(env_node)
	
	var env: Environment = env_node.environment
	if env == null:
		env = Environment.new()
		env_node.environment = env
	
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = environment_brightness
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = fog_density
	env.volumetric_fog_emission = Color(0.05, 0.05, 0.1)
	env.volumetric_fog_emission_energy = 0.3

func generate_cable_paths() -> void:
	cable_paths.clear()
	
	var start_z: float = -cable_length * 0.5
	var end_z: float = cable_length * 0.5
	
	for i in range(cable_count):
		var y_pos: float = 3.0 + float(i) * cable_spacing
		var phase: float = float(i) * 0.7
		var path: PackedVector3Array = _create_cable_path(start_z, end_z, y_pos, phase)
		cable_paths.append(path)

func _create_cable_path(start_z: float, end_z: float, y_pos: float, phase: float) -> PackedVector3Array:
	var samples: int = max(2, points_per_cable)
	var pts := PackedVector3Array()
	
	for i in range(samples):
		var t: float = 0.0 if samples <= 1 else float(i) / float(samples - 1)
		var z_pos: float = lerp(start_z, end_z, t)
		var base_pos := Vector3(0.0, y_pos, z_pos)
		
		match pattern_type:
			"Straight":
				pts.append(base_pos)
			"Sag":
				var sag: float = sin(PI * t) * sag_amount
				pts.append(base_pos + Vector3(0.0, -sag, 0.0))
			"Wave":
				var wave_x: float = sin(t * wave_frequency * TAU + phase) * wave_amplitude
				pts.append(base_pos + Vector3(wave_x, 0.0, 0.0))
			"Spiral":
				var spiral_radius: float = 1.0 + sin(t * TAU * spiral_turns + phase) * 0.5
				var spiral_angle: float = t * TAU * spiral_turns + phase
				var spiral_x: float = cos(spiral_angle) * spiral_radius
				var spiral_y: float = sin(spiral_angle) * spiral_radius * 0.3
				pts.append(base_pos + Vector3(spiral_x, spiral_y, 0.0))
			"Random":
				var random_x: float = sin(t * 3.0 + phase) * random_variation + cos(t * 5.0 + phase * 1.3) * random_variation * 0.5
				var random_y: float = cos(t * 2.0 + phase * 0.8) * random_variation * 0.7
				var random_z: float = sin(t * 4.0 + phase * 1.1) * random_variation * 0.3
				pts.append(base_pos + Vector3(random_x, random_y, random_z))
			_:
				pts.append(base_pos)
	
	return pts

func create_cable_meshes() -> void:
	if _cable_container and is_instance_valid(_cable_container):
		_cable_container.queue_free()
	
	_cable_container = Node3D.new()
	_cable_container.name = "CableMeshes"
	add_child(_cable_container)
	
	cable_meshes.clear()
	cable_materials.clear()
	
	if cable_paths.is_empty():
		return
	
	for i in range(cable_paths.size()):
		var path: PackedVector3Array = cable_paths[i]
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Cable_%02d" % i
		mesh_instance.mesh = _create_cable_mesh_from_path(path)
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		
		# Create material
		var material := StandardMaterial3D.new()
		material.albedo_color = _get_cable_color(i)
		material.metallic = cable_metallic
		material.roughness = cable_roughness
		material.emission_enabled = true
		material.emission = _get_cable_color(i) * cable_emission
		
		mesh_instance.material_override = material
		_cable_container.add_child(mesh_instance)
		
		cable_meshes.append(mesh_instance)
		cable_materials.append(material)

func _create_cable_mesh_from_path(path: PackedVector3Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if path.size() < 2:
		return mesh
	
	var segments: int = max(3, ring_segments)
	var radius: float = max(0.01, cable_radius)
	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	
	for i in range(path.size()):
		var current := path[i]
		var progress := float(i) / float(path.size() - 1)
		var direction := Vector3.ZERO
		
		if i == 0:
			direction = (path[i + 1] - current).normalized()
		elif i == path.size() - 1:
			direction = (current - path[i - 1]).normalized()
		else:
			direction = (path[i + 1] - path[i - 1]).normalized()
		
		if direction.length_squared() == 0.0:
			direction = Vector3.FORWARD
		
		var up := Vector3.UP
		if abs(direction.dot(up)) > 0.9:
			up = Vector3.RIGHT
		
		var right := direction.cross(up).normalized()
		var actual_up := right.cross(direction).normalized()
		
		for j in range(segments):
			var angle := float(j) / float(segments) * TAU
			var offset: Vector3 = (right * cos(angle) + actual_up * sin(angle)) * radius
			vertices.append(current + offset)
			normals.append(offset.normalized())
			uvs.append(Vector2(progress, float(j) / float(segments)))
	
	for i in range(path.size() - 1):
		var prev_ring: int = i * segments
		var curr_ring: int = (i + 1) * segments
		for j in range(segments):
			var next_j: int = (j + 1) % segments
			indices.append(prev_ring + j)
			indices.append(curr_ring + j)
			indices.append(prev_ring + next_j)
			indices.append(prev_ring + next_j)
			indices.append(curr_ring + j)
			indices.append(curr_ring + next_j)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _get_cable_color(cable_index: int) -> Color:
	if not use_vertex_colors:
		return cable_color
	
	# Create subtle color variation between cables
	var hue_offset: float = float(cable_index) / float(max(1, cable_count - 1)) * 0.1
	var base_hue: float = 0.6 + hue_offset  # Blue-ish base
	var saturation: float = 0.3 + sin(float(cable_index) * 0.5) * 0.1
	var value: float = 0.8 + cos(float(cable_index) * 0.3) * 0.1
	
	return Color.from_hsv(base_hue, saturation, value)

func regenerate_cables() -> void:
	generate_cable_paths()
	create_cable_meshes()

func change_pattern(new_pattern: String) -> void:
	pattern_type = new_pattern
	regenerate_cables()

func add_cable() -> void:
	cable_count += 1
	regenerate_cables()

func remove_cable() -> void:
	if cable_count > 1:
		cable_count -= 1
		regenerate_cables()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Space key
		add_cable()
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		remove_cable()
	elif event.is_action_pressed("ui_select"):  # Enter key
		regenerate_cables()
	elif event.is_action_pressed("ui_home"):  # Home key
		change_pattern("Straight")
	elif event.is_action_pressed("ui_end"):  # End key
		change_pattern("Random")

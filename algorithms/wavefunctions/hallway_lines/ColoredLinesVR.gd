# res://hallway_lines/ColoredLinesVR.gd
# A mesmerizing hallway of wall-to-wall colored sine lines

extends Node3D

@export var points_per_line: int = 120
@export var animation_speed: float = 0.0  # Set to 0 for static lines
@export var flow_speed: float = 0.0  # Set to 0 for static colors
@export var hallway_width: float = 12.0
@export var hallway_length: float = 60.0
@export var hallway_height: float = 8.0
@export var row_spacing: float = 6.0
@export var span_wave_amp: float = 2.2
@export var span_twist_amp: float = 1.1
@export var span_frequency: float = 1.5
@export var line_radius: float = 0.3  # Thicker tubes
@export var ring_segments: int = 16  # More segments for smoother tubes

var line_meshes: Array[MeshInstance3D] = []
var line_materials: Array[ShaderMaterial] = []
var line_paths: Array[PackedVector3Array] = []

var _line_container: Node3D
var _deform_tween: Tween

const FLOOR_THICKNESS := 0.2
const FLOOR_OFFSET_Y := -0.1

const LINE_SHADER := """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform float time_offset = 0.0;
uniform float flow_speed = 0.0;  // Static by default
uniform vec4 color_start : source_color = vec4(1.0, 0.0, 0.5, 1.0);
uniform vec4 color_end : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float glow_intensity = 1.5;
uniform float thickness_variation = 0.0;  // No thickness animation by default
uniform float pulse_frequency = 0.0;  // No pulse by default

varying float line_progress;

void vertex() {
	line_progress = UV.x;
	// Static thickness - no animation when pulse_frequency is 0
	float thickness = 1.0;
	if (pulse_frequency > 0.0) {
		thickness += sin(line_progress * 10.0 + TIME * pulse_frequency) * thickness_variation;
	}
	VERTEX.xyz *= thickness;
}

void fragment() {
	// Static gradient based on position along line
	float color_wave = line_progress;  // Simple gradient, no time-based animation
	vec3 flowing_color = mix(color_start.rgb, color_end.rgb, color_wave);

	// Optional rainbow effect, but static
	float hue_shift = line_progress;  // No time component for static look
	vec3 rainbow = vec3(
		sin(hue_shift * 6.2831) * 0.5 + 0.5,
		sin(hue_shift * 6.2831 + 2.094) * 0.5 + 0.5,
		sin(hue_shift * 6.2831 + 4.188) * 0.5 + 0.5
	);
	vec3 final_color = mix(flowing_color, rainbow, 0.3);

	// Static intensity - no pulse
	float pulse = 1.0;

	// Center glow effect
	float center_distance = abs(UV.y - 0.5) * 2.0;
	float glow = 1.0 - pow(center_distance, 0.5);

	ALBEDO = final_color;
	EMISSION = final_color * glow_intensity * glow;
	ALPHA = color_start.a;
}
"""

func _ready() -> void:
	randomize()
	_setup_environment()
	_create_hallway_box()
	generate_line_paths()
	create_line_meshes()
	start_line_animations()

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
	env.background_color = Color(0.03, 0.03, 0.07)
	env.ambient_light_color = Color(0.1, 0.1, 0.2)
	env.ambient_light_energy = 0.5
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.015
	env.volumetric_fog_emission = Color(0.05, 0.1, 0.2)
	env.volumetric_fog_emission_energy = 0.5
	var camera := get_viewport().get_camera_3d()
	if camera:
		camera.environment = env

func _create_hallway_box() -> void:
	



	var ceiling := MeshInstance3D.new()
	ceiling.name = "Ceiling"

	ceiling.position = Vector3(0.0, hallway_height + FLOOR_OFFSET_Y, 0.0)
	ceiling.material_override = _make_metal(Color(0.12, 0.12, 0.18))
	add_child(ceiling)

	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(0.2, hallway_height, hallway_length)
	var wall_material := _make_metal(Color(0.7, 0.7, 0.8))

	var wall_left := MeshInstance3D.new()
	wall_left.name = "WallLeft"
	wall_left.mesh = wall_mesh
	wall_left.material_override = wall_material
	wall_left.position = Vector3(-hallway_width * 0.5, hallway_height * 0.5 + FLOOR_OFFSET_Y, 0.0)
	add_child(wall_left)

	var wall_right := MeshInstance3D.new()
	wall_right.name = "WallRight"
	wall_right.mesh = wall_mesh
	wall_right.material_override = wall_material
	wall_right.position = Vector3(hallway_width * 0.5, hallway_height * 0.5 + FLOOR_OFFSET_Y, 0.0)
	add_child(wall_right)

func _make_metal(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.8
	mat.roughness = 0.12
	# mat.specular = 0.8  # Godot 3.x parameter not available in Godot 4
	return mat

func generate_line_paths() -> void:
	line_paths.clear()
	var start_z := -hallway_length * 0.5 + 3.0
	var end_z := hallway_length * 0.5 - 3.0
	var span := end_z - start_z
	var rows: int = max(1, int(floor(span / row_spacing)) + 1)

	for r in range(rows):
		var lerp_t: float = 0.0 if rows == 1 else float(r) / float(rows - 1)
		var z_pos: float = lerp(start_z, end_z, lerp_t)
		var spans_in_row: int = 2 + (r % 2)
		for s in range(spans_in_row):
			var y_mid := 2.0 + float(s) * 1.8 + sin((float(r) + float(s)) * 0.37) * 0.6
			var phase := float(r) * 0.55 + float(s) * 1.1
			line_paths.append(_create_span_path(z_pos, y_mid, phase))

func _create_span_path(z_pos: float, y_mid: float, phase: float) -> PackedVector3Array:
	var start := Vector3(-hallway_width * 0.5, y_mid, z_pos)
	var finish := Vector3(hallway_width * 0.5, y_mid, z_pos)
	var samples = max(2, points_per_line)
	var pts := PackedVector3Array()

	for i in range(samples):
		var t := 0.0 if samples <= 1 else float(i) / float(samples - 1)
		var base := start.lerp(finish, t)
		var arc := sin(PI * t) * span_wave_amp
		var twist := sin(TAU * span_frequency * t + phase) * span_twist_amp
		pts.append(base + Vector3(0.0, arc, twist))

	return pts

func create_line_meshes() -> void:
	if _line_container and is_instance_valid(_line_container):
		_line_container.queue_free()
	_line_container = Node3D.new()
	_line_container.name = "LineMeshes"
	add_child(_line_container)

	line_meshes.clear()
	line_materials.clear()

	if line_paths.is_empty():
		return

	var total := line_paths.size()
	for i in range(total):
		var path := line_paths[i]
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Line_%02d" % i
		mesh_instance.mesh = _create_line_mesh_from_path(path)
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

		var shader := Shader.new()
		shader.code = LINE_SHADER
		var material := ShaderMaterial.new()
		material.shader = shader

		var hue_base := 0.0
		if total > 1:
			hue_base = float(i) / float(total - 1)
		var color1 := Color.from_hsv(hue_base, 0.8, 1.0)
		var color2 := Color.from_hsv(fposmod(hue_base + 0.33, 1.0), 0.8, 1.0)
		material.set_shader_parameter("color_start", color1)
		material.set_shader_parameter("color_end", color2)
		material.set_shader_parameter("time_offset", randf_range(0.0, 10.0))
		material.set_shader_parameter("flow_speed", flow_speed)  # Use export value directly
		material.set_shader_parameter("glow_intensity", randf_range(1.5, 2.0))  # Consistent glow
		material.set_shader_parameter("thickness_variation", 0.0)  # No thickness variation
		material.set_shader_parameter("pulse_frequency", 0.0)  # No pulsing

		mesh_instance.set_surface_override_material(0, material)
		_line_container.add_child(mesh_instance)

		line_meshes.append(mesh_instance)
		line_materials.append(material)

func _create_line_mesh_from_path(path: PackedVector3Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if path.size() < 2:
		return mesh

	var segments: int = max(3, ring_segments)
	var radius: float = max(0.01, line_radius)

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

func start_line_animations() -> void:
	if line_meshes.is_empty():
		return

	if _deform_tween and _deform_tween.is_valid():
		_deform_tween.kill()
	_deform_tween = null

	# Only animate if animation_speed is greater than 0
	if animation_speed > 0.0:
		var duration: float = 15.0 / max(animation_speed, 0.01)
		_deform_tween = create_tween()
		_deform_tween.set_loops()
		_deform_tween.tween_method(Callable(self, "_update_line_deformation"), 0.0, TAU, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_animate_shader_properties()  # Only animate shader properties if lines are animating

func _update_line_deformation(time: float) -> void:
	for i in range(line_meshes.size()):
		if i >= line_paths.size():
			continue
		var mesh_instance := line_meshes[i]
		if not is_instance_valid(mesh_instance):
			continue
		var original_path := line_paths[i]
		if original_path.is_empty():
			continue
		var deformed := PackedVector3Array()
		var count := original_path.size()
		for j in range(count):
			var base := original_path[j]
			var t := 0.0 if count <= 1 else float(j) / float(count - 1)
			var edge_falloff := sin(PI * t)
			var deformation := Vector3(
				sin(time + float(i) * 0.3 + t * 4.0) * 0.5,
				cos(time * 0.7 + float(i) * 0.5 + t * 3.0) * 0.3,
				sin(time * 1.1 + float(i) * 0.7 + t * 5.0) * 0.4
			) * edge_falloff
			deformed.append(base + deformation)
		mesh_instance.mesh = _create_line_mesh_from_path(deformed)
		if i < line_materials.size():
			mesh_instance.set_surface_override_material(0, line_materials[i])

func _animate_shader_properties() -> void:
	for material in line_materials:
		if not is_instance_valid(material):
			continue
		if abs(flow_speed) > 0.001:
			var base_flow: float = abs(flow_speed)
			var flow_min: float = base_flow * 0.5
			var flow_max: float = base_flow * 2.0
			var tw_flow := create_tween()
			tw_flow.set_loops()
			tw_flow.tween_method(Callable(self, "_set_shader_param").bind(material, "flow_speed"), flow_min, flow_max, randf_range(3.0, 8.0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var tw_glow := create_tween()
		tw_glow.set_loops()
		tw_glow.tween_method(Callable(self, "_set_shader_param").bind(material, "glow_intensity"), 1.0, 3.0, randf_range(2.0, 6.0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_shader_param(material: ShaderMaterial, param: StringName, value: float) -> void:
	if is_instance_valid(material):
		material.set_shader_parameter(param, value)

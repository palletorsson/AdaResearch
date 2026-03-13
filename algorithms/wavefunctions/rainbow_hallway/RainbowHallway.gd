extends Node3D

@export var animation_speed: float = 1.0
@export var gradient_offset: float = 0.5
@export var glow_intensity: float = 0.5
@export var emission_strength: float = 0.5

@export_group("Cone Shape")
@export var cone_mode: bool = true
@export var start_radius: float = 4.0
@export var end_radius: float = 1.5
@export var num_segments: int = 12
@export var segment_length: float = 2.0
@export var wall_thickness: float = 0.3

var shader_material: ShaderMaterial
var gradient_texture: GradientTexture1D
var segments_parent: Node3D

func _ready() -> void:
	segments_parent = get_node_or_null("HallwaySegments")
	if not segments_parent:
		segments_parent = Node3D.new()
		segments_parent.name = "HallwaySegments"
		add_child(segments_parent)
	
	setup_hallway()
	setup_environment()

func setup_hallway() -> void:
	# Clear existing segments
	for child in segments_parent.get_children():
		child.queue_free()
	
	# Create the shader material
	shader_material = ShaderMaterial.new()
	var shader = load("res://algorithms/wavefunctions/rainbow_hallway/rainbow_hallway.gdshader")
	if shader:
		shader_material.shader = shader
	
	# Create gradient texture
	gradient_texture = GradientTexture1D.new()
	var gradient = Gradient.new()

	# Rainbow colors
	gradient.offsets = PackedFloat32Array([0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.2, 0.2),   # Red
		Color(1.0, 0.6, 0.2),   # Orange
		Color(1.0, 1.0, 0.2),   # Yellow
		Color(0.2, 1.0, 0.2),   # Green
		Color(0.2, 0.6, 1.0),   # Blue
		Color(0.6, 0.2, 1.0),   # Purple
		Color(1.0, 0.2, 0.6)    # Pink
	])
	
	gradient_texture.gradient = gradient
	if shader_material:
		shader_material.set_shader_parameter("rainbow_gradient", gradient_texture)
	
	# Generate cone segments
	_generate_cone_segments()
	
	# Set initial shader parameters
	update_shader_parameters()

func _generate_cone_segments() -> void:
	var total_length = num_segments * segment_length
	
	for i in range(num_segments):
		var t = float(i) / float(num_segments - 1) if num_segments > 1 else 0.0
		var radius = lerp(start_radius, end_radius, t)
		var z_pos = i * segment_length
		
		# Create tube segment using CSG
		var segment = _create_tube_segment(radius, segment_length, i)
		segment.position = Vector3(0, 0, -z_pos)
		segments_parent.add_child(segment)
		
		# Add light only every 3rd segment for performance
		if i % 3 == 0:
			var hue = fmod(t + gradient_offset, 1.0)
			var light_color = Color.from_hsv(hue, 0.8, 1.0)
			var light = OmniLight3D.new()
			light.light_color = light_color
			light.light_energy = 3.0  # Brighter to compensate for fewer lights
			light.omni_range = radius * 3.5  # Larger range
			light.shadow_enabled = false  # Disable shadows for performance
			light.position = Vector3(0, 0, -z_pos - segment_length * 0.5)
			segments_parent.add_child(light)

func _create_tube_segment(radius: float, length: float, index: int) -> CSGCombiner3D:
	var combiner = CSGCombiner3D.new()
	combiner.name = "Segment_%d" % index
	combiner.use_collision = true
	
	# Outer cylinder - reduced sides for performance
	var outer = CSGCylinder3D.new()
	outer.radius = radius + wall_thickness
	outer.height = length
	outer.sides = 16  # Reduced from 24 for better performance
	outer.rotation_degrees.x = 90
	outer.position.z = -length * 0.5
	combiner.add_child(outer)
	
	# Inner cylinder (subtract) - reduced sides for performance
	var inner = CSGCylinder3D.new()
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	inner.radius = radius
	inner.height = length + 0.1  # Slightly longer to avoid z-fighting
	inner.sides = 16  # Reduced from 24 for better performance
	inner.rotation_degrees.x = 90
	inner.position.z = -length * 0.5
	combiner.add_child(inner)
	
	# Apply material
	if shader_material:
		combiner.material_override = shader_material
	else:
		# Fallback material
		var mat = StandardMaterial3D.new()
		var hue = float(index) / float(num_segments)
		mat.albedo_color = Color.from_hsv(hue, 0.7, 0.9)
		mat.emission_enabled = true
		mat.emission = Color.from_hsv(hue, 0.8, 1.0)
		mat.emission_energy_multiplier = emission_strength
		combiner.material_override = mat
	
	return combiner

func setup_environment() -> void:
	var env = Environment.new()
	
	env.glow_enabled = true
	env.glow_intensity = glow_intensity
	env.glow_strength = 1.2
	env.glow_mix = 0.5
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 0.4
	
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.1, 0.1, 0.15)
	env.ambient_light_energy = 0.3
	
	var world_env = get_node_or_null("WorldEnvironment")
	if world_env:
		world_env.environment = env

func _process(_delta):
	update_shader_parameters()

func update_shader_parameters() -> void:
	if shader_material:
		shader_material.set_shader_parameter("animation_speed", animation_speed)
		shader_material.set_shader_parameter("gradient_offset", gradient_offset)
		shader_material.set_shader_parameter("glow_intensity", glow_intensity)
		shader_material.set_shader_parameter("emission_strength", emission_strength)
		var total_length = num_segments * segment_length
		shader_material.set_shader_parameter("gradient_start_z", 0.0)
		shader_material.set_shader_parameter("gradient_length_m", total_length)

func apply_grid_config(config: Dictionary) -> void:
	if config.has("start_radius"):
		start_radius = float(config["start_radius"])
	if config.has("end_radius"):
		end_radius = float(config["end_radius"])
	if config.has("num_segments"):
		num_segments = int(config["num_segments"])
	if config.has("segment_length"):
		segment_length = float(config["segment_length"])
	if config.has("animation_speed"):
		animation_speed = float(config["animation_speed"])
	
	setup_hallway()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


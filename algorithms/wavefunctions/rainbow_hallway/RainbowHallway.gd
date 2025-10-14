extends Node3D

@export var animation_speed: float = 1.0
@export var gradient_offset: float = 0.5
@export var glow_intensity: float = 0.5
@export var emission_strength: float = 0.3

var csg_combiner: CSGCombiner3D
var shader_material: ShaderMaterial
var gradient_texture: GradientTexture1D

func _ready():
	setup_hallway()
	setup_environment()
	setup_ui()

func setup_hallway():
	# Get the CSG combiner
	csg_combiner = $CSGCombiner3D
	
	# Create the shader material
	shader_material = ShaderMaterial.new()
	var shader = load("res://algorithms/wavefunctions/rainbow_hallway/rainbow_hallway.gdshader")
	shader_material.shader = shader
	
	# Create gradient texture
	gradient_texture = GradientTexture1D.new()
	var gradient = Gradient.new()
	
	# Set up rainbow colors
	gradient.add_point(0.0, Color(0.2, 0.8, 0.2))  # Green
	gradient.add_point(0.33, Color(0.8, 0.8, 0.2)) # Yellow
	gradient.add_point(0.66, Color(0.8, 0.2, 0.2)) # Red
	gradient.add_point(1.0, Color(0.2, 0.2, 0.8))  # Blue
	
	gradient_texture.gradient = gradient
	shader_material.set_shader_parameter("rainbow_gradient", gradient_texture)
	
	# Apply material to CSG combiner
	csg_combiner.material_override = shader_material
	
	# Set initial shader parameters
	update_shader_parameters()

func setup_environment():
	# Create environment for glow effect
	var env = Environment.new()
	
	# Enable glow
	env.glow_enabled = true
	env.glow_intensity = glow_intensity
	env.glow_strength = 1.0
	env.glow_mix = 0.5
	env.glow_bloom = 0.1
	env.glow_hdr_threshold = 0.5
	
	# Set background
	env.background = Environment.BG_SKY
	env.sky = Sky.new()
	
	# Apply to world environment
	var world_env = $WorldEnvironment
	world_env.environment = env

func setup_ui():
	# Connect UI sliders
	var gradient_slider = $UI/VBoxContainer/HSlider
	var speed_slider = $UI/VBoxContainer/HSlider2
	
	gradient_slider.value_changed.connect(_on_gradient_changed)
	speed_slider.value_changed.connect(_on_speed_changed)

func _process(delta):
	# Update shader parameters
	update_shader_parameters()

func update_shader_parameters():
	if shader_material:
		shader_material.set_shader_parameter("animation_speed", animation_speed)
		shader_material.set_shader_parameter("gradient_offset", gradient_offset)
		shader_material.set_shader_parameter("glow_intensity", glow_intensity)
		shader_material.set_shader_parameter("emission_strength", emission_strength)

func _on_gradient_changed(value: float):
	gradient_offset = value

func _on_speed_changed(value: float):
	animation_speed = value

func set_gradient_colors(colors: Array[Color]):
	"""Update the gradient colors dynamically"""
	if gradient_texture and gradient_texture.gradient:
		var gradient = gradient_texture.gradient
		gradient.clear()
		
		for i in range(colors.size()):
			var t = float(i) / float(colors.size() - 1) if colors.size() > 1 else 0.0
			gradient.add_point(t, colors[i])

func add_light_at_position(position: Vector3, color: Color = Color.WHITE, energy: float = 2.0):
	"""Add a light at the specified position"""
	var light = OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 15.0
	add_child(light)
	return light

func create_light_sequence(positions: Array[Vector3], colors: Array[Color] = []):
	"""Create a sequence of lights along the hallway"""
	if colors.is_empty():
		colors = [Color.WHITE] * positions.size()
	
	for i in range(positions.size()):
		var color = colors[i] if i < colors.size() else Color.WHITE
		add_light_at_position(positions[i], color)

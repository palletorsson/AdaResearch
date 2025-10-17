# perception_altering.gd
class_name PerceptionAlteringEnvironment
extends Node3D

# Configuration
@export var environment_size: Vector3 = Vector3(30, 8, 30)
@export var grid_size: float = 1.0
@export var effect_intensity: float = 1.0
@export var speed_multiplier: float = 1.0
@export var color_shift_speed: float = 0.2
@export var wobble_frequency: float = 0.5
@export var distortion_regions: Array[NodePath] = []

# Shader parameters
@export_group("Visual Distortion Parameters")
@export var max_color_shift: float = 0.3
@export var max_wobble_amount: float = 0.1
@export var max_spatial_distortion: float = 0.2

# Direction distortion parameters
@export_group("Movement Distortion Parameters")
@export var max_direction_shift: float = 45.0  # In degrees
@export var direction_shift_smoothness: float = 0.5
@export var enable_gravity_distortion: bool = true
@export var max_gravity_angle: float = 15.0  # In degrees

# Runtime variables
var grid_material: ShaderMaterial
var grid_lines: MeshInstance3D
var distortion_zones = []
var player: XROrigin3D
var original_transform: Transform3D
var grid_shader_path = "res://shaders/perception_grid_shader.gdshader"
var env_shader_path = "res://shaders/perception_env_shader.gdshader"
var world_environment: WorldEnvironment
var regions = []
var perception_state = {
	"color_phase": 0.0,
	"wobble_phase": 0.0,
	"spatial_phase": 0.0,
	"direction_phase": 0.0,
	"gravity_phase": 0.0
}

func _ready():
	# Find the player
	player = find_child("XROrigin3D", true)
	if player:
		original_transform = player.global_transform
	
	# Setup environment
	_setup_environment()
	
	# Setup grid floor
	_create_grid()
	
	# Setup distortion regions
	_setup_distortion_regions()
	
	# Add instruction label
	_add_instructions()
	
	print("Perception Altering Environment initialized")

func _setup_environment():
	# Create a world environment for global visual effects
	world_environment = WorldEnvironment.new()
	world_environment.name = "PerceptionEnvironment"
	
	var environment = Environment.new()
	#environment.background_mode = Environment.BACKGROUND_COLOR
	environment.background_color = Color(0.05, 0.05, 0.15)
	environment.fog_enabled = true
	environment.fog_density = 0.01
	environment.fog_sun_scatter = 0.5
	#environment.fog_color = Color(0.1, 0.1, 0.2)
	
	world_environment.environment = environment
	add_child(world_environment)
	
	# Add ambient light
	var ambient_light = DirectionalLight3D.new()
	ambient_light.name = "AmbientLight"
	ambient_light.transform.basis = Basis(Vector3(0.5, -0.7, 0.3).normalized(), PI * 0.3)
	ambient_light.shadow_enabled = true
	add_child(ambient_light)

func _create_grid():
	# Create a grid mesh
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(environment_size.x, environment_size.z)
	
	grid_lines = MeshInstance3D.new()
	grid_lines.name = "GridFloor"
	grid_lines.mesh = plane_mesh
	
	# Create shader material
	var shader_resource = _load_or_create_grid_shader()
	if shader_resource:
		grid_material = ShaderMaterial.new()
		grid_material.shader = shader_resource
		grid_material.set_shader_parameter("grid_size", grid_size)
		grid_material.set_shader_parameter("major_grid_size", grid_size * 5)
		grid_material.set_shader_parameter("grid_color", Color(0.3, 0.5, 0.8, 0.7))
		grid_material.set_shader_parameter("major_grid_color", Color(0.5, 0.7, 1.0, 0.9))
		grid_material.set_shader_parameter("background_color", Color(0.03, 0.03, 0.1, 0.2))
		grid_material.set_shader_parameter("wobble_amount", 0.0)
		grid_material.set_shader_parameter("color_shift", 0.0)
		grid_material.set_shader_parameter("spatial_distortion", 0.0)
		
		grid_lines.material_override = grid_material
	else:
		# Fallback material
		var std_material = StandardMaterial3D.new()
		std_material.albedo_color = Color(0.1, 0.1, 0.3, 0.5)
		std_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		grid_lines.material_override = std_material
	
	add_child(grid_lines)
	
	# Add floor collision
	var static_body = StaticBody3D.new()
	static_body.name = "GridCollision"
	
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(environment_size.x, 0.1, environment_size.z)
	collision_shape.shape = shape
	
	static_body.add_child(collision_shape)
	grid_lines.add_child(static_body)

func _setup_distortion_regions():
	# Process predefined distortion regions
	for region_path in distortion_regions:
		var region = get_node(region_path)
		if region:
			regions.append(region)
	
	# If no regions were specified, create some default ones
	if regions.size() == 0:
		_create_default_regions()

func _create_default_regions():
	# Create several distortion regions with different effects
	var region_configs = [
		{
			"position": Vector3(5, 1, 5),
			"size": Vector3(8, 4, 8),
			"color": Color(1.0, 0.3, 0.3, 0.1),
			"type": "color",
			"intensity": 1.0
		},
		{
			"position": Vector3(-5, 1, 5),
			"size": Vector3(6, 4, 6),
			"color": Color(0.3, 1.0, 0.3, 0.1),
			"type": "wobble",
			"intensity": 0.8
		},
		{
			"position": Vector3(0, 1, -8),
			"size": Vector3(10, 4, 6),
			"color": Color(0.3, 0.3, 1.0, 0.1),
			"type": "direction",
			"intensity": 0.7
		},
		{
			"position": Vector3(-8, 1, -8),
			"size": Vector3(6, 4, 6),
			"color": Color(0.8, 0.8, 0.2, 0.1),
			"type": "gravity",
			"intensity": 0.6
		},
		{
			"position": Vector3(8, 1, -8),
			"size": Vector3(6, 4, 6),
			"color": Color(0.8, 0.2, 0.8, 0.1),
			"type": "spatial",
			"intensity": 0.9
		}
	]
	
	for config in region_configs:
		var region = _create_distortion_region(
			config.position,
			config.size,
			config.color,
			config.type,
			config.intensity
		)
		regions.append(region)

func _create_distortion_region(position: Vector3, size: Vector3, color: Color, type: String, intensity: float) -> Node3D:
	var region = Node3D.new()
	region.name = "DistortionRegion_" + type
	region.position = position
	
	# Create visual representation
	var box = CSGBox3D.new()
	box.name = "VisualBox"
	box.size = size
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color * Color(1, 1, 1, 0)
	material.emission_energy = 0.5
	box.material = material
	
	region.add_child(box)
	
	# Create trigger area
	var area = Area3D.new()
	area.name = "TriggerArea"
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	
	# Connect signals
	area.body_entered.connect(_on_region_entered.bind(region, type, intensity))
	area.body_exited.connect(_on_region_exited.bind(region, type))
	
	region.add_child(area)
	
	# Store region type and intensity
	region.set_meta("type", type)
	region.set_meta("intensity", intensity)
	
	add_child(region)
	return region

func _on_region_entered(body: Node3D, region: Node3D, type: String, intensity: float):
	if body == player:
		print("Player entered " + type + " distortion region")
		
		# Apply the effect
		var visual_box = region.get_node("VisualBox")
		if visual_box:
			var material = visual_box.material
			material.emission_energy = 1.0
		
		# Store the active region in the distortion zones array
		if not distortion_zones.has(region):
			distortion_zones.append(region)

func _on_region_exited(body: Node3D, region: Node3D, type: String):
	if body == player:
		print("Player exited " + type + " distortion region")
		
		# Reduce the effect
		var visual_box = region.get_node("VisualBox")
		if visual_box:
			var material = visual_box.material
			material.emission_energy = 0.5
		
		# Remove from active regions
		if distortion_zones.has(region):
			distortion_zones.erase(region)

func _process(delta):
	# Update perception phases
	perception_state.color_phase += delta * color_shift_speed * speed_multiplier
	perception_state.wobble_phase += delta * wobble_frequency * speed_multiplier
	perception_state.spatial_phase += delta * 0.3 * speed_multiplier
	perception_state.direction_phase = fmod(perception_state.direction_phase + delta * 0.2 * speed_multiplier, 1.0)
	perception_state.gravity_phase = fmod(perception_state.gravity_phase + delta * 0.15 * speed_multiplier, 1.0)
	
	# Calculate effect intensities based on active regions
	var color_effect = 0.0
	var wobble_effect = 0.0
	var spatial_effect = 0.0
	var direction_effect = 0.0
	var gravity_effect = 0.0
	
	for region in distortion_zones:
		var type = region.get_meta("type")
		var intensity = region.get_meta("intensity")
		
		match type:
			"color":
				color_effect = max(color_effect, intensity)
			"wobble":
				wobble_effect = max(wobble_effect, intensity)
			"spatial":
				spatial_effect = max(spatial_effect, intensity)
			"direction":
				direction_effect = max(direction_effect, intensity)
			"gravity":
				gravity_effect = max(gravity_effect, intensity)
	
	# Apply global effect intensity multiplier
	color_effect *= effect_intensity
	wobble_effect *= effect_intensity
	spatial_effect *= effect_intensity
	direction_effect *= effect_intensity
	gravity_effect *= effect_intensity
	
	# Apply visual effects to the grid
	if grid_material:
		# Apply color shift effect
		var color_shift = sin(perception_state.color_phase * 2 * PI) * max_color_shift * color_effect
		grid_material.set_shader_parameter("color_shift", color_shift)
		
		# Apply wobble effect
		var wobble = sin(perception_state.wobble_phase * 2 * PI) * max_wobble_amount * wobble_effect
		grid_material.set_shader_parameter("wobble_amount", wobble)
		
		# Apply spatial distortion
		var spatial = sin(perception_state.spatial_phase * 2 * PI) * max_spatial_distortion * spatial_effect
		grid_material.set_shader_parameter("spatial_distortion", spatial)
	
	# Apply movement distortion to the player
	if player and (direction_effect > 0 or gravity_effect > 0):
		_apply_movement_distortion(delta, direction_effect, gravity_effect)

func _apply_movement_distortion(delta: float, direction_effect: float, gravity_effect: float):
	# Get the player's XR camera
	var camera = player.get_node("XRCamera3D")
	if not camera:
		return
	
	# Apply direction shift effect to controllers if they're used for movement
	var controllers = []
	var left_controller = player.get_node("LeftController")
	var right_controller = player.get_node("RightController")
	
	if left_controller:
		controllers.append(left_controller)
	if right_controller:
		controllers.append(right_controller)
	
	# Calculate the direction distortion angle
	var dir_angle = sin(perception_state.direction_phase * 2 * PI) * max_direction_shift * direction_effect
	
	# Apply to controllers
	for controller in controllers:
		if controller.has_method("set_perception_distortion"):
			controller.set_perception_distortion(dir_angle)
	
	# Apply gravity distortion if enabled
	if enable_gravity_distortion and gravity_effect > 0:
		var gravity_angle = sin(perception_state.gravity_phase * 2 * PI) * max_gravity_angle * gravity_effect
		
		# Only apply if we're not in standard XR - this would require deeper integration
		# with the movement system and would typically be implemented in the player controller
		# Here we just simulate a visual tilt
		camera.rotation.z = deg_to_rad(gravity_angle)

func _add_instructions():
	var instructions = Label3D.new()
	instructions.name = "Instructions"
	instructions.text = """
	Perception Altering Environment
	
	- Colored regions affect different aspects of perception
	- Red: Color shifting
	- Green: Visual wobbling
	- Blue: Movement direction distortion
	- Yellow: Gravity distortion
	- Purple: Spatial perception distortion
	
	Walk through the zones to experience different effects!
	"""
	
	instructions.font_size = 16
	instructions.position = Vector3(0, 4, -10)
	instructions.billboard = true
	add_child(instructions)

func reset_player():
	if player:
		player.global_transform = original_transform
		
		var camera = player.get_node("XRCamera3D")
		if camera:
			camera.rotation = Vector3.ZERO

func _load_or_create_grid_shader():
	# Try to load existing shader
	var shader = load(grid_shader_path)
	if shader:
		return shader
	
	# Create a new shader
	shader = Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode unshaded, blend_mix, depth_draw_always, cull_back;
	
	uniform float grid_size = 1.0;
	uniform float major_grid_size = 5.0;
	uniform vec4 grid_color : source_color = vec4(0.3, 0.5, 0.8, 0.7);
	uniform vec4 major_grid_color : source_color = vec4(0.5, 0.7, 1.0, 0.9);
	uniform vec4 background_color : source_color = vec4(0.03, 0.03, 0.1, 0.2);
	uniform float wobble_amount = 0.0;
	uniform float color_shift = 0.0;
	uniform float spatial_distortion = 0.0;
	
	void vertex() {
		// Apply vertex wobble
		VERTEX.y += sin(VERTEX.x * 5.0 + TIME) * wobble_amount * 0.1;
		VERTEX.y += cos(VERTEX.z * 5.0 + TIME * 0.7) * wobble_amount * 0.1;
		
		// Apply spatial distortion
		float dist = length(VERTEX.xz);
		VERTEX.xz += VERTEX.xz * sin(dist * 0.5 - TIME * 0.2) * spatial_distortion;
	}
	
	void fragment() {
		// Transform world coordinates to grid coordinates
		vec2 world_pos = VERTEX.xz;
		
		// Apply some spatial warping
		world_pos += sin(world_pos * 0.05 + TIME * 0.1) * spatial_distortion * 5.0;
		
		// Calculate grid pattern
		vec2 grid_pos = world_pos / grid_size;
		vec2 grid_frac = fract(grid_pos);
		vec2 grid_center = abs(grid_frac - 0.5);
		
		// Calculate major grid pattern
		vec2 major_grid_pos = world_pos / major_grid_size;
		vec2 major_grid_frac = fract(major_grid_pos);
		vec2 major_grid_center = abs(major_grid_frac - 0.5);
		
		// Calculate grid lines
		float line_width = 0.03;
		float grid_line = max(
			smoothstep(0.5 - line_width, 0.5, grid_center.x), 
			smoothstep(0.5 - line_width, 0.5, grid_center.y)
		);
		
		// Calculate major grid lines
		float major_line_width = 0.05;
		float major_grid_line = max(
			smoothstep(0.5 - major_line_width, 0.5, major_grid_center.x), 
			smoothstep(0.5 - major_line_width, 0.5, major_grid_center.y)
		);
		
		// Apply color shifting
		vec4 shifted_grid_color = grid_color;
		vec4 shifted_major_color = major_grid_color;
		
		shifted_grid_color.rgb = mix(grid_color.rgb, 
			vec3(grid_color.r * 0.5, grid_color.g * 1.5, grid_color.b * 0.8),
			sin(TIME * 0.5) * color_shift + color_shift);
			
		shifted_major_color.rgb = mix(major_grid_color.rgb, 
			vec3(major_grid_color.r * 1.3, major_grid_color.g * 0.6, major_grid_color.b * 1.2),
			cos(TIME * 0.3) * color_shift + color_shift);
		
		// Combine grid lines with background
		ALBEDO = mix(background_color.rgb, shifted_grid_color.rgb, grid_line);
		ALBEDO = mix(ALBEDO, shifted_major_color.rgb, major_grid_line);
		
		// Set transparency
		ALPHA = max(max(background_color.a, grid_line * grid_color.a), major_grid_line * major_grid_color.a);
	}
	"""
	
	return shader

# XR controller extension for perception distortion
# This would be attached to the XR controllers or integrated into the existing controller script
"""
extends XRController3D

# Perceptual distortion parameters
var perception_distortion_angle = 0.0
var original_controller_path = NodePath("")
var is_perception_modified = false

func _ready():
	# Store original controller path for reference
	original_controller_path = get_path()

func set_perception_distortion(angle: float):
	perception_distortion_angle = angle
	is_perception_modified = true
	
	# This would need to be integrated with the movement system
	# For direct effect, we could rotate the controller visually
	rotation.y += deg_to_rad(angle)
	
	# Actual movement direction modification would require
	# integrating with the locomotion system, which depends on implementation

func clear_perception_distortion():
	if is_perception_modified:
		rotation.y -= deg_to_rad(perception_distortion_angle)
		perception_distortion_angle = 0.0
		is_perception_modified = false
"""

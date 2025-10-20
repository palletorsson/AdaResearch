extends Node3D

# Editable parameters
@export var metaball_count: int = 9
@export var min_strength: float = 0.8
@export var max_strength: float = 1.2
@export var blend_factor: float = 0.4
@export var metaball_color: Color = Color(0.2, 0.6, 1.0)
@export var animate_strength: bool = false
@export var base_strength: float = 1.0  # Base strength value for all metaballs

# Internal variables
var cube_mesh: MeshInstance3D
var shader_material: ShaderMaterial
var metaball_positions = []
var metaball_strengths = []
var metaball_radii = []

func _ready():
	# Create a simple cube mesh for ray marching
	cube_mesh = MeshInstance3D.new()
	cube_mesh.mesh = BoxMesh.new()
	cube_mesh.mesh.size = Vector3(10.0, 10.0, 10.0)
	add_child(cube_mesh)
	
	# Add light
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(light)
	
	# Load the shader
	shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://algorithms/proceduralgeneration/implicitsurfacemodeling/metaballs/metaball.gdshader")
	
	# Apply to mesh
	cube_mesh.material_override = shader_material
	
	# Initialize metaballs
	initialize_metaballs()
	
	# Set shader parameters
	shader_material.set_shader_parameter("blend_factor", blend_factor)
	shader_material.set_shader_parameter("metaball_color", Vector3(
		metaball_color.r, metaball_color.g, metaball_color.b))
	
	print("Metaball setup complete with strength: ", base_strength)

func initialize_metaballs():
	# Clear existing arrays
	metaball_positions.clear()
	metaball_strengths.clear()
	metaball_radii.clear()
	
	# Initialize metaball positions and strengths
	for i in range(metaball_count):
		var radius = randf_range(0.5, 1.0)
		metaball_radii.append(radius)
		
		# Create Vector4 where xyz = position, w = radius
		var position = Vector4(
			randf_range(-2.0, 2.0),  # x
			randf_range(-2.0, 2.0),  # y
			randf_range(-2.0, 2.0),  # z
			radius                    # radius
		)
		
		metaball_positions.append(position)
		
		# Use the base_strength parameter for all metaballs
		metaball_strengths.append(base_strength)
	
	# Update shader parameters
	update_shader_parameters()

func _process(delta):
	# Create new array for updated positions
	var updated_positions = []
	
	# Animate metaballs
	for i in range(metaball_count):
		var t = Time.get_ticks_msec() * 0.001
		
		# Create a new Vector4 for each position (Vector4 is immutable in Godot 4)
		var new_position = Vector4(
			sin(t * (0.3 + float(i) * 0.1) + i) * 2.0,           # x
			cos(t * (0.2 + float(i) * 0.1) + i * 0.7) * 2.0,      # y
			sin(t * (0.4 + float(i) * 0.05) + i * 1.3) * 2.0,     # z
			metaball_radii[i]                                      # Keep same radius
		)
		
		updated_positions.append(new_position)
		
		# Optionally animate the strength
		if animate_strength:
			metaball_strengths[i] = base_strength + sin(t * 0.5 + i) * 0.3
	
	# Replace the array
	metaball_positions = updated_positions
	
	# Update shader parameters
	update_shader_parameters()

func update_shader_parameters():
	# Update metaball parameters in the shader
	shader_material.set_shader_parameter("metaball_positions", metaball_positions)
	shader_material.set_shader_parameter("metaball_strengths", metaball_strengths)
	
	# Update light direction
	shader_material.set_shader_parameter("light_direction", Vector3(1.0, 0.5, 1.0).normalized())

# Public function to update the base strength
func set_strength(new_strength: float):
	base_strength = new_strength
	
	# Update all metaball strengths
	for i in range(metaball_strengths.size()):
		metaball_strengths[i] = base_strength
	
	# Update shader parameters
	update_shader_parameters()
	
	print("Updated metaball strength to:", base_strength)

# Reset metaballs with current parameters
func reset_metaballs():
	initialize_metaballs()

extends Node3D

# @identity
# essence: ray-marched metaball field — a fragment shader walks the camera ray through a box volume, sums radial-falloff contributions from N moving spheres, and renders where the field crosses an iso-threshold
# desire: to make the iso-surface visible without ever building a mesh — the surface is computed per-pixel, defined as the level set of a sum, and exists only on the screen
# critical_parameter: blend_factor — at low values metaballs stay distinct, at high values they merge into one organic mass; this is the smoothness of the implicit gluing
# triggers: animate_strength=true cycles each metaball's strength on its own phase; world_offset shifts the rendering volume in local space while the grid system handles world placement
# emerges: discrete spheres become a single continuous surface as their fields overlap — no mesh stitching, no marching cubes, just a function evaluated everywhere
# needs: ShaderMaterial [resolved], BoxMesh [resolved], DirectionalLight3D [resolved]
# relationships: implicit-surface counterpart to marching cubes — same iso level threshold concept but rendered (raymarching) rather than meshed (marching cubes); contrast with nakama_metaballs which is mesh-based
# truth: a surface does not need vertices to exist — a function plus a threshold is already a shape, and rendering is just asking that function where it equals zero

# Editable parameters
@export var metaball_count: int = 9
@export var min_strength: float = 0.8
@export var max_strength: float = 1.2
@export var blend_factor: float = 0.4
@export var metaball_color: Color = Color(0.2, 0.6, 1.0)
@export var animate_strength: bool = false
@export var base_strength: float = 1.0  # Base strength value for all metaballs
@export var world_offset: Vector3 = Vector3.ZERO  # Local offset (grid system handles world position)

# Internal variables
var cube_mesh: MeshInstance3D
var shader_material: ShaderMaterial
var metaball_positions = []
var metaball_strengths = []
var metaball_radii = []

func _ready() -> void:
	# Create a simple cube mesh for ray marching
	cube_mesh = MeshInstance3D.new()
	cube_mesh.mesh = BoxMesh.new()
	cube_mesh.mesh.size = Vector3(12.0, 12.0, 12.0)
	cube_mesh.position = world_offset
	add_child(cube_mesh)
	
	# Add light
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(light)
	
	# Load the shader
	shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://algorithms/proceduralgeneration/isosurfaces/implicitsurfacemodeling/metaballs/metaball.gdshader")
	
	# Apply to mesh
	cube_mesh.material_override = shader_material
	
	# Initialize metaballs
	initialize_metaballs()
	
	# Set shader parameters
	shader_material.set_shader_parameter("blend_factor", blend_factor)
	shader_material.set_shader_parameter("metaball_color", Vector3(
		metaball_color.r, metaball_color.g, metaball_color.b))
	
	print("Metaball setup complete with strength: ", base_strength)

func initialize_metaballs() -> void:
	# Clear existing arrays
	metaball_positions.clear()
	metaball_strengths.clear()
	metaball_radii.clear()
	
	# Get the world-space center of the box (available after _ready / add_child)
	var center = cube_mesh.global_position if cube_mesh.is_inside_tree() else world_offset
	
	# Initialize metaball positions and strengths
	for i in range(metaball_count):
		var radius = randf_range(0.5, 1.0)
		metaball_radii.append(radius)
		
		# Create Vector4 where xyz = world position, w = radius
		var position = Vector4(
			center.x + randf_range(-2.0, 2.0),
			center.y + randf_range(-2.0, 2.0),
			center.z + randf_range(-2.0, 2.0),
			radius
		)
		
		metaball_positions.append(position)
		metaball_strengths.append(base_strength)
	
	# Update shader parameters
	update_shader_parameters()

func _process(_delta):
	# Animate around the box's actual world position (works wherever the grid places us)
	var center = cube_mesh.global_position
	
	# Create new array for updated positions
	var updated_positions = []
	
	# Animate metaballs
	for i in range(metaball_count):
		var t = Time.get_ticks_msec() * 0.001
		
		# Create a new Vector4 for each position (Vector4 is immutable in Godot 4)
		var new_position = Vector4(
			center.x + sin(t * (0.3 + float(i) * 0.1) + i) * 2.0,
			center.y + cos(t * (0.2 + float(i) * 0.1) + i * 0.7) * 2.0,
			center.z + sin(t * (0.4 + float(i) * 0.05) + i * 1.3) * 2.0,
			metaball_radii[i]
		)
		
		updated_positions.append(new_position)
		
		# Optionally animate the strength
		if animate_strength:
			metaball_strengths[i] = base_strength + sin(t * 0.5 + i) * 0.3
	
	# Replace the array
	metaball_positions = updated_positions
	
	# Update shader parameters
	update_shader_parameters()

func update_shader_parameters() -> void:
	# Update metaball parameters in the shader
	shader_material.set_shader_parameter("metaball_positions", metaball_positions)
	shader_material.set_shader_parameter("metaball_strengths", metaball_strengths)
	
	# Update light direction
	shader_material.set_shader_parameter("light_direction", Vector3(1.0, 0.5, 1.0).normalized())

# Public function to update the base strength
func set_strength(new_strength: float) -> void:
	base_strength = new_strength
	
	# Update all metaball strengths
	for i in range(metaball_strengths.size()):
		metaball_strengths[i] = base_strength
	
	# Update shader parameters
	update_shader_parameters()
	
	print("Updated metaball strength to:", base_strength)

# Reset metaballs with current parameters
func reset_metaballs() -> void:
	initialize_metaballs()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass

extends MeshInstance3D

# Water material setup script
class_name WaterSurface

@export_group("Textures")
@export var flow_map: Texture2D
@export var noise_texture: Texture2D  
@export var derivative_height_texture: Texture2D

@export_group("Water Properties")
@export var water_color: Color = Color(0.306, 0.514, 0.663, 0.8)
@export var metallic: float = 0.0
@export var roughness: float = 0.5

@export_group("Flow Settings")
@export var flow_strength: float = 1.0
@export var flow_speed: float = 1.0  
@export var tiling: float = 1.0

@export_group("Underwater Fog")
@export var water_fog_color: Color = Color(0.306, 0.514, 0.663, 1.0)
@export var water_fog_density: float = 0.15

@export_group("Refraction")
@export var refraction_strength: float = 0.25

@export_group("Transparency")
@export var transparency_: float = 0.8
@export var depth_fade_distance: float = 2.0

var water_material: ShaderMaterial

func _ready():
	setup_water_material()

func setup_water_material():
	# Load the water shader
	var water_shader = load("res://commons/resourses/shaders/catwater.gdshader") # Adjust path as needed
	
	# Create shader material
	water_material = ShaderMaterial.new()
	water_material.shader = water_shader
	
	# Set material properties
	update_material_properties()
	
	# Apply material to mesh
	material_override = water_material
	
	# Setup mesh if not already set
	if mesh == null:
		var plane_mesh = PlaneMesh.new()
		plane_mesh.size = Vector2(10, 10)
		plane_mesh.subdivide_width = 32
		plane_mesh.subdivide_depth = 32
		mesh = plane_mesh

func update_material_properties():
	if water_material == null:
		return
		
	# Set textures
	if flow_map:
		water_material.set_shader_parameter("flow_map", flow_map)
	if noise_texture:
		water_material.set_shader_parameter("noise_texture", noise_texture)  
	if derivative_height_texture:
		water_material.set_shader_parameter("deriv_height_texture", derivative_height_texture)
	
	# Set water properties
	water_material.set_shader_parameter("water_color", water_color)
	water_material.set_shader_parameter("metallic", metallic)
	water_material.set_shader_parameter("roughness", roughness)
	
	# Set flow properties
	water_material.set_shader_parameter("flow_strength", flow_strength)
	water_material.set_shader_parameter("flow_speed", flow_speed)
	water_material.set_shader_parameter("tiling", tiling)
	
	# Set fog properties
	water_material.set_shader_parameter("water_fog_color", water_fog_color)
	water_material.set_shader_parameter("water_fog_density", water_fog_density)
	
	# Set refraction
	water_material.set_shader_parameter("refraction_strength", refraction_strength)
	
	# Set transparency
	water_material.set_shader_parameter("transparency", transparency)
	water_material.set_shader_parameter("depth_fade_distance", depth_fade_distance)

# Call this when you change properties at runtime
func _set_property_changed():
	update_material_properties()

# Example function to create flow map texture procedurally
func create_simple_flow_map(size: int = 512) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RG8)
	
	for y in range(size):
		for x in range(size):
			# Simple radial flow pattern
			var center = Vector2(size * 0.5, size * 0.5)
			var pos = Vector2(x, y)
			var direction = (pos - center).normalized()
			
			# Convert direction to 0-1 range for texture
			var flow_r = (direction.x + 1.0) * 0.5
			var flow_g = (direction.y + 1.0) * 0.5
			
			image.set_pixel(x, y, Color(flow_r, flow_g, 0, 1))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# Example function to create derivative height texture
func create_simple_derivative_height_texture(size: int = 512) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = 12345
	noise.frequency = 0.1
	
	for y in range(size):
		for x in range(size):
			# Generate height using noise
			var height = noise.get_noise_2d(x, y) * 0.5 + 0.5
			
			# Calculate derivatives (simplified)
			var dx = 0.0
			var dy = 0.0
			if x > 0 and x < size - 1:
				dx = (noise.get_noise_2d(x + 1, y) - noise.get_noise_2d(x - 1, y)) * 0.5
			if y > 0 and y < size - 1:
				dy = (noise.get_noise_2d(x, y + 1) - noise.get_noise_2d(x, y - 1)) * 0.5
			
			# Pack into RGBA (derivatives in RG, height in B, strength in A)
			image.set_pixel(x, y, Color(
				dx * 0.5 + 0.5,  # R: X derivative
				dy * 0.5 + 0.5,  # G: Y derivative  
				height,          # B: Height
				1.0             # A: Strength multiplier
			))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

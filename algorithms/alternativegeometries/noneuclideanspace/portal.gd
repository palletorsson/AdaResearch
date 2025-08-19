# portal.gd
class_name Portal
extends Area3D

@export var linked_portal_path: NodePath
@export var portal_color: Color = Color(0.0, 0.4, 1.0, 0.5)
@export var portal_width: float = 2.0
@export var portal_height: float = 3.0
@export var two_way: bool = true

var linked_portal: Portal
var portal_mesh: MeshInstance3D
var portal_material: Material  # Changed from ShaderMaterial to Material base class

func _ready():
	# Set up collisions
	collision_layer = 2  # Portal layer
	collision_mask = 1   # Player layer
	
	# Add to portal group
	add_to_group("portals")
	
	# Create the portal visuals
	create_portal_visuals()
	
	# Link to another portal if specified
	if !linked_portal_path.is_empty():
		linked_portal = get_node(linked_portal_path)
		
		# If two-way and the linked portal doesn't link back, set it up
		if two_way and linked_portal and linked_portal.linked_portal != self:
			linked_portal.linked_portal = self

func create_portal_visuals():
	# Create portal mesh
	var portal_shape = BoxMesh.new()
	portal_shape.size = Vector3(portal_width, portal_height, 0.1)
	
	portal_mesh = MeshInstance3D.new()
	portal_mesh.name = "PortalMesh"
	portal_mesh.mesh = portal_shape
	add_child(portal_mesh)
	
	# Load shader resource - make sure the shader file exists at this path
	var shader_resource = load("res://algorithms/alternativegeometries/noneuclideanspace/portalShader.gdshader")
	
	if shader_resource:
		# Create portal material with custom shader
		var shader_material = ShaderMaterial.new()
		shader_material.shader = shader_resource
		shader_material.set_shader_parameter("portal_color", portal_color)
		portal_material = shader_material
	else:
		# Fallback to standard material if shader not found
		var std_material = StandardMaterial3D.new()
		std_material.albedo_color = portal_color
		std_material.emission_enabled = true
		std_material.emission = portal_color
		std_material.emission_energy = 1.5
		portal_material = std_material
	
	portal_mesh.material_override = portal_material
	
	# Create collision shape
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "PortalCollision"
	var shape = BoxShape3D.new()
	shape.size = Vector3(portal_width, portal_height, 0.5)
	collision_shape.shape = shape
	add_child(collision_shape)

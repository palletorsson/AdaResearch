# recursive_room.gd
class_name RecursiveRoom
extends Node3D

# Configuration
@export var room_size: Vector3 = Vector3(4, 3, 4)
@export var room_color: Color = Color(0.7, 0.7, 0.9)
@export var recursion_depth: int = 3
@export var scale_factor: float = 0.3
@export var portal_width: float = 1.5
@export var portal_height: float = 2.0

# Runtime variables
var wall_thickness: float = 0.1
var inner_rooms = []
var portals = []

func _ready():
	# Create the main room
	_create_room(0, Vector3.ONE, Vector3.ZERO)

func _create_room(depth: int, scale_vec: Vector3, position_offset: Vector3):
	var room_node = Node3D.new()
	room_node.name = "Room_Depth_" + str(depth)
	room_node.scale = scale_vec
	room_node.position = position_offset
	add_child(room_node)
	
	if depth == 0:
		# This is the main outer room
		inner_rooms.append(room_node)
	
	# Create the basic room structure
	_create_room_geometry(room_node, depth)
	
	# If we haven't reached max recursion depth, create more inner rooms
	if depth < recursion_depth:
		# Calculate the scale and position for the next level
		var next_scale = scale_vec * scale_factor
		
		# Create portals in each wall that lead to recursive rooms
		_create_recursive_portal(room_node, depth, Vector3(0, 0, -room_size.z/2), Vector3(0, 0, -1), next_scale) # North
		_create_recursive_portal(room_node, depth, Vector3(0, 0, room_size.z/2), Vector3(0, 0, 1), next_scale)   # South
		_create_recursive_portal(room_node, depth, Vector3(-room_size.x/2, 0, 0), Vector3(-1, 0, 0), next_scale) # West
		_create_recursive_portal(room_node, depth, Vector3(room_size.x/2, 0, 0), Vector3(1, 0, 0), next_scale)   # East

func _create_room_geometry(room_node: Node3D, depth: int):
	# Create the room walls
	var walls = CSGBox3D.new()
	walls.name = "Walls"
	walls.size = room_size
	
	var material = StandardMaterial3D.new()
	material.albedo_color = room_color.lightened(depth * 0.1)  # Lighter color for deeper rooms
	walls.material = material
	
	# Hollow out the room
	var inner_cutout = CSGBox3D.new()
	inner_cutout.name = "InnerCutout"
	inner_cutout.size = Vector3(
		room_size.x - wall_thickness * 2,
		room_size.y - wall_thickness * 2,
		room_size.z - wall_thickness * 2
	)
	inner_cutout.operation = CSGBox3D.OPERATION_SUBTRACTION
	walls.add_child(inner_cutout)
	
	# Add static body for collisions
	var static_body = StaticBody3D.new()
	static_body.name = "WallCollisions"
	room_node.add_child(static_body)
	
	# Create wall collisions
	_create_wall_collision(static_body, "Floor", Vector3(0, -room_size.y/2 + wall_thickness/2, 0), Vector3(room_size.x, wall_thickness, room_size.z))
	_create_wall_collision(static_body, "Ceiling", Vector3(0, room_size.y/2 - wall_thickness/2, 0), Vector3(room_size.x, wall_thickness, room_size.z))
	_create_wall_collision(static_body, "WallN", Vector3(0, 0, -room_size.z/2 + wall_thickness/2), Vector3(room_size.x, room_size.y, wall_thickness))
	_create_wall_collision(static_body, "WallS", Vector3(0, 0, room_size.z/2 - wall_thickness/2), Vector3(room_size.x, room_size.y, wall_thickness))
	_create_wall_collision(static_body, "WallE", Vector3(room_size.x/2 - wall_thickness/2, 0, 0), Vector3(wall_thickness, room_size.y, room_size.z))
	_create_wall_collision(static_body, "WallW", Vector3(-room_size.x/2 + wall_thickness/2, 0, 0), Vector3(wall_thickness, room_size.y, room_size.z))
	
	room_node.add_child(walls)
	
	# Add some visual elements to distinguish each recursive level
	var indicator = MeshInstance3D.new()
	indicator.name = "DepthIndicator"
	var indicator_mesh = SphereMesh.new()
	indicator_mesh.radius = 0.2
	indicator_mesh.height = 0.4
	indicator.mesh = indicator_mesh
	
	var indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = Color(1.0, 0.3, 0.3)
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(1.0, 0.3, 0.3)
	indicator_material.emission_energy = depth + 1.0
	indicator.material_override = indicator_material
	
	indicator.position = Vector3(0, 0, 0)
	room_node.add_child(indicator)
	
	# Add text label showing recursion depth
	var label = Label3D.new()
	label.text = "Depth: " + str(depth)
	label.font_size = 16
	label.billboard = true
	label.position = Vector3(0, room_size.y/2 - 0.5, 0)
	room_node.add_child(label)

func _create_wall_collision(parent: Node, name: String, position: Vector3, size: Vector3):
	var collision = CollisionShape3D.new()
	collision.name = name
	collision.transform.origin = position
	
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	
	parent.add_child(collision)

func _create_recursive_portal(parent: Node3D, current_depth: int, position: Vector3, normal: Vector3, next_scale: Vector3):
	# Create a portal in the wall
	var portal_cutout = CSGBox3D.new()
	portal_cutout.name = "PortalCutout_" + str(current_depth) + "_" + str(position)
	portal_cutout.size = Vector3(portal_width, portal_height, wall_thickness * 2)
	portal_cutout.position = position
	
	# Orient the portal cutout properly
	if abs(normal.x) > 0.5:
		portal_cutout.rotation.y = PI / 2
	
	portal_cutout.operation = CSGBox3D.OPERATION_SUBTRACTION
	parent.get_node("Walls").add_child(portal_cutout)
	
	# Create a visual portal effect
	var portal_visual = MeshInstance3D.new()
	portal_visual.name = "PortalVisual"
	var portal_mesh = QuadMesh.new()
	portal_mesh.size = Vector2(portal_width, portal_height)
	portal_visual.mesh = portal_mesh
	
	# Face the portal correctly
	portal_visual.position = position + normal * 0.01 # Offset slightly to avoid z-fighting
	
	if normal.z < 0:
		portal_visual.rotation.y = PI
	elif normal.x > 0:
		portal_visual.rotation.y = -PI / 2
	elif normal.x < 0:
		portal_visual.rotation.y = PI / 2
	
	# Create a material for the portal
	var portal_material = ShaderMaterial.new()
	
	# Try to load the shader
	var shader_resource = load("res://algorithms/alternativegeometries/noneuclideanspace/portalShader.gdshader")
	if shader_resource:
		portal_material.shader = shader_resource
		portal_material.set_shader_parameter("portal_color", Color(0.3, 0.7, 0.8, 0.7))
	else:
		# Fallback material
		var std_material = StandardMaterial3D.new()
		std_material.albedo_color = Color(0.3, 0.7, 0.8, 0.7)
		std_material.emission_enabled = true
		std_material.emission = Color(0.3, 0.7, 0.8)
		std_material.emission_energy = 1.0
		std_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		portal_material = std_material
	
	portal_visual.material_override = portal_material
	parent.add_child(portal_visual)
	portals.append(portal_visual)
	
	# Create a trigger area for the portal
	var portal_area = Area3D.new()
	portal_area.name = "PortalTrigger_" + str(current_depth)
	
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(portal_width, portal_height, 0.5)
	collision_shape.shape = box_shape
	portal_area.add_child(collision_shape)
	
	portal_area.position = position
	
	# Orient the collision properly
	if normal.z < 0:
		portal_area.rotation.y = PI
	elif normal.x > 0:
		portal_area.rotation.y = -PI / 2
	elif normal.x < 0:
		portal_area.rotation.y = PI / 2
	
	# Connect signals
	portal_area.body_entered.connect(_on_portal_entered.bind(current_depth, normal, next_scale))
	parent.add_child(portal_area)
	
	# Create the actual next level recursive room
	var next_position = position + normal * (room_size.z * scale_factor * 2)
	_create_room(current_depth + 1, next_scale, next_position)

func _on_portal_entered(body: Node3D, depth: int, normal: Vector3, next_scale: Vector3):
	if body is XROrigin3D:
		print("Player entered portal at depth: " + str(depth))
		
		# Create the teleport effect
		_teleport_player(body, depth, normal, next_scale)

func _teleport_player(player: XROrigin3D, depth: int, normal: Vector3, next_scale: Vector3):
	# Calculate the destination position
	var destination = normal * (room_size.z * scale_factor * 1.5)
	
	# Scale the player
	var current_scale = player.scale
	player.scale = current_scale * scale_factor
	
	# Move the player to the destination
	player.global_position += destination
	
	# Apply a slight velocity in the direction of travel to prevent getting stuck
	# Note: This assumes the player has a CharacterBody3D component or similar
	if player.has_method("apply_impulse"):
		player.apply_impulse(normal * 2.0)

# This method can be called to reset the player to the original room
func reset_player(player: XROrigin3D):
	player.scale = Vector3.ONE
	player.global_position = global_position + Vector3(0, 1, 0)

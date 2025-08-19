# non_euclidean_room.gd
class_name NonEuclideanRoom
extends Node3D

@export var room_size: Vector3 = Vector3(5, 3, 5)
@export var room_color: Color = Color(0.8, 0.8, 0.8)
@export var inner_bigger_than_outer: bool = false
@export var size_multiplier: float = 2.0

var room_mesh: MeshInstance3D
var wall_thickness: float = 0.1

func _ready():
	# Create the room mesh
	if inner_bigger_than_outer:
		_create_bigger_inside_room()
	else:
		_create_normal_room()

func _create_normal_room():
	# Create a simple box room
	room_mesh = MeshInstance3D.new()
	room_mesh.name = "RoomMesh"
	
	var material = StandardMaterial3D.new()
	material.albedo_color = room_color
	material.roughness = 0.7
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = room_size
	room_mesh.mesh = box_mesh
	room_mesh.material_override = material
	
	# Create inner box to hollow it out
	var inner_mesh = CSGBox3D.new()
	inner_mesh.name = "InnerCutout"
	inner_mesh.size = Vector3(
		room_size.x - wall_thickness * 2,
		room_size.y - wall_thickness * 2,
		room_size.z - wall_thickness * 2
	)
	inner_mesh.operation = CSGBox3D.OPERATION_SUBTRACTION
	
	# Add collisions for the walls
	_add_wall_collisions()
	
	# Add room to tree
	add_child(room_mesh)
	room_mesh.add_child(inner_mesh)

func _create_bigger_inside_room():
	# Create the outer shell
	var outer_shell = CSGBox3D.new()
	outer_shell.name = "OuterShell"
	outer_shell.size = room_size
	
	var material = StandardMaterial3D.new()
	material.albedo_color = room_color
	material.roughness = 0.7
	outer_shell.material = material
	
	# Create the inner room (which appears when inside)
	var inner_room = CSGBox3D.new()
	inner_room.name = "InnerRoom"
	inner_room.size = room_size * size_multiplier
	inner_room.visible = false  # Only visible once player is inside
	inner_room.material = material
	
	# Add triggers for the effect
	var trigger_area = Area3D.new()
	trigger_area.name = "RoomTrigger"
	
	var trigger_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(
		room_size.x - wall_thickness * 2,
		room_size.y - wall_thickness * 2,
		room_size.z - wall_thickness * 2
	)
	trigger_shape.shape = box_shape
	trigger_area.add_child(trigger_shape)
	
	# Connect signals
	trigger_area.body_entered.connect(_on_player_entered)
	trigger_area.body_exited.connect(_on_player_exited)
	
	# Add everything to tree
	add_child(outer_shell)
	add_child(inner_room)
	add_child(trigger_area)
	
	# Add collisions for the walls
	_add_wall_collisions()

func _add_wall_collisions():
	# Add a static body for collisions
	var static_body = StaticBody3D.new()
	static_body.name = "WallCollisions"
	add_child(static_body)
	
	# Create wall collisions
	_create_wall_collision(static_body, "Floor", Vector3(0, -room_size.y/2 + wall_thickness/2, 0), Vector3(room_size.x, wall_thickness, room_size.z))
	_create_wall_collision(static_body, "Ceiling", Vector3(0, room_size.y/2 - wall_thickness/2, 0), Vector3(room_size.x, wall_thickness, room_size.z))
	_create_wall_collision(static_body, "WallN", Vector3(0, 0, -room_size.z/2 + wall_thickness/2), Vector3(room_size.x, room_size.y, wall_thickness))
	_create_wall_collision(static_body, "WallS", Vector3(0, 0, room_size.z/2 - wall_thickness/2), Vector3(room_size.x, room_size.y, wall_thickness))
	_create_wall_collision(static_body, "WallE", Vector3(room_size.x/2 - wall_thickness/2, 0, 0), Vector3(wall_thickness, room_size.y, room_size.z))
	_create_wall_collision(static_body, "WallW", Vector3(-room_size.x/2 + wall_thickness/2, 0, 0), Vector3(wall_thickness, room_size.y, room_size.z))

func _create_wall_collision(parent: Node, name: String, position: Vector3, size: Vector3):
	var collision = CollisionShape3D.new()
	collision.name = name
	collision.transform.origin = position
	
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	
	parent.add_child(collision)

func _on_player_entered(body: Node3D):
	if body is XROrigin3D:
		# When player enters, swap visibility
		var outer_shell = get_node("OuterShell")
		var inner_room = get_node("InnerRoom")
		
		outer_shell.visible = false
		inner_room.visible = true

func _on_player_exited(body: Node3D):
	if body is XROrigin3D:
		# When player exits, restore original visuals
		var outer_shell = get_node("OuterShell")
		var inner_room = get_node("InnerRoom")
		
		outer_shell.visible = true
		inner_room.visible = false

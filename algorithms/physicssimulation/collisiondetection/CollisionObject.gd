extends Node3D

class_name CollisionObject

@export var object_type: String = "sphere"
@export var object_color: Color = Color.WHITE
@export var initial_position: Vector3 = Vector3.ZERO
@export var initial_velocity: Vector3 = Vector3.ZERO

var velocity: Vector3
var object_size: Vector3 = Vector3(0.5, 0.5, 0.5)

func _ready():
	_create_object_mesh()

func _create_object_mesh():
	var mesh: CSGShape3D
	
	match object_type:
		"sphere":
			mesh = CSGSphere3D.new()
			mesh.radius = 0.5
			object_size = Vector3(1, 1, 1)
		"cube":
			mesh = CSGBox3D.new()
			mesh.size = Vector3(1, 1, 1)
			object_size = Vector3(1, 1, 1)
		_:
			mesh = CSGSphere3D.new()
			mesh.radius = 0.5
			object_size = Vector3(1, 1, 1)
	
	mesh.material = StandardMaterial3D.new()
	mesh.material.albedo_color = object_color
	mesh.material.emission_enabled = true
	mesh.material.emission = object_color * 0.2
	
	add_child(mesh)

func initialize():
	position = initial_position
	velocity = initial_velocity

func update_physics(delta: float):
	# Simple physics update
	position += velocity * delta
	
	# Bounce off walls
	var bounds = Vector3(7.5, 10, 7.5)
	var half_size = object_size / 2
	
	if abs(position.x) > bounds.x - half_size.x:
		position.x = sign(position.x) * (bounds.x - half_size.x)
		velocity.x = -velocity.x * 0.8
	
	if abs(position.z) > bounds.z - half_size.z:
		position.z = sign(position.z) * (bounds.z - half_size.z)
		velocity.z = -velocity.z * 0.8
	
	if position.y < half_size.y:
		position.y = half_size.y
		velocity.y = -velocity.y * 0.8
	elif position.y > bounds.y - half_size.y:
		position.y = bounds.y - half_size.y
		velocity.y = -velocity.y * 0.8

func get_size() -> Vector3:
	return object_size

func reset_to_initial():
	position = initial_position
	velocity = initial_velocity

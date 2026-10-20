@tool
extends Node3D

# Modern Chair: Sleek, minimalist design using primitives

@export var seat_color: Color = Color(0.2, 0.2, 0.2)
@export var leg_color: Color = Color(0.8, 0.8, 0.8)

func _ready():
	_build_chair()

func _build_chair():
	# Clear existing children (for tool mode updates)
	for child in get_children():
		child.queue_free()
		
	# 1. Legs (Thin Cylinders)
	_create_leg(Vector3(-0.2, 0.2, -0.2)) # Front Left
	_create_leg(Vector3(0.2, 0.2, -0.2))  # Front Right
	_create_leg(Vector3(-0.2, 0.2, 0.2))  # Back Left
	_create_leg(Vector3(0.2, 0.2, 0.2))   # Back Right
	
	# 2. Seat (Rounded Box)
	var seat = MeshInstance3D.new()
	var seat_mesh = BoxMesh.new()
	seat_mesh.size = Vector3(0.5, 0.05, 0.5)
	seat.mesh = seat_mesh
	seat.position = Vector3(0, 0.425, 0) # Top of legs (0.4) + half thickness
	
	var seat_mat = StandardMaterial3D.new()
	seat_mat.albedo_color = seat_color
	seat_mat.roughness = 0.5
	seat.material_override = seat_mat
	add_child(seat)
	
	# 3. Backrest (Curved or Angled)
	var back = MeshInstance3D.new()
	var back_mesh = BoxMesh.new()
	back_mesh.size = Vector3(0.5, 0.4, 0.05)
	back.mesh = back_mesh
	# Position: Back edge of seat, angle slightly back
	back.position = Vector3(0, 0.65, 0.22) 
	back.rotation_degrees.x =  10
	
	back.material_override = seat_mat # Match seat
	add_child(back)
	
	# Collision
	var body = StaticBody3D.new()
	add_child(body)
	var seat_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.5, 0.6, 0.6) # Approximate Bounds
	seat_shape.shape = box
	seat_shape.position = Vector3(0, 0.3, 0)
	body.add_child(seat_shape)

func _create_leg(pos: Vector3):
	var leg = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.015
	mesh.height = 0.4
	leg.mesh = mesh
	leg.position = pos
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = leg_color
	mat.metallic = 0.8
	mat.roughness = 0.2
	leg.material_override = mat
	
	add_child(leg)

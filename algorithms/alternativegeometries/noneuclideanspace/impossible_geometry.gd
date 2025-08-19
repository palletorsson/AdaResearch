# impossible_geometry.gd
class_name ImpossibleGeometry
extends Node3D

@export var impossible_angle: float = 60.0
@export var corridor_length: float = 10.0
@export var corridor_width: float = 2.0
@export var corridor_height: float = 3.0

func _ready():
	# Create an impossible corridor (4 turns but returns to start)
	_create_impossible_corridor()

func _create_impossible_corridor():
	var corridors = []
	var turns = 4
	var angle_per_turn = impossible_angle
	
	for i in range(turns):
		var corridor = _create_corridor_segment()
		corridor.rotate_y(deg_to_rad(angle_per_turn * i))
		corridor.translate(Vector3(0, 0, -corridor_length/2).rotated(Vector3.UP, deg_to_rad(angle_per_turn * i)))
		corridors.append(corridor)
		add_child(corridor)
	
	# Place portals at the junction points
	for i in range(turns):
		var next_i = (i + 1) % turns
		
		var exit_pos = corridors[i].global_position + Vector3(0, 0, corridor_length/2).rotated(Vector3.UP, corridors[i].global_rotation.y)
		var entry_pos = corridors[next_i].global_position + Vector3(0, 0, -corridor_length/2).rotated(Vector3.UP, corridors[next_i].global_rotation.y)
		
		_create_portal_pair(
			exit_pos, 
			Quaternion.from_euler(Vector3(0, corridors[i].global_rotation.y, 0)),
			entry_pos,
			Quaternion.from_euler(Vector3(0, corridors[next_i].global_rotation.y, 0))
		)

func _create_corridor_segment() -> Node3D:
	var corridor = Node3D.new()
	corridor.name = "CorridorSegment"
	
	# Floor
	var floor = MeshInstance3D.new()
	floor.name = "Floor"
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(corridor_width, 0.1, corridor_length)
	floor.mesh = floor_mesh
	floor.translate(Vector3(0, -corridor_height/2, 0))
	corridor.add_child(floor)
	
	# Ceiling
	var ceiling = MeshInstance3D.new()
	ceiling.name = "Ceiling"
	var ceiling_mesh = BoxMesh.new() 
	ceiling_mesh.size = Vector3(corridor_width, 0.1, corridor_length)
	ceiling.mesh = ceiling_mesh
	ceiling.translate(Vector3(0, corridor_height/2, 0))
	corridor.add_child(ceiling)
	
	# Walls
	var left_wall = MeshInstance3D.new()
	left_wall.name = "LeftWall"
	var left_wall_mesh = BoxMesh.new()
	left_wall_mesh.size = Vector3(0.1, corridor_height, corridor_length)
	left_wall.mesh = left_wall_mesh
	left_wall.translate(Vector3(-corridor_width/2, 0, 0))
	corridor.add_child(left_wall)
	
	var right_wall = MeshInstance3D.new()
	right_wall.name = "RightWall"
	var right_wall_mesh = BoxMesh.new()
	right_wall_mesh.size = Vector3(0.1, corridor_height, corridor_length)
	right_wall.mesh = right_wall_mesh
	right_wall.translate(Vector3(corridor_width/2, 0, 0))
	corridor.add_child(right_wall)
	
	# Add materials
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.8)
	floor.material_override = material
	ceiling.material_override = material
	left_wall.material_override = material
	right_wall.material_override = material
	
	# Add collisions
	var static_body = StaticBody3D.new()
	static_body.name = "Collisions"
	corridor.add_child(static_body)
	
	var floor_col = CollisionShape3D.new()
	var floor_shape = BoxShape3D.new()
	floor_shape.size = floor_mesh.size
	floor_col.shape = floor_shape
	floor_col.transform = floor.transform
	static_body.add_child(floor_col)
	
	var ceiling_col = CollisionShape3D.new()
	var ceiling_shape = BoxShape3D.new()
	ceiling_shape.size = ceiling_mesh.size
	ceiling_col.shape = ceiling_shape
	ceiling_col.transform = ceiling.transform
	static_body.add_child(ceiling_col)
	
	var left_col = CollisionShape3D.new()
	var left_shape = BoxShape3D.new()
	left_shape.size = left_wall_mesh.size
	left_col.shape = left_shape
	left_col.transform = left_wall.transform
	static_body.add_child(left_col)
	
	var right_col = CollisionShape3D.new()
	var right_shape = BoxShape3D.new()
	right_shape.size = right_wall_mesh.size
	right_col.shape = right_shape
	right_col.transform = right_wall.transform
	static_body.add_child(right_col)
	
	return corridor

func _create_portal_pair(pos1: Vector3, rot1: Quaternion, pos2: Vector3, rot2: Quaternion):
	var portal1 = Portal.new()
	portal1.name = "Portal1"
	portal1.transform.origin = pos1
	portal1.transform.basis = Basis(rot1)
	
	var portal2 = Portal.new()
	portal2.name = "Portal2"
	portal2.transform.origin = pos2
	portal2.transform.basis = Basis(rot2)
	
	# Link the portals to each other
	portal1.linked_portal = portal2
	portal2.linked_portal = portal1
	
	add_child(portal1)
	add_child(portal2)

# CorridorGenerator.gd
# Generates a procedural corridor using MultiMeshInstance3D
# Dimensions: 3m Wide, 4m High, 6m Deep
# Coordinates: Z from -5 to 0. X from -1 to 1. Y from 0 to 3.

@tool
extends Node3D
class_name CorridorGenerator

@export var cube_scene: PackedScene
@export var regenerate: bool = false:
	set(value):
		_generate()

@export var position_offset: Vector3 = Vector3(1, 0, -1)

# Dimensions
@export var grid_width: int = 3
@export var grid_height: int = 6
@export var grid_depth: int = 6
@export var cube_size: float = 1.0

# MultiMesh
var multimesh_instance: MultiMeshInstance3D
var collision_parent: Node3D

func _ready():
	_generate()

func _generate():
	_clear()
	
	if not cube_scene:
		print("CorridorGenerator: No cube scene assigned")
		return

	# Create Containers
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.name = "CorridorMultiMesh"
	add_child(multimesh_instance)
	
	collision_parent = Node3D.new()
	collision_parent.name = "CorridorCollisions"
	add_child(collision_parent)

	# Extract Mesh from Template
	var temp_node = cube_scene.instantiate()
	var mesh_instance = _find_mesh_instance(temp_node)
	
	if not mesh_instance:
		print("CorridorGenerator: Could not find mesh in cube scene")
		temp_node.queue_free()
		return
		
	# Setup MultiMesh
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh_instance.mesh
	multimesh.use_colors = true
	# Set huge custom AABB to prevent culling issues with procedural generation
	multimesh.custom_aabb = AABB(Vector3(-1000, -1000, -1000), Vector3(2000, 2000, 2000))
	multimesh.visible_instance_count = -1
	multimesh_instance.multimesh = multimesh
	multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	# Apply Material - use simple material for MultiMesh compatibility
	# (Shader materials often don't work with MultiMesh instancing)
	var corridor_material = StandardMaterial3D.new()
	corridor_material.albedo_color = Color(0.15, 0.15, 0.18, 1.0)  # Dark gray
	corridor_material.metallic = 0.1
	corridor_material.roughness = 0.8
	multimesh_instance.material_override = corridor_material

	temp_node.queue_free()
	
	# Calculate Position List
	var transforms: Array[Transform3D] = []
	
	# Iterate coordinates
	# X: -1, 0, 1
	# Y: 0, 1, 2, 3
	# Z: -5, -4, -3, -2, -1, 0
	
	for z in range(-grid_depth + 1, 1): # -5 to 0
		for x in range(-(grid_width-1)/2, (grid_width-1)/2 + 1): # -1 to 1
			for y in range(grid_height): # 0 to 3
				
				# Determine if we should place a block
				# Floor: y == 0
				# Ceiling: y == grid_height - 1
				# Walls: x == min or x == max
				
				var is_floor = (y == 0)
				var is_ceiling = (y == grid_height - 1)
				var is_wall = (x == -1 or x == 1) # Assumes width 3 for now, logic below handles others?
				
				# Dynamic wall check based on width
				if grid_width > 1:
					var half_width = (grid_width - 1) / 2
					is_wall = (x == -half_width or x == half_width)
				else:
					is_wall = true # 1 wide is all wall? or no wall? Let's keep simple.
				
				# Place blocks only on boundary (tunnel)
				if is_floor or is_ceiling or is_wall:
					
					# Don't ensure walkability on z=0 at center? 
					# User said "3 units wide, meaning 1 walkable units wide"
					# So x=-1 is wall, x=1 is wall, x=0 is empty space.
					# y=0 is floor, y=3 is ceiling.
					
					var pos = Vector3(x, y, z) + position_offset
					var t = Transform3D()
					t.origin = pos * cube_size
					transforms.append(t)
					
					_create_collision(pos * cube_size)

	# Apply instances
	multimesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multimesh.set_instance_transform(i, transforms[i])
		multimesh.set_instance_color(i, Color.WHITE) # Can customize later

	print("CorridorGenerator: Created corridor with %d blocks" % transforms.size())

func _create_collision(pos: Vector3):
	var static_body = StaticBody3D.new()
	static_body.position = pos
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1, 1, 1) * cube_size
	col.shape = shape
	
	static_body.add_child(col)
	collision_parent.add_child(static_body)

func _clear():
	for child in get_children():
		child.queue_free()

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var res = _find_mesh_instance(child)
		if res: return res
	return null

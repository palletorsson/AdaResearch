# CorridorGenerator.gd
# Generates a procedural entrance room/corridor using MultiMeshInstance3D
# Can be narrow corridor (3 wide) or entrance room (5 wide with narrow exit)
#
# Entrance Room Layout (from above):
#   ["5", "1", "1", "1", "5"],  # Back wall (entrance)
#   ["5", "1", "1", "1", "5"],  # Room
#   ["5", "1", "1", "1", "5"],  # Room
#   ["5", "1", "1", "1", "5"],  # Room
#   ["5", "1", "1", "1", "5"],  # Room
#   ["5", "1", "5", "5", "5"],  # Exit - narrow 1-wide passage to Lab

@tool
extends Node3D
class_name CorridorGenerator

@export var cube_scene: PackedScene
@export var regenerate: bool = false:
	set(value):
		_generate()

@export var position_offset: Vector3 = Vector3(1, 0, -1)

# Entrance text
@export var show_entrance_text: bool = true
@export_multiline var entrance_text: String = "THE\nREAL"

# Room mode
@export_enum("Corridor:0", "EntranceRoom:1") var room_mode: int = 1

# Dimensions
@export var grid_width: int = 5  # 5 for entrance room, 3 for corridor
@export var grid_height: int = 6
@export var grid_depth: int = 6
@export var cube_size: float = 1.0

# Exit width (only center cells open at z=0)
@export var exit_width: int = 1  # 1 = only center open, 3 = full width open

# Closing walls
@export var close_back_wall: bool = true  # Close the entrance (z = -grid_depth + 1)
@export var close_front_wall: bool = false  # Close the exit (z = 0)

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
	var corridor_material = StandardMaterial3D.new()
	corridor_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)  # Pure white
	corridor_material.metallic = 0.0
	corridor_material.roughness = 0.3
	# Add emission for bright glowing effect
	corridor_material.emission_enabled = true
	corridor_material.emission = Color(1.0, 1.0, 1.0)  # White emission
	corridor_material.emission_energy_multiplier = 0.8  # Bright but not blinding
	multimesh_instance.material_override = corridor_material

	temp_node.queue_free()

	# Calculate Position List
	var transforms: Array[Transform3D] = []

	var half_width = (grid_width - 1) / 2  # For width 5: -2, -1, 0, 1, 2
	var half_exit = (exit_width - 1) / 2   # For exit 1: only 0

	for z in range(-grid_depth + 1, 1):  # -5 to 0
		for x in range(-half_width, half_width + 1):  # -2 to 2 for width 5
			for y in range(grid_height):  # 0 to 5

				# Determine if we should place a block
				var is_floor = (y == 0)
				var is_ceiling = (y == grid_height - 1)
				var is_wall = (x == -half_width or x == half_width)

				# Check for back wall (entrance)
				var is_back_wall = close_back_wall and (z == -grid_depth + 1)

				# Check for front wall (exit) - with narrow opening
				var is_front_wall = false
				if z == 0:
					# At exit row: only block cells outside the exit width
					var is_in_exit = (x >= -half_exit and x <= half_exit)
					if not is_in_exit:
						# Block this cell (wall around the narrow exit)
						is_front_wall = true

				# Place blocks on boundaries
				if is_floor or is_ceiling or is_wall or is_back_wall or is_front_wall:
					var pos = Vector3(x, y, z) + position_offset
					var t = Transform3D()
					t.origin = pos * cube_size
					transforms.append(t)
					_create_collision(pos * cube_size)

	# Apply instances
	multimesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multimesh.set_instance_transform(i, transforms[i])
		multimesh.set_instance_color(i, Color.WHITE)

	# Add entrance text
	if show_entrance_text:
		_create_entrance_text()

	print("CorridorGenerator: Created entrance room with %d blocks (width=%d, exit_width=%d)" % [transforms.size(), grid_width, exit_width])

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


func _create_entrance_text():
	# Create 3D text at the back wall of the entrance room
	var label = Label3D.new()
	label.name = "EntranceText"
	label.text = entrance_text
	label.font_size = 128
	label.pixel_size = 0.01
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Position in the middle of the room (around row 3 of 6)
	# Room spans z from -grid_depth+1 to 0, middle is around -grid_depth/2
	var text_z = (-grid_depth / 2.0) * cube_size + position_offset.z * cube_size
	var text_x = position_offset.x * cube_size
	var text_y = (grid_height / 2.0) * cube_size
	label.position = Vector3(text_x, text_y, text_z)

	# Rotate to face into the room (towards positive Z)
	label.rotation_degrees = Vector3(0, 0, 0)

	# Style - dark text on bright corridor
	label.modulate = Color(0.1, 0.1, 0.12)
	label.outline_modulate = Color(0.2, 0.2, 0.25)
	label.outline_size = 8

	# No shadow, billboard disabled
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.no_depth_test = false
	label.double_sided = true

	add_child(label)

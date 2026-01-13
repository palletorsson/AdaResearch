# LabChair.gd - Low-polygon office chair with octagonal seat/backrest and five-spoke base
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

var base_color: Color = Color(0.5, 0.5, 0.5)  # Gray
var armrest_color: Color = Color(0.7, 0.7, 0.7)  # Light gray/silver
var base_color_metal: Color = Color(0.8, 0.8, 0.8)  # Silver for base

var chair_scale: float = 0.5  # Overall scale
var seat_height: float = 0.4
var backrest_height: float = 0.6
var armrest_height: float = 0.25

var _mesh_instances: Array[MeshInstance3D] = []

func _ready():
	_build_lab_chair()

func _build_lab_chair() -> void:
	_teardown()
	
	# Build seat (octagonal)
	_build_octagonal_seat()
	
	# Build backrest (octagonal)
	_build_octagonal_backrest()
	
	# Build armrests (rectangular)
	_build_armrests()
	
	# Build five-spoke base
	_build_five_spoke_base()
	
	# Build wheels
	_build_wheels()

func _teardown() -> void:
	for mesh_instance in _mesh_instances:
		if mesh_instance and is_instance_valid(mesh_instance):
			if mesh_instance.get_parent() == self:
				remove_child(mesh_instance)
			mesh_instance.queue_free()
	_mesh_instances.clear()

func _build_octagonal_seat() -> void:
	var vertices = _create_octagon_vertices(0.3 * chair_scale, seat_height * chair_scale, 0.02 * chair_scale)
	var faces = _create_octagon_faces()
	var material = GridMaterialFactory.make(base_color)
	var mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(vertices, faces, {
		"name": "Seat",
		"material": material
	})
	add_child(mesh_instance)
	_mesh_instances.append(mesh_instance)

func _build_octagonal_backrest() -> void:
	var back_y = (seat_height + backrest_height * 0.5) * chair_scale
	var vertices = _create_octagon_vertices(0.25 * chair_scale, back_y, 0.02 * chair_scale)
	var faces = _create_octagon_faces()
	var material = GridMaterialFactory.make(base_color)
	var mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(vertices, faces, {
		"name": "Backrest",
		"material": material
	})
	add_child(mesh_instance)
	_mesh_instances.append(mesh_instance)

func _build_armrests() -> void:
	var arm_y = (seat_height + armrest_height) * chair_scale
	var arm_width = 0.15 * chair_scale
	var arm_depth = 0.25 * chair_scale
	var arm_thickness = 0.02 * chair_scale
	
	# Left armrest
	var left_vertices = _create_box_vertices(
		-arm_depth * 0.5, arm_y, -arm_width * 0.5,
		arm_depth, arm_thickness, arm_width
	)
	var left_faces = _create_box_faces()
	var left_material = GridMaterialFactory.make(armrest_color)
	var left_mesh = PrimitiveMeshBuilder.build_mesh_instance(left_vertices, left_faces, {
		"name": "LeftArmrest",
		"material": left_material
	})
	add_child(left_mesh)
	_mesh_instances.append(left_mesh)
	
	# Right armrest
	var right_vertices = _create_box_vertices(
		-arm_depth * 0.5, arm_y, arm_width * 0.5,
		arm_depth, arm_thickness, arm_width
	)
	var right_material = GridMaterialFactory.make(armrest_color)
	var right_mesh = PrimitiveMeshBuilder.build_mesh_instance(right_vertices, left_faces, {
		"name": "RightArmrest",
		"material": right_material
	})
	add_child(right_mesh)
	_mesh_instances.append(right_mesh)

func _build_five_spoke_base() -> void:
	var base_y = 0.1 * chair_scale
	var spoke_length = 0.15 * chair_scale
	var spoke_width = 0.02 * chair_scale
	var spoke_height = 0.02 * chair_scale
	
	# Center hub - simple box
	var hub_size = 0.05 * chair_scale
	var hub_vertices = _create_box_vertices(
		-hub_size * 0.5, base_y, -hub_size * 0.5,
		hub_size, 0.1 * chair_scale, hub_size
	)
	var hub_faces = _create_box_faces()
	var hub_material = GridMaterialFactory.make(base_color_metal)
	var hub_mesh = PrimitiveMeshBuilder.build_mesh_instance(hub_vertices, hub_faces, {
		"name": "BaseHub",
		"material": hub_material
	})
	add_child(hub_mesh)
	_mesh_instances.append(hub_mesh)
	
	# Five spokes - create along X axis then rotate
	for i in range(5):
		var angle = (i * 2.0 * PI) / 5.0
		
		# Create spoke along X axis
		var spoke_vertices = _create_box_vertices(
			0, base_y, -spoke_width * 0.5,
			spoke_length, spoke_height, spoke_width
		)
		
		# Rotate vertices around Y axis
		for j in range(spoke_vertices.size()):
			var v = spoke_vertices[j]
			var rotated_x = v.x * cos(angle) - v.z * sin(angle)
			var rotated_z = v.x * sin(angle) + v.z * cos(angle)
			spoke_vertices[j] = Vector3(rotated_x, v.y, rotated_z)
		
		var spoke_faces = _create_box_faces()
		var spoke_material = GridMaterialFactory.make(base_color_metal)
		var spoke_mesh = PrimitiveMeshBuilder.build_mesh_instance(spoke_vertices, spoke_faces, {
			"name": "Spoke_%d" % i,
			"material": spoke_material
		})
		add_child(spoke_mesh)
		_mesh_instances.append(spoke_mesh)

func _build_wheels() -> void:
	var wheel_y = 0.05 * chair_scale
	var wheel_radius = 0.03 * chair_scale
	var wheel_height = 0.02 * chair_scale
	var wheel_count = 5
	
	for i in range(wheel_count):
		var angle = (i * 2.0 * PI) / wheel_count
		var wheel_distance = 0.15 * chair_scale
		var wheel_x = cos(angle) * wheel_distance
		var wheel_z = sin(angle) * wheel_distance
		
		# Create wheel as a simple box (low-poly style)
		var wheel_size = wheel_radius * 2.0
		var wheel_vertices = _create_box_vertices(
			wheel_x - wheel_size * 0.5, wheel_y, wheel_z - wheel_size * 0.5,
			wheel_size, wheel_height, wheel_size
		)
		
		var wheel_faces = _create_box_faces()
		var wheel_material = GridMaterialFactory.make(base_color_metal)
		var wheel_mesh = PrimitiveMeshBuilder.build_mesh_instance(wheel_vertices, wheel_faces, {
			"name": "Wheel_%d" % i,
			"material": wheel_material
		})
		add_child(wheel_mesh)
		_mesh_instances.append(wheel_mesh)

func _create_octagon_vertices(radius: float, y: float, thickness: float) -> Array[Vector3]:
	var vertices: Array[Vector3] = []
	
	# Create octagon (8 sides) - bottom face
	for i in range(8):
		var angle = (i * 2.0 * PI) / 8.0
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		vertices.append(Vector3(x, y, z))
	
	# Top face (same pattern, offset by thickness)
	for i in range(8):
		var angle = (i * 2.0 * PI) / 8.0
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		vertices.append(Vector3(x, y + thickness, z))
	
	return vertices

func _create_octagon_faces() -> Array:
	var faces: Array = []
	
	# Top face - triangulate from first vertex (indices 8-15)
	for i in range(1, 7):
		faces.append([8, 8 + i, 8 + i + 1])
	
	# Bottom face - triangulate from first vertex (indices 0-7)
	for i in range(1, 7):
		faces.append([0, i + 1, i])
	
	# Side faces - connect bottom to top
	for i in range(8):
		var next_i = (i + 1) % 8
		var bottom_i = i
		var top_i = i + 8
		var next_bottom_i = next_i
		var next_top_i = next_i + 8
		
		# Two triangles per side
		faces.append([bottom_i, next_bottom_i, top_i])
		faces.append([next_bottom_i, next_top_i, top_i])
	
	return faces

func _create_box_vertices(x: float, y: float, z: float, width: float, height: float, depth: float) -> Array[Vector3]:
	return [
		Vector3(x, y, z),
		Vector3(x + width, y, z),
		Vector3(x + width, y, z + depth),
		Vector3(x, y, z + depth),
		Vector3(x, y + height, z),
		Vector3(x + width, y + height, z),
		Vector3(x + width, y + height, z + depth),
		Vector3(x, y + height, z + depth)
	]

func _create_box_faces() -> Array:
	return [
		[0, 2, 1], [0, 3, 2],  # Bottom
		[4, 5, 6], [4, 6, 7],  # Top
		[0, 1, 5], [0, 5, 4],  # Front
		[2, 3, 7], [2, 7, 6],  # Back
		[1, 2, 6], [1, 6, 5],  # Right
		[3, 0, 4], [3, 4, 7]   # Left
	]

func _create_cylinder_vertices(radius: float, y: float, height: float, segments: int = 8) -> Array[Vector3]:
	var vertices: Array[Vector3] = []
	
	# Bottom center
	vertices.append(Vector3(0, y, 0))
	# Top center
	vertices.append(Vector3(0, y + height, 0))
	
	# Bottom and top rings
	for i in range(segments):
		var angle = (i * 2.0 * PI) / segments
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		vertices.append(Vector3(x, y, z))
		vertices.append(Vector3(x, y + height, z))
	
	return vertices

func _create_cylinder_faces(segments: int = 8) -> Array:
	var faces: Array = []
	
	# Top face
	for i in range(segments):
		var next_i = (i + 1) % segments
		faces.append([1, (next_i * 2) + 2, (i * 2) + 2])
	
	# Bottom face
	for i in range(segments):
		var next_i = (i + 1) % segments
		faces.append([0, (i * 2) + 3, (next_i * 2) + 3])
	
	# Side faces
	for i in range(segments):
		var next_i = (i + 1) % segments
		var base_bottom = (i * 2) + 3
		var base_top = (i * 2) + 2
		var next_bottom = (next_i * 2) + 3
		var next_top = (next_i * 2) + 2
		
		faces.append([base_bottom, next_bottom, base_top])
		faces.append([next_bottom, next_top, base_top])
	
	return faces

func set_base_color(color: Color) -> void:
	base_color = color
	# Update seat and backrest materials
	for mesh_instance in _mesh_instances:
		if mesh_instance.name == "Seat" or mesh_instance.name == "Backrest":
			mesh_instance.material_override = GridMaterialFactory.make(base_color)

extends Node3D

## Compact 1m³ translation demo with two sliding door elements
## Each door slides only on X axis with visual path indicators

@export var cube_size: float = 1.0
@export var door_width: float = 0.4
@export var door_height: float = 0.6
@export var door_depth: float = 0.1

var _left_door: Node3D
var _right_door: Node3D
var _container: Node3D

func _ready() -> void:
	_setup_container()
	_create_doors()
	_create_path_indicators()

func _setup_container() -> void:
	# Create a wireframe cube to show the 1m³ boundary
	_container = Node3D.new()
	_container.name = "Container"
	add_child(_container)

	# Draw wireframe edges of the cube
	var edges = [
		# Bottom face
		[Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5)],
		[Vector3(0.5, -0.5, -0.5), Vector3(0.5, -0.5, 0.5)],
		[Vector3(0.5, -0.5, 0.5), Vector3(-0.5, -0.5, 0.5)],
		[Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, -0.5, -0.5)],
		# Top face
		[Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5)],
		[Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5)],
		[Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5)],
		[Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, 0.5, -0.5)],
		# Vertical edges
		[Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, 0.5, -0.5)],
		[Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5)],
		[Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5)],
		[Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, 0.5, 0.5)],
	]

	for edge in edges:
		_create_edge_line(edge[0] * cube_size, edge[1] * cube_size)

func _create_edge_line(from: Vector3, to: Vector3) -> void:
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()

	mesh_instance.mesh = immediate_mesh

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	_container.add_child(mesh_instance)

func _create_doors() -> void:
	# Left door (slides from left to center on X axis)
	_left_door = _create_door_element(
		"LeftDoor",
		Vector3(-0.3, 0.0, 0.0),  # Start position (left side)
		Color(0.8, 0.3, 0.3),      # Red
		-0.3,                       # slide_min (stays on left)
		0.0                         # slide_max (center)
	)
	add_child(_left_door)

	# Right door (slides from right to center on X axis)
	_right_door = _create_door_element(
		"RightDoor",
		Vector3(0.3, 0.0, 0.0),   # Start position (right side)
		Color(0.3, 0.3, 0.8),      # Blue
		0.0,                        # slide_min (center)
		0.3                         # slide_max (stays on right)
	)
	add_child(_right_door)

func _create_door_element(
	door_name: String,
	start_pos: Vector3,
	color: Color,
	slide_min: float,
	slide_max: float
) -> Node3D:
	# Load and instantiate the axis_slider scene
	var axis_slider_scene = load("res://commons/primitives/translation/axis_slider.tscn")
	var door = axis_slider_scene.instantiate()

	door.name = door_name
	door.position = start_pos

	# Configure axis restriction
	door.slide_axis = "X"
	door.slide_min = slide_min
	door.slide_max = slide_max
	door.snap_to_grid = false
	door.show_rail = false  # We'll draw custom path
	door.show_position_marker = false

	# Get the mesh instance and update it
	var mesh_instance = door.get_node("MeshInstance3D")
	if mesh_instance:
		# Replace with door-shaped mesh
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(door_width, door_height, door_depth)
		mesh_instance.mesh = box_mesh

		# Apply color material
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = color * 0.6
		material.roughness = 1.0
		material.metallic = 0.0
		material.metallic_specular = 0.0
		material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		mesh_instance.material_override = material

	# Update collision shape
	var collision = door.get_node("CollisionShape3D")
	if collision:
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(door_width, door_height, door_depth)
		collision.shape = box_shape

	return door

func _create_path_indicators() -> void:
	var target_y = 0.2  # Target Y height (20cm up)

	# Left door path: first up to target Y, then slide X to center
	_create_path_arrow(
		Vector3(-0.3, 0.0, 0.0),      # Start at left door position
		Vector3(-0.3, target_y, 0.0), # Step 1: Up to target Y
		Color(0.8, 0.3, 0.3, 0.6)
	)
	_create_path_arrow(
		Vector3(-0.3, target_y, 0.0), # From target Y position
		Vector3(0.0, target_y, 0.0),  # Step 2: Slide X to center
		Color(0.8, 0.3, 0.3, 0.6)
	)
	_create_label("1. Up", Vector3(-0.3, target_y/2, 0.12), Color(0.8, 0.3, 0.3))
	_create_label("2. Slide →", Vector3(-0.15, target_y, 0.12), Color(0.8, 0.3, 0.3))

	# Right door path: first up to target Y, then slide X to center
	_create_path_arrow(
		Vector3(0.3, 0.0, 0.0),       # Start at right door position
		Vector3(0.3, target_y, 0.0),  # Step 1: Up to target Y
		Color(0.3, 0.3, 0.8, 0.6)
	)
	_create_path_arrow(
		Vector3(0.3, target_y, 0.0),  # From target Y position
		Vector3(0.0, target_y, 0.0),  # Step 2: Slide X to center
		Color(0.3, 0.3, 0.8, 0.6)
	)
	_create_label("1. Up", Vector3(0.3, target_y/2, 0.12), Color(0.3, 0.3, 0.8))
	_create_label("2. ← Slide", Vector3(0.15, target_y, 0.12), Color(0.3, 0.3, 0.8))

func _create_path_arrow(from: Vector3, to: Vector3, color: Color) -> void:
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()

	# Draw line
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()

	mesh_instance.mesh = immediate_mesh

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mesh_instance.material_override = material

	add_child(mesh_instance)

	# Add arrowhead at the end
	var arrow_dir = (to - from).normalized()
	_create_arrowhead(to, arrow_dir, color)

func _create_arrowhead(position: Vector3, direction: Vector3, color: Color) -> void:
	var cone = MeshInstance3D.new()
	var cone_mesh = CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = 0.02
	cone_mesh.height = 0.05
	cone.mesh = cone_mesh

	# Orient cone in direction
	var up = Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right = direction.cross(up).normalized()
	up = right.cross(direction).normalized()

	var basis = Basis(right, up, -direction)
	cone.transform = Transform3D(basis, position)

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	cone.material_override = material

	add_child(cone)

func _create_label(text: String, pos: Vector3, color: Color) -> void:
	var label = Label3D.new()
	label.text = text
	label.font_size = 24
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	label.modulate = color
	add_child(label)

func print_help() -> void:
	print("=== Translation Cube Demo ===")
	print("Red door slides left → right (X axis)")
	print("Blue door slides right → left (X axis)")
	print("Path shown: up first, then to the side")
	print("Contained in 1m³ cube")

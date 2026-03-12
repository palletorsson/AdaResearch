extends Node3D

## Translation Demo: Two blocking obstacles that must be slid aside
## Teaches X, Y, Z axis movement

@export var obstacle_material_blocked: Color = Color(1.0, 0.3, 0.3, 0.8)  # Red when blocking
@export var obstacle_material_clear: Color = Color(0.3, 1.0, 0.3, 0.8)   # Green when moved
@export var check_clearance: bool = true
@export var clearance_threshold: float = 0.8  # How far slider must move to clear path

var _obstacle_1: Node3D
var _obstacle_2: Node3D
var _path_clear: bool = false

func _ready() -> void:
	_setup_demo()

func _setup_demo() -> void:
	# Create two blocking obstacles
	_obstacle_1 = _create_blocking_obstacle(
		Vector3(-1.0, 1.0, 0),
		Vector3(1.5, 0.3, 0.3),  # Wide horizontal blocker
		"X",  # Slides left/right
		-2.0, 2.0,
		Color(0.8, 0.3, 0.3)
	)
	add_child(_obstacle_1)

	_obstacle_2 = _create_blocking_obstacle(
		Vector3(1.0, 0.5, 0),
		Vector3(0.3, 0.3, 1.5),  # Deep vertical blocker
		"Y",  # Slides up/down
		-1.0, 2.0,
		Color(0.3, 0.3, 0.8)
	)
	add_child(_obstacle_2)

	# Create visual path/goal behind obstacles
	_create_path_indicator()

func _create_blocking_obstacle(
	start_pos: Vector3,
	size: Vector3,
	axis: String,
	slide_min: float,
	slide_max: float,
	color: Color
) -> Node3D:
	# Instantiate the axis_slider scene (includes XRToolsPickable setup)
	var axis_slider_scene = load("res://commons/primitives/translation/axis_slider.tscn")
	var slider = axis_slider_scene.instantiate()

	slider.position = start_pos

	# Configure axis restriction
	slider.slide_axis = axis
	slider.slide_min = slide_min
	slider.slide_max = slide_max
	slider.snap_to_grid = false
	slider.show_rail = true
	slider.show_position_marker = false

	# Get the mesh instance and update it with custom size
	var mesh_instance = slider.get_node_or_null("MeshInstance3D")
	if mesh_instance:
		var box_mesh = BoxMesh.new()
		box_mesh.size = size
		mesh_instance.mesh = box_mesh

		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = color * 0.5
		material.roughness = 1.0
		material.metallic = 0.0
		material.metallic_specular = 0.0
		material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		mesh_instance.material_override = material

	# Update collision shape to match size
	var collision = slider.get_node_or_null("CollisionShape3D")
	if collision:
		var box_shape = BoxShape3D.new()
		box_shape.size = size
		collision.shape = box_shape

	return slider

func _create_path_indicator() -> void:
	# Create a glowing sphere behind the obstacles as a "goal"
	var goal = MeshInstance3D.new()
	goal.name = "Goal"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	goal.mesh = sphere_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 0.3, 0.6)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0, 0.3) * 2.0
	material.roughness = 1.0
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	goal.material_override = material

	goal.position = Vector3(0, 1.0, -1.5)
	add_child(goal)

	# Add label explaining the objective
	var label = Label3D.new()
	label.text = "Slide obstacles\nto reach goal"
	label.font_size = 32
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.0, 0)
	label.modulate = Color(0.8, 0.8, 1.0)
	add_child(label)

func _process(_delta: float) -> void:
	if not check_clearance:
		return

	# Check if obstacles have been moved enough to clear the path
	var obstacle_1_clear = false
	var obstacle_2_clear = false

	if _obstacle_1 and _obstacle_1.has_method("get_axis_progress"):
		var progress = _obstacle_1.get_axis_progress()
		obstacle_1_clear = progress > clearance_threshold or progress < (1.0 - clearance_threshold)

	if _obstacle_2 and _obstacle_2.has_method("get_axis_progress"):
		var progress = _obstacle_2.get_axis_progress()
		obstacle_2_clear = progress > clearance_threshold

	var was_clear = _path_clear
	_path_clear = obstacle_1_clear and obstacle_2_clear

	# Visual feedback when path is cleared
	if _path_clear and not was_clear:
		print("Translation Demo: Path cleared!")
		_on_path_cleared()

func _on_path_cleared() -> void:
	# Change obstacle colors to green
	if _obstacle_1:
		var mesh = _obstacle_1.get_node_or_null("MeshInstance3D")
		if mesh:
			var mat = mesh.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color = obstacle_material_clear
				mat.emission = obstacle_material_clear * 0.5

	if _obstacle_2:
		var mesh = _obstacle_2.get_node_or_null("MeshInstance3D")
		if mesh:
			var mat = mesh.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color = obstacle_material_clear
				mat.emission = obstacle_material_clear * 0.5

func print_help() -> void:
	print("=== Translation Demo ===")
	print("Grab and slide the red obstacle left/right (X axis)")
	print("Grab and slide the blue obstacle up/down (Y axis)")
	print("Clear both obstacles to reach the goal")

extends Node3D

# Newton-Raphson Method Visualization: Root Finding & Convergent Identity
# Demonstrates iterative root finding with beautiful convergence visualization
# Shows tangent line approximations and convergence trajectories in 3D space

@export_category("Algorithm Configuration")
@export var target_function: String = "x^3 - 2*x - 5"  # Function to find roots for
@export var initial_guess: float = 2.0
@export var tolerance: float = 0.0001
@export var max_iterations: int = 20
@export var iteration_speed: float = 1.0  # Seconds between iterations

@export_category("Visualization")
@export var function_resolution: int = 200
@export var x_range: Vector2 = Vector2(-5, 5)
@export var y_range: Vector2 = Vector2(-10, 10)
@export var show_tangent_lines: bool = true
@export var show_convergence_path: bool = true
@export var animate_convergence: bool = true

@export_category("Educational")
@export var show_formula: bool = true
@export var show_steps: bool = true
@export var function_preset: String = "Cubic"  # Cubic, Quadratic, Sine, Custom

# Algorithm state
var current_x: float
var iterations_completed: int = 0
var convergence_history: Array[Vector2] = []
var is_converged: bool = false
var is_animating: bool = false
var animation_timer: float = 0.0

# Visual elements
var function_mesh: MeshInstance3D
var tangent_lines: Array[MeshInstance3D] = []
var convergence_path: MeshInstance3D
var iteration_points: Array[MeshInstance3D] = []
var ui_display: CanvasLayer
var root_marker: MeshInstance3D

# Mathematical components
var current_function_value: float
var current_derivative_value: float

# Colors
var function_color = Color(0.2, 0.6, 0.9)
var tangent_color = Color(0.9, 0.4, 0.2)
var convergence_color = Color(0.2, 0.9, 0.3)
var root_color = Color(0.9, 0.9, 0.2)

func _ready():
	setup_environment()
	setup_camera()
	load_function_preset()
	create_function_visualization()
	setup_ui()
	start_newton_raphson()

func _process(delta):
	if is_animating and animate_convergence:
		animation_timer += delta
		if animation_timer >= (1.0 / iteration_speed):
			perform_iteration_step()
			animation_timer = 0.0

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				restart_algorithm()
			KEY_SPACE:
				if not is_animating:
					perform_iteration_step()
			KEY_T:
				show_tangent_lines = !show_tangent_lines
				update_tangent_visualization()
			KEY_1:
				load_function_preset("Cubic")
			KEY_2:
				load_function_preset("Quadratic")
			KEY_3:
				load_function_preset("Sine")

func setup_environment():
	# Lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 1.2
	light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(light)
	
	# Environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.3, 0.3, 0.4)
	environment.ambient_light_energy = 0.4
	env.environment = environment
	add_child(env)

func setup_camera():
	var camera = Camera3D.new()
	camera.position = Vector3(0, 8, 12)
	camera.look_at_from_position(camera.position, Vector3(0, 0, 0), Vector3.UP)
	add_child(camera)

func load_function_preset(preset: String = ""):
	if preset != "":
		function_preset = preset
	
	match function_preset:
		"Cubic":
			target_function = "x^3 - 2*x - 5"
			initial_guess = 2.0
		"Quadratic":
			target_function = "x^2 - 4"
			initial_guess = 3.0
		"Sine":
			target_function = "sin(x) - 0.5"
			initial_guess = 1.0
		"Exponential":
			target_function = "e^x - 3"
			initial_guess = 1.5
	
	restart_algorithm()

func evaluate_function(x: float) -> float:
	"""Evaluate the target function at x"""
	match function_preset:
		"Cubic":
			return x*x*x - 2*x - 5
		"Quadratic":
			return x*x - 4
		"Sine":
			return sin(x) - 0.5
		"Exponential":
			return exp(x) - 3
		_:
			return x*x*x - 2*x - 5  # Default

func evaluate_derivative(x: float) -> float:
	"""Evaluate the derivative of the target function at x"""
	match function_preset:
		"Cubic":
			return 3*x*x - 2
		"Quadratic":
			return 2*x
		"Sine":
			return cos(x)
		"Exponential":
			return exp(x)
		_:
			return 3*x*x - 2  # Default

func create_function_visualization():
	"""Create 3D visualization of the function"""
	clear_previous_visualization()
	
	# Create function curve
	var curve_points = PackedVector3Array()
	var step = (x_range.y - x_range.x) / float(function_resolution)
	
	for i in range(function_resolution + 1):
		var x = x_range.x + i * step
		var y = evaluate_function(x)
		# Clamp y to visible range
		y = clamp(y, y_range.x, y_range.y)
		curve_points.append(Vector3(x, y, 0))
	
	# Create mesh from curve points
	function_mesh = create_curve_mesh(curve_points, function_color, 0.1)
	add_child(function_mesh)
	
	# Create x-axis
	var x_axis = create_axis_line(Vector3(x_range.x, 0, 0), Vector3(x_range.y, 0, 0), Color.WHITE)
	add_child(x_axis)
	
	# Create y-axis  
	var y_axis = create_axis_line(Vector3(0, y_range.x, 0), Vector3(0, y_range.y, 0), Color.WHITE)
	add_child(y_axis)

func create_curve_mesh(points: PackedVector3Array, color: Color, thickness: float) -> MeshInstance3D:
	"""Create a 3D curve mesh from points"""
	var mesh_instance = MeshInstance3D.new()
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Create tube geometry along the curve
	for i in range(points.size() - 1):
		var current = points[i]
		var next = points[i + 1]
		var direction = (next - current).normalized()
		var perpendicular = Vector3.UP.cross(direction).normalized() * thickness
		
		# Add vertices for a rectangular cross-section
		var base_index = vertices.size()
		vertices.append(current + perpendicular)
		vertices.append(current - perpendicular)
		vertices.append(next + perpendicular)
		vertices.append(next - perpendicular)
		
		# Add triangles
		indices.append_array([
			base_index, base_index + 1, base_index + 2,
			base_index + 1, base_index + 3, base_index + 2
		])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.3
	mesh_instance.material_override = material
	
	return mesh_instance

func create_axis_line(start: Vector3, end: Vector3, color: Color) -> MeshInstance3D:
	"""Create a simple line for axes"""
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = start.distance_to(end)
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	mesh_instance.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.6
	mesh_instance.material_override = material
	
	# Position and orient the line
	var center = (start + end) / 2
	mesh_instance.position = center
	mesh_instance.look_at_from_position(mesh_instance.position, end, Vector3.UP)
	
	return mesh_instance

func start_newton_raphson():
	"""Initialize the Newton-Raphson algorithm"""
	current_x = initial_guess
	iterations_completed = 0
	convergence_history.clear()
	is_converged = false
	
	# Add initial guess to history
	current_function_value = evaluate_function(current_x)
	convergence_history.append(Vector2(current_x, current_function_value))
	
	create_iteration_point(Vector3(current_x, current_function_value, 0), Color.YELLOW)
	update_ui()
	
	if animate_convergence:
		is_animating = true
		animation_timer = 0.0
	
	print("Newton-Raphson started with initial guess: ", current_x)

func perform_iteration_step():
	"""Perform one iteration of Newton-Raphson method"""
	if is_converged or iterations_completed >= max_iterations:
		is_animating = false
		return
	
	# Newton-Raphson formula: x_{n+1} = x_n - f(x_n) / f'(x_n)
	current_function_value = evaluate_function(current_x)
	current_derivative_value = evaluate_derivative(current_x)
	
	# Check for zero derivative (method fails)
	if abs(current_derivative_value) < 1e-12:
		print("Newton-Raphson failed: Zero derivative at x = ", current_x)
		is_animating = false
		return
	
	# Create tangent line visualization
	if show_tangent_lines:
		create_tangent_line(current_x, current_function_value, current_derivative_value)
	
	# Calculate next approximation
	var next_x = current_x - current_function_value / current_derivative_value
	var next_function_value = evaluate_function(next_x)
	
	# Check for convergence
	if abs(next_function_value) < tolerance or abs(next_x - current_x) < tolerance:
		is_converged = true
		is_animating = false
		create_root_marker(next_x)
		print("Converged to root: x = ", next_x, ", f(x) = ", next_function_value)
	
	# Update state
	current_x = next_x
	iterations_completed += 1
	convergence_history.append(Vector2(current_x, next_function_value))
	
	# Create visual point for this iteration
	var point_color = convergence_color if is_converged else Color.ORANGE
	create_iteration_point(Vector3(current_x, next_function_value, 0), point_color)
	
	# Update convergence path
	update_convergence_path()
	update_ui()

func create_tangent_line(x: float, fx: float, fpx: float):
	"""Create visualization of tangent line at current point"""
	var tangent_range = 2.0
	var x1 = x - tangent_range
	var x2 = x + tangent_range
	
	# Tangent line equation: y = f(x) + f'(x)(x_new - x)
	var y1 = fx + fpx * (x1 - x)
	var y2 = fx + fpx * (x2 - x)
	
	var tangent_line = create_axis_line(
		Vector3(x1, y1, 0.1), 
		Vector3(x2, y2, 0.1), 
		tangent_color
	)
	tangent_lines.append(tangent_line)
	add_child(tangent_line)

func create_iteration_point(position: Vector3, color: Color):
	"""Create a visual marker for an iteration point"""
	var point = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.15
	point.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.5
	point.material_override = material
	
	point.position = position
	iteration_points.append(point)
	add_child(point)

func create_root_marker(root_x: float):
	"""Create special marker for the discovered root"""
	root_marker = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = abs(y_range.y - y_range.x)
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.05
	root_marker.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = root_color
	material.emission_enabled = true
	material.emission = root_color * 0.6
	root_marker.material_override = material
	
	root_marker.position = Vector3(root_x, 0, 0)
	add_child(root_marker)

func update_convergence_path():
	"""Update the visual path showing convergence trajectory"""
	if convergence_history.size() < 2:
		return
	
	if convergence_path:
		convergence_path.queue_free()
	
	var path_points = PackedVector3Array()
	for point in convergence_history:
		path_points.append(Vector3(point.x, point.y, 0.05))
	
	convergence_path = create_curve_mesh(path_points, convergence_color, 0.05)
	add_child(convergence_path)

func update_tangent_visualization():
	"""Toggle tangent line visibility"""
	for tangent in tangent_lines:
		tangent.visible = show_tangent_lines

func clear_previous_visualization():
	"""Clear previous visualization elements"""
	if function_mesh:
		function_mesh.queue_free()
	
	for tangent in tangent_lines:
		tangent.queue_free()
	tangent_lines.clear()
	
	for point in iteration_points:
		point.queue_free()
	iteration_points.clear()
	
	if convergence_path:
		convergence_path.queue_free()
	
	if root_marker:
		root_marker.queue_free()

func restart_algorithm():
	"""Restart the algorithm with current parameters"""
	clear_previous_visualization()
	create_function_visualization()
	start_newton_raphson()

func setup_ui():
	"""Create user interface for information display"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(350, 400)
	panel.position = Vector2(20, 20)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(15, 15)
	vbox.custom_minimum_size = Vector2(320, 370)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Newton-Raphson Method"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	# Information labels (will be updated in update_ui())
	for i in range(8):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		vbox.add_child(label)
	
	update_ui()

func update_ui():
	"""Update the user interface with current algorithm state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(8):
		var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 8:
		labels[0].text = "Function: " + target_function
		labels[1].text = "Current x: %.6f" % current_x
		labels[2].text = "f(x): %.6f" % current_function_value
		labels[3].text = "f'(x): %.6f" % current_derivative_value if iterations_completed > 0 else "f'(x): --"
		labels[4].text = "Iteration: %d / %d" % [iterations_completed, max_iterations]
		labels[5].text = "Status: " + ("CONVERGED" if is_converged else "Running" if is_animating else "Paused")
		labels[6].text = "Tolerance: " + str(tolerance)
		labels[7].text = "Press R to restart, SPACE to step, T for tangents" 

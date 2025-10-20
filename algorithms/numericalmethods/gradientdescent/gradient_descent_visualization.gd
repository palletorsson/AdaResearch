extends Node3D

# Gradient Descent: Optimization & the Journey to Authenticity
# Demonstrates iterative optimization by following gradients down to minima
# Shows the beautiful process of finding optimal states through guided descent

@export_category("Optimization Configuration")
@export var objective_function: String = "x^2 + y^2"  # Function to minimize
@export var initial_position: Vector2 = Vector2(3.0, 2.0)
@export var learning_rate: float = 0.1
@export var tolerance: float = 0.001
@export var max_iterations: int = 50
@export var iteration_speed: float = 1.0  # Seconds between steps

@export_category("Visualization")
@export var surface_resolution: int = 100
@export var x_range: Vector2 = Vector2(-5, 5)
@export var y_range: Vector2 = Vector2(-5, 5)
@export var z_scale: float = 2.0
@export var show_gradient_vectors: bool = true
@export var show_path_trail: bool = true
@export var animate_descent: bool = true

@export_category("Visual Style")
@export var surface_color: Color = Color(0.3, 0.6, 0.9)
@export var gradient_color: Color = Color(0.9, 0.3, 0.3)
@export var path_color: Color = Color(0.9, 0.9, 0.3)
@export var minimum_color: Color = Color(0.3, 0.9, 0.3)
@export var current_position_color: Color = Color(0.9, 0.3, 0.9)

@export_category("Optimization Presets")
@export var function_preset: String = "Quadratic Bowl"  # Quadratic Bowl, Rosenbrock Valley, Himmelblau Function

# Algorithm state
var current_pos: Vector2
var descent_path: Array[Vector2] = []
var gradient_history: Array[Vector2] = []
var function_values: Array[float] = []
var current_iteration: int = 0
var is_optimizing: bool = false
var animation_timer: float = 0.0
var algorithm_step: String = "starting"

# Visual elements
var surface_mesh: MeshInstance3D
var gradient_arrows: Array[MeshInstance3D] = []
var path_trail: Array[MeshInstance3D] = []
var current_marker: MeshInstance3D
var minimum_markers: Array[MeshInstance3D] = []
var ui_display: CanvasLayer
var camera_controller: Node3D

# Mathematical components
var function_evaluator: FunctionEvaluator
var gradient_computer: GradientComputer

# Educational statistics
var optimization_stats: Dictionary = {
	"iterations": 0,
	"function_calls": 0,
	"gradient_calls": 0,
	"final_value": 0.0,
	"convergence_rate": 0.0
}

class FunctionEvaluator:
	var function_type: String
	
	func _init(f_type: String):
		function_type = f_type
	
	func evaluate(pos: Vector2) -> float:
		var x = pos.x
		var y = pos.y
		
		match function_type:
			"Quadratic Bowl":
				return x*x + y*y
			"Rosenbrock Valley":
				return (1 - x)*(1 - x) + 100*(y - x*x)*(y - x*x)
			"Himmelblau Function":
				return (x*x + y - 11)*(x*x + y - 11) + (x + y*y - 7)*(x + y*y - 7)
			_:
				return x*x + y*y  # Default to simple quadratic

class GradientComputer:
	var function_eval: FunctionEvaluator
	var epsilon: float = 0.0001
	
	func _init(func_evaluator: FunctionEvaluator):
		function_eval = func_evaluator
	
	func compute_gradient(pos: Vector2) -> Vector2:
		var x = pos.x
		var y = pos.y
		
		# Numerical gradient computation using finite differences
		var dx = (function_eval.evaluate(Vector2(x + epsilon, y)) - 
				 function_eval.evaluate(Vector2(x - epsilon, y))) / (2 * epsilon)
		var dy = (function_eval.evaluate(Vector2(x, y + epsilon)) - 
				 function_eval.evaluate(Vector2(x, y - epsilon))) / (2 * epsilon)
		
		return Vector2(dx, dy)

func _ready():
	setup_environment()
	setup_camera()
	initialize_mathematical_components()
	load_function_preset()
	create_surface_visualization()
	setup_ui()
	if animate_descent:
		start_gradient_descent()

func _process(delta):
	if is_optimizing and animate_descent:
		animation_timer += delta
		if animation_timer >= iteration_speed:
			perform_descent_step()
			animation_timer = 0.0

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if not is_optimizing:
					start_gradient_descent()
				else:
					perform_descent_step()
			KEY_R:
				restart_optimization()
			KEY_1:
				load_function_preset("Quadratic Bowl")
			KEY_2:
				load_function_preset("Rosenbrock Valley")
			KEY_3:
				load_function_preset("Himmelblau Function")
			KEY_G:
				toggle_gradient_visibility()
			KEY_P:
				toggle_path_visibility()

func setup_environment():
	# Dramatic lighting for 3D surface visualization
	var light = DirectionalLight3D.new()
	light.light_energy = 1.8
	light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(light)
	
	# Additional light for better surface definition
	var fill_light = DirectionalLight3D.new()
	fill_light.light_energy = 0.6
	fill_light.rotation_degrees = Vector3(45, -60, 0)
	add_child(fill_light)
	
	# Environment for depth perception
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.2, 0.2, 0.3)
	environment.ambient_light_energy = 0.4
	env.environment = environment
	add_child(env)

func setup_camera():
	camera_controller = Node3D.new()
	add_child(camera_controller)
	
	var camera = Camera3D.new()
	camera.position = Vector3(8, 12, 8)
	camera.look_at_from_position(camera.position, Vector3(0, 0, 0), Vector3.UP)
	camera_controller.add_child(camera)

func initialize_mathematical_components():
	function_evaluator = FunctionEvaluator.new(function_preset)
	gradient_computer = GradientComputer.new(function_evaluator)

func load_function_preset(preset: String = ""):
	if preset != "":
		function_preset = preset
		objective_function = preset
	
	match function_preset:
		"Quadratic Bowl":
			initial_position = Vector2(3.0, 2.0)
			learning_rate = 0.1
			
		"Rosenbrock Valley":
			initial_position = Vector2(-1.0, 1.0)
			learning_rate = 0.001  # Smaller learning rate for more complex function
			
		"Himmelblau Function":
			initial_position = Vector2(0.0, 0.0)
			learning_rate = 0.01
	
	if function_evaluator:
		function_evaluator.function_type = function_preset
	
	restart_optimization()

func create_surface_visualization():
	"""Create 3D surface visualization of the objective function"""
	clear_previous_visualization()
	
	# Create surface mesh
	create_function_surface()
	
	# Mark known minima for some functions
	mark_theoretical_minima()
	
	# Create current position marker
	create_position_marker()

func create_function_surface():
	"""Generate 3D mesh for the objective function surface"""
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var colors = PackedColorArray()
	
	var x_step = (x_range.y - x_range.x) / surface_resolution
	var y_step = (y_range.y - y_range.x) / surface_resolution
	
	# Generate vertices
	for i in range(surface_resolution + 1):
		for j in range(surface_resolution + 1):
			var x = x_range.x + i * x_step
			var y = y_range.x + j * y_step
			var z = function_evaluator.evaluate(Vector2(x, y)) * z_scale
			
			vertices.append(Vector3(x, z, y))  # Note: z up, y depth
			
			# Color based on height (function value)
			var normalized_height = clamp(z / 10.0, 0.0, 1.0)
			var color = surface_color.lerp(Color.WHITE, normalized_height)
			colors.append(color)
	
	# Generate indices for triangular faces
	for i in range(surface_resolution):
		for j in range(surface_resolution):
			var top_left = i * (surface_resolution + 1) + j
			var top_right = top_left + 1
			var bottom_left = (i + 1) * (surface_resolution + 1) + j
			var bottom_right = bottom_left + 1
			
			# First triangle
			indices.append(top_left)
			indices.append(bottom_left)
			indices.append(top_right)
			
			# Second triangle
			indices.append(top_right)
			indices.append(bottom_left)
			indices.append(bottom_right)
	
	# Create mesh
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_COLOR] = colors
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	surface_mesh = MeshInstance3D.new()
	surface_mesh.mesh = array_mesh
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.metallic = 0.1
	material.roughness = 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.8
	surface_mesh.material_override = material
	
	add_child(surface_mesh)

func mark_theoretical_minima():
	"""Mark known theoretical minima for educational purposes"""
	var minima_positions: Array[Vector2] = []
	
	match function_preset:
		"Quadratic Bowl":
			minima_positions = [Vector2(0, 0)]
		"Rosenbrock Valley":
			minima_positions = [Vector2(1, 1)]
		"Himmelblau Function":
			minima_positions = [Vector2(3, 2), Vector2(-2.8, 3.1), Vector2(-3.8, -3.3), Vector2(3.6, -1.8)]
	
	for pos in minima_positions:
		var marker = create_sphere_marker(pos, minimum_color, 0.3)
		minimum_markers.append(marker)
		add_child(marker)

func create_position_marker():
	"""Create marker for current optimization position"""
	current_marker = create_sphere_marker(current_pos, current_position_color, 0.4)
	add_child(current_marker)

func create_sphere_marker(pos_2d: Vector2, color: Color, size: float) -> MeshInstance3D:
	"""Create a sphere marker at given 2D position"""
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = size
	sphere_mesh.height = size * 2
	sphere.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.6
	sphere.material_override = material
	
	var z_pos = function_evaluator.evaluate(pos_2d) * z_scale + 0.5
	sphere.position = Vector3(pos_2d.x, z_pos, pos_2d.y)
	
	return sphere

func start_gradient_descent():
	"""Initialize gradient descent optimization"""
	current_pos = initial_position
	descent_path.clear()
	gradient_history.clear()
	function_values.clear()
	current_iteration = 0
	is_optimizing = true
	algorithm_step = "initializing"
	
	# Record starting position
	descent_path.append(current_pos)
	function_values.append(function_evaluator.evaluate(current_pos))
	
	# Reset statistics
	optimization_stats.iterations = 0
	optimization_stats.function_calls = 1
	optimization_stats.gradient_calls = 0
	
	update_position_marker()
	clear_visualizations()
	update_ui()
	
	print("Gradient descent started from position: ", current_pos)

func perform_descent_step():
	"""Perform one step of gradient descent"""
	if not is_optimizing:
		return
	
	if current_iteration >= max_iterations:
		# Optimization complete
		is_optimizing = false
		algorithm_step = "converged"
		optimization_stats.final_value = function_evaluator.evaluate(current_pos)
		print("Optimization complete after ", current_iteration, " iterations")
		update_ui()
		return
	
	# Compute gradient at current position
	var gradient = gradient_computer.compute_gradient(current_pos)
	gradient_history.append(gradient)
	optimization_stats.gradient_calls += 1
	
	# Check for convergence
	if gradient.length() < tolerance:
		is_optimizing = false
		algorithm_step = "converged"
		optimization_stats.final_value = function_evaluator.evaluate(current_pos)
		print("Converged! Gradient magnitude: ", gradient.length())
		update_ui()
		return
	
	# Perform gradient descent step
	var old_pos = current_pos
	current_pos = current_pos - learning_rate * gradient
	
	# Record new position
	descent_path.append(current_pos)
	var new_value = function_evaluator.evaluate(current_pos)
	function_values.append(new_value)
	optimization_stats.function_calls += 1
	
	current_iteration += 1
	optimization_stats.iterations = current_iteration
	algorithm_step = "descending"
	
	# Update visualizations
	update_position_marker()
	if show_gradient_vectors:
		create_gradient_arrow(old_pos, gradient)
	if show_path_trail:
		create_path_segment(old_pos, current_pos)
	
	update_ui()
	
	print("Step ", current_iteration, ": Position ", current_pos, " Value: ", new_value)

func update_position_marker():
	"""Update the current position marker"""
	if current_marker:
		var z_pos = function_evaluator.evaluate(current_pos) * z_scale + 0.5
		current_marker.position = Vector3(current_pos.x, z_pos, current_pos.y)

func create_gradient_arrow(pos: Vector2, gradient: Vector2):
	"""Create visual arrow showing gradient direction"""
	var arrow = create_arrow_mesh(pos, -gradient.normalized(), gradient_color)
	gradient_arrows.append(arrow)
	add_child(arrow)

func create_path_segment(from_pos: Vector2, to_pos: Vector2):
	"""Create visual segment of the optimization path"""
	var segment = create_line_segment(from_pos, to_pos, path_color)
	path_trail.append(segment)
	add_child(segment)

func create_arrow_mesh(pos_2d: Vector2, direction: Vector2, color: Color) -> MeshInstance3D:
	"""Create an arrow mesh showing direction"""
	var arrow = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = 1.0
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.05
	arrow.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.5
	arrow.material_override = material
	
	var z_pos = function_evaluator.evaluate(pos_2d) * z_scale + 1.0
	arrow.position = Vector3(pos_2d.x, z_pos, pos_2d.y)
	
	# Orient arrow in gradient direction
	var angle = atan2(direction.y, direction.x)
	arrow.rotation = Vector3(0, -angle + PI/2, PI/2)
	
	return arrow

func create_line_segment(from_pos: Vector2, to_pos: Vector2, color: Color) -> MeshInstance3D:
	"""Create a line segment between two positions"""
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	
	var distance = from_pos.distance_to(to_pos)
	cylinder.height = distance
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	line.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	line.material_override = material
	
	# Position at midpoint between from and to
	var midpoint = (from_pos + to_pos) / 2
	var from_z = function_evaluator.evaluate(from_pos) * z_scale + 0.3
	var to_z = function_evaluator.evaluate(to_pos) * z_scale + 0.3
	var mid_z = (from_z + to_z) / 2
	
	line.position = Vector3(midpoint.x, mid_z, midpoint.y)
	
	# Orient line between points
	var direction = to_pos - from_pos
	var angle = atan2(direction.y, direction.x)
	line.rotation = Vector3(0, -angle + PI/2, 0)
	
	return line

func clear_visualizations():
	"""Clear previous step visualizations"""
	for arrow in gradient_arrows:
		arrow.queue_free()
	gradient_arrows.clear()
	
	for segment in path_trail:
		segment.queue_free()
	path_trail.clear()

func clear_previous_visualization():
	"""Clear all previous visualization elements"""
	if surface_mesh:
		surface_mesh.queue_free()
	
	for marker in minimum_markers:
		marker.queue_free()
	minimum_markers.clear()
	
	if current_marker:
		current_marker.queue_free()
	
	clear_visualizations()

func restart_optimization():
	"""Restart optimization with current parameters"""
	clear_previous_visualization()
	initialize_mathematical_components()
	create_surface_visualization()
	is_optimizing = false
	current_iteration = 0
	descent_path.clear()
	gradient_history.clear()
	function_values.clear()
	optimization_stats.function_calls = 0
	optimization_stats.gradient_calls = 0
	update_ui()

func toggle_gradient_visibility():
	"""Toggle visibility of gradient vectors"""
	show_gradient_vectors = !show_gradient_vectors
	for arrow in gradient_arrows:
		arrow.visible = show_gradient_vectors
	update_ui()

func toggle_path_visibility():
	"""Toggle visibility of path trail"""
	show_path_trail = !show_path_trail
	for segment in path_trail:
		segment.visible = show_path_trail
	update_ui()

func setup_ui():
	"""Create comprehensive user interface"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 550)
	panel.position = Vector2(20, 20)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(15, 15)
	vbox.custom_minimum_size = Vector2(370, 520)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Gradient Descent: Journey to Optimality"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	# Information labels
	for i in range(16):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(label)
	
	update_ui()

func update_ui():
	"""Update user interface with current optimization state"""
	if not ui_display:
		return
	
	# Check if the UI structure exists
	var panel = ui_display.get_node_or_null("Panel")
	if not panel:
		return
	var vbox = panel.get_node("VBoxContainer")
	if not vbox:
		return
	
	var labels = []
	for i in range(16):
		var label = vbox.get_node("info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 16:
		labels[0].text = "Function: " + function_preset
		labels[1].text = "Current Position: (" + str(current_pos.x).pad_decimals(3) + ", " + str(current_pos.y).pad_decimals(3) + ")"
		
		var current_value = 0.0
		if function_evaluator:
			current_value = function_evaluator.evaluate(current_pos)
		labels[2].text = "Function Value: " + str(current_value).pad_decimals(4)
		
		labels[3].text = "Learning Rate: " + str(learning_rate)
		labels[4].text = ""
		labels[5].text = "Iterations: " + str(optimization_stats.iterations) + "/" + str(max_iterations)
		labels[6].text = "Function Evaluations: " + str(optimization_stats.function_calls)
		labels[7].text = "Gradient Evaluations: " + str(optimization_stats.gradient_calls)
		labels[8].text = ""
		labels[9].text = "Status: " + algorithm_step.replace("_", " ").capitalize()
		labels[10].text = "Path Length: " + str(descent_path.size()) + " points"
		
		var gradient_magnitude = 0.0
		if gradient_history.size() > 0:
			gradient_magnitude = gradient_history[-1].length()
		labels[11].text = "Gradient Magnitude: " + str(gradient_magnitude).pad_decimals(4)
		
		labels[12].text = ""
		labels[13].text = "Controls: SPACE=Step, R=Restart, 1-3=Functions"
		labels[14].text = "G=Toggle Gradients, P=Toggle Path"
		labels[15].text = "Following steepest descent toward optimal authenticity" 

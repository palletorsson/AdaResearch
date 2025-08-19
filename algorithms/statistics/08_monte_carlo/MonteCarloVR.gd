extends Node3D

# Interactive VR Monte Carlo Simulation - Computational Statistics
# Demonstrates random sampling for complex mathematical calculations

class_name MonteCarloVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Simulation Settings
@export_category("Monte Carlo Parameters")
@export var simulation_type: SimulationType = SimulationType.PI_ESTIMATION
@export var sample_size: int = 10000
@export var animation_speed: float = 10.0
@export var batch_size: int = 100

# Visual Settings
@export_category("Visualization")
@export var show_sample_points: bool = true
@export var show_convergence: bool = true
@export var circle_radius: float = 1.0

enum SimulationType {
	PI_ESTIMATION,
	INTEGRATION,
	OPTION_PRICING,
	RANDOM_WALK
}

# Internal variables
var sample_count: int = 0
var inside_circle_count: int = 0
var pi_estimates: Array[float] = []
var sample_points: Array[Vector3] = []

# VR Components
var xr_origin: XROrigin3D
var controllers: Array[XRController3D] = []

# Visual Elements
var circle_display: Node3D
var square_boundary: Node3D
var convergence_chart: Node3D
var info_display: Label3D
var sample_particles: Array[Node3D] = []

# Animation
var simulation_tween: Tween
var is_running: bool = false

func _ready():
	setup_vr()
	setup_visualization()
	setup_info_display()
	reset_simulation()

func setup_vr():
	"""Initialize VR system"""
	if enable_vr:
		var xr_interface = XRServer.find_interface("OpenXR")
		if xr_interface and xr_interface.is_initialized():
			get_viewport().use_xr = true
		else:
			enable_vr = false
	
	xr_origin = XROrigin3D.new()
	add_child(xr_origin)
	
	var xr_camera = XRCamera3D.new()
	xr_origin.add_child(xr_camera)
	
	if enable_vr:
		for hand in ["left_hand", "right_hand"]:
			var controller = XRController3D.new()
			controller.tracker = StringName(hand)
			controller.button_pressed.connect(_on_controller_button)
			xr_origin.add_child(controller)
			controllers.append(controller)

func setup_visualization():
	"""Create visualization elements for Monte Carlo simulation"""
	match simulation_type:
		SimulationType.PI_ESTIMATION:
			setup_pi_estimation_visual()
		SimulationType.INTEGRATION:
			setup_integration_visual()
		SimulationType.OPTION_PRICING:
			setup_option_pricing_visual()
		SimulationType.RANDOM_WALK:
			setup_random_walk_visual()

func setup_pi_estimation_visual():
	"""Set up visualization for π estimation using circle/square"""
	# Create unit circle
	circle_display = Node3D.new()
	add_child(circle_display)
	
	var circle_mesh = MeshInstance3D.new()
	# Create circle outline
	var curve_points: Array[Vector3] = []
	for i in range(101):
		var angle = float(i) / 100.0 * TAU
		var x = cos(angle) * circle_radius
		var y = sin(angle) * circle_radius
		curve_points.append(Vector3(x, y, 0))
	
	create_line_mesh(circle_mesh, curve_points, Color.CYAN)
	circle_display.add_child(circle_mesh)
	
	# Create square boundary
	square_boundary = Node3D.new()
	add_child(square_boundary)
	
	var square_mesh = MeshInstance3D.new()
	var square_points: Array[Vector3] = [
		Vector3(-circle_radius, -circle_radius, 0),
		Vector3(circle_radius, -circle_radius, 0),
		Vector3(circle_radius, circle_radius, 0),
		Vector3(-circle_radius, circle_radius, 0),
		Vector3(-circle_radius, -circle_radius, 0)
	]
	
	create_line_mesh(square_mesh, square_points, Color.WHITE)
	square_boundary.add_child(square_mesh)
	
	# Convergence chart
	setup_convergence_chart()

func create_line_mesh(mesh_instance: MeshInstance3D, points: Array[Vector3], color: Color):
	"""Create a line mesh from points"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	
	var indices: PackedInt32Array = []
	for i in range(points.size() - 1):
		indices.append(i)
		indices.append(i + 1)
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission = color * 0.3
	material.flags_unshaded = true
	mesh_instance.material_override = material

func setup_convergence_chart():
	"""Create chart to show convergence to π"""
	convergence_chart = Node3D.new()
	convergence_chart.position = Vector3(2.5, 0, 0)
	add_child(convergence_chart)
	
	# Chart background
	var bg = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(2.0, 1.5)
	bg.mesh = plane_mesh
	
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.1, 0.1, 0.1, 0.8)
	bg.material_override = bg_material
	
	convergence_chart.add_child(bg)
	
	# π reference line
	var pi_line = MeshInstance3D.new()
	var pi_points = [Vector3(-1.0, 0.0, 0.01), Vector3(1.0, 0.0, 0.01)]
	create_line_mesh(pi_line, pi_points, Color.RED)
	convergence_chart.add_child(pi_line)

func setup_integration_visual():
	"""Set up visualization for numerical integration"""
	# This would create visuals for integration under a curve
	pass

func setup_option_pricing_visual():
	"""Set up visualization for financial option pricing"""
	# This would create stock price paths visualization
	pass

func setup_random_walk_visual():
	"""Set up visualization for random walk simulation"""
	# This would create path visualization for random walks
	pass

func setup_info_display():
	"""Create information display"""
	info_display = Label3D.new()
	info_display.position = Vector3(-2.5, 1.5, 0)
	info_display.font_size = 24
	info_display.modulate = Color.WHITE
	add_child(info_display)
	update_info_display()

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		if is_running:
			stop_simulation()
		else:
			start_simulation()
	elif button_name == "grip_click":
		reset_simulation()

func _input(event):
	"""Handle desktop input"""
	if not enable_vr and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			if is_running:
				stop_simulation()
			else:
				start_simulation()
		elif event.keycode == KEY_R:
			reset_simulation()
		elif event.keycode == KEY_C:
			change_simulation_type()

func start_simulation():
	"""Start Monte Carlo simulation with animation"""
	if is_running:
		return
	
	is_running = true
	
	if simulation_tween:
		simulation_tween.kill()
	
	simulation_tween = create_tween()
	simulation_tween.set_loops()
	
	# Run simulation in batches
	for batch in range(sample_size / batch_size):
		simulation_tween.tween_callback(run_simulation_batch)
		simulation_tween.tween_delay(0.1 / animation_speed)
	
	simulation_tween.tween_callback(complete_simulation)

func run_simulation_batch():
	"""Run a batch of Monte Carlo samples"""
	match simulation_type:
		SimulationType.PI_ESTIMATION:
			run_pi_estimation_batch()
		SimulationType.INTEGRATION:
			run_integration_batch()
		SimulationType.OPTION_PRICING:
			run_option_pricing_batch()
		SimulationType.RANDOM_WALK:
			run_random_walk_batch()

func run_pi_estimation_batch():
	"""Run a batch of π estimation samples"""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(batch_size):
		if sample_count >= sample_size:
			break
		
		# Generate random point in square [-1,1] x [-1,1]
		var x = rng.randf_range(-circle_radius, circle_radius)
		var y = rng.randf_range(-circle_radius, circle_radius)
		
		# Check if point is inside circle
		var distance_squared = x * x + y * y
		var is_inside = distance_squared <= circle_radius * circle_radius
		
		if is_inside:
			inside_circle_count += 1
		
		sample_count += 1
		
		# Estimate π: (points inside circle / total points) * 4 = π
		var pi_estimate = 4.0 * float(inside_circle_count) / float(sample_count)
		pi_estimates.append(pi_estimate)
		
		# Visualize sample point
		if show_sample_points:
			create_sample_point(Vector3(x, y, 0), is_inside)
	
	update_convergence_chart()
	update_info_display()

func create_sample_point(position: Vector3, is_inside: bool):
	"""Create visual representation of a sample point"""
	var point = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.01
	point.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	if is_inside:
		material.albedo_color = Color.GREEN
		material.emission = Color.GREEN * 0.3
	else:
		material.albedo_color = Color.RED
		material.emission = Color.RED * 0.3
	point.material_override = material
	
	point.position = position
	add_child(point)
	sample_particles.append(point)
	
	# Limit number of visible points for performance
	if sample_particles.size() > 1000:
		var old_point = sample_particles.pop_front()
		old_point.queue_free()

func update_convergence_chart():
	"""Update the convergence chart showing π estimation"""
	# Clear existing convergence lines
	for child in convergence_chart.get_children():
		if child.name.begins_with("convergence_"):
			child.queue_free()
	
	if pi_estimates.size() < 2:
		return
	
	# Create convergence line
	var line_points: Array[Vector3] = []
	var max_samples = min(pi_estimates.size(), 200)  # Limit for performance
	
	for i in range(max_samples):
		var x = float(i) / float(max_samples) * 2.0 - 1.0
		var estimate = pi_estimates[i * pi_estimates.size() / max_samples]
		var y = (estimate - PI) / 2.0  # Scale around π
		line_points.append(Vector3(x, y, 0.02))
	
	var convergence_line = MeshInstance3D.new()
	convergence_line.name = "convergence_line"
	create_line_mesh(convergence_line, line_points, Color.YELLOW)
	convergence_chart.add_child(convergence_line)

func run_integration_batch():
	"""Run batch for numerical integration example"""
	# Example: integrate x² from 0 to 1
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Monte Carlo integration implementation would go here
	pass

func run_option_pricing_batch():
	"""Run batch for option pricing simulation"""
	# Black-Scholes option pricing via Monte Carlo would go here
	pass

func run_random_walk_batch():
	"""Run batch for random walk simulation"""
	# Random walk simulation would go here
	pass

func complete_simulation():
	"""Called when simulation completes"""
	is_running = false
	update_info_display()

func stop_simulation():
	"""Stop the running simulation"""
	if simulation_tween:
		simulation_tween.kill()
	is_running = false
	update_info_display()

func reset_simulation():
	"""Reset all simulation data"""
	stop_simulation()
	
	sample_count = 0
	inside_circle_count = 0
	pi_estimates.clear()
	sample_points.clear()
	
	# Clear visual elements
	for particle in sample_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	sample_particles.clear()
	
	# Clear convergence chart
	if convergence_chart:
		for child in convergence_chart.get_children():
			if child.name.begins_with("convergence_"):
				child.queue_free()
	
	update_info_display()

func change_simulation_type():
	"""Change the type of Monte Carlo simulation"""
	var current_index = simulation_type as int
	simulation_type = ((current_index + 1) % SimulationType.size()) as SimulationType
	
	reset_simulation()
	setup_visualization()

func update_info_display():
	"""Update information display"""
	var text = "Monte Carlo Simulation\n"
	text += "Type: %s\n\n" % get_simulation_type_name()
	
	match simulation_type:
		SimulationType.PI_ESTIMATION:
			text += "π Estimation\n"
			text += "Samples: %d/%d\n" % [sample_count, sample_size]
			text += "Inside circle: %d\n" % inside_circle_count
			
			if sample_count > 0:
				var current_estimate = 4.0 * float(inside_circle_count) / float(sample_count)
				var error = abs(current_estimate - PI)
				text += "Current π estimate: %.6f\n" % current_estimate
				text += "Actual π: %.6f\n" % PI
				text += "Error: %.6f\n" % error
				text += "Error %: %.3f%%" % (error / PI * 100.0)
			
			text += "\nRunning: %s" % ("Yes" if is_running else "No")
	
	info_display.text = text

func get_simulation_type_name() -> String:
	"""Get display name for current simulation type"""
	match simulation_type:
		SimulationType.PI_ESTIMATION:
			return "π Estimation"
		SimulationType.INTEGRATION:
			return "Numerical Integration"
		SimulationType.OPTION_PRICING:
			return "Option Pricing"
		SimulationType.RANDOM_WALK:
			return "Random Walk"
		_:
			return "Unknown"

func get_final_pi_estimate() -> float:
	"""Get the final π estimate"""
	if sample_count == 0:
		return 0.0
	return 4.0 * float(inside_circle_count) / float(sample_count)

func get_statistics_summary() -> Dictionary:
	"""Return comprehensive statistics"""
	return {
		"simulation_type": get_simulation_type_name(),
		"sample_count": sample_count,
		"target_samples": sample_size,
		"pi_estimate": get_final_pi_estimate(),
		"actual_pi": PI,
		"error": abs(get_final_pi_estimate() - PI),
		"inside_circle_count": inside_circle_count,
		"pi_estimates": pi_estimates.duplicate(),
		"is_running": is_running
	}
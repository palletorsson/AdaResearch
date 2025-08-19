extends Node3D

# Interactive VR Bayesian Inference - Prior and Posterior Updating
# Demonstrates Bayes' theorem through coin bias estimation

class_name BayesianInferenceVR

# VR Settings
@export_category("VR Configuration")
@export var enable_vr: bool = true

# Bayesian Settings
@export_category("Bayesian Parameters")
@export var true_coin_bias: float = 0.7  # Hidden true bias
@export var prior_alpha: float = 1.0     # Beta distribution prior
@export var prior_beta: float = 1.0
@export var max_observations: int = 100

# Visual Settings
@export_category("Visualization")
@export var curve_resolution: int = 200
@export var show_true_value: bool = false
@export var animate_updates: bool = true

# Internal variables
var observations: Array[bool] = []  # True = heads, False = tails
var posterior_alpha: float
var posterior_beta: float
var likelihood_history: Array[float] = []

# VR Components
var xr_origin: XROrigin3D
var controllers: Array[XRController3D] = []

# Visual Elements
var prior_curve: Node3D
var posterior_curve: Node3D
var likelihood_display: Node3D
var coin_display: Node3D
var info_display: Label3D
var observation_history: Node3D

# Animation
var update_tween: Tween

func _ready():
	setup_vr()
	initialize_bayesian_params()
	setup_visualization()
	setup_info_display()
	update_all_displays()

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

func initialize_bayesian_params():
	"""Initialize Bayesian inference parameters"""
	posterior_alpha = prior_alpha
	posterior_beta = prior_beta

func setup_visualization():
	"""Create visualization elements"""
	# Prior distribution display
	prior_curve = Node3D.new()
	prior_curve.position = Vector3(-2.5, 1.0, 0)
	add_child(prior_curve)
	create_distribution_curve(prior_curve, prior_alpha, prior_beta, Color.BLUE, "Prior")
	
	# Posterior distribution display
	posterior_curve = Node3D.new()
	posterior_curve.position = Vector3(2.5, 1.0, 0)
	add_child(posterior_curve)
	
	# Likelihood display
	likelihood_display = Node3D.new()
	likelihood_display.position = Vector3(0, 1.0, 0)
	add_child(likelihood_display)
	
	# Coin display
	coin_display = Node3D.new()
	coin_display.position = Vector3(0, -0.5, 0)
	add_child(coin_display)
	create_coin_visual()
	
	# Observation history
	observation_history = Node3D.new()
	observation_history.position = Vector3(0, -1.5, 0)
	add_child(observation_history)

func create_distribution_curve(parent: Node3D, alpha: float, beta: float, color: Color, label: String):
	"""Create beta distribution curve visualization"""
	# Clear existing curve
	for child in parent.get_children():
		child.queue_free()
	
	# Create curve points
	var curve_points: Array[Vector3] = []
	for i in range(curve_resolution + 1):
		var p = float(i) / float(curve_resolution)
		var density = beta_pdf(p, alpha, beta)
		var x = (p - 0.5) * 2.0  # Scale to [-1, 1]
		var y = density * 1.5     # Scale for visibility
		curve_points.append(Vector3(x, y, 0))
	
	# Create curve mesh
	var curve_mesh = MeshInstance3D.new()
	create_line_mesh(curve_mesh, curve_points, color)
	parent.add_child(curve_mesh)
	
	# Add label
	var label_3d = Label3D.new()
	label_3d.text = label + "\nα=%.1f, β=%.1f" % [alpha, beta]
	label_3d.position = Vector3(0, -0.5, 0)
	label_3d.font_size = 20
	label_3d.modulate = color
	parent.add_child(label_3d)
	
	# Add axes
	create_axes(parent)
	
	# Add true value line if enabled
	if show_true_value:
		create_true_value_line(parent, true_coin_bias, Color.RED)

func create_line_mesh(mesh_instance: MeshInstance3D, points: Array[Vector3], color: Color):
	"""Create line mesh from points"""
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

func create_axes(parent: Node3D):
	"""Create coordinate axes for probability plots"""
	# X-axis (probability)
	var x_axis = MeshInstance3D.new()
	var x_points = [Vector3(-1.0, 0, 0), Vector3(1.0, 0, 0)]
	create_line_mesh(x_axis, x_points, Color.WHITE)
	parent.add_child(x_axis)
	
	# Y-axis (density)
	var y_axis = MeshInstance3D.new()
	var y_points = [Vector3(0, 0, 0), Vector3(0, 1.5, 0)]
	create_line_mesh(y_axis, y_points, Color.WHITE)
	parent.add_child(y_axis)
	
	# Probability labels
	for p in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var label = Label3D.new()
		label.text = "%.2f" % p
		label.position = Vector3((p - 0.5) * 2.0, -0.2, 0)
		label.font_size = 12
		parent.add_child(label)

func create_true_value_line(parent: Node3D, value: float, color: Color):
	"""Create vertical line showing true parameter value"""
	var line = MeshInstance3D.new()
	var x_pos = (value - 0.5) * 2.0
	var line_points = [Vector3(x_pos, 0, 0.01), Vector3(x_pos, 1.5, 0.01)]
	create_line_mesh(line, line_points, color)
	parent.add_child(line)

func create_coin_visual():
	"""Create interactive coin for observations"""
	var coin = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 0.02
	cylinder_mesh.top_radius = 0.1
	cylinder_mesh.bottom_radius = 0.1
	coin.mesh = cylinder_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GOLD
	material.metallic = 0.8
	material.roughness = 0.2
	coin.material_override = material
	
	coin_display.add_child(coin)
	
	# Add instruction label
	var instruction = Label3D.new()
	instruction.text = "Press Trigger to Flip Coin"
	instruction.position = Vector3(0, 0.3, 0)
	instruction.font_size = 18
	coin_display.add_child(instruction)

func setup_info_display():
	"""Create information display"""
	info_display = Label3D.new()
	info_display.position = Vector3(-2.5, 2.5, 0)
	info_display.font_size = 20
	info_display.modulate = Color.WHITE
	add_child(info_display)

func _on_controller_button(button_name: String):
	"""Handle VR controller input"""
	if button_name == "trigger_click":
		flip_coin()
	elif button_name == "grip_click":
		reset_inference()

func _input(event):
	"""Handle desktop input"""
	if not enable_vr and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			flip_coin()
		elif event.keycode == KEY_R:
			reset_inference()
		elif event.keycode == KEY_T:
			show_true_value = !show_true_value
			update_all_displays()

func flip_coin():
	"""Flip coin and update Bayesian inference"""
	if observations.size() >= max_observations:
		return
	
	# Generate observation based on true bias
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var is_heads = rng.randf() < true_coin_bias
	
	# Add observation
	observations.append(is_heads)
	
	# Update posterior using Bayesian inference
	update_posterior(is_heads)
	
	# Animate the update
	if animate_updates:
		animate_coin_flip(is_heads)
	
	# Update displays
	update_all_displays()

func update_posterior(is_heads: bool):
	"""Update posterior distribution using Bayes' theorem"""
	# Beta-Binomial conjugate prior
	if is_heads:
		posterior_alpha += 1.0
	else:
		posterior_beta += 1.0
	
	# Calculate current likelihood for this observation
	var current_estimate = posterior_alpha / (posterior_alpha + posterior_beta)
	likelihood_history.append(current_estimate)

func animate_coin_flip(is_heads: bool):
	"""Animate coin flip result"""
	if update_tween:
		update_tween.kill()
	
	update_tween = create_tween()
	
	# Spin animation
	var coin = coin_display.get_child(0)
	update_tween.tween_property(coin, "rotation:y", coin.rotation.y + TAU * 3, 1.0)
	
	# Color change based on result
	var material = coin.material_override as StandardMaterial3D
	var result_color = Color.GREEN if is_heads else Color.RED
	update_tween.parallel().tween_property(material, "albedo_color", result_color, 0.5)
	update_tween.tween_property(material, "albedo_color", Color.GOLD, 0.5)

func update_all_displays():
	"""Update all visualization displays"""
	# Update posterior curve
	create_distribution_curve(posterior_curve, posterior_alpha, posterior_beta, Color.GREEN, "Posterior")
	
	# Update likelihood display
	update_likelihood_display()
	
	# Update observation history
	update_observation_history()
	
	# Update info display
	update_info_display_text()

func update_likelihood_display():
	"""Update likelihood visualization"""
	# Clear existing
	for child in likelihood_display.get_children():
		child.queue_free()
	
	if likelihood_history.is_empty():
		return
	
	# Create convergence line
	var line_points: Array[Vector3] = []
	for i in range(likelihood_history.size()):
		var x = float(i) / float(max_observations) * 2.0 - 1.0
		var y = likelihood_history[i] * 1.5
		line_points.append(Vector3(x, y, 0))
	
	var convergence_line = MeshInstance3D.new()
	create_line_mesh(convergence_line, line_points, Color.YELLOW)
	likelihood_display.add_child(convergence_line)
	
	# Add label
	var label = Label3D.new()
	label.text = "Estimate Convergence"
	label.position = Vector3(0, -0.5, 0)
	label.font_size = 18
	likelihood_display.add_child(label)
	
	# Add axes
	create_axes(likelihood_display)

func update_observation_history():
	"""Update visual history of observations"""
	# Clear existing
	for child in observation_history.get_children():
		child.queue_free()
	
	# Show recent observations (last 20)
	var start_index = max(0, observations.size() - 20)
	for i in range(start_index, observations.size()):
		var obs_index = i - start_index
		var x_pos = float(obs_index) / 20.0 * 4.0 - 2.0
		
		var obs_visual = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.03
		obs_visual.mesh = sphere_mesh
		
		var material = StandardMaterial3D.new()
		if observations[i]:  # Heads
			material.albedo_color = Color.GREEN
		else:  # Tails
			material.albedo_color = Color.RED
		obs_visual.material_override = material
		
		obs_visual.position = Vector3(x_pos, 0, 0)
		observation_history.add_child(obs_visual)
	
	# Add label
	var label = Label3D.new()
	label.text = "Recent Observations (Green=Heads, Red=Tails)"
	label.position = Vector3(0, 0.3, 0)
	label.font_size = 16
	observation_history.add_child(label)

func update_info_display_text():
	"""Update information text"""
	var text = "Bayesian Coin Bias Estimation\n\n"
	text += "Observations: %d/%d\n" % [observations.size(), max_observations]
	
	if observations.size() > 0:
		var heads_count = 0
		for obs in observations:
			if obs:
				heads_count += 1
		
		var frequentist_estimate = float(heads_count) / float(observations.size())
		var bayesian_estimate = posterior_alpha / (posterior_alpha + posterior_beta)
		var credible_interval = calculate_credible_interval(0.95)
		
		text += "\nResults:\n"
		text += "Heads: %d (%.1f%%)\n" % [heads_count, frequentist_estimate * 100]
		text += "Frequentist estimate: %.3f\n" % frequentist_estimate
		text += "Bayesian estimate: %.3f\n" % bayesian_estimate
		text += "95%% Credible Interval:\n"
		text += "  [%.3f, %.3f]\n" % [credible_interval[0], credible_interval[1]]
		
		if show_true_value:
			text += "\nTrue bias: %.3f\n" % true_coin_bias
			text += "Bayesian error: %.3f" % abs(bayesian_estimate - true_coin_bias)
	
	text += "\n\nPrior: Beta(%.1f, %.1f)\n" % [prior_alpha, prior_beta]
	text += "Posterior: Beta(%.1f, %.1f)" % [posterior_alpha, posterior_beta]
	
	info_display.text = text

func calculate_credible_interval(confidence: float) -> Array[float]:
	"""Calculate Bayesian credible interval"""
	var alpha_tail = (1.0 - confidence) / 2.0
	
	# For Beta distribution, use quantile function (approximation)
	var lower = beta_quantile(alpha_tail, posterior_alpha, posterior_beta)
	var upper = beta_quantile(1.0 - alpha_tail, posterior_alpha, posterior_beta)
	
	return [lower, upper]

func beta_pdf(x: float, alpha: float, beta: float) -> float:
	"""Beta probability density function"""
	if x <= 0.0 or x >= 1.0:
		return 0.0
	return pow(x, alpha - 1.0) * pow(1.0 - x, beta - 1.0) / beta_function(alpha, beta)

func beta_function(alpha: float, beta: float) -> float:
	"""Beta function B(α,β) = Γ(α)Γ(β)/Γ(α+β)"""
	# Approximation using gamma function properties
	return exp(log_gamma(alpha) + log_gamma(beta) - log_gamma(alpha + beta))

func log_gamma(x: float) -> float:
	"""Logarithm of gamma function (Stirling's approximation)"""
	if x < 1.0:
		return log_gamma(x + 1.0) - log(x)
	return (x - 0.5) * log(x) - x + 0.5 * log(2.0 * PI)

func beta_quantile(p: float, alpha: float, beta: float) -> float:
	"""Beta distribution quantile function (approximation)"""
	# Simple approximation for demonstration
	var mean = alpha / (alpha + beta)
	var variance = (alpha * beta) / ((alpha + beta) * (alpha + beta) * (alpha + beta + 1))
	var std_dev = sqrt(variance)
	
	# Normal approximation (rough)
	var z_score = 0.0
	if p < 0.5:
		z_score = -1.96  # Approximate for 0.025
	else:
		z_score = 1.96   # Approximate for 0.975
	
	var result = mean + z_score * std_dev
	return clamp(result, 0.001, 0.999)

func reset_inference():
	"""Reset all inference data"""
	observations.clear()
	likelihood_history.clear()
	posterior_alpha = prior_alpha
	posterior_beta = prior_beta
	
	update_all_displays()

func get_statistics_summary() -> Dictionary:
	"""Return comprehensive statistics"""
	var heads_count = 0
	for obs in observations:
		if obs:
			heads_count += 1
	
	return {
		"true_bias": true_coin_bias,
		"observations_count": observations.size(),
		"heads_count": heads_count,
		"frequentist_estimate": float(heads_count) / float(observations.size()) if observations.size() > 0 else 0.0,
		"bayesian_estimate": posterior_alpha / (posterior_alpha + posterior_beta),
		"prior_alpha": prior_alpha,
		"prior_beta": prior_beta,
		"posterior_alpha": posterior_alpha,
		"posterior_beta": posterior_beta,
		"credible_interval": calculate_credible_interval(0.95),
		"observations": observations.duplicate()
	}
extends Node3D

# VR-Reimagined Explainable AI (XAI)
# Interactive visualization of model explanations
# SHAP, LIME, Grad-CAM with spatial manipulation

@export_group("VR Scale")
@export var feature_spacing: float = 1.5  # Space between features
@export var importance_scale: float = 2.0  # Height scale for importance
@export var zone_spacing: float = 10.0  # Distance between explanation zones

@export_group("Model Settings")
@export var num_features: int = 10  # Number of input features
@export var num_perturbations: int = 20  # LIME perturbations
@export var num_attention_points: int = 16  # Grad-CAM resolution

@export_group("XAI Methods")
@export var show_shap: bool = true
@export var show_lime: bool = true
@export var show_grad_cam: bool = true
@export var enable_counterfactuals: bool = true

@export_group("Interactive Elements")
@export var enable_feature_manipulation: bool = true
@export var show_confidence: bool = true
@export var show_decision_boundary: bool = true
@export var animate_explanations: bool = true

# Model state
var time: float = 0.0
var current_prediction: String = "Cat"
var prediction_confidence: float = 0.87
var feature_values: Array = []
var feature_importance: Array = []  # SHAP values

# Explanation zones
var shap_zone: Node3D
var lime_zone: Node3D
var grad_cam_zone: Node3D

# Visual elements
var feature_bars: Array = []
var perturbation_spheres: Array = []
var heatmap_points: Array = []
var counterfactual_path: Array = []

func _ready():
	print("[XAI_VR] Initializing explainable AI workspace")
	_initialize_model_data()
	_create_prediction_display()
	_create_shap_zone()
	_create_lime_zone()
	_create_grad_cam_zone()
	_create_counterfactual_explorer()
	_create_control_panel()
	_create_info_panels()

func _process(delta):
	time += delta

	if animate_explanations:
		_animate_shap_values(delta)
		_animate_perturbations(delta)
		_animate_heatmap(delta)

	_update_confidence_display(delta)

func _initialize_model_data():
	"""Initialize feature values and importance scores"""
	var feature_names = ["Whiskers", "Ears", "Tail", "Fur", "Eyes", "Paws", "Nose", "Size", "Color", "Shape"]

	for i in range(num_features):
		feature_values.append(randf())

		# Simulate SHAP values (positive = supports prediction, negative = opposes)
		var importance = randf_range(-0.5, 1.0)
		feature_importance.append(importance)

func _create_prediction_display():
	"""Create central prediction display"""
	var prediction_container = Node3D.new()
	prediction_container.name = "PredictionDisplay"
	prediction_container.position = Vector3(0, 4.0, 0)
	add_child(prediction_container)

	# Prediction sphere
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.height = 2.0
	sphere.mesh = sphere_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.9)
	mat.emission_energy_multiplier = 1.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	sphere.material_override = mat
	prediction_container.add_child(sphere)

	# Prediction label
	var label = Label3D.new()
	label.name = "PredictionLabel"
	label.text = "PREDICTION: %s\n%.0f%% confident" % [current_prediction, prediction_confidence * 100]
	label.font_size = 64
	label.outline_size = 14
	label.modulate = Color(0.3, 0.9, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.8, 0)
	prediction_container.add_child(label)

func _create_shap_zone():
	"""Create SHAP values visualization zone"""
	if not show_shap:
		return

	shap_zone = Node3D.new()
	shap_zone.name = "SHAP_Zone"
	shap_zone.position = Vector3(-zone_spacing, 0, 0)
	add_child(shap_zone)

	# Zone label
	var label = Label3D.new()
	label.text = "SHAP VALUES\nFeature Importance"
	label.font_size = 56
	label.outline_size = 14
	label.modulate = Color(0.9, 0.3, 0.5)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 4.0, 0)
	shap_zone.add_child(label)

	# Create feature importance bars
	var feature_names = ["Whiskers", "Ears", "Tail", "Fur", "Eyes", "Paws", "Nose", "Size", "Color", "Shape"]

	for i in range(num_features):
		var bar = _create_importance_bar(i, feature_names[i], feature_importance[i])
		var y_pos = (i - num_features / 2.0 + 0.5) * feature_spacing
		bar.position = Vector3(0, y_pos, 0)
		shap_zone.add_child(bar)
		feature_bars.append(bar)

	# Base line (zero importance)
	var baseline = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.02
	cyl.height = num_features * feature_spacing + 1.0
	baseline.mesh = cyl

	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.5, 0.5, 0.5)
	base_mat.emission_enabled = true
	base_mat.emission = Color(0.5, 0.5, 0.5)
	base_mat.emission_energy_multiplier = 0.3
	baseline.material_override = base_mat

	baseline.position = Vector3(0, 0, 0)
	shap_zone.add_child(baseline)

func _create_importance_bar(index: int, feature_name: String, importance: float) -> Node3D:
	"""Create a horizontal bar showing feature importance"""
	var container = Node3D.new()
	container.name = "Feature_%d" % index

	# Bar extending from center
	var bar_body = RigidBody3D.new()
	bar_body.gravity_scale = 0.0

	var bar = MeshInstance3D.new()
	var box = BoxMesh.new()
	var bar_length = abs(importance) * importance_scale
	box.size = Vector3(bar_length, 0.3, 0.3)
	bar.mesh = box

	var mat = StandardMaterial3D.new()
	if importance > 0:
		# Positive = supports prediction (green)
		mat.albedo_color = Color(0.3, 0.9, 0.3)
		mat.emission = Color(0.3, 0.9, 0.3)
	else:
		# Negative = opposes prediction (red)
		mat.albedo_color = Color(0.9, 0.3, 0.3)
		mat.emission = Color(0.9, 0.3, 0.3)

	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.0
	mat.metallic = 0.0
	mat.roughness = 1.0
	bar.material_override = mat

	# Position bar extending from center
	bar.position = Vector3(importance * importance_scale / 2.0, 0, 0)
	bar_body.add_child(bar)

	# Collision for grabbing
	if enable_feature_manipulation:
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = box.size
		collision.shape = shape
		collision.position = bar.position
		bar_body.add_child(collision)

		bar_body.collision_layer = 1 | (1 << 20)
		bar_body.collision_mask = 1

	container.add_child(bar_body)

	# Feature label
	var label = Label3D.new()
	label.text = feature_name
	label.font_size = 28
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(-1.5, 0, 0)
	container.add_child(label)

	# Value label
	var value_label = Label3D.new()
	value_label.text = "%.2f" % importance
	value_label.font_size = 24
	value_label.outline_size = 6
	value_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	value_label.position = Vector3(importance * importance_scale + 0.5, 0, 0)
	container.add_child(value_label)

	return container

func _create_lime_zone():
	"""Create LIME local explanations zone"""
	if not show_lime:
		return

	lime_zone = Node3D.new()
	lime_zone.name = "LIME_Zone"
	lime_zone.position = Vector3(0, 0, 0)
	add_child(lime_zone)

	# Zone label
	var label = Label3D.new()
	label.text = "LIME\nLocal Perturbations"
	label.font_size = 56
	label.outline_size = 14
	label.modulate = Color(0.3, 0.9, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 4.0, 0)
	lime_zone.add_child(label)

	# Central data point (the instance being explained)
	var center_point = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	center_point.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.3)
	mat.emission_energy_multiplier = 1.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	center_point.material_override = mat
	lime_zone.add_child(center_point)

	# Create perturbation cloud
	for i in range(num_perturbations):
		var perturbation = _create_perturbation_point()
		lime_zone.add_child(perturbation)
		perturbation_spheres.append(perturbation)

	# Decision boundary surface (simplified as plane)
	if show_decision_boundary:
		_create_decision_boundary(lime_zone)

func _create_perturbation_point() -> MeshInstance3D:
	"""Create a perturbed sample point"""
	var point = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	point.mesh = sphere

	# Random position in local neighborhood
	var angle1 = randf() * TAU
	var angle2 = randf() * PI
	var radius = randf_range(1.0, 3.0)

	point.position = Vector3(
		cos(angle1) * sin(angle2) * radius,
		sin(angle1) * sin(angle2) * radius,
		cos(angle2) * radius
	)

	# Color based on prediction (simulated)
	var predicted_class = randi() % 2
	var mat = StandardMaterial3D.new()
	if predicted_class == 0:
		mat.albedo_color = Color(0.3, 0.9, 0.3, 0.6)
		mat.emission = Color(0.3, 0.9, 0.3)
	else:
		mat.albedo_color = Color(0.9, 0.3, 0.3, 0.6)
		mat.emission = Color(0.9, 0.3, 0.3)

	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.0
	mat.roughness = 1.0
	point.material_override = mat

	return point

func _create_decision_boundary(parent: Node3D):
	"""Create decision boundary visualization"""
	var boundary = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(6.0, 6.0)
	boundary.mesh = plane

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.9, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.5, 0.9)
	mat.emission_energy_multiplier = 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.metallic = 0.0
	mat.roughness = 1.0
	boundary.material_override = mat

	boundary.rotation.x = PI / 4.0
	boundary.rotation.z = PI / 6.0
	parent.add_child(boundary)

	# Boundary label
	var label = Label3D.new()
	label.text = "Decision Boundary"
	label.font_size = 32
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0, 3.5)
	parent.add_child(label)

func _create_grad_cam_zone():
	"""Create Grad-CAM attention heatmap zone"""
	if not show_grad_cam:
		return

	grad_cam_zone = Node3D.new()
	grad_cam_zone.name = "GradCAM_Zone"
	grad_cam_zone.position = Vector3(zone_spacing, 0, 0)
	add_child(grad_cam_zone)

	# Zone label
	var label = Label3D.new()
	label.text = "GRAD-CAM\nAttention Heatmap"
	label.font_size = 56
	label.outline_size = 14
	label.modulate = Color(0.9, 0.5, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 4.0, 0)
	grad_cam_zone.add_child(label)

	# Create 3D heatmap (heightmap based on attention)
	for y in range(num_attention_points):
		for x in range(num_attention_points):
			var heatmap_point = _create_heatmap_point(x, y)
			grad_cam_zone.add_child(heatmap_point)
			heatmap_points.append(heatmap_point)

func _create_heatmap_point(x: int, y: int) -> MeshInstance3D:
	"""Create a single heatmap point"""
	var point = MeshInstance3D.new()
	var box = BoxMesh.new()

	# Simulate attention value (higher in center)
	var center_x = num_attention_points / 2.0
	var center_y = num_attention_points / 2.0
	var dist = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
	var attention = exp(-dist / 4.0)  # Gaussian falloff

	box.size = Vector3(0.25, attention * 2.0, 0.25)
	point.mesh = box

	# Color based on attention (red = high, blue = low)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(attention, 0.3, 1.0 - attention)
	mat.emission_enabled = true
	mat.emission = Color(attention, 0.3, 1.0 - attention)
	mat.emission_energy_multiplier = 1.0
	mat.metallic = 0.0
	mat.roughness = 1.0
	point.material_override = mat

	# Position in grid
	var grid_size = 4.0
	var px = (float(x) / num_attention_points - 0.5) * grid_size
	var py = (float(y) / num_attention_points - 0.5) * grid_size
	point.position = Vector3(px, attention, py)

	return point

func _create_counterfactual_explorer():
	"""Create counterfactual explanation explorer"""
	if not enable_counterfactuals:
		return

	var cf_container = Node3D.new()
	cf_container.name = "CounterfactualExplorer"
	cf_container.position = Vector3(0, -4.0, 0)
	add_child(cf_container)

	# Label
	var label = Label3D.new()
	label.text = "COUNTERFACTUALS\nWhat if...?"
	label.font_size = 48
	label.outline_size = 12
	label.modulate = Color(0.9, 0.9, 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.5, 0)
	cf_container.add_child(label)

	# Create path from current to counterfactual
	var num_steps = 5
	for i in range(num_steps):
		var sphere = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.2
		sphere_mesh.height = 0.4
		sphere.mesh = sphere_mesh

		var t = float(i) / (num_steps - 1)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0 - t, 0.5, t)  # Gradient from red to blue
		mat.emission_enabled = true
		mat.emission = Color(1.0 - t, 0.5, t)
		mat.emission_energy_multiplier = 1.0
		mat.metallic = 0.0
		mat.roughness = 1.0
		sphere.material_override = mat

		sphere.position = Vector3(i * 1.0 - 2.0, 0, 0)
		cf_container.add_child(sphere)
		counterfactual_path.append(sphere)

		# Step label
		if i == 0:
			var step_label = Label3D.new()
			step_label.text = "Current"
			step_label.font_size = 24
			step_label.outline_size = 6
			step_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			step_label.position = Vector3(i * 1.0 - 2.0, -0.5, 0)
			cf_container.add_child(step_label)
		elif i == num_steps - 1:
			var step_label = Label3D.new()
			step_label.text = "Different\nPrediction"
			step_label.font_size = 24
			step_label.outline_size = 6
			step_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			step_label.position = Vector3(i * 1.0 - 2.0, -0.5, 0)
			cf_container.add_child(step_label)

func _create_control_panel():
	"""Create VR control panel"""
	var controls = Node3D.new()
	controls.name = "ControlPanel"
	controls.position = Vector3(zone_spacing + 5.0, 0, 0)
	add_child(controls)

	# Panel background
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 4.0, 0.1)
	panel.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.3, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.0
	mat.roughness = 1.0
	panel.material_override = mat
	controls.add_child(panel)

	# Title
	var title = Label3D.new()
	title.text = "EXPLAINABLE AI\nMETHODS"
	title.font_size = 56
	title.outline_size = 12
	title.position = Vector3(0, 1.6, 0.1)
	controls.add_child(title)

	# Methods enabled
	var methods = "SHAP: %s\nLIME: %s\nGrad-CAM: %s" % [
		"ON" if show_shap else "OFF",
		"ON" if show_lime else "OFF",
		"ON" if show_grad_cam else "OFF"
	]
	var methods_label = Label3D.new()
	methods_label.text = methods
	methods_label.font_size = 32
	methods_label.outline_size = 8
	methods_label.position = Vector3(0, 0.2, 0.1)
	controls.add_child(methods_label)

	# Confidence display
	var confidence = Label3D.new()
	confidence.name = "ConfidenceLabel"
	confidence.text = "Confidence: %.0f%%" % (prediction_confidence * 100)
	confidence.font_size = 36
	confidence.outline_size = 8
	confidence.position = Vector3(0, -1.0, 0.1)
	controls.add_child(confidence)

func _create_info_panels():
	"""Create educational info panels"""
	# SHAP explanation
	if show_shap:
		_create_info_panel(
			Vector3(-zone_spacing, 5.5, -3.0),
			"SHAP VALUES\nGame theory approach\nGlobal feature importance\nAdditive explanations",
			Color(0.9, 0.3, 0.5)
		)

	# LIME explanation
	if show_lime:
		_create_info_panel(
			Vector3(0, 5.5, -3.0),
			"LIME\nLocal surrogate model\nPerturbation-based\nInterpretable locally",
			Color(0.3, 0.9, 0.3)
		)

	# Grad-CAM explanation
	if show_grad_cam:
		_create_info_panel(
			Vector3(zone_spacing, 5.5, -3.0),
			"GRAD-CAM\nGradient-based attention\nVisual explanations\nClass activation maps",
			Color(0.9, 0.5, 0.3)
		)

func _create_info_panel(pos: Vector3, text: String, color: Color):
	"""Create floating info panel"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 32
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)

func _animate_shap_values(_delta):
	"""Animate SHAP feature bars"""
	for bar in feature_bars:
		var pulse = 1.0 + sin(time * 2.0) * 0.05
		bar.scale = Vector3(pulse, pulse, pulse)

func _animate_perturbations(delta):
	"""Animate LIME perturbation points"""
	for point in perturbation_spheres:
		# Gentle floating motion
		var original_y = point.position.y
		point.position.y += sin(time * 1.5 + point.position.x) * delta * 0.3

func _animate_heatmap(_delta):
	"""Animate Grad-CAM heatmap"""
	for point in heatmap_points:
		var pulse = 1.0 + sin(time * 2.0 + point.position.x + point.position.z) * 0.1
		point.scale = Vector3(pulse, 1.0, pulse)

func _update_confidence_display(_delta):
	"""Update confidence meter"""
	var controls = get_node_or_null("ControlPanel")
	if not controls:
		return

	var confidence_label = controls.get_node_or_null("ConfidenceLabel")
	if confidence_label:
		confidence_label.text = "Confidence: %.0f%%" % (prediction_confidence * 100)

# Public API
func set_feature_importance(feature_idx: int, importance: float):
	"""Set SHAP value for a feature"""
	if feature_idx >= 0 and feature_idx < feature_importance.size():
		feature_importance[feature_idx] = clamp(importance, -1.0, 1.0)

func highlight_feature(feature_idx: int):
	"""Highlight a specific feature"""
	print("[XAI] Highlighting feature %d" % feature_idx)

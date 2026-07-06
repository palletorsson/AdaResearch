extends Node3D

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: explanation(model, input) → feature importance; three methods: SHAP (game theory), LIME (local surrogate), Grad-CAM (gradient attention)
# desire: see WHY a model decided — grab feature bars, walk through perturbation clouds, read attention heatmaps
# critical_parameter: feature_importance — the SHAP values that reveal which inputs the model actually used
# triggers: switching XAI methods recolors the entire scene; manipulating features changes the explanation
# emerges: the realization that different explanation methods disagree — there is no single "true" explanation
# needs: grabbable SHAP bars [has], perturbation cloud [has], heatmap visualization [has], counterfactual path [has]
# relationships: depends on neural_networks_vr (must have a model to explain); contrasts anomaly_detection (detecting vs explaining)
# truth: a model that cannot explain itself is not understood — it is merely obeyed

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

# Integrated-board holders for runtime-updated readouts
var _prediction_holder: Node3D
var _control_holder: Node3D

func _ready() -> void:
	print("[XAI_VR] Initializing explainable AI workspace")
	_initialize_model_data()
	_create_prediction_display()
	_create_shap_zone()
	_create_lime_zone()
	_create_grad_cam_zone()
	_create_counterfactual_explorer()
	_create_control_panel()

func _process(delta: float) -> void:
	time += delta

	if animate_explanations:
		_animate_shap_values(delta)
		_animate_perturbations(delta)
		_animate_heatmap(delta)

	_update_confidence_display(delta)

func _initialize_model_data() -> void:
	"""Initialize feature values and importance scores"""
	var feature_names = ["Whiskers", "Ears", "Tail", "Fur", "Eyes", "Paws", "Nose", "Size", "Color", "Shape"]

	for i in range(num_features):
		feature_values.append(randf())

		# Simulate SHAP values (positive = supports prediction, negative = opposes)
		var importance = randf_range(-0.5, 1.0)
		feature_importance.append(importance)

func _create_prediction_display() -> void:
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

	# Prediction readout — one integrated board on a surface (no floating label).
	# Two lines consolidated onto a single billboarded tag stack; rebuilt on
	# confidence change via _rebuild_prediction_board().
	_prediction_holder = Node3D.new()
	_prediction_holder.name = "PredictionBoard"
	_prediction_holder.position = Vector3(0, 2.0, 0)
	prediction_container.add_child(_prediction_holder)
	_rebuild_prediction_board()

func _create_shap_zone() -> void:
	"""Create SHAP values visualization zone"""
	if not show_shap:
		return

	shap_zone = Node3D.new()
	shap_zone.name = "SHAP_Zone"
	shap_zone.position = Vector3(-zone_spacing, 0, 0)
	add_child(shap_zone)

	# Zone header — one integrated board (title + method info consolidated).
	_add_zone_header(
		shap_zone, Vector3(0, 5.2, 0),
		"SHAP VALUES",
		["Feature Importance", "Game theory approach", "Global + additive"],
		Color(0.95, 0.55, 0.72))

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

	# Feature name tag — a small integrated board to the LEFT of the baseline,
	# clear of the bar which extends the other way (no overlap with the value tag).
	var name_tag: Node3D = BakedText.make_tag(
		feature_name, Color(0.92, 0.94, 1.0), 0.34,
		Color(0.08, 0.09, 0.12), true, Color(0.55, 0.55, 0.6))
	if name_tag:
		name_tag.position = Vector3(-1.6, 0, 0)
		container.add_child(name_tag)

	# Value tag — sits just past the bar's tip, on the same side it extends,
	# so name (left) and value (right of tip) never collide.
	var accent := Color(0.3, 0.9, 0.3) if importance > 0 else Color(0.9, 0.3, 0.3)
	var value_tag: Node3D = BakedText.make_tag(
		"%.2f" % importance, Color(0.95, 0.97, 1.0), 0.30,
		Color(0.08, 0.09, 0.12), true, accent)
	if value_tag:
		value_tag.name = "ValueTag"
		value_tag.position = Vector3(importance * importance_scale + 0.55, 0, 0)
		container.add_child(value_tag)

	return container

func _create_lime_zone() -> void:
	"""Create LIME local explanations zone"""
	if not show_lime:
		return

	lime_zone = Node3D.new()
	lime_zone.name = "LIME_Zone"
	lime_zone.position = Vector3(0, 0, 0)
	add_child(lime_zone)

	# Zone header — one integrated board (title + method info consolidated).
	_add_zone_header(
		lime_zone, Vector3(0, 5.2, 0),
		"LIME",
		["Local Perturbations", "Local surrogate model", "Interpretable locally"],
		Color(0.4, 0.92, 0.45))

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

func _create_decision_boundary(parent: Node3D) -> void:
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

	# Boundary tag — integrated board clear of the tilted plane.
	var tag: Node3D = BakedText.make_tag(
		"Decision Boundary", Color(0.7, 0.75, 1.0), 0.4,
		Color(0.08, 0.09, 0.14), true, Color(0.5, 0.5, 0.9))
	if tag:
		tag.position = Vector3(0, 0, 3.6)
		parent.add_child(tag)

func _create_grad_cam_zone() -> void:
	"""Create Grad-CAM attention heatmap zone"""
	if not show_grad_cam:
		return

	grad_cam_zone = Node3D.new()
	grad_cam_zone.name = "GradCAM_Zone"
	grad_cam_zone.position = Vector3(zone_spacing, 0, 0)
	add_child(grad_cam_zone)

	# Zone header — one integrated board (title + method info consolidated).
	_add_zone_header(
		grad_cam_zone, Vector3(0, 5.2, 0),
		"GRAD-CAM",
		["Attention Heatmap", "Gradient-based attention", "Class activation maps"],
		Color(0.95, 0.6, 0.4))

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

func _create_counterfactual_explorer() -> void:
	"""Create counterfactual explanation explorer"""
	if not enable_counterfactuals:
		return

	var cf_container = Node3D.new()
	cf_container.name = "CounterfactualExplorer"
	cf_container.position = Vector3(0, -4.0, 0)
	add_child(cf_container)

	# Header — one integrated board above the path.
	_add_zone_header(
		cf_container, Vector3(0, 1.8, 0),
		"COUNTERFACTUALS",
		["What if...?"],
		Color(0.95, 0.9, 0.4))

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

		# Step tag — integrated board below each endpoint of the path.
		var step_text := ""
		if i == 0:
			step_text = "Current"
		elif i == num_steps - 1:
			step_text = "Different Prediction"
		if step_text != "":
			var step_tag: Node3D = BakedText.make_tag(
				step_text, Color(0.92, 0.94, 1.0), 0.3,
				Color(0.08, 0.09, 0.12), true, Color(1.0 - t, 0.5, t))
			if step_tag:
				step_tag.position = Vector3(i * 1.0 - 2.0, -0.6, 0)
				cf_container.add_child(step_tag)

func _create_control_panel() -> void:
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

	# One integrated readout ONTO the panel face — title, method states and the
	# runtime confidence consolidated into a single spaced text block (was 3
	# overlapping Label3Ds). Rebuilt in place when confidence changes.
	_control_holder = Node3D.new()
	_control_holder.name = "ControlReadout"
	_control_holder.position = Vector3(0, 0, 0.06)
	controls.add_child(_control_holder)
	_rebuild_control_board()

# ── Integrated-board builders (the fire_extinguisher / one-body principle) ──

## A zone header: a framed title tag with a spaced multi-line info block on an
## opaque plate below it. Consolidates the old floating zone-label + separate
## info-panel into one non-overlapping unit anchored at `pos`.
func _add_zone_header(parent: Node3D, pos: Vector3, title: String,
		info_lines: Array, color: Color) -> void:
	var header := Node3D.new()
	header.name = "ZoneHeader"
	header.position = pos
	parent.add_child(header)

	# Title board.
	var title_tag: Node3D = BakedText.make_tag(
		title, Color(1.0, 1.0, 1.0), 0.7,
		Color(0.09, 0.10, 0.14), true, color)
	if title_tag:
		title_tag.position = Vector3(0, 0, 0)
		header.add_child(title_tag)

	# Info block on an opaque plate below the title — spaced lines, no overlap.
	if info_lines.size() > 0:
		var line_h := 0.34
		var gap := 0.14
		var block_w := 3.4
		var n := info_lines.size()
		var block_h: float = (line_h + gap) * n + 0.28

		var plate: MeshInstance3D = BakedText.make_panel_mesh(
			"", Color(0.06, 0.07, 0.10, 0.92), color,
			Vector2(block_w, block_h), 1400, false)
		if plate:
			plate.name = "InfoPlate"
			plate.position = Vector3(0, -0.55 - block_h * 0.5, -0.01)
			var pm = plate.material_override
			if pm is StandardMaterial3D:
				pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			header.add_child(plate)

		var block: Node3D = BakedText.make_text_block(
			info_lines, color, line_h, block_w * 0.9, gap, false)
		block.position = Vector3(0, -0.55 - block_h * 0.5, 0.01)
		for c in block.get_children():
			if c is MeshInstance3D and c.material_override is StandardMaterial3D:
				c.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		header.add_child(block)

## Central prediction readout — a single two-line integrated board, rebuilt when
## the prediction/confidence changes (replaces the floating Label3D).
func _rebuild_prediction_board() -> void:
	if not is_instance_valid(_prediction_holder):
		return
	for c in _prediction_holder.get_children():
		c.queue_free()
	var lines := [
		"PREDICTION: %s" % current_prediction,
		"%.0f%% confident" % (prediction_confidence * 100.0),
	]
	var block: Node3D = BakedText.make_text_block(
		lines, Color(0.35, 0.95, 0.95), 0.5, 3.6, 0.14, true)
	for c in block.get_children():
		if c is MeshInstance3D and c.material_override is StandardMaterial3D:
			c.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_prediction_holder.add_child(block)

## Control-panel readout — title + method states + confidence consolidated onto
## ONE spaced text block on the panel face. Rebuilt when confidence changes.
func _rebuild_control_board() -> void:
	if not is_instance_valid(_control_holder):
		return
	for c in _control_holder.get_children():
		c.queue_free()
	var lines := [
		"EXPLAINABLE AI",
		"METHODS",
		"",
		"SHAP:     %s" % ("ON" if show_shap else "OFF"),
		"LIME:     %s" % ("ON" if show_lime else "OFF"),
		"Grad-CAM: %s" % ("ON" if show_grad_cam else "OFF"),
		"",
		"Confidence: %.0f%%" % (prediction_confidence * 100.0),
	]
	var block: Node3D = BakedText.make_text_block(
		lines, Color(0.9, 0.94, 1.0), 0.3, 2.7, 0.1, true)
	_control_holder.add_child(block)

func _animate_shap_values(_delta) -> void:
	"""Animate SHAP feature bars"""
	for bar in feature_bars:
		var pulse = 1.0 + sin(time * 2.0) * 0.05
		bar.scale = Vector3(pulse, pulse, pulse)

func _animate_perturbations(delta) -> void:
	"""Animate LIME perturbation points"""
	for point in perturbation_spheres:
		# Gentle floating motion
		var original_y = point.position.y
		point.position.y += sin(time * 1.5 + point.position.x) * delta * 0.3

func _animate_heatmap(_delta) -> void:
	"""Animate Grad-CAM heatmap"""
	for point in heatmap_points:
		var pulse = 1.0 + sin(time * 2.0 + point.position.x + point.position.z) * 0.1
		point.scale = Vector3(pulse, 1.0, pulse)

var _last_shown_confidence: float = -1.0

func _update_confidence_display(_delta) -> void:
	"""Rebuild the integrated confidence readouts only when the value changes."""
	if abs(prediction_confidence - _last_shown_confidence) < 0.005:
		return
	_last_shown_confidence = prediction_confidence
	_rebuild_control_board()
	_rebuild_prediction_board()

# Public API
func set_feature_importance(feature_idx: int, importance: float) -> void:
	"""Set SHAP value for a feature"""
	if feature_idx >= 0 and feature_idx < feature_importance.size():
		feature_importance[feature_idx] = clamp(importance, -1.0, 1.0)

func highlight_feature(feature_idx: int) -> void:
	"""Highlight a specific feature"""
	print("[XAI] Highlighting feature %d" % feature_idx)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass

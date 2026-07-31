extends Node3D

# @identity
# essence: max margin: min ||w||² s.t. yᵢ(w·xᵢ + b) ≥ 1; kernel trick maps to higher dimensions
# desire: see the maximum-margin hyperplane crystallize between classes, support vectors glowing gold at the boundary
# critical_parameter: C_parameter — regularization; low C allows misclassification for wider margin, high C demands perfection
# triggers: auto_start runs SMO optimization; kernel_type switches between linear, polynomial, RBF, sigmoid decision boundaries
# emerges: support vectors — the few critical points that define the entire boundary; most data points are irrelevant
# needs: VR controls [missing] — exported params but no spatial sliders
# relationships: contrasts enhanced_kmeans (supervised vs unsupervised); contrasts random_forest_visualization (single optimal boundary vs ensemble of approximations)
# truth: the decision boundary depends on only a few points — most of the data is redundant once the margin is found

# =============================================================================
# SVM — Support Vector Machine Visualization
# =============================================================================
# Visualizes classification with maximum-margin separating hyperplanes.
# Positive (green) and negative (red) data points are shown as spheres.
# The decision boundary is rendered as a point cloud. Support vectors are
# highlighted with golden glow and enlarged size.
# Uses a simplified SMO (Sequential Minimal Optimization) solver.
# =============================================================================

# --- Color Palette -----------------------------------------------------------
const COLOR_DATA := Color(0.3, 0.5, 0.9)       # Blues for data
const COLOR_POSITIVE_SVM := Color(0.3, 0.85, 0.4) # Green for +1 class
const COLOR_NEGATIVE_SVM := Color(0.9, 0.3, 0.3)  # Red for -1 class
const COLOR_SPECIAL := Color(1.0, 0.85, 0.2)    # Golds for support vectors
const COLOR_BOUNDARY := Color(0.9, 0.2, 0.9)    # Magenta for boundary

@export_category("SVM Configuration")
@export var kernel_type: String = "rbf"  # linear, polynomial, rbf, sigmoid
@export var C_parameter: float = 1.0  # Regularization parameter
@export var gamma: float = 1.0  # Kernel coefficient
@export var degree: int = 3  # Polynomial degree
@export var tolerance: float = 0.001  # Numerical tolerance

@export_category("Data Configuration")
@export var num_positive_samples: int = 50
@export var num_negative_samples: int = 50
@export var data_dimension: int = 2  # For visualization
@export var class_separation: float = 2.0
@export var data_noise: float = 0.5

@export_category("Visualization")
@export var show_support_vectors: bool = true
@export var show_decision_boundary: bool = true
@export var show_margin_lines: bool = true
@export var support_vector_size: float = 0.3
@export var positive_color: Color = COLOR_POSITIVE_SVM
@export var negative_color: Color = COLOR_NEGATIVE_SVM
@export var support_vector_color: Color = COLOR_SPECIAL
@export var boundary_color: Color = COLOR_BOUNDARY

@export_category("Algorithm Animation")
@export var auto_start: bool = true
@export var step_delay: float = 0.1
@export var show_optimization_steps: bool = true

# =============================================================================
# STAGE-2 DNA — #cohort:blobs|block|rings|braid|skew
# =============================================================================
# cohort — the shape of the population the method is asked to divide.
#
# The data was authored to flatter the method: two blobs pushed apart by
# `class_separation`, so the margin the SMO loop maximises always exists and the
# artifact whose subject is WHERE TO DRAW THE LINE could only ever be placed over
# data where the line is obvious. This is the knob that stops it flattering.
#
#   blobs  two rectangular clouds, 4.0 x 5.0 m each, centres 2.0 m apart in x.
#          The shipped case, unchanged. `class_separation` and `data_noise` still
#          govern it; the other four values replace them with an explicit layout.
#   block  one filled 6.0 x 5.0 m field — an even 12 x 10 lattice at 0.5 m pitch,
#          120 cells, every one occupied — the two classes meeting along a
#          diagonal through the middle. Same extent, no gap: the thing being
#          maximised has nowhere to sit.
#   rings  a small disc of one class ringed by an annulus of the other.
#          Separable by the rbf kernel this artifact defaults to and by no
#          straight line at all — the honest advertisement for the kernel trick.
#   braid  two sinusoidal bands 0.5 m apart, amplitude 1.5 m, period 3.0 m, so
#          the classes interleave four times across the field and no single
#          margin can hold.
#   skew   95 points of the negative class across the whole field and 5 positive
#          in one corner: the boundary that scores 95 percent is the boundary
#          that ignores them.
#
# Refused as axes: step_delay, auto_start, show_optimization_steps, tolerance.
# They set how far along an optimisation is when photographed, which is not a
# photographable property.
@export_category("Stage-2 DNA")
## The shape of the population the method is asked to divide.
@export_enum("blobs", "block", "rings", "braid", "skew") var cohort: String = "blobs"

const COHORTS: PackedStringArray = ["blobs", "block", "rings", "braid", "skew"]

## Fixed data seed. Every point position in this artifact is drawn from `_rng`,
## which is re-seeded from this constant at the top of every generate pass — two
## builds of one cohort value must be pixel-identical or the pixel critic reads
## sampling noise as axis signal.
const DATA_SEED: int = 20260730

# --- Field envelope ----------------------------------------------------------
# The caption plan depends on the scatter never leaving |y| <= 2.5 (see
# _ensure_labels). Every cohort below is built inside this rectangle, and the
# shipped blobs case already sits exactly on it (2.0 + data_noise 0.5).
const FIELD_W: float = 6.0
const FIELD_H: float = 5.0

# block: the field is FILLED by a lattice, not sampled by a scatter. BLOCK_FILL
# is the floor on how many cells that lattice holds (the sample-count exports can
# only push it up, never below a filled read); BLOCK_JITTER is the wobble applied
# to each occupied cell so the fill reads as a population and not as graph paper.
# A floor of 110 over 6.0 x 5.0 m resolves to a 12 x 10 lattice, 120 cells at
# exactly 0.500 x 0.500 m pitch, dots 0.2 m across — dense enough to read as one
# slab, open enough to count. The jitter is capped at 16% of the pitch so a map
# author who raises the sample counts densifies the field instead of smearing it.
const BLOCK_FILL: int = 110
const BLOCK_JITTER: float = 0.08

# rings: polar radii before the field fit. Generated at mean radius 3.0 with a
# 0.6 m wall, then scaled so the outer edge lands on the field rectangle — which
# makes it an ellipse rather than a circle. That is deliberate: a true 3.3 m
# circle would push the top of the scatter to y = 3.3 and eat the clearance the
# caption plan is built on.
const RING_R: float = 3.0
const RING_WALL: float = 0.6
const RING_DISC_R: float = 1.2

# braid: two offset sine bands.
const BRAID_AMP: float = 1.5
const BRAID_PERIOD: float = 3.0
const BRAID_SEP: float = 0.5
const BRAID_JITTER: float = 0.10

# skew: the minority pocket, a 0.9 m box tucked into the +x/+y corner.
const SKEW_POCKET: float = 0.9

# SVM Algorithm State
var training_data: Array = []
var training_labels: Array = []
var support_vectors: Array = []
var support_vector_labels: Array = []
var alphas: Array = []
var bias: float = 0.0
var is_trained: bool = false

# Optimization state
var is_training: bool = false
var current_iteration: int = 0
var max_iterations: int = 1000
var optimization_timer: Timer

# Visual elements
var data_points: Array = []
var boundary_mesh: MeshInstance3D
var margin_meshes: Array = []
var ui_display: CanvasLayer

# 3D in-scene labels
var _title_label_3d: Label3D
var _stats_label_3d: Label3D

# Build state
var _built: bool = false
var _emissive: bool = true
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Algorithm signals
signal training_step_complete()
signal training_finished()
signal classification_changed()

func _init() -> void:
	name = "SVM_Visualization"

func _ready() -> void:
	_build_all()
	_built = true

	if auto_start:
		call_deferred("start_training")

## Everything the still needs, synchronously, from @export values alone. The
## sweep sets `cohort` and adds the node to the tree; it never touches meta and
## never calls apply_grid_config, so the whole scatter has to land here.
func _build_all() -> void:
	setup_ui()
	setup_timer()
	_build_3d_labels()
	generate_training_data()

# --- Caption placement -------------------------------------------------------
# Two plates, both above the body, nothing in the viewing corridor.
#
# LabelFramer turns each of these into an opaque anthracite panel at spawn, so
# placement is the only thing that keeps them off the scatter:
#
#   title  y = 5.00, font 64 -> 0.32 m of text, 22 characters at ~3.5 m wide
#          => plate ~3.60 x 0.39 m, bezel ~3.66 x 0.45 m, spanning y 4.78..5.23
#   stats  y = 4.20, font 36 -> 0.18 m of text, empty at spawn, ~2.7 m once
#          update_ui writes into it => plate ~2.80 x 0.25 m, y 4.07..4.33
#
# The 0.80 m separation is far over the framer's 0.16 m merge gap, so they stay
# TWO plates — which is right: one is a permanent name, the other is live
# telemetry that the training loop rewrites. The scatter is a flat sheet in the
# z = 0 plane topping out at y = 2.5 under every cohort value, so the lower plate
# clears it by 1.57 m and frontal crossing is 0 everywhere.
#
# The empty stats label stays: it is the node the script live-updates and
# deleting it would break finalize_training. No per-point or per-support-vector
# captions — at 0.1 m radius, 100 points would become 100 opaque plates and the
# scatter would vanish under its own labelling.
const TITLE_Y: float = 5.0
const STATS_Y: float = 4.2

func _build_3d_labels() -> void:
	"""Create in-scene 3D labels for VR / immersive viewing (once)."""
	if _title_label_3d == null or not is_instance_valid(_title_label_3d):
		_title_label_3d = Label3D.new()
		_title_label_3d.text = "Support Vector Machine"
		_title_label_3d.font_size = 64
		_title_label_3d.modulate = COLOR_SPECIAL
		_title_label_3d.position = Vector3(0, TITLE_Y, 0)
		# Billboard stays ENABLED on both: these hang in the air above the sheet,
		# they are not ink on a surface of the artifact.
		_title_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_title_label_3d)

	if _stats_label_3d == null or not is_instance_valid(_stats_label_3d):
		_stats_label_3d = Label3D.new()
		_stats_label_3d.font_size = 36
		_stats_label_3d.modulate = Color.WHITE
		_stats_label_3d.position = Vector3(0, STATS_Y, 0)
		_stats_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_stats_label_3d)

func setup_ui() -> void:
	"""Create comprehensive UI for SVM visualization (once)."""
	if ui_display != null and is_instance_valid(ui_display):
		update_ui()
		return
	ui_display = CanvasLayer.new()
	add_child(ui_display)

	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(400, 600)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for SVM information
	for i in range(20):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer() -> void:
	"""Setup timer for animation (once)"""
	if optimization_timer != null and is_instance_valid(optimization_timer):
		optimization_timer.wait_time = step_delay
		return
	optimization_timer = Timer.new()
	optimization_timer.wait_time = step_delay
	optimization_timer.timeout.connect(_on_optimization_timer_timeout)
	add_child(optimization_timer)

func generate_training_data() -> void:
	"""Lay out the population named by `cohort`, then draw it."""
	training_data.clear()
	training_labels.clear()

	# Re-seeded here, not in _init: a rebuild must redraw the SAME points.
	_rng.seed = DATA_SEED

	var total: int = maxi(4, num_positive_samples + num_negative_samples)

	match cohort:
		"block":
			_layout_block(total)
		"rings":
			_layout_rings(total)
		"braid":
			_layout_braid(total)
		"skew":
			_layout_skew(total)
		_:
			_layout_blobs()

	create_data_visualization()
	print("Generated ", training_data.size(), " training samples (cohort=", cohort, ")")

## blobs — the shipped layout, expression for expression. Two 4.0 x 5.0 m clouds
## pushed `class_separation` apart in x, y smeared by `data_noise`. The only
## change is the source of the numbers: a seeded generator instead of the global
## one, so two builds are identical.
func _layout_blobs() -> void:
	for i in range(num_positive_samples):
		var point: Vector2 = Vector2(
			_rng.randf_range(-2, 2) + class_separation / 2.0,
			_rng.randf_range(-2, 2) + data_noise * _rng.randf_range(-1, 1)
		)
		training_data.append(point)
		training_labels.append(1)

	for i in range(num_negative_samples):
		var point: Vector2 = Vector2(
			_rng.randf_range(-2, 2) - class_separation / 2.0,
			_rng.randf_range(-2, 2) + data_noise * _rng.randf_range(-1, 1)
		)
		training_data.append(point)
		training_labels.append(-1)

## block — one filled field, split corner to corner. Same footprint as blobs,
## no gap anywhere along the seam: whatever the SMO loop converges on, there is
## no margin for it to sit in.
##
## The fill is a LATTICE, and that is the repair for a false declaration. This
## function used to draw `total` uniform points as
## `randf_range(-hx, hx), randf_range(-hy, hy)` — which is the draw order and the
## ranges `_layout_skew` uses for its 95-point majority, out of the same `_rng` at
## the same fixed seed. The two values therefore came out of the generator as the
## SAME 95 positions and rendered as one picture; `block` and `skew` were one
## value wearing two names.
##
## A lattice is also the truer reading of the word already written above: a
## filled field. A hundred uniform draws leave clumps and holes and a ragged
## seam; an evenly occupied field has no hole for a margin to hide in anywhere,
## and the diagonal the two classes meet along reads as an actual edge. Cell
## centres decide the label, so the seam stays straight; the jitter only touches
## where the dot sits inside its cell.
func _layout_block(total: int) -> void:
	var hx: float = FIELD_W * 0.5
	var hy: float = FIELD_H * 0.5

	# Cells sized to keep the pitch near-square across a 6.0 x 5.0 m field.
	var target: int = maxi(total, BLOCK_FILL)
	var cols: int = maxi(2, int(ceil(sqrt(float(target) * FIELD_W / FIELD_H))))
	var rows: int = maxi(2, int(ceil(float(target) / float(cols))))
	var step_x: float = FIELD_W / float(cols)
	var step_y: float = FIELD_H / float(rows)
	var jitter: float = minf(BLOCK_JITTER, minf(step_x, step_y) * 0.16)

	for j in range(rows):
		for i in range(cols):
			var cx: float = -hx + (float(i) + 0.5) * step_x
			var cy: float = -hy + (float(j) + 0.5) * step_y
			# Diagonal through the middle, in normalised field coordinates so it
			# runs corner to corner rather than at 45 degrees in a non-square
			# field. Taken from the cell centre, not the jittered dot, so the
			# seam is a clean staircase instead of a fringe.
			var side: float = (cy / hy) - (cx / hx)
			training_data.append(Vector2(
				cx + _rng.randf_range(-jitter, jitter),
				cy + _rng.randf_range(-jitter, jitter)
			))
			training_labels.append(1 if side >= 0.0 else -1)

## rings — 40% of the population in a central disc, 60% on a wall around it.
## Generated in polar form at mean radius 3.0 with a 0.6 m wall, then scaled onto
## the field rectangle (so it is an ellipse: see RING_R). No straight line
## separates these; the rbf kernel this artifact already defaults to does.
func _layout_rings(total: int) -> void:
	var inner_count: int = int(roundf(float(total) * 0.4))
	var outer_count: int = total - inner_count
	var outer_edge: float = RING_R + RING_WALL * 0.5
	var sx: float = (FIELD_W * 0.5) / outer_edge
	var sy: float = (FIELD_H * 0.5) / outer_edge

	for i in range(inner_count):
		var a: float = _rng.randf_range(0.0, TAU)
		# sqrt of a uniform draw keeps the disc evenly covered instead of piling
		# points at the centre.
		var r: float = RING_DISC_R * sqrt(_rng.randf())
		training_data.append(Vector2(cos(a) * r * sx, sin(a) * r * sy))
		training_labels.append(1)

	for i in range(outer_count):
		var a: float = _rng.randf_range(0.0, TAU)
		var r: float = _rng.randf_range(RING_R - RING_WALL * 0.5, outer_edge)
		training_data.append(Vector2(cos(a) * r * sx, sin(a) * r * sy))
		training_labels.append(-1)

## braid — two sine bands 0.5 m apart, amplitude 1.5 m, period 3.0 m across a
## 6.0 m field, so each class occupies four alternating stretches of any straight
## cut through the field. x is stratified (evenly spaced, not sampled) so the
## bands read as bands; only the cross-band scatter is random.
func _layout_braid(total: int) -> void:
	var upper: int = int(float(total) * 0.5)
	var lower: int = total - upper
	var hx: float = FIELD_W * 0.5

	for i in range(upper):
		var x: float = -hx + (float(i) + 0.5) / float(upper) * FIELD_W
		var base: float = BRAID_AMP * sin(TAU * x / BRAID_PERIOD)
		var y: float = base + BRAID_SEP * 0.5 + _rng.randf_range(-BRAID_JITTER, BRAID_JITTER)
		training_data.append(Vector2(x, y))
		training_labels.append(1)

	for i in range(lower):
		var x: float = -hx + (float(i) + 0.5) / float(lower) * FIELD_W
		var base: float = BRAID_AMP * sin(TAU * x / BRAID_PERIOD)
		var y: float = base - BRAID_SEP * 0.5 + _rng.randf_range(-BRAID_JITTER, BRAID_JITTER)
		training_data.append(Vector2(x, y))
		training_labels.append(-1)

## skew — 95 negative across the whole field, 5 positive in one corner. The
## majority class is spread, not clustered, so there is no shape to find: the
## boundary that scores 95 percent is the boundary that never looks at the
## pocket, and the still shows how small the pocket is.
func _layout_skew(total: int) -> void:
	var minority: int = maxi(1, int(roundf(float(total) * 0.05)))
	var majority: int = total - minority
	var hx: float = FIELD_W * 0.5
	var hy: float = FIELD_H * 0.5

	for i in range(majority):
		training_data.append(Vector2(
			_rng.randf_range(-hx, hx),
			_rng.randf_range(-hy, hy)
		))
		training_labels.append(-1)

	var cx: float = hx - SKEW_POCKET * 0.5 - 0.1
	var cy: float = hy - SKEW_POCKET * 0.5 - 0.1
	for i in range(minority):
		training_data.append(Vector2(
			cx + _rng.randf_range(-SKEW_POCKET * 0.5, SKEW_POCKET * 0.5),
			cy + _rng.randf_range(-SKEW_POCKET * 0.5, SKEW_POCKET * 0.5)
		))
		training_labels.append(1)

func create_data_visualization() -> void:
	"""Create 3D visualization of training data"""
	clear_previous_visualization()
	
	for i in range(training_data.size()):
		var point = training_data[i]
		var label = training_labels[i]
		
		var sphere = create_data_point(point, label)
		data_points.append(sphere)
		add_child(sphere)

func create_data_point(point: Vector2, label: int) -> MeshInstance3D:
	"""Create a 3D sphere for a data point, colored by class label."""
	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	sphere.mesh = mesh
	
	var base_color: Color = positive_color if label == 1 else negative_color
	var material = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.emission_enabled = _emissive
	material.emission = base_color * 0.35
	material.metallic = 0.3
	material.roughness = 0.45
	sphere.material_override = material
	
	sphere.position = Vector3(point.x, point.y, 0)
	return sphere

func start_training() -> void:
	"""Start SVM training process"""
	if is_training:
		return
	
	is_training = true
	current_iteration = 0
	initialize_svm_parameters()
	
	if show_optimization_steps:
		optimization_timer.start()
	else:
		# Run full training immediately
		train_svm_full()
		create_decision_boundary()
	
	print("Starting SVM training with kernel: ", kernel_type)

func initialize_svm_parameters() -> void:
	"""Initialize SVM parameters"""
	alphas.clear()
	for i in range(training_data.size()):
		alphas.append(0.0)
	
	bias = 0.0
	support_vectors.clear()
	support_vector_labels.clear()

func _on_optimization_timer_timeout() -> void:
	"""Perform one step of SVM optimization"""
	if not is_training:
		return
	
	var converged = perform_smo_step()
	current_iteration += 1
	
	if converged or current_iteration >= max_iterations:
		is_training = false
		optimization_timer.stop()
		finalize_training()
		training_finished.emit()
	else:
		training_step_complete.emit()
		# Update 3D progress
		if _stats_label_3d:
			_stats_label_3d.text = "Training: iter %d/%d  |  Kernel: %s" % [
				current_iteration, max_iterations, kernel_type
			]
	
	update_ui()

func perform_smo_step() -> bool:
	"""Perform one step of Sequential Minimal Optimization"""
	# Simplified SMO algorithm for educational purposes
	var num_changed = 0
	
	for i in range(training_data.size()):
		var Ei = calculate_error(i)
		
		if (training_labels[i] * Ei < -tolerance and alphas[i] < C_parameter) or \
		   (training_labels[i] * Ei > tolerance and alphas[i] > 0):
			
			# Select second alpha using heuristic
			var j = select_second_alpha(i, Ei)
			if j == -1:
				continue
			
			var Ej = calculate_error(j)
			
			# Update alphas
			if update_alphas(i, j, Ei, Ej):
				num_changed += 1
	
	return num_changed == 0

func calculate_error(i: int) -> float:
	"""Calculate prediction error for sample i"""
	var prediction = predict_sample(training_data[i])
	return prediction - training_labels[i]

func predict_sample(point: Vector2) -> float:
	"""Predict class for a single sample"""
	var result = bias
	
	for i in range(training_data.size()):
		if alphas[i] > 0:
			result += alphas[i] * training_labels[i] * kernel_function(training_data[i], point)
	
	return result

func kernel_function(x1: Vector2, x2: Vector2) -> float:
	"""Compute kernel function value"""
	match kernel_type:
		"linear":
			return x1.dot(x2)
		"polynomial":
			return pow(gamma * x1.dot(x2) + 1, degree)
		"rbf":
			var distance_sq = (x1 - x2).length_squared()
			return exp(-gamma * distance_sq)
		"sigmoid":
			return tanh(gamma * x1.dot(x2) + 1)
		_:
			return x1.dot(x2)  # Default to linear

func select_second_alpha(i: int, Ei: float) -> int:
	"""Select second alpha for SMO optimization"""
	var max_step = 0.0
	var best_j = -1
	
	for j in range(training_data.size()):
		if j == i:
			continue
		
		var Ej = calculate_error(j)
		var step = abs(Ei - Ej)
		
		if step > max_step:
			max_step = step
			best_j = j
	
	return best_j

func update_alphas(i: int, j: int, Ei: float, Ej: float) -> bool:
	"""Update alpha values using SMO algorithm"""
	var old_alpha_i = alphas[i]
	var old_alpha_j = alphas[j]
	
	# Calculate bounds
	var L: float
	var H: float
	
	if training_labels[i] != training_labels[j]:
		L = max(0, alphas[j] - alphas[i])
		H = min(C_parameter, C_parameter + alphas[j] - alphas[i])
	else:
		L = max(0, alphas[i] + alphas[j] - C_parameter)
		H = min(C_parameter, alphas[i] + alphas[j])
	
	if L == H:
		return false
	
	# Calculate eta
	var eta = 2 * kernel_function(training_data[i], training_data[j]) - \
			  kernel_function(training_data[i], training_data[i]) - \
			  kernel_function(training_data[j], training_data[j])
	
	if eta >= 0:
		return false
	
	# Update alphas
	alphas[j] = old_alpha_j - training_labels[j] * (Ei - Ej) / eta
	alphas[j] = clamp(alphas[j], L, H)
	
	if abs(alphas[j] - old_alpha_j) < 1e-5:
		return false
	
	alphas[i] = old_alpha_i + training_labels[i] * training_labels[j] * (old_alpha_j - alphas[j])
	
	# Update bias
	update_bias(i, j, old_alpha_i, old_alpha_j, Ei, Ej)
	
	return true

func update_bias(i: int, j: int, old_alpha_i: float, old_alpha_j: float, Ei: float, Ej: float) -> void:
	"""Update bias term"""
	var b1 = bias - Ei - training_labels[i] * (alphas[i] - old_alpha_i) * kernel_function(training_data[i], training_data[i]) - \
			 training_labels[j] * (alphas[j] - old_alpha_j) * kernel_function(training_data[i], training_data[j])
	
	var b2 = bias - Ej - training_labels[i] * (alphas[i] - old_alpha_i) * kernel_function(training_data[i], training_data[j]) - \
			 training_labels[j] * (alphas[j] - old_alpha_j) * kernel_function(training_data[j], training_data[j])
	
	if 0 < alphas[i] and alphas[i] < C_parameter:
		bias = b1
	elif 0 < alphas[j] and alphas[j] < C_parameter:
		bias = b2
	else:
		bias = (b1 + b2) / 2

func train_svm_full() -> void:
	"""Train SVM without animation"""
	initialize_svm_parameters()
	
	for iteration in range(max_iterations):
		if perform_smo_step():
			break
	
	finalize_training()

func finalize_training() -> void:
	"""Finalize SVM training"""
	extract_support_vectors()
	create_decision_boundary()
	update_support_vector_visualization()
	is_trained = true
	
	# Update 3D stats
	if _stats_label_3d:
		_stats_label_3d.text = "Trained!  SVs: %d  |  Kernel: %s  |  Bias: %.2f" % [
			support_vectors.size(), kernel_type, bias
		]
		var tw := create_tween()
		tw.tween_property(_stats_label_3d, "modulate", COLOR_SPECIAL, 0.2)
		tw.tween_property(_stats_label_3d, "modulate", Color.WHITE, 0.8)
	
	print("SVM training completed")
	print("Support vectors found: ", support_vectors.size())

func extract_support_vectors() -> void:
	"""Extract support vectors from training data"""
	support_vectors.clear()
	support_vector_labels.clear()
	
	for i in range(training_data.size()):
		if alphas[i] > tolerance:
			support_vectors.append(training_data[i])
			support_vector_labels.append(training_labels[i])

func create_decision_boundary() -> void:
	"""Create visualization of decision boundary"""
	if is_instance_valid(boundary_mesh):
		if boundary_mesh.get_parent() == self:
			remove_child(boundary_mesh)
		boundary_mesh.queue_free()
	boundary_mesh = null

	boundary_mesh = MeshInstance3D.new()
	var mesh = create_boundary_mesh()
	boundary_mesh.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = boundary_color
	material.emission_enabled = _emissive
	material.emission = boundary_color * 0.3
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	boundary_mesh.material_override = material
	
	add_child(boundary_mesh)

func create_boundary_mesh() -> ArrayMesh:
	"""Create mesh for decision boundary"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var resolution = 50
	var size = 8.0
	
	# Create grid of points and evaluate decision function
	for i in range(resolution):
		for j in range(resolution):
			var x = (i / float(resolution - 1)) * size - size/2
			var y = (j / float(resolution - 1)) * size - size/2
			var point = Vector2(x, y)
			
			var decision_value = predict_sample(point)
			
			# Create vertices near the decision boundary
			if abs(decision_value) < 0.1:  # Near boundary
				vertices.append(Vector3(x, y, 0))
				normals.append(Vector3(0, 0, 1))
				uvs.append(Vector2(i / float(resolution), j / float(resolution)))
	
	# Create simple point cloud for boundary
	for i in range(vertices.size()):
		indices.append(i)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	
	return array_mesh

func update_support_vector_visualization() -> void:
	"""Highlight support vectors with animated scale-up and golden glow."""
	if not show_support_vectors:
		return
	
	for i in range(training_data.size()):
		if alphas[i] > tolerance and i < data_points.size():
			var material = data_points[i].material_override as StandardMaterial3D
			material.albedo_color = support_vector_color
			material.emission = support_vector_color * 0.6
			material.metallic = 0.5
			material.roughness = 0.25
			
			# Animate support vectors scaling up with a bounce
			var target_scale = Vector3.ONE * (1.0 + support_vector_size)
			var tw := create_tween()
			tw.tween_property(data_points[i], "scale", target_scale * 1.3, 0.15).set_ease(Tween.EASE_OUT)
			tw.tween_property(data_points[i], "scale", target_scale, 0.25).set_ease(Tween.EASE_IN_OUT)

func classify_new_point(point: Vector2) -> Dictionary:
	"""Classify a new point and return detailed results"""
	if not is_trained:
		return {"error": "SVM not trained"}
	
	var prediction = predict_sample(point)
	var class_label = 1 if prediction > 0 else -1
	var confidence = abs(prediction)
	
	return {
		"prediction": prediction,
		"class": class_label,
		"confidence": confidence,
		"distance_to_boundary": abs(prediction)
	}

func clear_previous_visualization() -> void:
	"""Clear previous visualization elements.

	remove_child BEFORE queue_free: the rebuild is synchronous, and a freed-but-
	still-parented node would still be measured by the grid's auto-grounding pass
	on the way past. Only nodes THIS script created are touched — grid-added
	plates and utilities live in the same parent."""
	for point in data_points:
		if is_instance_valid(point):
			if point.get_parent() == self:
				remove_child(point)
			point.queue_free()
	data_points.clear()

	if is_instance_valid(boundary_mesh):
		if boundary_mesh.get_parent() == self:
			remove_child(boundary_mesh)
		boundary_mesh.queue_free()
	boundary_mesh = null

	for margin_mesh in margin_meshes:
		if is_instance_valid(margin_mesh):
			if margin_mesh.get_parent() == self:
				remove_child(margin_mesh)
			margin_mesh.queue_free()
	margin_meshes.clear()

func update_ui() -> void:
	"""Update UI with current SVM state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(20):
		var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 20:
		labels[0].text = "🧠 Support Vector Machine - Boundary Politics"
		labels[1].text = "Kernel: " + kernel_type.capitalize()
		labels[2].text = "C Parameter: " + str(C_parameter)
		labels[3].text = "Gamma: " + str(gamma)
		labels[4].text = ""
		labels[5].text = "Training Status: " + ("Training..." if is_training else "Trained" if is_trained else "Not Started")
		labels[6].text = "Iteration: " + str(current_iteration) + "/" + str(max_iterations)
		labels[7].text = "Training Samples: " + str(training_data.size())
		labels[8].text = "Support Vectors: " + str(support_vectors.size())
		labels[9].text = "Bias: " + str(bias).pad_decimals(3)
		labels[10].text = ""
		labels[11].text = "Controls:"
		labels[12].text = "SPACE - Start/Stop Training"
		labels[13].text = "R - Reset Data"
		labels[14].text = "1-4 - Change Kernel"
		labels[15].text = "↑/↓ - Adjust C Parameter"
		labels[16].text = ""
		labels[17].text = "🏳️‍🌈 Algorithmic Justice Framework:"
		labels[18].text = "Examines how classification boundaries"
		labels[19].text = "separate identities in high-dimensional space"

func _input(event: InputEvent) -> void:
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if is_training:
					stop_training()
				else:
					start_training()
			KEY_R:
				reset_svm()
			KEY_1:
				change_kernel("linear")
			KEY_2:
				change_kernel("polynomial")
			KEY_3:
				change_kernel("rbf")
			KEY_4:
				change_kernel("sigmoid")
			KEY_UP:
				C_parameter = min(C_parameter * 1.5, 10.0)
				reset_svm()
			KEY_DOWN:
				C_parameter = max(C_parameter / 1.5, 0.1)
				reset_svm()

func stop_training() -> void:
	"""Stop SVM training"""
	is_training = false
	optimization_timer.stop()

func reset_svm() -> void:
	"""Reset SVM and regenerate data"""
	stop_training()
	is_trained = false
	generate_training_data()

func change_kernel(new_kernel: String) -> void:
	"""Change kernel type and retrain"""
	kernel_type = new_kernel
	reset_svm()
	print("Changed kernel to: ", kernel_type)

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive algorithm information"""
	return {
		"name": "Support Vector Machine",
		"description": "Classification with maximum margin hyperplane",
		"kernel": kernel_type,
		"parameters": {
			"C": C_parameter,
			"gamma": gamma,
			"degree": degree,
			"tolerance": tolerance
		},
		"training_status": {
			"is_training": is_training,
			"is_trained": is_trained,
			"iteration": current_iteration,
			"max_iterations": max_iterations
		},
		"model_info": {
			"support_vectors": support_vectors.size(),
			"bias": bias,
			"training_samples": training_data.size()
		}
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# =============================================================================
# GRID CONFIG INTEGRATION
# =============================================================================
# Called by GridInteractablesComponent via call_deferred, AFTER _ready(). The
# scatter already exists by then — this only has to notice a real change and
# redraw. curation_station hands every artifact it curates {"emissive": false};
# that dict carries no axis key, so it must change nothing about the layout, and
# the key it DOES carry is applied in place before the early returns rather than
# quietly relying on a rebuild that no longer happens.

func apply_grid_config(config_data: Dictionary) -> void:
	var before_cohort: String = cohort

	if config_data.has("cohort"):
		cohort = _pick_axis(str(config_data["cohort"]), COHORTS, cohort)

	# Non-geometry key, applied IN PLACE, before any return.
	if config_data.has("emissive"):
		_emissive = _as_bool(config_data["emissive"], _emissive)
		_apply_emissive()

	if not _built:
		return
	if cohort == before_cohort:
		return

	_rebuild_now()
	print("[SVM_Visualization] Config applied - cohort=%s" % [cohort])

## Accept an axis value only if it names something this artifact actually builds.
## A typo in a map token falls back to the shipped look rather than stranding a
## placement with no scatter at all.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback

func _as_bool(raw, fallback: bool) -> bool:
	if raw is bool:
		return bool(raw)
	if raw is int or raw is float:
		return float(raw) != 0.0
	if raw is String:
		var v: String = str(raw).to_lower().strip_edges()
		if v in ["true", "1", "yes", "on"]:
			return true
		if v in ["false", "0", "no", "off"]:
			return false
	return fallback

## Toggle glow on everything this script has already drawn. Materials are
## per-node, so this walks them rather than rebuilding.
func _apply_emissive() -> void:
	for point in data_points:
		if is_instance_valid(point):
			var m: StandardMaterial3D = point.material_override as StandardMaterial3D
			if m:
				m.emission_enabled = _emissive
	if is_instance_valid(boundary_mesh):
		var bm: StandardMaterial3D = boundary_mesh.material_override as StandardMaterial3D
		if bm:
			bm.emission_enabled = _emissive

## Synchronous, inline, no call_deferred anywhere in the build path. The UI,
## timer and both caption labels are NOT freed — the labels have already been
## framed by LabelFramer at spawn, and a fresh pair would come back unframed.
func _rebuild_now() -> void:
	if optimization_timer != null and is_instance_valid(optimization_timer):
		optimization_timer.stop()
	is_training = false
	is_trained = false
	current_iteration = 0
	bias = 0.0
	alphas.clear()
	support_vectors.clear()
	support_vector_labels.clear()
	if _stats_label_3d != null and is_instance_valid(_stats_label_3d):
		_stats_label_3d.text = ""
		_stats_label_3d.modulate = Color.WHITE

	clear_previous_visualization()
	_build_all()

	# Same entry point _ready uses, not train_svm_full(): a config change must not
	# secretly photograph a converged model where the default photographs a
	# half-solved one.
	if auto_start:
		start_training()

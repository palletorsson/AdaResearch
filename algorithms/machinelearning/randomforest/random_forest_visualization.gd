extends Node3D

# @identity
# essence: prediction = majority_vote(tree₁(x), tree₂(x), ..., tree_n(x)); each tree trained on bootstrap sample with random feature subsets
# desire: watch a forest of decision trees grow, each different, each voting — democracy of weak learners producing strong predictions
# critical_parameter: num_trees — more trees reduce variance; the wisdom of crowds effect
# triggers: auto_start grows trees one by one; bootstrap sampling shows how each tree sees different data; feature importance emerges
# emerges: the ensemble is wiser than any individual tree — diversity plus aggregation equals accuracy
# needs: VR controls [missing] — exported params but no spatial sliders
# relationships: depends on enhanced_kmeans (trees split data like clustering); contrasts svm_visualization (one optimal boundary vs many approximate ones)
# truth: a forest of imperfect decision-makers can be more reliable than any single expert — this is the mathematics of collective intelligence

# =============================================================================
# Random Forest Visualization — Collective Intelligence & Democratic Decisions
# =============================================================================
# Visualizes ensemble learning: multiple decision trees are trained on
# bootstrap samples, each voting on the class label. The majority wins.
# Trees grow into the scene with animated node appearance.
# =============================================================================

# --- Color Palette -----------------------------------------------------------
const COLOR_DATA := Color(0.3, 0.5, 0.9)       # Blues for data
const COLOR_POSITIVE := Color(0.3, 0.85, 0.4)   # Greens for positive class
const COLOR_NEGATIVE := Color(0.9, 0.3, 0.3)    # Reds for negative class
const COLOR_SPECIAL := Color(1.0, 0.85, 0.2)    # Golds for highlights

# =============================================================================
# STAGE-2 DNA — one axis: `cohort`
# =============================================================================
# The shape of the population the method is asked to divide. The data was
# authored to flatter the method; this is the knob that stops it flattering.
#
#   block  100 spheres of radius 0.06 m filling an 8 x 8 x 8 m cube, labelled by
#          the sign of 0.5*f0 + 0.3*f1 - 0.2*f2 + 0.4*f3 with +/-0.2 noise, so the
#          two colours meet on a slanted plane through the middle of the cube.
#          THE SHIPPED CASE: an axis-aligned method fed a boundary that is not
#          axis-aligned but is at least flat.
#   blobs  two 3.0 m diameter clusters of 50 points each, centres 6.0 m apart on
#          the cube's diagonal with empty space between them — the case where five
#          depth-5 trees all agree and the entire point of an ensemble evaporates.
#   rings  40 points in a 1.5 m core and 60 on a 6.0 m diameter shell 0.8 m thick.
#          A boundary built only from axis-aligned cuts has to approximate a
#          sphere, and the staircase it produces is the argument this artifact
#          should be able to make and previously could not.
#   braid  the 8 m cube filled with eight alternating 1.0 m slabs of the two
#          classes along x, so every split available to a tree cuts through both
#          classes at once.
#   skew   95 points of one class through the 8 m cube and 5 of the other in a
#          single 1.5 m corner: a five-tree majority vote reaches 95 percent by
#          never once predicting the minority, and the still shows the corner it
#          wrote off.
#
# Reachable by setting the @export BEFORE _ready() — _ready() calls _build_all()
# synchronously and the whole 8 m cube of points is in frame at once. The trees
# are timer-driven and may be absent or mid-grow when the shutter opens, so the
# axis is legible in the SCATTER ALONE and never depends on the forest.
#
# REFUSED: training_speed, animate_tree_growth, show_bootstrap_process. They decide
# how many trees have finished growing when the shutter opens — a time-domain knob
# masquerading as a look.
const COHORTS: PackedStringArray = ["blobs", "block", "rings", "braid", "skew"]

## The shape of the population handed to the forest. `block` is the shipped look.
@export_enum("blobs", "block", "rings", "braid", "skew") var cohort: String = "block"

# --- Cohort geometry, all in metres of world space ---------------------------
const CUBE_HALF: float = 4.0            # the shipped scatter spans an 8 m cube
const BLOB_SEPARATION: float = 6.0      # between cluster centres, along (1,1,1)
const BLOB_DIAMETER: float = 3.0
const RING_CORE_DIAMETER: float = 1.5
const RING_SHELL_DIAMETER: float = 6.0
const RING_SHELL_THICKNESS: float = 0.8
const BRAID_SLABS: int = 8              # 8 slabs across 8 m = 1.0 m each
const SKEW_CORNER: float = 1.5          # edge of the corner the vote writes off
const SKEW_MAJORITY: int = 95
const SKEW_MINORITY: int = 5

# --- Determinism -------------------------------------------------------------
# Every draw in this file is seeded from a constant. Two builds of one cohort
# value must be pixel-identical or the pixel critic reads noise as signal.
const DATA_SEED: int = 20260730         # sample positions, labels, label noise
const FOREST_SEED: int = 991            # bootstrap resampling
const TREE_SEED_BASE: int = 7717        # per-tree random feature subsets
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _forest_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# --- Node caption sizing -----------------------------------------------------
# font 8 * pixel_size 0.005 = 0.04 m of text. The old font-16 string measured about
# 0.32 m wide; halving the font halves that to about 0.16 m, which fits inside the
# 0.2 m front face of a node cube. Longest string is 17 characters ("Feature_C <=-0.42").
const NODE_LABEL_FONT: int = 8
const NODE_LABEL_OUTLINE: int = 2

@export_category("Random Forest Configuration")
@export var num_trees: int = 5
@export var max_depth: int = 5
@export var min_samples_split: int = 2
@export var max_features: float = 0.8  # Fraction of features to consider
@export var bootstrap_sample_size: float = 0.8  # Fraction for bootstrap sampling

@export_category("Data Configuration")
@export var num_samples: int = 100
@export var num_features: int = 4  # For visualization purposes
@export var noise_level: float = 0.2
@export var class_balance: float = 0.5  # Ratio of positive to negative samples

@export_category("Visualization")
@export var show_individual_trees: bool = true
@export var show_ensemble_prediction: bool = true
@export var show_feature_importance: bool = true
@export var tree_spacing: float = 3.0
@export var node_size: float = 0.2
@export var tree_color_variation: bool = true

@export_category("Animation")
@export var auto_start: bool = true
@export var training_speed: float = 0.5
@export var show_bootstrap_process: bool = true
@export var animate_tree_growth: bool = true

# Data structures
var training_data: Array = []
var training_labels: Array = []
var feature_names: Array = ["Feature_A", "Feature_B", "Feature_C", "Feature_D"]
var decision_trees: Array = []
var bootstrap_samples: Array = []

# Training state
var is_training: bool = false
var current_tree_index: int = 0
var training_complete: bool = false
var training_timer: Timer

# Visualization elements
var tree_visualizations: Array = []
var data_points: Array = []
var forest_root: Node3D
var ui_display: CanvasLayer

# 3D in-scene labels
var _title_label_3d: Label3D
var _stats_label_3d: Label3D

# Lifecycle: built once from @export values, rebuilt only when an axis changes.
var _built: bool = false
# Nodes THIS SCRIPT parented to self. Freeing get_children() would destroy the
# grid's own added plates, so the rebuild only ever touches this list.
var _owned: Array[Node] = []
# Non-geometry key applied IN PLACE (curation_station hands every artifact
# {"emissive": false} one line after framing its labels).
var _emissive_on: bool = true

# Colors for visualization
var tree_colors: Array = [
	Color(0.8, 0.3, 0.3),  # Red
	Color(0.3, 0.8, 0.3),  # Green
	Color(0.3, 0.3, 0.8),  # Blue
	Color(0.8, 0.8, 0.3),  # Yellow
	Color(0.8, 0.3, 0.8),  # Magenta
	Color(0.3, 0.8, 0.8),  # Cyan
	Color(0.9, 0.5, 0.2),  # Orange
	Color(0.5, 0.2, 0.9),  # Purple
]

# Decision Tree Node class
class DecisionTreeNode:
	var is_leaf: bool = false
	var feature_index: int = -1
	var threshold: float = 0.0
	var left_child: DecisionTreeNode = null
	var right_child: DecisionTreeNode = null
	var prediction: int = 0
	var samples_count: int = 0
	var depth: int = 0
	var node_id: int = 0
	var gini_impurity: float = 0.0
	
	func _init(id: int = 0, d: int = 0) -> void:
		node_id = id
		depth = d

# Decision Tree class
class DecisionTree:
	var root: DecisionTreeNode = null
	var max_depth: int = 5
	var min_samples_split: int = 2
	var max_features: int = 4
	var tree_id: int = 0
	var next_node_id: int = 0
	# Own RNG, seeded by the caller. The random feature subset is drawn here, and
	# an unseeded shuffle would make two builds of one cohort value differ.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()

	func _init(id: int, max_d: int, min_samples: int, max_feat: int, seed_value: int = 0) -> void:
		tree_id = id
		max_depth = max_d
		min_samples_split = min_samples
		max_features = max_feat
		next_node_id = 0
		rng.seed = seed_value
	
	func train(data: Array, labels: Array, feature_indices: Array) -> void:
		root = build_tree(data, labels, feature_indices, 0)
	
	func build_tree(data: Array, labels: Array, feature_indices: Array, depth: int) -> DecisionTreeNode:
		var node = DecisionTreeNode.new(next_node_id, depth)
		next_node_id += 1
		node.samples_count = data.size()
		node.gini_impurity = calculate_gini(labels)
		
		# Check stopping criteria
		if depth >= max_depth or data.size() < min_samples_split or is_pure(labels):
			node.is_leaf = true
			node.prediction = get_majority_class(labels)
			return node
		
		# Find best split
		var best_split = find_best_split(data, labels, feature_indices)
		if best_split.gain <= 0:
			node.is_leaf = true
			node.prediction = get_majority_class(labels)
			return node
		
		node.feature_index = best_split.feature_index
		node.threshold = best_split.threshold
		
		# Split data
		var left_data = []
		var left_labels = []
		var right_data = []
		var right_labels = []
		
		for i in range(data.size()):
			if data[i][node.feature_index] <= node.threshold:
				left_data.append(data[i])
				left_labels.append(labels[i])
			else:
				right_data.append(data[i])
				right_labels.append(labels[i])
		
		# Build child nodes
		if left_data.size() > 0:
			node.left_child = build_tree(left_data, left_labels, feature_indices, depth + 1)
		if right_data.size() > 0:
			node.right_child = build_tree(right_data, right_labels, feature_indices, depth + 1)
		
		return node
	
	func find_best_split(data: Array, labels: Array, feature_indices: Array) -> Dictionary:
		var best_gain = -1.0
		var best_feature = -1
		var best_threshold = 0.0
		var parent_gini = calculate_gini(labels)
		
		# Randomly select subset of features
		var selected_features = []
		var num_features_to_select = min(max_features, feature_indices.size())
		var shuffled_features: Array = feature_indices.duplicate()
		# Fisher-Yates through this tree's own seeded RNG. Array.shuffle() draws
		# from the global generator and would void determinism.
		for k in range(shuffled_features.size() - 1, 0, -1):
			var j: int = rng.randi_range(0, k)
			var swap: Variant = shuffled_features[k]
			shuffled_features[k] = shuffled_features[j]
			shuffled_features[j] = swap

		for i in range(num_features_to_select):
			selected_features.append(shuffled_features[i])
		
		for feature_idx in selected_features:
			var feature_values = []
			for sample in data:
				feature_values.append(sample[feature_idx])
			
			# Try different thresholds
			var unique_values = []
			for value in feature_values:
				if value not in unique_values:
					unique_values.append(value)
			
			unique_values.sort()
			
			for i in range(unique_values.size() - 1):
				var threshold = (unique_values[i] + unique_values[i + 1]) / 2.0
				var gain = calculate_information_gain(data, labels, feature_idx, threshold, parent_gini)
				
				if gain > best_gain:
					best_gain = gain
					best_feature = feature_idx
					best_threshold = threshold
		
		return {
			"gain": best_gain,
			"feature_index": best_feature,
			"threshold": best_threshold
		}
	
	func calculate_information_gain(data: Array, labels: Array, feature_idx: int, threshold: float, parent_gini: float) -> float:
		var left_labels = []
		var right_labels = []
		
		for i in range(data.size()):
			if data[i][feature_idx] <= threshold:
				left_labels.append(labels[i])
			else:
				right_labels.append(labels[i])
		
		if left_labels.size() == 0 or right_labels.size() == 0:
			return 0.0
		
		var total_samples = float(labels.size())
		var left_weight = left_labels.size() / total_samples
		var right_weight = right_labels.size() / total_samples
		
		var weighted_gini = left_weight * calculate_gini(left_labels) + right_weight * calculate_gini(right_labels)
		return parent_gini - weighted_gini
	
	func calculate_gini(labels: Array) -> float:
		if labels.size() == 0:
			return 0.0
		
		var class_counts = {}
		for label in labels:
			class_counts[label] = class_counts.get(label, 0) + 1
		
		var gini = 1.0
		var total = float(labels.size())
		
		for count in class_counts.values():
			var probability = count / total
			gini -= probability * probability
		
		return gini
	
	func is_pure(labels: Array) -> bool:
		if labels.size() <= 1:
			return true
		
		var first_label = labels[0]
		for label in labels:
			if label != first_label:
				return false
		return true
	
	func get_majority_class(labels: Array) -> int:
		var class_counts = {}
		for label in labels:
			class_counts[label] = class_counts.get(label, 0) + 1
		
		var max_count = 0
		var majority_class = 0
		for class_label in class_counts:
			if class_counts[class_label] > max_count:
				max_count = class_counts[class_label]
				majority_class = class_label
		
		return majority_class
	
	func predict(sample: Array) -> int:
		return predict_recursive(root, sample)
	
	func predict_recursive(node: DecisionTreeNode, sample: Array) -> int:
		if node.is_leaf:
			return node.prediction
		
		if sample[node.feature_index] <= node.threshold:
			return predict_recursive(node.left_child, sample)
		else:
			return predict_recursive(node.right_child, sample)

# Main RandomForest class methods
func _init() -> void:
	name = "RandomForest_Visualization"

func _ready() -> void:
	_build_all()
	_built = true

	if auto_start:
		call_deferred("start_training")


## Everything the still depends on, built SYNCHRONOUSLY from @export values alone.
## No call_deferred in here: a deferred build that has already removed its children
## makes auto-grounding measure a zero AABB and bail.
func _build_all() -> void:
	setup_ui()
	setup_timer()
	setup_forest_visualization()
	_build_3d_labels()
	generate_training_data()


## Parent a node this script created and remember it, so the rebuild can free
## exactly its own work and nothing the grid added.
func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)

func setup_ui() -> void:
	"""Create comprehensive UI for Random Forest visualization"""
	ui_display = CanvasLayer.new()
	_own(ui_display)

	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(400, 700)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for Random Forest information
	for i in range(25):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer() -> void:
	"""Setup timer for training animation"""
	training_timer = Timer.new()
	training_timer.wait_time = training_speed
	training_timer.timeout.connect(_on_training_timer_timeout)
	_own(training_timer)

func setup_forest_visualization() -> void:
	"""Setup the 3D forest visualization container"""
	forest_root = Node3D.new()
	forest_root.name = "Forest_Root"
	_own(forest_root)

func _build_3d_labels() -> void:
	"""Create in-scene 3D labels visible in VR / immersive mode.

	THE TWO HANGING PLATES. LabelFramer turns each of these into an opaque
	anthracite panel with a bezel, so where they sit is load-bearing:
	  title  font 72 -> 0.36 m of text, 13 characters at ~2.3 m, plate ~2.4 x 0.43 m
	  stats  font 40 -> 0.20 m of text, empty at spawn
	The scatter cube tops out at y = +4.0 m and the trees hang DOWNWARD from
	y = 0 to about y = -2.5 m, so at y = 6.0 and y = 5.0 both plates clear the body
	entirely and crossing is 0 at every cohort value. The 1.0 m gap between them is
	well over the 0.16 m merge threshold, so they stay two plates, not one nameplate.
	Both stay billboarded — they hang in air with nothing behind them and the framer
	is right to plate them.
	"""
	_title_label_3d = Label3D.new()
	_title_label_3d.text = "Random Forest"
	_title_label_3d.font_size = 72
	_title_label_3d.modulate = COLOR_SPECIAL
	_title_label_3d.position = Vector3(0, 6, 0)
	_title_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(_title_label_3d)

	_stats_label_3d = Label3D.new()
	_stats_label_3d.font_size = 40
	_stats_label_3d.modulate = Color.WHITE
	_stats_label_3d.position = Vector3(0, 5, 0)
	_stats_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(_stats_label_3d)

func generate_training_data() -> void:
	"""Generate training data whose SHAPE is the cohort axis.

	Feature space is [-2, 2] and create_data_visualization multiplies by 2, so the
	scatter occupies an 8 m cube. Every cohort below is authored in metres of world
	space and divided back down, which is why the numbers in the comments are the
	numbers you can measure in the still."""
	training_data.clear()
	training_labels.clear()
	_rng.seed = DATA_SEED

	match cohort:
		"blobs":
			_gen_blobs()
		"rings":
			_gen_rings()
		"braid":
			_gen_braid()
		"skew":
			_gen_skew()
		_:
			_gen_block()

	create_data_visualization()
	print("Generated ", training_data.size(), " training samples with ", num_features,
		" features — cohort=", cohort)


## THE SHIPPED CASE. A uniform cube cut by one slanted plane: the sign of
## 0.5*f0 + 0.3*f1 - 0.2*f2 + 0.4*f3 plus +/-noise_level. Identical draw order to
## the pre-promotion code — four uniform features then one noise draw per sample —
## only now through a seeded generator so two builds match pixel for pixel.
func _gen_block() -> void:
	for i in range(num_samples):
		var sample: Array = []
		for j in range(num_features):
			sample.append(_rng.randf_range(-2.0, 2.0))

		var label: int = 0
		var decision_value: float = sample[0] * 0.5 + sample[1] * 0.3 - sample[2] * 0.2 + sample[3] * 0.4
		decision_value += _rng.randf_range(-noise_level, noise_level)

		if decision_value > 0:
			label = 1

		training_data.append(sample)
		training_labels.append(label)


## Two separated clouds. 50 points each, 3.0 m across, centres 6.0 m apart along
## the cube diagonal (1,1,1) — so a 3.0 m void sits between them and any single
## depth-5 tree separates them on its first cut. Five trees then agree completely
## and the ensemble has nothing left to do.
func _gen_blobs() -> void:
	var diagonal: Vector3 = Vector3(1.0, 1.0, 1.0).normalized()
	var radius: float = BLOB_DIAMETER * 0.5
	for c in range(2):
		var direction: float = 1.0 if c == 0 else -1.0
		var centre: Vector3 = diagonal * (BLOB_SEPARATION * 0.5 * direction)
		var label: int = 1 if c == 0 else 0
		for i in range(50):
			_add_world_point(centre + _rand_in_ball(radius), label)


## A core inside a shell — the value that earns the axis. 40 points fill a 1.5 m
## core (radius 0.75 m) and 60 sit on a 6.0 m diameter shell 0.8 m thick, i.e. a
## band between radius 2.6 and 3.4 m. The true boundary is a sphere; every cut a
## tree can make is a plane perpendicular to an axis, so the forest can only ever
## approximate it with a staircase. That staircase is the picture of what
## axis-aligned cutting means, and it was unbuildable before this axis existed.
func _gen_rings() -> void:
	for i in range(40):
		_add_world_point(_rand_in_ball(RING_CORE_DIAMETER * 0.5), 1)

	var mid_radius: float = RING_SHELL_DIAMETER * 0.5
	var half_thick: float = RING_SHELL_THICKNESS * 0.5
	for i in range(60):
		var radius: float = mid_radius + _rng.randf_range(-half_thick, half_thick)
		_add_world_point(_rand_direction() * radius, 0)


## Eight alternating 1.0 m slabs along x across the 8 m cube. Counts alternate
## 13/12 to reach exactly 100. Every axis-aligned split available to a tree cuts
## through both classes at once, so no single cut buys any purity in y or z and
## the x cuts have to be found one slab boundary at a time. Sphere centres are
## inset by their own 0.06 m radius so the slabs read as bands and not as a blur.
func _gen_braid() -> void:
	var slab_width: float = (CUBE_HALF * 2.0) / float(BRAID_SLABS)
	var counts: Array = [13, 12, 13, 12, 13, 12, 13, 12]
	for s in range(BRAID_SLABS):
		var x0: float = -CUBE_HALF + float(s) * slab_width
		var label: int = 1 if s % 2 == 0 else 0
		for i in range(int(counts[s])):
			var p: Vector3 = Vector3(
				_rng.randf_range(x0 + 0.06, x0 + slab_width - 0.06),
				_rng.randf_range(-CUBE_HALF, CUBE_HALF),
				_rng.randf_range(-CUBE_HALF, CUBE_HALF))
			_add_world_point(p, label)


## 95 of one class through the whole cube, 5 of the other in a single 1.5 m corner
## at (+x, +y, +z). A five-tree majority vote reaches 95 percent accuracy by never
## once predicting the minority. The majority is NOT cleared out of the corner —
## the five minority points sit buried in it, which is exactly why the vote can
## afford to write them off, and the still shows the corner it wrote off.
func _gen_skew() -> void:
	for i in range(SKEW_MAJORITY):
		_add_world_point(Vector3(
			_rng.randf_range(-CUBE_HALF, CUBE_HALF),
			_rng.randf_range(-CUBE_HALF, CUBE_HALF),
			_rng.randf_range(-CUBE_HALF, CUBE_HALF)), 0)

	var lo: float = CUBE_HALF - SKEW_CORNER
	for i in range(SKEW_MINORITY):
		_add_world_point(Vector3(
			_rng.randf_range(lo, CUBE_HALF),
			_rng.randf_range(lo, CUBE_HALF),
			_rng.randf_range(lo, CUBE_HALF)), 1)


## Store a sample from a WORLD position. create_data_visualization scales features
## by 2, so a feature is half its metre. The fourth feature carries no signal in
## these four cohorts — only the three visible axes do, which keeps the still an
## honest account of what the forest was given.
func _add_world_point(w: Vector3, label: int) -> void:
	var sample: Array = [w.x * 0.5, w.y * 0.5, w.z * 0.5]
	var width: int = maxi(num_features, 4)
	while sample.size() < width:
		sample.append(_rng.randf_range(-2.0, 2.0))
	training_data.append(sample)
	training_labels.append(label)


## Uniform direction on the unit sphere, from the seeded generator.
func _rand_direction() -> Vector3:
	var d: Vector3 = Vector3(
		_rng.randfn(0.0, 1.0), _rng.randfn(0.0, 1.0), _rng.randfn(0.0, 1.0))
	if d.length() < 0.0001:
		return Vector3.UP
	return d.normalized()


## Uniform point inside a ball of the given radius (cube-root keeps the density
## even instead of piling points at the centre).
func _rand_in_ball(radius: float) -> Vector3:
	var t: float = pow(_rng.randf(), 1.0 / 3.0)
	return _rand_direction() * radius * t

func create_data_visualization() -> void:
	"""Create 3D visualization of training data"""
	clear_data_points()
	
	for i in range(training_data.size()):
		var sample = training_data[i]
		var label = training_labels[i]
		
		# Use first 3 features for 3D positioning
		var position = Vector3(
			sample[0] * 2.0,
			sample[1] * 2.0,
			sample[2] * 2.0 if num_features > 2 else 0.0
		)
		
		var sphere = create_data_point(position, label)
		data_points.append(sphere)
		_own(sphere)

func create_data_point(position: Vector3, label: int) -> MeshInstance3D:
	"""Create a 3D sphere for a data point, colored by class label."""
	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	sphere.mesh = mesh
	
	var base_color := COLOR_POSITIVE if label == 1 else COLOR_NEGATIVE
	var material = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.emission_enabled = _emissive_on
	material.emission = base_color * 0.35
	material.metallic = 0.25
	material.roughness = 0.5
	sphere.material_override = material
	
	sphere.position = position
	return sphere

func start_training() -> void:
	"""Start Random Forest training process"""
	if is_training:
		return
	
	is_training = true
	training_complete = false
	current_tree_index = 0
	decision_trees.clear()
	bootstrap_samples.clear()
	# Reseed so every run of the same cohort draws the same bootstrap samples.
	_forest_rng.seed = FOREST_SEED

	clear_tree_visualizations()
	
	if animate_tree_growth:
		training_timer.start()
	else:
		train_all_trees()
	
	print("Starting Random Forest training with ", num_trees, " trees")

func _on_training_timer_timeout() -> void:
	"""Handle training timer timeout"""
	if not is_training:
		return
	
	if current_tree_index < num_trees:
		train_single_tree(current_tree_index)
		current_tree_index += 1
	else:
		finalize_training()

func train_single_tree(tree_index: int) -> void:
	"""Train a single decision tree"""
	# Create bootstrap sample
	var bootstrap_data = []
	var bootstrap_labels = []
	var sample_size = int(training_data.size() * bootstrap_sample_size)
	
	for i in range(sample_size):
		var random_index: int = _forest_rng.randi_range(0, training_data.size() - 1)
		bootstrap_data.append(training_data[random_index])
		bootstrap_labels.append(training_labels[random_index])
	
	bootstrap_samples.append({"data": bootstrap_data, "labels": bootstrap_labels})
	
	# Create and train decision tree
	var tree = DecisionTree.new(
		tree_index,
		max_depth,
		min_samples_split,
		int(num_features * max_features),
		TREE_SEED_BASE + tree_index
	)
	
	var feature_indices = []
	for i in range(num_features):
		feature_indices.append(i)
	
	tree.train(bootstrap_data, bootstrap_labels, feature_indices)
	decision_trees.append(tree)
	
	# Create visualization for this tree
	if show_individual_trees:
		create_tree_visualization(tree, tree_index)
	
	# Update 3D stats label
	if _stats_label_3d:
		_stats_label_3d.text = "Trees: %d / %d  |  Samples: %d" % [
			decision_trees.size(), num_trees, training_data.size()
		]
	
	print("Trained tree ", tree_index + 1, "/", num_trees)
	update_ui()

func train_all_trees() -> void:
	"""Train all trees without animation"""
	for i in range(num_trees):
		train_single_tree(i)
	
	finalize_training()

func finalize_training() -> void:
	"""Finalize Random Forest training"""
	is_training = false
	training_complete = true
	training_timer.stop()
	
	if show_feature_importance:
		calculate_feature_importance()
	
	# Update 3D stats with completion
	if _stats_label_3d:
		_stats_label_3d.text = "Training Complete!  Trees: %d  |  Samples: %d" % [
			num_trees, training_data.size()
		]
		# Flash gold on completion
		var tw := create_tween()
		tw.tween_property(_stats_label_3d, "modulate", COLOR_SPECIAL, 0.2)
		tw.tween_property(_stats_label_3d, "modulate", Color.WHITE, 0.8)
	
	# Pulse all tree visualizations to celebrate
	for tree_vis in tree_visualizations:
		var tw2 := create_tween()
		tw2.tween_property(tree_vis, "scale", Vector3.ONE * 1.15, 0.2).set_ease(Tween.EASE_OUT)
		tw2.tween_property(tree_vis, "scale", Vector3.ONE, 0.4).set_ease(Tween.EASE_IN_OUT)
	
	print("Random Forest training completed")
	update_ui()

func create_tree_visualization(tree: DecisionTree, tree_index: int) -> void:
	"""Create 3D visualization of a decision tree"""
	var tree_root = Node3D.new()
	tree_root.name = "Tree_" + str(tree_index)
	
	# Position trees in a circle
	var angle = (tree_index / float(num_trees)) * 2.0 * PI
	var radius = tree_spacing * num_trees * 0.1
	tree_root.position = Vector3(
		cos(angle) * radius,
		0,
		sin(angle) * radius
	)
	
	forest_root.add_child(tree_root)
	
	# Create nodes for the tree
	var color = tree_colors[tree_index % tree_colors.size()]
	create_tree_nodes(tree.root, tree_root, Vector3.ZERO, color, 0)
	
	# Animate tree growing in (scale from zero)
	tree_root.scale = Vector3.ZERO
	var tw := create_tween()
	tw.tween_property(tree_root, "scale", Vector3.ONE, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	tree_visualizations.append(tree_root)

func create_tree_nodes(node: DecisionTreeNode, parent: Node3D, position: Vector3, color: Color, level: int) -> void:
	"""Recursively create tree node visualizations"""
	if not node:
		return
	
	var node_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(node_size, node_size, node_size)
	node_mesh.mesh = mesh
	
	var material = StandardMaterial3D.new()
	if node.is_leaf:
		material.albedo_color = color.lightened(0.3)
		material.emission_enabled = _emissive_on
		material.emission = color * 0.5
	else:
		material.albedo_color = color
		material.emission_enabled = _emissive_on
		material.emission = color * 0.3

	node_mesh.material_override = material
	node_mesh.position = position
	parent.add_child(node_mesh)

	# THE PER-NODE CAPTION — the hazard in this artifact.
	#
	# This used to hang 0.1 m ABOVE every node box: font 16 (0.08 m of text, ~0.32 m
	# wide) floating over a 0.2 m cube, up to 63 nodes per tree across 5 trees. It
	# passed the placement gate only because billboard was left at Godot's
	# BILLBOARD_DISABLED default and the framer skips disabled labels — an unearned
	# exemption one flag-flip away from 315 opaque plates 0.32 m wide burying a
	# scatter whose points are 0.12 m across.
	#
	# The exemption is now EARNED rather than inherited: the caption lies flat on the
	# cube's own front face (z = half the cube + 2 mm), feature and threshold share
	# ONE line, and font 8 gives 0.04 m of text about 0.16 m wide — inside the 0.2 m
	# face. billboard stays DISABLED truthfully, because there is a cube directly
	# behind every glyph. The nodes are not deleted and they are not billboarded.
	var label := Label3D.new()
	if node.is_leaf:
		label.text = "Class: " + str(node.prediction)
	else:
		label.text = feature_names[node.feature_index] + " <=" + str(node.threshold).pad_decimals(2)

	label.font_size = NODE_LABEL_FONT
	# Godot's default outline (12) would swallow 0.04 m glyphs whole.
	label.outline_size = NODE_LABEL_OUTLINE
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.position = Vector3(0, 0, node_size * 0.5 + 0.002)
	node_mesh.add_child(label)

	# Create child nodes
	var child_offset = max(0.5, 2.0 / pow(2, level))
	
	if node.left_child:
		var left_pos = position + Vector3(-child_offset, -0.5, 0)
		create_tree_nodes(node.left_child, parent, left_pos, color, level + 1)
		
		# Create connection line
		create_connection_line(node_mesh, left_pos, color)
	
	if node.right_child:
		var right_pos = position + Vector3(child_offset, -0.5, 0)
		create_tree_nodes(node.right_child, parent, right_pos, color, level + 1)
		
		# Create connection line
		create_connection_line(node_mesh, right_pos, color)

func create_connection_line(from_node: MeshInstance3D, to_position: Vector3, color: Color) -> void:
	"""Create a line connecting tree nodes"""
	var line = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	
	var direction = to_position - from_node.position
	var length = direction.length()
	var center = from_node.position + direction * 0.5
	
	mesh.size = Vector3(0.02, 0.02, length)
	line.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = _emissive_on
	material.emission = color * 0.2
	line.material_override = material
	
	line.position = center
	line.look_at_from_position(line.position, from_node.position + direction, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI/2)
	
	from_node.get_parent().add_child(line)

func predict_sample(sample: Array) -> Dictionary:
	"""Predict class for a sample using the entire forest"""
	if not training_complete:
		return {"error": "Forest not trained"}
	
	var predictions = []
	for tree in decision_trees:
		predictions.append(tree.predict(sample))
	
	# Count votes
	var vote_counts = {}
	for prediction in predictions:
		vote_counts[prediction] = vote_counts.get(prediction, 0) + 1
	
	# Find majority vote
	var max_votes = 0
	var final_prediction = 0
	for class_label in vote_counts:
		if vote_counts[class_label] > max_votes:
			max_votes = vote_counts[class_label]
			final_prediction = class_label
	
	var confidence = float(max_votes) / float(num_trees)
	
	return {
		"prediction": final_prediction,
		"confidence": confidence,
		"votes": vote_counts,
		"individual_predictions": predictions
	}

func calculate_feature_importance():
	"""Calculate feature importance across all trees"""
	var importance_scores = []
	for i in range(num_features):
		importance_scores.append(0.0)
	
	# This is a simplified importance calculation
	# In practice, you'd calculate based on information gain
	for tree in decision_trees:
		calculate_tree_importance(tree.root, importance_scores)
	
	# Normalize
	var total_importance = 0.0
	for score in importance_scores:
		total_importance += score
	
	if total_importance > 0:
		for i in range(importance_scores.size()):
			importance_scores[i] /= total_importance
	
	print("Feature importance: ", importance_scores)
	return importance_scores

func calculate_tree_importance(node: DecisionTreeNode, importance_scores: Array) -> void:
	"""Recursively calculate importance for a tree"""
	if not node or node.is_leaf:
		return
	
	# Simple importance based on node usage
	importance_scores[node.feature_index] += node.samples_count * node.gini_impurity
	
	if node.left_child:
		calculate_tree_importance(node.left_child, importance_scores)
	if node.right_child:
		calculate_tree_importance(node.right_child, importance_scores)

func clear_tree_visualizations() -> void:
	"""Clear all tree visualizations"""
	for tree_vis in tree_visualizations:
		tree_vis.queue_free()
	tree_visualizations.clear()

func clear_data_points() -> void:
	"""Clear all data point visualizations"""
	for point in data_points:
		# Drop the ownership record too, so _rebuild_now never revisits a corpse.
		_owned.erase(point)
		point.queue_free()
	data_points.clear()

func update_ui() -> void:
	"""Update UI with current Random Forest state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(25):
		var label = ui_display.get_node_or_null("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 25:
		labels[0].text = "🌲 Random Forest - Collective Intelligence"
		labels[1].text = "Trees: " + str(num_trees)
		labels[2].text = "Max Depth: " + str(max_depth)
		labels[3].text = "Bootstrap Size: " + str(bootstrap_sample_size * 100) + "%"
		labels[4].text = "Max Features: " + str(max_features * 100) + "%"
		labels[5].text = ""
		labels[6].text = "Training Status: " + ("Training..." if is_training else "Complete" if training_complete else "Not Started")
		labels[7].text = "Trees Trained: " + str(decision_trees.size()) + "/" + str(num_trees)
		labels[8].text = "Training Samples: " + str(training_data.size())
		labels[9].text = "Features: " + str(num_features)
		labels[10].text = ""
		labels[11].text = "Visualization:"
		labels[12].text = "Individual Trees: " + ("Yes" if show_individual_trees else "No")
		labels[13].text = "Feature Importance: " + ("Yes" if show_feature_importance else "No")
		labels[14].text = "Bootstrap Process: " + ("Yes" if show_bootstrap_process else "No")
		labels[15].text = ""
		labels[16].text = "Controls:"
		labels[17].text = "SPACE - Start/Stop Training"
		labels[18].text = "R - Reset Forest"
		labels[19].text = "T - Toggle Tree Display"
		labels[20].text = "↑/↓ - Adjust Tree Count"
		labels[21].text = ""
		labels[22].text = "🏳️‍🌈 Democratic Algorithm Framework:"
		labels[23].text = "Explores collective decision-making"
		labels[24].text = "through ensemble learning methods"

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
				reset_forest()
			KEY_T:
				toggle_tree_display()
			KEY_UP:
				num_trees = min(num_trees + 1, 10)
				reset_forest()
			KEY_DOWN:
				num_trees = max(num_trees - 1, 1)
				reset_forest()

func stop_training() -> void:
	"""Stop Random Forest training"""
	is_training = false
	training_timer.stop()

func reset_forest() -> void:
	"""Reset Random Forest and regenerate data"""
	stop_training()
	training_complete = false
	current_tree_index = 0
	decision_trees.clear()
	bootstrap_samples.clear()
	clear_tree_visualizations()
	generate_training_data()

func toggle_tree_display() -> void:
	"""Toggle individual tree display"""
	show_individual_trees = !show_individual_trees
	
	if show_individual_trees and training_complete:
		# Recreate tree visualizations
		for i in range(decision_trees.size()):
			create_tree_visualization(decision_trees[i], i)
	else:
		clear_tree_visualizations()

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive algorithm information"""
	return {
		"name": "Random Forest",
		"description": "Ensemble learning with multiple decision trees",
		"parameters": {
			"num_trees": num_trees,
			"max_depth": max_depth,
			"min_samples_split": min_samples_split,
			"max_features": max_features,
			"bootstrap_sample_size": bootstrap_sample_size
		},
		"training_status": {
			"is_training": is_training,
			"training_complete": training_complete,
			"trees_trained": decision_trees.size(),
			"total_trees": num_trees
		},
		"data_info": {
			"num_samples": training_data.size(),
			"num_features": num_features,
			"class_balance": class_balance
		}
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION — Stage-2 DNA: #cohort:rings
# ═══════════════════════════════════════════════════════════════════
# GridInteractablesComponent calls this via call_deferred, AFTER _ready() and
# first in the deferred queue, so _build_all() has already run and _built is true.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_cohort: String = cohort

	if config_data.has("cohort"):
		cohort = _pick_axis(str(config_data["cohort"]), COHORTS, cohort)

	# NON-GEOMETRY KEYS, APPLIED IN PLACE — before every return below.
	# curation_station.gd hands EVERY artifact it curates {"emissive": false} one
	# line after framing its labels. That dict carries no axis, so the early return
	# will fire; if this were done after the return the key would be accepted and
	# do nothing, which is how two artifacts in an earlier wave lied.
	if config_data.has("emissive"):
		_emissive_on = _as_bool(config_data["emissive"], _emissive_on)
		_apply_emissive_in_place()

	if not _built:
		return
	if cohort == before_cohort:
		return

	_rebuild_now()
	print("[RandomForest] Config applied — cohort=%s" % [cohort])


## Tear down exactly what this script built, then rebuild inline. SYNCHRONOUS: a
## deferred rebuild that removes children first makes auto-grounding measure a zero
## AABB and bail.
func _rebuild_now() -> void:
	is_training = false
	training_complete = false
	current_tree_index = 0
	decision_trees.clear()
	bootstrap_samples.clear()
	tree_visualizations.clear()
	data_points.clear()

	for c in _owned:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_owned.clear()

	ui_display = null
	training_timer = null
	forest_root = null
	_title_label_3d = null
	_stats_label_3d = null

	_build_all()

	if auto_start:
		call_deferred("start_training")


## Accept an axis value only if it names something we actually build. A typo has to
## fall back to the shipped look rather than strand a placement with no scatter.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Map tokens arrive as strings as often as booleans.
func _as_bool(v: Variant, fallback: bool) -> bool:
	match typeof(v):
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT:
			return float(v) != 0.0
		TYPE_STRING, TYPE_STRING_NAME:
			var s: String = str(v).to_lower().strip_edges()
			if s == "true" or s == "1" or s == "yes" or s == "on":
				return true
			if s == "false" or s == "0" or s == "no" or s == "off":
				return false
	return fallback


## Emission is switched on the live materials — data points, tree node cubes and
## connection lines — so the key bites without a rebuild. _emissive_on is also read
## by every material constructor, so a later rebuild keeps the setting.
func _apply_emissive_in_place() -> void:
	for p in data_points:
		if is_instance_valid(p) and p is MeshInstance3D:
			var m: Material = (p as MeshInstance3D).material_override
			if m is StandardMaterial3D:
				(m as StandardMaterial3D).emission_enabled = _emissive_on
	if forest_root and is_instance_valid(forest_root):
		_set_emissive_recursive(forest_root)


func _set_emissive_recursive(n: Node) -> void:
	if n is MeshInstance3D:
		var m: Material = (n as MeshInstance3D).material_override
		if m is StandardMaterial3D:
			(m as StandardMaterial3D).emission_enabled = _emissive_on
	for child in n.get_children():
		_set_emissive_recursive(child)

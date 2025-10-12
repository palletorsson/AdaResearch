extends Node3D

# Random Forest: Collective Intelligence & Democratic Decision Making
# Visualizes ensemble learning through multiple decision trees
# Explores collective decision-making processes and democratic algorithms

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
	
	func _init(id: int = 0, d: int = 0):
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
	
	func _init(id: int, max_d: int, min_samples: int, max_feat: int):
		tree_id = id
		max_depth = max_d
		min_samples_split = min_samples
		max_features = max_feat
		next_node_id = 0
	
	func train(data: Array, labels: Array, feature_indices: Array):
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
		var shuffled_features = feature_indices.duplicate()
		shuffled_features.shuffle()
		
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
func _init():
	name = "RandomForest_Visualization"

func _ready():
	setup_ui()
	setup_timer()
	setup_forest_visualization()
	generate_training_data()
	
	if auto_start:
		call_deferred("start_training")

func setup_ui():
	"""Create comprehensive UI for Random Forest visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
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

func setup_timer():
	"""Setup timer for training animation"""
	training_timer = Timer.new()
	training_timer.wait_time = training_speed
	training_timer.timeout.connect(_on_training_timer_timeout)
	add_child(training_timer)

func setup_forest_visualization():
	"""Setup the 3D forest visualization container"""
	forest_root = Node3D.new()
	forest_root.name = "Forest_Root"
	add_child(forest_root)

func generate_training_data():
	"""Generate training data with multiple features"""
	training_data.clear()
	training_labels.clear()
	
	for i in range(num_samples):
		var sample = []
		for j in range(num_features):
			sample.append(randf_range(-2.0, 2.0))
		
		# Create a complex decision boundary
		var label = 0
		var decision_value = sample[0] * 0.5 + sample[1] * 0.3 - sample[2] * 0.2 + sample[3] * 0.4
		decision_value += randf_range(-noise_level, noise_level)
		
		if decision_value > 0:
			label = 1
		
		training_data.append(sample)
		training_labels.append(label)
	
	create_data_visualization()
	print("Generated ", training_data.size(), " training samples with ", num_features, " features")

func create_data_visualization():
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
		add_child(sphere)

func create_data_point(position: Vector3, label: int) -> MeshInstance3D:
	"""Create a 3D sphere for a data point"""
	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	sphere.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.9, 0.3) if label == 1 else Color(0.9, 0.3, 0.2)
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.3
	sphere.material_override = material
	
	sphere.position = position
	return sphere

func start_training():
	"""Start Random Forest training process"""
	if is_training:
		return
	
	is_training = true
	training_complete = false
	current_tree_index = 0
	decision_trees.clear()
	bootstrap_samples.clear()
	
	clear_tree_visualizations()
	
	if animate_tree_growth:
		training_timer.start()
	else:
		train_all_trees()
	
	print("Starting Random Forest training with ", num_trees, " trees")

func _on_training_timer_timeout():
	"""Handle training timer timeout"""
	if not is_training:
		return
	
	if current_tree_index < num_trees:
		train_single_tree(current_tree_index)
		current_tree_index += 1
	else:
		finalize_training()

func train_single_tree(tree_index: int):
	"""Train a single decision tree"""
	# Create bootstrap sample
	var bootstrap_data = []
	var bootstrap_labels = []
	var sample_size = int(training_data.size() * bootstrap_sample_size)
	
	for i in range(sample_size):
		var random_index = randi() % training_data.size()
		bootstrap_data.append(training_data[random_index])
		bootstrap_labels.append(training_labels[random_index])
	
	bootstrap_samples.append({"data": bootstrap_data, "labels": bootstrap_labels})
	
	# Create and train decision tree
	var tree = DecisionTree.new(
		tree_index,
		max_depth,
		min_samples_split,
		int(num_features * max_features)
	)
	
	var feature_indices = []
	for i in range(num_features):
		feature_indices.append(i)
	
	tree.train(bootstrap_data, bootstrap_labels, feature_indices)
	decision_trees.append(tree)
	
	# Create visualization for this tree
	if show_individual_trees:
		create_tree_visualization(tree, tree_index)
	
	print("Trained tree ", tree_index + 1, "/", num_trees)
	update_ui()

func train_all_trees():
	"""Train all trees without animation"""
	for i in range(num_trees):
		train_single_tree(i)
	
	finalize_training()

func finalize_training():
	"""Finalize Random Forest training"""
	is_training = false
	training_complete = true
	training_timer.stop()
	
	if show_feature_importance:
		calculate_feature_importance()
	
	print("Random Forest training completed")
	update_ui()

func create_tree_visualization(tree: DecisionTree, tree_index: int):
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
	
	tree_visualizations.append(tree_root)

func create_tree_nodes(node: DecisionTreeNode, parent: Node3D, position: Vector3, color: Color, level: int):
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
		material.emission_enabled = true
		material.emission = color * 0.5
	else:
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.3
	
	node_mesh.material_override = material
	node_mesh.position = position
	parent.add_child(node_mesh)
	
	# Add label
	var label = Label3D.new()
	if node.is_leaf:
		label.text = "Class: " + str(node.prediction)
	else:
		label.text = feature_names[node.feature_index] + "\n<=" + str(node.threshold).pad_decimals(2)
	
	label.font_size = 16
	label.position = Vector3(0, node_size + 0.1, 0)
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

func create_connection_line(from_node: MeshInstance3D, to_position: Vector3, color: Color):
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
	material.emission_enabled = true
	material.emission = color * 0.2
	line.material_override = material
	
	line.position = center
	line.look_at(from_node.position + direction, Vector3.UP)
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

func calculate_tree_importance(node: DecisionTreeNode, importance_scores: Array):
	"""Recursively calculate importance for a tree"""
	if not node or node.is_leaf:
		return
	
	# Simple importance based on node usage
	importance_scores[node.feature_index] += node.samples_count * node.gini_impurity
	
	if node.left_child:
		calculate_tree_importance(node.left_child, importance_scores)
	if node.right_child:
		calculate_tree_importance(node.right_child, importance_scores)

func clear_tree_visualizations():
	"""Clear all tree visualizations"""
	for tree_vis in tree_visualizations:
		tree_vis.queue_free()
	tree_visualizations.clear()

func clear_data_points():
	"""Clear all data point visualizations"""
	for point in data_points:
		point.queue_free()
	data_points.clear()

func update_ui():
	"""Update UI with current Random Forest state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(25):
		var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
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

func _input(event):
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

func stop_training():
	"""Stop Random Forest training"""
	is_training = false
	training_timer.stop()

func reset_forest():
	"""Reset Random Forest and regenerate data"""
	stop_training()
	training_complete = false
	current_tree_index = 0
	decision_trees.clear()
	bootstrap_samples.clear()
	clear_tree_visualizations()
	generate_training_data()

func toggle_tree_display():
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

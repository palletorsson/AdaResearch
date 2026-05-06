# @identity
# essence: forest = {tree_i(bootstrap_i(X, random_features)) for i in 1..n_trees}. Many weak trees on random subsets, majority vote.
# desire: Watch a forest grow — each tree sees different data, makes different mistakes, but together they're wiser than any single tree.
# critical_parameter: n_trees — more trees = smoother boundary, less variance, but diminishing returns. The wisdom of crowds.
# triggers: Automatic — trees grow one by one, each from a different bootstrap sample. Vote boundary updates after each tree.
# emerges: The ensemble boundary is smoother than any individual tree's boundary. Individual trees overfit; the forest generalizes.
# needs: Auto-stepping [has]. Missing: feature importance display, out-of-bag error, tree depth control.
# relationships: Contrasts with AdaBoost (parallel vs sequential). Both are ensembles but Random Forest uses bagging + feature randomness instead of sample weighting.
# truth: A random forest is democracy applied to prediction. Each tree votes from its own limited perspective. The majority is usually right.

extends Node3D

const N_SAMPLES := 80
const N_TREES := 12
const FIELD_SIZE := 4.0
const TREE_DEPTH := 3

var _samples: Array = []
var _trees: Array = []  # Each tree: Array of splits
var _tree_count := 0
var _timer := 0.0
var _tree_interval := 1.5

var _sample_meshes: Array[MeshInstance3D] = []
var _tree_columns: Array[MeshInstance3D] = []
var _boundary_mesh: ImmediateMesh
var _boundary_instance: MeshInstance3D
var _info_label: Label3D
var _title_label: Label3D

# Colors for individual tree boundaries
var _tree_colors: Array[Color] = [
	Color(1.0, 0.3, 0.3, 0.2), Color(0.3, 1.0, 0.3, 0.2),
	Color(0.3, 0.3, 1.0, 0.2), Color(1.0, 1.0, 0.3, 0.2),
	Color(1.0, 0.3, 1.0, 0.2), Color(0.3, 1.0, 1.0, 0.2),
	Color(1.0, 0.6, 0.2, 0.2), Color(0.6, 0.2, 1.0, 0.2),
	Color(0.2, 0.8, 0.5, 0.2), Color(0.8, 0.5, 0.2, 0.2),
	Color(0.5, 0.2, 0.8, 0.2), Color(0.2, 0.5, 0.8, 0.2),
]

func _ready() -> void:
	_create_environment()
	_generate_data()
	_create_visuals()
	_create_labels()
	_create_tree_display()

func _create_environment() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(FIELD_SIZE * 2.2, FIELD_SIZE * 2.2)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.08, 0.06)
	mat.roughness = 0.95
	ground.material_override = mat
	add_child(ground)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 1.3
	add_child(light)

func _generate_data() -> void:
	# Spiral-like pattern — harder to classify
	for i in range(N_SAMPLES):
		var label: int = i % 2
		var angle: float = float(i) * 0.15 + label * PI
		var radius: float = 0.5 + float(i) / N_SAMPLES * 3.0
		var noise := Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		var pos := Vector2(cos(angle) * radius, sin(angle) * radius) + noise
		pos = pos.clampf(-FIELD_SIZE + 0.5, FIELD_SIZE - 0.5)
		_samples.append({"pos": pos, "label": label})

func _create_visuals() -> void:
	for i in range(_samples.size()):
		var s: Dictionary = _samples[i]
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		mesh.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.85, 0.4) if s["label"] == 0 else Color(0.85, 0.3, 0.8)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color * 0.3
		mat.emission_energy_multiplier = 1.5
		mesh.material_override = mat
		mesh.position = Vector3(s["pos"].x, 0.08, s["pos"].y)
		add_child(mesh)
		_sample_meshes.append(mesh)

	# Ensemble boundary
	_boundary_mesh = ImmediateMesh.new()
	_boundary_instance = MeshInstance3D.new()
	_boundary_instance.mesh = _boundary_mesh
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.3, 1.0, 0.4, 0.5)
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_boundary_instance.material_override = bmat
	add_child(_boundary_instance)

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Random Forest"
	_title_label.font_size = 28
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, 3.5, 0)
	_title_label.modulate = Color(0.3, 1.0, 0.5, 0.9)
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.text = "Trees: 0/%d" % N_TREES
	_info_label.font_size = 20
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0, 3.0, 0)
	_info_label.modulate = Color(0.7, 0.7, 0.7, 0.7)
	add_child(_info_label)

func _create_tree_display() -> void:
	# Visual tree indicators along the back edge
	for i in range(N_TREES):
		var col := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.15
		cyl.bottom_radius = 0.15
		cyl.height = 0.1
		col.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.2, 0.2)
		mat.roughness = 0.6
		col.material_override = mat
		col.position = Vector3(-FIELD_SIZE + i * (FIELD_SIZE * 2.0 / (N_TREES - 1)), 0.05, -FIELD_SIZE - 0.8)
		add_child(col)
		_tree_columns.append(col)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _tree_interval and _tree_count < N_TREES:
		_timer = 0.0
		_grow_tree()

func _grow_tree() -> void:
	# Bootstrap sample
	var bootstrap: Array = []
	for i in range(_samples.size()):
		bootstrap.append(_samples[randi() % _samples.size()])

	# Build a simple decision tree with random feature selection
	var tree := _build_tree(bootstrap, TREE_DEPTH)
	_trees.append(tree)
	_tree_count += 1

	# Light up the tree column
	var col: MeshInstance3D = _tree_columns[_tree_count - 1]
	var mat := col.material_override as StandardMaterial3D
	var tc: Color = _tree_colors[(_tree_count - 1) % _tree_colors.size()]
	mat.albedo_color = Color(tc.r, tc.g, tc.b, 1.0)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.5
	mat.emission_energy_multiplier = 2.0
	col.scale.y = 1.0 + _tree_count * 0.5  # Grow taller

	_update_boundary()
	_update_info()

func _build_tree(data: Array, depth: int) -> Dictionary:
	if depth == 0 or data.size() < 4:
		# Leaf: majority vote
		var count_0 := 0
		var count_1 := 0
		for d in data:
			if d["label"] == 0: count_0 += 1
			else: count_1 += 1
		return {"leaf": true, "label": 0 if count_0 >= count_1 else 1}

	# Random feature: pick one axis
	var axis: int = randi() % 2
	var best_thresh := 0.0
	var best_gini := 999.0

	# Try random thresholds
	for _t in range(5):
		var idx: int = randi() % data.size()
		var thresh: float = data[idx]["pos"].x if axis == 0 else data[idx]["pos"].y
		var left: Array = []
		var right: Array = []
		for d in data:
			var val: float = d["pos"].x if axis == 0 else d["pos"].y
			if val < thresh: left.append(d)
			else: right.append(d)

		var gini := _gini_split(left, right, data.size())
		if gini < best_gini:
			best_gini = gini
			best_thresh = thresh

	# Split
	var left_data: Array = []
	var right_data: Array = []
	for d in data:
		var val: float = d["pos"].x if axis == 0 else d["pos"].y
		if val < best_thresh: left_data.append(d)
		else: right_data.append(d)

	if left_data.is_empty() or right_data.is_empty():
		var count_0 := 0
		for d in data:
			if d["label"] == 0: count_0 += 1
		return {"leaf": true, "label": 0 if count_0 >= data.size() / 2 else 1}

	return {
		"leaf": false,
		"axis": axis,
		"threshold": best_thresh,
		"left": _build_tree(left_data, depth - 1),
		"right": _build_tree(right_data, depth - 1),
	}

func _gini_split(left: Array, right: Array, total: int) -> float:
	if left.is_empty() or right.is_empty(): return 999.0
	var gl := _gini(left)
	var gr := _gini(right)
	return (float(left.size()) / total) * gl + (float(right.size()) / total) * gr

func _gini(data: Array) -> float:
	if data.is_empty(): return 0.0
	var c0 := 0
	for d in data:
		if d["label"] == 0: c0 += 1
	var p0: float = float(c0) / data.size()
	return 1.0 - p0 * p0 - (1.0 - p0) * (1.0 - p0)

func _tree_predict(tree: Dictionary, pos: Vector2) -> int:
	if tree["leaf"]:
		return tree["label"]
	var val: float = pos.x if tree["axis"] == 0 else pos.y
	if val < tree["threshold"]:
		return _tree_predict(tree["left"], pos)
	else:
		return _tree_predict(tree["right"], pos)

func _forest_predict(pos: Vector2) -> int:
	if _trees.is_empty(): return 0
	var votes_0 := 0
	var votes_1 := 0
	for tree in _trees:
		var pred := _tree_predict(tree, pos)
		if pred == 0: votes_0 += 1
		else: votes_1 += 1
	return 0 if votes_0 >= votes_1 else 1

func _update_boundary() -> void:
	_boundary_mesh.clear_surfaces()
	var res := 25
	var step: float = FIELD_SIZE * 2.0 / res
	_boundary_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for xi in range(res):
		for zi in range(res):
			var x: float = -FIELD_SIZE + xi * step
			var z: float = -FIELD_SIZE + zi * step
			var pred := _forest_predict(Vector2(x, z))
			var pred_r := _forest_predict(Vector2(x + step, z))
			var pred_d := _forest_predict(Vector2(x, z + step))
			# Draw boundary where prediction changes
			if pred != pred_r:
				_boundary_mesh.surface_add_vertex(Vector3(x + step, 0.05, z))
				_boundary_mesh.surface_add_vertex(Vector3(x + step, 0.05, z + step))
			if pred != pred_d:
				_boundary_mesh.surface_add_vertex(Vector3(x, 0.05, z + step))
				_boundary_mesh.surface_add_vertex(Vector3(x + step, 0.05, z + step))
	_boundary_mesh.surface_end()

func _update_info() -> void:
	var correct := 0
	for s in _samples:
		if _forest_predict(s["pos"]) == s["label"]:
			correct += 1
	var acc: float = float(correct) / N_SAMPLES * 100.0
	_info_label.text = "Trees: %d/%d  |  Acc: %.0f%%  |  Gini split" % [_tree_count, N_TREES, acc]

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass

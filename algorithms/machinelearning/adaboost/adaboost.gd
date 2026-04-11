# @identity
# essence: w(i) *= exp(alpha * err_i). Points that the last stump got wrong get heavier. The next stump focuses on the hard cases.
# desire: Watch a sequence of weak learners (stumps) each specialize on what the previous one failed. The ensemble gets smarter by remembering its mistakes.
# critical_parameter: n_rounds — how many weak learners to add. Too few = underfitting. Too many = overfitting. The sweet spot is where the weighted vote stabilizes.
# triggers: Automatic — builds one stump per round, updates sample weights, shows accumulated decision boundary.
# emerges: Misclassified points grow visually larger as their weight increases. The ensemble boundary gets progressively more complex from simple stumps.
# needs: Auto-stepping simulation [has]. Missing: VR speed slider, pause/step controls.
# relationships: Contrasts with RandomForest (sequential vs parallel). Both are ensemble methods but with opposite strategies — boosting vs bagging.
# truth: AdaBoost is a conversation between failure and focus. Each mistake makes the next learner pay more attention to what was missed.

class_name AdaBoostVisualization
extends Node3D

const N_SAMPLES := 60
const N_ROUNDS := 8
const FIELD_SIZE := 4.0

var _samples: Array = []  # {pos: Vector2, label: int, weight: float, mesh: MeshInstance3D}
var _stumps: Array = []   # {axis: int, threshold: float, polarity: int, alpha: float}
var _round := 0
var _timer := 0.0
var _round_interval := 2.0

var _sample_meshes: Array[MeshInstance3D] = []
var _boundary_mesh: ImmediateMesh
var _boundary_instance: MeshInstance3D
var _info_label: Label3D
var _title_label: Label3D
var _stump_labels: Array[Label3D] = []

func _ready() -> void:
	_create_environment()
	_generate_data()
	_create_visuals()
	_create_labels()

func _create_environment() -> void:
	# Ground plane
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(FIELD_SIZE * 2.2, FIELD_SIZE * 2.2)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.12)
	mat.roughness = 0.95
	ground.material_override = mat
	add_child(ground)

	# Light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 1.3
	add_child(light)

func _generate_data() -> void:
	# Two overlapping clusters — not linearly separable
	for i in range(N_SAMPLES):
		var label: int
		var pos: Vector2
		if i < N_SAMPLES / 2:
			label = 0  # class A
			pos = Vector2(randf_range(-2.0, 1.0), randf_range(-2.0, 1.0))
			# Add some noise into class B territory
			if randf() < 0.2:
				pos = Vector2(randf_range(0.0, 2.0), randf_range(0.0, 2.0))
		else:
			label = 1  # class B
			pos = Vector2(randf_range(-1.0, 2.0), randf_range(-1.0, 2.0))
			if randf() < 0.2:
				pos = Vector2(randf_range(-2.0, 0.0), randf_range(-2.0, 0.0))

		_samples.append({
			"pos": pos,
			"label": label,
			"weight": 1.0 / N_SAMPLES,
		})

func _create_visuals() -> void:
	# Sample spheres — size encodes weight
	for i in range(_samples.size()):
		var s: Dictionary = _samples[i]
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.08
		sphere.height = 0.16
		mesh.mesh = sphere

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.8, 1.0) if s["label"] == 0 else Color(1.0, 0.4, 0.3)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color * 0.4
		mat.emission_energy_multiplier = 1.5
		mesh.material_override = mat

		mesh.position = Vector3(s["pos"].x, 0.1, s["pos"].y)
		add_child(mesh)
		_sample_meshes.append(mesh)

	# Boundary visualization
	_boundary_mesh = ImmediateMesh.new()
	_boundary_instance = MeshInstance3D.new()
	_boundary_instance.mesh = _boundary_mesh
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(1.0, 1.0, 0.3, 0.6)
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_boundary_instance.material_override = bmat
	add_child(_boundary_instance)

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "AdaBoost"
	_title_label.font_size = 28
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, 3.5, 0)
	_title_label.modulate = Color(1, 1, 1, 0.9)
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.text = "Round 0/%d" % N_ROUNDS
	_info_label.font_size = 20
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0, 3.0, 0)
	_info_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
	add_child(_info_label)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _round_interval and _round < N_ROUNDS:
		_timer = 0.0
		_do_round()

func _do_round() -> void:
	_round += 1

	# Find best decision stump
	var best_stump := _find_best_stump()
	_stumps.append(best_stump)

	# Compute error
	var err := 0.0
	for i in range(_samples.size()):
		var pred := _stump_predict(best_stump, _samples[i]["pos"])
		if pred != _samples[i]["label"]:
			err += _samples[i]["weight"]
	err = clampf(err, 0.001, 0.999)

	# Compute alpha (stump weight)
	var alpha: float = 0.5 * log((1.0 - err) / err)
	best_stump["alpha"] = alpha

	# Update sample weights
	var total_w := 0.0
	for i in range(_samples.size()):
		var pred := _stump_predict(best_stump, _samples[i]["pos"])
		var correct: float = 1.0 if pred == _samples[i]["label"] else -1.0
		_samples[i]["weight"] *= exp(-alpha * correct)
		total_w += _samples[i]["weight"]

	# Normalize
	for i in range(_samples.size()):
		_samples[i]["weight"] /= total_w

	# Update visuals
	_update_sample_sizes()
	_update_boundary()
	_update_info()
	_add_stump_label(best_stump)

func _find_best_stump() -> Dictionary:
	var best := {"axis": 0, "threshold": 0.0, "polarity": 1, "alpha": 0.0}
	var best_err := 999.0

	for axis in [0, 1]:
		for ti in range(10):
			var threshold: float = -FIELD_SIZE + ti * (FIELD_SIZE * 2.0 / 9.0)
			for polarity in [1, -1]:
				var err := 0.0
				for i in range(_samples.size()):
					var val: float = _samples[i]["pos"].x if axis == 0 else _samples[i]["pos"].y
					var pred: int = 0 if (val * polarity < threshold * polarity) else 1
					if pred != _samples[i]["label"]:
						err += _samples[i]["weight"]
				if err < best_err:
					best_err = err
					best = {"axis": axis, "threshold": threshold, "polarity": polarity, "alpha": 0.0}
	return best

func _stump_predict(stump: Dictionary, pos: Vector2) -> int:
	var val: float = pos.x if stump["axis"] == 0 else pos.y
	return 0 if (val * stump["polarity"] < stump["threshold"] * stump["polarity"]) else 1

func _ensemble_predict(pos: Vector2) -> float:
	var score := 0.0
	for stump in _stumps:
		var pred := _stump_predict(stump, pos)
		var vote: float = 1.0 if pred == 1 else -1.0
		score += stump["alpha"] * vote
	return score

func _update_sample_sizes() -> void:
	var max_w := 0.0
	for s in _samples:
		max_w = maxf(max_w, s["weight"])

	for i in range(_samples.size()):
		var w: float = _samples[i]["weight"]
		var scale: float = 0.5 + (w / maxf(max_w, 0.001)) * 2.0
		_sample_meshes[i].scale = Vector3.ONE * scale

func _update_boundary() -> void:
	_boundary_mesh.clear_surfaces()

	var res := 20
	var step: float = FIELD_SIZE * 2.0 / res
	_boundary_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for xi in range(res):
		for zi in range(res):
			var x: float = -FIELD_SIZE + xi * step
			var z: float = -FIELD_SIZE + zi * step
			var score := _ensemble_predict(Vector2(x, z))
			if absf(score) < 0.3:
				_boundary_mesh.surface_add_vertex(Vector3(x, 0.05, z))
				_boundary_mesh.surface_add_vertex(Vector3(x + step * 0.5, 0.05, z + step * 0.5))
	_boundary_mesh.surface_end()

func _update_info() -> void:
	var correct := 0
	for i in range(_samples.size()):
		var score := _ensemble_predict(_samples[i]["pos"])
		var pred: int = 1 if score > 0 else 0
		if pred == _samples[i]["label"]:
			correct += 1
	var acc: float = float(correct) / N_SAMPLES * 100.0
	_info_label.text = "Round %d/%d  |  Stumps: %d  |  Acc: %.0f%%" % [_round, N_ROUNDS, _stumps.size(), acc]

func _add_stump_label(stump: Dictionary) -> void:
	var lbl := Label3D.new()
	var axis_name: String = "X" if stump["axis"] == 0 else "Z"
	lbl.text = "#%d %s=%.1f" % [_round, axis_name, stump["threshold"]]
	lbl.font_size = 12
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(1.0, 1.0, 0.3, 0.6)
	var pos: float = stump["threshold"]
	if stump["axis"] == 0:
		lbl.position = Vector3(pos, 0.3 + _round * 0.25, -FIELD_SIZE - 0.5)
	else:
		lbl.position = Vector3(-FIELD_SIZE - 0.5, 0.3 + _round * 0.25, pos)
	add_child(lbl)
	_stump_labels.append(lbl)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass

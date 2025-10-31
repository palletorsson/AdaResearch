extends Node3D

enum DetectionMode { Z_SCORE, ISOLATION_RADIUS, AUTOENCODER_ERROR }

const MODE_SEQUENCE := [
	DetectionMode.Z_SCORE,
	DetectionMode.ISOLATION_RADIUS,
	DetectionMode.AUTOENCODER_ERROR,
]

@export var normal_sample_count: int = 72
@export var anomaly_sample_count: int = 10
@export var dataset_seed: int = 20241031
@export var z_score_threshold: float = 2.4
@export var isolation_radius_threshold: float = 3.4
@export var autoencoder_error_threshold: float = 1.1
@export var anomaly_scale_multiplier: float = 1.35
@export var detection_mode: DetectionMode = DetectionMode.Z_SCORE

@onready var data_root: Node3D = $DataRoot
@onready var threshold_visual: MeshInstance3D = $ThresholdVisual
@onready var title_label: Label3D = $StatsLabels/TitleLabel
@onready var mode_label: Label3D = $StatsLabels/ModeLabel
@onready var summary_label: Label3D = $StatsLabels/SummaryLabel

const BASE_POINT_RADIUS := 0.12

var _rng := RandomNumberGenerator.new()
var _samples: Array = []
var _mean := Vector2.ZERO
var _std := Vector2.ONE
var _max_distance := 1.0

func _ready():
	_rng.seed = dataset_seed
	_generate_samples()
	_build_points()
	_refresh_statistics()
	run_detection()

func _generate_samples():
	_samples.clear()
	for i in range(max(10, normal_sample_count)):
		var pos := Vector2(
			_rng.randfn(0.0, 1.2),
			_rng.randfn(0.0, 1.0)
		)
		_samples.append({
			"position": pos,
			"tag": "normal"
		})

	for i in range(max(1, anomaly_sample_count)):
		var angle := _rng.randf_range(0.0, TAU)
		var radius := _rng.randf_range(4.0, 6.0)
		var offset := Vector2(cos(angle), sin(angle)) * radius
		offset.y += _rng.randfn(0.0, 0.6)
		_samples.append({
			"position": offset,
			"tag": "seeded_anomaly"
		})

func _build_points():
	for child in data_root.get_children():
		child.queue_free()

	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = BASE_POINT_RADIUS
	sphere_mesh.height = BASE_POINT_RADIUS * 2.0

	for sample in _samples:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = sphere_mesh
		mesh_instance.position = Vector3(sample["position"].x, 0.0, sample["position"].y)

		var material := StandardMaterial3D.new()
		material.metallic = 0.05
		material.roughness = 0.25
		material.emission_enabled = true
		material.emission = Color(0.2, 0.6, 1.0, 1.0) * 0.2
		mesh_instance.material_override = material

		data_root.add_child(mesh_instance)
		sample["mesh"] = mesh_instance
		sample["material"] = material

func run_detection():
	_refresh_statistics()
	var threshold := _active_threshold()
	var anomaly_count := 0
	var scores: Array = []

	for sample in _samples:
		var score := _score_sample(sample)
		sample["score"] = score
		scores.append(score)

		var normalized: float = clamp(score / threshold, 0.0, 1.5) if threshold > 0.0 else 0.0
		var mesh: MeshInstance3D = sample["mesh"]
		var material: StandardMaterial3D = sample["material"]

		var color_start: Color = Color(0.15, 0.75, 0.95, 1.0)
		var color_end: Color = Color(1.0, 0.3, 0.35, 1.0)
		var display_color := color_start.lerp(color_end, normalized)

		var is_anomaly := score >= threshold
		sample["is_anomaly"] = is_anomaly
		if is_anomaly:
			anomaly_count += 1

		material.albedo_color = display_color
		material.emission = display_color * (0.9 if is_anomaly else 0.25)
		mesh.scale = Vector3.ONE * (anomaly_scale_multiplier if is_anomaly else 1.0)
		mesh.position.y = 0.25 if is_anomaly else 0.0

	_update_threshold_visual(threshold)
	_update_labels(anomaly_count, scores, threshold)

func cycle_detection_mode() -> void:
	var idx: int = MODE_SEQUENCE.find(detection_mode)
	if idx == -1:
		idx = 0
	idx = (idx + 1) % MODE_SEQUENCE.size()
	detection_mode = MODE_SEQUENCE[idx]
	run_detection()

func reset_dataset(new_seed: int = dataset_seed) -> void:
	dataset_seed = new_seed
	_rng.seed = dataset_seed
	_generate_samples()
	_build_points()
	_refresh_statistics()
	run_detection()

func _refresh_statistics():
	if _samples.is_empty():
		_mean = Vector2.ZERO
		_std = Vector2.ONE
		_max_distance = 1.0
		return

	_mean = Vector2.ZERO
	for sample in _samples:
		_mean += sample["position"]
	_mean /= float(_samples.size())

	var variance := Vector2.ZERO
	_max_distance = 0.0
	for sample in _samples:
		var diff = sample["position"] - _mean
		variance.x += diff.x * diff.x
		variance.y += diff.y * diff.y
		_max_distance = max(_max_distance, diff.length())

	variance /= max(1.0, float(_samples.size()))
	_std = Vector2(
		sqrt(max(variance.x, 0.0001)),
		sqrt(max(variance.y, 0.0001))
	)
	_max_distance = max(_max_distance, 0.0001)

func _score_sample(sample: Dictionary) -> float:
	var pos: Vector2 = sample["position"]
	match detection_mode:
		DetectionMode.Z_SCORE:
			var z_x = abs((pos.x - _mean.x) / _std.x)
			var z_y = abs((pos.y - _mean.y) / _std.y)
			return z_x + z_y
		DetectionMode.ISOLATION_RADIUS:
			return (pos - _mean).length()
		DetectionMode.AUTOENCODER_ERROR:
			var expected_y := sin(pos.x * 0.6) * 1.5
			var reconstruction_error = abs(pos.y - expected_y)
			var radial_penalty = abs(pos.length() - 2.4) * 0.25
			return reconstruction_error + radial_penalty
	return 0.0

func _active_threshold() -> float:
	match detection_mode:
		DetectionMode.Z_SCORE:
			return max(0.5, z_score_threshold)
		DetectionMode.ISOLATION_RADIUS:
			return max(0.5, isolation_radius_threshold)
		DetectionMode.AUTOENCODER_ERROR:
			return max(0.1, autoencoder_error_threshold)
	return 1.0

func _update_threshold_visual(threshold: float) -> void:
	if not threshold_visual or not is_instance_valid(threshold_visual):
		return

	var visual_radius := 2.0
	match detection_mode:
		DetectionMode.Z_SCORE:
			visual_radius = max(0.5, ((_std.x + _std.y) * 0.5) * threshold)
		DetectionMode.ISOLATION_RADIUS:
			visual_radius = max(0.5, threshold)
		DetectionMode.AUTOENCODER_ERROR:
			visual_radius = max(0.5, 1.8 + threshold * 1.4)

	threshold_visual.scale = Vector3(visual_radius, 0.05, visual_radius)

	var material := threshold_visual.material_override
	if material == null:
		material = StandardMaterial3D.new()
		threshold_visual.material_override = material

	if material is StandardMaterial3D:
		var highlight := _mode_color()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(highlight.r, highlight.g, highlight.b, 0.18)
		material.emission_enabled = true
		material.emission = highlight * 0.35
		material.metallic = 0.0
		material.roughness = 0.4

func _update_labels(anomaly_count: int, scores: Array, threshold: float) -> void:
	if title_label:
		title_label.text = "Anomaly Detection Sandbox"

	if mode_label:
		mode_label.text = "[b]Mode:[/b] %s" % _mode_name()

	if summary_label:
		var total = max(1, _samples.size())
		scores.sort()
		var avg := 0.0
		for s in scores:
			avg += s
		avg /= total
		var median = scores[int(clamp(total / 2, 0, scores.size() - 1))]
		summary_label.text = "Anomalies: %d / %d\nThreshold: %.2f\nmu-score: %.2f  med-score: %.2f" % [
			anomaly_count,
			_total_samples(),
			threshold,
			avg,
			median
		]

func _mode_name() -> String:
	match detection_mode:
		DetectionMode.Z_SCORE:
			return "Z-Score"
		DetectionMode.ISOLATION_RADIUS:
			return "Isolation Radius"
		DetectionMode.AUTOENCODER_ERROR:
			return "Autoencoder Error"
	return "Unknown"

func _mode_color() -> Color:
	match detection_mode:
		DetectionMode.Z_SCORE:
			return Color(0.3, 0.7, 1.0, 1.0)
		DetectionMode.ISOLATION_RADIUS:
			return Color(0.6, 0.9, 0.4, 1.0)
		DetectionMode.AUTOENCODER_ERROR:
			return Color(1.0, 0.5, 0.6, 1.0)
	return Color.WHITE

func _total_samples() -> int:
	return _samples.size()

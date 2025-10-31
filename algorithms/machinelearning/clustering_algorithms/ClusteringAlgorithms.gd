extends Node3D

enum AlgorithmMode { K_MEANS, AGGLOMERATIVE, DBSCAN }

const MODE_SEQUENCE: Array[AlgorithmMode] = [
	AlgorithmMode.K_MEANS,
	AlgorithmMode.AGGLOMERATIVE,
	AlgorithmMode.DBSCAN,
]

const PALETTE: Array[Color] = [
	Color(0.15, 0.67, 0.95, 1.0),
	Color(0.25, 0.85, 0.45, 1.0),
	Color(0.96, 0.58, 0.20, 1.0),
	Color(0.85, 0.38, 0.78, 1.0),
	Color(0.30, 0.62, 0.78, 1.0),
]

const POINT_RADIUS: float = 0.12
const NOISE_COLOR: Color = Color(0.55, 0.55, 0.55, 1.0)

@export_range(30, 600, 10)
var sample_count: int = 180
@export_range(2, 6, 1)
var cluster_count: int = 3
@export var dataset_seed: int = 20241101
@export_range(0.2, 2.5, 0.05)
var cluster_spread: float = 0.8
@export_range(0.0, 0.3, 0.01)
var noise_ratio: float = 0.05
@export_range(0.5, 2.5, 0.05)
var dbscan_eps: float = 1.2
@export_range(3, 20, 1)
var dbscan_min_points: int = 6
@export_range(1, 12, 1)
var kmeans_iterations: int = 6
@export var algorithm_mode: AlgorithmMode = AlgorithmMode.K_MEANS
@export var animate_clusters: bool = true

@onready var data_root: Node3D = $DataRoot
@onready var centroids_root: Node3D = $CentroidsRoot
@onready var threshold_visual: MeshInstance3D = $ThresholdVisual
@onready var title_label: Label3D = $StatsLabels/TitleLabel
@onready var mode_label: Label3D = $StatsLabels/ModeLabel
@onready var summary_label: Label3D = $StatsLabels/SummaryLabel

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _samples: Array[Dictionary] = []
var _centroids: Array[Vector2] = []
var _inertia: float = 0.0
var _silhouette: float = 0.0
var _max_radius: float = 1.0

func _ready() -> void:
	_rng.seed = dataset_seed
	_generate_dataset()
	_build_point_meshes()
	run_clustering()

func _generate_dataset() -> void:
	_samples.clear()
	var safe_cluster_count = max(1, cluster_count)
	var centres: Array[Vector2] = []
	for i in range(safe_cluster_count):
		var angle := TAU * float(i) / float(safe_cluster_count)
		var radius := 3.5 + _rng.randf_range(-0.6, 0.6)
		centres.append(Vector2(cos(angle), sin(angle)) * radius)
	var normal_target = clamp(int(round(sample_count * (1.0 - noise_ratio))), 0, sample_count)
	var noise_target = sample_count - normal_target
	for i in range(normal_target):
		var idx = i % safe_cluster_count
		var base := centres[idx]
		var pos := Vector2(
			_rng.randfn(base.x, cluster_spread),
			_rng.randfn(base.y, cluster_spread)
		)
		_samples.append({
			"position": pos,
			"label": -1,
			"mesh": null,
			"material": null,
		})
	for i in range(noise_target):
		var pos := Vector2(
			_rng.randf_range(-6.0, 6.0),
			_rng.randf_range(-6.0, 6.0)
		)
		_samples.append({
			"position": pos,
			"label": -1,
			"mesh": null,
			"material": null,
		})
	_recalculate_dataset_radius()

func _build_point_meshes() -> void:
	for child in data_root.get_children():
		child.queue_free()
	var sphere := SphereMesh.new()
	sphere.radius = POINT_RADIUS
	sphere.height = POINT_RADIUS * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	for sample in _samples:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = sphere
		var pos: Vector2 = sample["position"]
		mesh_instance.position = Vector3(pos.x, 0.0, pos.y)
		var material := StandardMaterial3D.new()
		material.albedo_color = NOISE_COLOR
		material.emission_enabled = true
		material.emission = NOISE_COLOR * 0.25
		material.metallic = 0.05
		material.roughness = 0.3
		mesh_instance.material_override = material
		data_root.add_child(mesh_instance)
		sample["mesh"] = mesh_instance
		sample["material"] = material


func run_clustering() -> void:
	match algorithm_mode:
		AlgorithmMode.K_MEANS:
			_run_k_means()
		AlgorithmMode.AGGLOMERATIVE:
			_run_agglomerative()
		AlgorithmMode.DBSCAN:
			_run_dbscan()
	_apply_cluster_visuals()
	_update_centroid_visuals()
	_update_threshold_visual()
	_update_labels()

func cycle_algorithm_mode() -> void:
	var idx := MODE_SEQUENCE.find(algorithm_mode)
	if idx == -1:
		idx = 0
	idx = (idx + 1) % MODE_SEQUENCE.size()
	algorithm_mode = MODE_SEQUENCE[idx]
	run_clustering()

func reset_dataset(new_seed: int = dataset_seed) -> void:
	dataset_seed = new_seed
	_rng.seed = dataset_seed
	_generate_dataset()
	_build_point_meshes()
	run_clustering()

func _run_k_means() -> void:
	var positions: Array[Vector2] = []
	for sample in _samples:
		positions.append(sample["position"])
	if positions.is_empty():
		return
	var k = clamp(cluster_count, 1, positions.size())
	_centroids.clear()
	var chosen := {}
	while _centroids.size() < k and chosen.size() < positions.size():
		var idx := _rng.randi_range(0, positions.size() - 1)
		if chosen.has(idx):
			continue
		chosen[idx] = true
		_centroids.append(positions[idx])
	for sample in _samples:
		sample["label"] = 0
	for _i in range(kmeans_iterations):
		for sample in _samples:
			var best_dist := INF
			var best_label := 0
			var pos = sample["position"]
			for c_idx in range(_centroids.size()):
				var dist = pos.distance_squared_to(_centroids[c_idx])
				if dist < best_dist:
					best_dist = dist
					best_label = c_idx
			sample["label"] = best_label
		_update_centroid_means(k)
	_recalculate_metrics()

func _update_centroid_means(k: int) -> void:
	if _centroids.size() != k:
		_centroids.resize(k)
	var accumulators: Array[Vector2] = []
	var counts: Array[int] = []
	accumulators.resize(k)
	counts.resize(k)
	for i in range(k):
		accumulators[i] = Vector2.ZERO
		counts[i] = 0
	for sample in _samples:
		var label = clamp(sample["label"], 0, k - 1)
		accumulators[label] += sample["position"]
		counts[label] += 1
	for i in range(k):
		if counts[i] > 0:
			_centroids[i] = accumulators[i] / float(counts[i])

func _run_agglomerative() -> void:
	var points: Array[Vector2] = []
	for sample in _samples:
		points.append(sample["position"])
	if points.is_empty():
		return
	var clusters: Array = []
	for i in range(points.size()):
		clusters.append({
			"members": [i],
			"centroid": points[i],
		})
	var target = clamp(cluster_count, 1, points.size())
	while clusters.size() > target:
		var best_a := -1
		var best_b := -1
		var best_dist := INF
		for a in range(clusters.size()):
			for b in range(a + 1, clusters.size()):
				var dist := _single_link_distance(clusters[a]["members"], clusters[b]["members"], points)
				if dist < best_dist:
					best_dist = dist
					best_a = a
					best_b = b
		if best_a == -1:
			break
		var merged: Array[int] = clusters[best_a]["members"]
		merged += clusters[best_b]["members"]
		clusters[best_a] = {
			"members": merged,
			"centroid": _indices_mean(merged, points),
		}
		clusters.remove_at(best_b)
	_centroids.clear()
	for cluster_id in range(clusters.size()):
		var members: Array[int] = clusters[cluster_id]["members"]
		_centroids.append(clusters[cluster_id]["centroid"])
		for idx in members:
			_samples[idx]["label"] = cluster_id
	_recalculate_metrics()

func _single_link_distance(a_indices: Array[int], b_indices: Array[int], points: Array[Vector2]) -> float:
	var best := INF
	for ai in a_indices:
		for bi in b_indices:
			var dist := points[ai].distance_squared_to(points[bi])
			if dist < best:
				best = dist
	return sqrt(best)

func _indices_mean(indices: Array[int], points: Array[Vector2]) -> Vector2:
	if indices.is_empty():
		return Vector2.ZERO
	var accum := Vector2.ZERO
	for idx in indices:
		accum += points[idx]
	return accum / float(indices.size())

func _run_dbscan() -> void:
	var points: Array[Vector2] = []
	for sample in _samples:
		points.append(sample["position"])
	if points.is_empty():
		return
	var labels: Array[int] = []
	labels.resize(points.size())
	for i in range(labels.size()):
		labels[i] = -1
	var visited: Array[bool] = []
	visited.resize(points.size())
	for i in range(visited.size()):
		visited[i] = false
	var cluster_id := 0
	for i in range(points.size()):
		if visited[i]:
			continue
		visited[i] = true
		var neighbors := _region_query(points, i, dbscan_eps)
		if neighbors.size() < dbscan_min_points:
			labels[i] = -1
		else:
			_expand_cluster(points, labels, visited, i, neighbors, cluster_id)
			cluster_id += 1
	_centroids = _labels_to_centroids(points, labels, cluster_id)
	for i in range(_samples.size()):
		_samples[i]["label"] = labels[i]
	_recalculate_metrics()

func _expand_cluster(points: Array[Vector2], labels: Array[int], visited: Array[bool], seed: int, neighbors: Array[int], cluster_id: int) -> void:
	labels[seed] = cluster_id
	var queue := neighbors.duplicate()
	var index := 0
	while index < queue.size():
		var idx = queue[index]
		if not visited[idx]:
			visited[idx] = true
			var new_neighbors := _region_query(points, idx, dbscan_eps)
			if new_neighbors.size() >= dbscan_min_points:
				queue += new_neighbors
		if labels[idx] == -1:
			labels[idx] = cluster_id
		index += 1

func _region_query(points: Array[Vector2], index: int, eps: float) -> Array[int]:
	var result: Array[int] = []
	for i in range(points.size()):
		if points[index].distance_to(points[i]) <= eps:
			result.append(i)
	return result

func _labels_to_centroids(points: Array[Vector2], labels: Array[int], cluster_estimate: int) -> Array[Vector2]:
	var centroids: Array[Vector2] = []
	centroids.resize(cluster_estimate)
	var counts: Array[int] = []
	counts.resize(cluster_estimate)
	for i in range(cluster_estimate):
		centroids[i] = Vector2.ZERO
		counts[i] = 0
	for i in range(points.size()):
		var label := labels[i]
		if label < 0 or label >= cluster_estimate:
			continue
		centroids[label] += points[i]
		counts[label] += 1
	for i in range(cluster_estimate):
		if counts[i] > 0:
			centroids[i] /= float(counts[i])
	return centroids

func _recalculate_metrics() -> void:
	var points: Array[Vector2] = []
	for sample in _samples:
		points.append(sample["position"])
	_recalculate_dataset_radius()
	_inertia = _compute_inertia(points)
	_silhouette = _approximate_silhouette(points)

func _compute_inertia(points: Array[Vector2]) -> float:
	if points.is_empty() or _centroids.is_empty():
		return 0.0
	var total := 0.0
	var count := 0
	for i in range(points.size()):
		var label := int(_samples[i]["label"])
		if label < 0 or label >= _centroids.size():
			continue
		total += points[i].distance_squared_to(_centroids[label])
		count += 1
	return total / max(1, count)

func _approximate_silhouette(points: Array[Vector2]) -> float:
	if points.is_empty() or _centroids.is_empty():
		return 0.0
	var accum := 0.0
	var count := 0
	for i in range(points.size()):
		var label := int(_samples[i]["label"])
		if label < 0 or label >= _centroids.size():
			continue
		var a := _average_intra_distance(points, label, i)
		var b := _nearest_other_distance(points, label, i)
		var denom = max(a, b)
		if denom <= 0.0:
			continue
		accum += (b - a) / denom
		count += 1
	return accum / max(1, count)

func _average_intra_distance(points: Array[Vector2], cluster_id: int, index: int) -> float:
	var accum := 0.0
	var count := 0
	for i in range(points.size()):
		if i == index:
			continue
		if _samples[i]["label"] != cluster_id:
			continue
		accum += points[index].distance_to(points[i])
		count += 1
	return accum / max(1, count)

func _nearest_other_distance(points: Array[Vector2], cluster_id: int, index: int) -> float:
	var best := INF
	var cluster_total := _centroids.size()
	for other in range(cluster_total):
		if other == cluster_id:
			continue
		var accum := 0.0
		var count := 0
		for i in range(points.size()):
			if _samples[i]["label"] != other:
				continue
			accum += points[index].distance_to(points[i])
			count += 1
		if count > 0:
			best = min(best, accum / float(count))
	return best if best != INF else 0.0

func _apply_cluster_visuals() -> void:
	var palette_size = max(1, PALETTE.size())
	for sample in _samples:
		var mesh := sample.get("mesh") as MeshInstance3D
		var material := sample.get("material") as StandardMaterial3D
		if mesh == null or material == null:
			continue
		var label := int(sample["label"])
		var colour: Color = NOISE_COLOR if label < 0 else PALETTE[label % palette_size]
		material.albedo_color = colour
		material.emission = colour * (0.35 if label >= 0 else 0.2)
		var height: float = 0.25 if label >= 0 else 0.0
		if animate_clusters:
			mesh.position.y = lerp(mesh.position.y, height, 0.3)
		else:
			mesh.position.y = height

func _update_centroid_visuals() -> void:
	for child in centroids_root.get_children():
		child.queue_free()
	if _centroids.is_empty():
		return
	var centroid_mesh := SphereMesh.new()
	centroid_mesh.radius = POINT_RADIUS * 1.4
	for idx in range(_centroids.size()):
		var centroid := _centroids[idx]
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = centroid_mesh
		mesh_instance.position = Vector3(centroid.x, 0.15, centroid.y)
		var material := StandardMaterial3D.new()
		material.albedo_color = PALETTE[idx % max(1, PALETTE.size())].lightened(0.25)
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.6
		material.metallic = 0.1
		material.roughness = 0.25
		mesh_instance.material_override = material
		centroids_root.add_child(mesh_instance)

func _update_threshold_visual() -> void:
	if threshold_visual == null or not is_instance_valid(threshold_visual):
		return
	var radius = clamp(_max_radius + cluster_spread * 1.3, 1.0, 10.0)
	threshold_visual.visible = true
	threshold_visual.scale = Vector3(radius, 0.05, radius)
	var material := threshold_visual.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		threshold_visual.material_override = material
	var highlight := _mode_color()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(highlight.r, highlight.g, highlight.b, 0.16)
	material.emission_enabled = true
	material.emission = highlight * 0.28
	material.metallic = 0.0
	material.roughness = 0.4

func _update_labels() -> void:
	if title_label:
		title_label.text = "Clustering Algorithms Sandbox"
	if mode_label:
		mode_label.text = "[b]Algorithm:[/b] %s" % _mode_name()
	if summary_label:
		summary_label.text = "Clusters: %d\nInertia: %.3f\nSilhouette: %.3f" % [
			_effective_cluster_count(),
			_inertia,
			_silhouette,
		]

func _mode_name() -> String:
	match algorithm_mode:
		AlgorithmMode.K_MEANS:
			return "K-Means"
		AlgorithmMode.AGGLOMERATIVE:
			return "Agglomerative"
		AlgorithmMode.DBSCAN:
			return "DBSCAN"
	return "Unknown"

func _mode_color() -> Color:
	match algorithm_mode:
		AlgorithmMode.K_MEANS:
			return Color(0.3, 0.7, 1.0, 1.0)
		AlgorithmMode.AGGLOMERATIVE:
			return Color(0.6, 0.9, 0.4, 1.0)
		AlgorithmMode.DBSCAN:
			return Color(1.0, 0.55, 0.45, 1.0)
	return Color.WHITE

func _effective_cluster_count() -> int:
	var seen := {}
	for sample in _samples:
		var label := int(sample["label"])
		if label >= 0:
			seen[label] = true
	return seen.size()

func _recalculate_dataset_radius() -> void:
	if _samples.is_empty():
		_max_radius = 1.0
		return
	var centre := Vector2.ZERO
	for sample in _samples:
		centre += sample["position"]
	centre /= float(_samples.size())
	var max_dist := 0.0
	for sample in _samples:
		max_dist = max(max_dist, sample["position"].distance_to(centre))
	_max_radius = max(1.0, max_dist)

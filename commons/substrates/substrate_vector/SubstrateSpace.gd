# SubstrateSpace.gd — The query engine for 8D substrate space
#
# Holds all artifact vectors and enables similarity queries, gap analysis,
# clustering, and trajectory management.
#
# Usage:
#   var space := SubstrateSpace.new()
#   space.load_from_json("res://commons/artifacts/registry/substrate_vectors.json")
#   var neighbors := space.find_similar(my_artifact_vector, 5)
#   var gaps := space.find_gaps()

extends RefCounted
class_name SubstrateSpace

# ── Data ─────────────────────────────────────────────────────

## All registered artifact vectors: {lookup_name: SubstrateVector}
var artifacts: Dictionary = {}

## Named trajectories: {name: SubstrateTrajectory}
var trajectories: Dictionary = {}


# ── Registration ─────────────────────────────────────────────

func register(artifact_name: String, vector: SubstrateVector) -> void:
	artifacts[artifact_name] = vector


func unregister(artifact_name: String) -> void:
	artifacts.erase(artifact_name)


func has_artifact(artifact_name: String) -> bool:
	return artifacts.has(artifact_name)


func get_vector(artifact_name: String) -> SubstrateVector:
	return artifacts.get(artifact_name, SubstrateVector.zero())


func get_artifact_count() -> int:
	return artifacts.size()


func get_all_names() -> Array[String]:
	var result: Array[String] = []
	for k in artifacts:
		result.append(k)
	result.sort()
	return result


# ── Similarity Queries ───────────────────────────────────────

## Find the n most similar artifacts to a given vector.
## Returns Array of {name: String, vector: SubstrateVector, similarity: float}
func find_similar(target: SubstrateVector, n: int = 5, exclude: Array[String] = []) -> Array[Dictionary]:
	var scored: Array[Dictionary] = []
	for art_name in artifacts:
		if art_name in exclude:
			continue
		var vec: SubstrateVector = artifacts[art_name]
		var sim: float = target.overall_similarity(vec)
		scored.append({
			"name": art_name,
			"vector": vec,
			"similarity": sim,
		})

	scored.sort_custom(func(a, b): return a["similarity"] > b["similarity"])

	if scored.size() > n:
		scored.resize(n)
	return scored


## Find all artifacts where a dimension has a value above min_weight.
func find_in_region(dimension: String, value: String, min_weight: float = 0.3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for art_name in artifacts:
		var vec: SubstrateVector = artifacts[art_name]
		var w: float = vec.get_weight(dimension, value)
		if w >= min_weight:
			result.append({
				"name": art_name,
				"vector": vec,
				"weight": w,
			})
	result.sort_custom(func(a, b): return a["weight"] > b["weight"])
	return result


## Find artifacts that match ALL given dimension constraints.
## constraints: {dim_name: {value: min_weight, ...}, ...}
func find_matching(constraints: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for art_name in artifacts:
		var vec: SubstrateVector = artifacts[art_name]
		var passes := true
		for dim_name in constraints:
			for val_name in constraints[dim_name]:
				var min_w: float = constraints[dim_name][val_name]
				if vec.get_weight(dim_name, val_name) < min_w:
					passes = false
					break
			if not passes:
				break
		if passes:
			result.append({"name": art_name, "vector": vec})
	return result


# ── Gap Analysis ─────────────────────────────────────────────

## Find substrate combinations that have no artifacts.
## Checks pairs of dimensions and their values for coverage gaps.
## Returns Array of {dimension_a, value_a, dimension_b, value_b, description}
func find_gaps() -> Array[Dictionary]:
	var gaps: Array[Dictionary] = []
	var dims := SubstrateVector.DIMENSIONS
	var dim_vals := SubstrateVector.DIMENSION_VALUES

	# Check pairs of key dimensions
	var key_dims := ["algorithm", "physics", "containment", "interaction"]

	for i in key_dims.size():
		for j in range(i + 1, key_dims.size()):
			var dim_a: String = key_dims[i]
			var dim_b: String = key_dims[j]
			var vals_a: Array = dim_vals[dim_a]
			var vals_b: Array = dim_vals[dim_b]

			for va in vals_a:
				if va == "none":
					continue
				for vb in vals_b:
					if vb == "none":
						continue
					# Check if any artifact has both
					var found := false
					for art_name in artifacts:
						var vec: SubstrateVector = artifacts[art_name]
						if vec.get_weight(dim_a, va) >= 0.3 and vec.get_weight(dim_b, vb) >= 0.3:
							found = true
							break
					if not found:
						gaps.append({
							"dimension_a": dim_a,
							"value_a": va,
							"dimension_b": dim_b,
							"value_b": vb,
							"description": "No artifact with %s=%s AND %s=%s" % [dim_a, va, dim_b, vb],
						})

	return gaps


# ── Histograms ───────────────────────────────────────────────

## Count artifacts per value for a given dimension.
## Returns {value_name: count}
func get_dimension_histogram(dimension: String) -> Dictionary:
	var hist := {}
	var vals: Array = SubstrateVector.DIMENSION_VALUES.get(dimension, [])
	for v in vals:
		hist[v] = 0

	for art_name in artifacts:
		var vec: SubstrateVector = artifacts[art_name]
		var dim: Dictionary = vec.get_dimension(dimension)
		for v in dim:
			if dim[v] >= 0.3:  # threshold for counting
				hist[v] = hist.get(v, 0) + 1

	return hist


# ── Clustering ───────────────────────────────────────────────

## Simple k-means-style clustering of artifacts by substrate similarity.
## Returns Array of Arrays (each inner array is a list of artifact names).
func cluster(n_clusters: int = 5) -> Array[Array]:
	var names := get_all_names()
	if names.is_empty():
		return []

	# Initialize centroids from first n distinct artifacts
	var centroids: Array[SubstrateVector] = []
	var step := maxi(1, names.size() / n_clusters)
	for i in n_clusters:
		var idx := mini(i * step, names.size() - 1)
		centroids.append(artifacts[names[idx]])

	var assignments: Array[int] = []
	assignments.resize(names.size())

	# Run k-means for a few iterations
	for _iter in 10:
		# Assign each artifact to nearest centroid
		for i in names.size():
			var vec: SubstrateVector = artifacts[names[i]]
			var best_cluster := 0
			var best_sim := -1.0
			for c in centroids.size():
				var sim := vec.cosine_similarity(centroids[c])
				if sim > best_sim:
					best_sim = sim
					best_cluster = c
			assignments[i] = best_cluster

		# Recompute centroids as blend of all members
		for c in centroids.size():
			var members: Array[SubstrateVector] = []
			for i in names.size():
				if assignments[i] == c:
					members.append(artifacts[names[i]])
			if members.is_empty():
				continue
			var sum_vec := members[0]
			for m in range(1, members.size()):
				sum_vec = sum_vec.add(members[m])
			centroids[c] = sum_vec.scale(1.0 / float(members.size()))

	# Build result
	var clusters: Array[Array] = []
	for c in n_clusters:
		var group: Array = []
		for i in names.size():
			if assignments[i] == c:
				group.append(names[i])
		if not group.is_empty():
			clusters.append(group)

	return clusters


# ── Trajectories ─────────────────────────────────────────────

func register_trajectory(trajectory: SubstrateTrajectory) -> void:
	trajectories[trajectory.name] = trajectory


func get_trajectory(trajectory_name: String) -> SubstrateTrajectory:
	return trajectories.get(trajectory_name, null)


func get_trajectory_names() -> Array[String]:
	var result: Array[String] = []
	for k in trajectories:
		result.append(k)
	result.sort()
	return result


## Build pre-defined trajectories from the theory document.
## Call AFTER loading artifact vectors.
func build_predefined_trajectories() -> void:
	_build_trajectory(
		"specimen_in_jar",
		"Increasing agency inside a container",
		["dna_specimen", "random_walk_terrarium", "queer_morphology_specimen", "boids_aquarium"]
	)

	_build_trajectory(
		"cube_freedom",
		"Rigidity dissolving — a cube gaining degrees of freedom",
		["static_reference_cube", "rotating_cube_demo", "oscillation_controlled_cube", "jelly_cube", "queer_morphology_specimen"]
	)

	_build_trajectory(
		"vector_to_terrain",
		"Point data → field data → surface data",
		["vector_addition_demo", "flow_field_painter", "wave_interference_tank"]
	)

	_build_trajectory(
		"grid_to_world",
		"The algorithm escapes its container — grid becomes ground",
		["game_of_life_petri", "ca_rule_explorer"]
	)

	_build_trajectory(
		"math_to_walkgrid",
		"Artifact becomes terrain — the math object becomes the world you walk in",
		["mandelbrot_dive", "mandelbrot_space"]
	)

	_build_trajectory(
		"observation_collapses",
		"The act of looking determines what it is — interaction entangled with algorithm",
		["superposition_display", "schrodinger_box", "queer_morphology_specimen", "brouwer_choice_sequence"]
	)


func _build_trajectory(traj_name: String, desc: String, waypoint_names: Array) -> void:
	var traj := SubstrateTrajectory.new()
	traj.name = traj_name
	traj.description = desc

	for wp_name in waypoint_names:
		var vec: SubstrateVector
		if artifacts.has(wp_name):
			vec = artifacts[wp_name]
		else:
			# Create a placeholder zero vector for missing artifacts
			vec = SubstrateVector.zero()
		traj.add_waypoint(wp_name, vec)

	trajectories[traj_name] = traj


# ── Loading ──────────────────────────────────────────────────

## Load substrate vectors from a JSON file.
## Expected format: { "artifact_name": { "geometry": {...}, "physics": {...}, ... }, ... }
func load_from_json(path: String) -> int:
	if not FileAccess.file_exists(path):
		push_warning("SubstrateSpace: file not found: %s" % path)
		return 0

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("SubstrateSpace: cannot open: %s" % path)
		return 0

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("SubstrateSpace: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return 0

	var data: Dictionary = json.data
	var count := 0
	for art_name in data:
		if data[art_name] is Dictionary:
			var vec := SubstrateVector.from_dict(data[art_name])
			register(art_name, vec)
			count += 1

	return count


## Save all vectors to a JSON file.
func save_to_json(path: String) -> bool:
	var data := {}
	for art_name in artifacts:
		data[art_name] = artifacts[art_name].to_dict()

	var text := JSON.stringify(data, "  ")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SubstrateSpace: cannot write: %s" % path)
		return false

	file.store_string(text)
	file.close()
	return true


## Load vectors AND build trajectories (convenience method).
func initialize(json_path: String) -> int:
	var count := load_from_json(json_path)
	if count > 0:
		build_predefined_trajectories()
	return count


# ── Statistics ───────────────────────────────────────────────

## Overall substrate space statistics.
func get_statistics() -> Dictionary:
	var stats := {
		"total_artifacts": artifacts.size(),
		"total_trajectories": trajectories.size(),
		"dimension_coverage": {},
	}

	for dim_name in SubstrateVector.DIMENSIONS:
		var hist := get_dimension_histogram(dim_name)
		var used := 0
		var total := 0
		for v in hist:
			total += 1
			if hist[v] > 0:
				used += 1
		stats["dimension_coverage"][dim_name] = {
			"used_values": used,
			"total_values": total,
			"coverage": float(used) / float(total) if total > 0 else 0.0,
		}

	return stats

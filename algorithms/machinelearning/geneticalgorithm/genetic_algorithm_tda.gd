# genetic_algorithm_tda.gd
# Topological Data Analysis & Queer Forms Detection helpers for the Genetic Algorithm.
# Extracted from genetic_algorithm.gd to reduce file size.
#
# Contains:
#   - GAPersistentHomology: Persistent homology computation
#   - GAMapperAlgorithm: Mapper graph construction
#   - GAQueerFormsDetector: Population analysis for non-normative patterns
#   - GAEntropyCalculator: Shannon entropy measurement

extends RefCounted
class_name GeneticAlgorithmTDA


# Persistent Homology class for detecting topological features
class GAPersistentHomology:
	var dimension: int = 2
	var max_filtration_value: float = 10.0
	var resolution: float = 0.1

	func _init(dim: int = 2, max_filt: float = 10.0) -> void:
		dimension = dim
		max_filtration_value = max_filt

	func compute_persistent_homology(point_cloud: Array) -> Dictionary:
		## Compute persistent homology of a point cloud
		var persistence_pairs = []
		var betti_numbers = []

		# Create filtration (simplified Vietoris-Rips complex)
		var filtration_values = []
		for i in range(int(max_filtration_value / resolution)):
			filtration_values.append(i * resolution)

		# Track connected components (H0) and loops (H1)
		var previous_components = 0
		var previous_loops = 0

		for filt_value in filtration_values:
			var components = count_connected_components(point_cloud, filt_value)
			var loops = count_loops(point_cloud, filt_value)

			# Detect birth and death of topological features
			if components != previous_components:
				persistence_pairs.append({
					"dimension": 0,
					"birth": filt_value,
					"death": -1,  # Still alive
					"feature_type": "component"
				})

			if loops != previous_loops:
				persistence_pairs.append({
					"dimension": 1,
					"birth": filt_value,
					"death": -1,  # Still alive
					"feature_type": "loop"
				})

			betti_numbers.append({"H0": components, "H1": loops})
			previous_components = components
			previous_loops = loops

		return {
			"persistence_pairs": persistence_pairs,
			"betti_numbers": betti_numbers,
			"filtration_values": filtration_values
		}

	func count_connected_components(points: Array, threshold: float) -> int:
		## Count connected components at given threshold
		var components = 0
		var visited = []

		for i in range(points.size()):
			visited.append(false)

		for i in range(points.size()):
			if not visited[i]:
				components += 1
				dfs_component(points, i, threshold, visited)

		return components

	func dfs_component(points: Array, start: int, threshold: float, visited: Array) -> void:
		## Depth-first search for connected components
		visited[start] = true

		for i in range(points.size()):
			if not visited[i]:
				var distance = points[start].distance_to(points[i])
				if distance <= threshold:
					dfs_component(points, i, threshold, visited)

	func count_loops(points: Array, threshold: float) -> int:
		## Estimate number of loops (simplified)
		var edges = 0
		var vertices = points.size()

		# Count edges in the graph
		for i in range(points.size()):
			for j in range(i + 1, points.size()):
				var distance = points[i].distance_to(points[j])
				if distance <= threshold:
					edges += 1

		# Euler characteristic approximation: loops ~ edges - vertices + components
		var components = count_connected_components(points, threshold)
		return max(0, edges - vertices + components)

	func detect_queer_topology(persistence_data: Dictionary) -> float:
		## Detect non-normative topological features
		var queer_score = 0.0
		var persistence_pairs = persistence_data.persistence_pairs

		# Look for unusual topological features
		for pair in persistence_pairs:
			var persistence = pair.get("death", max_filtration_value) - pair.birth

			# Reward long-lived features (non-standard)
			if persistence > max_filtration_value * 0.3:
				queer_score += 0.5

			# Reward higher-dimensional features
			if pair.dimension > 0:
				queer_score += 0.3

		# Normalize score
		return clamp(queer_score / max(1, persistence_pairs.size()), 0.0, 1.0)


# Mapper Algorithm class for data visualization
class GAMapperAlgorithm:
	var filter_function: String = "distance_to_center"
	var num_intervals: int = 10
	var overlap_percent: float = 0.3
	var clustering_method: String = "single_linkage"

	func _init(filter_func: String = "distance_to_center", intervals: int = 10) -> void:
		filter_function = filter_func
		num_intervals = intervals

	func compute_mapper_graph(data_points: Array, metadata: Array = []) -> Dictionary:
		## Compute Mapper graph from data points
		# Step 1: Apply filter function
		var filter_values = []
		for point in data_points:
			filter_values.append(apply_filter_function(point, data_points))

		# Step 2: Create overlapping intervals
		var min_filter = filter_values.min()
		var max_filter = filter_values.max()
		var interval_size = (max_filter - min_filter) / num_intervals
		var overlap_size = interval_size * overlap_percent

		var intervals = []
		for i in range(num_intervals):
			var start = min_filter + i * interval_size - overlap_size
			var end = min_filter + (i + 1) * interval_size + overlap_size
			intervals.append({"start": start, "end": end, "index": i})

		# Step 3: Cluster points in each interval
		var nodes = []
		var node_id = 0

		for interval in intervals:
			var points_in_interval = []
			var indices_in_interval = []

			for i in range(data_points.size()):
				if filter_values[i] >= interval.start and filter_values[i] <= interval.end:
					points_in_interval.append(data_points[i])
					indices_in_interval.append(i)

			if points_in_interval.size() > 0:
				var clusters = cluster_points(points_in_interval)

				for cluster in clusters:
					var node = {
						"id": node_id,
						"interval": interval.index,
						"points": cluster,
						"indices": indices_in_interval,
						"center": calculate_cluster_center(cluster),
						"size": cluster.size()
					}
					nodes.append(node)
					node_id += 1

		# Step 4: Create edges between overlapping nodes
		var edges = []
		for i in range(nodes.size()):
			for j in range(i + 1, nodes.size()):
				if nodes_overlap(nodes[i], nodes[j]):
					edges.append({
						"source": nodes[i].id,
						"target": nodes[j].id,
						"weight": calculate_edge_weight(nodes[i], nodes[j])
					})

		return {
			"nodes": nodes,
			"edges": edges,
			"filter_values": filter_values,
			"intervals": intervals
		}

	func apply_filter_function(point: Vector3, all_points: Array) -> float:
		## Apply filter function to a point
		match filter_function:
			"distance_to_center":
				return point.distance_to(Vector3.ZERO)
			"density":
				return calculate_local_density(point, all_points)
			"eccentricity":
				return calculate_eccentricity(point, all_points)
			"queer_divergence":
				return calculate_queer_divergence(point, all_points)
			_:
				return point.distance_to(Vector3.ZERO)

	func calculate_local_density(point: Vector3, all_points: Array, radius: float = 2.0) -> float:
		## Calculate local density around a point
		var count = 0
		for p in all_points:
			if point.distance_to(p) <= radius:
				count += 1
		return float(count) / all_points.size()

	func calculate_eccentricity(point: Vector3, all_points: Array) -> float:
		## Calculate eccentricity (average distance to all other points)
		var total_distance = 0.0
		for p in all_points:
			total_distance += point.distance_to(p)
		return total_distance / all_points.size()

	func calculate_queer_divergence(point: Vector3, all_points: Array) -> float:
		## Calculate divergence from normative patterns
		var center = Vector3.ZERO
		for p in all_points:
			center += p
		center /= all_points.size()

		# Distance from population center
		var distance_from_center = point.distance_to(center)

		# Variance in local neighborhood
		var local_variance = 0.0
		var neighbors = []
		for p in all_points:
			if point.distance_to(p) <= 3.0:
				neighbors.append(p)

		if neighbors.size() > 1:
			var local_center = Vector3.ZERO
			for n in neighbors:
				local_center += n
			local_center /= neighbors.size()

			for n in neighbors:
				local_variance += local_center.distance_squared_to(n)
			local_variance /= neighbors.size()

		# Combine measures: high divergence = far from center + high local variance
		return distance_from_center * 0.7 + local_variance * 0.3

	func cluster_points(points: Array) -> Array:
		## Cluster points using simple single linkage
		if points.size() <= 1:
			return [points]

		var clusters = []
		var used = []

		for i in range(points.size()):
			used.append(false)

		for i in range(points.size()):
			if not used[i]:
				var cluster = [points[i]]
				used[i] = true

				# Find nearby points
				for j in range(points.size()):
					if not used[j] and points[i].distance_to(points[j]) <= 2.0:
						cluster.append(points[j])
						used[j] = true

				clusters.append(cluster)

		return clusters

	func calculate_cluster_center(cluster: Array) -> Vector3:
		## Calculate center of a cluster
		var center = Vector3.ZERO
		for point in cluster:
			center += point
		return center / cluster.size()

	func nodes_overlap(node1: Dictionary, node2: Dictionary) -> bool:
		## Check if two nodes have overlapping points
		for idx1 in node1.indices:
			for idx2 in node2.indices:
				if idx1 == idx2:
					return true
		return false

	func calculate_edge_weight(node1: Dictionary, node2: Dictionary) -> float:
		## Calculate weight of edge between nodes
		var overlap_count = 0
		for idx1 in node1.indices:
			for idx2 in node2.indices:
				if idx1 == idx2:
					overlap_count += 1

		return float(overlap_count) / min(node1.size, node2.size)

	func detect_queer_patterns(mapper_graph: Dictionary) -> Dictionary:
		## Detect non-normative patterns in the mapper graph
		var nodes = mapper_graph.nodes
		var edges = mapper_graph.edges

		var queer_patterns = {
			"isolated_nodes": [],
			"high_degree_nodes": [],
			"unusual_clusters": [],
			"bridge_nodes": []
		}

		# Calculate node degrees
		var node_degrees = {}
		for node in nodes:
			node_degrees[node.id] = 0

		for edge in edges:
			node_degrees[edge.source] += 1
			node_degrees[edge.target] += 1

		# Identify patterns
		for node in nodes:
			var degree = node_degrees[node.id]

			# Isolated nodes (potential outliers)
			if degree == 0:
				queer_patterns.isolated_nodes.append(node)

			# High-degree nodes (hubs)
			elif degree > 3:
				queer_patterns.high_degree_nodes.append(node)

			# Unusual cluster sizes
			if node.size > 10 or node.size == 1:
				queer_patterns.unusual_clusters.append(node)

		return queer_patterns


# Queer Forms Detector - integrates TDA with evolutionary patterns
class GAQueerFormsDetector:
	var persistent_homology: GAPersistentHomology
	var mapper_algorithm: GAMapperAlgorithm
	var entropy_calculator: GAEntropyCalculator

	func _init() -> void:
		persistent_homology = GAPersistentHomology.new(2, 15.0)
		mapper_algorithm = GAMapperAlgorithm.new("queer_divergence", 12)
		entropy_calculator = GAEntropyCalculator.new()

	func analyze_population(population: Array) -> Dictionary:
		## Comprehensive analysis of population for queer forms
		var positions = []
		var genetic_vectors = []
		var behavioral_vectors = []

		# Extract data for analysis
		for creature in population:
			positions.append(creature.position)
			genetic_vectors.append(encode_genetic_vector(creature.genes))
			behavioral_vectors.append(encode_behavioral_vector(creature))

		# Topological analysis
		var tda_results = persistent_homology.compute_persistent_homology(positions)
		var topological_queerness = persistent_homology.detect_queer_topology(tda_results)

		# Mapper analysis
		var mapper_results = mapper_algorithm.compute_mapper_graph(positions, genetic_vectors)
		var pattern_queerness = mapper_algorithm.detect_queer_patterns(mapper_results)

		# Entropy analysis
		var genetic_entropy = entropy_calculator.calculate_genetic_entropy(genetic_vectors)
		var behavioral_entropy = entropy_calculator.calculate_behavioral_entropy(behavioral_vectors)

		return {
			"topological_analysis": tda_results,
			"topological_queerness": topological_queerness,
			"mapper_analysis": mapper_results,
			"pattern_queerness": pattern_queerness,
			"genetic_entropy": genetic_entropy,
			"behavioral_entropy": behavioral_entropy,
			"overall_queerness": calculate_overall_queerness(topological_queerness, pattern_queerness, genetic_entropy, behavioral_entropy)
		}

	func encode_genetic_vector(genes: Dictionary) -> Array:
		## Encode genetic traits as vector
		return [
			genes.get("size", 0.5),
			genes.get("speed", 0.5),
			genes.get("aggression", 0.5),
			genes.get("exploration", 0.5),
			genes.get("social_tendency", 0.5),
			genes.get("red", 0.5),
			genes.get("green", 0.5),
			genes.get("blue", 0.5)
		]

	func encode_behavioral_vector(creature) -> Array:
		## Encode behavioral traits as vector
		return [
			creature.energy / 100.0,
			creature.age / 60.0,
			creature.fitness / 100.0,
			creature.velocity.length() / 5.0,
			creature.social_connections.size() / 10.0
		]

	func calculate_overall_queerness(topo_q: float, pattern_q: float, genetic_e: float, behavioral_e: float) -> float:
		## Calculate overall queerness score
		# Weight different measures
		var weights = [0.3, 0.25, 0.25, 0.2]  # topology, patterns, genetic entropy, behavioral entropy
		var values = [topo_q, pattern_q, genetic_e, behavioral_e]

		var weighted_sum = 0.0
		for i in range(weights.size()):
			weighted_sum += weights[i] * values[i]

		return clamp(weighted_sum, 0.0, 1.0)


# Entropy Calculator for measuring system complexity
class GAEntropyCalculator:
	func calculate_genetic_entropy(genetic_vectors: Array) -> float:
		## Calculate entropy of genetic diversity
		if genetic_vectors.is_empty():
			return 0.0

		var dimensions = genetic_vectors[0].size()
		var total_entropy = 0.0

		for dim in range(dimensions):
			var values = []
			for vector in genetic_vectors:
				values.append(vector[dim])

			total_entropy += calculate_shannon_entropy(values)

		return total_entropy / dimensions

	func calculate_behavioral_entropy(behavioral_vectors: Array) -> float:
		## Calculate entropy of behavioral diversity
		if behavioral_vectors.is_empty():
			return 0.0

		var dimensions = behavioral_vectors[0].size()
		var total_entropy = 0.0

		for dim in range(dimensions):
			var values = []
			for vector in behavioral_vectors:
				values.append(vector[dim])

			total_entropy += calculate_shannon_entropy(values)

		return total_entropy / dimensions

	func calculate_shannon_entropy(values: Array) -> float:
		## Calculate Shannon entropy of a value array
		var bins = 10
		var min_val = values.min()
		var max_val = values.max()
		var bin_size = (max_val - min_val) / bins

		if bin_size == 0:
			return 0.0

		var bin_counts = []
		for i in range(bins):
			bin_counts.append(0)

		# Count values in each bin
		for value in values:
			var bin_index = int((value - min_val) / bin_size)
			bin_index = clamp(bin_index, 0, bins - 1)
			bin_counts[bin_index] += 1

		# Calculate entropy
		var entropy = 0.0
		var total = values.size()

		for count in bin_counts:
			if count > 0:
				var probability = float(count) / total
				entropy -= probability * log(probability)

		return entropy / log(bins)  # Normalize to [0,1]

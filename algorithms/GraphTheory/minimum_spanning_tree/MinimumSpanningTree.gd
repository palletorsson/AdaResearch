extends Node3D
class_name MinimumSpanningTree

var time: float = 0.0
var algorithm_progress: float = 0.0
var total_weight: float = 0.0
var construction_progress: float = 0.0
var node_count: int = 12
var edge_count: int = 20
var flow_particles: Array = []
var graph_nodes: Array = []
var candidate_edges: Array = []
var mst_edges: Array = []
var weight_indicators: Array = []

func _ready():
	# Initialize MST visualization
	print("Minimum Spanning Tree Visualization initialized")
	create_graph_nodes()
	create_candidate_edges()
	create_weight_indicators()
	create_flow_particles()
	setup_mst_metrics()

func _process(delta):
	time += delta
	
	# Simulate algorithm progress
	algorithm_progress = min(1.0, time * 0.1)
	construction_progress = algorithm_progress
	total_weight = algorithm_progress * 15.0  # Arbitrary weight scale
	
	animate_graph_nodes(delta)
	animate_candidate_edges(delta)
	animate_mst_construction(delta)
	animate_algorithm_engine(delta)
	animate_weight_comparison(delta)
	animate_data_flow(delta)
	update_mst_metrics(delta)

func create_graph_nodes():
	# Create graph vertices
	var vertices_node = $GraphNodes/Vertices
	for i in range(node_count):
		var vertex = CSGSphere3D.new()
		vertex.radius = 0.2
		vertex.material_override = StandardMaterial3D.new()
		vertex.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		vertex.material_override.emission_enabled = true
		vertex.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.4
		
		# Position vertices in a roughly circular pattern with some randomness
		var angle = float(i) / node_count * PI * 2
		var radius = 3.0 + randf() * 1.5
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = randf_range(-0.5, 0.5)
		vertex.position = Vector3(x, y, z)
		
		vertices_node.add_child(vertex)
		graph_nodes.append({"vertex": vertex, "visited": false, "in_mst": false})

func create_candidate_edges():
	# Create all possible edges with weights
	var candidate_edges_node = $AllEdges/CandidateEdges
	for i in range(edge_count):
		var edge = CSGBox3D.new()
		edge.size = Vector3(0.08, 0.08, 1.0)
		edge.material_override = StandardMaterial3D.new()
		edge.material_override.albedo_color = Color(0.6, 0.6, 0.6, 0.5)
		edge.material_override.emission_enabled = true
		edge.material_override.emission = Color(0.6, 0.6, 0.6, 1) * 0.2
		edge.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Connect random pairs of vertices
		var node1_idx = randi() % graph_nodes.size()
		var node2_idx = randi() % graph_nodes.size()
		while node2_idx == node1_idx:
			node2_idx = randi() % graph_nodes.size()
		
		var node1_pos = graph_nodes[node1_idx]["vertex"].position
		var node2_pos = graph_nodes[node2_idx]["vertex"].position
		var weight = node1_pos.distance_to(node2_pos) + randf() * 2.0
		
		# Position and orient edge
		var center = (node1_pos + node2_pos) * 0.5
		var direction = node2_pos - node1_pos
		var length = direction.length()
		
		edge.position = center
		edge.scale.z = length
		edge.look_at(node2_pos, Vector3.UP)
		
		candidate_edges_node.add_child(edge)
		candidate_edges.append({
			"edge": edge,
			"node1": node1_idx,
			"node2": node2_idx,
			"weight": weight,
			"selected": false,
			"considered": false
		})
	
	# Sort edges by weight for Kruskal's algorithm simulation
	candidate_edges.sort_custom(func(a, b): return a["weight"] < b["weight"])

func create_weight_indicators():
	# Create weight comparison indicators
	var weight_indicators_node = $WeightComparison/WeightIndicators
	for i in range(5):
		var indicator = CSGSphere3D.new()
		indicator.radius = 0.1
		indicator.material_override = StandardMaterial3D.new()
		indicator.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		indicator.material_override.emission_enabled = true
		indicator.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position indicators vertically
		var y = (i - 2) * 0.8
		indicator.position = Vector3(0, y, 0)
		
		weight_indicators_node.add_child(indicator)
		weight_indicators.append(indicator)

func create_flow_particles():
	# Create algorithm flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(25):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the algorithm flow path
		var progress = float(i) / 25
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 4) * 2.0
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_mst_metrics():
	# Initialize MST metrics
	var weight_indicator = $MSTMetrics/TotalWeightMeter/WeightIndicator
	var progress_indicator = $MSTMetrics/ProgressMeter/ProgressIndicator
	if weight_indicator:
		weight_indicator.position.x = -2  # Start low
	if progress_indicator:
		progress_indicator.position.x = -2  # Start at beginning

func animate_graph_nodes(delta):
	# Animate graph vertices
	for i in range(graph_nodes.size()):
		var node_data = graph_nodes[i]
		var vertex = node_data["vertex"]
		
		if vertex:
			# Slight oscillation
			var base_pos = vertex.position
			var move_x = base_pos.x + sin(time * 0.8 + i * 0.15) * 0.1
			var move_y = base_pos.y + cos(time * 1.0 + i * 0.2) * 0.1
			var move_z = base_pos.z + sin(time * 1.2 + i * 0.1) * 0.05
			
			vertex.position.x = lerp(vertex.position.x, move_x, delta * 1.5)
			vertex.position.y = lerp(vertex.position.y, move_y, delta * 1.5)
			vertex.position.z = lerp(vertex.position.z, move_z, delta * 1.5)
			
			# Pulse based on MST inclusion
			var pulse = 1.0
			if node_data["in_mst"]:
				pulse = 1.0 + sin(time * 3.0 + i * 0.3) * 0.3 * algorithm_progress
			else:
				pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.1 * algorithm_progress
			vertex.scale = Vector3.ONE * pulse
			
			# Change color based on MST status
			if node_data["in_mst"]:
				vertex.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
				vertex.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.6
			elif node_data["visited"]:
				vertex.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
				vertex.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.4
			else:
				vertex.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
				vertex.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.4

func animate_candidate_edges(delta):
	# Animate candidate edges
	for i in range(candidate_edges.size()):
		var edge_data = candidate_edges[i]
		var edge = edge_data["edge"]
		
		if edge:
			# Update edge position based on connected vertices
			var node1_pos = graph_nodes[edge_data["node1"]]["vertex"].position
			var node2_pos = graph_nodes[edge_data["node2"]]["vertex"].position
			
			var center = (node1_pos + node2_pos) * 0.5
			var direction = node2_pos - node1_pos
			var length = direction.length()
			
			edge.position = lerp(edge.position, center, delta * 2.0)
			edge.scale.z = lerp(edge.scale.z, length, delta * 2.0)
			if direction.length() > 0.001:
				edge.look_at(node2_pos, Vector3.UP)
			
			# Animate based on consideration/selection status
			var consideration_progress = min(1.0, max(0.0, algorithm_progress * candidate_edges.size() - i))
			
			if edge_data["selected"]:
				# Selected for MST - bright green
				edge.material_override.albedo_color = Color(0.2, 0.8, 0.2, 0.8)
				edge.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.6
				var pulse = 1.0 + sin(time * 3.0 + i * 0.2) * 0.3
				edge.scale.x = pulse * 0.08
				edge.scale.y = pulse * 0.08
			elif edge_data["considered"]:
				# Considered but not selected - red
				edge.material_override.albedo_color = Color(0.8, 0.2, 0.2, 0.6)
				edge.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.3
			elif consideration_progress > 0.0:
				# Currently being considered - yellow
				edge.material_override.albedo_color = Color(0.8, 0.8, 0.2, 0.7)
				edge.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.4 * consideration_progress
				var pulse = 1.0 + consideration_progress * 0.2
				edge.scale.x = pulse * 0.08
				edge.scale.y = pulse * 0.08
			else:
				# Default candidate edge
				edge.material_override.albedo_color = Color(0.6, 0.6, 0.6, 0.5)
				edge.material_override.emission = Color(0.6, 0.6, 0.6, 1) * 0.2

func animate_mst_construction(delta):
	# Simulate MST construction (simplified Kruskal's algorithm)
	var edges_to_consider = int(algorithm_progress * candidate_edges.size())
	var mst_edge_count = 0
	
	for i in range(min(edges_to_consider, candidate_edges.size())):
		var edge_data = candidate_edges[i]
		edge_data["considered"] = true
		
		# Simple check - if we haven't selected too many edges, select this one
		if mst_edge_count < graph_nodes.size() - 1:
			edge_data["selected"] = true
			graph_nodes[edge_data["node1"]]["in_mst"] = true
			graph_nodes[edge_data["node2"]]["in_mst"] = true
			mst_edge_count += 1

func animate_algorithm_engine(delta):
	# Animate algorithm engine core
	var engine_core = $AlgorithmEngine/EngineCore
	if engine_core:
		# Rotate engine
		engine_core.rotation.y += delta * 0.5
		
		# Pulse based on algorithm progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * algorithm_progress
		engine_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on progress
		if engine_core.material_override:
			var intensity = 0.3 + algorithm_progress * 0.7
			engine_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate algorithm method cores
	var kruskal_core = $AlgorithmEngine/AlgorithmMethods/KruskalCore
	if kruskal_core:
		kruskal_core.rotation.y += delta * 0.8
		var kruskal_activation = sin(time * 1.5) * 0.5 + 0.5
		kruskal_activation *= algorithm_progress
		
		var pulse = 1.0 + kruskal_activation * 0.3
		kruskal_core.scale = Vector3.ONE * pulse
		
		if kruskal_core.material_override:
			var intensity = 0.3 + kruskal_activation * 0.7
			kruskal_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var prim_core = $AlgorithmEngine/AlgorithmMethods/PrimCore
	if prim_core:
		prim_core.rotation.y += delta * 1.0
		var prim_activation = cos(time * 1.8) * 0.5 + 0.5
		prim_activation *= algorithm_progress
		
		var pulse = 1.0 + prim_activation * 0.3
		prim_core.scale = Vector3.ONE * pulse
		
		if prim_core.material_override:
			var intensity = 0.3 + prim_activation * 0.7
			prim_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_weight_comparison(delta):
	# Animate weight comparison core
	var comparison_core = $WeightComparison/ComparisonCore
	if comparison_core:
		# Rotate comparison engine
		comparison_core.rotation.y += delta * 0.3
		
		# Pulse based on algorithm progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * algorithm_progress
		comparison_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity
		if comparison_core.material_override:
			var intensity = 0.3 + algorithm_progress * 0.7
			comparison_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate weight indicators
	for i in range(weight_indicators.size()):
		var indicator = weight_indicators[i]
		if indicator:
			# Pulse indicators based on weight comparison activity
			var comparison_activity = sin(time * 2.0 + i * 0.5) * 0.5 + 0.5
			comparison_activity *= algorithm_progress
			
			var pulse = 1.0 + comparison_activity * 0.4
			indicator.scale = Vector3.ONE * pulse
			
			# Change color based on weight range
			var weight_level = float(i) / 4.0
			var red_component = 0.8 * weight_level
			var green_component = 0.8 * (1.0 - weight_level)
			indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the algorithm flow
			var progress = (time * 0.25 + float(i) * 0.08) % 1.0
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 4) * 2.0
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and algorithm progress
			var color_progress = (progress + 0.5) % 1.0
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on algorithm
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * algorithm_progress
			particle.scale = Vector3.ONE * pulse

func update_mst_metrics(delta):
	# Update total weight meter
	var weight_indicator = $MSTMetrics/TotalWeightMeter/WeightIndicator
	if weight_indicator:
		var normalized_weight = total_weight / 20.0  # Normalize to 0-1
		var target_x = lerp(-2, 2, normalized_weight)
		weight_indicator.position.x = lerp(weight_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on weight (lower is better - green, higher is red)
		var green_component = 0.8 * (1.0 - normalized_weight)
		var red_component = 0.2 + 0.6 * normalized_weight
		weight_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update construction progress meter
	var progress_indicator = $MSTMetrics/ProgressMeter/ProgressIndicator
	if progress_indicator:
		var target_x = lerp(-2, 2, construction_progress)
		progress_indicator.position.x = lerp(progress_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on progress
		var green_component = 0.8 * construction_progress
		var red_component = 0.2 + 0.6 * (1.0 - construction_progress)
		progress_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_algorithm_progress(progress: float):
	algorithm_progress = clamp(progress, 0.0, 1.0)

func set_total_weight(weight: float):
	total_weight = weight

func set_construction_progress(progress: float):
	construction_progress = clamp(progress, 0.0, 1.0)

func get_algorithm_progress() -> float:
	return algorithm_progress

func get_total_weight() -> float:
	return total_weight

func get_construction_progress() -> float:
	return construction_progress

func reset_algorithm():
	time = 0.0
	algorithm_progress = 0.0
	total_weight = 0.0
	construction_progress = 0.0
	
	# Reset edge and node states
	for edge_data in candidate_edges:
		edge_data["selected"] = false
		edge_data["considered"] = false
	
	for node_data in graph_nodes:
		node_data["visited"] = false
		node_data["in_mst"] = false

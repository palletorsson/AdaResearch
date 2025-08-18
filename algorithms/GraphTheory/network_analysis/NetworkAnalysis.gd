extends Node3D
class_name NetworkAnalysis

var time: float = 0.0
var analysis_progress: float = 0.0
var clustering_coefficient: float = 0.0
var connectivity_index: float = 0.0
var node_count: int = 25
var edge_count: int = 40
var flow_particles: Array = []
var network_nodes: Array = []
var network_edges: Array = []
var communities: Array = []

func _ready():
	# Initialize Network Analysis visualization
	print("Network Analysis Visualization initialized")
	create_network_nodes()
	create_network_edges()
	create_communities()
	create_flow_particles()
	setup_network_metrics()

func _process(delta):
	time += delta
	
	# Simulate analysis progress
	analysis_progress = min(1.0, time * 0.1)
	clustering_coefficient = analysis_progress * 0.8
	connectivity_index = analysis_progress * 0.75
	
	animate_network_nodes(delta)
	animate_network_edges(delta)
	animate_analysis_engine(delta)
	animate_community_detection(delta)
	animate_data_flow(delta)
	update_network_metrics(delta)

func create_network_nodes():
	# Create central nodes (high centrality)
	var central_nodes = $NetworkNodes/CentralNodes
	for i in range(5):
		var node = CSGSphere3D.new()
		node.radius = 0.15
		node.material_override = StandardMaterial3D.new()
		node.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
		node.material_override.emission_enabled = true
		node.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.5
		
		# Position central nodes in inner circle
		var angle = float(i) / 5.0 * PI * 2
		var radius = 1.5
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = randf_range(-0.3, 0.3)
		node.position = Vector3(x, y, z)
		
		central_nodes.add_child(node)
		network_nodes.append({"node": node, "type": "central", "centrality": 0.8 + randf() * 0.2})
	
	# Create peripheral nodes (low centrality)
	var peripheral_nodes = $NetworkNodes/PeripheralNodes
	for i in range(15):
		var node = CSGSphere3D.new()
		node.radius = 0.08
		node.material_override = StandardMaterial3D.new()
		node.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
		node.material_override.emission_enabled = true
		node.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
		
		# Position peripheral nodes in outer circle
		var angle = float(i) / 15.0 * PI * 2
		var radius = 3.0 + randf() * 1.0
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = randf_range(-0.5, 0.5)
		node.position = Vector3(x, y, z)
		
		peripheral_nodes.add_child(node)
		network_nodes.append({"node": node, "type": "peripheral", "centrality": randf() * 0.3})
	
	# Create cluster nodes (intermediate centrality)
	var cluster_nodes = $NetworkNodes/ClusterNodes
	for i in range(5):
		var node = CSGSphere3D.new()
		node.radius = 0.12
		node.material_override = StandardMaterial3D.new()
		node.material_override.albedo_color = Color(0.2, 0.2, 0.8, 1)
		node.material_override.emission_enabled = true
		node.material_override.emission = Color(0.2, 0.2, 0.8, 1) * 0.4
		
		# Position cluster nodes in middle ring
		var angle = float(i) / 5.0 * PI * 2 + PI/5  # Offset from central nodes
		var radius = 2.5
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		var z = randf_range(-0.4, 0.4)
		node.position = Vector3(x, y, z)
		
		cluster_nodes.add_child(node)
		network_nodes.append({"node": node, "type": "cluster", "centrality": 0.4 + randf() * 0.3})

func create_network_edges():
	# Create edges between nodes
	var connection_lines = $NetworkEdges/ConnectionLines
	for i in range(edge_count):
		var edge = CSGBox3D.new()
		edge.size = Vector3(0.05, 0.05, 1.0)
		edge.material_override = StandardMaterial3D.new()
		edge.material_override.albedo_color = Color(0.8, 0.8, 0.2, 0.6)
		edge.material_override.emission_enabled = true
		edge.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.2
		edge.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Connect random nodes with bias towards central nodes
		var node1_idx = randi() % network_nodes.size()
		var node2_idx = randi() % network_nodes.size()
		while node2_idx == node1_idx:
			node2_idx = randi() % network_nodes.size()
		
		var node1_pos = network_nodes[node1_idx]["node"].position
		var node2_pos = network_nodes[node2_idx]["node"].position
		
		# Position and orient edge between nodes
		var center = (node1_pos + node2_pos) * 0.5
		var direction = node2_pos - node1_pos
		var length = direction.length()
		
		edge.position = center
		edge.scale.z = length
		edge.look_at(node2_pos, Vector3.UP)
		
		connection_lines.add_child(edge)
		network_edges.append({"edge": edge, "node1": node1_idx, "node2": node2_idx, "weight": randf()})

func create_communities():
	# Create community indicators
	var communities_node = $CommunityDetection/Communities
	for i in range(3):
		var community = CSGSphere3D.new()
		community.radius = 2.0
		community.material_override = StandardMaterial3D.new()
		
		match i:
			0:
				community.material_override.albedo_color = Color(0.8, 0.2, 0.2, 0.2)
			1:
				community.material_override.albedo_color = Color(0.2, 0.8, 0.2, 0.2)
			2:
				community.material_override.albedo_color = Color(0.2, 0.2, 0.8, 0.2)
		
		community.material_override.emission_enabled = true
		community.material_override.emission = community.material_override.albedo_color * 0.5
		community.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Position communities in different areas
		var angle = float(i) / 3.0 * PI * 2
		var radius = 2.5
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		community.position = Vector3(x, y, 0)
		
		communities_node.add_child(community)
		communities.append(community)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(30):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along network paths
		var progress = float(i) / 30
		var angle = progress * PI * 4
		var radius = 2.0 + sin(progress * PI * 3) * 1.0
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_network_metrics():
	# Initialize network metrics
	var clustering_indicator = $NetworkMetrics/ClusteringMeter/ClusteringIndicator
	var connectivity_indicator = $NetworkMetrics/ConnectivityMeter/ConnectivityIndicator
	if clustering_indicator:
		clustering_indicator.position.x = 0  # Start at middle
	if connectivity_indicator:
		connectivity_indicator.position.x = 0  # Start at middle

func animate_network_nodes(delta):
	# Animate network nodes based on centrality
	for i in range(network_nodes.size()):
		var node_data = network_nodes[i]
		var node = node_data["node"]
		var centrality = node_data["centrality"]
		
		if node:
			# Move nodes with slight oscillation
			var base_pos = node.position
			var move_x = base_pos.x + sin(time * 0.5 + i * 0.1) * 0.1
			var move_y = base_pos.y + cos(time * 0.7 + i * 0.12) * 0.1
			var move_z = base_pos.z + sin(time * 0.9 + i * 0.08) * 0.05
			
			node.position.x = lerp(node.position.x, move_x, delta * 1.5)
			node.position.y = lerp(node.position.y, move_y, delta * 1.5)
			node.position.z = lerp(node.position.z, move_z, delta * 1.5)
			
			# Pulse based on centrality and analysis progress
			var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.3 * centrality * analysis_progress
			node.scale = Vector3.ONE * pulse
			
			# Change emission based on centrality
			if node.material_override:
				var intensity = 0.3 + centrality * analysis_progress * 0.7
				node.material_override.emission = node.material_override.albedo_color * intensity

func animate_network_edges(delta):
	# Animate network edges
	for i in range(network_edges.size()):
		var edge_data = network_edges[i]
		var edge = edge_data["edge"]
		var weight = edge_data["weight"]
		
		if edge:
			# Update edge positions based on connected nodes
			var node1_pos = network_nodes[edge_data["node1"]]["node"].position
			var node2_pos = network_nodes[edge_data["node2"]]["node"].position
			
			var center = (node1_pos + node2_pos) * 0.5
			var direction = node2_pos - node1_pos
			var length = direction.length()
			
			edge.position = lerp(edge.position, center, delta * 2.0)
			edge.scale.z = lerp(edge.scale.z, length, delta * 2.0)
			if direction.length() > 0.001:
				edge.look_at(node2_pos, Vector3.UP)
			
			# Pulse based on edge weight and analysis progress
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * weight * analysis_progress
			edge.scale.x = pulse * 0.05
			edge.scale.y = pulse * 0.05
			
			# Change color based on edge activity
			var activity = (sin(time * 1.5 + i * 0.2) * 0.5 + 0.5) * analysis_progress
			var color = Color(0.8, 0.8, 0.2, 0.6 + activity * 0.4)
			edge.material_override.albedo_color = color

func animate_analysis_engine(delta):
	# Animate analysis engine core
	var engine_core = $AnalysisEngine/EngineCore
	if engine_core:
		# Rotate engine
		engine_core.rotation.y += delta * 0.5
		
		# Pulse based on analysis progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * analysis_progress
		engine_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on analysis
		if engine_core.material_override:
			var intensity = 0.3 + analysis_progress * 0.7
			engine_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate analysis method cores
	var centrality_core = $AnalysisEngine/AnalysisMethods/CentralityCore
	if centrality_core:
		centrality_core.rotation.y += delta * 0.8
		var centrality_activation = sin(time * 1.5) * 0.5 + 0.5
		centrality_activation *= analysis_progress
		
		var pulse = 1.0 + centrality_activation * 0.3
		centrality_core.scale = Vector3.ONE * pulse
		
		if centrality_core.material_override:
			var intensity = 0.3 + centrality_activation * 0.7
			centrality_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var clustering_core = $AnalysisEngine/AnalysisMethods/ClusteringCore
	if clustering_core:
		clustering_core.rotation.y += delta * 1.0
		var clustering_activation = cos(time * 1.8) * 0.5 + 0.5
		clustering_activation *= analysis_progress
		
		var pulse = 1.0 + clustering_activation * 0.3
		clustering_core.scale = Vector3.ONE * pulse
		
		if clustering_core.material_override:
			var intensity = 0.3 + clustering_activation * 0.7
			clustering_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var smallworld_core = $AnalysisEngine/AnalysisMethods/SmallWorldCore
	if smallworld_core:
		smallworld_core.rotation.y += delta * 1.2
		var smallworld_activation = sin(time * 2.0) * 0.5 + 0.5
		smallworld_activation *= analysis_progress
		
		var pulse = 1.0 + smallworld_activation * 0.3
		smallworld_core.scale = Vector3.ONE * pulse
		
		if smallworld_core.material_override:
			var intensity = 0.3 + smallworld_activation * 0.7
			smallworld_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_community_detection(delta):
	# Animate community detection core
	var community_core = $CommunityDetection/CommunityCore
	if community_core:
		# Rotate community detection
		community_core.rotation.y += delta * 0.3
		
		# Pulse based on analysis progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * analysis_progress
		community_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on analysis
		if community_core.material_override:
			var intensity = 0.3 + analysis_progress * 0.7
			community_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate community indicators
	for i in range(communities.size()):
		var community = communities[i]
		if community:
			# Pulse communities based on detection strength
			var detection_strength = sin(time * 1.0 + i * 0.5) * 0.5 + 0.5
			detection_strength *= analysis_progress
			
			var pulse = 1.0 + detection_strength * 0.2
			community.scale = Vector3.ONE * pulse
			
			# Change transparency based on detection
			var alpha = 0.2 + detection_strength * 0.3
			var color = community.material_override.albedo_color
			color.a = alpha
			community.material_override.albedo_color = color

func animate_data_flow(delta):
	# Animate flow particles along network paths
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles along network flow
			var progress = (time * 0.3 + float(i) * 0.1) % 1.0
			var angle = progress * PI * 4
			var radius = 2.0 + sin(progress * PI * 3) * 1.0
			var x = cos(angle) * radius
			var y = sin(angle) * radius
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on network position
			var network_activity = (progress + 0.5) % 1.0
			var red_component = 0.8 * (0.5 + network_activity * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - network_activity) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on analysis
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * analysis_progress
			particle.scale = Vector3.ONE * pulse

func update_network_metrics(delta):
	# Update clustering coefficient meter
	var clustering_indicator = $NetworkMetrics/ClusteringMeter/ClusteringIndicator
	if clustering_indicator:
		var target_x = lerp(-2, 2, clustering_coefficient)
		clustering_indicator.position.x = lerp(clustering_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on clustering
		var green_component = 0.8 * clustering_coefficient
		var red_component = 0.2 + 0.6 * (1.0 - clustering_coefficient)
		clustering_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update connectivity index meter
	var connectivity_indicator = $NetworkMetrics/ConnectivityMeter/ConnectivityIndicator
	if connectivity_indicator:
		var target_x = lerp(-2, 2, connectivity_index)
		connectivity_indicator.position.x = lerp(connectivity_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on connectivity
		var green_component = 0.8 * connectivity_index
		var red_component = 0.2 + 0.6 * (1.0 - connectivity_index)
		connectivity_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_analysis_progress(progress: float):
	analysis_progress = clamp(progress, 0.0, 1.0)

func set_clustering_coefficient(clustering: float):
	clustering_coefficient = clamp(clustering, 0.0, 1.0)

func set_connectivity_index(connectivity: float):
	connectivity_index = clamp(connectivity, 0.0, 1.0)

func get_analysis_progress() -> float:
	return analysis_progress

func get_clustering_coefficient() -> float:
	return clustering_coefficient

func get_connectivity_index() -> float:
	return connectivity_index

func reset_analysis():
	time = 0.0
	analysis_progress = 0.0
	clustering_coefficient = 0.0
	connectivity_index = 0.0

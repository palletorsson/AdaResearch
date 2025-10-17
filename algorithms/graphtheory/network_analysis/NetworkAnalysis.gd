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
	print("Network Analysis Visualization initialized")
	setup_scene()
	create_network_nodes()
	create_network_edges()
	create_communities()
	create_flow_particles()

func setup_scene():
	# Enhanced lighting
	var light = DirectionalLight3D.new()
	light.light_energy = 0.8
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.shadow_enabled = true
	add_child(light)
	
	var ambient = WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_mode = Environment.BG_COLOR
	ambient.environment.background_color = Color(0.05, 0.05, 0.1)
	ambient.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambient.environment.ambient_light_color = Color(0.1, 0.1, 0.15)
	ambient.environment.glow_enabled = true
	ambient.environment.glow_intensity = 1.5
	ambient.environment.glow_strength = 1.2
	ambient.environment.glow_bloom = 0.3
	add_child(ambient)
	
	# Camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 12)
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	add_child(camera)

func _process(delta):
	time += delta
	analysis_progress = min(1.0, time * 0.1)
	clustering_coefficient = 0.3 + analysis_progress * 0.5 + sin(time * 0.5) * 0.1
	connectivity_index = 0.4 + analysis_progress * 0.4 + cos(time * 0.6) * 0.1
	
	animate_network_nodes(delta)
	update_network_edges(delta)
	animate_flow_particles(delta)
	animate_communities(delta)

func create_network_nodes():
	# Central hub nodes
	for i in range(5):
		var node = create_node_sphere(0.18, Color(1.0, 0.3, 0.3))
		var angle = float(i) / 5.0 * TAU
		var radius = 1.8
		node.position = Vector3(cos(angle) * radius, sin(angle) * radius, 0)
		add_child(node)
		network_nodes.append({
			"node": node, 
			"type": "central", 
			"centrality": 0.85 + randf() * 0.15,
			"base_pos": node.position,
			"angle": angle,
			"radius": radius
		})
	
	# Mid-tier cluster nodes
	for i in range(8):
		var node = create_node_sphere(0.13, Color(0.3, 0.7, 1.0))
		var angle = float(i) / 8.0 * TAU + 0.2
		var radius = 3.2
		node.position = Vector3(cos(angle) * radius, sin(angle) * radius, randf_range(-0.3, 0.3))
		add_child(node)
		network_nodes.append({
			"node": node, 
			"type": "cluster", 
			"centrality": 0.5 + randf() * 0.2,
			"base_pos": node.position,
			"angle": angle,
			"radius": radius
		})
	
	# Peripheral nodes
	for i in range(12):
		var node = create_node_sphere(0.09, Color(0.4, 1.0, 0.4))
		var angle = float(i) / 12.0 * TAU
		var radius = 4.5 + randf() * 0.5
		node.position = Vector3(cos(angle) * radius, sin(angle) * radius, randf_range(-0.5, 0.5))
		add_child(node)
		network_nodes.append({
			"node": node, 
			"type": "peripheral", 
			"centrality": randf() * 0.3,
			"base_pos": node.position,
			"angle": angle,
			"radius": radius
		})

func create_node_sphere(radius: float, color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_instance.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 1.5
	material.emission_energy_multiplier = 2.0
	material.metallic = 0.6
	material.roughness = 0.3
	mesh_instance.material_override = material
	
	return mesh_instance

func create_network_edges():
	# Connect central nodes to each other
	for i in range(5):
		for j in range(i + 1, 5):
			create_edge(i, j, 0.8)
	
	# Connect central to mid-tier
	for i in range(5):
		for j in range(2):
			var target = 5 + (i * 2 + j) % 8
			create_edge(i, target, 0.6)
	
	# Connect mid-tier to peripheral
	for i in range(8):
		for j in range(2):
			var target = 13 + (i + j * 6) % 12
			create_edge(5 + i, target, 0.4)
	
	# Add some random connections
	for i in range(8):
		var n1 = randi() % network_nodes.size()
		var n2 = randi() % network_nodes.size()
		if n1 != n2:
			create_edge(n1, n2, randf_range(0.2, 0.5))

func create_edge(idx1: int, idx2: int, weight: float):
	var edge_container = Node3D.new()
	add_child(edge_container)
	
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	line.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.8, 1.0, 0.7)
	material.emission_enabled = true
	material.emission = Color(0.4, 0.6, 1.0) * 0.8
	material.emission_energy_multiplier = 1.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	line.material_override = material
	
	edge_container.add_child(line)
	
	network_edges.append({
		"container": edge_container,
		"line": line,
		"node1": idx1,
		"node2": idx2,
		"weight": weight
	})

func update_network_edges(delta):
	for edge_data in network_edges:
		var node1_pos = network_nodes[edge_data["node1"]]["node"].global_position
		var node2_pos = network_nodes[edge_data["node2"]]["node"].global_position
		
		var container = edge_data["container"]
		var line = edge_data["line"]
		
		# Position at midpoint
		var midpoint = (node1_pos + node2_pos) * 0.5
		container.position = midpoint
		
		# Calculate direction and distance
		var direction = node2_pos - node1_pos
		var distance = direction.length()
		
		# Scale to match distance
		line.scale.y = distance
		
		# Orient toward target
		if distance > 0.001:
			var up = Vector3.UP
			if abs(direction.normalized().dot(up)) > 0.99:
				up = Vector3.RIGHT
			container.look_at_from_position(container.position, node2_pos, up)
			container.rotate_object_local(Vector3.RIGHT, PI / 2)
		
		# Animate pulse
		var weight = edge_data["weight"]
		var pulse = 1.0 + sin(time * 3.0 + edge_data["node1"] * 0.5) * 0.3 * weight * analysis_progress
		line.scale.x = pulse * 0.02
		line.scale.z = pulse * 0.02
		
		# Animate color flow
		var flow = fmod(time * 2.0 + edge_data["node1"] * 0.3, 1.0)
		var intensity = 0.5 + sin(flow * TAU) * 0.5
		var material = line.material_override as StandardMaterial3D
		material.emission_energy_multiplier = 1.0 + intensity * analysis_progress * 2.0

func create_communities():
	for i in range(3):
		var torus = MeshInstance3D.new()
		var torus_mesh = TorusMesh.new()
		torus_mesh.inner_radius = 1.5
		torus_mesh.outer_radius = 2.0
		torus.mesh = torus_mesh
		
		var material = StandardMaterial3D.new()
		var hue = float(i) / 3.0
		var color = Color.from_hsv(hue, 0.7, 0.8, 0.15)
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = Color.from_hsv(hue, 0.7, 1.0) * 0.5
		material.emission_energy_multiplier = 1.0
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		torus.material_override = material
		
		var angle = float(i) / 3.0 * TAU
		torus.position = Vector3(cos(angle) * 1.8, sin(angle) * 1.8, 0)
		add_child(torus)
		
		communities.append({
			"mesh": torus,
			"base_pos": torus.position,
			"hue": hue,
			"phase": float(i) / 3.0 * TAU
		})

func animate_communities(delta):
	for comm_data in communities:
		var comm = comm_data["mesh"]
		var phase = comm_data["phase"]
		
		# Rotate
		comm.rotation.z += delta * 0.3
		
		# Pulse
		var pulse = 1.0 + sin(time * 1.5 + phase) * 0.15 * analysis_progress
		comm.scale = Vector3.ONE * pulse
		
		# Glow intensity
		var material = comm.material_override as StandardMaterial3D
		var intensity = 0.5 + sin(time * 2.0 + phase) * 0.5
		material.emission_energy_multiplier = 1.0 + intensity * analysis_progress * 2.0
		
		# Update alpha
		var alpha = 0.1 + intensity * analysis_progress * 0.2
		var color = material.albedo_color
		color.a = alpha
		material.albedo_color = color

func create_flow_particles():
	for i in range(40):
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.06
		particle.mesh = sphere
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 1.0, 0.5)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.8, 0.3) * 2.0
		material.emission_energy_multiplier = 3.0
		particle.material_override = material
		
		add_child(particle)
		flow_particles.append({
			"particle": particle,
			"edge_index": randi() % network_edges.size(),
			"progress": randf(),
			"speed": randf_range(0.3, 0.8)
		})

func animate_flow_particles(delta):
	for particle_data in flow_particles:
		var particle = particle_data["particle"]
		var edge_idx = particle_data["edge_index"]
		
		# Move along edge
		particle_data["progress"] += delta * particle_data["speed"]
		if particle_data["progress"] > 1.0:
			particle_data["progress"] = 0.0
			particle_data["edge_index"] = randi() % network_edges.size()
			edge_idx = particle_data["edge_index"]
		
		var edge = network_edges[edge_idx]
		var node1_pos = network_nodes[edge["node1"]]["node"].global_position
		var node2_pos = network_nodes[edge["node2"]]["node"].global_position
		
		particle.position = node1_pos.lerp(node2_pos, particle_data["progress"])
		
		# Pulse
		var pulse = 1.0 + sin(time * 4.0 + edge_idx) * 0.3
		particle.scale = Vector3.ONE * pulse
		
		# Trail effect via opacity
		var trail_factor = sin(particle_data["progress"] * PI)
		var material = particle.material_override as StandardMaterial3D
		material.emission_energy_multiplier = 2.0 + trail_factor * 2.0 * analysis_progress

func animate_network_nodes(delta):
	for i in range(network_nodes.size()):
		var node_data = network_nodes[i]
		var node = node_data["node"]
		var centrality = node_data["centrality"]
		
		# Orbital animation
		var orbit_speed = 0.1 * (1.0 - centrality * 0.5)
		node_data["angle"] += delta * orbit_speed
		
		var base_radius = node_data["radius"]
		var wobble = sin(time * 2.0 + i * 0.5) * 0.2
		var current_radius = base_radius + wobble * centrality
		
		var target_x = cos(node_data["angle"]) * current_radius
		var target_y = sin(node_data["angle"]) * current_radius
		var target_z = sin(time * 0.5 + i * 0.3) * 0.3 * centrality
		
		node.position.x = lerp(node.position.x, target_x, delta * 2.0)
		node.position.y = lerp(node.position.y, target_y, delta * 2.0)
		node.position.z = lerp(node.position.z, target_z, delta * 2.0)
		
		# Pulse based on centrality
		var pulse = 1.0 + sin(time * 3.0 + i * 0.4) * 0.25 * centrality * analysis_progress
		node.scale = Vector3.ONE * pulse
		
		# Emission intensity
		var material = node.material_override as StandardMaterial3D
		var intensity = 1.5 + centrality * analysis_progress * 2.0
		material.emission_energy_multiplier = intensity

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

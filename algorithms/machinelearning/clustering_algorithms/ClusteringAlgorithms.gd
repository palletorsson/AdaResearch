extends Node3D
 

var time: float = 0.0
var clustering_progress: float = 0.0
var inertia_score: float = 1.0
var silhouette_score: float = 0.0
var particle_count: int = 15
var flow_particles: Array = []
var cluster_particles: Array = []

func _ready():
	# Initialize Clustering Algorithms visualization
	print("Clustering Algorithms Visualization initialized")
	create_cluster_particles()
	create_flow_particles()
	setup_training_metrics()

func _process(delta):
	time += delta
	
	# Simulate clustering progress
	clustering_progress = min(1.0, time * 0.12)
	inertia_score = max(0.1, 1.0 - clustering_progress * 0.8)
	silhouette_score = clustering_progress * 0.9
	
	animate_clusters(delta)
	animate_centroids(delta)
	animate_clustering_algorithm(delta)
	animate_data_flow(delta)
	update_training_metrics(delta)

func create_cluster_particles():
	# Create particles for each cluster
	var clusters = [$DataPoints/Cluster1/Cluster1Particles, $DataPoints/Cluster2/Cluster2Particles, $DataPoints/Cluster3/Cluster3Particles]
	var cluster_colors = [Color(0.8, 0.2, 0.2, 1), Color(0.2, 0.8, 0.2, 1), Color(0.2, 0.2, 0.8, 1)]
	
	for cluster_idx in range(clusters.size()):
		var cluster = clusters[cluster_idx]
		var base_color = cluster_colors[cluster_idx]
		
		for i in range(particle_count):
			var particle = CSGSphere3D.new()
			particle.radius = 0.08
			particle.material_override = StandardMaterial3D.new()
			particle.material_override.albedo_color = base_color
			particle.material_override.emission_enabled = true
			particle.material_override.emission = base_color * 0.3
			
			# Position particles in a cluster around the centroid
			var cluster_x = (cluster_idx - 1) * 6  # -6, 0, 6
			var x = cluster_x + randf_range(-1.5, 1.5)
			var y = randf_range(-1.5, 1.5)
			var z = randf_range(-1.5, 1.5)
			particle.position = Vector3(x, y, z)
			
			cluster.add_child(particle)
			cluster_particles.append(particle)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(20):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the clustering flow path
		var progress = float(i) / 20
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 2) * 1.5
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_training_metrics():
	# Initialize clustering metrics
	var inertia_indicator = $TrainingMetrics/InertiaMeter/InertiaIndicator
	var silhouette_indicator = $TrainingMetrics/SilhouetteMeter/SilhouetteIndicator
	if inertia_indicator:
		inertia_indicator.position.x = 0  # Start at middle
	if silhouette_indicator:
		silhouette_indicator.position.x = 0  # Start at middle

func animate_clusters(delta):
	# Animate cluster particles
	for i in range(cluster_particles.size()):
		var particle = cluster_particles[i]
		if particle:
			# Get the cluster this particle belongs to
			var cluster_idx = i / particle_count
			var cluster_x = (cluster_idx - 1) * 6
			
			# Move particles towards their cluster centroid
			var target_x = cluster_x + sin(time * 0.8 + i * 0.1) * 0.5
			var target_y = sin(time * 1.2 + i * 0.15) * 0.3
			var target_z = cos(time * 1.0 + i * 0.12) * 0.3
			
			particle.position.x = lerp(particle.position.x, target_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, target_y, delta * 1.5)
			particle.position.z = lerp(particle.position.z, target_z, delta * 1.5)
			
			# Pulse particles based on clustering progress
			var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.2 * clustering_progress
			particle.scale = Vector3.ONE * pulse

func animate_centroids(delta):
	# Animate centroid cores
	var centroids = [$Centroids/Centroid1/Centroid1Core, $Centroids/Centroid2/Centroid2Core, $Centroids/Centroid3/Centroid3Core]
	
	for i in range(centroids.size()):
		var centroid = centroids[i]
		if centroid:
			# Rotate centroids
			centroid.rotation.y += delta * (0.5 + i * 0.2)
			
			# Pulse based on clustering progress
			var pulse = 1.0 + sin(time * 2.0 + i * PI) * 0.15 * clustering_progress
			centroid.scale = Vector3.ONE * pulse
			
			# Change emission intensity based on clustering
			if centroid.material_override:
				var intensity = 0.3 + clustering_progress * 0.7
				centroid.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_clustering_algorithm(delta):
	# Animate clustering algorithm core
	var algorithm_core = $ClusteringAlgorithm/AlgorithmCore
	if algorithm_core:
		# Rotate algorithm
		algorithm_core.rotation.y += delta * 0.4
		
		# Pulse based on clustering progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * clustering_progress
		algorithm_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on clustering
		if algorithm_core.material_override:
			var intensity = 0.3 + clustering_progress * 0.7
			algorithm_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the clustering flow
			var progress = fmod(time * 0.2 + i * 0.1, 1.0)
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 2) * 1.5
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and clustering progress
			var color_progress = fmod((progress + 0.5), 1.0)
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var green_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
			particle.material_override.emission = Color(red_component, green_component, 0.2, 1) * 0.3
			
			# Pulse particles based on clustering
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * clustering_progress
			particle.scale = Vector3.ONE * pulse

func update_training_metrics(delta):
	# Update inertia meter
	var inertia_indicator = $TrainingMetrics/InertiaMeter/InertiaIndicator
	if inertia_indicator:
		var target_x = lerp(-2, 2, 1.0 - inertia_score)
		inertia_indicator.position.x = lerp(inertia_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on inertia (lower is better)
		var green_component = 0.8 * (1.0 - inertia_score)
		var red_component = 0.2 + 0.6 * inertia_score
		inertia_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update silhouette meter
	var silhouette_indicator = $TrainingMetrics/SilhouetteMeter/SilhouetteIndicator
	if silhouette_indicator:
		var target_x = lerp(-2, 2, silhouette_score)
		silhouette_indicator.position.x = lerp(silhouette_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on silhouette (higher is better)
		var green_component = 0.8 * silhouette_score
		var red_component = 0.2 + 0.6 * (1.0 - silhouette_score)
		silhouette_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_clustering_progress(progress: float):
	clustering_progress = clamp(progress, 0.0, 1.0)

func set_inertia_score(inertia: float):
	inertia_score = clamp(inertia, 0.1, 1.0)

func set_silhouette_score(silhouette: float):
	silhouette_score = clamp(silhouette, 0.0, 1.0)

func get_clustering_progress() -> float:
	return clustering_progress

func get_inertia_score() -> float:
	return inertia_score

func get_silhouette_score() -> float:
	return silhouette_score

func reset_clustering():
	time = 0.0
	clustering_progress = 0.0
	inertia_score = 1.0
	silhouette_score = 0.0

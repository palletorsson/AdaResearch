extends Node3D

# Simple K-Means Clustering Visualization
# Automatic visualization with no UI or interaction

# Algorithm Parameters
@export var data_point_count: int = 50
@export var cluster_count: int = 3
@export var iteration_speed: float = 2.0
@export var data_space_size: float = 20.0
@export var cluster_spread: float = 3.0

# Algorithm state
var data_points: Array = []
var centroids: Array = []
var assignments: Array = []
var iteration: int = 0
var converged: bool = false
var algorithm_timer: float = 0.0

# Visual elements
var point_meshes: Array = []
var centroid_meshes: Array = []

# Cluster colors
var cluster_colors: Array = [
	Color(1.0, 0.2, 0.2),  # Red
	Color(0.2, 1.0, 0.2),  # Green
	Color(0.2, 0.2, 1.0),  # Blue
	Color(1.0, 1.0, 0.2),  # Yellow
	Color(1.0, 0.2, 1.0),  # Magenta
	Color(0.2, 1.0, 1.0),  # Cyan
]

# Data structures
class DataPoint:
	var position: Vector3
	var cluster_id: int = -1
	var mesh_instance: MeshInstance3D
	
	func _init(pos: Vector3):
		position = pos

class Centroid:
	var position: Vector3
	var cluster_id: int
	var mesh_instance: MeshInstance3D
	
	func _init(pos: Vector3, id: int):
		position = pos
		cluster_id = id

func _ready():
	generate_data()
	initialize_centroids()
	create_visuals()
	start_clustering()

func _process(delta):
	if not converged:
		algorithm_timer += delta
		if algorithm_timer >= iteration_speed:
			perform_clustering_step()
			algorithm_timer = 0.0

func generate_data():
	data_points.clear()
	
	# Generate clustered data
	var points_per_cluster = data_point_count / 3
	
	for cluster_idx in range(3):
		var cluster_center = Vector3(
			randf_range(-data_space_size/3, data_space_size/3),
			randf_range(-2, 2),
			randf_range(-data_space_size/3, data_space_size/3)
		)
		
		for i in range(points_per_cluster):
			var offset = Vector3(
				randf_range(-cluster_spread, cluster_spread),
				randf_range(-cluster_spread/2, cluster_spread/2),
				randf_range(-cluster_spread, cluster_spread)
			)
			
			var point = DataPoint.new(cluster_center + offset)
			data_points.append(point)
	
	# Add remaining points randomly
	var remaining = data_point_count - data_points.size()
	for i in range(remaining):
		var random_pos = Vector3(
			randf_range(-data_space_size/2, data_space_size/2),
			randf_range(-2, 2),
			randf_range(-data_space_size/2, data_space_size/2)
		)
		var point = DataPoint.new(random_pos)
		data_points.append(point)

func initialize_centroids():
	centroids.clear()
	assignments.clear()
	
	# Random centroid initialization
	for i in range(cluster_count):
		var random_pos = Vector3(
			randf_range(-data_space_size/2, data_space_size/2),
			randf_range(-1, 1),
			randf_range(-data_space_size/2, data_space_size/2)
		)
		var centroid = Centroid.new(random_pos, i)
		centroids.append(centroid)
	
	# Initialize assignments
	for i in range(data_points.size()):
		assignments.append(-1)

func create_visuals():
	# Create data point visuals
	for point in data_points:
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.2
		sphere.height = 0.4
		mesh_instance.mesh = sphere
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.7, 0.7, 0.7)
		mesh_instance.material_override = material
		mesh_instance.position = point.position
		
		point.mesh_instance = mesh_instance
		add_child(mesh_instance)
		point_meshes.append(mesh_instance)
	
	# Create centroid visuals
	for centroid in centroids:
		var mesh_instance = MeshInstance3D.new()
		var cube = BoxMesh.new()
		cube.size = Vector3(0.6, 0.6, 0.6)
		mesh_instance.mesh = cube
		
		var material = StandardMaterial3D.new()
		material.albedo_color = cluster_colors[centroid.cluster_id]
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.5
		material.metallic = 0.8
		mesh_instance.material_override = material
		mesh_instance.position = centroid.position
		
		centroid.mesh_instance = mesh_instance
		add_child(mesh_instance)
		centroid_meshes.append(mesh_instance)

func start_clustering():
	iteration = 0
	converged = false
	print("Starting K-means clustering with ", cluster_count, " clusters")

func perform_clustering_step():
	if converged:
		return
	
	iteration += 1
	print("Iteration: ", iteration)
	
	# Assignment step
	for i in range(data_points.size()):
		var point = data_points[i]
		var min_distance = INF
		var nearest_cluster = 0
		
		for j in range(centroids.size()):
			var distance = point.position.distance_to(centroids[j].position)
			if distance < min_distance:
				min_distance = distance
				nearest_cluster = j
		
		assignments[i] = nearest_cluster
		point.cluster_id = nearest_cluster
	
	# Update step
	var total_movement = 0.0
	for i in range(centroids.size()):
		var centroid = centroids[i]
		var sum_pos = Vector3.ZERO
		var count = 0
		
		for j in range(data_points.size()):
			if assignments[j] == i:
				sum_pos += data_points[j].position
				count += 1
		
		if count > 0:
			var new_position = sum_pos / count
			total_movement += centroid.position.distance_to(new_position)
			centroid.position = new_position
	
	# Check convergence
	if total_movement < 0.1 or iteration >= 20:
		converged = true
		print("Converged after ", iteration, " iterations")
	
	# Update visuals
	update_visuals()

func update_visuals():
	# Update point colors
	for i in range(data_points.size()):
		var point = data_points[i]
		var cluster_id = assignments[i]
		
		if cluster_id >= 0 and cluster_id < cluster_colors.size():
			var material = point.mesh_instance.material_override
			material.albedo_color = cluster_colors[cluster_id]
			material.emission_enabled = true
			material.emission = cluster_colors[cluster_id] * 0.3
	
	# Update centroid positions with smooth animation
	for centroid in centroids:
		if centroid.mesh_instance:
			var tween = create_tween()
			tween.tween_property(centroid.mesh_instance, "position", centroid.position, 1.0)

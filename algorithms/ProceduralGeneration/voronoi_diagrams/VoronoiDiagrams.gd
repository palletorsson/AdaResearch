extends Node3D
class_name VoronoiDiagrams

var time: float = 0.0
var generation_progress: float = 0.0
var uniformity_score: float = 0.0
var coverage_score: float = 0.0
var seed_count: int = 15
var cell_resolution: int = 25
var seed_points: Array = []
var voronoi_cells: Array = []
var boundaries: Array = []
var distance_indicators: Array = []
var sweep_line_position: float = -5.0

func _ready():
	# Initialize Voronoi Diagrams visualization
	print("Voronoi Diagrams Visualization initialized")
	create_seed_points()
	create_voronoi_cells()
	create_boundaries()
	create_distance_indicators()
	setup_voronoi_metrics()

func _process(delta):
	time += delta
	
	# Simulate generation progress
	generation_progress = min(1.0, time * 0.1)
	uniformity_score = generation_progress * 0.85
	coverage_score = generation_progress * 0.9
	
	animate_seed_points(delta)
	animate_voronoi_cells(delta)
	animate_generation_engine(delta)
	animate_distance_fields(delta)
	animate_sweep_line(delta)
	update_voronoi_metrics(delta)

func create_seed_points():
	# Create Voronoi seed points
	var seed_points_node = $VoronoiSpace/SeedPoints
	for i in range(seed_count):
		var seed = CSGSphere3D.new()
		seed.radius = 0.15
		seed.material_override = StandardMaterial3D.new()
		
		# Different colors for different seed types
		var seed_type = i % 4
		match seed_type:
			0:  # Primary seeds
				seed.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
			1:  # Secondary seeds
				seed.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
			2:  # Tertiary seeds
				seed.material_override.albedo_color = Color(0.2, 0.2, 0.8, 1)
			3:  # Quaternary seeds
				seed.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		
		seed.material_override.emission_enabled = true
		seed.material_override.emission = seed.material_override.albedo_color * 0.5
		
		# Random position within space
		var pos = Vector3(
			randf_range(-4, 4),
			randf_range(-3, 3),
			randf_range(-4, 4)
		)
		seed.position = pos
		
		seed_points_node.add_child(seed)
		seed_points.append({
			"seed": seed,
			"position": pos,
			"influence": randf_range(0.5, 1.5),
			"type": seed_type
		})

func create_voronoi_cells():
	# Create Voronoi cell representations
	var voronoi_cells_node = $VoronoiSpace/VoronoiCells
	for i in range(seed_count):
		var cell = CSGSphere3D.new()
		cell.radius = 1.5
		cell.material_override = StandardMaterial3D.new()
		
		# Match seed colors but with transparency
		var seed_data = seed_points[i]
		var base_color = seed_data["seed"].material_override.albedo_color
		base_color.a = 0.3
		cell.material_override.albedo_color = base_color
		cell.material_override.emission_enabled = true
		cell.material_override.emission = base_color * 0.2
		cell.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Position at seed location
		cell.position = seed_data["position"]
		
		voronoi_cells_node.add_child(cell)
		voronoi_cells.append({
			"cell": cell,
			"seed_index": i,
			"area": 1.0,
			"neighbors": []
		})

func create_boundaries():
	# Create Voronoi boundary lines
	var boundaries_node = $VoronoiSpace/Boundaries
	for i in range(30):  # Create boundary segments
		var boundary = CSGBox3D.new()
		boundary.size = Vector3(0.05, 0.05, 1.0)
		boundary.material_override = StandardMaterial3D.new()
		boundary.material_override.albedo_color = Color(0.8, 0.8, 0.8, 0.8)
		boundary.material_override.emission_enabled = true
		boundary.material_override.emission = Color(0.8, 0.8, 0.8, 1) * 0.3
		boundary.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		# Random boundary positions (will be updated based on actual Voronoi calculation)
		var pos = Vector3(
			randf_range(-4, 4),
			randf_range(-3, 3),
			randf_range(-4, 4)
		)
		boundary.position = pos
		
		# Random orientation
		boundary.rotation.y = randf() * PI * 2
		
		boundaries_node.add_child(boundary)
		boundaries.append({
			"boundary": boundary,
			"start_point": Vector3.ZERO,
			"end_point": Vector3.ZERO,
			"separates": []
		})

func create_distance_indicators():
	# Create distance field indicators
	var distance_indicators_node = $DistanceFields/DistanceIndicators
	for i in range(cell_resolution):
		var indicator = CSGSphere3D.new()
		indicator.radius = 0.08
		indicator.material_override = StandardMaterial3D.new()
		indicator.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		indicator.material_override.emission_enabled = true
		indicator.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Grid position for distance field sampling
		var grid_size = 5
		var row = i / grid_size
		var col = i % grid_size
		var pos = Vector3(
			(col - grid_size/2.0) * 0.8,
			0,
			(row - grid_size/2.0) * 0.8
		)
		indicator.position = pos
		
		distance_indicators_node.add_child(indicator)
		distance_indicators.append({
			"indicator": indicator,
			"position": pos,
			"nearest_seed": 0,
			"distance": 0.0
		})

func setup_voronoi_metrics():
	# Initialize Voronoi metrics
	var uniformity_indicator = $VoronoiMetrics/UniformityMeter/UniformityIndicator
	var coverage_indicator = $VoronoiMetrics/CoverageMeter/CoverageIndicator
	if uniformity_indicator:
		uniformity_indicator.position.x = 0  # Start at middle
	if coverage_indicator:
		coverage_indicator.position.x = 0  # Start at middle

func animate_seed_points(delta):
	# Animate seed points
	for i in range(seed_points.size()):
		var seed_data = seed_points[i]
		var seed = seed_data["seed"]
		
		if seed:
			# Slight movement to show dynamic generation
			var base_pos = seed_data["position"]
			var move_x = base_pos.x + sin(time * 0.5 + i * 0.2) * 0.1
			var move_y = base_pos.y + cos(time * 0.7 + i * 0.15) * 0.1
			var move_z = base_pos.z + sin(time * 0.9 + i * 0.18) * 0.1
			
			seed.position.x = lerp(seed.position.x, move_x, delta * 1.0)
			seed.position.y = lerp(seed.position.y, move_y, delta * 1.0)
			seed.position.z = lerp(seed.position.z, move_z, delta * 1.0)
			
			# Update stored position
			seed_data["position"] = seed.position
			
			# Pulse based on influence and generation progress
			var pulse = 1.0 + sin(time * 3.0 + i * 0.3) * 0.2 * seed_data["influence"] * generation_progress
			seed.scale = Vector3.ONE * pulse
			
			# Change emission based on activity
			var activity = (sin(time * 2.0 + i * 0.2) * 0.5 + 0.5) * generation_progress
			if seed.material_override:
				var intensity = 0.5 + activity * 0.5
				seed.material_override.emission = seed.material_override.albedo_color * intensity

func animate_voronoi_cells(delta):
	# Animate Voronoi cells
	for i in range(voronoi_cells.size()):
		var cell_data = voronoi_cells[i]
		var cell = cell_data["cell"]
		var seed_data = seed_points[cell_data["seed_index"]]
		
		if cell:
			# Follow seed position
			cell.position = lerp(cell.position, seed_data["position"], delta * 2.0)
			
			# Calculate approximate cell size based on nearest neighbors
			var avg_distance = calculate_average_neighbor_distance(i)
			var target_radius = avg_distance * 0.7
			var current_radius = cell.radius
			cell.radius = lerp(current_radius, target_radius, delta * 1.0)
			
			# Update cell area
			cell_data["area"] = PI * cell.radius * cell.radius
			
			# Pulse based on cell activity
			var pulse = 1.0 + sin(time * 2.5 + i * 0.4) * 0.1 * generation_progress
			cell.scale = Vector3.ONE * pulse
			
			# Change transparency based on generation progress
			var alpha = 0.3 + generation_progress * 0.2
			var color = cell.material_override.albedo_color
			color.a = alpha
			cell.material_override.albedo_color = color

func calculate_average_neighbor_distance(seed_index: int) -> float:
	var seed_pos = seed_points[seed_index]["position"]
	var total_distance = 0.0
	var neighbor_count = 0
	
	for i in range(seed_points.size()):
		if i != seed_index:
			var other_pos = seed_points[i]["position"]
			var distance = seed_pos.distance_to(other_pos)
			total_distance += distance
			neighbor_count += 1
	
	return total_distance / neighbor_count if neighbor_count > 0 else 1.0

func animate_generation_engine(delta):
	# Animate generation engine core
	var engine_core = $GenerationEngine/EngineCore
	if engine_core:
		# Rotate engine
		engine_core.rotation.y += delta * 0.5
		
		# Pulse based on generation progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * generation_progress
		engine_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on generation
		if engine_core.material_override:
			var intensity = 0.3 + generation_progress * 0.7
			engine_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate generation method cores
	var fortune_core = $GenerationEngine/GenerationMethods/FortuneCore
	if fortune_core:
		fortune_core.rotation.y += delta * 0.8
		var fortune_activation = sin(time * 1.5) * 0.5 + 0.5
		fortune_activation *= generation_progress
		
		var pulse = 1.0 + fortune_activation * 0.3
		fortune_core.scale = Vector3.ONE * pulse
		
		if fortune_core.material_override:
			var intensity = 0.3 + fortune_activation * 0.7
			fortune_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var delaunay_core = $GenerationEngine/GenerationMethods/DelaunayCore
	if delaunay_core:
		delaunay_core.rotation.y += delta * 1.0
		var delaunay_activation = cos(time * 1.8) * 0.5 + 0.5
		delaunay_activation *= generation_progress
		
		var pulse = 1.0 + delaunay_activation * 0.3
		delaunay_core.scale = Vector3.ONE * pulse
		
		if delaunay_core.material_override:
			var intensity = 0.3 + delaunay_activation * 0.7
			delaunay_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var lloyd_core = $GenerationEngine/GenerationMethods/LloydCore
	if lloyd_core:
		lloyd_core.rotation.y += delta * 1.2
		var lloyd_activation = sin(time * 2.0) * 0.5 + 0.5
		lloyd_activation *= generation_progress
		
		var pulse = 1.0 + lloyd_activation * 0.3
		lloyd_core.scale = Vector3.ONE * pulse
		
		if lloyd_core.material_override:
			var intensity = 0.3 + lloyd_activation * 0.7
			lloyd_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_distance_fields(delta):
	# Animate distance field core
	var field_core = $DistanceFields/FieldCore
	if field_core:
		# Rotate field
		field_core.rotation.y += delta * 0.3
		
		# Pulse based on generation progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * generation_progress
		field_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity
		if field_core.material_override:
			var intensity = 0.3 + generation_progress * 0.7
			field_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate distance indicators
	for i in range(distance_indicators.size()):
		var indicator_data = distance_indicators[i]
		var indicator = indicator_data["indicator"]
		
		if indicator:
			# Calculate distance to nearest seed
			var min_distance = 999999.0
			var nearest_seed = 0
			
			for j in range(seed_points.size()):
				var seed_pos = seed_points[j]["position"]
				var distance = indicator_data["position"].distance_to(seed_pos)
				if distance < min_distance:
					min_distance = distance
					nearest_seed = j
			
			indicator_data["nearest_seed"] = nearest_seed
			indicator_data["distance"] = min_distance
			
			# Color based on nearest seed
			var seed_color = seed_points[nearest_seed]["seed"].material_override.albedo_color
			indicator.material_override.albedo_color = seed_color
			indicator.material_override.emission = seed_color * 0.3
			
			# Scale based on distance (closer = smaller)
			var scale_factor = 1.0 - (min_distance / 5.0)  # Normalize distance
			scale_factor = clamp(scale_factor, 0.3, 1.0)
			var pulse = scale_factor + sin(time * 3.0 + i * 0.2) * 0.1 * generation_progress
			indicator.scale = Vector3.ONE * pulse

func animate_sweep_line(delta):
	# Animate Fortune's algorithm sweep line
	var sweep_core = $SweepLine/SweepCore
	if sweep_core:
		# Move sweep line across space
		sweep_line_position += delta * 2.0
		if sweep_line_position > 5.0:
			sweep_line_position = -5.0
		
		sweep_core.position.x = sweep_line_position
		
		# Pulse based on sweep activity
		var pulse = 1.0 + sin(time * 3.0) * 0.1 * generation_progress
		sweep_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on sweep position
		if sweep_core.material_override:
			var intensity = 0.3 + abs(sin(sweep_line_position * 0.5)) * 0.7 * generation_progress
			sweep_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate boundaries based on sweep line
	for i in range(boundaries.size()):
		var boundary_data = boundaries[i]
		var boundary = boundary_data["boundary"]
		
		if boundary:
			# Move boundaries to show dynamic construction
			var base_pos = boundary.position
			var move_x = base_pos.x + sin(time * 1.0 + i * 0.3) * 0.2
			var move_y = base_pos.y + cos(time * 1.2 + i * 0.25) * 0.1
			var move_z = base_pos.z + sin(time * 0.8 + i * 0.35) * 0.2
			
			boundary.position.x = lerp(boundary.position.x, move_x, delta * 1.5)
			boundary.position.y = lerp(boundary.position.y, move_y, delta * 1.5)
			boundary.position.z = lerp(boundary.position.z, move_z, delta * 1.5)
			
			# Pulse boundaries
			var pulse = 1.0 + sin(time * 2.8 + i * 0.4) * 0.2 * generation_progress
			boundary.scale = Vector3.ONE * pulse
			
			# Change visibility based on proximity to sweep line
			var distance_to_sweep = abs(boundary.position.x - sweep_line_position)
			var visibility = 1.0 - (distance_to_sweep / 5.0)
			visibility = clamp(visibility, 0.2, 1.0)
			
			var color = boundary.material_override.albedo_color
			color.a = 0.8 * visibility
			boundary.material_override.albedo_color = color

func update_voronoi_metrics(delta):
	# Update uniformity meter
	var uniformity_indicator = $VoronoiMetrics/UniformityMeter/UniformityIndicator
	if uniformity_indicator:
		var target_x = lerp(-2, 2, uniformity_score)
		uniformity_indicator.position.x = lerp(uniformity_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on uniformity
		var green_component = 0.8 * uniformity_score
		var red_component = 0.2 + 0.6 * (1.0 - uniformity_score)
		uniformity_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update coverage meter
	var coverage_indicator = $VoronoiMetrics/CoverageMeter/CoverageIndicator
	if coverage_indicator:
		var target_x = lerp(-2, 2, coverage_score)
		coverage_indicator.position.x = lerp(coverage_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on coverage
		var green_component = 0.8 * coverage_score
		var red_component = 0.2 + 0.6 * (1.0 - coverage_score)
		coverage_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_generation_progress(progress: float):
	generation_progress = clamp(progress, 0.0, 1.0)

func set_uniformity_score(uniformity: float):
	uniformity_score = clamp(uniformity, 0.0, 1.0)

func set_coverage_score(coverage: float):
	coverage_score = clamp(coverage, 0.0, 1.0)

func get_generation_progress() -> float:
	return generation_progress

func get_uniformity_score() -> float:
	return uniformity_score

func get_coverage_score() -> float:
	return coverage_score

func reset_generation():
	time = 0.0
	generation_progress = 0.0
	uniformity_score = 0.0
	coverage_score = 0.0
	sweep_line_position = -5.0

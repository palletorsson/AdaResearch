# CAVRShowcase.gd
# Comprehensive VR Cellular Automata Showcase System
# Attach to Node3D in your VR scene
extends Node3D

# Showcase configurations
const SHOWCASE_COUNT = 12
const PLATFORM_RADIUS = 15.0
const PLATFORM_HEIGHT = 0.5
const GRID_SIZE = 20  # Smaller for better performance and visibility

var current_showcase = 0
var showcases: Array = []
var info_panels: Array = []
var transition_time = 0.0
var auto_cycle = true
var cycle_interval = 10.0  # Changed to 10 seconds

# CA System types
enum CAType {
	RECRYSTALLIZATION,    # Metal crystallization
	DENDRITE_GROWTH,      # Crystal dendrites
	PERCOLATION,          # Fluid percolation
	CRACK_PROPAGATION,    # Material cracks
	AVALANCHE,            # Sand pile models
	TRAFFIC_FLOW,         # Highway traffic
	FLOOD_PROPAGATION,    # Water spread
	ECOSYSTEM,            # Biological systems
	DISEASE_SPREAD,       # Epidemiology
	BLOOD_FLOW,           # Lattice Boltzmann
	DROPLET_BEHAVIOR,     # Surface tension
	SELF_ORGANIZATION     # Emergence studies
}

func _ready():
 
	initialize_ca_showcases()
	start_showcase_cycle()

func create_info_panel(index: int, pos: Vector3):
	var panel = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2.5, 1.5, 0.1)
	panel.mesh = box_mesh
	panel.position = pos
	panel.visible = false  # Start hidden, will be shown by highlight_current_showcase
	
	var panel_material = StandardMaterial3D.new()
	panel_material.albedo_color = Color(0.05, 0.1, 0.15, 0.95)
	panel_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel_material.emission_enabled = true
	panel_material.emission = Color(0.2, 0.4, 0.6) * 0.4
	panel_material.metallic = 0.2
	panel_material.roughness = 0.1
	panel_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	panel.material_override = panel_material
	
	# Add text label
	var label = Label3D.new()
	label.text = get_ca_name(index)
	label.font_size = 24
	label.position = Vector3(0, 0, 0.06)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	panel.add_child(label)
	
	add_child(panel)
	info_panels.append(panel)

func initialize_ca_showcases():
	showcases.clear()
	info_panels.clear()
	
	# Initialize each CA type with specific parameters at the same position
	var central_position = Vector3(0, 0, 0)
	
	for i in range(SHOWCASE_COUNT):
		var ca_type = i as CAType
		var showcase = create_ca_showcase(ca_type, central_position)
		showcases.append(showcase)
		
		# Create info panel for this showcase
		create_info_panel(i, central_position + Vector3(0, 2, 0))
	
	# Initially show only the first showcase
	highlight_current_showcase()

func create_ca_showcase(ca_type: CAType, platform_pos: Vector3) -> Node3D:
	var showcase = Node3D.new()
	showcase.position = platform_pos + Vector3(0, 1, 0)
	showcase.visible = false  # Start hidden, will be shown by highlight_current_showcase
	add_child(showcase)
	
	match ca_type:
		CAType.RECRYSTALLIZATION:
			create_recrystallization_ca(showcase)
		CAType.DENDRITE_GROWTH:
			create_dendrite_growth_ca(showcase)
		CAType.PERCOLATION:
			create_percolation_ca(showcase)
		CAType.CRACK_PROPAGATION:
			create_crack_propagation_ca(showcase)
		CAType.AVALANCHE:
			create_avalanche_ca(showcase)
		CAType.TRAFFIC_FLOW:
			create_traffic_flow_ca(showcase)
		CAType.FLOOD_PROPAGATION:
			create_flood_propagation_ca(showcase)
		CAType.ECOSYSTEM:
			create_ecosystem_ca(showcase)
		CAType.DISEASE_SPREAD:
			create_disease_spread_ca(showcase)
		CAType.BLOOD_FLOW:
			create_blood_flow_ca(showcase)
		CAType.DROPLET_BEHAVIOR:
			create_droplet_behavior_ca(showcase)
		CAType.SELF_ORGANIZATION:
			create_self_organization_ca(showcase)
	
	return showcase

func create_recrystallization_ca(parent: Node3D):
	# Metal recrystallization simulation
	var grid = create_3d_grid(parent, "Recrystallization")
	var nucleation_sites = []
	
	# Add nucleation sites with visual markers
	for i in range(5):
		var site = Vector3i(
			randi() % GRID_SIZE,
			randi() % GRID_SIZE,
			randi() % GRID_SIZE
		)
		nucleation_sites.append(site)
		
		# Create visual marker for nucleation site
		var marker = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.1
		sphere_mesh.height = 0.2  # Fix elongated sphere
		marker.mesh = sphere_mesh
		var marker_material = StandardMaterial3D.new()
		marker_material.albedo_color = Color(1.0, 0.6, 0.0)
		marker_material.emission_enabled = true
		marker_material.emission = Color(1.0, 0.6, 0.0) * 0.8
		marker_material.metallic = 0.3
		marker_material.roughness = 0.2
		marker_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		marker.material_override = marker_material
		parent.add_child(marker)
	
	# Store CA data
	parent.set_meta("type", "recrystallization")
	parent.set_meta("grid", grid)
	parent.set_meta("nucleation_sites", nucleation_sites)
	parent.set_meta("growth_rate", 0.02)

func create_dendrite_growth_ca(parent: Node3D):
	# Crystal dendrite formation
	var grid = create_3d_grid(parent, "Dendrite Growth")
	var growth_centers = []
	
	# Central growth point
	var center = Vector3i(GRID_SIZE/2, GRID_SIZE/2, GRID_SIZE/2)
	growth_centers.append(center)
	
	# Create visual center point
	var center_marker = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.15
	sphere_mesh.height = 0.3  # Fix elongated sphere
	center_marker.mesh = sphere_mesh
	var center_material = StandardMaterial3D.new()
	center_material.albedo_color = Color(0.3, 0.7, 1.0)
	center_material.emission_enabled = true
	center_material.emission = Color(0.3, 0.7, 1.0) * 0.9
	center_material.metallic = 0.4
	center_material.roughness = 0.1
	center_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	center_marker.material_override = center_material
	parent.add_child(center_marker)
	
	parent.set_meta("type", "dendrite")
	parent.set_meta("grid", grid)
	parent.set_meta("growth_centers", growth_centers)
	parent.set_meta("growth_probability", 0.3)
	parent.set_meta("branching_factor", 0.15)

func create_percolation_ca(parent: Node3D):
	# Fluid percolation through porous medium
	var grid = create_3d_grid(parent, "Percolation")
	
	# Create porous structure visualization
	for i in range(20):
		var pore = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.05 + randf() * 0.03
		sphere_mesh.height = sphere_mesh.radius * 2  # Fix elongated sphere
		pore.mesh = sphere_mesh
		pore.position = Vector3(
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5)
		)
		var pore_material = StandardMaterial3D.new()
		pore_material.albedo_color = Color(0.6, 0.6, 0.8, 0.7)
		pore_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pore.material_override = pore_material
		parent.add_child(pore)
	
	parent.set_meta("type", "percolation")
	parent.set_meta("grid", grid)
	parent.set_meta("porosity", 0.6)
	parent.set_meta("flow_rate", 0.1)

func create_crack_propagation_ca(parent: Node3D):
	# Material crack propagation
	var grid = create_3d_grid(parent, "Crack Propagation")
	var stress_points = []
	
	# Add initial stress concentrators with visual markers
	for i in range(3):
		var stress_point = Vector3i(
			randi() % GRID_SIZE,
			GRID_SIZE - 1,
			randi() % GRID_SIZE
		)
		stress_points.append(stress_point)
		
		# Create stress visualization
		var stress_marker = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.2, 0.1, 0.2)
		stress_marker.mesh = box_mesh
		var stress_material = StandardMaterial3D.new()
		stress_material.albedo_color = Color(1.0, 0.2, 0.2)
		stress_material.emission_enabled = true
		stress_material.emission = Color(1.0, 0.2, 0.2) * 0.7
		stress_marker.material_override = stress_material
		parent.add_child(stress_marker)
	
	parent.set_meta("type", "crack")
	parent.set_meta("grid", grid)
	parent.set_meta("stress_points", stress_points)
	parent.set_meta("crack_threshold", 0.4)

func create_avalanche_ca(parent: Node3D):
	# Sand pile avalanche model (Bak-Tang-Wiesenfeld)
	var grid = create_2d_grid_on_platform(parent, "Avalanche Model")
	
	# Create sand pile visualization
	var pile_base = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 1.0
	cylinder_mesh.bottom_radius = 1.5
	cylinder_mesh.height = 0.5
	pile_base.mesh = cylinder_mesh
	var sand_material = StandardMaterial3D.new()
	sand_material.albedo_color = Color(0.8, 0.6, 0.2)
	pile_base.material_override = sand_material
	parent.add_child(pile_base)
	
	parent.set_meta("type", "avalanche")
	parent.set_meta("grid", grid)
	parent.set_meta("critical_slope", 4)
	parent.set_meta("sand_drop_rate", 0.1)

func create_traffic_flow_ca(parent: Node3D):
	# Highway traffic flow simulation
	var road_segments = create_road_network(parent)
	
	parent.set_meta("type", "traffic")
	parent.set_meta("roads", road_segments)
	parent.set_meta("car_density", 0.3)
	parent.set_meta("max_velocity", 3)

func create_flood_propagation_ca(parent: Node3D):
	# Flood water propagation
	var terrain = create_terrain_grid(parent, "Flood Simulation")
	
	parent.set_meta("type", "flood")
	parent.set_meta("terrain", terrain)
	parent.set_meta("water_sources", [Vector3i(10, 50, 10)])
	parent.set_meta("flow_rate", 0.08)

func create_ecosystem_ca(parent: Node3D):
	# Predator-prey ecosystem
	var grid = create_3d_grid(parent, "Ecosystem")
	
	# Create some visual ecosystem elements
	for i in range(10):
		var organism = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.05
		sphere_mesh.height = 0.1  # Fix elongated sphere
		organism.mesh = sphere_mesh
		organism.position = Vector3(
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5)
		)
		var org_material = StandardMaterial3D.new()
		if i < 7:  # Prey
			org_material.albedo_color = Color(0.2, 0.8, 0.2)
		else:  # Predators
			org_material.albedo_color = Color(0.8, 0.2, 0.2)
		organism.material_override = org_material
		parent.add_child(organism)
	
	parent.set_meta("type", "ecosystem")
	parent.set_meta("grid", grid)
	parent.set_meta("prey_birth_rate", 0.1)
	parent.set_meta("predator_death_rate", 0.05)
	parent.set_meta("hunt_success_rate", 0.3)

func create_disease_spread_ca(parent: Node3D):
	# Epidemic spread model (SIR)
	var population_grid = create_3d_grid(parent, "Disease Spread")
	
	# Create population visualization
	for i in range(30):
		var person = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.05, 0.1, 0.05)
		person.mesh = box_mesh
		person.position = Vector3(
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5)
		)
		var person_material = StandardMaterial3D.new()
		if i < 5:  # Initially infected
			person_material.albedo_color = Color(1.0, 0.2, 0.2)
		else:  # Susceptible
			person_material.albedo_color = Color(0.2, 0.8, 0.2)
		person.material_override = person_material
		parent.add_child(person)
	
	parent.set_meta("type", "disease")
	parent.set_meta("grid", population_grid)
	parent.set_meta("infection_rate", 0.2)
	parent.set_meta("recovery_rate", 0.1)
	parent.set_meta("initial_infected", 5)

func create_blood_flow_ca(parent: Node3D):
	# Lattice Boltzmann blood flow
	var vessel_network = create_vessel_network(parent)
	
	parent.set_meta("type", "blood_flow")
	parent.set_meta("vessels", vessel_network)
	parent.set_meta("viscosity", 0.004)
	parent.set_meta("pressure_gradient", 0.1)

func create_droplet_behavior_ca(parent: Node3D):
	# Surface tension and droplet dynamics
	var surface_grid = create_surface_grid(parent)
	
	# Add some droplets
	for i in range(5):
		var droplet = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.1 + randf() * 0.05
		sphere_mesh.height = sphere_mesh.radius * 2  # Fix elongated sphere
		droplet.mesh = sphere_mesh
		droplet.position = Vector3(
			randf_range(-1.0, 1.0),
			0.2,
			randf_range(-1.0, 1.0)
		)
		var droplet_material = StandardMaterial3D.new()
		droplet_material.albedo_color = Color(0.2, 0.6, 1.0, 0.8)
		droplet_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		droplet_material.emission_enabled = true
		droplet_material.emission = Color(0.1, 0.3, 0.5) * 0.3
		droplet.material_override = droplet_material
		parent.add_child(droplet)
	
	parent.set_meta("type", "droplet")
	parent.set_meta("surface", surface_grid)
	parent.set_meta("surface_tension", 0.7)
	parent.set_meta("contact_angle", 45.0)

func create_self_organization_ca(parent: Node3D):
	# Self-organizing patterns and emergence
	var grid = create_3d_grid(parent, "Self-Organization")
	
	# Create random initial pattern
	for i in range(20):
		var particle = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.03
		sphere_mesh.height = 0.06  # Fix elongated sphere
		particle.mesh = sphere_mesh
		particle.position = Vector3(
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5)
		)
		var particle_material = StandardMaterial3D.new()
		particle_material.albedo_color = Color(
			randf(), randf(), randf()
		)
		particle.material_override = particle_material
		parent.add_child(particle)
	
	parent.set_meta("type", "self_org")
	parent.set_meta("grid", grid)
	parent.set_meta("interaction_strength", 0.1)
	parent.set_meta("randomness", 0.05)

# Helper functions for grid creation
func create_3d_grid(parent: Node3D, label: String) -> Array:
	"""Create a visual 3D grid with animated spheres"""
	var cells = []  # Store actual sphere nodes for animation
	
	# Create visual representation using colorful animated spheres
	var multi_mesh_instance = MultiMeshInstance3D.new()
	var multi_mesh = MultiMesh.new()
	
	# Use spheres for a more organic look
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.08
	sphere_mesh.height = 0.16
	
	multi_mesh.mesh = sphere_mesh
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.use_colors = true  # Enable per-instance colors!
	multi_mesh.instance_count = GRID_SIZE * GRID_SIZE * GRID_SIZE
	
	# Initialize all instances
	var spacing = 0.15  # Grid spacing
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var index = x * GRID_SIZE * GRID_SIZE + y * GRID_SIZE + z
				var pos = Vector3(
					(x - GRID_SIZE/2.0) * spacing,
					(y - GRID_SIZE/2.0) * spacing,
					(z - GRID_SIZE/2.0) * spacing
				)
				# Start invisible (scale 0)
				var transform = Transform3D(Basis().scaled(Vector3(0.01, 0.01, 0.01)), pos)
				multi_mesh.set_instance_transform(index, transform)
				multi_mesh.set_instance_color(index, Color(1, 1, 1, 0))  # Transparent
	
	multi_mesh_instance.multimesh = multi_mesh
	parent.add_child(multi_mesh_instance)
	parent.set_meta("visual_multimesh", multi_mesh_instance)
	parent.set_meta("active_cells", [])  # Track active cells for animation
	
	return cells

func activate_cell(showcase: Node3D, x: int, y: int, z: int, color: Color):
	"""Activate a cell with a growing animation"""
	if not showcase.has_meta("visual_multimesh"):
		return
	
	var multi_mesh_instance = showcase.get_meta("visual_multimesh")
	if not multi_mesh_instance:
		return
	
	var multi_mesh = multi_mesh_instance.multimesh
	var spacing = 0.15
	var index = x * GRID_SIZE * GRID_SIZE + y * GRID_SIZE + z
	
	var pos = Vector3(
		(x - GRID_SIZE/2.0) * spacing,
		(y - GRID_SIZE/2.0) * spacing,
		(z - GRID_SIZE/2.0) * spacing
	)
	
	# Animate growth!
	var target_scale = 1.0 + randf() * 0.3  # Varied sizes
	var transform = Transform3D(Basis().scaled(Vector3(target_scale, target_scale, target_scale)), pos)
	multi_mesh.set_instance_transform(index, transform)
	multi_mesh.set_instance_color(index, color)
	
	# Track as active
	var active_cells = showcase.get_meta("active_cells")
	if not active_cells.has(Vector3i(x, y, z)):
		active_cells.append(Vector3i(x, y, z))

func create_2d_grid_on_platform(parent: Node3D, label: String) -> Array:
	var grid = []
	grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		grid[x] = []
		grid[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			grid[x][y] = 0
	
	return grid

func create_road_network(parent: Node3D) -> Array:
	var roads = []
	
	# Create simple road segments
	for i in range(3):
		var road = {
			"start": Vector3(-2, 0, -1 + i),
			"end": Vector3(2, 0, -1 + i),
			"cars": [],
			"speed_limit": 2
		}
		roads.append(road)
		
		# Visualize road
		var road_mesh = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(4, 0.1, 0.3)
		road_mesh.mesh = box_mesh
		road_mesh.position = Vector3(0, 0, -1 + i)
		road_mesh.material_override = StandardMaterial3D.new()
		road_mesh.material_override.albedo_color = Color(0.3, 0.3, 0.3)
		parent.add_child(road_mesh)
	
	return roads

func create_terrain_grid(parent: Node3D, label: String) -> Array:
	var terrain = []
	terrain.resize(GRID_SIZE)
	
	# Create terrain visualization
	for i in range(10):
		var terrain_chunk = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.3, randf() * 0.5, 0.3)
		terrain_chunk.mesh = box_mesh
		terrain_chunk.position = Vector3(
			randf_range(-1.5, 1.5),
			0,
			randf_range(-1.5, 1.5)
		)
		var terrain_material = StandardMaterial3D.new()
		terrain_material.albedo_color = Color(0.4, 0.3, 0.2)
		terrain_chunk.material_override = terrain_material
		parent.add_child(terrain_chunk)
	
	for x in range(GRID_SIZE):
		terrain[x] = []
		terrain[x].resize(GRID_SIZE)
		for z in range(GRID_SIZE):
			# Create height map with some variation
			var height = sin(x * 0.1) * cos(z * 0.1) * 5 + randf() * 2
			terrain[x][z] = {
				"height": height,
				"water_level": 0,
				"absorption": randf() * 0.1
			}
	
	return terrain

func create_vessel_network(parent: Node3D) -> Array:
	var vessels = []
	
	# Create branching vessel structure
	for i in range(5):
		var vessel = MeshInstance3D.new()
		var cylinder_mesh = CylinderMesh.new()
		cylinder_mesh.top_radius = 0.1 - i * 0.015
		cylinder_mesh.bottom_radius = 0.1 - i * 0.015
		cylinder_mesh.height = 2.0
		vessel.mesh = cylinder_mesh
		vessel.position = Vector3(sin(i) * 0.5, 0, cos(i) * 0.5)
		vessel.rotation.z = i * 0.3
		
		var vessel_material = StandardMaterial3D.new()
		vessel_material.albedo_color = Color(0.8, 0.2, 0.2, 0.7)
		vessel_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vessel.material_override = vessel_material
		
		parent.add_child(vessel)
		vessels.append(vessel)
	
	return vessels

func create_surface_grid(parent: Node3D) -> Array:
	var surface = []
	var surface_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(3, 0.1, 3)
	surface_mesh.mesh = box_mesh
	surface_mesh.material_override = StandardMaterial3D.new()
	surface_mesh.material_override.albedo_color = Color(0.4, 0.6, 0.8, 0.8)
	surface_mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	parent.add_child(surface_mesh)
	
	return surface

func start_showcase_cycle():
	print("VR CA Showcase initialized with ", SHOWCASE_COUNT, " demonstrations")
	highlight_current_showcase()

func _process(delta):
	transition_time += delta
	
	if auto_cycle and transition_time >= cycle_interval:
		cycle_to_next_showcase()
		transition_time = 0.0
	
	# Update only the currently visible showcase (non-blocking)
	update_current_showcase(delta)

func update_current_showcase(delta):
	"""Update only the currently visible showcase for better performance"""
	if current_showcase < 0 or current_showcase >= showcases.size():
		return
		
	var showcase = showcases[current_showcase]
	var ca_type = showcase.get_meta("type")
	
	match ca_type:
		"recrystallization":
			update_recrystallization(showcase, delta)
		"dendrite":
			update_dendrite_growth(showcase, delta)
		"percolation":
			update_percolation(showcase, delta)
		"crack":
			update_crack_propagation(showcase, delta)
		"avalanche":
			update_avalanche(showcase, delta)
		"traffic":
			update_traffic_flow(showcase, delta)
		"flood":
			update_flood_propagation(showcase, delta)
		"ecosystem":
			update_ecosystem(showcase, delta)
		"disease":
			update_disease_spread(showcase, delta)
		"blood_flow":
			update_blood_flow(showcase, delta)
		"droplet":
			update_droplet_behavior(showcase, delta)
		"self_org":
			update_self_organization(showcase, delta)

func update_all_showcases(delta):
	"""Legacy function - updates all showcases (more expensive)"""
	for i in range(showcases.size()):
		var showcase = showcases[i]
		var ca_type = showcase.get_meta("type")
		
		match ca_type:
			"recrystallization":
				update_recrystallization(showcase, delta)
			"dendrite":
				update_dendrite_growth(showcase, delta)
			"percolation":
				update_percolation(showcase, delta)
			"crack":
				update_crack_propagation(showcase, delta)
			"avalanche":
				update_avalanche(showcase, delta)
			"traffic":
				update_traffic_flow(showcase, delta)
			"flood":
				update_flood_propagation(showcase, delta)
			"ecosystem":
				update_ecosystem(showcase, delta)
			"disease":
				update_disease_spread(showcase, delta)
			"blood_flow":
				update_blood_flow(showcase, delta)
			"droplet":
				update_droplet_behavior(showcase, delta)
			"self_org":
				update_self_organization(showcase, delta)

func update_recrystallization(showcase: Node3D, delta):
	"""Growing crystals - Orange spheres expanding from centers"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	var nucleation_sites = showcase.get_meta("nucleation_sites")
	
	# Grow from active cells
	if active_cells.size() < 1000:  # Limit growth
		for site in nucleation_sites:
			if randf() < 5.0 * delta:  # Fast growth
				# Grow in random direction
				var direction = Vector3i(
					randi_range(-1, 1),
					randi_range(-1, 1),
					randi_range(-1, 1)
				)
				var new_pos = site + direction
				
				# Bounds check
				if new_pos.x >= 0 and new_pos.x < GRID_SIZE and \
				   new_pos.y >= 0 and new_pos.y < GRID_SIZE and \
				   new_pos.z >= 0 and new_pos.z < GRID_SIZE:
					# Activate with orange/gold color
					var color = Color(1.0, 0.6 + randf() * 0.4, 0.0)
					activate_cell(showcase, new_pos.x, new_pos.y, new_pos.z, color)

func update_dendrite_growth(showcase: Node3D, delta):
	"""Branching crystals - Blue/cyan tendrils"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	
	# Grow dendrites from existing cells
	if active_cells.size() < 800:
		for i in range(min(5, active_cells.size())):  # Multiple growth points
			var cell = active_cells[randi() % max(1, active_cells.size())]
			if randf() < 3.0 * delta:
				# Prefer growing in one direction (tendril-like)
				var direction = Vector3i(
					randi_range(-1, 1),
					randi_range(-2, 2),  # Prefer vertical
					randi_range(-1, 1)
				)
				var new_pos = cell + direction
				
				if new_pos.x >= 0 and new_pos.x < GRID_SIZE and \
				   new_pos.y >= 0 and new_pos.y < GRID_SIZE and \
				   new_pos.z >= 0 and new_pos.z < GRID_SIZE:
					var color = Color(0.2, 0.7 + randf() * 0.3, 1.0)  # Cyan/blue
					activate_cell(showcase, new_pos.x, new_pos.y, new_pos.z, color)

func update_percolation(showcase: Node3D, delta):
	"""Water flowing down - Green/aqua droplets"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	
	# Add new droplets at top and flow downward
	if active_cells.size() < 1200:
		# Add new drops at top
		if randf() < 8.0 * delta:
			var x = randi() % GRID_SIZE
			var z = randi() % GRID_SIZE
			var y = GRID_SIZE - 1  # Top
			var color = Color(0.0, 0.8 + randf() * 0.2, 0.8)
			activate_cell(showcase, x, y, z, color)
		
		# Flow downward from existing cells
		for cell in active_cells:
			if randf() < 2.0 * delta:
				var new_pos = cell + Vector3i(randi_range(-1, 1), -1, randi_range(-1, 1))  # Down
				if new_pos.y >= 0 and new_pos.x >= 0 and new_pos.x < GRID_SIZE and new_pos.z >= 0 and new_pos.z < GRID_SIZE:
					var color = Color(0.0, 0.7 + randf() * 0.3, 0.9)
					activate_cell(showcase, new_pos.x, new_pos.y, new_pos.z, color)

func update_crack_propagation(showcase: Node3D, delta):
	"""Cracks spreading - Red lightning bolts"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	if active_cells.size() < 600:
		for i in range(min(3, active_cells.size())):
			var cell = active_cells[randi() % max(1, active_cells.size())]
			if randf() < 4.0 * delta:
				var direction = Vector3i(randi_range(-2, 2), randi_range(-1, 1), randi_range(-2, 2))
				var new_pos = cell + direction
				if new_pos.x >= 0 and new_pos.x < GRID_SIZE and new_pos.y >= 0 and new_pos.y < GRID_SIZE and new_pos.z >= 0 and new_pos.z < GRID_SIZE:
					var color = Color(1.0, 0.1 + randf() * 0.2, 0.0)  # Red
					activate_cell(showcase, new_pos.x, new_pos.y, new_pos.z, color)

func update_avalanche(showcase: Node3D, delta):
	"""Sand avalanche - Yellow/brown particles falling"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	if active_cells.size() < 900:
		# Add sand at top
		if randf() < 6.0 * delta:
			var x = randi() % GRID_SIZE
			var z = randi() % GRID_SIZE
			var color = Color(1.0, 0.8 + randf() * 0.2, 0.2)  # Sandy
			activate_cell(showcase, x, GRID_SIZE-1, z, color)

func update_traffic_flow(showcase: Node3D, delta):
	"""Traffic - Moving white/yellow lights"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	if active_cells.size() < 400:
		if randf() < 10.0 * delta:
			var z = randi() % GRID_SIZE
			var color = Color(1.0, 1.0, randf() * 0.5)  # White/yellow
			activate_cell(showcase, GRID_SIZE/2, 0, z, color)

func update_flood_propagation(showcase: Node3D, delta):
	"""Flood spreading - Blue waves expanding outward"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	if active_cells.size() < 1000:
		for i in range(min(8, active_cells.size())):
			var cell = active_cells[randi() % max(1, active_cells.size())]
			if randf() < 3.0 * delta:
				var direction = Vector3i(randi_range(-1, 1), 0, randi_range(-1, 1))  # Horizontal spread
				var new_pos = cell + direction
				if new_pos.x >= 0 and new_pos.x < GRID_SIZE and new_pos.y >= 0 and new_pos.y < GRID_SIZE and new_pos.z >= 0 and new_pos.z < GRID_SIZE:
					var color = Color(0.0, 0.3 + randf() * 0.3, 1.0)  # Deep blue
					activate_cell(showcase, new_pos.x, new_pos.y, new_pos.z, color)

func update_ecosystem(showcase: Node3D, delta):
	"""Ecosystem - Green/brown organic growth"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	if active_cells.size() < 700:
		if randf() < 8.0 * delta:
			var x = randi() % GRID_SIZE
			var y = randi_range(0, GRID_SIZE/2)  # Bottom half
			var z = randi() % GRID_SIZE
			var color = Color(0.2 + randf() * 0.3, 0.8, 0.2)  # Green
			activate_cell(showcase, x, y, z, color)

func update_disease_spread(showcase: Node3D, delta):
	"""Disease - Purple/magenta infection spreading"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	if active_cells.size() < 800:
		for i in range(min(6, active_cells.size())):
			var cell = active_cells[randi() % max(1, active_cells.size())]
			if randf() < 4.0 * delta:
				var direction = Vector3i(randi_range(-1, 1), randi_range(-1, 1), randi_range(-1, 1))
				var new_pos = cell + direction
				if new_pos.x >= 0 and new_pos.x < GRID_SIZE and new_pos.y >= 0 and new_pos.y < GRID_SIZE and new_pos.z >= 0 and new_pos.z < GRID_SIZE:
					var color = Color(0.9, 0.1, 0.9 + randf() * 0.1)  # Magenta
					activate_cell(showcase, new_pos.x, new_pos.y, new_pos.z, color)

func update_blood_flow(showcase: Node3D, delta):
	"""Blood flow - Dark red pulsing"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	if active_cells.size() < 500:
		if randf() < 7.0 * delta:
			var pos = Vector3i(GRID_SIZE/2 + randi_range(-3, 3), randi() % GRID_SIZE, GRID_SIZE/2 + randi_range(-3, 3))
			if pos.x >= 0 and pos.x < GRID_SIZE and pos.z >= 0 and pos.z < GRID_SIZE:
				var color = Color(0.7 + randf() * 0.3, 0.0, 0.1)  # Dark red
				activate_cell(showcase, pos.x, pos.y, pos.z, color)

func update_droplet_behavior(showcase: Node3D, delta):
	"""Droplets - Silvery spheres forming and falling"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	if active_cells.size() < 300:
		if randf() < 12.0 * delta:
			var x = randi() % GRID_SIZE
			var z = randi() % GRID_SIZE
			var color = Color(0.8 + randf() * 0.2, 0.9 + randf() * 0.1, 1.0)  # Silver/white
			activate_cell(showcase, x, GRID_SIZE-1, z, color)

func update_self_organization(showcase: Node3D, delta):
	"""Self-organization - Rainbow spiral emerging from chaos"""
	if not showcase.has_meta("active_cells"):
		return
	var active_cells = showcase.get_meta("active_cells")
	if active_cells.size() < 1500:
		if randf() < 15.0 * delta:
			var angle = randf() * TAU
			var radius = randf() * GRID_SIZE * 0.4
			var x = int(GRID_SIZE/2 + cos(angle) * radius)
			var z = int(GRID_SIZE/2 + sin(angle) * radius)
			var y = randi() % GRID_SIZE
			if x >= 0 and x < GRID_SIZE and z >= 0 and z < GRID_SIZE:
				var color = Color.from_hsv(randf(), 0.8 + randf() * 0.2, 1.0)  # Rainbow
				activate_cell(showcase, x, y, z, color)

func cycle_to_next_showcase():
	current_showcase = (current_showcase + 1) % SHOWCASE_COUNT
	highlight_current_showcase()
	print("Switched to showcase: ", current_showcase, " - ", get_ca_name(current_showcase))

func highlight_current_showcase():
	# Hide all showcases except the current one
	for i in range(showcases.size()):
		showcases[i].visible = (i == current_showcase)
		info_panels[i].visible = (i == current_showcase)

func get_ca_name(index: int) -> String:
	var names = [
		"Recrystallization", "Dendrite Growth", "Percolation", "Crack Propagation",
		"Avalanche Model", "Traffic Flow", "Flood Propagation", "Ecosystem",
		"Disease Spread", "Blood Flow", "Droplet Behavior", "Self-Organization"
	]
	return names[index] if index < names.size() else "Unknown"

# Simplified CA update functions (implement detailed logic as needed)
func grow_crystal_at_site(grid: Array, site: Vector3i):
	# Implement crystal growth logic - expand from nucleation sites
	var neighbors = get_3d_neighbors(site)
	for neighbor in neighbors:
		if is_valid_3d_position(neighbor) and randf() < 0.1:
			grid[neighbor.x][neighbor.y][neighbor.z] = 1  # Crystal state

func add_dendrite_branch(grid: Array, center: Vector3i):
	# Implement dendrite branching - probabilistic growth
	var growth_directions = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	
	for direction in growth_directions:
		var new_pos = center + direction
		if is_valid_3d_position(new_pos) and randf() < 0.15:
			grid[new_pos.x][new_pos.y][new_pos.z] = 2  # Dendrite state

func percolate_fluid(grid: Array, rate: float):
	# Implement percolation logic - fluid flow through connected sites
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] == 1 and randf() < rate:  # If site is occupied and fluid can flow
					var neighbors = get_3d_neighbors(Vector3i(x, y, z))
					for neighbor in neighbors:
						if is_valid_3d_position(neighbor) and grid[neighbor.x][neighbor.y][neighbor.z] == 1:
							grid[neighbor.x][neighbor.y][neighbor.z] = 3  # Fluid state

func propagate_cracks(grid: Array, stress_points: Array, threshold: float):
	# Implement crack propagation from stress concentrators
	for stress_point in stress_points:
		var neighbors = get_3d_neighbors(stress_point)
		for neighbor in neighbors:
			if is_valid_3d_position(neighbor) and randf() < 0.05:
				grid[neighbor.x][neighbor.y][neighbor.z] = 4  # Cracked state

func add_sand_grain(grid: Array):
	# Add sand grain to random location
	var x = randi() % GRID_SIZE
	var y = randi() % GRID_SIZE
	grid[x][y] += 1

func check_avalanche_conditions(grid: Array, critical_slope: int):
	# Check for avalanche conditions and redistribute sand
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] >= critical_slope:
				# Avalanche occurs - redistribute to neighbors
				var excess = grid[x][y] - critical_slope + 1
				grid[x][y] = critical_slope - 1
				
				var neighbors = get_2d_neighbors(Vector2i(x, y))
				for neighbor in neighbors:
					if is_valid_2d_position(neighbor):
						grid[neighbor.x][neighbor.y] += excess / neighbors.size()

func update_traffic_on_roads(roads: Array, max_velocity: int):
	# Update traffic flow using cellular automaton rules
	for road in roads:
		var cars = road["cars"]
		# Simple traffic CA: move cars forward if space available
		for car in cars:
			if car["position"] < road["end"].x - 0.5:
				car["position"] += min(car["velocity"], max_velocity) * 0.1
			car["velocity"] = min(car["velocity"] + 1, max_velocity)

func propagate_flood_water(terrain: Array, sources: Array, rate: float):
	# Implement flood water spread across terrain
	for source in sources:
		if is_valid_2d_position(Vector2i(source.x, source.z)):
			terrain[source.x][source.z]["water_level"] += rate
			
			# Spread to lower neighbors
			var neighbors = get_2d_neighbors(Vector2i(source.x, source.z))
			for neighbor in neighbors:
				if is_valid_2d_position(neighbor):
					var height_diff = terrain[source.x][source.z]["height"] - terrain[neighbor.x][neighbor.y]["height"]
					if height_diff > 0:
						var water_flow = min(terrain[source.x][source.z]["water_level"] * 0.1, height_diff)
						terrain[source.x][source.z]["water_level"] -= water_flow
						terrain[neighbor.x][neighbor.y]["water_level"] += water_flow

func update_population_dynamics(grid: Array, birth_rate: float, death_rate: float):
	# Update ecosystem dynamics - predator-prey interactions
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var cell = grid[x][y][z]
				match cell:
					1:  # Prey
						if randf() < birth_rate:
							var neighbors = get_3d_neighbors(Vector3i(x, y, z))
							for neighbor in neighbors:
								if is_valid_3d_position(neighbor) and grid[neighbor.x][neighbor.y][neighbor.z] == 0:
									grid[neighbor.x][neighbor.y][neighbor.z] = 1  # New prey
									break
					2:  # Predator
						if randf() < death_rate:
							grid[x][y][z] = 0  # Die

func spread_disease(grid: Array, infection_rate: float, recovery_rate: float):
	# Implement SIR epidemic model
	var new_grid = duplicate_3d_grid(grid)
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var cell = grid[x][y][z]
				match cell:
					0:  # Susceptible
						var infected_neighbors = count_infected_neighbors(grid, Vector3i(x, y, z))
						if infected_neighbors > 0 and randf() < infection_rate:
							new_grid[x][y][z] = 1  # Become infected
					1:  # Infected
						if randf() < recovery_rate:
							new_grid[x][y][z] = 2  # Recover
					2:  # Recovered
						pass  # Immune
	
	# Update grid
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				grid[x][y][z] = new_grid[x][y][z]

func simulate_blood_flow(vessels: Array, viscosity: float):
	# Implement lattice Boltzmann flow simulation
	for vessel in vessels:
		# Simplified flow visualization - animate vessel materials
		var material = vessel.material_override as StandardMaterial3D
		var time_factor = Time.get_ticks_msec() * 0.001
		var flow_intensity = 0.5 + 0.3 * sin(time_factor * 2.0)
		material.emission = Color(0.8, 0.2, 0.2) * flow_intensity

func update_droplet_dynamics(surface: Array, tension: float):
	# Implement droplet behavior with surface tension
	# This would involve complex fluid dynamics - simplified here
	pass

func evolve_self_organization(grid: Array, interaction: float):
	# Implement self-organizing patterns
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var neighbors = get_3d_neighbors(Vector3i(x, y, z))
				var neighbor_sum = 0
				for neighbor in neighbors:
					if is_valid_3d_position(neighbor):
						neighbor_sum += grid[neighbor.x][neighbor.y][neighbor.z]
				
				# Self-organization rule: become similar to neighbors
				var avg_neighbor = float(neighbor_sum) / neighbors.size()
				grid[x][y][z] = int(grid[x][y][z] * (1.0 - interaction) + avg_neighbor * interaction)

# Helper functions for neighbor detection and validation
func get_3d_neighbors(pos: Vector3i) -> Array:
	var neighbors = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				if dx == 0 and dy == 0 and dz == 0:
					continue
				neighbors.append(Vector3i(pos.x + dx, pos.y + dy, pos.z + dz))
	return neighbors

func get_2d_neighbors(pos: Vector2i) -> Array:
	var neighbors = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			neighbors.append(Vector2i(pos.x + dx, pos.y + dy))
	return neighbors

func is_valid_3d_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE and pos.z >= 0 and pos.z < GRID_SIZE

func is_valid_2d_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

func duplicate_3d_grid(grid: Array) -> Array:
	var new_grid = []
	new_grid.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		new_grid[x] = []
		new_grid[x].resize(GRID_SIZE)
		for y in range(GRID_SIZE):
			new_grid[x][y] = grid[x][y].duplicate()
	
	return new_grid

func count_infected_neighbors(grid: Array, pos: Vector3i) -> int:
	var count = 0
	var neighbors = get_3d_neighbors(pos)
	for neighbor in neighbors:
		if is_valid_3d_position(neighbor) and grid[neighbor.x][neighbor.y][neighbor.z] == 1:
			count += 1
	return count

# VR Interaction handlers
func on_vr_controller_input(controller_id: int, input_type: String):
	if input_type == "trigger_pressed":
		cycle_to_next_showcase()
	elif input_type == "grip_pressed":
		auto_cycle = not auto_cycle
		print("Auto-cycle: ", auto_cycle)

func _input(event):
	"""Handle keyboard input for testing and control"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				cycle_to_next_showcase()
			KEY_A:
				auto_cycle = not auto_cycle
				print("Auto-cycle: ", auto_cycle)
			KEY_R:
				reset_all_showcases()
				print("Reset all showcases")
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				var target_showcase = event.keycode - KEY_1
				if target_showcase < SHOWCASE_COUNT:
					current_showcase = target_showcase
					highlight_current_showcase()
					print("Switched to showcase: ", get_ca_name(current_showcase))
			KEY_PLUS, KEY_EQUAL:
				cycle_interval = max(5.0, cycle_interval - 2.0)
				print("Cycle interval: ", cycle_interval, " seconds")
			KEY_MINUS:
				cycle_interval = min(60.0, cycle_interval + 2.0)
				print("Cycle interval: ", cycle_interval, " seconds")
			KEY_H:
				print_help()

# Public method to focus on specific CA type
func focus_on_ca_type(ca_type: CAType):
	current_showcase = ca_type as int
	highlight_current_showcase()
	transition_time = 0.0

# Debug and analysis methods
func get_showcase_statistics() -> Dictionary:
	var stats = {}
	for i in range(showcases.size()):
		var showcase = showcases[i]
		var ca_type = showcase.get_meta("type")
		stats[ca_type] = {
			"active": i == current_showcase,
			"position": showcase.position,
			"name": get_ca_name(i)
		}
	return stats

func reset_all_showcases():
	# Reset all CA systems to initial state
	var central_position = Vector3(0, 0, 0)
	
	for i in range(showcases.size()):
		var showcase = showcases[i]
		var ca_type = i as CAType
		
		# Clear existing showcase
		for child in showcase.get_children():
			child.queue_free()
		
		# Recreate with fresh parameters at central position
		create_ca_showcase(ca_type, central_position)

func set_auto_cycle_interval(seconds: float):
	cycle_interval = max(5.0, seconds)  # Minimum 5 seconds
	print("Auto-cycle interval set to: ", cycle_interval, " seconds")

func print_help():
	"""Print help information for controls"""
	print("=== CA Showcase Controls ===")
	print("SPACE - Cycle to next showcase")
	print("A - Toggle auto-cycle")
	print("R - Reset all showcases")
	print("1-9 - Jump to specific showcase")
	print("+/- - Adjust cycle interval")
	print("H - Show this help")
	print("")
	print("Current showcase: ", get_ca_name(current_showcase))
	print("Auto-cycle: ", auto_cycle)
	print("Cycle interval: ", cycle_interval, " seconds")

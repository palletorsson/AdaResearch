extends Node3D
class_name WorthingtonSplashStudy

# Professor A. M. Worthington's Mercury Drop Splash Study (1895)
# "The Splash of a Drop" - Revolutionary high-speed photography

@export var page_scale: float = 1.0
@export var animation_speed: float = 1.0
@export var show_scientific_labels: bool = true
@export var paper_color: Color = Color(0.94, 0.91, 0.86, 1)
@export var ink_color: Color = Color(0.15, 0.12, 0.1, 1)
@export var mercury_color: Color = Color(0.05, 0.05, 0.08, 1)

var paper_material: StandardMaterial3D
var ink_material: StandardMaterial3D
var mercury_material: StandardMaterial3D
var splash_materials: Array[StandardMaterial3D] = []

# Splash sequence data based on Worthington's observations
var splash_sequence = [
	# Stage 1: Initial impact (t = 0)
	{
		"time": 0,
		"diameter": 4.33,  # mm as recorded
		"shape": "solid_circle",
		"crown_height": 0,
		"droplets": [],
		"label": "1\nActual size, 4.33 mm.\nin diameter."
	},
	# Stage 2: Initial deformation (t = 0 sec)
	{
		"time": 0.001,
		"diameter": 6.0,
		"shape": "jagged_circle",
		"crown_height": 0,
		"droplets": [],
		"label": "2\n\nτ = 0 sec."
	},
	# Stage 3: Crown formation with spikes
	{
		"time": 0.002,
		"diameter": 7.5,
		"shape": "crown_with_spikes",
		"crown_height": 2.0,
		"droplets": [],
		"label": "3"
	},
	# Stage 4: Crown with droplet formation
	{
		"time": 0.003,
		"diameter": 8.0,
		"shape": "crown_with_droplets",
		"crown_height": 3.0,
		"droplets": [
			{"angle": 0, "distance": 4.0, "size": 0.3},
			{"angle": 45, "distance": 4.2, "size": 0.25},
			{"angle": 90, "distance": 4.5, "size": 0.4},
			{"angle": 135, "distance": 4.3, "size": 0.2},
			{"angle": 180, "distance": 4.1, "size": 0.35},
			{"angle": 225, "distance": 4.4, "size": 0.3},
			{"angle": 270, "distance": 4.6, "size": 0.25},
			{"angle": 315, "distance": 4.2, "size": 0.3}
		],
		"label": "4\n\n\nτ = .003 sec."
	},
	# Stage 4A: Alternative crown pattern
	{
		"time": 0.003,
		"diameter": 8.0,
		"shape": "crown_with_droplets",
		"crown_height": 2.8,
		"droplets": [
			{"angle": 30, "distance": 4.2, "size": 0.28},
			{"angle": 75, "distance": 4.4, "size": 0.32},
			{"angle": 120, "distance": 4.0, "size": 0.25},
			{"angle": 165, "distance": 4.3, "size": 0.3},
			{"angle": 210, "distance": 4.5, "size": 0.35},
			{"angle": 255, "distance": 4.1, "size": 0.22},
			{"angle": 300, "distance": 4.4, "size": 0.3},
			{"angle": 345, "distance": 4.2, "size": 0.25}
		],
		"label": "4A"
	}
]

func _ready():
	setup_materials()
	create_scientific_page()
	create_title_header()
	create_splash_sequence()
	setup_period_lighting()
	if animation_speed > 0:
		animate_splash_sequence()

func setup_materials():
	# Victorian paper material
	paper_material = StandardMaterial3D.new()
	paper_material.albedo_color = paper_color
	paper_material.roughness = 0.9
	paper_material.metallic = 0.0
	
	# Period ink material
	ink_material = StandardMaterial3D.new()
	ink_material.albedo_color = ink_color
	ink_material.roughness = 0.8
	ink_material.metallic = 0.0
	
	# Mercury material (highly reflective)
	mercury_material = StandardMaterial3D.new()
	mercury_material.albedo_color = mercury_color
	mercury_material.metallic = 0.9
	mercury_material.roughness = 0.1
	mercury_material.emission_enabled = false
	
	# Create variations for different splash intensities
	for i in range(5):
		var splash_mat = mercury_material.duplicate()
		var intensity = 1.0 - (i * 0.15)
		splash_mat.albedo_color = mercury_color * intensity
		splash_materials.append(splash_mat)

func create_scientific_page():
	var page = StaticBody3D.new()
	page.name = "ScientificPage"
	add_child(page)
	
	var page_mesh = MeshInstance3D.new()
	page_mesh.name = "PageBackground"
	page_mesh.transform.basis = page_mesh.transform.basis.rotated(Vector3.RIGHT, -PI/2)
	page_mesh.position.y = -0.01
	
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(8, 12) * page_scale
	page_mesh.mesh = quad_mesh
	page_mesh.material_override = paper_material
	
	page.add_child(page_mesh)

func create_title_header():
	var header = Node3D.new()
	header.name = "TitleHeader"
	header.position = Vector3(0, 0.005, 4.5 * page_scale)
	add_child(header)
	
	# Series title
	var series_label = Label3D.new()
	series_label.text = "SERIES XI."
	series_label.position = Vector3(0, 0, 0.8)
	series_label.font_size = int(24 * page_scale)
	series_label.modulate = ink_color
	header.add_child(series_label)
	
	# Subtitle
	var subtitle_label = Label3D.new()
	subtitle_label.text = "(2) Instantaneous Shadow Photographs (life size) of the Splash of\na Drop of Mercury falling 15 cm. on to Glass."
	subtitle_label.position = Vector3(0, 0, 0.4)
	subtitle_label.font_size = int(16 * page_scale)
	subtitle_label.modulate = ink_color
	header.add_child(subtitle_label)

func create_splash_sequence():
	var sequence_group = Node3D.new()
	sequence_group.name = "SplashSequence"
	add_child(sequence_group)
	
	# Positions for the 5 splash stages (matching the original layout)
	var positions = [
		Vector3(0, 0, 2.5 * page_scale),      # Stage 1 - top center
		Vector3(0, 0, 1.0 * page_scale),      # Stage 2 - middle center
		Vector3(0, 0, -0.8 * page_scale),     # Stage 3 - lower center
		Vector3(-1.5 * page_scale, 0, -2.8 * page_scale),  # Stage 4 - bottom left
		Vector3(1.5 * page_scale, 0, -2.8 * page_scale)    # Stage 4A - bottom right
	]
	
	for i in range(splash_sequence.size()):
		var stage_data = splash_sequence[i]
		var stage_group = Node3D.new()
		stage_group.name = "SplashStage" + str(i + 1)
		stage_group.position = positions[i]
		sequence_group.add_child(stage_group)
		
		create_splash_stage(stage_group, stage_data, i)

func create_splash_stage(parent: Node3D, stage_data: Dictionary, stage_index: int):
	var diameter = stage_data["diameter"]
	var shape = stage_data["shape"]
	var crown_height = stage_data["crown_height"]
	var droplets = stage_data["droplets"]
	var label = stage_data["label"]
	
	match shape:
		"solid_circle":
			create_solid_circle(parent, diameter)
		"jagged_circle":
			create_jagged_circle(parent, diameter)
		"crown_with_spikes":
			create_crown_with_spikes(parent, diameter, crown_height)
		"crown_with_droplets":
			create_crown_with_droplets(parent, diameter, crown_height, droplets)
	
	# Add scientific label
	if show_scientific_labels:
		var stage_label = Label3D.new()
		stage_label.text = label
		stage_label.position = Vector3(0, 0.01, -diameter * 0.8 * page_scale)
		stage_label.font_size = int(12 * page_scale)
		stage_label.modulate = ink_color
		parent.add_child(stage_label)

func create_solid_circle(parent: Node3D, diameter: float):
	var circle = MeshInstance3D.new()
	circle.name = "MercuryDrop"
	circle.position.y = 0.002
	
	var circle_mesh = CylinderMesh.new()
	circle_mesh.height = 0.004
	circle_mesh.top_radius = (diameter * 0.5) * page_scale * 0.1  # Convert mm to scene units
	circle_mesh.bottom_radius = circle_mesh.top_radius
	
	circle.mesh = circle_mesh
	circle.material_override = mercury_material
	parent.add_child(circle)

func create_jagged_circle(parent: Node3D, diameter: float):
	var base_radius = (diameter * 0.5) * page_scale * 0.1
	
	# Create main circle
	create_solid_circle(parent, diameter * 0.8)
	
	# Add jagged edges using small spikes
	var jagged_group = Node3D.new()
	jagged_group.name = "JaggedEdges"
	parent.add_child(jagged_group)
	
	var spike_count = 16
	for i in range(spike_count):
		var angle = (i / float(spike_count)) * TAU
		var spike_distance = base_radius * randf_range(0.9, 1.1)
		var spike_pos = Vector3(
			cos(angle) * spike_distance,
			0.002,
			sin(angle) * spike_distance
		)
		
		var spike = MeshInstance3D.new()
		spike.position = spike_pos
		var spike_mesh = BoxMesh.new()
		spike_mesh.size = Vector3(0.002, 0.004, 0.008) * page_scale
		spike.mesh = spike_mesh
		spike.material_override = mercury_material
		jagged_group.add_child(spike)

func create_crown_with_spikes(parent: Node3D, diameter: float, crown_height: float):
	var base_radius = (diameter * 0.5) * page_scale * 0.1
	var height = crown_height * page_scale * 0.1
	
	# Central crown ring
	var crown = MeshInstance3D.new()
	crown.name = "Crown"
	crown.position.y = 0.002
	
	var crown_mesh = CylinderMesh.new()
	crown_mesh.height = 0.004
	crown_mesh.top_radius = base_radius * 0.6
	crown_mesh.bottom_radius = base_radius * 0.8
	crown.mesh = crown_mesh
	crown.material_override = mercury_material
	parent.add_child(crown)
	
	# Spikes radiating outward
	var spike_group = Node3D.new()
	spike_group.name = "CrownSpikes"
	parent.add_child(spike_group)
	
	var spike_count = 24
	for i in range(spike_count):
		var angle = (i / float(spike_count)) * TAU
		var spike_length = randf_range(0.15, 0.25) * page_scale
		var spike_base_pos = Vector3(
			cos(angle) * base_radius,
			0.002,
			sin(angle) * base_radius
		)
		var spike_tip_pos = spike_base_pos + Vector3(
			cos(angle) * spike_length,
			height * randf_range(0.5, 1.0),
			sin(angle) * spike_length
		)
		
		create_spike_line(spike_group, spike_base_pos, spike_tip_pos, i)

func create_crown_with_droplets(parent: Node3D, diameter: float, crown_height: float, droplets: Array):
	# Create the crown base
	create_crown_with_spikes(parent, diameter, crown_height)
	
	# Add surrounding droplets
	var droplet_group = Node3D.new()
	droplet_group.name = "SurroundingDroplets"
	parent.add_child(droplet_group)
	
	for droplet_data in droplets:
		var angle = deg_to_rad(droplet_data["angle"])
		var distance = droplet_data["distance"] * page_scale * 0.1
		var size = droplet_data["size"] * page_scale * 0.1
		
		var droplet_pos = Vector3(
			cos(angle) * distance,
			0.003,
			sin(angle) * distance
		)
		
		var droplet = MeshInstance3D.new()
		droplet.position = droplet_pos
		
		var droplet_mesh = SphereMesh.new()
		droplet_mesh.radius = size
		droplet_mesh.height = size * 1.5
		droplet.mesh = droplet_mesh
		droplet.material_override = splash_materials[randi() % splash_materials.size()]
		
		droplet_group.add_child(droplet)
		
		# Add connecting jets/streams
		var crown_edge_pos = Vector3(
			cos(angle) * (diameter * 0.4) * page_scale * 0.1,
			0.004,
			sin(angle) * (diameter * 0.4) * page_scale * 0.1
		)
		create_mercury_stream(droplet_group, crown_edge_pos, droplet_pos)

func create_spike_line(parent: Node3D, start_pos: Vector3, end_pos: Vector3, index: int):
	var spike = MeshInstance3D.new()
	spike.name = "Spike" + str(index)
	
	var direction = (end_pos - start_pos)
	var length = direction.length()
	var center = (start_pos + end_pos) / 2
	
	spike.position = center
	spike.look_at(center + direction.normalized(), Vector3.UP)
	
	var spike_mesh = BoxMesh.new()
	spike_mesh.size = Vector3(0.001, 0.001, length) * page_scale
	spike.mesh = spike_mesh
	spike.material_override = mercury_material
	
	parent.add_child(spike)

func create_mercury_stream(parent: Node3D, start_pos: Vector3, end_pos: Vector3):
	var stream = MeshInstance3D.new()
	stream.name = "MercuryStream"
	
	var direction = (end_pos - start_pos)
	var length = direction.length()
	var center = (start_pos + end_pos) / 2
	
	stream.position = center
	stream.look_at(center + direction.normalized(), Vector3.UP)
	
	var stream_mesh = BoxMesh.new()
	stream_mesh.size = Vector3(0.0005, 0.0005, length) * page_scale
	stream.mesh = stream_mesh
	stream.material_override = mercury_material
	
	parent.add_child(stream)

func setup_period_lighting():
	var lighting = Node3D.new()
	lighting.name = "ScientificLighting"
	add_child(lighting)
	
	# Main directional light simulating laboratory conditions
	var main_light = DirectionalLight3D.new()
	main_light.name = "LaboratoryLight"
	main_light.position = Vector3(2, 4, 2) * page_scale
	main_light.look_at(Vector3.ZERO, Vector3.UP)
	main_light.light_energy = 1.2
	main_light.light_color = Color(1, 0.95, 0.85, 1)  # Warm incandescent light
	main_light.shadow_enabled = true
	lighting.add_child(main_light)
	
	# Side light for mercury reflections
	var side_light = OmniLight3D.new()
	side_light.name = "MercuryReflectionLight"
	side_light.position = Vector3(-1, 1, 0) * page_scale
	side_light.light_energy = 0.8
	side_light.light_color = Color(0.9, 0.95, 1, 1)  # Cooler light for metallic reflections
	side_light.omni_range = 5.0 * page_scale
	lighting.add_child(side_light)
	
	# Environment setup
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = paper_color
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.9, 0.87, 0.8, 1)
	environment.ambient_light_energy = 0.4
	world_env.environment = environment
	add_child(world_env)

func animate_splash_sequence():
	if animation_speed <= 0:
		return
	
	var sequence_group = get_node_or_null("SplashSequence")
	if not sequence_group:
		return
	
	# Initially hide all stages except the first
	for i in range(1, sequence_group.get_child_count()):
		var stage = sequence_group.get_child(i)
		set_node_transparency(stage, 0.0)
	
	# Animate sequence progression
	var tween = create_tween()
	var delay = 0.0
	var stage_duration = 2.0 / animation_speed
	
	for i in range(1, sequence_group.get_child_count()):
		delay += stage_duration
		var stage = sequence_group.get_child(i)
		# Use custom transparency animation for 3D nodes
		tween.parallel().tween_method(
			func(alpha): set_node_transparency(stage, alpha),
			0.0, 1.0, 0.5
		).set_delay(delay)
		
		# Add some dynamic motion to droplets
		if i >= 3:  # Stages with droplets
			animate_droplet_motion(stage, delay)

func animate_droplet_motion(stage: Node3D, start_delay: float):
	var droplet_group = stage.get_node_or_null("SurroundingDroplets")
	if not droplet_group:
		return
	
	var tween = create_tween()
	
	for child in droplet_group.get_children():
		if child.name.begins_with("MercuryStream"):
			continue
			
		var original_pos = child.position
		var motion_amplitude = 0.02 * page_scale
		
		# Add subtle oscillation to simulate the dynamic nature of the splash
		tween.parallel().tween_method(
			func(offset): child.position = original_pos + Vector3(0, sin(offset) * motion_amplitude, 0),
			0.0, TAU, 2.0
		).set_delay(start_delay) 

# Scientific measurement functions
func get_splash_diameter(stage_index: int) -> float:
	if stage_index >= 0 and stage_index < splash_sequence.size():
		return splash_sequence[stage_index]["diameter"]
	return 0.0

func get_splash_time(stage_index: int) -> float:
	if stage_index >= 0 and stage_index < splash_sequence.size():
		return splash_sequence[stage_index]["time"]
	return 0.0

# Educational interaction
func highlight_stage(stage_index: int):
	var sequence_group = get_node_or_null("SplashSequence")
	if not sequence_group or stage_index >= sequence_group.get_child_count():
		return
	
	# Dim all other stages
	for i in range(sequence_group.get_child_count()):
		var stage = sequence_group.get_child(i)
		if i == stage_index:
			set_node_brightness(stage, 1.0)
		else:
			set_node_brightness(stage, 0.5)

func reset_highlighting():
	var sequence_group = get_node_or_null("SplashSequence")
	if not sequence_group:
		return
	
	for stage in sequence_group.get_children():
		set_node_brightness(stage, 1.0)

# Helper functions for 3D node transparency and brightness control
func set_node_transparency(node: Node3D, alpha: float):
	# For 3D nodes, we need to modify materials instead of modulate
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			if mesh_instance.material_override:
				var material = mesh_instance.material_override
				if material is StandardMaterial3D:
					var std_material = material as StandardMaterial3D
					# Clone material to avoid affecting other instances
					var new_material = std_material.duplicate()
					var current_color = new_material.albedo_color
					new_material.albedo_color = Color(current_color.r, current_color.g, current_color.b, alpha)
					if alpha < 1.0:
						new_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mesh_instance.material_override = new_material
		elif child is Node3D:
			# Recursively handle child 3D nodes
			set_node_transparency(child, alpha)

func set_node_brightness(node: Node3D, brightness: float):
	# For 3D nodes, we adjust material brightness instead of modulate
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			if mesh_instance.material_override:
				var material = mesh_instance.material_override
				if material is StandardMaterial3D:
					var std_material = material as StandardMaterial3D
					# Clone material to avoid affecting other instances
					var new_material = std_material.duplicate()
					var base_color = new_material.albedo_color
					# Adjust brightness by multiplying RGB values
					new_material.albedo_color = Color(
						base_color.r * brightness,
						base_color.g * brightness, 
						base_color.b * brightness,
						base_color.a
					)
					mesh_instance.material_override = new_material
		elif child is Node3D:
			# Recursively handle child 3D nodes
			set_node_brightness(child, brightness)

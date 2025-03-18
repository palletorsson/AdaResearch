extends Node3D

# Ada Research: Resonance Frequencies Visualizer
# This script creates a 3D visualization of resonance frequencies and standing waves

@export_category("Simulation Parameters")
@export var base_frequency: float = 1.0
@export var num_harmonics: int = 5
@export var amplitude: float = 1.0
@export var decay_factor: float = 0.7
@export var visualization_mode: int = 0  # 0 = String, 1 = Membrane, 2 = 3D Field
@export var time_scale: float = 1.0

@export_category("String/Membrane Parameters")
@export var grid_size: Vector2i = Vector2i(40, 40)
@export var membrane_subdivisions: int = 40
@export var string_points: int = 100
@export var string_length: float = 10.0
@export var string_width: float = 0.1

@export_category("Visualization")
@export var draw_debug_info: bool = true
@export var show_node_positions: bool = false
@export var color_by_amplitude: bool = true
@export var wave_color: Color = Color(0.0, 0.7, 1.0)
@export var line_thickness: float = 3.0

# Internal variables
var time: float = 0.0
var harmonics: Array = []
var mesh_instance: MeshInstance3D
var line_renderer: ImmediateMesh
var nodes: Array = []
var node_positions: Array = []
var debug_label: Label3D
var resonance_nodes: Array = []

class Harmonic:
	var frequency: float
	var phase: float
	var amplitude: float
	
	func _init(f: float, p: float, a: float):
		frequency = f
		phase = p
		amplitude = a
	
	func value(t: float) -> float:
		return amplitude * sin(2.0 * PI * frequency * t + phase)

func _ready():
	# Initialize harmonics
	initialize_harmonics()
	
	# Create visualization based on mode
	match visualization_mode:
		0:
			create_string_visualization()
		1:
			create_membrane_visualization()
		2:
			create_3d_field_visualization()
	
	# Create debug info
	if draw_debug_info:
		create_debug_label()
	
	# Create resonance nodes
	create_resonance_nodes()

func _process(delta):
	time += delta * time_scale
	
	# Update visualization based on mode
	match visualization_mode:
		0:
			update_string_visualization()
		1:
			update_membrane_visualization()
		2:
			update_3d_field_visualization()
	
	# Update debug info
	if draw_debug_info:
		update_debug_info()
	
	# Update resonance nodes
	update_resonance_nodes()

func initialize_harmonics():
	harmonics.clear()
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Create harmonics with decreasing amplitude
	for i in range(num_harmonics):
		var freq = base_frequency * (i + 1)
		var phase = rng.randf_range(0, 2 * PI)
		var ampl = amplitude * pow(decay_factor, i)
		
		harmonics.append(Harmonic.new(freq, phase, ampl))

func get_combined_amplitude(t: float) -> float:
	var value = 0.0
	
	for harmonic in harmonics:
		value += harmonic.value(t)
	
	return value

func get_combined_amplitude_at(t: float, x: float, mode: int = 1) -> float:
	var value = 0.0
	
	# Normalized position from 0 to 1
	var normalized_pos = x / string_length
	
	for i in range(harmonics.size()):
		# Different modes for different wave patterns
		var spatial_factor = 0.0
		match mode:
			0:  # Fundamental mode
				spatial_factor = sin(PI * normalized_pos)
			1:  # Regular harmonics
				spatial_factor = sin((i + 1) * PI * normalized_pos)
			2:  # Bessel function approximation
				spatial_factor = sin((i + 1) * PI * normalized_pos * normalized_pos)
		
		value += harmonics[i].amplitude * sin(2.0 * PI * harmonics[i].frequency * t + harmonics[i].phase) * spatial_factor
	
	return value

func get_membrane_amplitude(t: float, x: float, y: float) -> float:
	var value = 0.0
	
	# Normalized positions from 0 to 1
	var nx = x / string_length
	var ny = y / string_length
	
	for i in range(harmonics.size()):
		for j in range(harmonics.size()):
			# 2D standing wave pattern
			var spatial_factor = sin((i + 1) * PI * nx) * sin((j + 1) * PI * ny)
			var harm_idx = min(i + j, harmonics.size() - 1)
			
			value += harmonics[harm_idx].amplitude * 0.5 * sin(2.0 * PI * harmonics[harm_idx].frequency * t + harmonics[harm_idx].phase) * spatial_factor
	
	return value

# STRING VISUALIZATION FUNCTIONS
func create_string_visualization():
	# Create line renderer for the string
	line_renderer = ImmediateMesh.new()
	var line_instance = MeshInstance3D.new()
	line_instance.name = "StringLine"
	line_instance.mesh = line_renderer
	
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	line_instance.material_override = material
	
	add_child(line_instance)
	
	# Create node visualizations if enabled
	if show_node_positions:
		create_node_visualizations()

func update_string_visualization():
	# Clear previous line
	line_renderer.clear_surfaces()
	
	# Begin drawing the line
	line_renderer.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	# Calculate points along the string
	for i in range(string_points + 1):
		var x = (float(i) / string_points) * string_length - string_length / 2
		var amplitude = get_combined_amplitude_at(time, x + string_length / 2)
		
		# Create vertex
		var color_val = (amplitude / (amplitude * 2.0)) + 0.5
		var vertex_color = wave_color
		
		if color_by_amplitude:
			# Blend between blue and red based on amplitude
			vertex_color = wave_color.lerp(Color(1.0, 0.2, 0.2), abs(amplitude) / (amplitude * 2.0))
		
		line_renderer.surface_set_color(vertex_color)
		line_renderer.surface_add_vertex(Vector3(x, amplitude, 0))
	
	# End drawing the line
	line_renderer.surface_end()
	
	# Update node positions if enabled
	if show_node_positions:
		update_node_positions()

func create_node_visualizations():
	nodes.clear()
	
	# Create a small sphere for each node
	for i in range(num_harmonics + 1):
		var node_instance = MeshInstance3D.new()
		node_instance.name = "Node_" + str(i)
		
		var sphere = SphereMesh.new()
		sphere.radius = 0.1
		sphere.height = 0.2
		node_instance.mesh = sphere
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.5, 0.0)  # Orange
		material.emission_enabled = true
		material.emission = Color(1.0, 0.5, 0.0)
		material.emission_energy_multiplier = 2.0
		node_instance.material_override = material
		
		node_instance.visible = false  # Hide initially
		add_child(node_instance)
		nodes.append(node_instance)

func update_node_positions():
	# Calculate the positions of nodes (points of zero amplitude)
	node_positions.clear()
	
	# Calculate positions of nodes (zero points) for the 1st harmonic
	for i in range(1, num_harmonics + 1):
		for j in range(1, i + 1):
			var normalized_pos = float(j) / (i + 1)
			var x = normalized_pos * string_length - string_length / 2
			node_positions.append(x)
	
	# Update the positions of node visualizations
	for i in range(min(nodes.size(), node_positions.size())):
		var x = node_positions[i]
		nodes[i].position = Vector3(x, 0, 0)
		nodes[i].visible = true

# MEMBRANE VISUALIZATION FUNCTIONS
func create_membrane_visualization():
	# Create a mesh for the membrane
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MembraneMesh"
	add_child(mesh_instance)
	
	# Set up material
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	mesh_instance.material_override = material
	
	# Create initial mesh
	update_membrane_visualization()

func update_membrane_visualization():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Calculate size of each grid cell
	var cell_size = string_length / membrane_subdivisions
	
	# Generate the grid of vertices
	for x in range(membrane_subdivisions + 1):
		for y in range(membrane_subdivisions + 1):
			var pos_x = x * cell_size - string_length / 2
			var pos_y = y * cell_size - string_length / 2
			
			var amplitude = get_membrane_amplitude(time, x * cell_size, y * cell_size)
			
			var vertex_position = Vector3(pos_x, amplitude, pos_y)
			
			# Set color based on amplitude
			var color_value = (amplitude + amplitude * 2.0) / (amplitude * 4.0) + 0.5
			var vertex_color = wave_color
			
			if color_by_amplitude:
				vertex_color = wave_color.lerp(Color(1.0, 0.2, 0.2), abs(amplitude) / 2.0)
			
			surface_tool.set_color(vertex_color)
			surface_tool.set_normal(Vector3(0, 1, 0))
			surface_tool.add_vertex(vertex_position)
	
	# Generate triangles
	for x in range(membrane_subdivisions):
		for y in range(membrane_subdivisions):
			var i00 = x * (membrane_subdivisions + 1) + y
			var i10 = (x + 1) * (membrane_subdivisions + 1) + y
			var i11 = (x + 1) * (membrane_subdivisions + 1) + (y + 1)
			var i01 = x * (membrane_subdivisions + 1) + (y + 1)
			
			# First triangle
			surface_tool.add_index(i00)
			surface_tool.add_index(i10)
			surface_tool.add_index(i11)
			
			# Second triangle
			surface_tool.add_index(i00)
			surface_tool.add_index(i11)
			surface_tool.add_index(i01)
	
	# Generate normals
	surface_tool.generate_normals()
	
	# Create the mesh
	var mesh = surface_tool.commit()
	mesh_instance.mesh = mesh

# 3D FIELD VISUALIZATION FUNCTIONS
func create_3d_field_visualization():
	# For 3D visualization, we'll use particles
	var particles = GPUParticles3D.new()
	particles.name = "ResonanceParticles"
	particles.amount = 1000
	particles.lifetime = 2.0
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.randomness = 1.0
	
	var process_material = ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(string_length/2, string_length/2, string_length/2)
	process_material.gravity = Vector3(0, 0, 0)
	process_material.color = wave_color
	
	particles.process_material = process_material
	
	# Simple quad mesh for particles
	var particle_mesh = QuadMesh.new()
	particle_mesh.size = Vector2(0.1, 0.1)
	
	var mesh_material = StandardMaterial3D.new()
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.vertex_color_use_as_albedo = true
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh_material.billboard_keep_scale = true
	
	particle_mesh.material = mesh_material
	
	particles.draw_pass_1 = particle_mesh
	
	add_child(particles)
	
	# Store the particles node for later updates
	mesh_instance = particles

func update_3d_field_visualization():
	# For 3D field visualization, we mainly rely on the particle system
	# However, we can update properties based on current time
	
	if mesh_instance and mesh_instance is MeshInstance3D:
		var particles = mesh_instance as MeshInstance3D
		
		# Get the process material
		var process_material = particles.process_material as ParticleProcessMaterial
		
		if process_material:
			# Calculate a current "intensity" based on harmonics
			var intensity = abs(get_combined_amplitude(time)) * 0.5 + 0.5
			
			# Update particle properties
			process_material.initial_velocity_min = intensity * 2.0
			process_material.initial_velocity_max = intensity * 5.0
			process_material.scale_min = 0.05 + intensity * 0.1
			process_material.scale_max = 0.1 + intensity * 0.2
			
			# Update color
			if color_by_amplitude:
				process_material.color = wave_color.lerp(Color(1.0, 0.2, 0.2, 1.0), intensity)

# DEBUG INFORMATION
func create_debug_label():
	debug_label = Label3D.new()
	debug_label.name = "DebugLabel"
	debug_label.position = Vector3(-string_length/2, 2.0, 0)
	debug_label.pixel_size = 0.01
	debug_label.font_size = 16
	debug_label.modulate = Color(1, 1, 1, 1)
	debug_label.text = "Resonance Frequencies Visualization"
	debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	add_child(debug_label)

func update_debug_info():
	var debug_text = "Resonance Frequencies Visualization\n"
	debug_text += "Base Frequency: " + str(base_frequency) + " Hz\n"
	debug_text += "Harmonics: " + str(num_harmonics) + "\n"
	debug_text += "Current Time: " + str(time) + " s\n\n"
	
	debug_text += "Harmonics:\n"
	for i in range(harmonics.size()):
		debug_text += "  f" + str(i+1) + " = " + str(harmonics[i].frequency) + " Hz, A = " + str(snappedf(harmonics[i].amplitude, 0.01)) + "\n"
	
	debug_label.text = debug_text

# RESONANCE NODES
func create_resonance_nodes():
	resonance_nodes.clear()
	
	# Create visualization for resonance modes
	for i in range(num_harmonics):
		var node = Node3D.new()
		node.name = "ResonanceMode_" + str(i+1)
		
		# Create a line renderer for this resonance mode
		var mode_line = ImmediateMesh.new()
		var mode_instance = MeshInstance3D.new()
		mode_instance.name = "ModeLine_" + str(i+1)
		mode_instance.mesh = mode_line
		
		var material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		mode_instance.material_override = material
		
		node.add_child(mode_instance)
		
		# Position the node below the main visualization
		node.position.y = -2.0 - i * 1.5
		node.visible = false
		
		add_child(node)
		resonance_nodes.append({"node": node, "line": mode_line})
	
	# Add buttons to toggle resonance nodes
	create_resonance_buttons()

func create_resonance_buttons():
	var ui = Control.new()
	ui.name = "UI"
	ui.anchor_right = 1.0
	ui.anchor_bottom = 1.0
	add_child(ui)
	
	var panel = Panel.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(200, 30 + num_harmonics * 30)
	ui.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(180, panel.size.y - 20)
	panel.add_child(vbox)
	
	var label = Label.new()
	label.text = "Resonance Modes:"
	vbox.add_child(label)
	
	for i in range(num_harmonics):
		var checkbox = CheckBox.new()
		checkbox.text = "Mode " + str(i+1)
		checkbox.connect("toggled", _on_mode_toggled.bind(i))
		vbox.add_child(checkbox)

func _on_mode_toggled(toggled, index):
	if index >= 0 and index < resonance_nodes.size():
		resonance_nodes[index].node.visible = toggled

func update_resonance_nodes():
	for i in range(resonance_nodes.size()):
		if not resonance_nodes[i].node.visible:
			continue
		
		var mode_line = resonance_nodes[i].line
		var mode_index = i
		
		# Clear previous line
		mode_line.clear_surfaces()
		
		# Begin drawing the line
		mode_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		
		# Calculate points for this resonance mode
		for j in range(string_points + 1):
			var x = (float(j) / string_points) * string_length - string_length / 2
			
			# Get amplitude for this specific mode
			var t_offset = time * (i + 1) * 0.2  # Slightly different timing for each mode
			var amplitude = 0.0
			
			# Simplified mode calculation
			var normalized_pos = (x + string_length / 2) / string_length
			amplitude = sin((i + 1) * PI * normalized_pos) * sin(2.0 * PI * harmonics[i].frequency * time)
			amplitude *= harmonics[i].amplitude
			
			# Create vertex
			var vertex_color = Color.from_hsv(float(i) / num_harmonics, 0.8, 0.9)
			mode_line.surface_set_color(vertex_color)
			mode_line.surface_add_vertex(Vector3(x, amplitude, 0))
		
		# End drawing the line
		mode_line.surface_end()

# USER INTERFACE
func create_ui():
	var ui = Control.new()
	ui.anchor_right = 1.0
	ui.anchor_bottom = 1.0
	add_child(ui)
	
	# Main controls panel
	var panel = Panel.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(250, 300)
	ui.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(230, 280)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Resonance Frequencies"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Frequency slider
	add_slider(vbox, "Base Frequency", base_frequency, 0.1, 5.0, _on_frequency_changed)
	
	# Harmonics slider
	add_slider(vbox, "Harmonics", float(num_harmonics), 1.0, 10.0, _on_harmonics_changed)
	
	# Amplitude slider
	add_slider(vbox, "Amplitude", amplitude, 0.1, 2.0, _on_amplitude_changed)
	
	# Time scale slider
	add_slider(vbox, "Time Scale", time_scale, 0.1, 3.0, _on_time_scale_changed)
	
	# Mode dropdown
	add_mode_dropdown(vbox)
	
	# Reset button
	var reset_button = Button.new()
	reset_button.text = "Reset Simulation"
	reset_button.connect("pressed", _on_reset_pressed)
	vbox.add_child(reset_button)

func add_slider(parent, label_text, initial_value, min_value, max_value, callback):
	var container = HBoxContainer.new()
	parent.add_child(container)
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 120
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.value = initial_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.connect("value_changed", callback)
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.text = str(initial_value)
	value_label.custom_minimum_size.x = 40
	container.add_child(value_label)
	
	# Store label for updates
	slider.set_meta("value_label", value_label)

func add_mode_dropdown(parent):
	var container = HBoxContainer.new()
	parent.add_child(container)
	
	var label = Label.new()
	label.text = "Visualization Mode"
	label.custom_minimum_size.x = 120
	container.add_child(label)
	
	var dropdown = OptionButton.new()
	dropdown.add_item("String", 0)
	dropdown.add_item("Membrane", 1)
	dropdown.add_item("3D Field", 2)
	dropdown.select(visualization_mode)
	dropdown.connect("item_selected", _on_mode_selected)
	container.add_child(dropdown)

# CALLBACKS
func _on_frequency_changed(value):
	base_frequency = value
	if get_tree().get_nodes_in_group("value_labels").size() > 0:
		get_tree().get_nodes_in_group("value_labels")[0].text = str(snappedf(value, 0.01))
	initialize_harmonics()

func _on_harmonics_changed(value):
	num_harmonics = int(value)
	if get_tree().get_nodes_in_group("value_labels").size() > 1:
		get_tree().get_nodes_in_group("value_labels")[1].text = str(num_harmonics)
	initialize_harmonics()
	
	# Recreate resonance nodes
	for node in resonance_nodes:
		node.node.queue_free()
	create_resonance_nodes()

func _on_amplitude_changed(value):
	amplitude = value
	if get_tree().get_nodes_in_group("value_labels").size() > 2:
		get_tree().get_nodes_in_group("value_labels")[2].text = str(snappedf(value, 0.01))
	initialize_harmonics()

func _on_time_scale_changed(value):
	time_scale = value
	if get_tree().get_nodes_in_group("value_labels").size() > 3:
		get_tree().get_nodes_in_group("value_labels")[3].text = str(snappedf(value, 0.01))

func _on_mode_selected(index):
	visualization_mode = index
	
	# Clean up previous visualization
	if mesh_instance:
		mesh_instance.queue_free()
		mesh_instance = null
	
	if line_renderer:
		line_renderer.clear_surfaces()
	
	for node in nodes:
		node.queue_free()
	nodes.clear()
	
	# Create new visualization
	match visualization_mode:
		0:
			create_string_visualization()
		1:
			create_membrane_visualization()
		2:
			create_3d_field_visualization()

func _on_reset_pressed():
	time = 0.0
	initialize_harmonics()

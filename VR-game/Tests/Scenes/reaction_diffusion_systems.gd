extends Node3D

# Ada Research: Reaction-Diffusion System Maze Generator
# This implements the Gray-Scott model to create organic, maze-like patterns

@export_category("Simulation Parameters")
# Use separate width and height integers instead of Vector2i for better compatibility
@export var width: int = 200
@export var height: int = 200
@export var iterations_per_frame: int = 10
@export var feed_rate: float = 0.055  # Feed rate (F)
@export var kill_rate: float = 0.062  # Kill rate (k)
@export var diffusion_rate_a: float = 1.0  # Diffusion rate of chemical A
@export var diffusion_rate_b: float = 0.5  # Diffusion rate of chemical B
@export var time_scale: float = 1.0  # Speed of simulation
@export var delta_t: float = 1.0     # Time step size

@export_category("Visualization")
@export var mesh_height: float = 2.0
@export var initialize_as_maze: bool = true
@export var auto_start: bool = true
@export var enable_3d_mesh: bool = true

@export_category("Material Settings")
@export var material_a: Material
@export var material_b: Material
@export var path_material: Material

# Simulation variables
var grid_a: Array = []  # Concentration of chemical A
var grid_b: Array = []  # Concentration of chemical B
var next_a: Array = []  # Next state for A
var next_b: Array = []  # Next state for B
var simulation_running: bool = false
var mesh_instance: MeshInstance3D
var mesh_data: Array = []
var frame_count: int = 0

func _ready():
	initialize_grids()
	
	if enable_3d_mesh:
		create_mesh()
		
	if auto_start:
		simulation_running = true

func _process(delta):
	if simulation_running:
		# Run multiple iterations per frame for faster results
		for i in range(iterations_per_frame):
			update_simulation(delta * time_scale)
		
		# Update the mesh every few frames to improve performance
		frame_count += 1
		if frame_count % 5 == 0 and enable_3d_mesh:
			update_mesh()

func initialize_grids():
	# Initialize grids with chemical A at 1.0 and chemical B at 0.0
	grid_a = []
	grid_b = []
	next_a = []
	next_b = []
	
	for x in range(width):
		grid_a.append([])
		grid_b.append([])
		next_a.append([])
		next_b.append([])
		
		for y in range(height):
			grid_a[x].append(1.0)  # Chemical A fills the space
			grid_b[x].append(0.0)  # Chemical B is initially absent
			next_a[x].append(0.0)
			next_b[x].append(0.0)
	
	# Initialize with seed pattern
	if initialize_as_maze:
		create_maze_seed()
	else:
		create_random_seed()

func create_random_seed():
	# Add random spots of chemical B
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(20):
		var x = rng.randi_range(width/3, 2*width/3)
		var y = rng.randi_range(height/3, 2*height/3)
		
		# Create a small square of chemical B
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				var nx = x + dx
				var ny = y + dy
				
				if nx >= 0 and nx < width and ny >= 0 and ny < height:
					grid_a[nx][ny] = 0.5
					grid_b[nx][ny] = 0.5

func create_maze_seed():
	# Initialize with a pattern that will lead to maze-like structures
	var center_x = width / 2
	var center_y = height / 2
	
	# Create central cross pattern
	for x in range(width):
		for y in range(height):
			# Create a grid pattern of B chemical
			if (x + y) % 20 < 10:
				grid_a[x][y] = 0.0
				grid_b[x][y] = 1.0
	
	# Add some randomness for more interesting patterns
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(100):
		var x = rng.randi_range(0, width - 1)
		var y = rng.randi_range(0, height - 1)
		var size = rng.randi_range(3, 8)
		
		for dx in range(-size, size):
			for dy in range(-size, size):
				var nx = x + dx
				var ny = y + dy
				
				if nx >= 0 and nx < width and ny >= 0 and ny < height:
					if rng.randf() < 0.7:
						grid_a[nx][ny] = 0.0
						grid_b[nx][ny] = 1.0

func update_simulation(delta: float):
	# Gray-Scott reaction-diffusion system
	# dA/dt = Da∇²A - AB² + f(1-A)
	# dB/dt = Db∇²B + AB² - (f+k)B
	
	var dt = delta_t * delta
	
	# Compute the next state
	for x in range(width):
		for y in range(height):
			# Get current values
			var a = grid_a[x][y]
			var b = grid_b[x][y]
			
			# Calculate Laplacian (∇²) using a 5-point stencil
			var laplacian_a = calculate_laplacian(grid_a, x, y)
			var laplacian_b = calculate_laplacian(grid_b, x, y)
			
			# Reaction terms
			var reaction_term = a * b * b
			
			# Update rules for Gray-Scott
			var da = diffusion_rate_a * laplacian_a - reaction_term + feed_rate * (1.0 - a)
			var db = diffusion_rate_b * laplacian_b + reaction_term - (feed_rate + kill_rate) * b
			
			# Apply changes
			next_a[x][y] = a + da * dt
			next_b[x][y] = b + db * dt
			
			# Ensure values stay in valid range [0,1]
			next_a[x][y] = clamp(next_a[x][y], 0.0, 1.0)
			next_b[x][y] = clamp(next_b[x][y], 0.0, 1.0)
	
	# Swap buffers
	var temp_a = grid_a
	var temp_b = grid_b
	grid_a = next_a
	grid_b = next_b
	next_a = temp_a
	next_b = temp_b

func calculate_laplacian(grid: Array, x: int, y: int) -> float:
	var center = grid[x][y]
	var sum = 0.0
	
	# Check the four adjacent cells with wraparound boundary conditions
	var left = grid[(x - 1 + width) % width][y]
	var right = grid[(x + 1) % width][y]
	var up = grid[x][(y - 1 + height) % height]
	var down = grid[x][(y + 1) % height]
	
	sum = left + right + up + down - 4.0 * center
	return sum

func create_mesh():
	# Create a surface tool to build the mesh
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ReactionDiffusionMesh"
	add_child(mesh_instance)
	
	# Create initial flat terrain mesh
	update_mesh()
func update_mesh():
	# Create a new Array Mesh
	var array_mesh = ArrayMesh.new()
	var surface_tool = SurfaceTool.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Scale factor to fit the mesh in world space
	var scale_x = 10.0 / float(width)
	var scale_z = 10.0 / float(height)
	
	# Sample the grid at a lower resolution for better performance
	var sample_rate = 1  # Increase to reduce resolution
	var sampled_width = width / sample_rate
	var sampled_height = height / sample_rate
	
	# Create vertices
	for x in range(0, width, sample_rate):
		for y in range(0, height, sample_rate):
			# Get chemical B concentration at this point
			var b_value = grid_b[x][y]
			
			# Create vertex with height based on chemical B
			var vertex = Vector3(
				x * scale_x - 5.0,      # x position
				b_value * mesh_height,  # height based on chemical B
				y * scale_z - 5.0       # z position
			)
			
			# Add vertex
			# In Godot 4, we need to set the color and normal before adding the vertex
			surface_tool.set_color(Color(b_value, b_value, b_value))
			surface_tool.set_normal(Vector3(0, 1, 0))  # We'll recalculate normals later
			surface_tool.add_vertex(vertex)
	
	# Create triangles
	for x in range(0, sampled_width - 1):
		for y in range(0, sampled_height - 1):
			var i00 = x * sampled_height + y
			var i10 = (x + 1) * sampled_height + y
			var i11 = (x + 1) * sampled_height + (y + 1)
			var i01 = x * sampled_height + (y + 1)
			
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
	
	# Apply the material
	if material_b:
		var material_instance = material_b.duplicate()
		mesh_instance.set_surface_override_material(0, material_instance)
	
	# Assign the mesh
	mesh_instance.mesh = mesh

# Visualize the maze path
func visualize_maze_path():
	var maze_data = extract_maze_path()
	var path_grid = maze_data.path_grid
	var start = maze_data.start
	var end = maze_data.end
	
	# Create a simple visualization of the path
	var path_mesh = MeshInstance3D.new()
	path_mesh.name = "MazePath"
	add_child(path_mesh)
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Scale factor to fit the mesh in world space
	var scale_x = 10.0 / float(width)
	var scale_z = 10.0 / float(height)
	var path_height = 0.1  # Height of the path above the terrain
	
	# Create vertices for path cells
	for x in range(width):
		for y in range(height):
			if path_grid[x][y]:
				var world_x = x * scale_x - 5.0
				var world_z = y * scale_z - 5.0
				var height = grid_b[x][y] * mesh_height + path_height
				
				# Create a small quad for each path cell
				var v1 = Vector3(world_x, height, world_z)
				var v2 = Vector3(world_x + scale_x, height, world_z)
				var v3 = Vector3(world_x + scale_x, height, world_z + scale_z)
				var v4 = Vector3(world_x, height, world_z + scale_z)
				
				# Set a color for the path vertices
				surface_tool.set_color(Color(1, 0.5, 1, 0.8))
				
				# Add two triangles for the quad
				surface_tool.add_vertex(v1)
				surface_tool.add_vertex(v2)
				surface_tool.add_vertex(v3)
				
				surface_tool.add_vertex(v1)
				surface_tool.add_vertex(v3)
				surface_tool.add_vertex(v4)
	
	# Create the mesh
	var mesh = surface_tool.commit()
	
	# Apply the material
	if path_material:
		path_mesh.set_surface_override_material(0, path_material)
	else:
		var default_material = StandardMaterial3D.new()
		default_material.albedo_color = Color(1, 0, 0, 0.7)  # Semi-transparent red
		default_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		path_mesh.set_surface_override_material(0, default_material)
	
	# Assign the mesh
	path_mesh.mesh = mesh
	
	# Create special markers for start and end
	create_marker(start, Color(0, 1, 0), "Start")  # Green for start
	create_marker(end, Color(1, 0, 0), "End")      # Red for end
# Utility functions for changing simulation parameters
func set_feed_rate(value: float):
	feed_rate = value

func set_kill_rate(value: float):
	kill_rate = value

func toggle_simulation():
	simulation_running = !simulation_running

func reset_simulation():
	initialize_grids()
	if enable_3d_mesh:
		update_mesh()

# Creates a UI for controlling the simulation
func create_ui():
	var ui = Control.new()
	ui.anchor_right = 1.0
	ui.anchor_bottom = 1.0
	add_child(ui)
	
	var panel = Panel.new()
	panel.position = Vector2(10, 10)
	panel.size = Vector2(200, 150)
	ui.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(180, 130)
	panel.add_child(vbox)
	
	# Add sliders for feed and kill rates
	add_slider(vbox, "Feed Rate", feed_rate, 0.01, 0.1, self.set_feed_rate)
	add_slider(vbox, "Kill Rate", kill_rate, 0.01, 0.1, self.set_kill_rate)
	
	# Add buttons
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var toggle_button = Button.new()
	toggle_button.text = "Pause/Play"
	toggle_button.connect("pressed", Callable(self, "toggle_simulation"))
	hbox.add_child(toggle_button)
	
	var reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.connect("pressed", Callable(self, "reset_simulation"))
	hbox.add_child(reset_button)

func add_slider(parent: Control, label_text: String, initial_value: float, min_value: float, max_value: float, callback: Callable):
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.value = initial_value
	slider.step = 0.001
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.connect("value_changed", callback)
	hbox.add_child(slider)

# Called to extract a path from the reaction-diffusion pattern
func extract_maze_path() -> Dictionary:
	var threshold = 0.5  # Threshold for considering a cell part of the path
	var path_grid = []
	
	# Initialize path grid
	for x in range(width):
		path_grid.append([])
		for y in range(height):
			# Mark cells where chemical B is below threshold as path
			path_grid[x].append(grid_b[x][y] < threshold)
	
	# Find start and end points (could be more sophisticated)
	var start = Vector2i(0, height / 2)
	var end = Vector2i(width - 1, height / 2)
	
	# Find actual valid starting points
	for y in range(height):
		if path_grid[0][y]:
			start = Vector2i(0, y)
			break
	
	for y in range(height):
		if path_grid[width - 1][y]:
			end = Vector2i(width - 1, y)
			break
	
	return {
		"path_grid": path_grid,
		"start": start,
		"end": end
	}

func create_marker(position: Vector2i, color: Color, label: String):
	var marker = MeshInstance3D.new()
	marker.name = label + "Marker"
	
	# Create a small sphere mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	marker.mesh = sphere_mesh
	
	# Set material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	marker.material_override = material
	
	# Position the marker
	var scale_x = 10.0 / float(width)
	var scale_z = 10.0 / float(height)
	var height = 0.5  # Fixed height above terrain
	
	marker.position = Vector3(
		position.x * scale_x - 5.0,
		mesh_height + height,
		position.y * scale_z - 5.0
	)
	
	add_child(marker)

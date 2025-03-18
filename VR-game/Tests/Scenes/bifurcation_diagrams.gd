extends Node3D

# Glass Bifurcation Diagram Generator
# Assumes you already have a glass shader assigned to the material

@export var min_r_value: float = 2.8
@export var max_r_value: float = 4.0
@export var num_r_values: int = 100
@export var iterations_per_r: int = 200
@export var discard_iterations: int = 100
@export var pipe_radius: float = 0.05
@export var x_scale: float = 10.0
@export var y_scale: float = 20.0
@export var z_spread: float = 0.1

# Reference to the glass material
@export var glass_material: Material

var pipe_mesh: ImmediateMesh
var pipe_instance: MeshInstance3D
var curve_points = []
var r_values = []

func _ready():
	generate_bifurcation_data()
	create_glass_pipes()

func generate_bifurcation_data():
	# Generate r parameter values (control parameter for logistic map)
	var r_step = (max_r_value - min_r_value) / num_r_values
	
	for i in range(num_r_values):
		var r = min_r_value + i * r_step
		r_values.append(r)
		
		# For each r value, compute the logistic map and collect bifurcation points
		var x = 0.5  # Starting value
		var points_for_r = []
		
		# Run iterations
		for j in range(iterations_per_r + discard_iterations):
			# Logistic map: x_{n+1} = r * x_n * (1 - x_n)
			x = r * x * (1.0 - x)
			
			# Only keep points after the discard period (to reach the attractor)
			if j >= discard_iterations:
				points_for_r.append(x)
		
		curve_points.append(points_for_r)

func create_glass_pipes():
	pipe_mesh = ImmediateMesh.new()
	pipe_instance = MeshInstance3D.new()
	pipe_instance.mesh = pipe_mesh
	pipe_instance.material_override = glass_material
	add_child(pipe_instance)
	
	# Create a tube for each r value branching structure
	for i in range(len(r_values)):
		var r = r_values[i]
		var points = curve_points[i]
		
		# Convert logistic map outputs to 3D positions
		var positions = []
		for point in points:
			var x_pos = (r - min_r_value) / (max_r_value - min_r_value) * x_scale
			var y_pos = point * y_scale
			var z_pos = randf_range(-z_spread, z_spread)  # Small random z offset for visual interest
			positions.append(Vector3(x_pos, y_pos, z_pos))
		
		# Sort positions for better pipe rendering
		positions.sort_custom(func(a, b): return a.y < b.y)
		
		# Generate the glass pipe mesh for this branch
		create_tube_along_points(positions, pipe_radius, i)

func create_tube_along_points(points, radius, branch_index):
	# Skip if not enough points
	if points.size() < 2:
		return
	
	# We'll generate triangle strips for the tube
	pipe_mesh.clear_surfaces()
	pipe_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var num_segments = 8  # Number of segments around the tube
	
	for i in range(points.size() - 1):
		var p1 = points[i]
		var p2 = points[i + 1]
		
		# Direction between points
		var direction = (p2 - p1).normalized()
		
		# Find perpendicular vectors to create circle segments
		var up = Vector3(0, 1, 0)
		if direction.dot(up) > 0.9:
			up = Vector3(1, 0, 0)
		
		var right = direction.cross(up).normalized()
		up = right.cross(direction).normalized()
		
		# Generate circles at both points
		var circle1 = []
		var circle2 = []
		
		for j in range(num_segments):
			var angle = j * 2.0 * PI / num_segments
			var offset = right * cos(angle) * radius + up * sin(angle) * radius
			circle1.append(p1 + offset)
			circle2.append(p2 + offset)
		
		# Create triangles between the circles to form the tube
		for j in range(num_segments):
			var j_next = (j + 1) % num_segments
			
			# First triangle
			pipe_mesh.surface_set_normal(up)
			pipe_mesh.surface_add_vertex(circle1[j])
			pipe_mesh.surface_set_normal(up)
			pipe_mesh.surface_add_vertex(circle2[j])
			pipe_mesh.surface_set_normal(up)
			pipe_mesh.surface_add_vertex(circle1[j_next])
			
			# Second triangle
			pipe_mesh.surface_set_normal(up)
			pipe_mesh.surface_add_vertex(circle1[j_next])
			pipe_mesh.surface_set_normal(up)
			pipe_mesh.surface_add_vertex(circle2[j])
			pipe_mesh.surface_set_normal(up)
			pipe_mesh.surface_add_vertex(circle2[j_next])
	
	pipe_mesh.surface_end()

# Optional: Add interactivity to explore different parameter ranges
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			# Regenerate with slightly different parameters
			min_r_value = randf_range(2.8, 3.2)
			max_r_value = randf_range(3.8, 4.0)
			generate_bifurcation_data()
			create_glass_pipes()

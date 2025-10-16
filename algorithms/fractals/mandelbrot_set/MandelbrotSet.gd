# This script generates a VR-optimized Mandelbrot set.
# It uses incremental calculation and a single ArrayMesh for high performance.

extends Node3D

# VR-Optimized State Variables
var time = 0.0
var resolution = 200  # Increased resolution for more detail
var max_iterations = 100
var zoom = 1.0
var center = Vector2(-0.5, 0.0)

# Incremental generation state
var current_x = 0
var current_y = 0
var is_generating = false

# VR-Optimized rendering
var fractal_mesh_instance: MeshInstance3D
var array_mesh: ArrayMesh
var vertices = PackedVector3Array()
var colors = PackedColorArray()

# Materials
var fractal_material: StandardMaterial3D

func _ready():
	"""Initializes the scene, materials, and starts the initial generation."""
	setup_vr_optimized_scene()
	setup_materials()
	start_generation()

func setup_vr_optimized_scene():
	"""Sets up the single MeshInstance3D for rendering the fractal."""
	fractal_mesh_instance = MeshInstance3D.new()
	fractal_mesh_instance.name = "MandelbrotMesh"
	add_child(fractal_mesh_instance)

func setup_materials():
	"""Sets up the material for the fractal mesh."""
	fractal_material = StandardMaterial3D.new()
	# VR optimization: Unshaded material for better performance and glow
	fractal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fractal_material.vertex_color_use_as_albedo = true
	fractal_material.point_size = 2.0  # VR friendly point size
	fractal_material.albedo_color = Color.WHITE
	fractal_mesh_instance.material_override = fractal_material

func _process(delta):
	"""Handles animation and incremental generation."""
	time += delta
	
	# Only generate if the flag is set
	if is_generating:
		generate_batch_of_points()
	
	animate_fractal()

func start_generation():
	"""Resets generation state and prepares for a new fractal."""
	vertices.clear()
	colors.clear()
	current_x = 0
	current_y = 0
	is_generating = true
	# Reset the mesh instance's mesh to clear the previous fractal
	fractal_mesh_instance.mesh = null
	
func generate_batch_of_points():
	"""
	Calculates a small batch of points each frame to smooth out performance.
	"""
	var batch_size = 50  # Adjust this value for performance
	var points_generated_this_frame = 0

	# Continue calculating points until the batch size is met or the grid is complete
	while points_generated_this_frame < batch_size and is_generating:
		# Calculate the current point
		var real = center.x + (float(current_x) - resolution/2.0) * (4.0 / zoom) / resolution
		var imag = center.y + (float(current_y) - resolution/2.0) * (4.0 / zoom) / resolution
		
		var iterations = mandelbrot_iterations(real, imag)
		var normalized_iter = float(iterations) / max_iterations
		
		# Define the point's position in 3D space
		var pos = Vector3(
			(float(current_x) - resolution/2.0) * 0.1,
			(float(current_y) - resolution/2.0) * 0.1,
			0
		)
		
		# Define the point's color based on iterations
		var point_color
		if iterations >= max_iterations:
			point_color = Color.BLACK  # In the set
		else:
			# Outside the set, a colorful gradient
			var hue = normalized_iter * 360.0
			point_color = Color.from_hsv(hue / 360.0, 0.8, 1.0)
		
		# Add the calculated point and color to our arrays
		vertices.append(pos)
		colors.append(point_color)
		
		# Move to the next point in the grid
		current_x += 1
		if current_x >= resolution:
			current_x = 0
			current_y += 1
		
		# Check if generation is complete
		if current_y >= resolution:
			is_generating = false
		
		points_generated_this_frame += 1
	
	# Update the mesh instance with the new points
	update_mesh()

func update_mesh():
	"""Updates the ArrayMesh with the current points."""
	if not array_mesh:
		array_mesh = ArrayMesh.new()
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	
	if array_mesh.get_surface_count() > 0:
		array_mesh.clear_surfaces()
	
	# Use a single surface with PRIMITIVE_POINTS
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	fractal_mesh_instance.mesh = array_mesh

func mandelbrot_iterations(c_real: float, c_imag: float) -> int:
	"""Calculates the number of iterations for a given complex number."""
	var z_real = 0.0
	var z_imag = 0.0
	var iterations = 0
	
	while iterations < max_iterations and (z_real * z_real + z_imag * z_imag) < 4.0:
		var new_real = z_real * z_real - z_imag * z_imag + c_real
		var new_imag = 2.0 * z_real * z_imag + c_imag
		z_real = new_real
		z_imag = new_imag
		iterations += 1
	
	return iterations

func animate_fractal():
	"""Applies a subtle animation to the fractal."""
	if not fractal_mesh_instance:
		return
	
	# Gentle pulsing animation
	var pulse = 1.0 + sin(time * 2.0) * 0.1
	fractal_mesh_instance.scale = Vector3.ONE * pulse

func _input(event):
	"""Handles user input to manually trigger a new generation."""
	if event.is_action_pressed("ui_accept"):  # Space key
		# Randomly select a new zoom and center
		zoom = 1.0 + randf() * 1000.0
		center = Vector2(randf() * 2.0 - 1.5, randf() * 2.0 - 1.0)
		start_generation()
		print("🌟 Starting new fractal generation...")

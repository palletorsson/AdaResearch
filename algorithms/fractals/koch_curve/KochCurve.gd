# This script generates a VR-optimized Koch snowflake fractal.
# It uses a single ArrayMesh instead of multiple CSG nodes for performance.

extends Node3D

# VR-Optimized State Variables
var time = 0.0
var current_iteration = 0
var max_iterations = 4
var iteration_timer = 0.0
var iteration_interval = 3.0
var total_segments = 0

# Koch curve generation data
var points = []

# VR-Optimized rendering (NO CSG!)
var koch_mesh_instance: MeshInstance3D
var iteration_mesh_instance: MeshInstance3D
var complexity_mesh_instance: MeshInstance3D

# Materials
var koch_material: StandardMaterial3D
var iter_material: StandardMaterial3D
var complexity_material: StandardMaterial3D

func _ready():
	"""Initializes the scene, materials, and the base Koch curve."""
	setup_vr_optimized_scene()
	setup_materials()
	initialize_koch_curve()
	# The first iteration is generated immediately on start.
	generate_next_iteration()

func setup_vr_optimized_scene():
	"""Setup VR-optimized mesh instances instead of CSG nodes."""
	
	# Main Koch curve mesh
	koch_mesh_instance = MeshInstance3D.new()
	koch_mesh_instance.name = "KochMesh"
	add_child(koch_mesh_instance)
	
	# Iteration control indicator (single mesh)
	iteration_mesh_instance = MeshInstance3D.new()
	iteration_mesh_instance.name = "IterationControl"
	iteration_mesh_instance.position = Vector3(-6, 0, 0)
	add_child(iteration_mesh_instance)
	
	# Complexity indicator (single mesh)
	complexity_mesh_instance = MeshInstance3D.new()
	complexity_mesh_instance.name = "ComplexityIndicator"
	complexity_mesh_instance.position = Vector3(6, 0, 0)
	add_child(complexity_mesh_instance)

func setup_materials():
	"""Setup VR-optimized materials."""
	
	# Koch curve material
	koch_material = StandardMaterial3D.new()
	koch_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
	koch_material.emission_enabled = true
	koch_material.emission = Color(0.1, 0.4, 0.6)
	koch_material.emission_energy_multiplier = 1.5
	koch_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # VR optimization
	koch_mesh_instance.material_override = koch_material
	
	# Iteration control material
	iter_material = StandardMaterial3D.new()
	iter_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	iter_material.emission_enabled = true
	iter_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	iter_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	iteration_mesh_instance.material_override = iter_material
	
	# Complexity indicator material
	complexity_material = StandardMaterial3D.new()
	complexity_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	complexity_material.emission_enabled = true
	complexity_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	complexity_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	complexity_mesh_instance.material_override = complexity_material

func initialize_koch_curve():
	"""Resets the curve to its base equilateral triangle state."""
	points.clear()
	# Increase the size of the base triangle for better VR visibility
	var triangle_size = 40.0
	var height = triangle_size * sqrt(3) / 2.0
	
	# Three vertices of equilateral triangle
	points.append(Vector2(-triangle_size/2, -height/3))
	points.append(Vector2(triangle_size/2, -height/3))
	points.append(Vector2(0, 2*height/3))
	points.append(Vector2(-triangle_size/2, -height/3))  # Close the triangle
	
	# Reset iteration counter
	current_iteration = 0
	# Update visual for base state
	update_vr_optimized_visual()

func _process(delta):
	"""Main game loop, handles animations and timed iteration advancement."""
	time += delta
	iteration_timer += delta
	
	# Advance iteration at a fixed interval
	if iteration_timer >= iteration_interval:
		iteration_timer = 0.0
		generate_next_iteration()
 

func generate_next_iteration():
	"""
	Applies a single Koch transformation and updates the visual.
	This prevents the recursive loop that caused the stack overflow.
	"""
	current_iteration = (current_iteration + 1) % (max_iterations + 1)
	
	if current_iteration == 0:
		# Reset to base triangle
		initialize_koch_curve()
	else:
		# Apply ONE Koch transformation step
		apply_koch_transformation()
		update_vr_optimized_visual()
	
	print("🔺 Koch iteration: %d, segments: %d" % [current_iteration, total_segments])

func apply_koch_transformation():
	"""Applies the Koch curve transformation rule to each segment."""
	var new_points = []
	
	for i in range(points.size() - 1):
		var start = points[i]
		var end = points[i + 1]
		
		# Apply Koch curve rule: replace each line segment with a new fractal segment
		var koch_points = generate_koch_segment(start, end)
		
		# Add all points except the last one (to avoid duplication with the next segment)
		for j in range(koch_points.size() - 1):
			new_points.append(koch_points[j])
	
	# Add the final point from the last segment to close the curve
	new_points.append(points[-1])
	points = new_points

func generate_koch_segment(start: Vector2, end: Vector2) -> Array:
	"""
	Implements the core Koch curve rule: divides a segment into thirds
	and creates an equilateral triangle on the middle third.
	"""
	var direction = end - start
	var length = direction.length()
	var unit_dir = direction.normalized()
	
	# Calculate the five points of the new segment
	var p1 = start
	var p2 = start + unit_dir * (length / 3.0)
	var p4 = start + unit_dir * (2.0 * length / 3.0)
	var p5 = end
	
	# Calculate the peak of the equilateral triangle
	var perpendicular = Vector2(-unit_dir.y, unit_dir.x)  # Rotate 90 degrees
	var triangle_height = (length / 3.0) * sqrt(3) / 2.0
	var p3 = p2 + perpendicular * triangle_height
	
	return [p1, p2, p3, p4, p5]

func update_vr_optimized_visual():
	"""
	Creates a single, optimized VR mesh from the generated points.
	This is much more efficient than using separate meshes for each segment.
	"""
	
	total_segments = points.size() - 1
	
	if points.size() < 2:
		return
	
	# Create single ArrayMesh for the entire Koch curve
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	var colors = PackedColorArray()
	
	# Increased thickness for better VR visibility
	var ribbon_width = 0.4
	var vertex_index = 0
	
	# Create a ribbon (series of quads) for each segment
	for i in range(points.size() - 1):
		var start = Vector3(points[i].x, points[i].y, 0)
		var end = Vector3(points[i + 1].x, points[i + 1].y, 0)
		
		var direction = (end - start).normalized()
		var perpendicular = Vector3(-direction.y, direction.x, 0) * ribbon_width
		
		# Create quad vertices
		var v1 = start + perpendicular
		var v2 = start - perpendicular
		var v3 = end - perpendicular
		var v4 = end + perpendicular
		
		# Add vertices, normals, and colors
		vertices.append(v1)
		vertices.append(v2)
		vertices.append(v3)
		vertices.append(v4)
		
		var normal = Vector3(0, 0, 1) # Facing towards the camera
		normals.append(normal)
		normals.append(normal)
		normals.append(normal)
		normals.append(normal)
		
		var u_coord = float(i) / float(points.size() - 1)
		uvs.append(Vector2(u_coord, 0))
		uvs.append(Vector2(u_coord, 1))
		uvs.append(Vector2(u_coord, 1))
		uvs.append(Vector2(u_coord, 0))
		
		var color_intensity = float(i) / total_segments
		var iteration_intensity = float(current_iteration) / max_iterations
		
		var segment_color = Color(
			0.2 + iteration_intensity * 0.8,
			0.8 - color_intensity * 0.4,
			0.3 + color_intensity * 0.7,
			1.0
		)
		
		colors.append(segment_color)
		colors.append(segment_color)
		colors.append(segment_color)
		colors.append(segment_color)
		
		# Add indices for the two triangles that form the quad
		indices.append(vertex_index)
		indices.append(vertex_index + 1)
		indices.append(vertex_index + 2)
		
		indices.append(vertex_index)
		indices.append(vertex_index + 2)
		indices.append(vertex_index + 3)
		
		vertex_index += 4
	
	# Build the final mesh from the arrays
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_COLOR] = colors
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FORMAT_NORMAL | Mesh.ARRAY_FORMAT_COLOR)
	koch_mesh_instance.mesh = array_mesh

 
func create_cylinder_mesh(mesh_instance: MeshInstance3D, radius: float, height: float):
	"""Creates a simple cylinder mesh without CSG."""
	
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height
	cylinder_mesh.segments = 12  # Lower segments for VR performance
	
	mesh_instance.mesh = cylinder_mesh

func get_fractal_info() -> Dictionary:
	"""Gets and returns fractal information for debugging/display."""
	return {
		"iteration": current_iteration,
		"segments": total_segments,
		"theoretical_length": pow(4.0/3.0, float(current_iteration)) * 12.0,
		"vr_optimized": true,
		"mesh_instances": 3  # Instead of hundreds of CSG nodes
	}

# Input handling for testing
func _input(event):
	"""Handles user input to manually advance the iteration."""
	if event.is_action_pressed("ui_accept"):  # Space key
		generate_next_iteration()
	
	if event.is_action_pressed("ui_select"):  # Enter key
		var info = get_fractal_info()
		print("📊 Fractal Info: ", info)

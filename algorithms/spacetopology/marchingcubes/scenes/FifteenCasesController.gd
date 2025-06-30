# FifteenCasesController.gd
# Demonstrates the 15 unique surface cases of the Marching Cubes algorithm
# Each case represents a fundamental surface topology that can occur

extends Node3D

# The 15 unique surface cases with their representative configurations
# Using 0.3 for "outside" and 0.7 for "inside" to ensure proper threshold crossing at 0.5
var fifteen_cases = [
	{
		"name": "Case 0: Empty",
		"description": "All vertices outside surface",
		"config": 0,  # 00000000 - no vertices inside
		"densities": [0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 1: Single Corner",
		"description": "One vertex inside surface",
		"config": 1,  # 00000001 - vertex 0 inside
		"densities": [0.7, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 2: Adjacent Corners",
		"description": "Two adjacent vertices inside",
		"config": 3,  # 00000011 - vertices 0,1 inside
		"densities": [0.7, 0.7, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 3: Triangle Corner",
		"description": "Three vertices forming triangle",
		"config": 7,  # 00000111 - vertices 0,1,2 inside
		"densities": [0.7, 0.7, 0.7, 0.3, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 4: Diagonal Corners",
		"description": "Two opposite corners",
		"config": 9,  # 00001001 - vertices 0,3 inside (diagonal)
		"densities": [0.7, 0.3, 0.3, 0.7, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 5: L-Shape",
		"description": "Four vertices in L-shape",
		"config": 15, # 00001111 - bottom face inside
		"densities": [0.7, 0.7, 0.7, 0.7, 0.3, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 6: Wedge",
		"description": "Triangular wedge shape",
		"config": 23, # 00010111 - 5 vertices inside
		"densities": [0.7, 0.7, 0.7, 0.3, 0.7, 0.3, 0.3, 0.3]
	},
	{
		"name": "Case 7: Tunnel",
		"description": "Tube/tunnel through cube",
		"config": 51, # 00110011 - creates tunnel
		"densities": [0.7, 0.7, 0.3, 0.3, 0.7, 0.7, 0.3, 0.3]
	},
	{
		"name": "Case 8: Saddle",
		"description": "Saddle point configuration",
		"config": 85, # 01010101 - alternating pattern
		"densities": [0.7, 0.3, 0.7, 0.3, 0.7, 0.3, 0.7, 0.3]
	},
	{
		"name": "Case 9: Complex Saddle",
		"description": "Complex saddle surface",
		"config": 102, # 01100110 - different alternating
		"densities": [0.3, 0.7, 0.7, 0.3, 0.3, 0.7, 0.7, 0.3]
	},
	{
		"name": "Case 10: Bridge",
		"description": "Bridge connecting surfaces",
		"config": 60, # 00111100 - creates bridge
		"densities": [0.3, 0.3, 0.7, 0.7, 0.7, 0.7, 0.3, 0.3]
	},
	{
		"name": "Case 11: Complex Surface",
		"description": "Complex multi-surface",
		"config": 90, # 01011010 - complex pattern
		"densities": [0.3, 0.7, 0.3, 0.7, 0.7, 0.3, 0.7, 0.3]
	},
	{
		"name": "Case 12: Asymmetric",
		"description": "Asymmetric surface pattern",
		"config": 105, # 01101001 - asymmetric
		"densities": [0.7, 0.3, 0.3, 0.7, 0.3, 0.7, 0.7, 0.3]
	},
	{
		"name": "Case 13: Nearly Full",
		"description": "Seven vertices inside",
		"config": 127, # 01111111 - vertex 7 outside
		"densities": [0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.3]
	},
	{
		"name": "Case 14: Full",
		"description": "All vertices inside surface",
		"config": 255, # 11111111 - all vertices inside
		"densities": [0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7]
	}
]

@export var case_spacing: float = 4.0  # Distance between cases
@export var show_wireframes: bool = true
@export var show_labels: bool = true
@export var animate_threshold: bool = false

# Camera controls
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 8.0
@export var max_zoom: float = 30.0
var current_zoom: float = 10.0
var camera_controller: Node3D

var labels: Array[Label3D] = []
var meshes: Array[MeshInstance3D] = []
var animation_time: float = 0.0

func _ready():
	print("🔮 Marching Cubes: Demonstrating 15 unique surface cases...")
	
	# Get camera controller reference
	camera_controller = get_node("CameraController")
	if camera_controller == null:
		camera_controller = get_parent().get_node("CameraController")
	
	generate_fifteen_cases()
	if show_labels:
		create_labels()

func _process(delta):
	if animate_threshold:
		animation_time += delta
		animate_cases()

func generate_fifteen_cases():
	"""Generate visual representations of all 15 cases"""
	var rows = 3
	var cols = 5
	
	for i in range(fifteen_cases.size()):
		var case_data = fifteen_cases[i]
		var row = i / cols
		var col = i % cols
		
		var position = Vector3(
			col * case_spacing - (cols - 1) * case_spacing * 0.5,
			0,
			row * case_spacing - (rows - 1) * case_spacing * 0.5
		)
		
		generate_case_mesh(case_data, position, i)

func generate_case_mesh(case_data: Dictionary, position: Vector3, case_index: int):
	"""Generate mesh for a specific marching cubes case"""
	# Create cube data for marching cubes
	var cube_data = {
		"positions": get_cube_positions(),
		"densities": case_data.densities
	}
	
	# Generate mesh using marching cubes
	var generator = MarchingCubesGenerator.new()
	var triangles = generator.march_cube(cube_data)
	
	# Create visual representation
	var mesh_instance = create_case_visualization(triangles, position, case_data, case_index)
	add_child(mesh_instance)
	meshes.append(mesh_instance)
	
	# Add wireframe cube to show the voxel structure
	if show_wireframes:
		var wireframe = create_wireframe_cube(position, case_data.densities)
		add_child(wireframe)

func get_cube_positions() -> Array:
	"""Get the 8 corner positions of a unit cube"""
	return [
		Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0),  # Bottom face
		Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)   # Top face
	]

func create_case_visualization(triangles: Array, position: Vector3, case_data: Dictionary, case_index: int) -> MeshInstance3D:
	"""Create a colored mesh instance for a marching cubes case"""
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Case_%d" % case_index
	mesh_instance.position = position
	
	if triangles.size() > 0:
		# Create mesh from triangles
		var array_mesh = ArrayMesh.new()
		var vertices = PackedVector3Array()
		var normals = PackedVector3Array()
		var indices = PackedInt32Array()
		
		var vertex_index = 0
		for triangle in triangles:
			if triangle.vertices.size() == 3 and triangle.normals.size() == 3:
				vertices.append_array(triangle.vertices)
				normals.append_array(triangle.normals)
				
				# Add triangle indices
				indices.append(vertex_index)
				indices.append(vertex_index + 1)
				indices.append(vertex_index + 2)
				vertex_index += 3
		
		if vertices.size() > 0:
			var arrays = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_INDEX] = indices
			array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mesh_instance.mesh = array_mesh
	else:
		# No triangles - create a small indicator sphere
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.1
		sphere_mesh.height = 0.2
		mesh_instance.mesh = sphere_mesh
		mesh_instance.position.y += 0.5
	
	# Create material with case-specific color
	var material = StandardMaterial3D.new()
	material.albedo_color = get_case_color(case_index)
	material.metallic = 0.2
	material.roughness = 0.8
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.3
	material.emission_energy = 0.5
	
	if show_wireframes:
		material.flags_transparent = true
		material.albedo_color.a = 0.8
	
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

func create_wireframe_cube(position: Vector3, densities: Array) -> Node3D:
	"""Create wireframe representation showing vertex states"""
	var wireframe_node = Node3D.new()
	wireframe_node.name = "Wireframe"
	wireframe_node.position = position
	
	var cube_positions = get_cube_positions()
	
	# Create vertex indicators
	for i in range(8):
		var vertex_sphere = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.08
		sphere_mesh.height = 0.16
		vertex_sphere.mesh = sphere_mesh
		vertex_sphere.position = cube_positions[i]
		
		# Color based on density (inside/outside)
		var material = StandardMaterial3D.new()
		if densities[i] > 0.5:
			material.albedo_color = Color.RED  # Inside surface
		else:
			material.albedo_color = Color.BLUE  # Outside surface
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.5
		vertex_sphere.set_surface_override_material(0, material)
		
		wireframe_node.add_child(vertex_sphere)
	
	# Create edge lines
	var edge_connections = [
		[0, 1], [1, 2], [2, 3], [3, 0],  # Bottom face
		[4, 5], [5, 6], [6, 7], [7, 4],  # Top face
		[0, 4], [1, 5], [2, 6], [3, 7]   # Vertical edges
	]
	
	for edge in edge_connections:
		var line = create_edge_line(cube_positions[edge[0]], cube_positions[edge[1]])
		wireframe_node.add_child(line)
	
	return wireframe_node

func create_edge_line(start: Vector3, end: Vector3) -> MeshInstance3D:
	"""Create a line between two points"""
	var line_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	vertices.append(start)
	vertices.append(end)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	line_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = line_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.flags_unshaded = true
	material.vertex_color_use_as_albedo = false
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

func create_labels():
	"""Create text labels for each case"""
	for i in range(fifteen_cases.size()):
		var case_data = fifteen_cases[i]
		var row = i / 5
		var col = i % 5
		
		var label_position = Vector3(
			col * case_spacing - 4 * case_spacing * 0.5,
			-1.5,
			row * case_spacing - 2 * case_spacing * 0.5
		)
		
		var label = Label3D.new()
		label.text = "%s\n%s\nConfig: %d" % [case_data.name, case_data.description, case_data.config]
		label.position = label_position
		label.modulate = Color.WHITE
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		
		add_child(label)
		labels.append(label)

func get_case_color(case_index: int) -> Color:
	"""Get a unique color for each case"""
	var hue = float(case_index) / float(fifteen_cases.size())
	return Color.from_hsv(hue, 0.8, 1.0)

func animate_cases():
	"""Animate the threshold to show how surfaces change"""
	var threshold = sin(animation_time) * 0.5 + 0.5  # Oscillate between 0 and 1
	
	# Update all mesh materials to show animation
	for i in range(meshes.size()):
		var mesh_instance = meshes[i]
		var material = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
		if material:
			material.emission_energy = 0.5 + threshold * 0.5

func _input(event):
	"""Handle input for interactive features"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				show_wireframes = !show_wireframes
				print("Wireframes: %s" % show_wireframes)
			KEY_L:
				show_labels = !show_labels
				for label in labels:
					label.visible = show_labels
			KEY_A:
				animate_threshold = !animate_threshold
				print("Animation: %s" % animate_threshold)
			KEY_R:
				# Regenerate cases
				for child in get_children():
					child.queue_free()
				meshes.clear()
				labels.clear()
				call_deferred("generate_fifteen_cases")
				if show_labels:
					call_deferred("create_labels")
			KEY_EQUAL, KEY_PLUS:
				# Zoom in with + key
				zoom_camera(-zoom_speed)
			KEY_MINUS:
				# Zoom out with - key
				zoom_camera(zoom_speed)
	
	elif event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					# Zoom in with mouse wheel
					zoom_camera(-zoom_speed)
				MOUSE_BUTTON_WHEEL_DOWN:
					# Zoom out with mouse wheel
					zoom_camera(zoom_speed)

func zoom_camera(delta: float):
	"""Zoom the camera in or out"""
	if camera_controller == null:
		return
	
	current_zoom = clamp(current_zoom + delta, min_zoom, max_zoom)
	
	# Update camera position - maintain the same angle but change distance
	var base_height = current_zoom * 0.4  # Height scales with distance
	var base_distance = current_zoom
	
	camera_controller.position = Vector3(0, base_height, base_distance)
	print("Camera zoom: %.1f (distance: %.1f)" % [current_zoom, base_distance])

func _enter_tree():
	print("""
🔮 Marching Cubes 15 Cases Demo
=============================
Controls:
- W: Toggle wireframes
- L: Toggle labels
- A: Toggle animation
- R: Regenerate
- Mouse Wheel: Zoom in/out
- +/-: Zoom in/out (keyboard)

This demonstrates the 15 fundamental surface cases that can occur
in the Marching Cubes algorithm. Each case represents a unique
surface topology configuration.
""") 

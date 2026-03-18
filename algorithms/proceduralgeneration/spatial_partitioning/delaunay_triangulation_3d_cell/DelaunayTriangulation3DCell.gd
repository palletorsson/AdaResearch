@tool
extends MeshInstance3D
class_name DelaunayTriangulation3DCell

@export var generations: int = 7
@export var initial_points: int = 20
@export var subdivision_factor: float = 0.5
@export_range(0.0, 2.0) var randomness: float = 0.3
@export var cell_radius: float = 2.0
@export var show_vertices: bool = true
@export var show_edges: bool = true
@export var show_label: bool = true
@export var use_grabbable_points: bool = true  # Enable draggable vertices

@export var regenerate: bool = false:
	set(value):
		if value:
			generate_cell_body()
			regenerate = false

var vertex_container: Node3D
var edge_container: Node3D
var current_points: Array = []  # Store points for retriangulation
var grab_point_scene: PackedScene

func _ready() -> void:
	# Load grabbable point scene (only at runtime, not in editor)
	if not Engine.is_editor_hint() and use_grabbable_points:
		grab_point_scene = load("res://commons/primitives/point/grab_sphere_point_with_text.tscn")
	generate_cell_body()

func generate_cell_body() -> void:
	# Clear previous visualization
	for child in get_children():
		child.queue_free()

	current_points = generate_hierarchical_points()
	var mesh_data = create_delaunay_mesh(current_points)
	mesh = mesh_data

	# Add vertex visualization
	if show_vertices:
		visualize_vertices(current_points)

	# Add edge visualization
	if show_edges:
		visualize_edges(current_points)

	# Add explanation label
	if show_label:
		add_explanation_label()

func visualize_vertices(points: Array) -> void:
	vertex_container = Node3D.new()
	vertex_container.name = "Vertices"
	add_child(vertex_container)

	var max_grabbable = 12  # Limit grabbable points for usability
	for i in range(min(points.size(), 30)):  # Limit to avoid clutter
		var point = points[i]

		# Use grabbable points at runtime (limited count for usability)
		if not Engine.is_editor_hint() and use_grabbable_points and grab_point_scene and i < max_grabbable:
			var grab_point = grab_point_scene.instantiate()
			grab_point.position = point
			grab_point.set_meta("point_index", i)
			vertex_container.add_child(grab_point)

			# Connect to dropped signal to regenerate mesh
			if grab_point.has_signal("dropped"):
				grab_point.dropped.connect(_on_point_dropped.bind(i, grab_point))
		else:
			# Static sphere for editor or non-grabbable points
			var sphere = MeshInstance3D.new()
			var sphere_mesh = SphereMesh.new()
			sphere_mesh.radius = 0.08
			sphere_mesh.height = 0.16
			sphere.mesh = sphere_mesh
			sphere.position = point

			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.8, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.8, 0.2)
			mat.emission_energy_multiplier = 2.0
			sphere.material_override = mat

			vertex_container.add_child(sphere)

func _on_point_dropped(_pickable, index: int, grab_node: Node3D) -> void:
	# Update the point position when dropped
	if index < current_points.size():
		current_points[index] = grab_node.position
		# Regenerate mesh and edges with new point positions
		_update_mesh_and_edges()

func _update_mesh_and_edges() -> void:
	# Regenerate mesh with new point positions
	var mesh_data = create_delaunay_mesh(current_points)
	mesh = mesh_data

	# Clear and rebuild edges
	if edge_container:
		edge_container.queue_free()
	if show_edges:
		visualize_edges(current_points)

func visualize_edges(points: Array) -> void:
	edge_container = Node3D.new()
	edge_container.name = "Edges"
	add_child(edge_container)

	var edge_mesh = ImmediateMesh.new()
	var edge_instance = MeshInstance3D.new()
	edge_instance.mesh = edge_mesh

	# Draw edges connecting nearby points
	for i in range(min(points.size(), 30)):
		var neighbors = find_nearest_neighbors(i, points, 3)
		for n in neighbors:
			edge_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			edge_mesh.surface_add_vertex(points[i])
			edge_mesh.surface_add_vertex(points[n])
			edge_mesh.surface_end()

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.8, 1.0, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge_instance.material_override = mat

	edge_container.add_child(edge_instance)

func add_explanation_label() -> void:
	var label = Label3D.new()
	label.text = "DELAUNAY TRIANGULATION\nTriangles where no point\nlies inside circumcircle"
	label.position = Vector3(0, cell_radius + 1.0, 0)
	label.font_size = 40
	label.modulate = Color(0.3, 1.0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	add_child(label)

	# Add drag instruction label (only at runtime with grabbable points)
	if not Engine.is_editor_hint() and use_grabbable_points:
		var instruction = Label3D.new()
		instruction.text = "Grab & drag points to\nretriangulate in real-time"
		instruction.position = Vector3(0, -cell_radius - 0.8, 0)
		instruction.font_size = 32
		instruction.modulate = Color(1.0, 0.9, 0.5)
		instruction.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		instruction.outline_size = 6
		add_child(instruction)

# Generate points with generational hierarchy
func generate_hierarchical_points() -> Array:
	var points = []
	
	# Generation 0: Initial points on sphere
	for i in range(initial_points):
		var theta = randf() * TAU
		var phi = acos(2.0 * randf() - 1.0)
		var r = cell_radius
		
		var point = Vector3(
			r * sin(phi) * cos(theta),
			r * sin(phi) * sin(theta),
			r * cos(phi)
		)
		points.append(point)
	
	# Subsequent generations: subdivide and add interior points
	for gen in range(1, generations):
		var gen_points = []
		var layer_radius = cell_radius * (1.0 - float(gen) / float(generations))
		var points_this_gen = int(initial_points * pow(subdivision_factor, gen))
		
		for i in range(points_this_gen):
			var theta = randf() * TAU
			var phi = acos(2.0 * randf() - 1.0)
			var r = layer_radius + randf_range(-randomness, randomness)
			
			var point = Vector3(
				r * sin(phi) * cos(theta),
				r * sin(phi) * sin(theta),
				r * cos(phi)
			)
			gen_points.append(point)
		
		points.append_array(gen_points)
	
	# Add center point
	points.append(Vector3.ZERO)
	
	return points

# Create mesh using simplified Delaunay approach
func create_delaunay_mesh(points: Array) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create convex hull and internal triangulation
	var triangles = triangulate_points(points)
	
	# Build mesh from triangles
	for tri in triangles:
		var p1 = points[tri[0]]
		var p2 = points[tri[1]]
		var p3 = points[tri[2]]
		
		var normal = (p2 - p1).cross(p3 - p1).normalized()
		
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(p1)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(p2)
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(p3)
	
	surface_tool.generate_normals()
	return surface_tool.commit()

# Simplified triangulation using convex hull approach
func triangulate_points(points: Array) -> Array:
	var triangles = []
	var n = points.size()
	
	if n < 4:
		return triangles
	
	# Create triangulation using nearest neighbor approach
	for i in range(n):
		var neighbors = find_nearest_neighbors(i, points, 6)
		
		for j in range(neighbors.size() - 1):
			for k in range(j + 1, neighbors.size()):
				if is_valid_triangle(i, neighbors[j], neighbors[k], points):
					triangles.append([i, neighbors[j], neighbors[k]])
	
	# Remove duplicate triangles
	return remove_duplicate_triangles(triangles)

func find_nearest_neighbors(index: int, points: Array, count: int) -> Array:
	var distances = []
	var point = points[index]
	
	for i in range(points.size()):
		if i != index:
			var dist = point.distance_to(points[i])
			distances.append({"index": i, "distance": dist})
	
	distances.sort_custom(func(a, b): return a.distance < b.distance)
	
	var neighbors = []
	for i in range(min(count, distances.size())):
		neighbors.append(distances[i].index)
	
	return neighbors

func is_valid_triangle(i1: int, i2: int, i3: int, points: Array) -> bool:
	var p1 = points[i1]
	var p2 = points[i2]
	var p3 = points[i3]
	
	# Check if triangle has reasonable area
	var edge1 = p2 - p1
	var edge2 = p3 - p1
	var area = edge1.cross(edge2).length()
	
	return area > 0.001

func remove_duplicate_triangles(triangles: Array) -> Array:
	var unique = []
	var seen = {}
	
	for tri in triangles:
		var sorted_tri = tri.duplicate()
		sorted_tri.sort()
		var key = str(sorted_tri)
		
		if not seen.has(key):
			seen[key] = true
			unique.append(tri)
	
	return unique

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass

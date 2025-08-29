# GridWireChair.gd
# Procedural generation of wire grid chairs
# Inspired by Harry Bertoia's Diamond Chair and wire furniture
extends Node3D
class_name GridWireChair

@export var chair_width: float = 0.7
@export var chair_depth: float = 0.6
@export var chair_height: float = 0.8
@export var seat_height: float = 0.45
@export var wire_thickness: float = 0.003
@export var grid_density: int = 12
@export var curvature_intensity: float = 0.2
@export var generate_on_ready: bool = true

var materials: ModernistMaterials
var wire_frame_instance: MeshInstance3D
var cushion_instance: MeshInstance3D

func _ready():
	materials = ModernistMaterials.new()
	add_child(materials)
	
	if generate_on_ready:
		generate_chair()

func generate_chair():
	"""Generate the complete wire grid chair"""
	clear_existing_geometry()
	
	generate_wire_frame()
	generate_optional_cushion()

func clear_existing_geometry():
	"""Remove existing chair geometry"""
	if wire_frame_instance:
		wire_frame_instance.queue_free()
	if cushion_instance:
		cushion_instance.queue_free()

func generate_wire_frame():
	"""Generate the diamond-pattern wire frame"""
	wire_frame_instance = MeshInstance3D.new()
	add_child(wire_frame_instance)
	
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Generate main shell wire grid
	generate_shell_grid(vertices, normals, indices)
	
	# Generate base/legs
	generate_base_structure(vertices, normals, indices)
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	wire_frame_instance.mesh = array_mesh
	wire_frame_instance.material_override = materials.get_material("chrome")

func generate_shell_grid(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array):
	"""Generate the main shell with diamond wire pattern"""
	
	# Create diamond lattice pattern
	for i in range(grid_density):
		for j in range(grid_density):
			var u = float(i) / (grid_density - 1)
			var v = float(j) / (grid_density - 1)
			
			# Calculate position on curved shell surface
			var pos = calculate_shell_position(u, v)
			
			# Add horizontal wire if not at edge
			if i < grid_density - 1:
				var next_u = float(i + 1) / (grid_density - 1)
				var next_pos = calculate_shell_position(next_u, v)
				add_wire_segment(vertices, normals, indices, pos, next_pos)
			
			# Add vertical wire if not at edge
			if j < grid_density - 1:
				var next_v = float(j + 1) / (grid_density - 1)
				var next_pos = calculate_shell_position(u, next_v)
				add_wire_segment(vertices, normals, indices, pos, next_pos)
			
			# Add diagonal wires for diamond pattern
			if i < grid_density - 1 and j < grid_density - 1:
				var diag_u = float(i + 1) / (grid_density - 1)
				var diag_v = float(j + 1) / (grid_density - 1)
				var diag_pos = calculate_shell_position(diag_u, diag_v)
				
				# Create diamond by alternating diagonal directions
				if (i + j) % 2 == 0:
					add_wire_segment(vertices, normals, indices, pos, diag_pos)
				else:
					var alt_pos = calculate_shell_position(diag_u, v)
					add_wire_segment(vertices, normals, indices, pos, alt_pos)
					var alt_pos2 = calculate_shell_position(u, diag_v)
					add_wire_segment(vertices, normals, indices, alt_pos2, diag_pos)

func calculate_shell_position(u: float, v: float) -> Vector3:
	"""Calculate 3D position on the curved chair shell"""
	# Base position
	var x = (u - 0.5) * chair_width
	var z = (v - 0.5) * chair_depth
	
	# Curved shell calculation
	var y = seat_height
	
	# Seat depression (front area)
	if v > 0.4:
		var seat_factor = (v - 0.4) / 0.6
		y += -curvature_intensity * seat_factor * seat_factor
	
	# Back support curve
	if v < 0.6:
		var back_factor = (0.6 - v) / 0.6
		y += back_factor * chair_height * 0.5
	
	# Side curves for armrests and containment
	var edge_distance = abs(u - 0.5) * 2
	if edge_distance > 0.7:
		var wall_factor = (edge_distance - 0.7) / 0.3
		y += wall_factor * curvature_intensity * 0.8
	
	return Vector3(x, y, z)

func add_wire_segment(vertices: PackedVector3Array, normals: PackedVector3Array,
					  indices: PackedInt32Array, start: Vector3, end: Vector3):
	"""Add a cylindrical wire segment between two points"""
	var base_vertex_count = vertices.size()
	var wire_sides = 6  # Hexagonal cross-section for efficiency
	
	var direction = (end - start).normalized()
	var length = start.distance_to(end)
	
	# Create perpendicular vectors for wire cross-section
	var up = Vector3.UP
	if abs(direction.dot(up)) > 0.9:
		up = Vector3.RIGHT
	
	var right = direction.cross(up).normalized()
	up = right.cross(direction).normalized()
	
	# Generate wire vertices
	for segment in range(2):  # Start and end
		var center = start + direction * length * segment
		
		for i in range(wire_sides):
			var angle = float(i) / wire_sides * TAU
			var local_pos = right * cos(angle) * wire_thickness + up * sin(angle) * wire_thickness
			var vertex_pos = center + local_pos
			var normal = local_pos.normalized()
			
			vertices.append(vertex_pos)
			normals.append(normal)
	
	# Generate wire indices
	for i in range(wire_sides):
		var next_i = (i + 1) % wire_sides
		
		# Side faces of the wire
		indices.append_array([
			base_vertex_count + i,
			base_vertex_count + wire_sides + i,
			base_vertex_count + next_i
		])
		indices.append_array([
			base_vertex_count + next_i,
			base_vertex_count + wire_sides + i,
			base_vertex_count + wire_sides + next_i
		])

func generate_base_structure(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array):
	"""Generate the base support structure"""
	# Simple four-point base connection to ground
	var base_points = [
		Vector3(-chair_width * 0.3, 0, chair_depth * 0.3),
		Vector3(chair_width * 0.3, 0, chair_depth * 0.3),
		Vector3(-chair_width * 0.3, 0, -chair_depth * 0.3),
		Vector3(chair_width * 0.3, 0, -chair_depth * 0.3)
	]
	
	var shell_connection_points = [
		calculate_shell_position(0.2, 0.8),
		calculate_shell_position(0.8, 0.8),
		calculate_shell_position(0.2, 0.2),
		calculate_shell_position(0.8, 0.2)
	]
	
	# Connect base points to shell
	for i in range(4):
		add_wire_segment(vertices, normals, indices, base_points[i], shell_connection_points[i])
	
	# Add cross-bracing at base
	add_wire_segment(vertices, normals, indices, base_points[0], base_points[3])
	add_wire_segment(vertices, normals, indices, base_points[1], base_points[2])

func generate_optional_cushion():
	"""Generate an optional seat cushion"""
	if randf() > 0.5:  # 50% chance of having a cushion
		cushion_instance = MeshInstance3D.new()
		add_child(cushion_instance)
		
		# Simple curved cushion
		var cushion_mesh = create_cushion_mesh()
		cushion_instance.mesh = cushion_mesh
		cushion_instance.position = Vector3(0, seat_height - 0.02, 0.05)
		
		# Random cushion color
		var cushion_materials = ["red_primary", "blue_primary", "canvas", "memory_foam"]
		var material_choice = cushion_materials[randi() % cushion_materials.size()]
		cushion_instance.material_override = materials.get_material(material_choice)

func create_cushion_mesh() -> ArrayMesh:
	"""Create a simple cushion mesh that fits the seat area"""
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var cushion_width = chair_width * 0.6
	var cushion_depth = chair_depth * 0.4
	var cushion_thickness = 0.03
	
	var segments = 8
	
	# Generate cushion vertices
	for i in range(segments + 1):
		for j in range(segments + 1):
			var u = float(i) / segments
			var v = float(j) / segments
			
			var x = (u - 0.5) * cushion_width
			var z = (v - 0.5) * cushion_depth
			var y = cushion_thickness * 0.5
			
			# Slight curve to match seat depression
			y -= curvature_intensity * 0.1 * v * v
			
			vertices.append(Vector3(x, y, z))
			normals.append(Vector3(0, 1, 0))
			uvs.append(Vector2(u, v))
	
	# Generate indices
	for i in range(segments):
		for j in range(segments):
			var current = i * (segments + 1) + j
			var next_row = (i + 1) * (segments + 1) + j
			
			indices.append_array([current, next_row, current + 1])
			indices.append_array([current + 1, next_row, next_row + 1])
	
	# Create mesh arrays
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func regenerate_with_parameters(params: Dictionary):
	"""Regenerate chair with new parameters"""
	if params.has("chair_width"):
		chair_width = params.chair_width
	if params.has("chair_depth"):
		chair_depth = params.chair_depth
	if params.has("chair_height"):
		chair_height = params.chair_height
	if params.has("grid_density"):
		grid_density = params.grid_density
	if params.has("curvature_intensity"):
		curvature_intensity = params.curvature_intensity
	
	generate_chair()

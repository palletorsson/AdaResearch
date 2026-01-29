# SpiralHelicalChair.gd
# Procedural generation of spiral helical chairs
extends Node3D
class_name SpiralHelicalChair

@export var spiral_radius: float = 0.3
@export var spiral_height: float = 0.8
@export var spiral_turns: float = 2.5
@export var tube_radius: float = 0.02
@export var generate_on_ready: bool = true

var materials: ModernistMaterials

func _ready():
	materials = ModernistMaterials.new()
	add_child(materials)
	if generate_on_ready:
		generate_chair()

func generate_chair():
	var spiral_instance = MeshInstance3D.new()
	add_child(spiral_instance)
	
	var curve = Curve3D.new()
	var segments = 100
	
	# Generate spiral curve
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = t * spiral_turns * TAU
		var height = t * spiral_height
		var radius = spiral_radius * (1.0 + sin(t * PI) * 0.3)  # Variable radius
		
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		curve.add_point(Vector3(x, height, z))
	
	# Create tube mesh from curve
	var tube_mesh = create_tube_from_curve(curve)
	spiral_instance.mesh = tube_mesh
	spiral_instance.material_override = materials.get_material("chrome")

func create_tube_from_curve(curve: Curve3D) -> ArrayMesh:
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var tube_segments = 8
	
	for i in range(curve.get_point_count()):
		var pos = curve.get_point_position(i)
		var forward = Vector3.FORWARD
		if i < curve.get_point_count() - 1:
			forward = (curve.get_point_position(i + 1) - pos).normalized()
		
		var up = Vector3.UP
		var right = forward.cross(up).normalized()
		up = right.cross(forward).normalized()
		
		for j in range(tube_segments):
			var angle = float(j) / tube_segments * TAU
			var local_pos = right * cos(angle) * tube_radius + up * sin(angle) * tube_radius
			vertices.append(pos + local_pos)
			normals.append(local_pos.normalized())
	
	# Generate indices (simplified)
	for i in range(curve.get_point_count() - 1):
		for j in range(tube_segments):
			var current = i * tube_segments + j
			var next_ring = (i + 1) * tube_segments + j
			var next_segment = i * tube_segments + ((j + 1) % tube_segments)
			var next_both = (i + 1) * tube_segments + ((j + 1) % tube_segments)
			
			indices.append_array([current, next_ring, next_segment])
			indices.append_array([next_segment, next_ring, next_both])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func regenerate_with_parameters(params: Dictionary):
	for child in get_children():
		if child != materials:
			child.queue_free()
	generate_chair()


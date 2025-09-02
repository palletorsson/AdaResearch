# FlowingRibbonChair.gd
# Procedural generation of flowing ribbon chairs
extends Node3D
class_name FlowingRibbonChair

@export var ribbon_width: float = 0.08
@export var ribbon_thickness: float = 0.02
@export var flow_amplitude: float = 0.3
@export var generate_on_ready: bool = true

var materials: ModernistMaterials

func _ready():
	materials = ModernistMaterials.new()
	add_child(materials)
	if generate_on_ready:
		generate_chair()

func generate_chair():
	var ribbon_instance = MeshInstance3D.new()
	add_child(ribbon_instance)
	
	var curve = Curve3D.new()
	var segments = 50
	
	# Create flowing ribbon path
	for i in range(segments + 1):
		var t = float(i) / segments
		var x = sin(t * PI * 2) * flow_amplitude
		var y = 0.1 + t * 0.6 + sin(t * PI * 3) * 0.1
		var z = -0.3 + t * 0.6
		curve.add_point(Vector3(x, y, z))
	
	# Create ribbon mesh
	var ribbon_mesh = create_ribbon_mesh(curve)
	ribbon_instance.mesh = ribbon_mesh
	ribbon_instance.material_override = materials.get_material("pure_white")

func create_ribbon_mesh(curve: Curve3D) -> ArrayMesh:
	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	for i in range(curve.get_point_count()):
		var pos = curve.get_point_position(i)
		var forward = Vector3.FORWARD
		if i < curve.get_point_count() - 1:
			forward = (curve.get_point_position(i + 1) - pos).normalized()
		
		var right = Vector3.UP.cross(forward).normalized()
		
		# Add ribbon width vertices
		vertices.append(pos + right * ribbon_width/2)
		vertices.append(pos - right * ribbon_width/2)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	
	# Generate indices for ribbon surface
	for i in range(curve.get_point_count() - 1):
		var current_left = i * 2
		var current_right = i * 2 + 1
		var next_left = (i + 1) * 2
		var next_right = (i + 1) * 2 + 1
		
		indices.append_array([current_left, next_left, current_right])
		indices.append_array([current_right, next_left, next_right])
	
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


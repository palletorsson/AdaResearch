extends Node3D
class_name GardenRenderer

# The Axiom Garden - Iteration 3: The Form
# Renders the turtle paths using MultiMeshInstance3D for performance.

@export var material: StandardMaterial3D
@export var thickness: float = 0.05

var multi_mesh_instance: MultiMeshInstance3D

func _ready() -> void:
	multi_mesh_instance = MultiMeshInstance3D.new()
	add_child(multi_mesh_instance)
	
	# Setup the mesh
	var mesh = CylinderMesh.new()
	mesh.top_radius = thickness
	mesh.bottom_radius = thickness
	mesh.height = 1.0 # Base height, will scale
	mesh.radial_segments = 6 # Low poly is fine for neon style
	
	if material:
		mesh.material = material
	else:
		var default_mat = StandardMaterial3D.new()
		default_mat.albedo_color = Color.GREEN
		default_mat.emission_enabled = true
		default_mat.emission = Color.LIME_GREEN
		default_mat.emission_energy_multiplier = 2.0
		mesh.material = default_mat
		
	multi_mesh_instance.multimesh = MultiMesh.new()
	multi_mesh_instance.multimesh.mesh = mesh
	multi_mesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D

func render(lines: Array) -> void:
	var count = lines.size()
	if count == 0:
		multi_mesh_instance.multimesh.instance_count = 0
		return
		
	multi_mesh_instance.multimesh.instance_count = count
	
	for i in range(count):
		var segment = lines[i]
		var start = segment[0]
		var end = segment[1]
		
		var diff = end - start
		var length = diff.length()
		var midpoint = start + (diff / 2.0)
		
		if length < 0.001:
			continue
			
		# Create transform
		var t = Transform3D()
		
		# 1. Position at midpoint
		t.origin = midpoint
		
		# 2. Orient Y axis to point along the segment
		# Default cylinder is along Y.
		# We need a basis where Y points from start to end.
		var up = diff.normalized()
		
		# Calculate a valid right vector (cross product with UP)
		var right = Vector3.RIGHT
		if abs(up.dot(Vector3.RIGHT)) > 0.99:
			right = Vector3.BACK
			
		var forward = right.cross(up).normalized()
		right = up.cross(forward).normalized()
		
		t.basis = Basis(right, up, forward)
		
		# 3. Scale Y to match length
		t.basis = t.basis.scaled(Vector3(1, length, 1))
		
		multi_mesh_instance.multimesh.set_instance_transform(i, t)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


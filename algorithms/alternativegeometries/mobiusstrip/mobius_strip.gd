extends Node3D

@export var major_radius := 1.0
@export var minor_radius := 0.2
@export var segments := 64
@export var twists := 1
@export var width_segments := 16
@export var rotation_speed := 0.2
@export var auto_rotate := true
@export_color_no_alpha var strip_color := Color(0.8, 0.2, 0.8)
@export var metallic := 0.5
@export var roughness := 0.2

var mesh_instance: MeshInstance3D

func _ready():
	generate_mobius_strip()

func _process(delta):
	if auto_rotate:
		rotate_y(rotation_speed * delta)

func generate_mobius_strip():
	# Create mesh instance if it doesn't exist
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)
	
	# Create an ArrayMesh
	var arr_mesh = ArrayMesh.new()
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Generate vertices for the Möbius strip
	for i in range(segments + 1):
		var u = float(i) / segments
		var theta = u * TAU
		
		# Center circle of the Möbius strip
		var center = Vector3(major_radius * cos(theta), 0, major_radius * sin(theta))
		
		# Calculate tangent, normal, and binormal vectors for the tube
		var tangent = Vector3(-sin(theta), 0, cos(theta)).normalized()
		var normal = Vector3(-cos(theta), 0, -sin(theta)).normalized()
		var binormal = Vector3(0, 1, 0)
		
		# For the Möbius strip, we rotate the normal and binormal as we go around
		var twist_angle = theta * 0.5 * twists
		var twisted_normal = normal * cos(twist_angle) + binormal * sin(twist_angle)
		var twisted_binormal = -normal * sin(twist_angle) + binormal * cos(twist_angle)
		
		for j in range(width_segments + 1):
			var v = float(j) / width_segments
			var phi = v * TAU * 0.5  # Only go halfway around for the width
			
			# Convert v from [0,1] to [-1,1] for the strip width
			var width_factor = (v * 2.0 - 1.0) * minor_radius
			
			# Calculate the point on the Möbius strip
			var point = center + twisted_normal * width_factor
			
			vertices.append(point)
			
			# Calculate normal at this point (pointing outward from the surface)
			var point_normal = twisted_binormal
			normals.append(point_normal)
			
			# UV coordinates
			uvs.append(Vector2(u, v))
	
	# Generate indices for the triangles
	for i in range(segments):
		for j in range(width_segments):
			var current = i * (width_segments + 1) + j
			var next_i = (i + 1) * (width_segments + 1) + j
			
			# First triangle
			indices.append(current)
			indices.append(current + 1)
			indices.append(next_i)
			
			# Second triangle
			indices.append(current + 1)
			indices.append(next_i + 1)
			indices.append(next_i)
	
	# Assign arrays to surface
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	# Create the mesh
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	mesh_instance.mesh = arr_mesh
	
	# Create a default material
	var material = StandardMaterial3D.new()
	material.albedo_color = strip_color
	material.metallic = metallic
	material.roughness = roughness
	material.emission_enabled = true
	material.emission = strip_color
	material.emission_energy_multiplier = 0.2
	mesh_instance.set_surface_override_material(0, material)
	material.cull_mode = StandardMaterial3D.CULL_DISABLED

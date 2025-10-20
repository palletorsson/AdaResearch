class_name CrystalRandomWalk
extends Node3D

## Configuration
@export_group("Crystal Properties")
@export var steps: int = 30
@export var tetrahedron_size: float = 1.0
@export var branch_probability: float = 0.3
@export var branch_decay: float = 0.85

@export_group("Visual Effects")
@export var taper_amount: float = 0.97  # Scale multiplier per step
@export var rotation_chaos: float = 0.0  # Random rotation per step (set to 0 for clean tessellation)
@export var color_start: Color = Color(0.5, 0.8, 1.0)
@export var color_end: Color = Color(0.2, 0.4, 0.8)
@export var emission_strength: float = 0.5

@export_group("Generation")
@export var auto_generate: bool = true
@export var random_seed: int = 0

# Internal data
var transforms: Array[Transform3D] = []
var colors: Array[Color] = []
var tetrahedron_mesh: Mesh

# Regular tetrahedron vertices (alternating corners of a cube)
# These form a perfect tetrahedron
const TETRA_VERTS = [
	Vector3(1, 1, 1),
	Vector3(1, -1, -1),
	Vector3(-1, 1, -1),
	Vector3(-1, -1, 1)
]

# Four triangular faces of a tetrahedron
# Each face is defined by 3 vertex indices
const TETRA_FACES = [
	[0, 2, 1],  # Face 0
	[0, 3, 2],  # Face 1
	[0, 1, 3],  # Face 2
	[1, 2, 3]   # Face 3
]

# Face normals and centroids (calculated in _ready)
var face_normals: Array[Vector3] = []
var face_centroids: Array[Vector3] = []

func _ready():
	if random_seed != 0:
		seed(random_seed)

	# Calculate face properties for the tetrahedron
	_calculate_face_properties()

	create_tetrahedron_mesh()

	if auto_generate:
		generate_crystal()

func _calculate_face_properties():
	"""Calculate normals and centroids for each face"""
	face_normals.clear()
	face_centroids.clear()

	for face in TETRA_FACES:
		# Get the three vertices of this face
		var v0 = TETRA_VERTS[face[0]]
		var v1 = TETRA_VERTS[face[1]]
		var v2 = TETRA_VERTS[face[2]]

		# Calculate centroid
		var centroid = (v0 + v1 + v2) / 3.0
		face_centroids.append(centroid)

		# Calculate normal (pointing outward from tetrahedron center)
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var normal = edge1.cross(edge2).normalized()

		# Ensure normal points outward (away from origin)
		if normal.dot(centroid) < 0:
			normal = -normal

		face_normals.append(normal)

func create_tetrahedron_mesh():
	"""Create a regular tetrahedron mesh with flat shading"""
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()

	# Scale vertices by tetrahedron_size
	var scaled_verts = []
	for v in TETRA_VERTS:
		scaled_verts.append(v * tetrahedron_size * 0.5)

	var vertex_index = 0

	# Create each face with its own vertices (for flat shading)
	for i in range(TETRA_FACES.size()):
		var face = TETRA_FACES[i]
		var normal = face_normals[i]

		# Add 3 vertices for this triangular face
		for vert_idx in face:
			verts.append(scaled_verts[vert_idx])
			normals.append(normal)

		# Add indices for this face
		indices.append_array([vertex_index, vertex_index + 1, vertex_index + 2])
		vertex_index += 3

	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_NORMAL] = normals

	print("Tetrahedron mesh - Vertices: ", verts.size(), " Indices: ", indices.size(), " Normals: ", normals.size())

	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)

	tetrahedron_mesh = array_mesh
	print("Tetrahedron mesh created with ", verts.size(), " vertices (", TETRA_FACES.size(), " faces)")
	print("Tetrahedron size: ", tetrahedron_size)

func generate_crystal():
	"""Generate the crystal structure"""
	transforms.clear()
	colors.clear()
	
	# Clear existing multimesh if any
	for child in get_children():
		child.queue_free()
	
	print("Starting crystal generation with ", steps, " steps")
	var start_transform = Transform3D.IDENTITY
	_recursive_walk(start_transform, steps, branch_probability, 0, steps)
	print("Recursive walk completed, creating multimesh with ", transforms.size(), " transforms")
	
	# If no transforms were created, add a test prism at origin
	if transforms.is_empty():
		print("No transforms created, adding test prism at origin")
		transforms.append(Transform3D.IDENTITY)
		colors.append(Color.WHITE)
	
	create_multimesh()

func _recursive_walk(current_transform: Transform3D, remaining_steps: int,
					  branch_chance: float, depth: int, max_depth: int):
	"""Recursively build tetrahedral crystal structure"""
	if remaining_steps <= 0:
		return

	# Safety check to prevent infinite recursion
	if depth > 100:
		print("Warning: Maximum depth reached, stopping recursion")
		return

	# Add current tetrahedron
	var scale_factor = pow(taper_amount, depth)
	var scaled_transform = current_transform.scaled_local(Vector3.ONE * scale_factor)
	transforms.append(scaled_transform)

	# Color gradient based on depth
	var t = float(depth) / float(max_depth)
	colors.append(color_start.lerp(color_end, t))

	# Debug: Print first few transforms
	if transforms.size() <= 5:
		print("Transform ", transforms.size(), ": ", scaled_transform.origin, " Scale: ", scale_factor)

	# Try to branch
	if randf() < branch_chance and remaining_steps > 3:
		var branch_face_idx = randi() % 4  # Pick one of 4 faces
		var branch_transform = _attach_next_tetrahedron(current_transform, branch_face_idx, depth)
		_recursive_walk(branch_transform, remaining_steps - 1,
					   branch_chance * branch_decay, depth + 1, max_depth)

	# Continue main path - pick a random face
	var main_face_idx = randi() % 4
	var next_transform = _attach_next_tetrahedron(current_transform, main_face_idx, depth)
	_recursive_walk(next_transform, remaining_steps - 1,
				   branch_chance, depth + 1, max_depth)

func _attach_next_tetrahedron(base_transform: Transform3D, face_index: int,
							   depth: int) -> Transform3D:
	"""Calculate transform for perfect face-to-face tetrahedral tessellation"""
	var scale_factor = pow(taper_amount, depth)
	var next_scale_factor = pow(taper_amount, depth + 1)

	# Get parent face properties in local space
	var parent_face = TETRA_FACES[face_index]
	var parent_face_centroid = face_centroids[face_index] * tetrahedron_size * 0.5 * scale_factor
	var parent_face_normal = face_normals[face_index]

	# Transform parent face to world space
	var world_face_centroid = base_transform * parent_face_centroid
	var world_face_normal = (base_transform.basis * parent_face_normal).normalized()

	# For perfect tessellation, we need to:
	# 1. Pick which child face will attach (use face 0 for consistency, or random)
	var child_attach_face = 0  # Always attach via face 0 of the child

	# 2. Calculate where the child's center needs to be
	#    Distance from child center to its attachment face
	var child_face_centroid = face_centroids[child_attach_face] * tetrahedron_size * 0.5 * next_scale_factor
	var child_center_to_face_dist = child_face_centroid.length()

	# 3. Position: Move from world face centroid inward along parent normal
	#    by the distance from child center to child's attachment face
	var new_origin = world_face_centroid + world_face_normal * child_center_to_face_dist

	# 4. Orientation: Rotate child so its attachment face aligns (face-to-face)
	#    The child face normal must point opposite to parent face normal
	var child_face_normal = face_normals[child_attach_face]

	# Create a basis that:
	# - Aligns child face normal to be opposite of parent face normal
	# - Starts with base orientation, then flips the attachment face
	var new_basis = base_transform.basis

	# Calculate rotation needed to flip the child face to align with parent face
	# We need child's face normal to point in -world_face_normal direction
	var target_normal = -world_face_normal
	var current_normal = (base_transform.basis * child_face_normal).normalized()

	# Rotation axis: perpendicular to both normals
	var rotation_axis = current_normal.cross(target_normal)
	if rotation_axis.length_squared() > 0.0001:
		rotation_axis = rotation_axis.normalized()
		var angle = current_normal.angle_to(target_normal)
		var rotation = Basis(rotation_axis, angle)
		new_basis = rotation * new_basis
	elif current_normal.dot(target_normal) < 0:
		# Normals are opposite, rotate 180° around any perpendicular axis
		var perp = Vector3.UP if abs(current_normal.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		rotation_axis = current_normal.cross(perp).normalized()
		new_basis = Basis(rotation_axis, PI) * new_basis

	var new_transform = Transform3D(new_basis, new_origin)

	# Optional: add rotation chaos (will break perfect tessellation)
	if rotation_chaos > 0:
		var chaos_axis = world_face_normal
		new_transform.basis = Basis(chaos_axis, randf_range(-rotation_chaos, rotation_chaos)) * new_transform.basis

	return new_transform

func create_multimesh():
	"""Create MultiMeshInstance3D from generated transforms"""
	var mmi = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()

	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tetrahedron_mesh
	mm.use_colors = true
	mm.instance_count = transforms.size()

	# Set all transforms and colors
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])

		# Add emission to color
		var col = colors[i] if i < colors.size() else Color.WHITE
		col.a = emission_strength  # Use alpha for emission (if shader supports it)
		mm.set_instance_color(i, col)

	mmi.multimesh = mm

	# Create material with emission
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = color_start
	material.emission_energy_multiplier = emission_strength
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	mmi.material_override = material

	add_child(mmi)
	print("Crystal generated with ", transforms.size(), " tetrahedra")
	print("Tetrahedron mesh size: ", tetrahedron_mesh.get_faces().size() if tetrahedron_mesh else 0, " faces")
	print("MultiMesh instance count: ", mm.instance_count)
	print("MultiMesh use_colors: ", mm.use_colors)
	print("Material emission: ", material.emission, " Energy: ", material.emission_energy_multiplier)
	print("MultiMeshInstance3D added to scene")

## Public API
func regenerate():
	"""Regenerate the crystal with current settings"""
	generate_crystal()

func set_seed(new_seed: int):
	"""Set random seed and regenerate"""
	random_seed = new_seed
	seed(new_seed)
	generate_crystal()

func get_crystal_stats() -> Dictionary:
	"""Get statistics about the generated crystal"""
	var bounds = _calculate_bounds()
	return {
		"total_tetrahedra": transforms.size(),
		"tetrahedron_size": tetrahedron_size,
		"crystal_bounds": bounds,
		"branch_probability": branch_probability,
		"taper_amount": taper_amount,
		"rotation_chaos": rotation_chaos
	}

func _calculate_bounds() -> Dictionary:
	"""Calculate the bounding box of the crystal"""
	if transforms.is_empty():
		return {"min": Vector3.ZERO, "max": Vector3.ZERO}
	
	var min_pos = transforms[0].origin
	var max_pos = transforms[0].origin
	
	for transform in transforms:
		min_pos.x = min(min_pos.x, transform.origin.x)
		min_pos.y = min(min_pos.y, transform.origin.y)
		min_pos.z = min(min_pos.z, transform.origin.z)
		max_pos.x = max(max_pos.x, transform.origin.x)
		max_pos.y = max(max_pos.y, transform.origin.y)
		max_pos.z = max(max_pos.z, transform.origin.z)
	
	var bounds = {"min": min_pos, "max": max_pos}
	print("Crystal bounds - Min: ", min_pos, " Max: ", max_pos, " Size: ", max_pos - min_pos)
	return bounds

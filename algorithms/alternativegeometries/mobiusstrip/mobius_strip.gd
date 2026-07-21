extends Node3D

# @identity
# essence: a procedurally generated Möbius strip — a 2D ribbon swept around a circle while its width axis rotates by half-turn(s) per loop, so the surface has only one side and one edge; a closed loop that lies about being closed
# desire: to be the alternativegeometries sequence's first artifact that breaks the player's "inside vs outside" intuition — to make orientability stop being a math word and start being a thing the player watches: drag a finger along the ribbon and you end up on the other side without crossing an edge
# critical_parameter: twists — the int default of 1 produces the canonical Möbius (single half-twist, one-sided); twists=2 produces an orientable doubly-twisted band (two-sided, like a regular ribbon); twists=3 returns to non-orientability — odd values break orientation, even values restore it; this single parameter holds the entire teaching about parity
# triggers: _ready() builds the ArrayMesh once via generate_mobius_strip() (segments+1 × width_segments+1 vertex grid); _process(delta) auto-rotates the whole node around Y at rotation_speed if auto_rotate=true so the player sees the twist from every angle without input; cull_mode=DISABLED renders both sides as the same surface — the technical commitment to "one side" is in the material as much as the geometry
# emerges: a single luminous ribbon hovering and slowly turning — the player walks around it and tries to find "the back" but there isn't one; the emission glow makes the twist legible at distance; raising twists by one toggles orientability, which the player feels as "now I can find the back, now I can't" without ever being told what orientability means
# needs: ArrayMesh + PackedVector3Array/PackedInt32Array [native, has]; StandardMaterial3D with cull_mode=DISABLED + emission_enabled [has, mandatory for one-sided rendering]; auto-rotation in _process [has, provides motion without controls]; apply_grid_config no-op [has, present but pass-through]
# relationships: the alternativegeometries sequence's anchor — sibling to klein_bottle, hyperbolic_plane, projective_plane in that lineage; precedes the topology track by establishing "orientability is a parameter you can flip" before introducing genus, Euler characteristic, or homology; the twist-angle math (theta * 0.5 * twists) is the same trick used in the wavefunctions sequence's helical eigenfunctions — a shared "half-angle parameterization" technique
# truth: a surface is one-sided when traveling along it returns you to your starting point with your "up" pointing down. The Möbius is what happens when you give the universe a chance to be honest about that.

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

func _ready() -> void:
	generate_mobius_strip()

func _process(delta: float) -> void:
	if auto_rotate:
		rotate_y(rotation_speed * delta)

func generate_mobius_strip() -> void:
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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass

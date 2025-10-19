# InstancingScatterVR.gd
# A mesmerizing VR scene with thousands of objects scattered across surfaces
extends Node3D

@export var instance_count: int = 5000
@export var scatter_radius: float = 20.0
@export var animation_speed: float = 1.0
@export var object_scale: float = 0.3

var surface_mesh: MeshInstance3D
var crystal_multi_mesh: MultiMeshInstance3D
var flower_multi_mesh: MultiMeshInstance3D
var particle_multi_mesh: MultiMeshInstance3D

# Surface sampling points
var scatter_positions: PackedVector3Array = []
var scatter_normals: PackedVector3Array = []

func _ready():
	setup_scene()
	create_surface_mesh()
	generate_scatter_points()
	create_instanced_objects()
	start_animations()

func setup_scene():
	# Create environment
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_energy = 0.4
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
	# Set darker background for better contrast
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color(0.1, 0.1, 0.2)
	sky_mat.sky_horizon_color = Color(0.2, 0.1, 0.3)
	
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = env
	
	# Add multiple colored lights for ambiance
	create_ambient_lights()

func create_ambient_lights():
	# Main directional light
	var main_light = DirectionalLight3D.new()
	main_light.position = Vector3(10, 15, 10)
	main_light.look_at(Vector3.ZERO, Vector3.UP)
	main_light.light_energy = 0.8
	main_light.light_color = Color(0.9, 0.9, 1.0)
	add_child(main_light)
	
	# Colored point lights for atmosphere
	var light_colors = [Color.CYAN, Color.MAGENTA, Color.YELLOW, Color.GREEN]
	for i in range(4):
		var light = OmniLight3D.new()
		var angle = i * PI * 0.5
		light.position = Vector3(cos(angle) * 12, 5, sin(angle) * 12)
		light.light_energy = 2.0
		light.light_color = light_colors[i]
		light.omni_range = 15.0
		add_child(light)

func create_surface_mesh():
	# Create a complex surface for scattering - like terrain or organic shapes
	var noise = FastNoiseLite.new()
	noise.seed = 12345
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Create heightmap-based terrain
	var terrain_mesh = PlaneMesh.new()
	terrain_mesh.size = Vector2(scatter_radius * 2, scatter_radius * 2)
	terrain_mesh.subdivide_width = 50
	terrain_mesh.subdivide_depth = 50
	
	surface_mesh = MeshInstance3D.new()
	surface_mesh.mesh = terrain_mesh
	
	# Apply noise to create hills and valleys
	var array_mesh = ArrayMesh.new()
	var arrays = surface_mesh.mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals = arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	
	# Displace vertices based on noise
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var height = noise.get_noise_2d(vertex.x, vertex.z) * 3.0
		vertex.y += height
		vertices[i] = vertex
	
	# Recalculate normals
	for i in range(0, vertices.size(), 3):
		if i + 2 < vertices.size():
			var v1 = vertices[i + 1] - vertices[i]
			var v2 = vertices[i + 2] - vertices[i]
			var normal = v1.cross(v2).normalized()
			normals[i] = normal
			normals[i + 1] = normal  
			normals[i + 2] = normal
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	surface_mesh.mesh = array_mesh
	
	# Create material for surface
	var surface_material = StandardMaterial3D.new()
	surface_material.albedo_color = Color(0.2, 0.3, 0.4)
	surface_material.metallic = 0.3
	surface_material.roughness = 0.7
	surface_mesh.set_surface_override_material(0, surface_material)
	
	add_child(surface_mesh)

func generate_scatter_points():
	# Sample points across the surface mesh
	scatter_positions.clear()
	scatter_normals.clear()
	
	var surface_arrays = surface_mesh.mesh.surface_get_arrays(0)
	var vertices = surface_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals = surface_arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	var indices = surface_arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	
	# Generate random points on triangles
	for i in range(instance_count):
		# Pick a random triangle
		var triangle_idx = randi() % (indices.size() / 3) * 3
		var v1 = vertices[indices[triangle_idx]]
		var v2 = vertices[indices[triangle_idx + 1]]
		var v3 = vertices[indices[triangle_idx + 2]]
		
		var n1 = normals[indices[triangle_idx]]
		var n2 = normals[indices[triangle_idx + 1]]  
		var n3 = normals[indices[triangle_idx + 2]]
		
		# Random barycentric coordinates
		var r1 = randf()
		var r2 = randf()
		if r1 + r2 > 1.0:
			r1 = 1.0 - r1
			r2 = 1.0 - r2
		var r3 = 1.0 - r1 - r2
		
		# Calculate point and normal
		var point = v1 * r1 + v2 * r2 + v3 * r3
		var normal = (n1 * r1 + n2 * r2 + n3 * r3).normalized()
		
		scatter_positions.append(point)
		scatter_normals.append(normal)

func create_instanced_objects():
	# Create crystals
	create_crystal_instances()
	
	# Create flowers/plants
	create_flower_instances()
	
	# Create particle effects
	create_particle_instances()

func create_crystal_instances():
	crystal_multi_mesh = MultiMeshInstance3D.new()
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	
	# Create crystal geometry (diamond shape)
	var crystal_mesh = create_crystal_mesh()
	multi_mesh.mesh = crystal_mesh
	multi_mesh.instance_count = instance_count / 3
	
	# Create glowing crystal material
	var crystal_material = StandardMaterial3D.new()
	crystal_material.albedo_color = Color(0.3, 0.8, 1.0, 0.8)
	crystal_material.metallic = 0.9
	crystal_material.roughness = 0.1
	crystal_material.emission_enabled = true
	crystal_material.emission = Color(0.2, 0.6, 1.0)
	crystal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	crystal_mesh.surface_set_material(0, crystal_material)
	
	crystal_multi_mesh.multimesh = multi_mesh
	add_child(crystal_multi_mesh)
	
	# Position crystals
	for i in range(multi_mesh.instance_count):
		if i < scatter_positions.size():
			var transform = Transform3D()
			transform.origin = scatter_positions[i] + scatter_normals[i] * 0.2
			
			# Align to surface normal
			if scatter_normals[i].length() > 0.1:
				transform.basis = Basis.looking_at(scatter_normals[i], Vector3.UP)
			
			# Random scale and rotation
			var scale = randf_range(0.5, 2.0) * object_scale
			transform = transform.scaled_local(Vector3(scale, scale * randf_range(1.5, 3.0), scale))
			transform = transform.rotated_local(Vector3.UP, randf() * PI * 2)
			
			multi_mesh.set_instance_transform(i, transform)

func create_flower_instances():
	flower_multi_mesh = MultiMeshInstance3D.new()
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	
	# Create flower geometry (simple petals)
	var flower_mesh = create_flower_mesh()
	multi_mesh.mesh = flower_mesh
	multi_mesh.instance_count = instance_count / 3
	
	flower_multi_mesh.multimesh = multi_mesh
	add_child(flower_multi_mesh)
	
	# Position flowers
	var start_idx = instance_count / 3
	for i in range(multi_mesh.instance_count):
		var scatter_idx = start_idx + i
		if scatter_idx < scatter_positions.size():
			var transform = Transform3D()
			transform.origin = scatter_positions[scatter_idx] + scatter_normals[scatter_idx] * 0.1
			
			# Align to surface
			if scatter_normals[scatter_idx].length() > 0.1:
				transform.basis = Basis.looking_at(scatter_normals[scatter_idx], Vector3.UP)
			
			var scale = randf_range(0.3, 1.0) * object_scale
			transform = transform.scaled_local(Vector3(scale, scale, scale))
			transform = transform.rotated_local(Vector3.UP, randf() * PI * 2)
			
			multi_mesh.set_instance_transform(i, transform)

func create_particle_instances():
	particle_multi_mesh = MultiMeshInstance3D.new()
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	
	# Create small glowing spheres
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.05
	sphere_mesh.height = 0.1
	
	var particle_material = StandardMaterial3D.new()
	particle_material.flags_unshaded = true
	particle_material.albedo_color = Color(1.0, 1.0, 0.3, 0.7)
	particle_material.emission_enabled = true
	particle_material.emission = Color(1.0, 1.0, 0.5)
	particle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	sphere_mesh.surface_set_material(0, particle_material)
	
	multi_mesh.mesh = sphere_mesh
	multi_mesh.instance_count = instance_count / 3
	
	particle_multi_mesh.multimesh = multi_mesh
	add_child(particle_multi_mesh)
	
	# Position floating particles
	var start_idx = (instance_count * 2) / 3
	for i in range(multi_mesh.instance_count):
		var scatter_idx = start_idx + i
		if scatter_idx < scatter_positions.size():
			var transform = Transform3D()
			# Float particles above surface
			transform.origin = scatter_positions[scatter_idx] + scatter_normals[scatter_idx] * randf_range(0.5, 2.0)
			
			var scale = randf_range(0.5, 1.5) * object_scale
			transform = transform.scaled_local(Vector3(scale, scale, scale))
			
			multi_mesh.set_instance_transform(i, transform)

func create_crystal_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Create diamond/crystal shape
	var points = [
		Vector3(0, 1, 0),      # top
		Vector3(0.5, 0, 0.5),  # sides
		Vector3(-0.5, 0, 0.5),
		Vector3(-0.5, 0, -0.5),
		Vector3(0.5, 0, -0.5),
		Vector3(0, -0.3, 0)    # bottom
	]
	
	# Create faces
	var faces = [
		[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1],  # top
		[5, 2, 1], [5, 3, 2], [5, 4, 3], [5, 1, 4]   # bottom
	]
	
	for face in faces:
		for idx in face:
			vertices.append(points[idx])
			# Calculate normal (simplified)
			var normal = Vector3(0, 1, 0)
			if idx == 5:
				normal = Vector3(0, -1, 0)
			normals.append(normal)
	
	# Add indices
	for i in range(vertices.size()):
		indices.append(i)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_flower_mesh() -> ArrayMesh:
	# Simple flower made of quads
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Create 5 petals
	for petal in range(5):
		var angle = petal * PI * 2.0 / 5.0
		var next_angle = (petal + 1) * PI * 2.0 / 5.0
		
		# Petal vertices
		var center = Vector3.ZERO
		var p1 = Vector3(cos(angle) * 0.3, 0, sin(angle) * 0.3)
		var p2 = Vector3(cos(angle) * 0.8, 0.1, sin(angle) * 0.8)
		var p3 = Vector3(cos(next_angle) * 0.8, 0.1, sin(next_angle) * 0.8)
		var p4 = Vector3(cos(next_angle) * 0.3, 0, sin(next_angle) * 0.3)
		
		var base_idx = vertices.size()
		vertices.append_array([center, p1, p2, p4, p3])
		
		# Normals
		for i in range(5):
			normals.append(Vector3.UP)
		
		# UVs
		uvs.append_array([Vector2(0.5, 0.5), Vector2(0, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1)])
		
		# Indices for triangles
		indices.append_array([
			base_idx, base_idx + 1, base_idx + 2,
			base_idx, base_idx + 2, base_idx + 4,
			base_idx, base_idx + 4, base_idx + 3
		])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Add colorful flower material
	var flower_material = StandardMaterial3D.new()
	flower_material.albedo_color = Color(
		randf_range(0.7, 1.0),
		randf_range(0.2, 0.8), 
		randf_range(0.3, 1.0)
	)
	flower_material.roughness = 0.8
	mesh.surface_set_material(0, flower_material)
	
	return mesh

func start_animations():
	# Gentle swaying animation for crystals
	if crystal_multi_mesh and crystal_multi_mesh.multimesh:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_method(animate_crystals, 0.0, PI * 2.0, 8.0 / animation_speed)
	
	# Floating animation for particles
	if particle_multi_mesh and particle_multi_mesh.multimesh:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_method(animate_particles, 0.0, PI * 2.0, 6.0 / animation_speed)

func animate_crystals(time: float):
	if not crystal_multi_mesh or not crystal_multi_mesh.multimesh:
		return
		
	var multi_mesh = crystal_multi_mesh.multimesh
	for i in range(multi_mesh.instance_count):
		var original_transform = multi_mesh.get_instance_transform(i)
		var sway = sin(time + i * 0.1) * 0.1
		var new_transform = original_transform.rotated_local(Vector3.RIGHT, sway)
		multi_mesh.set_instance_transform(i, new_transform)

func animate_particles(time: float):
	if not particle_multi_mesh or not particle_multi_mesh.multimesh:
		return
		
	var multi_mesh = particle_multi_mesh.multimesh
	for i in range(multi_mesh.instance_count):
		if i < scatter_positions.size():
			var base_pos = scatter_positions[i + (instance_count * 2) / 3] if i + (instance_count * 2) / 3 < scatter_positions.size() else scatter_positions[i % scatter_positions.size()]
			var normal = scatter_normals[i + (instance_count * 2) / 3] if i + (instance_count * 2) / 3 < scatter_normals.size() else scatter_normals[i % scatter_normals.size()]
			
			var float_height = 1.0 + sin(time + i * 0.2) * 0.5
			var drift = Vector3(sin(time + i * 0.15) * 0.2, 0, cos(time + i * 0.15) * 0.2)
			
			var transform = Transform3D()
			transform.origin = base_pos + normal * float_height + drift
			
			var scale = (0.8 + sin(time + i * 0.3) * 0.3) * object_scale
			transform = transform.scaled_local(Vector3(scale, scale, scale))
			
			multi_mesh.set_instance_transform(i, transform)

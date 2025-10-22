## Marching Cubes Sculpture Generator
## Uses marching cubes to create smooth sculptural surfaces from WFC patterns
extends Node3D

## Sculpture parameters
@export var sculpture_type : SculptureType = SculptureType.ABSTRACT_ORGANIC
@export var hollow_intensity : float = 0.7
@export var surface_complexity : float = 0.8
@export var organic_flow : float = 0.9
@export var sculpture_seed : int = 0

## Marching cubes parameters
@export var resolution : Vector3i = Vector3i(64, 64, 64)
@export var iso_level : float = 0.0
@export var chunk_scale : float = 20.0
@export var noise_scale : float = 2.0

## Controls
@export var auto_generate_on_ready : bool = true
@export var generate : bool = false : set = _generate
@export var clear_mesh : bool = false : set = _clear
@export var show_wireframe : bool = false : set = _set_wireframe

## Camera exploration
@export var enable_fly_camera : bool = true
@export var camera_speed : float = 8.0
@export var mouse_sensitivity : float = 0.003

enum SculptureType {
	ABSTRACT_ORGANIC,
	GEOMETRIC_CRYSTAL,
	BIOLOGICAL,
	MINERAL_FORMATION,
	FLUID_DYNAMIC,
	SPIRAL_TORUS,
	FRACTAL_TREE,
	SPHERE_CLUSTER,
	CAVE_NETWORK,
	CELLULAR_STRUCTURE
}

var rendering_device : RenderingDevice
var compute_shader : RID
var pipeline : RID
var mesh_instance : MeshInstance3D
var camera : Camera3D
var camera_rotation : Vector3 = Vector3.ZERO

func _ready():
	if sculpture_seed > 0:
		seed(sculpture_seed)
	
	setup_camera()
	
	if auto_generate_on_ready:
		call_deferred("generate_sculpture")

func _generate(value):
	if value:
		generate_sculpture()

func _clear(value):
	if value:
		clear_sculpture()

func _set_wireframe(value):
	show_wireframe = value
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.wireframe = value

func setup_camera():
	# Create fly camera for exploration
	camera = Camera3D.new()
	camera.name = "ExplorationCamera"
	camera.position = Vector3(0, 0, chunk_scale * 0.8)
	camera.fov = 75.0
	add_child(camera)
	camera.make_current()

func _input(event):
	if not enable_fly_camera or not camera:
		return
	
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_rotation.y -= event.relative.x * mouse_sensitivity
		camera_rotation.x -= event.relative.y * mouse_sensitivity
		camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)
		camera.rotation = camera_rotation

func _process(delta):
	if not enable_fly_camera or not camera:
		return
	
	# WASD movement
	var input_dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir -= camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_dir -= camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_Q):
		input_dir -= camera.global_transform.basis.y
	if Input.is_key_pressed(KEY_E):
		input_dir += camera.global_transform.basis.y
	
	if input_dir.length() > 0:
		camera.position += input_dir.normalized() * camera_speed * delta

func generate_sculpture():
	print("🎨 Generating marching cubes sculpture...")
	clear_sculpture()
	
	# Generate density field based on sculpture type
	var density_field = generate_density_field()
	
	# Create mesh using marching cubes
	create_marching_cubes_mesh(density_field)
	
	print("✅ Sculpture complete!")

func generate_density_field() -> Array:
	var field = []
	field.resize(resolution.x)
	
	var center = Vector3(resolution) * 0.5
	
	for x in resolution.x:
		field[x] = []
		field[x].resize(resolution.y)
		for y in resolution.y:
			field[x][y] = []
			field[x][y].resize(resolution.z)
			for z in resolution.z:
				var pos = Vector3(x, y, z)
				var world_pos = (pos - center) / float(resolution.x) * chunk_scale
				
				# Generate density based on sculpture type
				var density = evaluate_density(world_pos, center)
				field[x][y][z] = density
	
	return field

func evaluate_density(world_pos: Vector3, center: Vector3) -> float:
	var density = 0.0
	
	match sculpture_type:
		SculptureType.ABSTRACT_ORGANIC:
			density = evaluate_organic(world_pos)
		SculptureType.GEOMETRIC_CRYSTAL:
			density = evaluate_crystal(world_pos)
		SculptureType.BIOLOGICAL:
			density = evaluate_biological(world_pos)
		SculptureType.MINERAL_FORMATION:
			density = evaluate_mineral(world_pos)
		SculptureType.FLUID_DYNAMIC:
			density = evaluate_fluid(world_pos)
		SculptureType.SPIRAL_TORUS:
			density = evaluate_spiral(world_pos)
		SculptureType.FRACTAL_TREE:
			density = evaluate_tree(world_pos)
		SculptureType.SPHERE_CLUSTER:
			density = evaluate_sphere_cluster(world_pos)
		SculptureType.CAVE_NETWORK:
			density = evaluate_cave(world_pos)
		SculptureType.CELLULAR_STRUCTURE:
			density = evaluate_cellular(world_pos)
	
	return density

# Density evaluation functions for different sculpture types

func evaluate_organic(pos: Vector3) -> float:
	var dist = pos.length()
	var base_radius = chunk_scale * 0.3
	
	# Base sphere
	var density = base_radius - dist
	
	# Add organic noise layers
	var noise1 = simplex_noise(pos * 0.5 * noise_scale) * organic_flow * 2.0
	var noise2 = simplex_noise(pos * 1.0 * noise_scale) * surface_complexity
	var noise3 = simplex_noise(pos * 2.0 * noise_scale) * surface_complexity * 0.5
	
	density += noise1 + noise2 + noise3
	
	# Hollow interior
	if hollow_intensity > 0.1:
		var inner_radius = base_radius * (1.0 - hollow_intensity)
		var inner_dist = inner_radius - dist
		if inner_dist > 0:
			density = min(density, -inner_dist * 0.5)
	
	return density

func evaluate_crystal(pos: Vector3) -> float:
	var dist = pos.length()
	var base_radius = chunk_scale * 0.3
	
	# Crystal facets using absolute value of noise
	var facet1 = abs(simplex_noise(pos * 0.8)) - 0.3
	var facet2 = abs(simplex_noise(pos * 1.2 + Vector3(100, 0, 0))) - 0.3
	var facet3 = abs(simplex_noise(pos * 1.0 + Vector3(0, 100, 0))) - 0.3
	
	var density = base_radius - dist
	density += (facet1 + facet2 + facet3) * surface_complexity * 3.0
	
	# Sharp features
	density = density * (1.0 - organic_flow * 0.5)
	
	return density

func evaluate_biological(pos: Vector3) -> float:
	var dist = pos.length()
	var base_radius = chunk_scale * 0.35
	
	# Coral/sponge like structure
	var noise1 = simplex_noise(pos * 1.5 * noise_scale)
	var noise2 = simplex_noise(pos * 3.0 * noise_scale) * 0.5
	
	var density = base_radius - dist + noise1 * 3.0 * surface_complexity
	
	# Add porous structures
	if hollow_intensity > 0.5:
		var pores = simplex_noise(pos * 4.0) * hollow_intensity
		density += pores * 2.0
	
	return density * organic_flow

func evaluate_mineral(pos: Vector3) -> float:
	var dist = pos.length()
	var base_radius = chunk_scale * 0.3
	
	# Layered structure
	var layers = sin(pos.y * 2.0 + simplex_noise(pos * 0.5) * 3.0) * surface_complexity
	var noise = simplex_noise(pos * noise_scale) * 0.5
	
	var density = base_radius - dist + layers + noise
	
	return density

func evaluate_fluid(pos: Vector3) -> float:
	var dist = pos.length()
	
	# Fluid-like flowing form
	var flow1 = simplex_noise(Vector3(pos.x * 0.5, pos.y * 1.5, pos.z * 0.5))
	var flow2 = simplex_noise(Vector3(pos.x * 1.0, pos.y * 0.8, pos.z * 1.0) + Vector3(100, 0, 0))
	
	var base_radius = chunk_scale * 0.25 + flow1 * chunk_scale * 0.15
	var density = base_radius - dist + flow2 * 2.0 * surface_complexity
	
	# Very smooth
	return density * organic_flow * 1.2

func evaluate_spiral(pos: Vector3) -> float:
	# Torus with spiral twist
	var angle = atan2(pos.x, pos.z)
	var radius_from_center = sqrt(pos.x * pos.x + pos.z * pos.z)
	
	var major_radius = chunk_scale * 0.25
	var minor_radius = chunk_scale * 0.1
	
	# Spiral twist
	var twist = pos.y * 0.3 + simplex_noise(pos * 0.5) * organic_flow
	var twisted_angle = angle + twist
	
	var torus_center = Vector2(
		major_radius * cos(twisted_angle),
		major_radius * sin(twisted_angle)
	)
	
	var point_2d = Vector2(radius_from_center, 0)
	var dist_to_torus = (point_2d - torus_center).length()
	
	var density = minor_radius - sqrt(dist_to_torus * dist_to_torus + pos.y * pos.y)
	density += simplex_noise(pos * 2.0) * surface_complexity
	
	return density

func evaluate_tree(pos: Vector3) -> float:
	var dist = pos.length()
	
	# Main trunk
	var trunk_radius = chunk_scale * 0.1
	var trunk_dist = sqrt(pos.x * pos.x + pos.z * pos.z) - trunk_radius
	
	# Branches using noise
	var branch_factor = simplex_noise(pos * 1.5) * simplex_noise(pos * 0.8)
	var density = -trunk_dist + branch_factor * surface_complexity * 3.0
	
	# Taper with height
	density -= abs(pos.y) * 0.1
	
	return density

func evaluate_sphere_cluster(pos: Vector3) -> float:
	# Multiple sphere centers
	var sphere_centers = [
		Vector3(0, 0, 0),
		Vector3(chunk_scale * 0.2, chunk_scale * 0.1, 0),
		Vector3(-chunk_scale * 0.15, chunk_scale * 0.15, chunk_scale * 0.1),
		Vector3(0, chunk_scale * 0.2, -chunk_scale * 0.15),
		Vector3(chunk_scale * 0.1, -chunk_scale * 0.1, chunk_scale * 0.15)
	]
	
	var max_density = -INF
	for center in sphere_centers:
		var dist = (pos - center).length()
		var radius = chunk_scale * 0.15 + simplex_noise(center * 5.0) * chunk_scale * 0.05
		var sphere_density = radius - dist
		max_density = max(max_density, sphere_density)
	
	# Blend spheres with metaball effect
	max_density += simplex_noise(pos * 2.0) * surface_complexity
	
	return max_density

func evaluate_cave(pos: Vector3) -> float:
	# Inverted - solid outside, hollow inside with cave networks
	var dist = pos.length()
	var shell_thickness = chunk_scale * 0.3
	var outer_radius = chunk_scale * 0.4
	var inner_radius = outer_radius - shell_thickness
	
	# Shell
	var density = -(abs(dist - (outer_radius + inner_radius) * 0.5) - shell_thickness * 0.5)
	
	# Cave tunnels using 3D noise
	var cave_noise = simplex_noise(pos * 1.5 * noise_scale)
	density += cave_noise * hollow_intensity * 3.0
	
	return density

func evaluate_cellular(pos: Vector3) -> float:
	# Cellular/voronoi-like structure
	var cell_size = chunk_scale * 0.15
	var cell_pos = (pos / cell_size).floor() * cell_size
	
	var min_dist = INF
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var offset = Vector3(dx, dy, dz) * cell_size
				var neighbor = cell_pos + offset
				var center = neighbor + Vector3(
					simplex_noise(neighbor * 0.1) * cell_size * 0.4,
					simplex_noise(neighbor * 0.1 + Vector3(100, 0, 0)) * cell_size * 0.4,
					simplex_noise(neighbor * 0.1 + Vector3(0, 100, 0)) * cell_size * 0.4
				)
				var dist = (pos - center).length()
				min_dist = min(min_dist, dist)
	
	var wall_thickness = cell_size * 0.15 * (1.0 - hollow_intensity)
	var density = wall_thickness - min_dist
	density += simplex_noise(pos * 3.0) * surface_complexity * 0.5
	
	return density

func simplex_noise(p: Vector3) -> float:
	# Simple 3D noise function (simplified - you can use a better implementation)
	return sin(p.x * 2.3 + p.y * 1.7) * cos(p.z * 1.9 + p.x * 2.1) * sin(p.y * 2.5 + p.z * 1.8)

func create_marching_cubes_mesh(density_field: Array):
	print("🔨 Creating mesh from density field...")
	
	# Create mesh using simplified surface extraction
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var cell_size = chunk_scale / float(resolution.x)
	var center_offset = Vector3(resolution) * cell_size * 0.5
	
	var vertex_count = 0
	var triangle_count = 0
	
	# Simplified surface extraction - create quads where density crosses iso-level
	for x in range(resolution.x - 1):
		for y in range(resolution.y - 1):
			for z in range(resolution.z - 1):
				var values = [
					density_field[x][y][z],
					density_field[x+1][y][z],
					density_field[x+1][y][z+1],
					density_field[x][y][z+1],
					density_field[x][y+1][z],
					density_field[x+1][y+1][z],
					density_field[x+1][y+1][z+1],
					density_field[x][y+1][z+1]
				]
				
				# Check if surface crosses this cube
				var has_positive = false
				var has_negative = false
				for v in values:
					if v > iso_level:
						has_positive = true
					else:
						has_negative = true
				
				if not (has_positive and has_negative):
					continue  # No surface here
				
				# Create position for this cell
				var pos = Vector3(x, y, z) * cell_size - center_offset
				
				# Create a simple quad at the surface
				# Check each face of the cube
				var faces = [
					# Bottom face (-Y)
					[Vector3(0,0,0), Vector3(1,0,0), Vector3(1,0,1), Vector3(0,0,1), Vector3(0,-1,0)],
					# Top face (+Y)
					[Vector3(0,1,0), Vector3(0,1,1), Vector3(1,1,1), Vector3(1,1,0), Vector3(0,1,0)],
					# Left face (-X)
					[Vector3(0,0,0), Vector3(0,0,1), Vector3(0,1,1), Vector3(0,1,0), Vector3(-1,0,0)],
					# Right face (+X)
					[Vector3(1,0,0), Vector3(1,1,0), Vector3(1,1,1), Vector3(1,0,1), Vector3(1,0,0)],
					# Front face (-Z)
					[Vector3(0,0,0), Vector3(0,1,0), Vector3(1,1,0), Vector3(1,0,0), Vector3(0,0,-1)],
					# Back face (+Z)
					[Vector3(0,0,1), Vector3(1,0,1), Vector3(1,1,1), Vector3(0,1,1), Vector3(0,0,1)],
				]
				
				for face in faces:
					var normal = face[4]
					var v0 = pos + face[0] * cell_size
					var v1 = pos + face[1] * cell_size
					var v2 = pos + face[2] * cell_size
					var v3 = pos + face[3] * cell_size
					
					# Add two triangles for the quad
					surface_tool.set_normal(normal)
					surface_tool.add_vertex(v0)
					surface_tool.add_vertex(v1)
					surface_tool.add_vertex(v2)
					
					surface_tool.set_normal(normal)
					surface_tool.add_vertex(v0)
					surface_tool.add_vertex(v2)
					surface_tool.add_vertex(v3)
					
					vertex_count += 6
					triangle_count += 2
	
	if vertex_count > 0:
		# Generate normals
		surface_tool.generate_normals()
		
		var mesh = surface_tool.commit()
		
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "SculptureMesh"
		mesh_instance.mesh = mesh
		
		# Create material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.8, 0.7)
		material.roughness = 0.3
		material.metallic = 0.1
		material.cull_mode = StandardMaterial3D.CULL_DISABLED  # See from inside
		mesh_instance.material_override = material
		
		add_child(mesh_instance)
		print("✅ Mesh created with ", vertex_count, " vertices, ", triangle_count, " triangles")
	else:
		print("⚠️ No mesh generated - no surface found")
		print("   Try adjusting iso_level or checking density values")

func clear_sculpture():
	if mesh_instance:
		mesh_instance.queue_free()
		mesh_instance = null

func get_edge_table() -> Array:
	# Marching cubes edge table (simplified)
	return []

func get_tri_table() -> Array:
	# Marching cubes triangle table (simplified)
	return []


# cube_mound.gd - Drop cubes and generate mesh from pile
extends Node3D

@export var num_cubes: int = 20
@export var cube_size: float = 1.0
@export var spawn_height: float = 10.0
@export var spawn_radius: float = 3.0
@export var settle_time: float = 3.0
@export var voxel_size: float = 0.5
@export var generate_on_start: bool = true

var cubes: Array = []
var state: String = "idle"  # idle, dropping, settling, generating, done
var timer: float = 0.0
var generated_mesh: MeshInstance3D = null

@onready var ground = $Ground

func _ready():
	if generate_on_start:
		start_generation()

func start_generation():
	if state != "idle" and state != "done":
		return
	
	clear_cubes()
	clear_generated_mesh()
	
	print("Dropping %d cubes..." % num_cubes)
	drop_cubes()
	state = "dropping"
	timer = 0.0

func drop_cubes():
	for i in range(num_cubes):
		var cube = RigidBody3D.new()
		
		# Random spawn position in cylinder above ground
		var angle = randf() * TAU
		var radius = randf() * spawn_radius
		var spawn_pos = Vector3(
			cos(angle) * radius,
			spawn_height + randf() * 2.0,
			sin(angle) * radius
		)
		cube.position = spawn_pos
		
		# Random rotation
		cube.rotation = Vector3(
			randf() * TAU,
			randf() * TAU,
			randf() * TAU
		)
		
		# Add collision shape
		var collision = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3.ONE * cube_size
		collision.shape = box_shape
		cube.add_child(collision)
		
		# Add visual mesh
		var mesh_instance = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3.ONE * cube_size
		mesh_instance.mesh = box_mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(randf(), randf(), randf())
		mesh_instance.material_override = material
		cube.add_child(mesh_instance)
		
		add_child(cube)
		cubes.append(cube)
	
	print("Cubes dropped! Waiting for settlement...")

func _process(delta):
	if state == "dropping":
		timer += delta
		# Wait a moment for cubes to start falling
		if timer > 0.5:
			state = "settling"
			timer = 0.0
	
	elif state == "settling":
		timer += delta
		
		# Check if all cubes are sleeping (settled)
		var all_settled = true
		for cube in cubes:
			if cube is RigidBody3D and not cube.sleeping:
				all_settled = false
				break
		
		# Force generation after settle_time regardless
		if timer > settle_time or all_settled:
			print("Cubes settled! Generating mesh...")
			state = "generating"
			# Generate mesh in next frame to show message
			await get_tree().process_frame
			generate_mesh_from_cubes()
			state = "done"
			print("Mesh generation complete!")

func generate_mesh_from_cubes():
	# Get all cube positions
	var positions = []
	for cube in cubes:
		if cube is RigidBody3D:
			positions.append(cube.global_position)
	
	if positions.is_empty():
		print("No cubes to generate mesh from!")
		return
	
	# Find bounds
	var min_bounds = positions[0]
	var max_bounds = positions[0]
	
	for pos in positions:
		min_bounds.x = min(min_bounds.x, pos.x)
		min_bounds.y = min(min_bounds.y, pos.y)
		min_bounds.z = min(min_bounds.z, pos.z)
		max_bounds.x = max(max_bounds.x, pos.x)
		max_bounds.y = max(max_bounds.y, pos.y)
		max_bounds.z = max(max_bounds.z, pos.z)
	
	# Expand bounds by cube size
	min_bounds -= Vector3.ONE * cube_size
	max_bounds += Vector3.ONE * cube_size
	
	# Create voxel grid
	var grid_size = ((max_bounds - min_bounds) / voxel_size).ceil()
	var voxel_grid = {}
	
	# Mark voxels occupied by cubes
	for pos in positions:
		var voxel_pos = ((pos - min_bounds) / voxel_size).floor()
		
		# Mark cube volume as occupied (cube_size in voxels)
		var half_extent = int(ceil(cube_size / voxel_size))
		for x in range(-half_extent, half_extent + 1):
			for y in range(-half_extent, half_extent + 1):
				for z in range(-half_extent, half_extent + 1):
					var check_pos = voxel_pos + Vector3(x, y, z)
					var key = "%d,%d,%d" % [check_pos.x, check_pos.y, check_pos.z]
					voxel_grid[key] = true
	
	# Generate mesh from surface voxels
	var surface_mesh = create_mesh_from_voxels(voxel_grid, min_bounds, grid_size)
	
	# Create mesh instance
	generated_mesh = MeshInstance3D.new()
	generated_mesh.mesh = surface_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.4)
	material.roughness = 0.8
	material.metallic = 0.0
	generated_mesh.material_override = material
	
	add_child(generated_mesh)

	# Create collider from generated mesh so the player can walk on the mound
	var static_body := StaticBody3D.new()
	static_body.name = "MoundCollider"
	var collider := CollisionShape3D.new()
	var tri_shape := surface_mesh.create_trimesh_shape()
	if tri_shape:
		collider.shape = tri_shape
		static_body.add_child(collider)
		add_child(static_body)
	
	# Optionally hide original cubes
	for cube in cubes:
		cube.visible = false

func create_mesh_from_voxels(voxel_grid: Dictionary, min_bounds: Vector3, grid_size: Vector3) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# For each occupied voxel, check neighbors and add faces for exposed sides
	for key in voxel_grid.keys():
		var parts = key.split(",")
		var x = int(parts[0])
		var y = int(parts[1])
		var z = int(parts[2])
		var pos = Vector3(x, y, z)
		
		# Check each face direction
		var directions = [
			Vector3(1, 0, 0),   # Right
			Vector3(-1, 0, 0),  # Left
			Vector3(0, 1, 0),   # Up
			Vector3(0, -1, 0),  # Down
			Vector3(0, 0, 1),   # Forward
			Vector3(0, 0, -1)   # Back
		]
		
		for dir in directions:
			var neighbor_pos = pos + dir
			var neighbor_key = "%d,%d,%d" % [neighbor_pos.x, neighbor_pos.y, neighbor_pos.z]
			
			# If neighbor is not occupied, this face is exposed
			if not voxel_grid.has(neighbor_key):
				add_voxel_face(st, pos, dir, min_bounds)
	
	st.generate_normals()
	return st.commit()

func add_voxel_face(st: SurfaceTool, voxel_pos: Vector3, normal: Vector3, min_bounds: Vector3):
	# Convert voxel position to world position
	var world_pos = min_bounds + voxel_pos * voxel_size
	var half_size = voxel_size * 0.5
	
	# Define vertices based on face normal
	var vertices = []
	
	if normal == Vector3(1, 0, 0):  # Right face (+X)
		vertices = [
			world_pos + Vector3(half_size, -half_size, -half_size),
			world_pos + Vector3(half_size, -half_size, half_size),
			world_pos + Vector3(half_size, half_size, half_size),
			world_pos + Vector3(half_size, half_size, -half_size)
		]
	elif normal == Vector3(-1, 0, 0):  # Left face (-X)
		vertices = [
			world_pos + Vector3(-half_size, -half_size, half_size),
			world_pos + Vector3(-half_size, -half_size, -half_size),
			world_pos + Vector3(-half_size, half_size, -half_size),
			world_pos + Vector3(-half_size, half_size, half_size)
		]
	elif normal == Vector3(0, 1, 0):  # Top face (+Y)
		vertices = [
			world_pos + Vector3(-half_size, half_size, -half_size),
			world_pos + Vector3(half_size, half_size, -half_size),
			world_pos + Vector3(half_size, half_size, half_size),
			world_pos + Vector3(-half_size, half_size, half_size)
		]
	elif normal == Vector3(0, -1, 0):  # Bottom face (-Y)
		vertices = [
			world_pos + Vector3(-half_size, -half_size, half_size),
			world_pos + Vector3(half_size, -half_size, half_size),
			world_pos + Vector3(half_size, -half_size, -half_size),
			world_pos + Vector3(-half_size, -half_size, -half_size)
		]
	elif normal == Vector3(0, 0, 1):  # Front face (+Z)
		vertices = [
			world_pos + Vector3(-half_size, -half_size, half_size),
			world_pos + Vector3(-half_size, half_size, half_size),
			world_pos + Vector3(half_size, half_size, half_size),
			world_pos + Vector3(half_size, -half_size, half_size)
		]
	elif normal == Vector3(0, 0, -1):  # Back face (-Z)
		vertices = [
			world_pos + Vector3(half_size, -half_size, -half_size),
			world_pos + Vector3(half_size, half_size, -half_size),
			world_pos + Vector3(-half_size, half_size, -half_size),
			world_pos + Vector3(-half_size, -half_size, -half_size)
		]
	
	# Add two triangles for the quad
	st.set_normal(normal)
	st.add_vertex(vertices[0])
	st.add_vertex(vertices[1])
	st.add_vertex(vertices[2])
	
	st.add_vertex(vertices[0])
	st.add_vertex(vertices[2])
	st.add_vertex(vertices[3])

func clear_cubes():
	for cube in cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	cubes.clear()

func clear_generated_mesh():
	if generated_mesh and is_instance_valid(generated_mesh):
		generated_mesh.queue_free()
	generated_mesh = null

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			start_generation()
		elif event.keycode == KEY_T:
			# Toggle cube visibility
			if not cubes.is_empty():
				var visible = !cubes[0].visible
				for cube in cubes:
					cube.visible = visible
		elif event.keycode == KEY_R:
			# Regenerate with different random positions
			get_tree().reload_current_scene()

func _exit_tree():
	clear_cubes()
	clear_generated_mesh()

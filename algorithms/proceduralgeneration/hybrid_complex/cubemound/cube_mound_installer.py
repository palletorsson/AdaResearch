#!/usr/bin/env python3
"""
Godot 4 Cube Mound Mesh Generator
Drops physics cubes, lets them pile up, then generates a mesh from the result
"""

import os

def create_file(filename, content):
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Created: {filename}")

def main():
    print("=" * 60)
    print("Godot 4 Cube Mound Mesh Generator - Installer")
    print("=" * 60)
    print("\nCreating cube mound system files...\n")
    
    # cube_mound.gd - Main controller
    cube_mound_gd = '''# cube_mound.gd - Drop cubes and generate mesh from pile
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
'''
    create_file('cube_mound.gd', cube_mound_gd)
    
    # cube_mound_scene.tscn
    cube_mound_scene = '''[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://cube_mound.gd" id="1"]

[sub_resource type="BoxShape3D" id="1"]
size = Vector3(30, 1, 30)

[sub_resource type="BoxMesh" id="2"]
size = Vector3(30, 1, 30)

[sub_resource type="StandardMaterial3D" id="3"]
albedo_color = Color(0.3, 0.3, 0.3, 1)

[node name="CubeMound" type="Node3D"]
script = ExtResource("1")
num_cubes = 20
cube_size = 1.0
spawn_height = 10.0
spawn_radius = 3.0
settle_time = 3.0
voxel_size = 0.5

[node name="Ground" type="StaticBody3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="Ground"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)
shape = SubResource("1")

[node name="MeshInstance3D" type="MeshInstance3D" parent="Ground"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)
mesh = SubResource("2")
material_override = SubResource("3")

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(0.866, -0.25, 0.433, 0, 0.866, 0.5, -0.5, -0.433, 0.75, 12, 8, 12)

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.707, 0.707, 0, -0.707, 0.707, 0, 10, 0)
shadow_enabled = true

[node name="UI" type="CanvasLayer" parent="."]

[node name="Instructions" type="Label" parent="UI"]
offset_left = 10.0
offset_top = 10.0
offset_right = 400.0
offset_bottom = 100.0
text = "SPACE - Drop new cubes and generate mesh
T - Toggle cube visibility
R - Restart scene"
'''
    create_file('cube_mound_scene.tscn', cube_mound_scene)
    
    # advanced_cube_mound.gd - Version with smoothing options
    advanced_cube_mound_gd = '''# advanced_cube_mound.gd - Advanced version with smoothing and options
extends Node3D

@export var num_cubes: int = 20
@export var cube_size: float = 1.0
@export var spawn_height: float = 10.0
@export var spawn_radius: float = 3.0
@export var settle_time: float = 3.0
@export var voxel_size: float = 0.5
@export var smooth_mesh: bool = true
@export var smooth_iterations: int = 2
@export var use_convex_hull: bool = false
@export var generate_on_start: bool = true

var cubes: Array = []
var state: String = "idle"
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
		
		var angle = randf() * TAU
		var radius = randf() * spawn_radius
		var spawn_pos = Vector3(
			cos(angle) * radius,
			spawn_height + randf() * 2.0,
			sin(angle) * radius
		)
		cube.position = spawn_pos
		cube.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		
		var collision = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3.ONE * cube_size
		collision.shape = box_shape
		cube.add_child(collision)
		
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

func _process(delta):
	if state == "dropping":
		timer += delta
		if timer > 0.5:
			state = "settling"
			timer = 0.0
	
	elif state == "settling":
		timer += delta
		
		var all_settled = true
		for cube in cubes:
			if cube is RigidBody3D and not cube.sleeping:
				all_settled = false
				break
		
		if timer > settle_time or all_settled:
			print("Generating mesh...")
			state = "generating"
			await get_tree().process_frame
			generate_mesh_from_cubes()
			state = "done"
			print("Done!")

func generate_mesh_from_cubes():
	var positions = []
	for cube in cubes:
		if cube is RigidBody3D:
			positions.append(cube.global_position)
	
	if positions.is_empty():
		return
	
	var surface_mesh: ArrayMesh
	
	if use_convex_hull:
		surface_mesh = create_convex_hull_mesh(positions)
	else:
		surface_mesh = create_voxel_mesh(positions)
	
	if smooth_mesh and not use_convex_hull:
		surface_mesh = smooth_mesh_laplacian(surface_mesh, smooth_iterations)
	
	generated_mesh = MeshInstance3D.new()
	generated_mesh.mesh = surface_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.4)
	material.roughness = 0.8
	generated_mesh.material_override = material
	
	add_child(generated_mesh)
	
	for cube in cubes:
		cube.visible = false

func create_convex_hull_mesh(positions: Array) -> ArrayMesh:
	# Simple convex hull using Godot's built-in ConvexPolygonShape3D
	var shape = ConvexPolygonShape3D.new()
	
	# Add points around each cube position
	var points = PackedVector3Array()
	for pos in positions:
		var hs = cube_size * 0.5
		points.append(pos + Vector3(-hs, -hs, -hs))
		points.append(pos + Vector3(hs, -hs, -hs))
		points.append(pos + Vector3(-hs, hs, -hs))
		points.append(pos + Vector3(hs, hs, -hs))
		points.append(pos + Vector3(-hs, -hs, hs))
		points.append(pos + Vector3(hs, -hs, hs))
		points.append(pos + Vector3(-hs, hs, hs))
		points.append(pos + Vector3(hs, hs, hs))
	
	shape.points = points
	
	# Convert shape to mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Get faces from convex shape
	var faces = shape.get_faces()
	for i in range(0, faces.size(), 3):
		st.add_vertex(faces[i])
		st.add_vertex(faces[i + 1])
		st.add_vertex(faces[i + 2])
	
	st.generate_normals()
	return st.commit()

func create_voxel_mesh(positions: Array) -> ArrayMesh:
	var min_bounds = positions[0]
	var max_bounds = positions[0]
	
	for pos in positions:
		min_bounds = min_bounds.min(pos)
		max_bounds = max_bounds.max(pos)
	
	min_bounds -= Vector3.ONE * cube_size
	max_bounds += Vector3.ONE * cube_size
	
	var voxel_grid = {}
	
	for pos in positions:
		var voxel_pos = ((pos - min_bounds) / voxel_size).floor()
		var half_extent = int(ceil(cube_size / voxel_size))
		
		for x in range(-half_extent, half_extent + 1):
			for y in range(-half_extent, half_extent + 1):
				for z in range(-half_extent, half_extent + 1):
					var check_pos = voxel_pos + Vector3(x, y, z)
					var key = "%d,%d,%d" % [check_pos.x, check_pos.y, check_pos.z]
					voxel_grid[key] = true
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for key in voxel_grid.keys():
		var parts = key.split(",")
		var pos = Vector3(int(parts[0]), int(parts[1]), int(parts[2]))
		
		var directions = [
			Vector3(1, 0, 0), Vector3(-1, 0, 0),
			Vector3(0, 1, 0), Vector3(0, -1, 0),
			Vector3(0, 0, 1), Vector3(0, 0, -1)
		]
		
		for dir in directions:
			var neighbor_pos = pos + dir
			var neighbor_key = "%d,%d,%d" % [neighbor_pos.x, neighbor_pos.y, neighbor_pos.z]
			
			if not voxel_grid.has(neighbor_key):
				add_voxel_face(st, pos, dir, min_bounds)
	
	st.generate_normals()
	return st.commit()

func add_voxel_face(st: SurfaceTool, voxel_pos: Vector3, normal: Vector3, min_bounds: Vector3):
	var world_pos = min_bounds + voxel_pos * voxel_size
	var hs = voxel_size * 0.5
	
	var vertices = []
	
	if normal.x > 0:
		vertices = [
			world_pos + Vector3(hs, -hs, -hs),
			world_pos + Vector3(hs, -hs, hs),
			world_pos + Vector3(hs, hs, hs),
			world_pos + Vector3(hs, hs, -hs)
		]
	elif normal.x < 0:
		vertices = [
			world_pos + Vector3(-hs, -hs, hs),
			world_pos + Vector3(-hs, -hs, -hs),
			world_pos + Vector3(-hs, hs, -hs),
			world_pos + Vector3(-hs, hs, hs)
		]
	elif normal.y > 0:
		vertices = [
			world_pos + Vector3(-hs, hs, -hs),
			world_pos + Vector3(hs, hs, -hs),
			world_pos + Vector3(hs, hs, hs),
			world_pos + Vector3(-hs, hs, hs)
		]
	elif normal.y < 0:
		vertices = [
			world_pos + Vector3(-hs, -hs, hs),
			world_pos + Vector3(hs, -hs, hs),
			world_pos + Vector3(hs, -hs, -hs),
			world_pos + Vector3(-hs, -hs, -hs)
		]
	elif normal.z > 0:
		vertices = [
			world_pos + Vector3(-hs, -hs, hs),
			world_pos + Vector3(-hs, hs, hs),
			world_pos + Vector3(hs, hs, hs),
			world_pos + Vector3(hs, -hs, hs)
		]
	else:
		vertices = [
			world_pos + Vector3(hs, -hs, -hs),
			world_pos + Vector3(hs, hs, -hs),
			world_pos + Vector3(-hs, hs, -hs),
			world_pos + Vector3(-hs, -hs, -hs)
		]
	
	st.set_normal(normal)
	st.add_vertex(vertices[0])
	st.add_vertex(vertices[1])
	st.add_vertex(vertices[2])
	st.add_vertex(vertices[0])
	st.add_vertex(vertices[2])
	st.add_vertex(vertices[3])

func smooth_mesh_laplacian(input_mesh: ArrayMesh, iterations: int) -> ArrayMesh:
	for iter in range(iterations):
		var arrays = input_mesh.surface_get_arrays(0)
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		var indices = arrays[Mesh.ARRAY_INDEX]
		
		# Build vertex neighbor map
		var neighbors = {}
		for i in range(vertices.size()):
			neighbors[i] = []
		
		for i in range(0, indices.size(), 3):
			var i0 = indices[i]
			var i1 = indices[i + 1]
			var i2 = indices[i + 2]
			
			if not neighbors[i0].has(i1): neighbors[i0].append(i1)
			if not neighbors[i0].has(i2): neighbors[i0].append(i2)
			if not neighbors[i1].has(i0): neighbors[i1].append(i0)
			if not neighbors[i1].has(i2): neighbors[i1].append(i2)
			if not neighbors[i2].has(i0): neighbors[i2].append(i0)
			if not neighbors[i2].has(i1): neighbors[i2].append(i1)
		
		# Smooth vertices
		var new_vertices = PackedVector3Array()
		new_vertices.resize(vertices.size())
		
		for i in range(vertices.size()):
			if neighbors[i].size() > 0:
				var avg = Vector3.ZERO
				for n in neighbors[i]:
					avg += vertices[n]
				avg /= neighbors[i].size()
				new_vertices[i] = vertices[i].lerp(avg, 0.5)
			else:
				new_vertices[i] = vertices[i]
		
		arrays[Mesh.ARRAY_VERTEX] = new_vertices
		
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.create_from_arrays(arrays)
		st.generate_normals()
		input_mesh = st.commit()
	
	return input_mesh

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
			if not cubes.is_empty():
				var visible = !cubes[0].visible
				for cube in cubes:
					cube.visible = visible
		elif event.keycode == KEY_R:
			get_tree().reload_current_scene()

func _exit_tree():
	clear_cubes()
	clear_generated_mesh()
'''
    create_file('advanced_cube_mound.gd', advanced_cube_mound_gd)
    
    # README.md
    readme = '''# Godot 4 Cube Mound Mesh Generator

Drop physics cubes, let them pile up, then generate a mesh from their positions!

## Features

🎲 **Physics Simulation** - Real RigidBody3D cubes with collision
📦 **Automatic Mesh Generation** - Creates mesh from settled cube positions
🔷 **Voxel-based Surface** - Finds edges and builds surface mesh
✨ **Two Versions** - Basic and advanced with smoothing
🎨 **Customizable** - Number of cubes, size, spawn area, voxel resolution

## Quick Start

1. **Run installer:**
   ```bash
   python install_cube_mound.py
   ```

2. **Open Godot 4**
3. **Open `cube_mound_scene.tscn`**
4. **Press F5** - Cubes drop and mesh generates automatically!

## Controls

- **SPACE** - Drop new cubes and generate mesh
- **T** - Toggle cube visibility (show/hide original cubes)
- **R** - Restart scene with new random positions

## How It Works

### 1. Drop Phase
- Spawns N RigidBody3D cubes
- Random positions in cylinder above ground
- Random rotations
- Each cube has unique color

### 2. Settle Phase
- Physics engine simulates falling
- Cubes collide and pile up
- Waits for all cubes to sleep (stop moving)
- Or times out after `settle_time` seconds

### 3. Generate Phase
- Captures all cube positions
- Creates 3D voxel grid
- Marks occupied voxels (cube volumes)
- Finds surface voxels (exposed faces)
- Builds mesh from surface faces

### 4. Result
- Single mesh wrapping the pile
- Original cubes hidden
- Can toggle visibility to compare

## Configuration

### Basic Settings (Inspector)

- **Num Cubes** (default: 20)
  - More cubes = bigger pile
  - Try: 10, 20, 50, 100

- **Cube Size** (default: 1.0)
  - Size of each physics cube
  - Smaller = more detail

- **Spawn Height** (default: 10.0)
  - How high cubes drop from
  - Higher = more chaos

- **Spawn Radius** (default: 3.0)
  - Cylinder radius for spawn area
  - Larger = more spread out

- **Settle Time** (default: 3.0 seconds)
  - Max wait for physics to settle
  - Increase for more cubes

- **Voxel Size** (default: 0.5)
  - Resolution of generated mesh
  - Smaller = more detailed mesh
  - Larger = smoother, blockier mesh

## Advanced Version

Use `advanced_cube_mound.gd` for additional features:

### Smoothing Options

- **Smooth Mesh** (true/false)
  - Apply Laplacian smoothing
  - Makes surface less blocky

- **Smooth Iterations** (default: 2)
  - Number of smoothing passes
  - More = smoother but slower

### Convex Hull Option

- **Use Convex Hull** (true/false)
  - Uses convex hull instead of voxels
  - Creates wrapping shape around pile
  - Good for simplified collision mesh

## Use Cases

### Game Development
- **Rubble Piles** - Destroyed buildings
- **Rock Formations** - Natural terrain
- **Debris** - Explosion aftermath
- **Procedural Props** - Random mounds

### Procedural Generation
- **Terrain Features** - Hills, mounds
- **Cave Formations** - Stalactites/stalagmites
- **Organic Shapes** - Abstract sculptures

### Prototyping
- **Quick Collision Meshes** - From placement
- **Level Blocking** - Rapid terrain
- **Visual Effects** - Particle-to-mesh

## Examples

### Small Detailed Pile
```
num_cubes = 30
cube_size = 0.5
spawn_radius = 2.0
voxel_size = 0.3
```

### Large Rough Mound
```
num_cubes = 100
cube_size = 1.0
spawn_radius = 5.0
voxel_size = 1.0
```

### Smooth Organic Shape
```
num_cubes = 50
cube_size = 0.8
voxel_size = 0.4
smooth_mesh = true
smooth_iterations = 3
```

## Performance Notes

### Voxel Resolution
- **Small voxels** (0.2-0.4): High detail, many triangles
- **Medium voxels** (0.5-0.8): Balanced
- **Large voxels** (1.0+): Low detail, few triangles

### Cube Count
- **10-30**: Fast, good for testing
- **30-50**: Normal gameplay
- **50-100**: Heavy, use for baking
- **100+**: Very heavy, pre-generate only

### Optimization Tips
1. Use larger voxel_size for performance
2. Enable smoothing only when needed
3. Hide original cubes after generation
4. Pre-generate meshes at design time
5. Use convex hull for collision-only meshes

## Technical Details

### Voxelization Algorithm
```
For each cube position:
  Calculate voxel grid position
  Mark cube volume as occupied (multiple voxels)

For each occupied voxel:
  Check 6 neighbors (NESW, Up, Down)
  If neighbor is empty:
    Add face to mesh
```

### Mesh Generation
- Uses SurfaceTool for construction
- Generates normals automatically
- Clockwise winding for correct lighting
- Each exposed voxel face becomes 2 triangles

### Smoothing (Advanced)
- Laplacian smoothing
- Averages vertex positions with neighbors
- Preserves topology
- Multiple iterations for more smoothing

## Troubleshooting

**Cubes fall through ground:**
- Check Ground StaticBody3D has collision
- Verify physics layers match

**Mesh looks blocky:**
- Decrease voxel_size
- Enable smoothing (advanced version)
- Increase smooth_iterations

**Generation is slow:**
- Reduce num_cubes
- Increase voxel_size
- Disable smoothing

**Mesh has holes:**
- Decrease voxel_size
- Check cube_size vs voxel_size ratio
- Ensure settle_time is long enough

**Cubes don't settle:**
- Increase settle_time
- Check physics simulation speed
- Verify no moving platforms nearby

## Extending the System

### Add Colors to Mesh
```gdscript
# In generate_mesh_from_cubes:
var cube_colors = []
for cube in cubes:
    var mat = cube.get_child(1).material_override
    cube_colors.append(mat.albedo_color)

# Then assign colors based on nearest cube
```

### Save Generated Mesh
```gdscript
# After generation:
ResourceSaver.save(generated_mesh.mesh, "res://saved_mound.tres")
```

### Animated Growth
```gdscript
# Show cubes appearing one by one
for i in range(num_cubes):
    spawn_cube()
    await get_tree().create_timer(0.1).timeout
```

### Multiple Materials
```gdscript
# Assign different materials to top/sides
# Check face normal in add_voxel_face
if normal.y > 0.5:
    use_top_material()
else:
    use_side_material()
```

## Credits

Inspired by procedural mesh generation techniques.
Voxel-based surface extraction algorithm.
Laplacian smoothing for organic shapes.

Enjoy creating mounds! 📦🏔️
'''
    create_file('README.md', readme)
    
    print("\n" + "=" * 60)
    print("Installation Complete!")
    print("=" * 60)
    print("\nCreated files:")
    print("  - cube_mound.gd (Basic version)")
    print("  - advanced_cube_mound.gd (With smoothing)")
    print("  - cube_mound_scene.tscn (Demo scene)")
    print("  - README.md (Full documentation)")
    print("\n" + "=" * 60)
    print("NEXT STEPS:")
    print("=" * 60)
    print("\n1. Open Godot 4")
    print("2. Import/add files to project")
    print("3. Open cube_mound_scene.tscn")
    print("4. Press F5!")
    print("\nCubes will drop, pile up, then mesh generates automatically!")
    print("\nPress SPACE for new pile, T to toggle cubes, R to restart")
    print("=" * 60)

if __name__ == "__main__":
    main()

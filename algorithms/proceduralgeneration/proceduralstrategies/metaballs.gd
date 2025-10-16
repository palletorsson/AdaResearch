# metaballs.gd - Smooth organic shapes from sphere influences
extends Node3D

@export var num_balls: int = 8
@export var grid_resolution: int = 32
@export var threshold: float = 1.0
@export var animate: bool = true

var balls: Array = []
var mesh_instance: MeshInstance3D
var time: float = 0.0

func _ready():
	randomize()
	create_metaballs()
	generate_mesh()

func create_metaballs():
	balls.clear()
	for i in range(num_balls):
		balls.append({
			"position": Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5)),
			"radius": randf_range(1.5, 3.0),
			"velocity": Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
		})

func _process(delta):
	if animate:
		time += delta
		update_metaballs(delta)
		generate_mesh()

func update_metaballs(delta):
	for ball in balls:
		ball.position += ball.velocity * delta
		
		# Bounce off bounds
		for axis in ["x", "y", "z"]:
			if abs(ball.position[axis]) > 8:
				ball.velocity[axis] *= -1
				ball.position[axis] = clamp(ball.position[axis], -8, 8)

func metaball_field(pos: Vector3) -> float:
	var sum = 0.0
	for ball in balls:
		var dist = pos.distance_to(ball.position)
		if dist < 0.001:
			dist = 0.001
		sum += (ball.radius * ball.radius) / (dist * dist)
	return sum

func generate_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var cell_size = 16.0 / grid_resolution
	
	# Sample grid and find surface
	for x in range(grid_resolution - 1):
		for y in range(grid_resolution - 1):
			for z in range(grid_resolution - 1):
				var p = Vector3(x, y, z) * cell_size - Vector3.ONE * 8
				
				# Get corner values
				var corners = []
				for i in range(8):
					var offset = Vector3(
						float(i & 1),
						float((i >> 1) & 1),
						float((i >> 2) & 1)
					) * cell_size
					corners.append(metaball_field(p + offset))
				
				# Simple surface extraction
				var inside_count = 0
				for val in corners:
					if val > threshold:
						inside_count += 1
				
				# If surface crosses this cell, add geometry
				if inside_count > 0 and inside_count < 8:
					var center = p + Vector3.ONE * cell_size * 0.5
					add_surface_geometry(st, center, cell_size)
	
	st.generate_normals()
	
	if mesh_instance:
		mesh_instance.mesh = st.commit()
	else:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = st.commit()
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.3, 0.5)
		material.roughness = 0.2
		material.metallic = 0.8
		mesh_instance.material_override = material
		add_child(mesh_instance)

func add_surface_geometry(st: SurfaceTool, center: Vector3, size: float):
	var hs = size * 0.5
	# Add simple cube for surface approximation
	var dirs = [Vector3.UP, Vector3.RIGHT, Vector3.FORWARD]
	for dir in dirs:
		for sign in [-1, 1]:
			var n = dir * sign
			var v = center + n * hs
			st.add_vertex(v)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		create_metaballs()
		generate_mesh()

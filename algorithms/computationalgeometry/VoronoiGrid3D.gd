extends Node3D

@export var grid_size: int = 10
@export var spacing: float = 1.0
@export var sphere_radius: float = 0.05
@export var line_radius: float = 0.01

@export var random_strength: float = 0.1
@export var cohesion_strength: float = 0.05
@export var separation_strength: float = 0.2
@export var alignment_strength: float = 0.05
@export var neighbor_radius: float = 2.0
@export var max_speed: float = 0.3

var points: Array[Vector2] = []
var velocities: Array[Vector2] = []
var sphere_nodes: Array[MeshInstance3D] = []
var line_nodes: Array[MeshInstance3D] = []

var sphere_mesh := SphereMesh.new()
var cylinder_mesh := CylinderMesh.new()

func _ready() -> void:
	randomize()
	# Setup meshes
	sphere_mesh.radial_segments = 8
	sphere_mesh.rings = 6
	sphere_mesh.radius = sphere_radius
	sphere_mesh.height = sphere_radius * 2
	cylinder_mesh.radial_segments = 6
	cylinder_mesh.height = 1.0
	cylinder_mesh.top_radius = line_radius
	cylinder_mesh.bottom_radius = line_radius

	# Initialize grid positions and velocities
	for x in range(grid_size):
		for y in range(grid_size):
			points.append(Vector2((x - grid_size/2.0) * spacing, (y - grid_size/2.0) * spacing))
			velocities.append(Vector2.ZERO)
			var s = MeshInstance3D.new()
			s.mesh = sphere_mesh
			add_child(s)
			sphere_nodes.append(s)

	update_lines()

func _process(delta: float) -> void:
	update_flocking(delta)
	update_geometry()

func update_flocking(delta: float) -> void:
	for i in range(points.size()):
		var p = points[i]
		var v = velocities[i]

		var random_vec = Vector2(randf_range(-1,1), randf_range(-1,1)) * random_strength

		var neighbor_count = 0
		var avg_pos = Vector2.ZERO
		var avg_vel = Vector2.ZERO
		var separation = Vector2.ZERO

		for j in range(points.size()):
			if i == j:
				continue
			var diff = points[j] - p
			var dist = diff.length()
			if dist < neighbor_radius and dist > 0:
				avg_pos += points[j]
				avg_vel += velocities[j]
				separation -= diff / (dist * dist)
				neighbor_count += 1

		if neighbor_count > 0:
			avg_pos /= neighbor_count
			avg_vel /= neighbor_count

			var cohesion = (avg_pos - p) * cohesion_strength
			var align = (avg_vel - v) * alignment_strength
			var separate = separation * separation_strength

			v += cohesion + align + separate

		v += random_vec
		if v.length() > max_speed:
			v = v.normalized() * max_speed

		p += v * delta
		points[i] = p
		velocities[i] = v

func update_geometry() -> void:
	# Move spheres
	for i in range(points.size()):
		var p2d = points[i]
		sphere_nodes[i].position = Vector3(p2d.x, p2d.y, 0)

	# Update lines
	for l in line_nodes:
		l.queue_free()
	line_nodes.clear()
	update_lines()

func update_lines() -> void:
	for x in range(grid_size):
		for y in range(grid_size):
			var i = x * grid_size + y
			if x < grid_size - 1:
				add_line(points[i], points[i + grid_size])
			if y < grid_size - 1:
				add_line(points[i], points[i + 1])

func add_line(p1: Vector2, p2: Vector2) -> void:
	var v1 = Vector3(p1.x, p1.y, 0)
	var v2 = Vector3(p2.x, p2.y, 0)
	var dir = v2 - v1
	var length = dir.length()
	if length <= 0.0001:
		return
	var mid = (v1 + v2) * 0.5

	# Build a basis whose Y-axis aligns with the segment
	var y_axis := dir.normalized()
	var tmp_up := Vector3.UP
	if abs(tmp_up.dot(y_axis)) > 0.999:
		tmp_up = Vector3.FORWARD
	var x_axis := tmp_up.cross(y_axis).normalized()
	var z_axis := y_axis.cross(x_axis).normalized()
	var basis := Basis(x_axis, y_axis, z_axis)

	var line := MeshInstance3D.new()
	line.mesh = cylinder_mesh
	line.transform = Transform3D(basis, mid)
	line.scale = Vector3(1.0, length, 1.0)
	add_child(line)
	line_nodes.append(line)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


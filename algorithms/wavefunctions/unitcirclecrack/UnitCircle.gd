# QueerUnitCircle.gd
# Animated 3D unit circle with pride colors

extends Node3D

var angle: float = 0.0
var time: float = 0.0
var moving_point: MeshInstance3D
var radius_line: MeshInstance3D
var x_projection: MeshInstance3D
var y_projection: MeshInstance3D
var circle_mesh: MeshInstance3D

func _ready():
	setup_scene()

func setup_scene():
	# Rainbow unit circle
	circle_mesh = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 0.95
	torus_mesh.outer_radius = 1.0
	torus_mesh.rings = 64
	circle_mesh.mesh = torus_mesh
	
	var circle_material = StandardMaterial3D.new()
	circle_material.albedo_color = Color.MAGENTA
	circle_material.emission_enabled = true
	circle_material.emission = Color.MAGENTA * 0.3
	circle_mesh.material_override = circle_material
	add_child(circle_mesh)
	
	# Pride flag axes
	create_axis(Vector3(2, 0, 0), Color.HOT_PINK)      # Trans pink
	create_axis(Vector3(-2, 0, 0), Color.DEEP_SKY_BLUE) # Trans blue
	create_axis(Vector3(0, 2, 0), Color.ORANGE)        # Lesbian orange
	create_axis(Vector3(0, -2, 0), Color.PURPLE)       # Lesbian purple
	
	# Animated point on circle
	moving_point = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.08
	moving_point.mesh = sphere_mesh
	
	var point_material = StandardMaterial3D.new()
	point_material.albedo_color = Color.YELLOW
	point_material.emission_enabled = true
	point_material.emission = Color.YELLOW * 0.5
	moving_point.material_override = point_material
	add_child(moving_point)
	
	# Rainbow radius line
	radius_line = create_glowing_line(Vector3.ZERO, Vector3(1, 0, 0), Color.CYAN)
	
	# Colorful projection lines
	x_projection = create_glowing_line(Vector3.ZERO, Vector3(1, 0, 0), Color.RED)
	y_projection = create_glowing_line(Vector3.ZERO, Vector3(0, 1, 0), Color.GREEN)

func create_axis(end_pos: Vector3, color: Color):
	var axis = create_glowing_line(Vector3.ZERO, end_pos, color)
	axis.scale = Vector3(1, 1, 0.5)

func create_glowing_line(start: Vector3, end: Vector3, color: Color) -> MeshInstance3D:
	var line_mesh = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = start.distance_to(end)
	cylinder_mesh.top_radius = 0.02
	cylinder_mesh.bottom_radius = 0.02
	line_mesh.mesh = cylinder_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.4
	line_mesh.material_override = material
	
	line_mesh.position = (start + end) / 2
	if end != start:
		var direction = (end - start).normalized()
		line_mesh.look_at_from_position(line_mesh.position, line_mesh.position + direction, Vector3.UP)
	
	add_child(line_mesh)
	return line_mesh

func update_line(line: MeshInstance3D, start: Vector3, end: Vector3):
	var distance = start.distance_to(end)
	if distance > 0:
		var original_height = (line.mesh as CylinderMesh).height
		line.scale.y = distance / original_height
		line.position = (start + end) / 2
		var direction = (end - start).normalized()
		line.look_at_from_position(line.position, line.position + direction, Vector3.UP)

func _process(delta):
	time += delta
	angle += delta * 0.8
	
	# Calculate unit circle position
	var x = cos(angle)
	var y = sin(angle)
	var circle_pos = Vector3(x, y, 0)
	
	# Update moving point
	if moving_point:
		moving_point.position = circle_pos
		
		# Color cycling for the point
		var hue = fmod(time * 0.5, 1.0)
		var rainbow_color = Color.from_hsv(hue, 0.8, 1.0)
		var point_mat = moving_point.material_override as StandardMaterial3D
		if point_mat:
			point_mat.albedo_color = rainbow_color
			point_mat.emission = rainbow_color * 0.5
	
	# Update lines
	if radius_line:
		update_line(radius_line, Vector3.ZERO, circle_pos)
	if x_projection:
		update_line(x_projection, Vector3(x, 0, 0), circle_pos)
	if y_projection:
		update_line(y_projection, Vector3(0, y, 0), circle_pos)
	
	# Pulse the circle
	if circle_mesh:
		var pulse = 1.0 + sin(time * 3.0) * 0.1
		circle_mesh.scale = Vector3(pulse, pulse, 1.0)
	
	# Rotate the whole scene slowly
	rotation.z = time * 0.1

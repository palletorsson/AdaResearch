# poincare_disk.gd
# Poincaré disk model of hyperbolic geometry
# Parallel lines diverge, triangles have angle sum < 180°

extends Node3D

class_name PoincareDisk

signal curvature_changed(value: float)

@export var disk_radius: float = 0.4
@export var line_count: int = 8
@export var show_triangle: bool = true
@export var animate_geodesics: bool = true

var _disk_mesh: MeshInstance3D
var _geodesic_lines: Array[MeshInstance3D] = []
var _triangle_mesh: MeshInstance3D
var _angle_label: Label3D
var _info_label: Label3D
var _time: float = 0.0

func _ready():
	_create_disk()
	_create_geodesics()
	if show_triangle:
		_create_hyperbolic_triangle()
	_create_labels()

func _create_disk():
	_disk_mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = disk_radius
	cylinder.bottom_radius = disk_radius
	cylinder.height = 0.01
	cylinder.radial_segments = 64
	_disk_mesh.mesh = cylinder
	_disk_mesh.rotation_degrees.x = 90
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.15, 0.25, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.2
	mat.roughness = 0.3
	_disk_mesh.material_override = mat
	add_child(_disk_mesh)
	
	# Boundary circle (the "infinity" of hyperbolic space)
	var boundary = _create_circle_mesh(disk_radius, 0.005)
	var boundary_mat = StandardMaterial3D.new()
	boundary_mat.albedo_color = Color(0.8, 0.6, 0.2)
	boundary_mat.emission_enabled = true
	boundary_mat.emission = Color(0.8, 0.6, 0.2)
	boundary_mat.emission_energy_multiplier = 0.3
	boundary.material_override = boundary_mat
	add_child(boundary)

func _create_circle_mesh(radius: float, thickness: float) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = radius - thickness
	torus.outer_radius = radius + thickness
	torus.rings = 64
	torus.ring_segments = 8
	mesh_instance.mesh = torus
	mesh_instance.rotation_degrees.x = 90
	return mesh_instance

func _create_geodesics():
	# In hyperbolic space, geodesics (straight lines) appear as circular arcs
	# that meet the boundary at right angles
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.7, 1.0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 0.8)
	mat.emission_energy_multiplier = 0.2
	
	for i in range(line_count):
		var angle = (float(i) / line_count) * PI
		var geodesic = _create_geodesic_arc(angle)
		geodesic.material_override = mat.duplicate()
		add_child(geodesic)
		_geodesic_lines.append(geodesic)

func _create_geodesic_arc(angle: float) -> MeshInstance3D:
	# Create an arc that represents a geodesic in the Poincaré disk
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var segments = 32
	for i in range(segments + 1):
		var t = float(i) / segments
		# Parametric equation for hyperbolic geodesic as circular arc
		var arc_angle = -PI * 0.4 + t * PI * 0.8
		var r = disk_radius * 0.8
		var x = cos(angle) * r * cos(arc_angle) - sin(angle) * r * sin(arc_angle) * 0.5
		var y = sin(angle) * r * cos(arc_angle) + cos(angle) * r * sin(arc_angle) * 0.5
		immediate_mesh.surface_add_vertex(Vector3(x, y, 0.01))
	
	immediate_mesh.surface_end()
	mesh_instance.mesh = immediate_mesh
	return mesh_instance

func _create_hyperbolic_triangle():
	# Triangle in hyperbolic space - angles sum to LESS than 180°
	_triangle_mesh = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	# Three vertices of a hyperbolic triangle (as points in the disk)
	var v1 = Vector3(0, disk_radius * 0.3, 0.02)
	var v2 = Vector3(-disk_radius * 0.25, -disk_radius * 0.2, 0.02)
	var v3 = Vector3(disk_radius * 0.25, -disk_radius * 0.2, 0.02)
	
	# Draw curved edges (geodesic arcs)
	_add_geodesic_edge(immediate_mesh, v1, v2)
	_add_geodesic_edge(immediate_mesh, v2, v3)
	_add_geodesic_edge(immediate_mesh, v3, v1)
	
	immediate_mesh.surface_end()
	_triangle_mesh.mesh = immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.2)
	mat.emission_energy_multiplier = 0.4
	_triangle_mesh.material_override = mat
	add_child(_triangle_mesh)

func _add_geodesic_edge(mesh: ImmediateMesh, from: Vector3, to: Vector3):
	var segments = 16
	for i in range(segments + 1):
		var t = float(i) / segments
		# Slight curve to simulate hyperbolic geodesic
		var mid = (from + to) / 2
		var normal = Vector3(-(to.y - from.y), to.x - from.x, 0).normalized()
		var curve_amount = 0.05 * sin(t * PI)
		var point = from.lerp(to, t) + normal * curve_amount
		mesh.surface_add_vertex(point)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.pixel_size = 0.001
	_info_label.font_size = 14
	_info_label.text = "POINCARÉ DISK\nHyperbolic Geometry\nParallel lines diverge"
	_info_label.position = Vector3(0, -disk_radius - 0.15, 0)
	add_child(_info_label)
	
	_angle_label = Label3D.new()
	_angle_label.pixel_size = 0.001
	_angle_label.font_size = 12
	_angle_label.text = "Triangle angles: ~150°\n(Less than 180°!)"
	_angle_label.position = Vector3(0, disk_radius + 0.1, 0)
	_angle_label.modulate = Color(1.0, 0.7, 0.5)
	add_child(_angle_label)

func _process(delta):
	if animate_geodesics:
		_time += delta * 0.5
		for i in range(_geodesic_lines.size()):
			var line = _geodesic_lines[i]
			var mat = line.material_override as StandardMaterial3D
			var pulse = 0.5 + 0.5 * sin(_time + i * 0.5)
			mat.albedo_color.a = 0.4 + 0.4 * pulse

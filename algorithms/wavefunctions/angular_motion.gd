extends Node3D

## Angular Motion — accelerating rotation with spiral trail
## A rod spins around Y with increasing angular velocity.
## One endpoint traces an ImmediateMesh spiral trail.

@export var angle_acceleration: float = 0.01
@export var angle_velocity: float = 0.0
@export var angle: float = 0.0

@export var rod_base_length: float = 0.1  # half-length, grows over time
@export var endpoint_radius: float = 0.01
@export var rod_radius: float = 0.004
@export var max_trail_points: int = 2000

var trail_points: PackedVector3Array = PackedVector3Array()
var trail_mesh: ImmediateMesh
var trail_instance: MeshInstance3D
var trail_material: StandardMaterial3D

var rod_instance: MeshInstance3D
var rod_mesh: CylinderMesh

var sphere_right: MeshInstance3D
var sphere_left: MeshInstance3D

var label: Label3D

func _ready() -> void:
	_build_trail()
	_build_rod()
	_build_endpoints()
	_build_label()

func _build_trail() -> void:
	trail_mesh = ImmediateMesh.new()
	trail_instance = MeshInstance3D.new()
	trail_instance.mesh = trail_mesh
	trail_material = StandardMaterial3D.new()
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.vertex_color_use_as_albedo = true
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.no_depth_test = true
	add_child(trail_instance)

func _build_rod() -> void:
	rod_mesh = CylinderMesh.new()
	rod_mesh.top_radius = rod_radius
	rod_mesh.bottom_radius = rod_radius
	rod_mesh.height = rod_base_length * 2.0
	rod_instance = MeshInstance3D.new()
	rod_instance.mesh = rod_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.8, 0.8, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.8, 0.8)
	mat.emission_energy_multiplier = 0.5
	rod_instance.material_override = mat
	add_child(rod_instance)

func _build_endpoints() -> void:
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = endpoint_radius
	sphere_mesh.height = endpoint_radius * 2.0
	sphere_mesh.radial_segments = 12
	sphere_mesh.rings = 6

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.6, 0.6, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.6, 0.6)
	mat.emission_energy_multiplier = 0.5

	sphere_right = MeshInstance3D.new()
	sphere_right.mesh = sphere_mesh
	sphere_right.material_override = mat
	add_child(sphere_right)

	sphere_left = MeshInstance3D.new()
	sphere_left.mesh = sphere_mesh.duplicate()
	sphere_left.material_override = mat
	add_child(sphere_left)

func _build_label() -> void:
	label = Label3D.new()
	label.text = "Angular Motion"
	label.font_size = 32
	label.pixel_size = 0.001
	label.position = Vector3(0.0, 0.45, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	label.no_depth_test = true
	add_child(label)

func _process(delta: float) -> void:
	# Accelerating angular motion
	angle_velocity += angle_acceleration * delta
	angle += angle_velocity * delta

	# Grow rod length slowly (original: 0.01 px/frame → scaled)
	rod_base_length += 0.00002

	# Clamp so it stays within ~0.4m radius
	rod_base_length = minf(rod_base_length, 0.38)

	# Endpoint positions in XZ plane (rotation around Y)
	var cos_a := cos(angle)
	var sin_a := sin(angle)
	var right_pos := Vector3(cos_a * rod_base_length, 0.0, sin_a * rod_base_length)
	var left_pos := Vector3(-cos_a * rod_base_length, 0.0, -sin_a * rod_base_length)

	# Update endpoint spheres
	sphere_right.position = right_pos
	sphere_left.position = left_pos

	# Update rod: orient along the line between endpoints
	# CylinderMesh is along Y by default, so we rotate it to lie in XZ
	rod_mesh.height = rod_base_length * 2.0
	rod_instance.position = Vector3.ZERO
	rod_instance.rotation = Vector3.ZERO
	# Rotate: first rotate -90° around X to lay flat, then rotate around Y by angle
	rod_instance.transform.basis = Basis(Vector3.UP, angle) * Basis(Vector3.RIGHT, -PI / 2.0)

	# Add trail point
	trail_points.append(right_pos)
	if trail_points.size() > max_trail_points:
		trail_points = trail_points.slice(1)

	# Rebuild trail mesh
	_draw_trail()

func _draw_trail() -> void:
	trail_mesh.clear_surfaces()
	var count := trail_points.size()
	if count < 2:
		return

	trail_mesh.surface_begin(Mesh.PRIMITIVE_LINES, trail_material)
	for i in range(count - 1):
		var age_0 := float(i) / float(count - 1)
		var age_1 := float(i + 1) / float(count - 1)
		var color_0 := Color(0.0, 1.0, 0.2, age_0 * 0.8)
		var color_1 := Color(0.0, 1.0, 0.2, age_1 * 0.8)
		trail_mesh.surface_set_color(color_0)
		trail_mesh.surface_add_vertex(trail_points[i])
		trail_mesh.surface_set_color(color_1)
		trail_mesh.surface_add_vertex(trail_points[i + 1])
	trail_mesh.surface_end()

func _exit_tree() -> void:
	trail_points.clear()
	if trail_mesh:
		trail_mesh.clear_surfaces()

func apply_grid_config(config: Dictionary) -> void:
	pass
